-- SCHEMA
CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
      user_id INTEGER NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    );
CREATE TABLE expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL NOT NULL,
      description TEXT,
      date DATE NOT NULL,
      category_id INTEGER NOT NULL,
      parcelado INTEGER DEFAULT 0,
      user_id INTEGER NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP, parcela_grupo TEXT, parcela_numero INTEGER, parcela_total INTEGER,
      FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE RESTRICT,
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    );
CREATE TABLE goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      target_amount REAL NOT NULL,
      current_amount REAL DEFAULT 0,
      icon TEXT DEFAULT 'flag',
      user_id INTEGER NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    );
CREATE TABLE incomes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL NOT NULL,
      description TEXT,
      date DATE NOT NULL,
      category_id INTEGER,
      parcelado INTEGER DEFAULT 0,
      user_id INTEGER NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP, parcela_grupo TEXT, parcela_numero INTEGER, parcela_total INTEGER,
      FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL,
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    );
CREATE TABLE password_resets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      code_hash TEXT NOT NULL,
      expires_at INTEGER NOT NULL,
      attempts INTEGER NOT NULL DEFAULT 0,
      used INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    );
CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    , sessoes_desde INTEGER NOT NULL DEFAULT 0);

-- categories: 15 linha(s)
{"id":1,"name":"Salário","type":"income","user_id":1,"created_at":"2026-11-23 12:15:54"}
{"id":2,"name":"Freelance","type":"income","user_id":1,"created_at":"2026-11-23 12:15:54"}
{"id":3,"name":"Investimentos","type":"income","user_id":1,"created_at":"2026-11-23 12:15:54"}
{"id":4,"name":"Bônus","type":"income","user_id":1,"created_at":"2026-11-23 12:15:54"}
{"id":5,"name":"Outros","type":"income","user_id":1,"created_at":"2026-11-23 12:15:54"}
{"id":6,"name":"Alimentação","type":"expense","user_id":1,"created_at":"2026-11-23 12:15:54"}
{"id":7,"name":"Transporte","type":"expense","user_id":1,"created_at":"2026-11-23 12:15:54"}
{"id":8,"name":"Moradia","type":"expense","user_id":1,"created_at":"2026-11-23 12:15:54"}
{"id":9,"name":"Saúde","type":"expense","user_id":1,"created_at":"2026-11-23 12:15:54"}
{"id":10,"name":"Lazer","type":"expense","user_id":1,"created_at":"2026-11-23 12:15:54"}
{"id":11,"name":"Compras","type":"expense","user_id":1,"created_at":"2026-11-23 12:15:54"}
{"id":12,"name":"Assinaturas","type":"expense","user_id":1,"created_at":"2026-11-23 12:15:54"}
{"id":13,"name":"Impostos","type":"expense","user_id":1,"created_at":"2026-11-23 12:15:54"}
{"id":14,"name":"Outros","type":"expense","user_id":1,"created_at":"2026-11-23 12:15:54"}
{"id":15,"name":"Projetos","type":"income","user_id":1,"created_at":"2026-11-23 12:15:54"}

-- expenses: 5 linha(s)
{"id":1,"amount":1450,"description":"Aluguel","date":"2026-11-03","category_id":8,"parcelado":0,"user_id":1,"created_at":"2026-11-23 12:15:54","parcela_grupo":null,"parcela_numero":null,"parcela_total":null}
{"id":2,"amount":412.9,"description":"Mercado do mês","date":"2026-11-04","category_id":6,"parcelado":0,"user_id":1,"created_at":"2026-11-23 12:15:54","parcela_grupo":null,"parcela_numero":null,"parcela_total":null}
{"id":4,"amount":900,"description":"Notebook","date":"2026-11-01","category_id":11,"parcelado":1,"user_id":1,"created_at":"2026-11-23 12:15:54","parcela_grupo":"2724c3ff-3a96-4aa6-82b7-57cb88f68f47","parcela_numero":1,"parcela_total":4}
{"id":6,"amount":900,"description":"Notebook","date":"2027-01-01","category_id":11,"parcelado":1,"user_id":1,"created_at":"2026-11-23 12:15:54","parcela_grupo":"2724c3ff-3a96-4aa6-82b7-57cb88f68f47","parcela_numero":3,"parcela_total":4}
{"id":7,"amount":900,"description":"Notebook","date":"2027-02-01","category_id":11,"parcelado":1,"user_id":1,"created_at":"2026-11-23 12:15:54","parcela_grupo":"2724c3ff-3a96-4aa6-82b7-57cb88f68f47","parcela_numero":4,"parcela_total":4}

-- goals: 2 linha(s)
{"id":1,"title":"Reserva de emergência","target_amount":10000,"current_amount":2750.75,"icon":"wallet","user_id":1,"created_at":"2026-11-23 12:15:54"}
{"id":2,"title":"Viagem","target_amount":6000,"current_amount":0,"icon":"flight","user_id":1,"created_at":"2026-11-23 12:15:54"}

-- incomes: 2 linha(s)
{"id":1,"amount":5200,"description":"Salário","date":"2026-11-05","category_id":1,"parcelado":0,"user_id":1,"created_at":"2026-11-23 12:15:54","parcela_grupo":null,"parcela_numero":null,"parcela_total":null}
{"id":2,"amount":850.5,"description":"Logo — padaria São João","date":"2026-11-02","category_id":15,"parcelado":0,"user_id":1,"created_at":"2026-11-23 12:15:54","parcela_grupo":null,"parcela_numero":null,"parcela_total":null}

-- password_resets: 0 linha(s)

-- users: 1 linha(s)
{"id":1,"name":"Paula M. Ribeiro","email":"paula@teste.local","password":"$2b$10$…(hash bcrypt)","created_at":"2026-11-23 12:15:54","sessoes_desde":1795436154}

