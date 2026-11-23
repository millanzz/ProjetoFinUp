/**
 * Mede o tempo de resposta da API (rodando em outro processo) para um cenário.
 * Uso: node medir-api.js <cenario> <arquivo-saida.json> [porta]
 *
 * Para cada rota: 3 chamadas de aquecimento + N chamadas medidas, uma de cada
 * vez (sem concorrência). Depois, uma rodada de 20 usuários simultâneos.
 * O tempo é medido no cliente: do envio da requisição até o fim do corpo.
 */
const fs = require('fs');

const [cenario, saida, porta = '3999'] = process.argv.slice(2);
const API = `http://127.0.0.1:${porta}`;
const MEDICOES = 20;

async function chamar(metodo, rota, { body, token } = {}) {
  const t0 = process.hrtime.bigint();
  const r = await fetch(API + rota, {
    method: metodo,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  const buf = Buffer.from(await r.arrayBuffer());
  const ms = Number(process.hrtime.bigint() - t0) / 1e6;
  return { ms, status: r.status, bytes: buf.length, json: buf.length ? JSON.parse(buf) : null };
}

function estatisticas(tempos) {
  const o = [...tempos].sort((a, b) => a - b);
  const q = (p) => o[Math.min(o.length - 1, Math.ceil((p / 100) * o.length) - 1)];
  const r = (x) => Math.round(x * 10) / 10;
  return { n: o.length, min: r(o[0]), mediana: r(q(50)), p95: r(q(95)), max: r(o[o.length - 1]), media: r(o.reduce((a, b) => a + b, 0) / o.length) };
}

async function medir(nome, fazer, { aquecimento = 3, n = MEDICOES } = {}) {
  for (let i = 0; i < aquecimento; i++) await fazer(i);
  const tempos = [];
  let bytes = 0;
  let status;
  for (let i = 0; i < n; i++) {
    const r = await fazer(i);
    tempos.push(r.ms);
    bytes = r.bytes;
    status = r.status;
  }
  const e = estatisticas(tempos);
  console.log(`  ${nome.padEnd(34)} mediana ${String(e.mediana).padStart(8)} ms   p95 ${String(e.p95).padStart(8)} ms   ${(bytes / 1024).toFixed(1).padStart(9)} KB   (HTTP ${status})`);
  return { rota: nome, ...e, kb_resposta: Math.round((bytes / 1024) * 10) / 10, status };
}

(async () => {
  const mes = new Date().toISOString().slice(0, 7);
  const resultados = [];
  console.log(`Cenário ${cenario}`);

  resultados.push(await medir('POST /auth/login', () =>
    chamar('POST', '/auth/login', { body: { email: 'perf@teste.local', password: 'senha123' } }), { aquecimento: 1, n: 10 }));
  const token = (await chamar('POST', '/auth/login', { body: { email: 'perf@teste.local', password: 'senha123' } })).json.token;
  const cat = (await chamar('GET', '/categories?type=expense', { token })).json[0].id;

  for (const rota of ['/dashboard', `/dashboard?month=${mes}`, '/incomes', '/expenses', `/expenses?month=${mes}`, '/goals', '/categories']) {
    resultados.push(await medir(`GET ${rota.replace(mes, 'AAAA-MM')}`, () => chamar('GET', rota, { token })));
  }

  // Escrita: cria, edita e exclui (o volume do cenário não muda no fim)
  const criados = [];
  resultados.push(await medir('POST /expenses', async (i) => {
    const r = await chamar('POST', '/expenses', { token, body: { amount: 10 + i, date: `${mes}-15`, description: 'medição', category_id: cat } });
    criados.push(r.json.id);
    return r;
  }));
  resultados.push(await medir('PUT /expenses/:id', (i) =>
    chamar('PUT', `/expenses/${criados[i]}`, { token, body: { amount: 99.9 } })));
  resultados.push(await medir('DELETE /expenses/:id', (i) =>
    chamar('DELETE', `/expenses/${criados.shift()}`, { token })));

  // Carga simultânea: 20 usuários pedem o dashboard ao mesmo tempo (5 rodadas)
  const simultaneos = [];
  const t0 = Date.now();
  for (let rodada = 0; rodada < 5; rodada++) {
    const rs = await Promise.all(Array.from({ length: 20 }, () => chamar('GET', '/dashboard', { token })));
    simultaneos.push(...rs.map((r) => r.ms));
  }
  const total = (Date.now() - t0) / 1000;
  const conc = { rota: 'GET /dashboard (20 simultâneos × 5)', ...estatisticas(simultaneos), req_por_segundo: Math.round(100 / total) };
  console.log(`  ${conc.rota.padEnd(34)} mediana ${String(conc.mediana).padStart(8)} ms   p95 ${String(conc.p95).padStart(8)} ms   ${conc.req_por_segundo} req/s`);

  fs.writeFileSync(saida, JSON.stringify({ cenario, medido_em: new Date().toISOString(), rotas: resultados, simultaneo: conc }, null, 2));
})().catch((e) => { console.error(e); process.exit(1); });
