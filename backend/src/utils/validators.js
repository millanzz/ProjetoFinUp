const dbAsync = require('./dbAsync');

/** Erro com status HTTP, tratado nos controllers via `handleError`. */
class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

/** Número finito e maior que zero. */
const isPositiveNumber = (v) => typeof v === 'number' && Number.isFinite(v) && v > 0;

/** Número finito e maior ou igual a zero. */
const isNonNegativeNumber = (v) => typeof v === 'number' && Number.isFinite(v) && v >= 0;

/** Data no formato AAAA-MM-DD e que existe no calendário (rejeita 2026-02-30). */
function isValidDate(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const [y, m, d] = value.split('-').map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  return dt.getUTCFullYear() === y && dt.getUTCMonth() === m - 1 && dt.getUTCDate() === d;
}

/** Mês no formato AAAA-MM. */
const isValidMonth = (value) =>
  typeof value === 'string' && /^\d{4}-(0[1-9]|1[0-2])$/.test(value);

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/** E-mail sem espaços e em minúsculas, para não diferenciar "A@x" de "a@x". */
const normalizeEmail = (email) =>
  typeof email === 'string' ? email.trim().toLowerCase() : email;

const isValidEmail = (email) => typeof email === 'string' && EMAIL_RE.test(email);

/**
 * Garante que a categoria existe, pertence ao usuário e é do tipo certo.
 * Lança HttpError(400) caso contrário.
 */
async function assertCategory(categoryId, userId, type) {
  if (!Number.isInteger(categoryId) || categoryId <= 0) {
    throw new HttpError(400, 'category_id inválido');
  }
  const cat = await dbAsync.get(
    `SELECT id, type FROM categories WHERE id = ? AND user_id = ?`,
    [categoryId, userId]
  );
  if (!cat) throw new HttpError(400, 'Categoria não encontrada para este usuário');
  if (cat.type !== type) {
    throw new HttpError(
      400,
      type === 'income'
        ? 'A categoria informada não é de receita'
        : 'A categoria informada não é de despesa'
    );
  }
}

/**
 * Erro inesperado: registra no log do servidor e responde uma mensagem
 * genérica. Antes vários pontos devolviam err.message ao cliente, expondo
 * detalhes internos (bcrypt, SQLite…).
 */
function erroInterno(res, err) {
  console.error(err);
  return res.status(500).json({ error: 'Erro interno do servidor' });
}

/** Resposta padrão para erros nos controllers async. */
function handleError(res, err) {
  if (err instanceof HttpError) {
    return res.status(err.status).json({ error: err.message });
  }
  return erroInterno(res, err);
}

/** Texto não vazio (depois de tirar espaços) e com no máximo `max` caracteres. */
const isTexto = (v, max) => typeof v === 'string' && v.trim().length > 0 && v.length <= max;

/** Escapa texto para colocar dentro de HTML (e-mails). */
const escapeHtml = (v) =>
  String(v).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);

module.exports = {
  HttpError,
  isPositiveNumber,
  isNonNegativeNumber,
  isValidDate,
  isValidMonth,
  normalizeEmail,
  isValidEmail,
  assertCategory,
  handleError,
  erroInterno,
  isTexto,
  escapeHtml,
};
