/**
 * Cria um banco SQLite com o schema REAL do FinUp (executando o db.js) e o
 * enche com dados sintéticos para o teste de desempenho.
 *
 * Uso: node semear.js <arquivo.db> <lancamentosDoUsuario> <lancamentosDeOutrosUsuarios>
 *
 * - Usuário medido: perf@teste.local / senha123, com as categorias padrão.
 *   Lançamentos espalhados nos últimos 24 meses (30% receitas, 70% despesas,
 *   ~10% das despesas em compras parceladas) e 20 metas.
 * - "Outros usuários": 50 contas que dividem os lançamentos extras (servem para
 *   ver o efeito de um banco grande sobre um usuário pequeno).
 * Os dados são gerados com semente fixa: a mesma execução gera os mesmos dados.
 */
const path = require('path');
const fs = require('fs');

const BACKEND = path.resolve(__dirname, '..', '..', '..', 'backend');
const arquivo = path.resolve(process.argv[2]);
const nUsuario = Number(process.argv[3] || 0);
const nOutros = Number(process.argv[4] || 0);
if (fs.existsSync(arquivo)) fs.unlinkSync(arquivo);

const sqlite3 = require(path.join(BACKEND, 'node_modules', 'sqlite3'));
const bcrypt = require(path.join(BACKEND, 'node_modules', 'bcrypt'));
const Original = sqlite3.Database;
sqlite3.Database = function (_f, ...r) { return new Original(arquivo, ...r); };
console.log = ((log) => (...a) => (String(a[0]).startsWith('Banco SQLite') ? 0 : log(...a)))(console.log);
const db = require(path.join(BACKEND, 'src', 'database', 'db.js'));

// PRNG determinístico (mulberry32)
let s = 20261108;
const rnd = () => { s |= 0; s = (s + 0x6d2b79f5) | 0; let t = Math.imul(s ^ (s >>> 15), 1 | s); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
const escolher = (a) => a[Math.floor(rnd() * a.length)];
const valor = (min, max) => Math.round((min + rnd() * (max - min)) * 100) / 100;

const hoje = new Date();
const dataAleatoria = () => {
  const d = new Date(hoje.getFullYear(), hoje.getMonth() - Math.floor(rnd() * 24), 1 + Math.floor(rnd() * 28));
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
};
const RECEITAS = ['Salário', 'Freelance', 'Investimentos', 'Bônus', 'Outros'];
const DESPESAS = ['Alimentação', 'Transporte', 'Moradia', 'Saúde', 'Lazer', 'Compras', 'Assinaturas', 'Impostos', 'Outros'];
const run = (sql, p = []) => new Promise((ok, err) => db.run(sql, p, function (e) { e ? err(e) : ok(this); }));

async function criarUsuario(nome, email, hash) {
  const { lastID } = await run('INSERT INTO users (name, email, password) VALUES (?, ?, ?)', [nome, email, hash]);
  const cats = { income: {}, expense: {} };
  for (const [tipo, nomes] of [['income', RECEITAS], ['expense', DESPESAS]]) {
    for (const n of nomes) cats[tipo][n] = (await run('INSERT INTO categories (name, type, user_id) VALUES (?, ?, ?)', [n, tipo, lastID])).lastID;
  }
  return { id: lastID, cats };
}

function lancamentos(usuario, n, insReceita, insDespesa) {
  let feitos = 0;
  let grupo = 0;
  while (feitos < n) {
    if (rnd() < 0.3) {
      insReceita.run(valor(100, 8000), `Receita ${feitos}`, dataAleatoria(), usuario.cats.income[escolher(RECEITAS)], usuario.id);
      feitos++;
    } else if (rnd() < 0.1 && n - feitos >= 4) {
      const parcelas = 4 + Math.floor(rnd() * 9);
      const qtd = Math.min(parcelas, n - feitos);
      const g = `perf-${usuario.id}-${grupo++}`;
      const v = valor(20, 500);
      const cat = usuario.cats.expense.Compras;
      const base = dataAleatoria();
      for (let i = 0; i < qtd; i++) {
        const [a, m, d] = base.split('-').map(Number);
        const dt = new Date(a, m - 1 + i, d);
        const data = `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, '0')}-${String(dt.getDate()).padStart(2, '0')}`;
        insDespesa.run(v, `Compra parcelada ${g}`, data, cat, 1, usuario.id, g, i + 1, parcelas);
      }
      feitos += qtd;
    } else {
      insDespesa.run(valor(5, 1500), `Despesa ${feitos}`, dataAleatoria(), usuario.cats.expense[escolher(DESPESAS)], 0, usuario.id, null, null, null);
      feitos++;
    }
  }
}

(async () => {
  const t0 = Date.now();
  await new Promise((ok) => db.serialize(() => db.get('SELECT 1', ok)));
  const hash = bcrypt.hashSync('senha123', 10);
  await run('BEGIN');
  const medido = await criarUsuario('Usuária Desempenho', 'perf@teste.local', hash);
  const outros = [];
  if (nOutros > 0) for (let i = 1; i <= 50; i++) outros.push(await criarUsuario(`Outro ${i}`, `outro${i}@teste.local`, hash));
  const insReceita = db.prepare('INSERT INTO incomes (amount, description, date, category_id, user_id) VALUES (?, ?, ?, ?, ?)');
  const insDespesa = db.prepare(`INSERT INTO expenses (amount, description, date, category_id, parcelado, user_id,
                                 parcela_grupo, parcela_numero, parcela_total) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`);
  lancamentos(medido, nUsuario, insReceita, insDespesa);
  for (const o of outros) lancamentos(o, Math.floor(nOutros / 50), insReceita, insDespesa);
  for (let i = 0; i < 20; i++) {
    await run('INSERT INTO goals (title, target_amount, current_amount, icon, user_id) VALUES (?, ?, ?, ?, ?)',
      [`Meta ${i + 1}`, valor(1000, 50000), valor(0, 1000), 'flag', medido.id]);
  }
  await new Promise((ok) => insReceita.finalize(ok));
  await new Promise((ok) => insDespesa.finalize(ok));
  await run('COMMIT');
  const cont = await new Promise((ok) => db.get(
    `SELECT (SELECT COUNT(*) FROM incomes WHERE user_id = ?) + (SELECT COUNT(*) FROM expenses WHERE user_id = ?) AS usuario,
            (SELECT COUNT(*) FROM incomes) + (SELECT COUNT(*) FROM expenses) AS total`, [medido.id, medido.id], (e, r) => ok(r)));
  db.close(() => {
    const mb = (fs.statSync(arquivo).size / 1048576).toFixed(1);
    process.stdout.write(JSON.stringify({ lancamentos_usuario: cont.usuario, lancamentos_banco: cont.total, tamanho_mb: Number(mb), segundos: (Date.now() - t0) / 1000 }) + '\n');
  });
})();
