const dbAsync = require('../utils/dbAsync');
const {
  HttpError,
  isPositiveNumber,
  isNonNegativeNumber,
  handleError,
} = require('../utils/validators');

/** Ícones aceitos (mesmas chaves do app). */
const ICONES = ['flag', 'wallet', 'home', 'car', 'flight', 'phone', 'school', 'laptop', 'star', 'trend'];
const ICONE_PADRAO = 'flag';

function validarIcone(icon) {
  if (!ICONES.includes(icon)) {
    throw new HttpError(400, `icon deve ser um destes: ${ICONES.join(', ')}`);
  }
}

// POST /goals
exports.create = async (req, res) => {
  try {
    const { title, target_amount, current_amount, icon } = req.body;

    if (typeof title !== 'string' || !title.trim()) {
      throw new HttpError(400, 'title é obrigatório');
    }
    if (title.trim().length > 100) throw new HttpError(400, 'title deve ter até 100 caracteres');
    if (!isPositiveNumber(target_amount)) {
      throw new HttpError(400, 'target_amount deve ser um número positivo');
    }
    const atual = current_amount === undefined || current_amount === null ? 0 : current_amount;
    if (!isNonNegativeNumber(atual)) {
      throw new HttpError(400, 'current_amount deve ser um número maior ou igual a zero');
    }
    const icone = icon === undefined || icon === null ? ICONE_PADRAO : icon;
    validarIcone(icone);

    const { lastID } = await dbAsync.run(
      `INSERT INTO goals (title, target_amount, current_amount, icon, user_id)
       VALUES (?, ?, ?, ?, ?)`,
      [title.trim(), target_amount, atual, icone, req.userId]
    );

    res.status(201).json({
      id: lastID,
      title: title.trim(),
      target_amount,
      current_amount: atual,
      icon: icone,
      user_id: req.userId,
    });
  } catch (err) {
    handleError(res, err);
  }
};

// GET /goals
exports.list = async (req, res) => {
  try {
    const rows = await dbAsync.all(
      `SELECT * FROM goals WHERE user_id = ? ORDER BY created_at DESC, id DESC`,
      [req.userId]
    );
    res.json(rows);
  } catch (err) {
    handleError(res, err);
  }
};

// PATCH /goals/:id - atualiza progresso, título, valor alvo e ícone
exports.update = async (req, res) => {
  try {
    const { current_amount, title, target_amount, icon } = req.body;
    const fields = [];
    const params = [];

    if (current_amount !== undefined) {
      if (!isNonNegativeNumber(current_amount)) {
        throw new HttpError(400, 'current_amount deve ser um número maior ou igual a zero');
      }
      fields.push('current_amount = ?');
      params.push(current_amount);
    }
    if (title !== undefined) {
      if (typeof title !== 'string' || !title.trim()) {
        throw new HttpError(400, 'title não pode ser vazio');
      }
      if (title.trim().length > 100) throw new HttpError(400, 'title deve ter até 100 caracteres');
      fields.push('title = ?');
      params.push(title.trim());
    }
    if (target_amount !== undefined) {
      if (!isPositiveNumber(target_amount)) {
        throw new HttpError(400, 'target_amount deve ser um número positivo');
      }
      fields.push('target_amount = ?');
      params.push(target_amount);
    }
    if (icon !== undefined) {
      validarIcone(icon);
      fields.push('icon = ?');
      params.push(icon);
    }

    if (fields.length === 0) throw new HttpError(400, 'Nenhum campo para atualizar');

    params.push(req.params.id, req.userId);
    const { changes } = await dbAsync.run(
      `UPDATE goals SET ${fields.join(', ')} WHERE id = ? AND user_id = ?`,
      params
    );
    if (changes === 0) throw new HttpError(404, 'Meta não encontrada');

    res.json({ message: 'Meta atualizada' });
  } catch (err) {
    handleError(res, err);
  }
};

// POST /goals/:id/aportes - soma um aporte ao valor guardado.
// A soma é feita no próprio UPDATE, então dois aportes simultâneos
// não sobrescrevem um ao outro.
exports.aportar = async (req, res) => {
  try {
    const { amount } = req.body;
    if (!isPositiveNumber(amount)) {
      throw new HttpError(400, 'amount deve ser um número positivo');
    }

    const { changes } = await dbAsync.run(
      // ROUND(…, 2): sem resíduo de ponto flutuante (0,10 + 0,20 = 0,30) (DEF-01)
      `UPDATE goals SET current_amount = ROUND(COALESCE(current_amount, 0) + ?, 2)
       WHERE id = ? AND user_id = ?`,
      [amount, req.params.id, req.userId]
    );
    if (changes === 0) throw new HttpError(404, 'Meta não encontrada');

    const meta = await dbAsync.get(
      `SELECT * FROM goals WHERE id = ? AND user_id = ?`,
      [req.params.id, req.userId]
    );
    res.json(meta);
  } catch (err) {
    handleError(res, err);
  }
};

// DELETE /goals/:id
exports.remove = async (req, res) => {
  try {
    const { changes } = await dbAsync.run(
      `DELETE FROM goals WHERE id = ? AND user_id = ?`,
      [req.params.id, req.userId]
    );
    if (changes === 0) throw new HttpError(404, 'Meta não encontrada');
    res.status(204).send();
  } catch (err) {
    handleError(res, err);
  }
};
