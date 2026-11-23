/**
 * Sobe a API REAL do FinUp gravando num ARQUIVO SQLite escolhido pelo teste
 * (nunca o backend/database.db), como na arquitetura de produção:
 *
 *   App Flutter  ──HTTP/JSON──▶  API Express (backend/src)  ──sqlite3──▶  arquivo .db
 *
 * Além da API, abre um "inspetor" só de teste na porta seguinte (porta+1),
 * que permite ao teste conferir o que de fato ficou gravado no SQLite,
 * usando a MESMA conexão da API.
 *
 * Uso: node servidor.js <arquivo.db> <porta>
 * Nada do projeto é alterado; o .env do projeto não é lido.
 */
const path = require('path');

const BACKEND = path.resolve(__dirname, '..', '..', '..', 'backend');
const arquivo = path.resolve(process.argv[2] || path.join(__dirname, 'banco-teste.db'));
const porta = Number(process.argv[3] || 3999);

process.env.JWT_SECRET = 'segredo-somente-para-testes-de-integracao';
process.env.JWT_EXPIRES_IN = '7d';
delete process.env.SMTP_HOST;

// Redireciona o db.js para o arquivo do teste.
const sqlite3 = require(path.join(BACKEND, 'node_modules', 'sqlite3'));
const OriginalDatabase = sqlite3.Database;
sqlite3.Database = function DatabaseDoTeste(_arquivoDoProjeto, ...resto) {
  return new OriginalDatabase(arquivo, ...resto);
};
const log = console.log;
console.log = (...a) => {
  if (typeof a[0] === 'string' && a[0].startsWith('Banco SQLite aberto')) return;
  log(...a);
};

const app = require(path.join(BACKEND, 'src', 'app.js'));
const db = require(path.join(BACKEND, 'src', 'database', 'db.js'));
const express = require(path.join(BACKEND, 'node_modules', 'express'));
const jwt = require(path.join(BACKEND, 'node_modules', 'jsonwebtoken'));

// ── Inspetor (somente teste) ─────────────────────────────────────
const inspetor = express();
inspetor.use(express.json());

// Consulta de leitura no SQLite: { sql, params } -> linhas
inspetor.post('/sql', (req, res) => {
  const { sql, params = [] } = req.body;
  if (!/^\s*(select|pragma)\b/i.test(sql)) {
    return res.status(400).json({ error: 'inspetor só aceita SELECT/PRAGMA em /sql' });
  }
  db.all(sql, params, (err, rows) => (err ? res.status(500).json({ error: err.message }) : res.json(rows)));
});

// Escrita direta (simula outro cliente/ação fora do app): { sql, params }
inspetor.post('/exec', (req, res) => {
  const { sql, params = [] } = req.body;
  db.run(sql, params, function (err) {
    if (err) return res.status(409).json({ error: err.message });
    res.json({ changes: this.changes, lastID: this.lastID });
  });
});

// Token JWT assinado com a chave do servidor (ex.: já expirado).
inspetor.post('/token', (req, res) => {
  const { id, email, expiradoHaSegundos } = req.body;
  const payload = { id, email };
  if (expiradoHaSegundos) payload.exp = Math.floor(Date.now() / 1000) - expiradoHaSegundos;
  res.json({ token: jwt.sign(payload, process.env.JWT_SECRET) });
});

// Espera o schema terminar (db.serialize) antes de anunciar que está pronto.
db.serialize(() => {
  db.get('SELECT 1', () => {
    app.listen(porta, '127.0.0.1', () => {
      inspetor.listen(porta + 1, '127.0.0.1', () => {
        log(`PRONTO api=http://127.0.0.1:${porta} inspetor=http://127.0.0.1:${porta + 1} banco=${arquivo}`);
      });
    });
  });
});
