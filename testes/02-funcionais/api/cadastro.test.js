const { describe, test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { iniciar, cliente } = require('./servidor');

let srv, api;
const dbGet = (sql, p = []) =>
  new Promise((res, rej) => srv.db.get(sql, p, (e, r) => (e ? rej(e) : res(r))));

describe('Cadastro (POST /users e criação de lançamentos/metas)', () => {
  before(async () => {
    srv = await iniciar();
    api = cliente(srv.base);
  });
  after(() => srv.fechar());

  // ── Cadastro de usuário ────────────────────────────────────
  test('CT-CAD-01 cadastro válido devolve 201 sem a senha e permite login', async () => {
    const r = await api.post('/users', { body: { name: '  Bruno Lima ', email: 'Bruno@Teste.Local', password: 'abc123' } });
    assert.equal(r.status, 201);
    assert.deepEqual(Object.keys(r.body).sort(), ['email', 'id', 'name']);
    assert.equal(r.body.name, 'Bruno Lima');
    assert.equal(r.body.email, 'bruno@teste.local', 'e-mail gravado em minúsculas');
    const l = await api.post('/auth/login', { body: { email: 'bruno@teste.local', password: 'abc123' } });
    assert.equal(l.status, 200);
  });

  test('CT-CAD-02 senha é gravada com hash bcrypt, nunca em texto puro', async () => {
    const row = await dbGet('SELECT password FROM users WHERE email = ?', ['bruno@teste.local']);
    assert.notEqual(row.password, 'abc123');
    assert.match(row.password, /^\$2[aby]\$10\$/);
  });

  test('CT-CAD-03 novo usuário recebe as 14 categorias padrão (5 receita, 9 despesa)', async () => {
    const u = await api.novoUsuario('Carla', 'carla@teste.local');
    const r = await api.get('/categories', { token: u.token });
    assert.equal(r.body.filter((c) => c.type === 'income').length, 5);
    assert.equal(r.body.filter((c) => c.type === 'expense').length, 9);
  });

  test('CT-CAD-04 e-mail já cadastrado é recusado com 409 (inclusive com outra caixa)', async () => {
    for (const email of ['bruno@teste.local', 'BRUNO@teste.local', ' bruno@teste.local ']) {
      const r = await api.post('/users', { body: { name: 'Outro', email, password: 'abc123' } });
      assert.equal(r.status, 409, email);
      assert.equal(r.body.error, 'Email já cadastrado');
    }
  });

  test('CT-CAD-05 campos obrigatórios ausentes ou só com espaços são recusados com 400', async () => {
    const casos = [
      {},
      { email: 'x@teste.local', password: 'abc123' },
      { name: 'X', password: 'abc123' },
      { name: 'X', email: 'x@teste.local' },
      { name: '   ', email: 'x@teste.local', password: 'abc123' },
    ];
    for (const body of casos) {
      const r = await api.post('/users', { body });
      assert.equal(r.status, 400, JSON.stringify(body));
    }
  });

  test('CT-CAD-06 e-mail em formato inválido é recusado com 400', async () => {
    for (const email of ['semarroba.com', 'a@b', 'com espaco@teste.local', '@teste.local']) {
      const r = await api.post('/users', { body: { name: 'X', email, password: 'abc123' } });
      assert.equal(r.status, 400, email);
    }
  });

  test('CT-CAD-07 senha com menos de 6 caracteres é recusada; 6 é aceita (limite)', async () => {
    const curta = await api.post('/users', { body: { name: 'X', email: 'limite@teste.local', password: '12345' } });
    assert.equal(curta.status, 400);
    const ok = await api.post('/users', { body: { name: 'X', email: 'limite@teste.local', password: '123456' } });
    assert.equal(ok.status, 201);
  });

  test('CT-CAD-08 nome com HTML/SQL é gravado como texto, sem efeito colateral', async () => {
    const nome = "Robert'); DROP TABLE users;-- <b>x</b>";
    const u = await api.novoUsuario(nome, 'bobby@teste.local');
    const me = await api.get('/users/me', { token: u.token });
    assert.equal(me.body.name, nome);
    const n = await dbGet('SELECT COUNT(*) AS n FROM users');
    assert.ok(n.n >= 4, 'tabela users continua existindo');
  });

  // ── Cadastro de lançamentos e metas pela API ───────────────
  test('CT-CAD-09 cadastrar receita autenticado: aparece na listagem e no dashboard', async () => {
    const u = await api.novoUsuario('Dani', 'dani@teste.local');
    const r = await api.post('/incomes', {
      token: u.token,
      body: { amount: 3500, date: '2026-11-05', description: 'Salário', category_id: u.categorias['income:Salário'] },
    });
    assert.equal(r.status, 201);
    const lista = await api.get('/incomes', { token: u.token });
    assert.equal(lista.body.length, 1);
    assert.equal(lista.body[0].category_name, 'Salário');
    const dash = await api.get('/dashboard?month=2026-11', { token: u.token });
    assert.equal(dash.body.total_incomes, 3500);
  });

  test('CT-CAD-10 cadastrar despesa parcelada: gera 3 lançamentos visíveis em meses diferentes', async () => {
    const u = await api.novoUsuario('Eva', 'eva@teste.local');
    const r = await api.post('/expenses', {
      token: u.token,
      body: { amount: 900, date: '2026-11-20', description: 'Geladeira', category_id: u.categorias['expense:Compras'], parcelas: 3 },
    });
    assert.equal(r.status, 201);
    for (const [mes, n] of [['2026-11', 1], ['2026-12', 1], ['2027-01', 1], ['2027-02', 0]]) {
      const l = await api.get(`/expenses?month=${mes}`, { token: u.token });
      assert.equal(l.body.length, n, mes);
    }
  });

  test('CT-CAD-11 cadastrar meta: aparece na listagem do usuário', async () => {
    const u = await api.novoUsuario('Fabi', 'fabi@teste.local');
    const r = await api.post('/goals', { token: u.token, body: { title: 'Viagem', target_amount: 5000, icon: 'flight' } });
    assert.equal(r.status, 201);
    const l = await api.get('/goals', { token: u.token });
    assert.deepEqual(l.body.map((g) => [g.title, g.target_amount, g.current_amount, g.icon]), [['Viagem', 5000, 0, 'flight']]);
  });

  test('CT-CAD-12 cadastrar categoria personalizada e usá-la numa despesa', async () => {
    const u = await api.novoUsuario('Gabi', 'gabi@teste.local');
    const c = await api.post('/categories', { token: u.token, body: { name: 'Pets', type: 'expense' } });
    assert.equal(c.status, 201);
    const d = await api.post('/expenses', { token: u.token, body: { amount: 120, date: '2026-11-01', category_id: c.body.id } });
    assert.equal(d.status, 201);
    const t = await api.post('/categories', { token: u.token, body: { name: 'X', type: 'outro' } });
    assert.equal(t.status, 400);
  });

  test('CT-CAD-13 dados de um usuário não aparecem para outro', async () => {
    const a = await api.novoUsuario('Hugo', 'hugo@teste.local');
    const b = await api.novoUsuario('Iris', 'iris@teste.local');
    await api.post('/goals', { token: a.token, body: { title: 'Do Hugo', target_amount: 10 } });
    await api.post('/incomes', { token: a.token, body: { amount: 10, date: '2026-11-01' } });
    assert.equal((await api.get('/goals', { token: b.token })).body.length, 0);
    assert.equal((await api.get('/incomes', { token: b.token })).body.length, 0);
  });
});
