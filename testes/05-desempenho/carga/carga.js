/**
 * Teste de CARGA da API do FinUp com usuários virtuais simultâneos.
 * Uso: node carga.js <usuarios> <segundos> <saida.json> [porta]
 *
 * Cada usuário virtual faz o mesmo caminho do app:
 *   1. POST /auth/login (uma vez, ao "abrir o app")
 *   2. repete até acabar o tempo:
 *        GET /incomes · GET /expenses · GET /goals · GET /dashboard?month   (o que o app carrega)
 *        POST /expenses (nova despesa) · DELETE /expenses/:id (exclui a mesma)
 *        pausa de 1 s (tempo de "pensar" do usuário)
 * Todas as requisições são registradas: rota, status, tempo e erro.
 * Falha = erro de rede/tempo esgotado (15 s) ou status diferente do esperado.
 */
const fs = require('fs');

const [usuarios, segundos, saida, porta = '3999'] = process.argv.slice(2);
const N = Number(usuarios);
const DURACAO = Number(segundos) * 1000;
const API = `http://127.0.0.1:${porta}`;
const MES = new Date().toISOString().slice(0, 7);
const CONTAS = ['perf@teste.local', ...Array.from({ length: 50 }, (_, i) => `outro${i + 1}@teste.local`)];
const registros = [];
const esperar = (ms) => new Promise((r) => setTimeout(r, ms));

async function chamar(rota, nome, metodo, esperado, { token, body } = {}) {
  const t0 = performance.now();
  let status = 0, erro = null, json = null;
  try {
    const r = await fetch(API + rota, {
      method: metodo,
      headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
      body: body ? JSON.stringify(body) : undefined,
      signal: AbortSignal.timeout(15000),
    });
    status = r.status;
    const txt = await r.text();
    if (txt) { try { json = JSON.parse(txt); } catch { /* corpo não JSON */ } }
    if (status !== esperado) erro = `HTTP ${status}`;
  } catch (e) {
    erro = e.name === 'TimeoutError' ? 'tempo esgotado (15 s)' : `rede: ${e.message}`;
  }
  registros.push({ rota: nome, ms: performance.now() - t0, status, erro, t: Date.now() });
  return json;
}

async function usuarioVirtual(i, fim) {
  await esperar(Math.random() * 2000); // usuários chegam ao longo de 2 s
  const email = CONTAS[i % CONTAS.length];
  const login = await chamar('/auth/login', 'POST /auth/login', 'POST', 200, { body: { email, password: 'senha123' } });
  const token = login && login.token;
  if (!token) return;
  let cat = null;
  while (Date.now() < fim) {
    await chamar('/incomes', 'GET /incomes', 'GET', 200, { token });
    const desp = await chamar('/expenses', 'GET /expenses', 'GET', 200, { token });
    await chamar('/goals', 'GET /goals', 'GET', 200, { token });
    await chamar(`/dashboard?month=${MES}`, 'GET /dashboard', 'GET', 200, { token });
    if (!cat && Array.isArray(desp) && desp.length) cat = desp[0].category_id;
    if (cat) {
      const nova = await chamar('/expenses', 'POST /expenses', 'POST', 201, {
        token, body: { amount: 12.34, date: `${MES}-15`, description: `carga ${i}`, category_id: cat },
      });
      if (nova && nova.id) await chamar(`/expenses/${nova.id}`, 'DELETE /expenses/:id', 'DELETE', 204, { token });
    }
    await esperar(1000);
  }
}

function stats(lista) {
  const ms = lista.map((r) => r.ms).sort((a, b) => a - b);
  if (!ms.length) return null;
  const q = (p) => ms[Math.min(ms.length - 1, Math.ceil((p / 100) * ms.length) - 1)];
  const r1 = (x) => Math.round(x * 10) / 10;
  const falhas = lista.filter((r) => r.erro).length;
  return {
    requisicoes: lista.length, falhas, taxa_falha_pct: r1((100 * falhas) / lista.length),
    media_ms: r1(ms.reduce((a, b) => a + b, 0) / ms.length), mediana_ms: r1(q(50)), p95_ms: r1(q(95)),
    min_ms: r1(ms[0]), max_ms: r1(ms[ms.length - 1]),
  };
}

(async () => {
  const inicio = Date.now();
  const fim = inicio + DURACAO;
  await Promise.all(Array.from({ length: N }, (_, i) => usuarioVirtual(i, fim)));
  const total = (Date.now() - inicio) / 1000;
  const rotas = [...new Set(registros.map((r) => r.rota))];
  const erros = {};
  for (const r of registros) if (r.erro) erros[r.erro] = (erros[r.erro] || 0) + 1;
  const res = {
    usuarios: N, duracao_s: Math.round(total * 10) / 10, medido_em: new Date(inicio).toISOString(),
    geral: { ...stats(registros), throughput_rps: Math.round((registros.length / total) * 10) / 10 },
    sem_login: stats(registros.filter((r) => r.rota !== 'POST /auth/login')),
    por_rota: Object.fromEntries(rotas.map((n) => [n, stats(registros.filter((r) => r.rota === n))])),
    tipos_de_erro: erros,
  };
  fs.writeFileSync(saida, JSON.stringify(res, null, 2));
  const g = res.geral;
  console.log(`${N} usuários · ${g.requisicoes} req em ${res.duracao_s}s · ${g.throughput_rps} req/s · média ${g.media_ms} ms · p95 ${g.p95_ms} ms · falhas ${g.falhas} (${g.taxa_falha_pct}%)`);
})();
