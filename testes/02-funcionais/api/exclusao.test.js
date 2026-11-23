const { describe, test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { iniciar, cliente } = require('./servidor');

let srv, api;

describe('Exclusão (receitas, despesas, parcelamentos, metas e categorias)', () => {
  before(async () => {
    srv = await iniciar();
    api = cliente(srv.base);
  });
  after(() => srv.fechar());

  test('CT-EXC-01 excluir receita: 204, some da listagem e do saldo', async () => {
    const u = await api.novoUsuario('Ana', 'exc-ana@teste.local');
    const { body: r1 } = await api.post('/incomes', { token: u.token, body: { amount: 1000, date: '2026-11-01' } });
    await api.post('/incomes', { token: u.token, body: { amount: 200, date: '2026-11-02' } });
    const r = await api.del(`/incomes/${r1.id}`, { token: u.token });
    assert.equal(r.status, 204);
    assert.deepEqual((await api.get('/incomes', { token: u.token })).body.map((x) => x.amount), [200]);
    assert.equal((await api.get('/dashboard', { token: u.token })).body.balance, 200);
  });

  test('CT-EXC-02 excluir a mesma receita duas vezes: a segunda responde 404', async () => {
    const u = await api.novoUsuario('Beto', 'exc-beto@teste.local');
    const { body } = await api.post('/incomes', { token: u.token, body: { amount: 10, date: '2026-11-01' } });
    assert.equal((await api.del(`/incomes/${body.id}`, { token: u.token })).status, 204);
    assert.equal((await api.del(`/incomes/${body.id}`, { token: u.token })).status, 404);
  });

  test('CT-EXC-03 excluir despesa: 204 e o saldo volta a subir', async () => {
    const u = await api.novoUsuario('Caio', 'exc-caio@teste.local');
    await api.post('/incomes', { token: u.token, body: { amount: 1000, date: '2026-11-01' } });
    const { body: d } = await api.post('/expenses', { token: u.token, body: { amount: 400, date: '2026-11-02', category_id: u.categorias['expense:Lazer'] } });
    assert.equal((await api.get('/dashboard', { token: u.token })).body.balance, 600);
    assert.equal((await api.del(`/expenses/${d.id}`, { token: u.token })).status, 204);
    assert.equal((await api.get('/dashboard', { token: u.token })).body.balance, 1000);
  });

  test('CT-EXC-04 usuário não consegue excluir lançamento de outro (404) e o dado continua', async () => {
    const a = await api.novoUsuario('Duda', 'exc-duda@teste.local');
    const b = await api.novoUsuario('Enzo', 'exc-enzo@teste.local');
    const { body: d } = await api.post('/expenses', { token: a.token, body: { amount: 50, date: '2026-11-01', category_id: a.categorias['expense:Saúde'] } });
    assert.equal((await api.del(`/expenses/${d.id}`, { token: b.token })).status, 404);
    assert.equal((await api.get('/expenses', { token: a.token })).body.length, 1);
  });

  test('CT-EXC-05 excluir sem token responde 401', async () => {
    assert.equal((await api.del('/incomes/1')).status, 401);
    assert.equal((await api.del('/goals/1')).status, 401);
  });

  test('CT-EXC-06 excluir uma parcela mantém as outras', async () => {
    const u = await api.novoUsuario('Fred', 'exc-fred@teste.local');
    const { body } = await api.post('/expenses', { token: u.token, body: { amount: 300, date: '2026-11-10', category_id: u.categorias['expense:Compras'], parcelas: 3 } });
    assert.equal((await api.del(`/expenses/${body.parcelas[0].id}`, { token: u.token })).status, 204);
    const restantes = (await api.get('/expenses', { token: u.token })).body;
    assert.deepEqual(restantes.map((x) => x.parcela_numero).sort(), [2, 3]);
  });

  test('CT-EXC-07 excluir parcelamento inteiro (DELETE /grupo) remove todas as parcelas', async () => {
    const u = await api.novoUsuario('Gil', 'exc-gil@teste.local');
    const { body } = await api.post('/expenses', { token: u.token, body: { amount: 1200, date: '2026-11-10', category_id: u.categorias['expense:Compras'], parcelas: 12 } });
    await api.post('/expenses', { token: u.token, body: { amount: 30, date: '2026-11-11', category_id: u.categorias['expense:Lazer'] } });
    const r = await api.del(`/expenses/grupo/${body.parcela_grupo}`, { token: u.token });
    assert.equal(r.status, 200);
    assert.equal(r.body.removidas, 12);
    assert.deepEqual((await api.get('/expenses', { token: u.token })).body.map((x) => x.amount), [30]);
  });

  test('CT-EXC-08 excluir parcelamento de outro usuário responde 404 e nada é removido', async () => {
    const a = await api.novoUsuario('Hana', 'exc-hana@teste.local');
    const b = await api.novoUsuario('Ivo', 'exc-ivo@teste.local');
    const { body } = await api.post('/incomes', { token: a.token, body: { amount: 300, date: '2026-11-10', parcelas: 3 } });
    assert.equal((await api.del(`/incomes/grupo/${body.parcela_grupo}`, { token: b.token })).status, 404);
    assert.equal((await api.get('/incomes', { token: a.token })).body.length, 3);
  });

  test('CT-EXC-09 excluir meta: 204, some da listagem; repetir responde 404', async () => {
    const u = await api.novoUsuario('Jade', 'exc-jade@teste.local');
    const { body: g } = await api.post('/goals', { token: u.token, body: { title: 'Celular', target_amount: 2000 } });
    await api.post(`/goals/${g.id}/aportes`, { token: u.token, body: { amount: 500 } });
    assert.equal((await api.del(`/goals/${g.id}`, { token: u.token })).status, 204);
    assert.equal((await api.get('/goals', { token: u.token })).body.length, 0);
    assert.equal((await api.del(`/goals/${g.id}`, { token: u.token })).status, 404);
  });

  test('CT-EXC-10 excluir meta de outro usuário responde 404 e ela continua', async () => {
    const a = await api.novoUsuario('Kai', 'exc-kai@teste.local');
    const b = await api.novoUsuario('Luz', 'exc-luz@teste.local');
    const { body: g } = await api.post('/goals', { token: a.token, body: { title: 'Meta A', target_amount: 100 } });
    assert.equal((await api.del(`/goals/${g.id}`, { token: b.token })).status, 404);
    assert.equal((await api.get('/goals', { token: a.token })).body.length, 1);
  });

  test('CT-EXC-11 categoria em uso não pode ser excluída (409); sem uso é excluída (204)', async () => {
    const u = await api.novoUsuario('Max', 'exc-max@teste.local');
    const emUso = u.categorias['expense:Moradia'];
    await api.post('/expenses', { token: u.token, body: { amount: 900, date: '2026-11-05', category_id: emUso } });
    const r = await api.del(`/categories/${emUso}`, { token: u.token });
    assert.equal(r.status, 409);
    assert.match(r.body.error, /em uso por 1 lançamento/);
    assert.equal((await api.del(`/categories/${u.categorias['expense:Impostos']}`, { token: u.token })).status, 204);
    const nomes = (await api.get('/categories?type=expense', { token: u.token })).body.map((c) => c.name);
    assert.ok(nomes.includes('Moradia') && !nomes.includes('Impostos'));
  });

  test('CT-EXC-12 excluir categoria de receita sem lançamentos e de outro usuário', async () => {
    const a = await api.novoUsuario('Noa', 'exc-noa@teste.local');
    const b = await api.novoUsuario('Ori', 'exc-ori@teste.local');
    assert.equal((await api.del(`/categories/${a.categorias['income:Bônus']}`, { token: b.token })).status, 404);
    assert.equal((await api.del(`/categories/${a.categorias['income:Bônus']}`, { token: a.token })).status, 204);
  });

  test('CT-EXC-13 id inexistente ou não numérico responde 404', async () => {
    const u = await api.novoUsuario('Pam', 'exc-pam@teste.local');
    for (const rota of ['/incomes/99999', '/expenses/abc', '/goals/0', '/categories/99999', '/expenses/grupo/nao-existe']) {
      assert.equal((await api.del(rota, { token: u.token })).status, 404, rota);
    }
  });
});
