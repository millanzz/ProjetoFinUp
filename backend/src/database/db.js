const path = require('path');
const sqlite3 = require('sqlite3').verbose();

// Arquivo do banco: DB_PATH no .env (em produção, fora da pasta do código,
// para sobreviver às atualizações) ou backend/database.db por padrão.
const dbPath = process.env.DB_PATH
  ? path.resolve(process.env.DB_PATH)
  : path.join(__dirname, '..', '..', 'database.db');

const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Erro ao abrir o banco:', err.message);
  } else {
    console.log(`Banco SQLite aberto em: ${dbPath}`);
  }
});

// Executa o schema
db.serialize(() => {

  db.run(`PRAGMA foreign_keys = ON`);

  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
      user_id INTEGER NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    );
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS incomes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL NOT NULL,
      description TEXT,
      date DATE NOT NULL,
      category_id INTEGER,
      parcelado INTEGER DEFAULT 0,
      user_id INTEGER NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL,
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    );
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL NOT NULL,
      description TEXT,
      date DATE NOT NULL,
      category_id INTEGER NOT NULL,
      parcelado INTEGER DEFAULT 0,
      user_id INTEGER NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE RESTRICT,
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    );
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      target_amount REAL NOT NULL,
      current_amount REAL DEFAULT 0,
      icon TEXT DEFAULT 'flag',
      user_id INTEGER NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    );
  `);

  // Códigos de "esqueci minha senha". Guardamos só o hash do código.
  db.run(`
    CREATE TABLE IF NOT EXISTS password_resets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      code_hash TEXT NOT NULL,
      expires_at INTEGER NOT NULL,
      attempts INTEGER NOT NULL DEFAULT 0,
      used INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    );
  `);

  // ── Migrações leves ─────────────────────────────────────────
  // Se o banco foi criado por uma versão anterior do schema,
  // adiciona as colunas novas. O callback vazio ignora o erro
  // "duplicate column name" quando a coluna já existe.
  db.run(`ALTER TABLE goals ADD COLUMN icon TEXT DEFAULT 'flag'`, () => {});
  // Tokens emitidos antes deste instante (segundos) deixam de valer: usado ao
  // trocar ou redefinir a senha, para encerrar as sessões abertas.
  db.run(`ALTER TABLE users ADD COLUMN sessoes_desde INTEGER NOT NULL DEFAULT 0`, () => {});
  db.run(`ALTER TABLE incomes ADD COLUMN parcelado INTEGER DEFAULT 0`, () => {});
  db.run(`ALTER TABLE expenses ADD COLUMN parcelado INTEGER DEFAULT 0`, () => {});

  // Parcelamento: cada parcela é um lançamento no seu mês, ligados
  // pelo mesmo parcela_grupo. parcela_numero vai de 1 a parcela_total.
  for (const tabela of ['incomes', 'expenses']) {
    db.run(`ALTER TABLE ${tabela} ADD COLUMN parcela_grupo TEXT`, () => {});
    db.run(`ALTER TABLE ${tabela} ADD COLUMN parcela_numero INTEGER`, () => {});
    db.run(`ALTER TABLE ${tabela} ADD COLUMN parcela_total INTEGER`, () => {});
  }

  // Metas antigas guardavam emoji no ícone; o app novo usa nomes
  // ('flag', 'flight'…). Converte uma vez os emojis conhecidos.
  const EMOJI_PARA_ICONE = {
    '🎯': 'flag', '💰': 'wallet', '🏠': 'home', '🚗': 'car', '✈️': 'flight',
    '📱': 'phone', '🎓': 'school', '💻': 'laptop', '🏖️': 'flight', '🎁': 'star',
  };
  for (const [emoji, icone] of Object.entries(EMOJI_PARA_ICONE)) {
    db.run(`UPDATE goals SET icon = ? WHERE icon = ?`, [icone, emoji]);
  }
  db.run(`UPDATE goals SET icon = 'flag' WHERE icon IS NULL OR icon = ''`);

  // Índices (DEF-06/07): sem eles toda consulta lia a tabela inteira, de todos
  // os usuários, e um usuário com poucos dados ficava lento num banco grande.
  // IF NOT EXISTS: criados uma vez; bancos antigos ganham os índices ao subir.
  // Índices "cobrindo" (com category_id e amount): o resumo soma direto do
  // índice, sem ler cada linha da tabela. Um índice só por (user_id, date)
  // deixava o resumo mais lento para quem tem dezenas de milhares de lançamentos.
  db.run(`DROP INDEX IF EXISTS idx_incomes_user_date`);
  db.run(`DROP INDEX IF EXISTS idx_expenses_user_date`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_incomes_user_resumo ON incomes(user_id, date, category_id, amount)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_expenses_user_resumo ON expenses(user_id, date, category_id, amount)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_incomes_category ON incomes(category_id)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category_id)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_incomes_grupo ON incomes(parcela_grupo)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_expenses_grupo ON expenses(parcela_grupo)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_categories_user ON categories(user_id, type)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_goals_user ON goals(user_id)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_password_resets_user ON password_resets(user_id)`);

});

module.exports = db;
