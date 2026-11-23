const { describe, test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { controller, seed, chamar, dbAsync, U1, CAT } = require('./helpers');

const despesas = controller('expenseController.js');
const dashboard = controller('dashboardController.js');

const criar = (body, userId = U1) => chamar(despesas.create, { userId, body });
const totalDespesas = async (query = {}) =>
  (await chamar(dashboard.summary, { query })).body.total_expenses;

describe('Despesas (POST/GET/PUT/DELETE /expenses)', () => {
  beforeEach(seed);

  test('CT-DES-01 cria despesa válida e ela entra no total', async () => {
    const r = await criar({ amount: 1250.75, date: '2026-11-05', category_id: CAT.aluguel });
    assert.equal(r.status, 201);
    assert.equal(await totalDespesas(), 1250.75);
  });

  test('CT-DES-02 despesa sem categoria é rejeitada (categoria obrigatória)', async () => {
    const r = await criar({ amount: 10, date: '2026-11-05' });
    assert.equal(r.status, 400);
    assert.match(r.body.error, /category_id é obrigatório/);
  });

  test('CT-DES-03 categoria de receita não pode ser usada em despesa', async () => {
    const r = await criar({ amount: 10, date: '2026-11-05', category_id: CAT.salario });
    assert.equal(r.status, 400);
    assert.match(r.body.error, /não é de despesa/);
  });

  test('CT-DES-04 valor inválido é rejeitado e nada é gravado', async () => {
    for (const amount of [0, -0.01, '50', null]) {
      const r = await criar({ amount, date: '2026-11-05', category_id: CAT.mercado });
      assert.equal(r.status, 400, `amount=${String(amount)} deveria dar 400`);
    }
    assert.equal(await totalDespesas(), 0);
  });

  test('CT-DES-05 parcelamento de R$ 100 em 3x: centavos e datas de fim de mês', async () => {
    const r = await criar({ amount: 100, date: '2026-01-31', category_id: CAT.mercado, parcelas: 3 });
    assert.equal(r.status, 201);
    assert.deepEqual(r.body.parcelas.map((p) => p.amount), [33.34, 33.33, 33.33]);
    assert.deepEqual(r.body.parcelas.map((p) => p.date), ['2026-01-31', '2026-02-28', '2026-03-31']);
    assert.equal(await totalDespesas(), 100);
  });

  test('CT-DES-06 parcelamento cruza ano bissexto (31/01/2028 → 29/02/2028)', async () => {
    const r = await criar({ amount: 50, date: '2028-01-31', category_id: CAT.mercado, parcelas: 2 });
    assert.deepEqual(r.body.parcelas.map((p) => p.date), ['2028-01-31', '2028-02-29']);
    assert.deepEqual(r.body.parcelas.map((p) => p.amount), [25, 25]);
  });

  test('CT-DES-07 parcelas em 12x de R$ 1.999,99 somam exatamente o total', async () => {
    const r = await criar({ amount: 1999.99, date: '2026-11-15', category_id: CAT.mercado, parcelas: 12 });
    assert.equal(r.status, 201);
    const centavos = r.body.parcelas.reduce((s, p) => s + Math.round(p.amount * 100), 0);
    assert.equal(centavos, 199999);
    assert.equal(r.body.parcelas[0].amount, 166.73);
    assert.ok(r.body.parcelas.slice(1).every((p) => p.amount === 166.66));
  });

  test('CT-DES-08 número de parcelas fora do limite (0, 49, 2.5) é rejeitado', async () => {
    for (const parcelas of [0, 49, 2.5, -3]) {
      const r = await criar({ amount: 100, date: '2026-11-05', category_id: CAT.mercado, parcelas });
      assert.equal(r.status, 400, `parcelas=${parcelas} deveria dar 400`);
    }
    assert.equal(await totalDespesas(), 0);
  });

  test('CT-DES-09 valor pequeno demais para as parcelas (R$ 0,05 em 10x) é rejeitado', async () => {
    const r = await criar({ amount: 0.05, date: '2026-11-05', category_id: CAT.mercado, parcelas: 10 });
    assert.equal(r.status, 400);
  });

  test('CT-DES-10 excluir o grupo remove todas as parcelas e zera o total', async () => {
    const { body } = await criar({ amount: 600, date: '2026-11-05', category_id: CAT.mercado, parcelas: 6 });
    const r = await chamar(despesas.removeGrupo, { params: { grupo: body.parcela_grupo } });
    assert.equal(r.status, 200);
    assert.equal(r.body.removidas, 6);
    assert.equal(await totalDespesas(), 0);
  });

  test('CT-DES-11 edição com valor inválido é rejeitada e o valor original é mantido', async () => {
    const { body } = await criar({ amount: 80, date: '2026-11-05', category_id: CAT.mercado });
    const r = await chamar(despesas.update, { params: { id: body.id }, body: { amount: -80 } });
    assert.equal(r.status, 400);
    assert.equal(await totalDespesas(), 80);
  });

  test('CT-DES-12 editar data move a despesa de mês no total mensal', async () => {
    const { body } = await criar({ amount: 80, date: '2026-11-05', category_id: CAT.mercado });
    await chamar(despesas.update, { params: { id: body.id }, body: { date: '2026-12-05' } });
    assert.equal(await totalDespesas({ month: '2026-11' }), 0);
    assert.equal(await totalDespesas({ month: '2026-12' }), 80);
  });
});
