const nodemailer = require('nodemailer');

/**
 * Envio de e-mails.
 *
 * Com SMTP_HOST no .env, envia de verdade (Gmail, Outlook, Mailtrap…).
 * Sem SMTP configurado, apenas mostra o e-mail no console do servidor,
 * o que basta para desenvolver e testar.
 */
let transporter = null;

function smtpConfigurado() {
  return Boolean(process.env.SMTP_HOST);
}

function getTransporter() {
  if (!transporter) {
    const port = Number(process.env.SMTP_PORT || 587);
    transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port,
      secure: port === 465,
      auth: process.env.SMTP_USER
        ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
        : undefined,
    });
  }
  return transporter;
}

async function enviarEmail({ para, assunto, texto, html }) {
  if (!smtpConfigurado()) {
    console.log(
      `\n──── E-mail (modo desenvolvimento: SMTP não configurado) ────\n` +
        `Para: ${para}\nAssunto: ${assunto}\n\n${texto}\n` +
        `─────────────────────────────────────────────────────────────\n`
    );
    return;
  }

  await getTransporter().sendMail({
    from: process.env.SMTP_FROM || process.env.SMTP_USER,
    to: para,
    subject: assunto,
    text: texto,
    html,
  });
}

module.exports = { enviarEmail, smtpConfigurado };
