/**
 * Junta os resultados de todos os cenários em tabelas (Markdown) e num CSV.
 * Uso: node consolidar.js <pasta-resultados>  > resultados.md
 */
const fs = require('fs');
const path = require('path');

const RES = path.resolve(process.argv[2]);
const CENARIOS = ['V1', 'V2', 'V3', 'V4', 'C1', 'C2'];
const ler = (f) => (fs.existsSync(path.join(RES, f)) ? JSON.parse(fs.readFileSync(path.join(RES, f), 'utf8')) : null);
const fmt = (n) => (n == null ? '—' : Number(n).toLocaleString('pt-BR', { maximumFractionDigits: 1 }));

// Critérios de aceitação (ver relatório, seção 3)
const LIMITE = { leitura: 500, escrita: 300, login: 1000 };
const marca = (rota, p95) => {
  const lim = rota.startsWith('POST /auth') ? LIMITE.login : rota.startsWith('GET') ? LIMITE.leitura : LIMITE.escrita;
  return p95 <= lim ? '✅' : '❌';
};

const banco = Object.fromEntries(CENARIOS.map((c) => [c, ler(`banco-${c}.json`)]));
const api = Object.fromEntries(CENARIOS.map((c) => [c, ler(`api-${c}.json`)]));
const app = Object.fromEntries(CENARIOS.map((c) => [c, ler(`app-${c}.json`)]));
const out = [];
const csv = ['cenario,camada,medida,mediana_ms,p95_ms,kb'];

out.push('## Cenários\n', '| Cenário | Lançamentos do usuário | Lançamentos no banco | Tamanho do banco |', '|---|---:|---:|---:|');
for (const c of CENARIOS) if (banco[c]) out.push(`| ${c} | ${fmt(banco[c].lancamentos_usuario)} | ${fmt(banco[c].lancamentos_banco)} | ${fmt(banco[c].tamanho_mb)} MB |`);

out.push('\n## API — p95 (ms) por rota e cenário\n');
const rotas = api.V1 ? api.V1.rotas.map((r) => r.rota) : [];
out.push(`| Rota | ${CENARIOS.join(' | ')} |`, `|---|${CENARIOS.map(() => '---:').join('|')}|`);
for (const rota of rotas) {
  const cel = CENARIOS.map((c) => {
    const r = api[c]?.rotas.find((x) => x.rota === rota);
    if (!r) return '—';
    csv.push(`${c},api,"${rota}",${r.mediana},${r.p95},${r.kb_resposta}`);
    return `${marca(rota, r.p95)} ${fmt(r.p95)}`;
  });
  out.push(`| \`${rota}\` | ${cel.join(' | ')} |`);
}
out.push(`| \`GET /dashboard\` 20 simultâneos | ${CENARIOS.map((c) => {
  const s = api[c]?.simultaneo; if (!s) return '—';
  csv.push(`${c},api,"GET /dashboard 20 simultaneos",${s.mediana},${s.p95},`);
  return `${s.p95 <= LIMITE.leitura ? '✅' : '❌'} ${fmt(s.p95)}`;
}).join(' | ')} |`);
out.push(`| Vazão com 20 simultâneos (req/s) | ${CENARIOS.map((c) => fmt(api[c]?.simultaneo?.req_por_segundo)).join(' | ')} |`);

out.push('\n## API — mediana (ms) e tamanho da resposta\n');
out.push(`| Rota | ${CENARIOS.map((c) => `${c} mediana`).join(' | ')} | Resposta em V4 |`, `|---|${CENARIOS.map(() => '---:').join('|')}|---:|`);
for (const rota of rotas) {
  out.push(`| \`${rota}\` | ${CENARIOS.map((c) => fmt(api[c]?.rotas.find((x) => x.rota === rota)?.mediana)).join(' | ')} | ${fmt(api.V4?.rotas.find((x) => x.rota === rota)?.kb_resposta)} KB |`);
}

out.push('\n## App (Flutter, modo debug) — mediana (ms)\n');
const medidas = [
  ['entrar_ms', 'Entrar (login + carregar dados)', 3000],
  ['recarga_mediana_ms', 'Recarregar o cache do app (mês atual em diante)', 2000],
  ['rede_mediana_ms', '  ↳ parte de rede (download do cache)', null],
  ['processamento_mediana_ms', '  ↳ parte de processamento (JSON → modelos)', null],
  ['abrir_inicio_ate_saldo_ms', 'Abrir a Início até mostrar o saldo', 2000],
  ['troca_aba_ate_atualizar_mediana_ms', 'Trocar de aba (até recarregar e redesenhar)', 1000],
  ['historico_tudo_mediana_ms', 'Histórico → filtro "Tudo" (até mostrar a 1ª página e os totais)', 1000],
  ['historico_rolar_pagina_mediana_ms', 'Histórico "Tudo" → carregar mais uma página', 1000],
  ['lancamentos_no_app', 'Lançamentos guardados no aparelho', null],
  ['kb_baixados_por_recarga', 'KB baixados a cada recarga do cache', null],
];
out.push(`| Medida | Limite | ${CENARIOS.join(' | ')} |`, `|---|---:|${CENARIOS.map(() => '---:').join('|')}|`);
for (const [k, nome, lim] of medidas) {
  const cel = CENARIOS.map((c) => {
    const v = app[c]?.[k];
    if (v == null) return '—';
    csv.push(`${c},app,"${nome.trim()}",${v},,`);
    return lim ? `${v <= lim ? '✅' : '❌'} ${fmt(v)}` : fmt(v);
  });
  out.push(`| ${nome} | ${lim ? fmt(lim) : ''} | ${cel.join(' | ')} |`);
}
fs.writeFileSync(path.join(RES, '..', 'resultados.csv'), csv.join('\n') + '\n');
console.log(out.join('\n'));
