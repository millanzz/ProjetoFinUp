const { describe, test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { controller, seed, chamar, dbAsync, U1, U2, CAT } = require('./helpers');

const dashboard = controller('dashboardController.js');
const despesas = controller('expenseController.js');

async function receita(amount, date, userId = U1, category_id = CAT.salario) {
  await dbAsync.run(
    'INSERT INTO incomes (amount, date, category_id, user_id) VALUES (?, ?, ?, ?)',
    [amount, date, category_id, userId]
  );
}
async function despesa(amount, date, userId = U1, category_id = CAT.aluguel) {
  await dbAsync.run(
    'INSERT INTO expenses (amount, date, category_id, user_id) VALUES (?, ?, ?, ?)',
    [amount, date, category_id, userId]
  );
}
const resumo = (query = {}, userId = U1) => chamar(dashboard.summary, { userId, query });

describe('Cálculo de saldo (GET /dashboard)', () => {
  beforeEach(seed);

  test('CT-SAL-01 usuário sem lançamentos tem saldo e totais zerados', async () => {
    const { status, body } = await resumo();
    assert.equal(status, 200);
    assert.equal(body.balance, 0);
    assert.equal(body.total_incomes, 0);
    assert.equal(body.total_expenses, 0);
  });

  test('CT-SAL-02 saldo = receitas − despesas (R$ 6.500,50 − R$ 1.500,25 = R$ 5.000,25)', async () => {
    await receita(5000, '2026-11-05');
    await receita(1500.5, '2026-11-10', U1, CAT.freela);
    await despesa(1200, '2026-11-06');
    await despesa(300.25, '2026-11-07', U1, CAT.mercado);
    const { body } = await resumo();
    assert.equal(body.total_incomes, 6500.5);
    assert.equal(body.total_expenses, 1500.25);
    assert.equal(body.balance, 5000.25);
  });

  test('CT-SAL-03 saldo negativo quando despesas superam receitas', async () => {
    await receita(1000, '2026-11-01');
    await despesa(1500.75, '2026-11-02');
    const { body } = await resumo();
    assert.equal(body.balance, -500.75);
  });

  test('CT-SAL-04 filtro ?month considera somente o mês pedido', async () => {
    await receita(3000, '2026-10-31');
    await receita(2000, '2026-11-01');
    await despesa(500, '2026-11-30');
    await despesa(800, '2026-12-01');
    const { body } = await resumo({ month: '2026-11' });
    assert.equal(body.total_incomes, 2000);
    assert.equal(body.total_expenses, 500);
    assert.equal(body.balance, 1500);
  });

  test('CT-SAL-05 saldo de um usuário não inclui lançamentos de outro', async () => {
    await receita(1000, '2026-11-01', U1);
    await receita(9999, '2026-11-01', U2, CAT.u2Receita);
    await despesa(7777, '2026-11-01', U2, CAT.u2Despesa);
    const { body } = await resumo();
    assert.equal(body.balance, 1000);
    const outro = await resumo({}, U2);
    assert.equal(outro.body.balance, 2222);
  });

  test('CT-SAL-06 mês em formato inválido é rejeitado com 400', async () => {
    for (const month of ['2026-13', '2026-7', '11/2026', '']) {
      const { status } = await resumo({ month });
      assert.equal(status, 400, `month="${month}" deveria dar 400`);
    }
  });

  test('CT-SAL-07 evolução mensal agrupa receitas e despesas por mês', async () => {
    await receita(1000, '2026-09-10');
    await despesa(400, '2026-09-20');
    await receita(1200, '2026-10-05');
    await despesa(300, '2026-10-06');
    await despesa(200, '2026-10-07');
    const { body } = await resumo();
    assert.deepEqual(body.monthly, [
      { month: '2026-09', incomes: 1000, expenses: 400 },
      { month: '2026-10', incomes: 1200, expenses: 500 },
    ]);
  });

  test('CT-SAL-08 despesas por categoria somam corretamente e vêm em ordem decrescente', async () => {
    await despesa(1200, '2026-11-01', U1, CAT.aluguel);
    await despesa(150, '2026-11-02', U1, CAT.mercado);
    await despesa(250, '2026-11-03', U1, CAT.mercado);
    await receita(500, '2026-11-04', U1, null);
    const { body } = await resumo();
    assert.deepEqual(body.expenses_by_category, [
      { category: 'Aluguel', total: 1200 },
      { category: 'Mercado', total: 400 },
    ]);
    assert.deepEqual(body.incomes_by_category, [{ category: 'Sem categoria', total: 500 }]);
  });

  test('CT-SAL-09 compra parcelada entra no saldo de cada mês pela parcela', async () => {
    await receita(1000, '2026-01-05');
    const r = await chamar(despesas.create, {
      body: { amount: 100, date: '2026-01-31', category_id: CAT.mercado, parcelas: 3 },
    });
    assert.equal(r.status, 201);
    assert.equal((await resumo({ month: '2026-01' })).body.balance, 1000 - 33.34);
    assert.equal((await resumo({ month: '2026-02' })).body.balance, -33.33);
    assert.equal((await resumo({ month: '2026-03' })).body.balance, -33.33);
    assert.equal((await resumo()).body.total_expenses, 100);
  });

  test('CT-SAL-10 saldo exato em centavos (R$ 0,10 + R$ 0,20 − R$ 0,30 = R$ 0,00)', async () => {
    await receita(0.1, '2026-11-01');
    await receita(0.2, '2026-11-02');
    await despesa(0.3, '2026-11-03');
    const { body } = await resumo();
    assert.equal(body.balance, 0, `balance veio ${body.balance} (total_incomes=${body.total_incomes})`);
    assert.equal(body.total_incomes, 0.3, `total_incomes veio ${body.total_incomes}`);
  });

  test('CT-SAL-12 saldo exato em centavos, ordem inversa (R$ 0,30 − (R$ 0,10 + R$ 0,20) = R$ 0,00)', async () => {
    await receita(0.3, '2026-11-01');
    await despesa(0.1, '2026-11-02');
    await despesa(0.2, '2026-11-03');
    const { body } = await resumo();
    assert.equal(body.balance, 0, `balance veio ${body.balance} (total_expenses=${body.total_expenses})`);
  });

  test('CT-SAL-11 saldo exato com muitos lançamentos de centavos (100 × R$ 0,01 − R$ 1,00)', async () => {
    for (let i = 0; i < 100; i++) await receita(0.01, '2026-11-01');
    await despesa(1, '2026-11-02');
    const { body } = await resumo();
    assert.equal(body.balance, 0, `balance veio ${body.balance}`);
  });
});
