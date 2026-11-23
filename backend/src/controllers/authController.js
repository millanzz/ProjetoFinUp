const bcrypt = require('bcrypt');
const { emitirToken } = require('../utils/token');
const db = require('../database/db');
const { normalizeEmail, erroInterno } = require('../utils/validators');

// POST /auth/login
exports.login = (req, res) => {
  const { password } = req.body;
  const email = normalizeEmail(req.body.email);

  if (!email || !password) {
    return res.status(400).json({
      error: 'Email e password são obrigatórios'
    });
  }
  // Senha que não é texto (ex.: número) derrubava o bcrypt com erro 500 (DEF-03).
  if (typeof email !== 'string' || typeof password !== 'string') {
    return res.status(400).json({ error: 'Email e password devem ser texto' });
  }

  db.get(
    `SELECT * FROM users WHERE lower(email) = ?`,
    [email],
    async (err, user) => {
      if (err) return erroInterno(res, err);
      if (!user) {
        return res.status(401).json({ error: 'Email ou senha inválidos' });
      }

      if (!process.env.JWT_SECRET) {
        console.error('JWT_SECRET não definido no .env');
        return res.status(500).json({
          error: 'Servidor sem JWT_SECRET configurado. Veja o .env.example.'
        });
      }

      try {
        const isValid = await bcrypt.compare(password, user.password);
        if (!isValid) {
          return res.status(401).json({ error: 'Email ou senha inválidos' });
        }

        const token = emitirToken(user);

        res.json({
          token,
          user: {
            id: user.id,
            name: user.name,
            email: user.email
          }
        });
      } catch (e) {
        erroInterno(res, e);
      }
    }
  );
};
