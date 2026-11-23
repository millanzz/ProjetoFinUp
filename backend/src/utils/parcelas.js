const crypto = require('crypto');

const MIN_PARCELAS = 2;
const MAX_PARCELAS = 48;

/**
 * Divide o valor total em `n` parcelas, em centavos, sem perder nenhum.
 * A sobra da divisão vai para a primeira parcela.
 *   dividirValor(100, 3) -> [33.34, 33.33, 33.33]
 */
function dividirValor(total, n) {
  const centavos = Math.round(total * 100);
  const base = Math.floor(centavos / n);
  const sobra = centavos - base * n;
  return Array.from({ length: n }, (_, i) => (base + (i === 0 ? sobra : 0)) / 100);
}

/**
 * Datas das parcelas, uma por mês a partir de `dataInicial` (AAAA-MM-DD).
 * Se o dia não existe no mês (ex.: 31 em fevereiro), usa o último dia.
 *   datasParcelas('2026-01-31', 3) -> ['2026-01-31', '2026-02-28', '2026-03-31']
 */
function datasParcelas(dataInicial, n) {
  const [ano, mes, dia] = dataInicial.split('-').map(Number);
  const datas = [];
  for (let i = 0; i < n; i++) {
    const m0 = mes - 1 + i; // mês zero-based, pode passar de 11
    const a = ano + Math.floor(m0 / 12);
    const m = (m0 % 12) + 1;
    const ultimoDia = new Date(Date.UTC(a, m, 0)).getUTCDate();
    const d = Math.min(dia, ultimoDia);
    datas.push(`${a}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`);
  }
  return datas;
}

const novoGrupo = () => crypto.randomUUID();

module.exports = { MIN_PARCELAS, MAX_PARCELAS, dividirValor, datasParcelas, novoGrupo };
