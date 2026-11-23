const jwt = require('jsonwebtoken');
const db = require('../database/db');
const { erroInterno } = require('../utils/validators');

/**
 * Middleware que valida o JWT enviado no header Authorization.
 * Espera o formato: "Authorization: Bearer <token>"
 * Em caso de sucesso, popula req.userId com o id do usuário logado.
 */
module.exports = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({ error: 'Token não fornecido' });
  }

  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    return res.status(401).json({ error: 'Token mal formatado' });
  }

  const token = parts[1];

  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    if (err) {
      return res.status(401).json({ error: 'Token inválido ou expirado' });
    }

    // O token só vale se a conta ainda existe e se ele foi emitido depois da
    // última troca/redefinição de senha (sessões encerradas).
    db.get(`SELECT sessoes_desde FROM users WHERE id = ?`, [decoded.id], (dbErr, user) => {
      if (dbErr) return erroInterno(res, dbErr);
      if (!user) return res.status(401).json({ error: 'Sessão inválida: a conta não existe mais' });
      if ((decoded.iat || 0) < user.sessoes_desde) {
        return res.status(401).json({ error: 'Sessão encerrada. Entre novamente.' });
      }
      req.userId = decoded.id;
      req.userEmail = decoded.email;
      next();
    });
  });
};
