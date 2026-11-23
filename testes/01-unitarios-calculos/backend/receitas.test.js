const { describe, test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { controller, seed, chamar, dbAsync, U1, U2, CAT } = require('./helpers');

const receitas = controller('incomeController.js');
const dashboard = controller('dashboardController.js');

const criar = (body, userId = U1) => chamar(receitas.create, { userId, body });
const totalReceitas = async (query = {}) =>
  (await chamar(dashboard.summary, { query })).body.total_incomes;

describe('Receitas (POST/GET/PUT/DELETE /incomes)', () => {
  beforeEach(seed);

  test('CT-REC-01 cria receita válida e ela entra no total', async () => {
    const r = await criar({ amount: 4500.9, date: '2026-11-05', category_id: CAT.salario, description: 'Salário' });
    assert.equal(r.status, 201);
    assert.equal(r.body.amount, 4500.9);
    const row = await dbAsync.get('SELECT * FROM incomes WHERE id = ?', [r.body.id]);
    assert.equal(row.amount, 4500.9);
    assert.equal(row.user_id, U1);
    assert.equal(await totalReceitas(), 4500.9);
  });

  test('CT-REC-02 receita sem categoria é aceita (categoria opcional)', async () => {
    const r = await criar({ amount: 200, date: '2026-11-05' });
    assert.equal(r.status, 201);
    assert.equal(r.body.category_id, null);
  });

  test('CT-REC-03 valor zero, negativo, texto ou infinito é rejeitado', async () => {
    for (const amount of [0, -10, '100', Infinity, NaN]) {
      const r = await criar({ amount, date: '2026-11-05' });
      assert.equal(r.status, 400, `amount=${String(amount)} deveria dar 400`);
    }
    assert.equal(await totalReceitas(), 0);
  });

  test('CT-REC-04 valor ou data ausentes são rejeitados', async () => {
    assert.equal((await criar({ date: '2026-11-05' })).status, 400);
    assert.equal((await criar({ amount: 10 })).status, 400);
  });

  test('CT-REC-05 data inexistente ou fora do formato é rejeitada', async () => {
    for (const date of ['2026-02-30', '2026-13-01', '07/11/2026', '2026-1-5']) {
      const r = await criar({ amount: 10, date });
      assert.equal(r.status, 400, `date=${date} deveria dar 400`);
    }
  });

  test('CT-REC-06 categoria de despesa não pode ser usada em receita', async () => {
    const r = await criar({ amount: 10, date: '2026-11-05', category_id: CAT.aluguel });
    assert.equal(r.status, 400);
    assert.match(r.body.error, /não é de receita/);
  });

  test('CT-REC-07 categoria de outro usuário é rejeitada', async () => {
    const r = await criar({ amount: 10, date: '2026-11-05', category_id: CAT.u2Receita });
    assert.equal(r.status, 400);
  });

  test('CT-REC-08 receita parcelada divide o total sem perder centavos (R$ 1.000 em 3x)', async () => {
    const r = await criar({ amount: 1000, date: '2026-11-10', category_id: CAT.freela, parcelas: 3 });
    assert.equal(r.status, 201);
    assert.deepEqual(r.body.parcelas.map((p) => p.amount), [333.34, 333.33, 333.33]);
    assert.deepEqual(r.body.parcelas.map((p) => p.date), ['2026-11-10', '2026-12-10', '2027-01-10']);
    const soma = await dbAsync.get(
      'SELECT ROUND(SUM(amount), 2) AS s, COUNT(*) AS n FROM incomes WHERE parcela_grupo = ?',
      [r.body.parcela_grupo]
    );
    assert.equal(soma.n, 3);
    assert.equal(soma.s, 1000);
  });

  test('CT-REC-09 listagem por mês retorna só as receitas daquele mês', async () => {
    await criar({ amount: 100, date: '2026-10-31' });
    await criar({ amount: 200, date: '2026-11-01' });
    await criar({ amount: 300, date: '2026-11-30' });
    const r = await chamar(receitas.list, { query: { month: '2026-11' } });
    assert.equal(r.status, 200);
    assert.deepEqual(r.body.map((x) => x.amount), [300, 200]);
    assert.equal(await totalReceitas({ month: '2026-11' }), 500);
  });

  test('CT-REC-10 editar o valor atualiza o total de receitas', async () => {
    const { body } = await criar({ amount: 100, date: '2026-11-05' });
    const r = await chamar(receitas.update, { params: { id: body.id }, body: { amount: 250.5 } });
    assert.equal(r.status, 200);
    assert.equal(await totalReceitas(), 250.5);
  });

  test('CT-REC-11 excluir receita de outro usuário retorna 404 e não remove', async () => {
    const { body } = await criar({ amount: 100, date: '2026-11-05' });
    const r = await chamar(receitas.remove, { userId: U2, params: { id: body.id } });
    assert.equal(r.status, 404);
    assert.equal(await totalReceitas(), 100);
  });

  test('CT-REC-12 excluir a própria receita tira o valor do total', async () => {
    const { body } = await criar({ amount: 100, date: '2026-11-05' });
    await criar({ amount: 50, date: '2026-11-06' });
    const r = await chamar(receitas.remove, { params: { id: body.id } });
    assert.equal(r.status, 204);
    assert.equal(await totalReceitas(), 50);
  });
});
