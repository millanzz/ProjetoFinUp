const { describe, test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const { controller, seed, chamar, dbAsync, U1, U2 } = require('./helpers');

const metas = controller('goalController.js');

const criar = (body, userId = U1) => chamar(metas.create, { userId, body });
const aportar = (id, amount, userId = U1) =>
  chamar(metas.aportar, { userId, params: { id }, body: { amount } });
const guardado = async (id) =>
  (await dbAsync.get('SELECT current_amount FROM goals WHERE id = ?', [id])).current_amount;

describe('Metas (POST/PATCH/DELETE /goals e aportes)', () => {
  beforeEach(seed);

  test('CT-MET-01 cria meta com valor guardado 0 e ícone padrão', async () => {
    const r = await criar({ title: '  Viagem  ', target_amount: 5000 });
    assert.equal(r.status, 201);
    assert.equal(r.body.title, 'Viagem');
    assert.equal(r.body.current_amount, 0);
    assert.equal(r.body.icon, 'flag');
    assert.equal(await guardado(r.body.id), 0);
  });

  test('CT-MET-02 valor alvo zero, negativo ou texto é rejeitado', async () => {
    for (const target_amount of [0, -1, '500', undefined]) {
      const r = await criar({ title: 'Meta', target_amount });
      assert.equal(r.status, 400, `target_amount=${String(target_amount)} deveria dar 400`);
    }
  });

  test('CT-MET-03 valor guardado inicial negativo é rejeitado', async () => {
    const r = await criar({ title: 'Meta', target_amount: 100, current_amount: -5 });
    assert.equal(r.status, 400);
  });

  test('CT-MET-04 aportes somam ao valor guardado (R$ 200 + R$ 150,50 = R$ 350,50)', async () => {
    const { body } = await criar({ title: 'Notebook', target_amount: 1000 });
    assert.equal((await aportar(body.id, 200)).body.current_amount, 200);
    const r = await aportar(body.id, 150.5);
    assert.equal(r.status, 200);
    assert.equal(r.body.current_amount, 350.5);
  });

  test('CT-MET-05 aporte zero ou negativo é rejeitado e não altera o valor', async () => {
    const { body } = await criar({ title: 'Meta', target_amount: 1000, current_amount: 100 });
    for (const amount of [0, -50, '10']) {
      assert.equal((await aportar(body.id, amount)).status, 400);
    }
    assert.equal(await guardado(body.id), 100);
  });

  test('CT-MET-06 10 aportes simultâneos de R$ 10 resultam em R$ 100 (sem perder nenhum)', async () => {
    const { body } = await criar({ title: 'Reserva', target_amount: 1000 });
    const rs = await Promise.all(Array.from({ length: 10 }, () => aportar(body.id, 10)));
    assert.ok(rs.every((r) => r.status === 200));
    assert.equal(await guardado(body.id), 100);
  });

  test('CT-MET-07 aporte além do alvo é aceito (meta ultrapassada)', async () => {
    const { body } = await criar({ title: 'Meta', target_amount: 1000, current_amount: 900 });
    const r = await aportar(body.id, 300);
    assert.equal(r.status, 200);
    assert.equal(r.body.current_amount, 1200);
  });

  test('CT-MET-08 aporte em meta de outro usuário retorna 404 e não altera', async () => {
    const { body } = await criar({ title: 'Meta', target_amount: 1000, current_amount: 10 });
    assert.equal((await aportar(body.id, 500, U2)).status, 404);
    assert.equal(await guardado(body.id), 10);
  });

  test('CT-MET-09 edição de valores e validação de ícone', async () => {
    const { body } = await criar({ title: 'Carro', target_amount: 30000, icon: 'car' });
    const ok = await chamar(metas.update, { params: { id: body.id }, body: { current_amount: 7500, target_amount: 25000 } });
    assert.equal(ok.status, 200);
    const row = await dbAsync.get('SELECT * FROM goals WHERE id = ?', [body.id]);
    assert.equal(row.current_amount, 7500);
    assert.equal(row.target_amount, 25000);
    const neg = await chamar(metas.update, { params: { id: body.id }, body: { current_amount: -1 } });
    assert.equal(neg.status, 400);
    const ico = await chamar(metas.update, { params: { id: body.id }, body: { icon: '🚗' } });
    assert.equal(ico.status, 400);
  });

  test('CT-MET-10 aportes de centavos somam exato (R$ 0,10 + R$ 0,20 = R$ 0,30)', async () => {
    const { body } = await criar({ title: 'Cofrinho', target_amount: 0.3 });
    await aportar(body.id, 0.1);
    const r = await aportar(body.id, 0.2);
    assert.equal(r.body.current_amount, 0.3, `current_amount veio ${r.body.current_amount}`);
  });
});
