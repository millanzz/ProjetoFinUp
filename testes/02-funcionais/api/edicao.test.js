const { describe, test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { iniciar, cliente } = require('./servidor');

let srv, api;

describe('Edição (perfil, senha, receitas, despesas e metas)', () => {
  before(async () => {
    srv = await iniciar();
    api = cliente(srv.base);
  });
  after(() => srv.fechar());

  // ── Perfil ─────────────────────────────────────────────────
  test('CT-EDI-01 editar nome do perfil reflete em /users/me', async () => {
    const u = await api.novoUsuario('Joao', 'joao@teste.local');
    const r = await api.put('/users/me', { token: u.token, body: { name: '  João Pedro  ' } });
    assert.equal(r.status, 200);
    assert.equal((await api.get('/users/me', { token: u.token })).body.name, 'João Pedro');
  });

  test('CT-EDI-02 editar e-mail: o novo entra no login e o antigo deixa de entrar', async () => {
    const u = await api.novoUsuario('Kel', 'kel@teste.local');
    const r = await api.put('/users/me', { token: u.token, body: { email: 'Kel.Novo@Teste.Local' } });
    assert.equal(r.status, 200);
    assert.equal((await api.get('/users/me', { token: u.token })).body.email, 'kel.novo@teste.local');
    assert.equal((await api.post('/auth/login', { body: { email: 'kel.novo@teste.local', password: u.senha } })).status, 200);
    assert.equal((await api.post('/auth/login', { body: { email: 'kel@teste.local', password: u.senha } })).status, 401);
  });

  test('CT-EDI-03 trocar e-mail para um já usado por outra pessoa é recusado com 409', async () => {
    await api.novoUsuario('Lia', 'lia@teste.local');
    const u = await api.novoUsuario('Leo', 'leo@teste.local');
    for (const email of ['lia@teste.local', 'LIA@TESTE.LOCAL']) {
      const r = await api.put('/users/me', { token: u.token, body: { email } });
      assert.equal(r.status, 409, email);
    }
    assert.equal((await api.get('/users/me', { token: u.token })).body.email, 'leo@teste.local');
  });

  test('CT-EDI-04 perfil com nome vazio, e-mail inválido ou sem campos é recusado com 400', async () => {
    const u = await api.novoUsuario('Mia', 'mia@teste.local');
    for (const body of [{ name: '   ' }, { email: 'invalido' }, {}]) {
      assert.equal((await api.put('/users/me', { token: u.token, body })).status, 400, JSON.stringify(body));
    }
    const me = (await api.get('/users/me', { token: u.token })).body;
    assert.deepEqual([me.name, me.email], ['Mia', 'mia@teste.local']);
  });

  test('CT-EDI-05 editar perfil sem token é recusado com 401', async () => {
    assert.equal((await api.put('/users/me', { body: { name: 'X' } })).status, 401);
  });

  // ── Senha ──────────────────────────────────────────────────
  test('CT-EDI-06 trocar senha: a nova entra no login e a antiga não', async () => {
    const u = await api.novoUsuario('Nina', 'nina@teste.local', 'antiga1');
    const r = await api.put('/users/me/password', { token: u.token, body: { current_password: 'antiga1', new_password: 'nova123' } });
    assert.equal(r.status, 200);
    assert.equal((await api.post('/auth/login', { body: { email: 'nina@teste.local', password: 'nova123' } })).status, 200);
    assert.equal((await api.post('/auth/login', { body: { email: 'nina@teste.local', password: 'antiga1' } })).status, 401);
  });

  test('CT-EDI-07 trocar senha com a senha atual errada é recusado com 401', async () => {
    const u = await api.novoUsuario('Otto', 'otto@teste.local', 'certa12');
    const r = await api.put('/users/me/password', { token: u.token, body: { current_password: 'errada', new_password: 'nova123' } });
    assert.equal(r.status, 401);
    assert.equal((await api.post('/auth/login', { body: { email: 'otto@teste.local', password: 'certa12' } })).status, 200);
  });

  test('CT-EDI-08 nova senha curta ou campos ausentes são recusados com 400', async () => {
    const u = await api.novoUsuario('Pia', 'pia@teste.local', 'certa12');
    for (const body of [{ current_password: 'certa12', new_password: '123' }, { new_password: 'nova123' }, { current_password: 'certa12' }]) {
      assert.equal((await api.put('/users/me/password', { token: u.token, body })).status, 400, JSON.stringify(body));
    }
  });

  test('CT-EDI-09 nova senha enviada como número é recusada com erro de cliente (4xx)', async () => {
    const u = await api.novoUsuario('Quim', 'quim@teste.local', 'certa12');
    const r = await api.put('/users/me/password', { token: u.token, body: { current_password: 'certa12', new_password: 12345678 } });
    assert.ok(r.status >= 400 && r.status < 500, `status veio ${r.status}: ${JSON.stringify(r.body)}`);
  });

  // ── Receitas e despesas ────────────────────────────────────
  test('CT-EDI-10 editar receita (valor, descrição, data, categoria) reflete na listagem', async () => {
    const u = await api.novoUsuario('Rita', 'rita@teste.local');
    const { body: rec } = await api.post('/incomes', { token: u.token, body: { amount: 100, date: '2026-11-01', description: 'Freela' } });
    const r = await api.put(`/incomes/${rec.id}`, {
      token: u.token,
      body: { amount: 180.5, description: 'Freela site', date: '2026-11-15', category_id: u.categorias['income:Freelance'] },
    });
    assert.equal(r.status, 200);
    const [item] = (await api.get('/incomes', { token: u.token })).body;
    assert.deepEqual(
      [item.amount, item.description, item.date, item.category_name],
      [180.5, 'Freela site', '2026-11-15', 'Freelance']
    );
  });

  test('CT-EDI-11 editar despesa com dados inválidos é recusado e nada muda', async () => {
    const u = await api.novoUsuario('Saulo', 'saulo@teste.local');
    const cat = u.categorias['expense:Moradia'];
    const { body: d } = await api.post('/expenses', { token: u.token, body: { amount: 1500, date: '2026-11-05', category_id: cat } });
    const invalidos = [
      { amount: 0 },
      { date: '2026-02-30' },
      { category_id: u.categorias['income:Salário'] },
      { category_id: null },
      {},
    ];
    for (const body of invalidos) {
      assert.equal((await api.put(`/expenses/${d.id}`, { token: u.token, body })).status, 400, JSON.stringify(body));
    }
    const [item] = (await api.get('/expenses', { token: u.token })).body;
    assert.deepEqual([item.amount, item.date, item.category_id], [1500, '2026-11-05', cat]);
  });

  test('CT-EDI-12 editar uma parcela altera só ela, não o parcelamento todo', async () => {
    const u = await api.novoUsuario('Tais', 'tais@teste.local');
    const { body } = await api.post('/expenses', {
      token: u.token,
      body: { amount: 300, date: '2026-11-10', category_id: u.categorias['expense:Compras'], parcelas: 3 },
    });
    const segunda = body.parcelas[1];
    assert.equal((await api.put(`/expenses/${segunda.id}`, { token: u.token, body: { amount: 120 } })).status, 200);
    const valores = (await api.get('/expenses', { token: u.token })).body.map((x) => x.amount).sort();
    assert.deepEqual(valores, [100, 100, 120]);
  });

  test('CT-EDI-13 editar lançamento inexistente ou de outro usuário responde 404', async () => {
    const a = await api.novoUsuario('Ugo', 'ugo@teste.local');
    const b = await api.novoUsuario('Vera', 'vera@teste.local');
    const { body: rec } = await api.post('/incomes', { token: a.token, body: { amount: 50, date: '2026-11-01' } });
    assert.equal((await api.put('/incomes/99999', { token: a.token, body: { amount: 1 } })).status, 404);
    assert.equal((await api.put(`/incomes/${rec.id}`, { token: b.token, body: { amount: 1 } })).status, 404);
    assert.equal((await api.get('/incomes', { token: a.token })).body[0].amount, 50);
  });

  // ── Metas ──────────────────────────────────────────────────
  test('CT-EDI-14 editar meta (título, alvo, guardado e ícone) reflete na listagem', async () => {
    const u = await api.novoUsuario('Wil', 'wil@teste.local');
    const { body: g } = await api.post('/goals', { token: u.token, body: { title: 'Carro', target_amount: 30000 } });
    const r = await api.patch(`/goals/${g.id}`, {
      token: u.token,
      body: { title: 'Carro usado', target_amount: 25000, current_amount: 5000, icon: 'car' },
    });
    assert.equal(r.status, 200);
    const [item] = (await api.get('/goals', { token: u.token })).body;
    assert.deepEqual([item.title, item.target_amount, item.current_amount, item.icon], ['Carro usado', 25000, 5000, 'car']);
  });

  test('CT-EDI-15 aporte em meta pela API soma ao valor guardado', async () => {
    const u = await api.novoUsuario('Xena', 'xena@teste.local');
    const { body: g } = await api.post('/goals', { token: u.token, body: { title: 'Reserva', target_amount: 1000 } });
    await api.post(`/goals/${g.id}/aportes`, { token: u.token, body: { amount: 250 } });
    const r = await api.post(`/goals/${g.id}/aportes`, { token: u.token, body: { amount: 100 } });
    assert.equal(r.status, 200);
    assert.equal(r.body.current_amount, 350);
  });

  test('CT-EDI-16 editar meta com dados inválidos ou de outro usuário é recusado', async () => {
    const a = await api.novoUsuario('Yuri', 'yuri@teste.local');
    const b = await api.novoUsuario('Zoe', 'zoe@teste.local');
    const { body: g } = await api.post('/goals', { token: a.token, body: { title: 'Meta', target_amount: 100 } });
    for (const body of [{ title: '' }, { target_amount: 0 }, { current_amount: -1 }, { icon: 'xyz' }, {}]) {
      assert.equal((await api.patch(`/goals/${g.id}`, { token: a.token, body })).status, 400, JSON.stringify(body));
    }
    assert.equal((await api.patch(`/goals/${g.id}`, { token: b.token, body: { title: 'Hack' } })).status, 404);
    assert.equal((await api.get('/goals', { token: a.token })).body[0].title, 'Meta');
  });
});
