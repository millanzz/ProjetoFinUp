const db = require('../database/db');
const { isValidMonth, erroInterno } = require('../utils/validators');
const { inicioDoMesSeguinte } = require('../utils/paginacao');

/**
 * GET /dashboard
 * Retorna o resumo financeiro do usuário logado:
 * saldo, totais, gastos/receitas por categoria e evolução mensal.
 *
 * Query params opcionais:
 *   ?month=2026-07  -> filtra os totais e categorias por mês (YYYY-MM)
 */
exports.summary = (req, res) => {
  const userId = req.userId;
  const { month } = req.query;

  if (month !== undefined && !isValidMonth(month)) {
    return res.status(400).json({ error: 'month deve estar no formato AAAA-MM' });
  }

  // Filtro de mês opcional, por faixa de datas para usar o índice (user_id, date)
  const monthFilter = month ? ` AND date >= ? AND date < ?` : '';
  const monthParams = month ? [`${month}-01`, inicioDoMesSeguinte(month)] : [];

  const queries = {
    totalIncomes: {
      sql: `SELECT ROUND(COALESCE(SUM(amount), 0), 2) AS total FROM incomes
            WHERE user_id = ?${monthFilter}`,
      params: [userId, ...monthParams]
    },
    totalExpenses: {
      sql: `SELECT ROUND(COALESCE(SUM(amount), 0), 2) AS total FROM expenses
            WHERE user_id = ?${monthFilter}`,
      params: [userId, ...monthParams]
    },
    expensesByCategory: {
      sql: `SELECT COALESCE(c.name, 'Sem categoria') AS category,
                   ROUND(SUM(e.amount), 2) AS total
            FROM expenses e
            LEFT JOIN categories c ON c.id = e.category_id
            WHERE e.user_id = ?${monthFilter.replace(/date/g, 'e.date')}
            GROUP BY c.name
            ORDER BY total DESC`,
      params: [userId, ...monthParams]
    },
    incomesByCategory: {
      sql: `SELECT COALESCE(c.name, 'Sem categoria') AS category,
                   ROUND(SUM(i.amount), 2) AS total
            FROM incomes i
            LEFT JOIN categories c ON c.id = i.category_id
            WHERE i.user_id = ?${monthFilter.replace(/date/g, 'i.date')}
            GROUP BY c.name
            ORDER BY total DESC`,
      params: [userId, ...monthParams]
    },
    monthly: {
      sql: `SELECT month, ROUND(SUM(incomes), 2) AS incomes, ROUND(SUM(expenses), 2) AS expenses
            FROM (
              SELECT strftime('%Y-%m', date) AS month, amount AS incomes, 0 AS expenses
              FROM incomes WHERE user_id = ?
              UNION ALL
              SELECT strftime('%Y-%m', date) AS month, 0 AS incomes, amount AS expenses
              FROM expenses WHERE user_id = ?
            )
            GROUP BY month
            ORDER BY month ASC`,
      params: [userId, userId]
    }
  };

  const result = {};
  const keys = Object.keys(queries);
  let pending = keys.length;
  let responded = false;

  const fail = (err) => {
    if (!responded) {
      responded = true;
      erroInterno(res, err);
    }
  };

  keys.forEach((key) => {
    const { sql, params } = queries[key];

    if (key === 'totalIncomes' || key === 'totalExpenses') {
      db.get(sql, params, (err, row) => {
        if (err) return fail(err);
        result[key] = row.total;
        if (--pending === 0) finish();
      });
    } else {
      db.all(sql, params, (err, rows) => {
        if (err) return fail(err);
        result[key] = rows;
        if (--pending === 0) finish();
      });
    }
  });

  function finish() {
    if (responded) return;
    responded = true;
    res.json({
      // Somas e saldo arredondados para centavos (DEF-01): antes 0,10 + 0,20 − 0,30
      // dava 5,55e-17 em vez de 0.
      balance: Math.round((result.totalIncomes - result.totalExpenses) * 100) / 100 || 0,
      total_incomes: result.totalIncomes,
      total_expenses: result.totalExpenses,
      expenses_by_category: result.expensesByCategory,
      incomes_by_category: result.incomesByCategory,
      monthly: result.monthly
    });
  }
};
