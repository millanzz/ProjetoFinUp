/**
 * Cria um arquivo SQLite no formato de uma versão ANTERIOR do FinUp:
 *   - receitas/despesas sem as colunas parcelado / parcela_*
 *   - metas com ícone em emoji (🎯, ✈️, 🏖️) ou vazio
 * Serve para testar se o db.js atual migra o banco e se o app lê os dados antigos.
 *
 * Uso: node criar-banco-legado.js <arquivo.db>
 */
const path = require('path');
const fs = require('fs');

const BACKEND = path.resolve(__dirname, '..', '..', '..', 'backend');
const sqlite3 = require(path.join(BACKEND, 'node_modules', 'sqlite3'));
const bcrypt = require(path.join(BACKEND, 'node_modules', 'bcrypt'));

const arquivo = path.resolve(process.argv[2]);
if (fs.existsSync(arquivo)) fs.unlinkSync(arquivo);

const db = new sqlite3.Database(arquivo);
const hash = bcrypt.hashSync('legado123', 10);

db.serialize(() => {
  db.run(`CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE, password TEXT NOT NULL, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)`);
  db.run(`CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
          type TEXT NOT NULL CHECK(type IN ('income','expense')), user_id INTEGER NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE)`);
  db.run(`CREATE TABLE incomes (id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL NOT NULL, description TEXT,
          date DATE NOT NULL, category_id INTEGER, user_id INTEGER NOT NULL, created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE)`);
  db.run(`CREATE TABLE expenses (id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL NOT NULL, description TEXT,
          date DATE NOT NULL, category_id INTEGER NOT NULL, user_id INTEGER NOT NULL, created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE RESTRICT,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE)`);
  db.run(`CREATE TABLE goals (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, target_amount REAL NOT NULL,
          current_amount REAL DEFAULT 0, icon TEXT, user_id INTEGER NOT NULL, created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE)`);

  db.run(`INSERT INTO users (id, name, email, password) VALUES (1, 'Usuária Antiga', 'legado@teste.local', ?)`, [hash]);
  db.run(`INSERT INTO categories (id, name, type, user_id) VALUES (1, 'Salário', 'income', 1), (2, 'Moradia', 'expense', 1)`);
  db.run(`INSERT INTO incomes (amount, description, date, category_id, user_id) VALUES (5000, 'Salário antigo', '2025-12-05', 1, 1)`);
  db.run(`INSERT INTO expenses (amount, description, date, category_id, user_id) VALUES (1500, 'Aluguel antigo', '2025-12-10', 2, 1)`);
  db.run(`INSERT INTO goals (title, target_amount, current_amount, icon, user_id) VALUES
          ('Reserva', 10000, 2500, '🎯', 1), ('Viagem', 8000, 0, '✈️', 1), ('Praia', 3000, 100, '🏖️', 1), ('Sem ícone', 500, 0, NULL, 1)`);
});

db.close((err) => {
  if (err) throw err;
  console.log(`Banco legado criado em ${arquivo}`);
});
