const jwt = require('jsonwebtoken');

/** Emite o token de sessão (JWT) de um usuário. */
function emitirToken(user) {
  return jwt.sign(
    { id: user.id, email: user.email },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
}

/** Instante atual em segundos (mesma unidade do campo iat do JWT). */
const agoraEmSegundos = () => Math.floor(Date.now() / 1000);

module.exports = { emitirToken, agoraEmSegundos };
