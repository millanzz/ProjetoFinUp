/**
 * Paginação das listas (mitigação dos cenários de estresse V3/V4).
 * Roda contra a API real com banco em memória.
 * Uso: node --test --test-reporter=spec paginacao.test.js
 */
const { describe, test, before, after } = require('node:test');
const assert = require('node:assert/strict');

const { iniciar, cliente } = require('../02-funcionais/api/servidor');

let srv, api, u;

/** Insere direto no banco (rápido) n lançamentos espalhados em 2025 e 2026. */
function semear(userId, catDespesa, catReceita) {
  const run = (sql, p) => new Promise((ok, err) => srv.db.run(sql, p, (e) => (e ? err(e) : ok())));
  const linhas = [];
  for (let i = 0; i < 1200; i++) {
    const mes = String((i % 12) + 1).padStart(2, '0');
    const ano = i < 600 ? 2025 : 2026;
    const dia = String((i % 28) + 1).padStart(2, '0');
    linhas.push([i % 3 === 0 ? 'incomes' : 'expenses', 1 + (i % 7) + 0.1, `L${i}`, `${ano}-${mes}-${dia}`, i % 3 === 0 ? catReceita : catDespesa]);
  }
  return Promise.all(linhas.map(([t, v, d, dt, c]) =>
    run(`INSERT INTO ${t} (amount, description, date, category_id, user_id) VALUES (?, ?, ?, ?, ?)`, [v, d, dt, c, userId])));
}

describe('Paginação das listas', () => {
  before(async () => {
    srv = await iniciar();
    api = cliente(srv.base);
    u = await api.novoUsuario('Pagina', 'pagina@teste.local');
    await semear(u.user.id, u.categorias['expense:Alimentação'], u.categorias['income:Salário']);
  });
  after(() => srv.fechar());

  test('PAG-01 GET /expenses devolve no máximo 500 por padrão e informa o total e a próxima página', async () => {
    const r = await fetch(`${srv.base}/expenses`, { headers: { Authorization: `Bearer ${u.token}` } });
    const corpo = await r.json();
    assert.equal(corpo.length, 500);
    assert.equal(r.headers.get('x-total-count'), '800');
    assert.equal(r.headers.get('x-next-offset'), '500');
    const ultima = await fetch(`${srv.base}/expenses?offset=500`, { headers: { Authorization: `Bearer ${u.token}` } });
    assert.equal((await ultima.json()).length, 300);
    assert.equal(ultima.headers.get('x-next-offset'), null, 'última página não tem próxima');
  });

  test('PAG-02 percorrer as páginas traz cada lançamento uma vez, do mais recente ao mais antigo', async () => {
    const vistos = [];
    let offset = 0;
    while (offset !== null) {
      const r = await api.get(`/lancamentos?limit=137&offset=${offset}`, { token: u.token });
      assert.equal(r.status, 200);
      vistos.push(...r.body.itens);
      offset = r.body.proximo_offset;
    }
    assert.equal(vistos.length, 1200);
    assert.equal(new Set(vistos.map((l) => `${l.tipo}:${l.id}`)).size, 1200, 'sem repetidos');
    for (let i = 1; i < vistos.length; i++) {
      assert.ok(vistos[i - 1].date >= vistos[i].date, `ordem na posição ${i}`);
    }
  });

  test('PAG-03 os totais vêm de todo o período, não só da página', async () => {
    const r = await api.get('/lancamentos?from=2026-01-01&to=2026-12-31&limit=10', { token: u.token });
    const soma = (t) => new Promise((ok) => srv.db.get(
      `SELECT COUNT(*) n, ROUND(SUM(amount), 2) s FROM ${t} WHERE user_id = ? AND date BETWEEN '2026-01-01' AND '2026-12-31'`,
      [u.user.id], (_e, row) => ok(row)));
    const [rec, des] = [await soma('incomes'), await soma('expenses')];
    assert.equal(r.body.itens.length, 10);
    assert.equal(r.body.total, rec.n + des.n);
    assert.equal(r.body.receitas, rec.s);
    assert.equal(r.body.despesas, des.s);
    assert.equal(r.body.saldo, Math.round((rec.s - des.s) * 100) / 100);
    const porCategoria = r.body.categorias.reduce((s, c) => s + c.total, 0);
    assert.equal(Math.round(porCategoria * 100) / 100, Math.round((rec.s + des.s) * 100) / 100);
  });

  test('PAG-04 filtro por tipo e por mês (com virada de ano)', async () => {
    const r = await api.get('/lancamentos?tipo=despesa&month=2025-12&limit=1000', { token: u.token });
    assert.ok(r.body.itens.length > 0);
    assert.ok(r.body.itens.every((l) => l.tipo === 'despesa' && l.date.startsWith('2025-12')));
    assert.equal(r.body.receitas, 0);
    const lista = await api.get('/expenses?month=2025-12&limit=1000', { token: u.token });
    assert.deepEqual(lista.body.map((l) => l.id).sort(), r.body.itens.map((l) => l.id).sort());
  });

  test('PAG-05 limit=0 devolve só os totais', async () => {
    const r = await api.get('/lancamentos?limit=0', { token: u.token });
    assert.deepEqual(r.body.itens, []);
    assert.equal(r.body.total, 1200);
    assert.equal(r.body.proximo_offset, null);
  });

  test('PAG-06 parâmetros inválidos recebem 400', async () => {
    for (const q of ['limit=1001', 'limit=-1', 'offset=abc', 'from=2026-13-01', 'to=ontem', 'tipo=meta', 'month=2026-1']) {
      const r = await api.get(`/lancamentos?${q}`, { token: u.token });
      assert.equal(r.status, 400, q);
    }
    assert.equal((await api.get('/expenses?limit=5000', { token: u.token })).status, 400);
  });

  test('PAG-07 GET /lancamentos/meses lista os meses com dados', async () => {
    const r = await api.get('/lancamentos/meses', { token: u.token });
    assert.equal(r.body.length, 24);
    assert.equal(r.body[0], '2026-12');
    assert.equal(r.body.at(-1), '2025-01');
  });

  test('PAG-08 um usuário não vê os lançamentos do outro', async () => {
    const outro = await api.novoUsuario('Outro', 'outro-pag@teste.local');
    const r = await api.get('/lancamentos', { token: outro.token });
    assert.equal(r.body.total, 0);
    assert.deepEqual((await api.get('/lancamentos/meses', { token: outro.token })).body, []);
    assert.equal((await api.get('/lancamentos')).status, 401);
  });
});
