-- SCHEMA
CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
          type TEXT NOT NULL CHECK(type IN ('income','expense')), user_id INTEGER NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE expenses (id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL NOT NULL, description TEXT,
          date DATE NOT NULL, category_id INTEGER NOT NULL, user_id INTEGER NOT NULL, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, parcelado INTEGER DEFAULT 0, parcela_grupo TEXT, parcela_numero INTEGER, parcela_total INTEGER,
          FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE RESTRICT,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE goals (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, target_amount REAL NOT NULL,
          current_amount REAL DEFAULT 0, icon TEXT, user_id INTEGER NOT NULL, created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE);
CREATE TABLE incomes (id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL NOT NULL, description TEXT,
          date DATE NOT NULL, category_id INTEGER, user_id INTEGER NOT NULL, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, parcelado INTEGER DEFAULT 0, parcela_grupo TEXT, parcela_numero INTEGER, parcela_total INTEGER,
          FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL,
          FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE);
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
CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE, password TEXT NOT NULL, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, sessoes_desde INTEGER NOT NULL DEFAULT 0);

-- categories: 2 linha(s)
{"id":1,"name":"Salário","type":"income","user_id":1,"created_at":"2026-11-23 12:15:40"}
{"id":2,"name":"Moradia","type":"expense","user_id":1,"created_at":"2026-11-23 12:15:40"}

-- expenses: 4 linha(s)
{"id":1,"amount":1500,"description":"Aluguel antigo","date":"2025-12-10","category_id":2,"user_id":1,"created_at":"2026-11-23 12:15:40","parcelado":0,"parcela_grupo":null,"parcela_numero":null,"parcela_total":null}
{"id":2,"amount":300,"description":"Sofá","date":"2026-11-08","category_id":2,"user_id":1,"created_at":"2026-11-23 12:15:41","parcelado":1,"parcela_grupo":"179dd838-7e4f-43ec-98d9-8346e5c0d6ba","parcela_numero":1,"parcela_total":3}
{"id":3,"amount":300,"description":"Sofá","date":"2026-12-08","category_id":2,"user_id":1,"created_at":"2026-11-23 12:15:41","parcelado":1,"parcela_grupo":"179dd838-7e4f-43ec-98d9-8346e5c0d6ba","parcela_numero":2,"parcela_total":3}
{"id":4,"amount":300,"description":"Sofá","date":"2027-01-08","category_id":2,"user_id":1,"created_at":"2026-11-23 12:15:41","parcelado":1,"parcela_grupo":"179dd838-7e4f-43ec-98d9-8346e5c0d6ba","parcela_numero":3,"parcela_total":3}

-- goals: 4 linha(s)
{"id":1,"title":"Reserva","target_amount":10000,"current_amount":2500,"icon":"flag","user_id":1,"created_at":"2026-11-23 12:15:40"}
{"id":2,"title":"Viagem","target_amount":8000,"current_amount":0,"icon":"flight","user_id":1,"created_at":"2026-11-23 12:15:40"}
{"id":3,"title":"Praia","target_amount":3000,"current_amount":100,"icon":"flight","user_id":1,"created_at":"2026-11-23 12:15:40"}
{"id":4,"title":"Sem ícone","target_amount":500,"current_amount":0,"icon":"flag","user_id":1,"created_at":"2026-11-23 12:15:40"}

-- incomes: 1 linha(s)
{"id":1,"amount":5000,"description":"Salário antigo","date":"2025-12-05","category_id":1,"user_id":1,"created_at":"2026-11-23 12:15:40","parcelado":0,"parcela_grupo":null,"parcela_numero":null,"parcela_total":null}

-- password_resets: 0 linha(s)

-- users: 1 linha(s)
{"id":1,"name":"Usuária Antiga","email":"legado@teste.local","password":"$2b$10$…(hash bcrypt)","created_at":"2026-11-23 12:15:40","sessoes_desde":0}

