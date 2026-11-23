const dbAsync = require('../utils/dbAsync');
const { HttpError, handleError } = require('../utils/validators');
const { periodo, pagina } = require('../utils/paginacao');

const TABELAS = new Map([['receita', 'incomes'], ['despesa', 'expenses']]);

/** Tipos pedidos em ?tipo= (receita | despesa); sem o parâmetro, os dois. */
function tipos(query) {
  if (query.tipo === undefined) return ['receita', 'despesa'];
  if (!TABELAS.has(query.tipo)) throw new HttpError(400, 'tipo deve ser receita ou despesa');
  return [query.tipo];
}

/**
 * GET /lancamentos — extrato paginado de receitas E despesas juntas.
 *
 * Query: ?tipo=receita|despesa, ?month=AAAA-MM, ?from= e ?to= (AAAA-MM-DD),
 *        ?limit= (0 a 1000, padrão 500; 0 = só os totais) e ?offset=.
 *
 * Resposta:
 *   itens           a página pedida, do mais recente para o mais antigo,
 *                   cada um com `tipo` ("receita" ou "despesa")
 *   total           quantos lançamentos o filtro tem ao todo
 *   proximo_offset  offset da próxima página, ou null se esta é a última
 *   receitas, despesas, saldo   somas de TODO o filtro (não só da página)
 *   categorias      [{ tipo, categoria, total }] de todo o filtro (só na 1ª página)
 *
 * Os totais são calculados pelo banco, então o app consegue mostrar o resumo
 * de um período inteiro baixando só a primeira página.
 */
exports.list = async (req, res) => {
  try {
    const ts = tipos(req.query);
    const filtro = periodo(req.query, 't.date');
    const { limit, offset } = pagina(req.query);
    const base = [req.userId, ...filtro.params];

    const somas = Promise.all(ts.map((tipo) => dbAsync.get(
      `SELECT COUNT(*) AS n, ROUND(COALESCE(SUM(t.amount), 0), 2) AS soma
       FROM ${TABELAS.get(tipo)} t WHERE t.user_id = ?${filtro.sql}`, base)));

    const categorias = offset > 0 ? Promise.resolve(null) : Promise.all(ts.map((tipo) => dbAsync.all(
      `SELECT '${tipo}' AS tipo, COALESCE(c.name, 'Sem categoria') AS categoria,
              ROUND(SUM(t.amount), 2) AS total
       FROM ${TABELAS.get(tipo)} t LEFT JOIN categories c ON c.id = t.category_id
       WHERE t.user_id = ?${filtro.sql}
       GROUP BY c.name ORDER BY total DESC`, base))).then((ls) => ls.flat());

    // Cada tabela devolve no máximo offset + limit linhas já ordenadas pelo
    // índice; a união só ordena essas e corta a página.
    const itens = limit === 0 ? Promise.resolve([]) : dbAsync.all(
      `SELECT * FROM (${ts.map((tipo) => `SELECT * FROM (
          SELECT t.*, c.name AS category_name, '${tipo}' AS tipo
          FROM ${TABELAS.get(tipo)} t LEFT JOIN categories c ON c.id = t.category_id
          WHERE t.user_id = ?${filtro.sql}
          ORDER BY t.date DESC, t.id DESC LIMIT ?)`).join(' UNION ALL ')})
       ORDER BY date DESC, tipo DESC, id DESC
       LIMIT ? OFFSET ?`,
      [...ts.flatMap(() => [...base, offset + limit]), limit, offset]);

    const [s, cats, linhas] = await Promise.all([somas, categorias, itens]);
    const total = s.reduce((acc, r) => acc + r.n, 0);
    const soma = (tipo) => (ts.includes(tipo) ? s[ts.indexOf(tipo)].soma : 0);
    const receitas = soma('receita');
    const despesas = soma('despesa');

    res.json({
      itens: linhas,
      total,
      proximo_offset: limit > 0 && offset + linhas.length < total ? offset + linhas.length : null,
      receitas,
      despesas,
      saldo: Math.round((receitas - despesas) * 100) / 100 || 0,
      ...(cats ? { categorias: cats } : {}),
    });
  } catch (err) {
    handleError(res, err);
  }
};

/**
 * GET /lancamentos/meses — meses (AAAA-MM) que têm algum lançamento, do mais
 * recente para o mais antigo. Serve para o seletor de mês do app sem precisar
 * baixar os lançamentos.
 */
exports.meses = async (req, res) => {
  try {
    const rows = await dbAsync.all(
      `SELECT DISTINCT substr(date, 1, 7) AS mes FROM incomes WHERE user_id = ?
       UNION
       SELECT DISTINCT substr(date, 1, 7) AS mes FROM expenses WHERE user_id = ?
       ORDER BY mes DESC`,
      [req.userId, req.userId]
    );
    res.json(rows.map((r) => r.mes));
  } catch (err) {
    handleError(res, err);
  }
};
