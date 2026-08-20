const bcrypt = require('bcrypt');
const db = require('../database/db');

// Categorias criadas automaticamente para cada usuário novo,
// espelhando as opções disponíveis no app Flutter.
const DEFAULT_CATEGORIES = {
  income: ['Salário', 'Freelance', 'Investimentos', 'Bônus', 'Outros'],
  expense: [
    'Alimentação', 'Transporte', 'Moradia', 'Saúde', 'Lazer',
    'Compras', 'Assinaturas', 'Impostos', 'Outros'
  ]
};

function seedDefaultCategories(userId) {
  const stmt = db.prepare(
    `INSERT INTO categories (name, type, user_id) VALUES (?, ?, ?)`
  );
  for (const [type, names] of Object.entries(DEFAULT_CATEGORIES)) {
    for (const name of names) {
      stmt.run(name, type, userId);
    }
  }
  stmt.finalize();
}

// POST /users - cadastrar novo usuário
exports.create = async (req, res) => {
  const { name, email, password } = req.body;

  if (!name || !email || !password) {
    return res.status(400).json({
      error: 'Os campos name, email e password são obrigatórios'
    });
  }

  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return res.status(400).json({ error: 'Email inválido' });
  }

  if (password.length < 6) {
    return res.status(400).json({
      error: 'A senha deve ter pelo menos 6 caracteres'
    });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);

    db.run(
      `INSERT INTO users (name, email, password) VALUES (?, ?, ?)`,
      [name, email, hashedPassword],
      function (err) {
        if (err) {
          if (err.message.includes('UNIQUE')) {
            return res.status(409).json({ error: 'Email já cadastrado' });
          }
          return res.status(500).json({ error: err.message });
        }

        // cria as categorias padrão do usuário
        seedDefaultCategories(this.lastID);

        res.status(201).json({
          id: this.lastID,
          name,
          email
        });
      }
    );
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// GET /users/me - dados do usuário logado
exports.me = (req, res) => {
  db.get(
    `SELECT id, name, email, created_at FROM users WHERE id = ?`,
    [req.userId],
    (err, row) => {
      if (err) return res.status(500).json({ error: err.message });
      if (!row) return res.status(404).json({ error: 'Usuário não encontrado' });
      res.json(row);
    }
  );
};

// PUT /users/me - atualizar nome e/ou email
exports.update = (req, res) => {
  const { name, email } = req.body;

  const fields = [];
  const params = [];

  if (name !== undefined) {
    if (!name.trim()) {
      return res.status(400).json({ error: 'name não pode ser vazio' });
    }
    fields.push('name = ?');
    params.push(name.trim());
  }

  if (email !== undefined) {
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return res.status(400).json({ error: 'Email inválido' });
    }
    fields.push('email = ?');
    params.push(email);
  }

  if (fields.length === 0) {
    return res.status(400).json({ error: 'Nenhum campo para atualizar' });
  }

  params.push(req.userId);

  db.run(
    `UPDATE users SET ${fields.join(', ')} WHERE id = ?`,
    params,
    function (err) {
      if (err) {
        if (err.message.includes('UNIQUE')) {
          return res.status(409).json({ error: 'Email já cadastrado' });
        }
        return res.status(500).json({ error: err.message });
      }
      if (this.changes === 0) {
        return res.status(404).json({ error: 'Usuário não encontrado' });
      }
      res.json({ message: 'Usuário atualizado' });
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
  if (new_password.length < 6) {
    return res.status(400).json({
      error: 'A nova senha deve ter pelo menos 6 caracteres'
    });
  }

  db.get(
    `SELECT password FROM users WHERE id = ?`,
    [req.userId],
    async (err, row) => {
      if (err) return res.status(500).json({ error: err.message });
      if (!row) return res.status(404).json({ error: 'Usuário não encontrado' });

      try {
        const isValid = await bcrypt.compare(current_password, row.password);
        if (!isValid) {
          return res.status(401).json({ error: 'Senha atual incorreta' });
        }

        const hashed = await bcrypt.hash(new_password, 10);
        db.run(
          `UPDATE users SET password = ? WHERE id = ?`,
          [hashed, req.userId],
          (err2) => {
            if (err2) return res.status(500).json({ error: err2.message });
            res.json({ message: 'Senha atualizada' });
          }
        );
      } catch (e) {
        res.status(500).json({ error: e.message });
      }
    }
  );
};
