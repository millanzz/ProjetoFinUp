const crypto = require('crypto');
const bcrypt = require('bcrypt');
const dbAsync = require('../utils/dbAsync');
const { enviarEmail } = require('../utils/mailer');
const {
  HttpError,
  normalizeEmail,
  isValidEmail,
  handleError,
  escapeHtml,
} = require('../utils/validators');

const VALIDADE_MIN = 15; // minutos que o código vale
const MAX_TENTATIVAS = 5; // erros permitidos por código
const ESPERA_REENVIO_S = 60; // intervalo mínimo entre pedidos

// Mesma resposta exista ou não a conta, para não revelar quais
// e-mails estão cadastrados.
const RESPOSTA_PEDIDO = {
  message: 'Se o e-mail estiver cadastrado, enviamos um código de 6 dígitos.',
  validade_minutos: VALIDADE_MIN,
  reenviar_em_segundos: ESPERA_REENVIO_S,
};

const ERRO_CODIGO = 'Código inválido ou expirado. Peça um novo código.';

/**
 * POST /auth/forgot-password  { email }
 * Gera um código de 6 dígitos, válido por 15 minutos, e envia por e-mail.
 */
exports.forgotPassword = async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);
    if (!isValidEmail(email)) throw new HttpError(400, 'Informe um e-mail válido');

    const user = await dbAsync.get(
      `SELECT id, name, email FROM users WHERE lower(email) = ?`,
      [email]
    );
    if (!user) return res.json(RESPOSTA_PEDIDO);

    const agora = Date.now();

    // Evita disparar vários e-mails seguidos.
    const ultimo = await dbAsync.get(
      `SELECT created_at FROM password_resets
       WHERE user_id = ? ORDER BY created_at DESC LIMIT 1`,
      [user.id]
    );
    if (ultimo && agora - ultimo.created_at < ESPERA_REENVIO_S * 1000) {
      return res.json(RESPOSTA_PEDIDO);
    }

    const codigo = String(crypto.randomInt(0, 1000000)).padStart(6, '0');
    const codeHash = await bcrypt.hash(codigo, 10);

    // Só o código mais recente vale.
    await dbAsync.run(
      `UPDATE password_resets SET used = 1 WHERE user_id = ? AND used = 0`,
      [user.id]
    );
    await dbAsync.run(
      `INSERT INTO password_resets (user_id, code_hash, expires_at, created_at)
       VALUES (?, ?, ?, ?)`,
      [user.id, codeHash, agora + VALIDADE_MIN * 60 * 1000, agora]
    );

    const primeiroNome = (user.name || '').trim().split(/\s+/)[0] || 'tudo bem';
    // O nome é escrito pelo próprio usuário: escapa antes de pôr no HTML (DEF-17)
    const nomeHtml = escapeHtml(primeiroNome);
    try {
      await enviarEmail({
        para: user.email,
        assunto: `FinUp · seu código é ${codigo}`,
        texto:
          `Olá, ${primeiroNome}!\n\n` +
          `Seu código para redefinir a senha do FinUp é: ${codigo}\n\n` +
          `Ele vale por ${VALIDADE_MIN} minutos. Se você não pediu, ignore este e-mail.`,
        html:
          `<div style="font-family:Roboto,Arial,sans-serif;color:#1E293B">` +
          `<p>Olá, ${nomeHtml}!</p>` +
          `<p>Seu código para redefinir a senha do <b>FinUp</b> é:</p>` +
          `<p style="font-size:32px;font-weight:700;letter-spacing:6px;color:#2F6FE4">${codigo}</p>` +
          `<p>Ele vale por ${VALIDADE_MIN} minutos. Se você não pediu, ignore este e-mail.</p>` +
          `</div>`,
      });
    } catch (err) {
      // Não revela ao cliente se a conta existe; o erro fica no log.
      console.error('Falha ao enviar e-mail de recuperação:', err.message);
    }

    res.json(RESPOSTA_PEDIDO);
  } catch (err) {
    handleError(res, err);
  }
};

/**
 * POST /auth/reset-password  { email, code, new_password }
 * Confere o código e troca a senha. Cada código aceita 5 tentativas.
 */
exports.resetPassword = async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);
    const code = typeof req.body.code === 'string' ? req.body.code.trim() : '';
    const novaSenha = req.body.new_password;

    if (!isValidEmail(email) || !/^\d{6}$/.test(code)) {
      throw new HttpError(400, 'Informe o e-mail e o código de 6 dígitos');
    }
    if (typeof novaSenha !== 'string' || novaSenha.length < 6) {
      throw new HttpError(400, 'A nova senha deve ter pelo menos 6 caracteres');
    }

    const user = await dbAsync.get(`SELECT id FROM users WHERE lower(email) = ?`, [email]);
    if (!user) throw new HttpError(400, ERRO_CODIGO);

    const pedido = await dbAsync.get(
      `SELECT * FROM password_resets
       WHERE user_id = ? AND used = 0
       ORDER BY created_at DESC LIMIT 1`,
      [user.id]
    );
    if (!pedido || pedido.expires_at < Date.now()) {
      throw new HttpError(400, ERRO_CODIGO);
    }

    // Reserva a tentativa ANTES de conferir o código, numa única instrução:
    // só passa quem ainda está abaixo do limite. Antes o limite era lido, o
    // código conferido (~60 ms) e só depois a tentativa contada, e 40 palpites
    // simultâneos eram todos conferidos (DEF-13).
    const { changes } = await dbAsync.run(
      `UPDATE password_resets SET attempts = attempts + 1
       WHERE id = ? AND attempts < ? AND used = 0`,
      [pedido.id, MAX_TENTATIVAS]
    );
    if (changes === 0) throw new HttpError(400, ERRO_CODIGO);
    const { attempts: usadas } = await dbAsync.get(
      `SELECT attempts FROM password_resets WHERE id = ?`, [pedido.id]
    );

    const confere = await bcrypt.compare(code, pedido.code_hash);
    if (!confere) {
      const restantes = MAX_TENTATIVAS - usadas;
      throw new HttpError(
        400,
        restantes > 0
          ? `Código incorreto. Você ainda tem ${restantes} tentativa(s).`
          : ERRO_CODIGO
      );
    }

    const hash = await bcrypt.hash(novaSenha, 10);
    // Nova senha + encerramento de todas as sessões abertas (tokens antigos)
    await dbAsync.run(
      `UPDATE users SET password = ?, sessoes_desde = ? WHERE id = ?`,
      [hash, Math.floor(Date.now() / 1000), user.id]
    );
    await dbAsync.run(`UPDATE password_resets SET used = 1 WHERE user_id = ?`, [user.id]);

    res.json({ message: 'Senha redefinida. Entre com a nova senha.' });
  } catch (err) {
    handleError(res, err);
  }
};
