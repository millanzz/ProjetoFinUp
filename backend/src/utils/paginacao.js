const { HttpError, isValidDate, isValidMonth } = require('./validators');

/** Tamanho de página quando o cliente não informa `limit`. */
const LIMITE_PADRAO = 500;
/** Maior página aceita. */
const LIMITE_MAXIMO = 1000;

/** Primeiro dia do mês seguinte a "AAAA-MM" (também no formato AAAA-MM-DD). */
function inicioDoMesSeguinte(mes) {
  const [a, m] = mes.split('-').map(Number);
  const ano = m === 12 ? a + 1 : a;
  const proximo = m === 12 ? 1 : m + 1;
  return `${ano}-${String(proximo).padStart(2, '0')}-01`;
}

/**
 * Lê o período da query string e devolve o trecho SQL de filtro por data.
 *
 *   ?month=AAAA-MM          só aquele mês
 *   ?from=AAAA-MM-DD        a partir do dia (inclusive)
 *   ?to=AAAA-MM-DD          até o dia (inclusive)
 *
 * O filtro é feito por FAIXA de datas (date >= ? AND date < ?), e não com
 * strftime('%Y-%m', date) = ?, para o SQLite poder usar o índice
 * (user_id, date, ...) em vez de ler todos os lançamentos do usuário.
 *
 * @param {object} query  req.query
 * @param {string} coluna nome qualificado da coluna de data (ex.: "t.date")
 */
function periodo(query, coluna = 'date') {
  const { month, from, to } = query;
  const partes = [];
  const params = [];

  if (month !== undefined) {
    if (!isValidMonth(month)) throw new HttpError(400, 'month deve estar no formato AAAA-MM');
    partes.push(`${coluna} >= ?`, `${coluna} < ?`);
    params.push(`${month}-01`, inicioDoMesSeguinte(month));
  }
  if (from !== undefined) {
    if (!isValidDate(from)) throw new HttpError(400, 'from deve estar no formato AAAA-MM-DD');
    partes.push(`${coluna} >= ?`);
    params.push(from);
  }
  if (to !== undefined) {
    if (!isValidDate(to)) throw new HttpError(400, 'to deve estar no formato AAAA-MM-DD');
    // date guarda só AAAA-MM-DD; "<= to" inclui o próprio dia
    partes.push(`${coluna} <= ?`);
    params.push(to);
  }

  return { sql: partes.map((p) => ` AND ${p}`).join(''), params };
}

/** Inteiro não negativo vindo da query string, ou o padrão. */
function inteiro(valor, nome, padrao) {
  if (valor === undefined) return padrao;
  if (!/^\d+$/.test(String(valor))) {
    throw new HttpError(400, `${nome} deve ser um número inteiro não negativo`);
  }
  return Number(valor);
}

/**
 * Lê `limit` e `offset`. `limit` vai de 0 a LIMITE_MAXIMO (0 = só os totais,
 * sem itens); o padrão é LIMITE_PADRAO.
 */
function pagina(query) {
  const limit = inteiro(query.limit, 'limit', LIMITE_PADRAO);
  const offset = inteiro(query.offset, 'offset', 0);
  if (limit > LIMITE_MAXIMO) throw new HttpError(400, `limit deve ser no máximo ${LIMITE_MAXIMO}`);
  return { limit, offset };
}

module.exports = { LIMITE_PADRAO, LIMITE_MAXIMO, periodo, pagina, inicioDoMesSeguinte };
