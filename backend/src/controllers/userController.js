const bcrypt = require('bcrypt');
const dbAsync = require('../utils/dbAsync');
const { emitirToken, agoraEmSegundos } = require('../utils/token');
const db = require('../database/db');
const { normalizeEmail, isValidEmail, erroInterno } = require('../utils/validators');

// Categorias criadas automaticamente para cada usuário novo,
// espelhando as opções disponíveis no app Flutter.
const DEFAULT_CATEGORIES = {
  income: ['Salário', 'Freelance', 'Investimentos', 'Bônus', 'Outros'],
  expense: [
    'Alimentação', 'Transporte', 'Moradia', 'Saúde', 'Lazer',
    'Compras', 'Assinaturas', 'Impostos', 'Outros'
  ]
};

/**
 * Cria as categorias padrão num ÚNICO INSERT, que termina antes de a API
 * responder ao cadastro. Antes os 14 INSERTs eram disparados sem esperar e a
 * resposta saía na frente: um app rápido lia a lista incompleta e criava
 * categorias repetidas.
 */
function seedDefaultCategories(userId) {
  const linhas = Object.entries(DEFAULT_CATEGORIES).flatMap(([type, names]) =>
    names.map((name) => [name, type, userId])
  );
  return dbAsync.run(
    `INSERT INTO categories (name, type, user_id) VALUES ${linhas.map(() => '(?, ?, ?)').join(', ')}`,
    linhas.flat()
  );
}

