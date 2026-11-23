/**
 * Cria, pela API em HTTPS, o usuário e alguns lançamentos usados no teste da
 * versão Web (navegadores.js entra como compat@teste.local).
 * Uso: NODE_TLS_REJECT_UNAUTHORIZED=0 node semear-https.js https://127.0.0.1:3443
 */
const BASE = process.argv[2];
const chamar = (rota, { metodo = 'GET', corpo, token } = {}) =>
  fetch(BASE + rota, {
    method: metodo,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: corpo ? JSON.stringify(corpo) : undefined,
  }).then(async (r) => ({ status: r.status, body: await r.json().catch(() => null) }));

(async () => {
  await chamar('/users', { metodo: 'POST', corpo: { name: 'Maria Aparecida dos Santos Albuquerque', email: 'compat@teste.local', password: 'senha123' } });
  const token = (await chamar('/auth/login', { metodo: 'POST', corpo: { email: 'compat@teste.local', password: 'senha123' } })).body.token;
  const cats = (await chamar('/categories?type=expense', { token })).body;
  const mes = new Date().toISOString().slice(0, 7);
  await chamar('/incomes', { metodo: 'POST', token, corpo: { amount: 4500, date: `${mes}-05`, description: 'Salário' } });
  await chamar('/expenses', { metodo: 'POST', token, corpo: { amount: 1200, date: `${mes}-06`, description: 'Aluguel', category_id: cats.find((c) => c.name === 'Moradia').id } });
  console.log('dados criados pela API em HTTPS');
})();
