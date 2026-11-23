const db = require('../database/db');
const dbAsync = require('../utils/dbAsync');
const { HttpError, handleError, erroInterno, isTexto } = require('../utils/validators');

// POST /categories
// Nome obrigatório (até 50 caracteres) e sem repetir, para o mesmo usuário e tipo.
exports.create = async (req, res) => {
  try {
    const { type } = req.body;
    if (!req.body.name || !type) throw new HttpError(400, 'name e type são obrigatórios');
    if (!['income', 'expense'].includes(type)) {
      throw new HttpError(400, "type deve ser 'income' ou 'expense'");
    }
    if (!isTexto(req.body.name, 50)) {
      throw new HttpError(400, 'name deve ser um texto de até 50 caracteres');
    }
    const name = req.body.name.trim();

    const existente = await dbAsync.get(
      `SELECT id FROM categories WHERE user_id = ? AND type = ? AND lower(name) = lower(?)`,
      [req.userId, type, name]
    );
    if (existente) throw new HttpError(409, 'Já existe uma categoria com esse nome');

    const { lastID } = await dbAsync.run(
      `INSERT INTO categories (name, type, user_id) VALUES (?, ?, ?)`,
      [name, type, req.userId]
    );
    res.status(201).json({ id: lastID, name, type, user_id: req.userId });
  } catch (err) {
    handleError(res, err);
  }
};

// GET /categories
exports.list = (req, res) => {
  const { type } = req.query;

  let sql = `SELECT * FROM categories WHERE user_id = ?`;
  const params = [req.userId];

  if (type) {
    sql += ` AND type = ?`;
    params.push(type);
  }

  sql += ` ORDER BY name ASC`;

  db.all(sql, params, (err, rows) => {
    if (err) return erroInterno(res, err);
    res.json(rows);
  });
};

// DELETE /categories/:id
// Categoria com lançamentos não pode ser apagada (despesas exigem
// categoria). Responde 409 com mensagem clara em vez de erro do SQLite.
exports.remove = async (req, res) => {
  try {
    const { id } = req.params;

    const cat = await dbAsync.get(
      `SELECT id FROM categories WHERE id = ? AND user_id = ?`,
      [id, req.userId]
    );
    if (!cat) throw new HttpError(404, 'Categoria não encontrada');

    const uso = await dbAsync.get(
      `SELECT
         (SELECT COUNT(*) FROM incomes  WHERE category_id = ? AND user_id = ?) +
         (SELECT COUNT(*) FROM expenses WHERE category_id = ? AND user_id = ?) AS total`,
      [id, req.userId, id, req.userId]
    );
    if (uso.total > 0) {
      throw new HttpError(
        409,
        `Categoria em uso por ${uso.total} lançamento(s). Mova ou exclua esses lançamentos antes.`
      );
    }

    await dbAsync.run(`DELETE FROM categories WHERE id = ? AND user_id = ?`, [id, req.userId]);
    res.status(204).send();
  } catch (err) {
    handleError(res, err);
  }
};
