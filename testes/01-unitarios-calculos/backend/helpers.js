/**
 * Infraestrutura dos testes unitários do backend.
 *
 * Nada do projeto é alterado: antes de carregar `src/database/db.js`,
 * o construtor do sqlite3 é interceptado para abrir um banco EM MEMÓRIA
 * no lugar de `backend/database.db`. O schema real (o do db.js) é executado
 * normalmente, então os testes rodam contra as mesmas tabelas do app.
 */
const path = require('path');

const BACKEND = path.resolve(__dirname, '..', '..', '..', 'backend');

// 1) Banco em memória: o arquivo real nunca é aberto.
const sqlite3 = require(path.join(BACKEND, 'node_modules', 'sqlite3'));
const OriginalDatabase = sqlite3.Database;
sqlite3.Database = function DatabaseEmMemoria(_arquivo, ...resto) {
  return new OriginalDatabase(':memory:', ...resto);
};

// Silencia o log "Banco SQLite aberto em ..." (que mostraria o caminho real).
const logOriginal = console.log;
console.log = (...a) => {
  if (typeof a[0] === 'string' && a[0].startsWith('Banco SQLite aberto')) return;
  logOriginal(...a);
};

const db = require(path.join(BACKEND, 'src', 'database', 'db.js'));
const dbAsync = require(path.join(BACKEND, 'src', 'utils', 'dbAsync.js'));

const controller = (nome) => require(path.join(BACKEND, 'src', 'controllers', nome));

/** Espera o schema do db.js terminar de ser criado. */
const pronto = () =>
  new Promise((resolve, reject) => {
    db.serialize(() => db.get('SELECT 1', (err) => (err ? reject(err) : resolve())));
  });

/** Usuários e categorias fixos usados em todos os testes. */
const U1 = 1;
const U2 = 2;
const CAT = {}; // preenchido em seed()

async function seed() {
  await pronto();
  await dbAsync.run('DELETE FROM incomes');
  await dbAsync.run('DELETE FROM expenses');
  await dbAsync.run('DELETE FROM goals');
  await dbAsync.run('DELETE FROM categories');
  await dbAsync.run('DELETE FROM users');
  await dbAsync.run(
    `INSERT INTO users (id, name, email, password) VALUES
       (1, 'Usuária Teste', 'u1@teste.local', 'x'),
       (2, 'Outro Usuário', 'u2@teste.local', 'x')`
  );
  const cats = [
    ['salario', 'Salário', 'income', U1],
    ['freela', 'Freelance', 'income', U1],
    ['aluguel', 'Aluguel', 'expense', U1],
    ['mercado', 'Mercado', 'expense', U1],
    ['u2Despesa', 'Despesa do U2', 'expense', U2],
    ['u2Receita', 'Receita do U2', 'income', U2],
  ];
  for (const [chave, nome, tipo, user] of cats) {
    const { lastID } = await dbAsync.run(
      'INSERT INTO categories (name, type, user_id) VALUES (?, ?, ?)',
      [nome, tipo, user]
    );
    CAT[chave] = lastID;
  }
}

/** Chama um handler Express (req, res) e devolve { status, body }. */
function chamar(handler, { userId = U1, body = {}, params = {}, query = {} } = {}) {
  return new Promise((resolve, reject) => {
    const res = {
      statusCode: 200,
      status(c) { this.statusCode = c; return this; },
      json(b) { resolve({ status: this.statusCode, body: b }); return this; },
      send(b) { resolve({ status: this.statusCode, body: b }); return this; },
    };
    try {
      const r = handler({ userId, body, params, query }, res);
      if (r && typeof r.catch === 'function') r.catch(reject);
    } catch (e) {
      reject(e);
    }
  });
}

module.exports = { db, dbAsync, controller, seed, chamar, U1, U2, CAT };
