/**
 * Sobe a API REAL do FinUp (backend/src/app.js) com um banco SQLite em memória.
 *
 * - Nenhum arquivo do projeto é alterado e o backend/database.db não é aberto:
 *   o construtor do sqlite3 é interceptado antes de carregar o db.js.
 * - O .env do projeto não é lido; o JWT_SECRET abaixo é um valor só de teste.
 *
 * Uso nos testes:   const { iniciar } = require('./servidor'); const api = await iniciar();
 * Uso manual:       node servidor.js 3999   (para os testes de interface do app)
 */
const path = require('path');

const BACKEND = path.resolve(__dirname, '..', '..', '..', 'backend');

process.env.JWT_SECRET = 'segredo-somente-para-testes-funcionais';
process.env.JWT_EXPIRES_IN = '1h';
delete process.env.SMTP_HOST;

const sqlite3 = require(path.join(BACKEND, 'node_modules', 'sqlite3'));
const OriginalDatabase = sqlite3.Database;
sqlite3.Database = function DatabaseEmMemoria(_arquivo, ...resto) {
  return new OriginalDatabase(':memory:', ...resto);
};

const logOriginal = console.log;
console.log = (...a) => {
  if (typeof a[0] === 'string' && a[0].startsWith('Banco SQLite aberto')) return;
  logOriginal(...a);
};

const app = require(path.join(BACKEND, 'src', 'app.js'));
const db = require(path.join(BACKEND, 'src', 'database', 'db.js'));
const jwt = require(path.join(BACKEND, 'node_modules', 'jsonwebtoken'));

function iniciar(porta = 0) {
  return new Promise((resolve) => {
    const server = app.listen(porta, '127.0.0.1', () => {
      const base = `http://127.0.0.1:${server.address().port}`;
      resolve({ base, server, db, jwt, fechar: () => new Promise((r) => server.close(r)) });
    });
  });
}

/** Cliente HTTP simples para os testes: devolve { status, body }. */
function cliente(base) {
  async function req(metodo, rota, { body, token, headers = {}, raw } = {}) {
    const h = { ...headers };
    if (body !== undefined || raw !== undefined) h['Content-Type'] = 'application/json';
    if (token) h.Authorization = `Bearer ${token}`;
    const res = await fetch(base + rota, {
      method: metodo,
      headers: h,
      body: raw !== undefined ? raw : body !== undefined ? JSON.stringify(body) : undefined,
    });
    const texto = await res.text();
    let json = null;
    try { json = texto ? JSON.parse(texto) : null; } catch { json = texto; }
    return { status: res.status, body: json };
  }
  const api = {
    get: (r, o) => req('GET', r, o),
    post: (r, o) => req('POST', r, o),
    put: (r, o) => req('PUT', r, o),
    patch: (r, o) => req('PATCH', r, o),
    del: (r, o) => req('DELETE', r, o),
  };

  /** Cadastra e faz login; devolve { token, user, categorias }. */
  api.novoUsuario = async (nome, email, senha = 'senha123') => {
    const c = await api.post('/users', { body: { name: nome, email, password: senha } });
    if (c.status !== 201) throw new Error(`cadastro falhou: ${c.status} ${JSON.stringify(c.body)}`);
    const l = await api.post('/auth/login', { body: { email, password: senha } });
    const token = l.body.token;
    const cats = (await api.get('/categories', { token })).body;
    const categorias = Object.fromEntries(cats.map((x) => [`${x.type}:${x.name}`, x.id]));
    return { token, user: l.body.user, categorias, senha };
  };
  return api;
}

module.exports = { iniciar, cliente };

if (require.main === module) {
  const porta = Number(process.argv[2] || 3999);
  iniciar(porta).then(({ base }) => logOriginal(`API de teste (banco em memória) em ${base}`));
}
