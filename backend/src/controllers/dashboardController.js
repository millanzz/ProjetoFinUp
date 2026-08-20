const db = require('../database/db');

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

  // filtro de mês opcional (strftime('%Y-%m', date))
  const monthFilter = month ? ` AND strftime('%Y-%m', date) = ?` : '';
  const monthParams = month ? [month] : [];

  const queries = {
    totalIncomes: {
      sql: `SELECT COALESCE(SUM(amount), 0) AS total FROM incomes
            WHERE user_id = ?${monthFilter}`,
      params: [userId, ...monthParams]
    },
    totalExpenses: {
      sql: `SELECT COALESCE(SUM(amount), 0) AS total FROM expenses
            WHERE user_id = ?${monthFilter}`,
      params: [userId, ...monthParams]
    },
    expensesByCategory: {
      sql: `SELECT COALESCE(c.name, 'Sem categoria') AS category,
                   SUM(e.amount) AS total
            FROM expenses e
            LEFT JOIN categories c ON c.id = e.category_id
            WHERE e.user_id = ?${monthFilter.replace('date', 'e.date')}
            GROUP BY c.name
            ORDER BY total DESC`,
      params: [userId, ...monthParams]
    },
    incomesByCategory: {
      sql: `SELECT COALESCE(c.name, 'Sem categoria') AS category,
                   SUM(i.amount) AS total
            FROM incomes i
            LEFT JOIN categories c ON c.id = i.category_id
            WHERE i.user_id = ?${monthFilter.replace('date', 'i.date')}
            GROUP BY c.name
            ORDER BY total DESC`,
      params: [userId, ...monthParams]
    },
    monthly: {
      sql: `SELECT month, SUM(incomes) AS incomes, SUM(expenses) AS expenses
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
      res.status(500).json({ error: err.message });
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
      balance: result.totalIncomes - result.totalExpenses,
      total_incomes: result.totalIncomes,
      total_expenses: result.totalExpenses,
      expenses_by_category: result.expensesByCategory,
      incomes_by_category: result.incomesByCategory,
      monthly: result.monthly
    });
  }
};