// POST /users - cadastrar novo usuário
exports.create = async (req, res) => {
  const { password } = req.body;
  const name = typeof req.body.name === 'string' ? req.body.name.trim() : req.body.name;
  const email = normalizeEmail(req.body.email);

  if (!name || !email || !password) {
    return res.status(400).json({
      error: 'Os campos name, email e password são obrigatórios'
    });
  }

  if (!isValidEmail(email)) {
    return res.status(400).json({ error: 'Email inválido' });
  }
  if (typeof name !== 'string' || name.length > 100) {
    return res.status(400).json({ error: 'O nome deve ter até 100 caracteres' });
  }

  if (typeof password !== 'string' || password.length < 6) {
    return res.status(400).json({
      error: 'A senha deve ter pelo menos 6 caracteres'
    });
  }

  try {
    const existente = await new Promise((resolve, reject) =>
      db.get(`SELECT id FROM users WHERE lower(email) = ?`, [email],
        (err, row) => (err ? reject(err) : resolve(row)))
    );
    if (existente) {
      return res.status(409).json({ error: 'Email já cadastrado' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    db.run(
      `INSERT INTO users (name, email, password) VALUES (?, ?, ?)`,
      [name, email, hashedPassword],
      function (err) {
        if (err) {
          if (err.message.includes('UNIQUE')) {
            return res.status(409).json({ error: 'Email já cadastrado' });
          }
          return erroInterno(res, err);
        }

        // cria as categorias padrão do usuário (antes de responder)
        const id = this.lastID;
        seedDefaultCategories(id)
          .then(() => res.status(201).json({ id, name, email }))
          .catch((e) => erroInterno(res, e));
      }
    );
  } catch (err) {
    erroInterno(res, err);
  }
};

// GET /users/me - dados do usuário logado
exports.me = (req, res) => {
  db.get(
    `SELECT id, name, email, created_at FROM users WHERE id = ?`,
    [req.userId],
    (err, row) => {
      if (err) return erroInterno(res, err);
      if (!row) return res.status(404).json({ error: 'Usuário não encontrado' });
      res.json(row);
    }
  );
};

// PUT /users/me - atualizar nome e/ou email
exports.update = (req, res) => {
  const { name } = req.body;
  const email = req.body.email === undefined ? undefined : normalizeEmail(req.body.email);

  const fields = [];
  const params = [];

  if (name !== undefined) {
    if (typeof name !== 'string' || !name.trim()) {
      return res.status(400).json({ error: 'name não pode ser vazio' });
    }
    if (name.trim().length > 100) {
      return res.status(400).json({ error: 'O nome deve ter até 100 caracteres' });
    }
    fields.push('name = ?');
    params.push(name.trim());
  }

  if (email !== undefined) {
    if (!isValidEmail(email)) {
      return res.status(400).json({ error: 'Email inválido' });
    }
    fields.push('email = ?');
    params.push(email);
  }

  if (fields.length === 0) {
    return res.status(400).json({ error: 'Nenhum campo para atualizar' });
  }

  params.push(req.userId);

  const atualizar = () => db.run(
    `UPDATE users SET ${fields.join(', ')} WHERE id = ?`,
    params,
    function (err) {
      if (err) {
        if (err.message.includes('UNIQUE')) {
          return res.status(409).json({ error: 'Email já cadastrado' });
        }
        return erroInterno(res, err);
      }
      if (this.changes === 0) {
        return res.status(404).json({ error: 'Usuário não encontrado' });
      }
      res.json({ message: 'Usuário atualizado' });
    }
  );

  if (email === undefined) return atualizar();

  // O índice UNIQUE diferencia maiúsculas; confere sem diferenciar.
  db.get(
    `SELECT id FROM users WHERE lower(email) = ? AND id <> ?`,
    [email, req.userId],
    (err, row) => {
      if (err) return erroInterno(res, err);
      if (row) return res.status(409).json({ error: 'Email já cadastrado' });
      atualizar();
    }
  );
};

// PUT /users/me/password - trocar senha
exports.updatePassword = (req, res) => {
  const { current_password, new_password } = req.body;

  if (!current_password || !new_password) {
    return res.status(400).json({
      error: 'current_password e new_password são obrigatórios'
    });
  }
  // Senha que não é texto pulava a regra de 6 caracteres e derrubava o bcrypt (DEF-03).
  if (typeof current_password !== 'string' || typeof new_password !== 'string') {
    return res.status(400).json({ error: 'As senhas devem ser texto' });
  }
  if (new_password.length < 6) {
    return res.status(400).json({
      error: 'A nova senha deve ter pelo menos 6 caracteres'
    });
  }

  db.get(
    `SELECT password FROM users WHERE id = ?`,
    [req.userId],
    async (err, row) => {
      if (err) return erroInterno(res, err);
      if (!row) return res.status(404).json({ error: 'Usuário não encontrado' });

      try {
        const isValid = await bcrypt.compare(current_password, row.password);
        if (!isValid) {
          return res.status(401).json({ error: 'Senha atual incorreta' });
        }

        const hashed = await bcrypt.hash(new_password, 10);
        // Encerra as sessões abertas em outros aparelhos e devolve um token novo
        // para este aparelho continuar conectado.
        db.run(
          `UPDATE users SET password = ?, sessoes_desde = ? WHERE id = ?`,
          [hashed, agoraEmSegundos(), req.userId],
          (err2) => {
            if (err2) return erroInterno(res, err2);
            res.json({
              message: 'Senha atualizada',
              token: emitirToken({ id: req.userId, email: req.userEmail }),
            });
          }
        );
      } catch (e) {
        erroInterno(res, e);
      }
    }
  );
};

// DELETE /users/me - excluir a conta e TODOS os dados do usuário (LGPD, art. 18)
// Exige a senha atual no corpo: { "password": "..." }.
exports.remove = async (req, res) => {
  try {
    const { password } = req.body || {};
    if (typeof password !== 'string' || !password) {
      return res.status(400).json({ error: 'Informe a senha atual para excluir a conta' });
    }
    const user = await dbAsync.get(`SELECT password FROM users WHERE id = ?`, [req.userId]);
    if (!user) return res.status(404).json({ error: 'Usuário não encontrado' });
    if (!(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ error: 'Senha incorreta' });
    }

    // Ordem explícita: lançamentos antes das categorias (despesas usam
    // ON DELETE RESTRICT na categoria). O usuário por último.
    for (const tabela of ['expenses', 'incomes', 'goals', 'password_resets', 'categories']) {
      await dbAsync.run(`DELETE FROM ${tabela} WHERE user_id = ?`, [req.userId]);
    }
    await dbAsync.run(`DELETE FROM users WHERE id = ?`, [req.userId]);
    res.status(204).send();
  } catch (err) {
    erroInterno(res, err);
  }
};
