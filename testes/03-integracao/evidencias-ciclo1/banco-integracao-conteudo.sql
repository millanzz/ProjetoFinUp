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
    );

-- categories: 42 linha(s)
{"id":1,"name":"Salário","type":"income","user_id":1,"created_at":"2026-11-08 03:32:34"}
{"id":2,"name":"Freelance","type":"income","user_id":1,"created_at":"2026-11-08 03:32:34"}
{"id":3,"name":"Investimentos","type":"income","user_id":1,"created_at":"2026-11-08 03:32:34"}
{"id":4,"name":"Bônus","type":"income","user_id":1,"created_at":"2026-11-08 03:32:34"}
{"id":5,"name":"Outros","type":"income","user_id":1,"created_at":"2026-11-08 03:32:34"}
{"id":6,"name":"Alimentação","type":"expense","user_id":1,"created_at":"2026-11-08 03:32:34"}
{"id":7,"name":"Transporte","type":"expense","user_id":1,"created_at":"2026-11-08 03:32:34"}
{"id":8,"name":"Moradia","type":"expense","user_id":1,"created_at":"2026-11-08 03:32:34"}
{"id":9,"name":"Saúde","type":"expense","user_id":1,"created_at":"2026-11-08 03:32:34"}
{"id":10,"name":"Lazer","type":"expense","user_id":1,"created_at":"2026-11-08 03:32:34"}
{"id":11,"name":"Compras","type":"expense","user_id":1,"created_at":"2026-11-08 03:32:34"}
{"id":12,"name":"Assinaturas","type":"expense","user_id":1,"created_at":"2026-11-08 03:32:34"}
{"id":13,"name":"Impostos","type":"expense","user_id":1,"created_at":"2026-11-08 03:32:34"}
{"id":14,"name":"Outros","type":"expense","user_id":1,"created_at":"2026-11-08 03:32:34"}
{"id":15,"name":"Salário","type":"income","user_id":2,"created_at":"2026-11-08 03:32:34"}
{"id":16,"name":"Freelance","type":"income","user_id":2,"created_at":"2026-11-08 03:32:34"}
{"id":17,"name":"Investimentos","type":"income","user_id":2,"created_at":"2026-11-08 03:32:34"}
{"id":18,"name":"Bônus","type":"income","user_id":2,"created_at":"2026-11-08 03:32:34"}
{"id":19,"name":"Outros","type":"income","user_id":2,"created_at":"2026-11-08 03:32:34"}
{"id":20,"name":"Alimentação","type":"expense","user_id":2,"created_at":"2026-11-08 03:32:34"}
{"id":21,"name":"Transporte","type":"expense","user_id":2,"created_at":"2026-11-08 03:32:34"}
{"id":22,"name":"Moradia","type":"expense","user_id":2,"created_at":"2026-11-08 03:32:34"}
{"id":23,"name":"Saúde","type":"expense","user_id":2,"created_at":"2026-11-08 03:32:34"}
{"id":24,"name":"Lazer","type":"expense","user_id":2,"created_at":"2026-11-08 03:32:35"}
{"id":25,"name":"Compras","type":"expense","user_id":2,"created_at":"2026-11-08 03:32:35"}
{"id":26,"name":"Assinaturas","type":"expense","user_id":2,"created_at":"2026-11-08 03:32:35"}
{"id":27,"name":"Impostos","type":"expense","user_id":2,"created_at":"2026-11-08 03:32:35"}
{"id":28,"name":"Outros","type":"expense","user_id":2,"created_at":"2026-11-08 03:32:35"}
{"id":29,"name":"Salário","type":"income","user_id":3,"created_at":"2026-11-08 03:32:35"}
{"id":30,"name":"Freelance","type":"income","user_id":3,"created_at":"2026-11-08 03:32:35"}
{"id":31,"name":"Investimentos","type":"income","user_id":3,"created_at":"2026-11-08 03:32:35"}
{"id":32,"name":"Bônus","type":"income","user_id":3,"created_at":"2026-11-08 03:32:35"}
{"id":33,"name":"Outros","type":"income","user_id":3,"created_at":"2026-11-08 03:32:35"}
{"id":34,"name":"Alimentação","type":"expense","user_id":3,"created_at":"2026-11-08 03:32:35"}
{"id":35,"name":"Transporte","type":"expense","user_id":3,"created_at":"2026-11-08 03:32:35"}
{"id":36,"name":"Moradia","type":"expense","user_id":3,"created_at":"2026-11-08 03:32:35"}
{"id":37,"name":"Saúde","type":"expense","user_id":3,"created_at":"2026-11-08 03:32:35"}
{"id":38,"name":"Lazer","type":"expense","user_id":3,"created_at":"2026-11-08 03:32:35"}
{"id":39,"name":"Compras","type":"expense","user_id":3,"created_at":"2026-11-08 03:32:35"}
{"id":41,"name":"Impostos","type":"expense","user_id":3,"created_at":"2026-11-08 03:32:35"}
{"id":42,"name":"Outros","type":"expense","user_id":3,"created_at":"2026-11-08 03:32:35"}
{"id":43,"name":"Pets","type":"expense","user_id":3,"created_at":"2026-11-08 03:32:35"}

-- expenses: 11 linha(s)
{"id":1,"amount":12.5,"description":"Sem categoria","date":"2026-11-08","category_id":42,"parcelado":0,"user_id":3,"created_at":"2026-11-08 03:32:35","parcela_grupo":null,"parcela_numero":null,"parcela_total":null}
{"id":2,"amount":120,"description":"Ração","date":"2026-11-08","category_id":43,"parcelado":0,"user_id":3,"created_at":"2026-11-08 03:32:35","parcela_grupo":null,"parcela_numero":null,"parcela_total":null}
{"id":3,"amount":250,"description":"Veterinário","date":"2026-11-09","category_id":43,"parcelado":0,"user_id":3,"created_at":"2026-11-08 03:32:35","parcela_grupo":null,"parcela_numero":null,"parcela_total":null}
{"id":4,"amount":333.34,"description":"Geladeira","date":"2026-11-30","category_id":39,"parcelado":1,"user_id":3,"created_at":"2026-11-08 03:32:36","parcela_grupo":"0c058bb3-e634-40f4-9d49-3bb94d1a3cad","parcela_numero":1,"parcela_total":3}
{"id":5,"amount":333.33,"description":"Geladeira","date":"2026-12-30","category_id":39,"parcelado":1,"user_id":3,"created_at":"2026-11-08 03:32:36","parcela_grupo":"0c058bb3-e634-40f4-9d49-3bb94d1a3cad","parcela_numero":2,"parcela_total":3}
{"id":6,"amount":333.33,"description":"Geladeira","date":"2027-01-30","category_id":39,"parcelado":1,"user_id":3,"created_at":"2026-11-08 03:32:36","parcela_grupo":"0c058bb3-e634-40f4-9d49-3bb94d1a3cad","parcela_numero":3,"parcela_total":3}
{"id":7,"amount":95.5,"description":"Mercado do mês","date":"2026-11-12","category_id":34,"parcelado":0,"user_id":3,"created_at":"2026-11-08 03:32:36","parcela_grupo":null,"parcela_numero":null,"parcela_total":null}
{"id":15,"amount":250.25,"description":"Luz","date":"2026-11-21","category_id":36,"parcelado":0,"user_id":3,"created_at":"2026-11-08 03:32:36","parcela_grupo":null,"parcela_numero":null,"parcela_total":null}
{"id":16,"amount":10,"description":"Data 2028-02-29","date":"2028-02-29","category_id":42,"parcelado":0,"user_id":3,"created_at":"2026-11-08 03:32:36","parcela_grupo":null,"parcela_numero":null,"parcela_total":null}
{"id":17,"amount":10,"description":"Data 2026-12-31","date":"2026-12-31","category_id":42,"parcelado":0,"user_id":3,"created_at":"2026-11-08 03:32:36","parcela_grupo":null,"parcela_numero":null,"parcela_total":null}
{"id":18,"amount":10,"description":"Data 2027-01-01","date":"2027-01-01","category_id":42,"parcelado":0,"user_id":3,"created_at":"2026-11-08 03:32:36","parcela_grupo":null,"parcela_numero":null,"parcela_total":null}

-- goals: 0 linha(s)

-- incomes: 5 linha(s)
{"id":1,"amount":4000,"description":"Salário da Ana","date":"2026-11-05","category_id":1,"parcelado":0,"user_id":1,"created_at":"2026-11-08 03:32:35","parcela_grupo":null,"parcela_numero":null,"parcela_total":null}
{"id":2,"amount":4500.75,"description":"Salário de novembro — açaí, pão & café ☕🍇","date":"2026-11-08","category_id":29,"parcelado":0,"user_id":3,"created_at":"2026-11-08 03:32:35","parcela_grupo":null,"parcela_numero":null,"parcela_total":null}
{"id":3,"amount":1200.5,"description":"Freela","date":"2026-11-20","category_id":30,"parcelado":0,"user_id":3,"created_at":"2026-11-08 03:32:36","parcela_grupo":null,"parcela_numero":null,"parcela_total":null}
{"id":4,"amount":0.01,"description":"Centavo","date":"2026-11-01","category_id":33,"parcelado":0,"user_id":3,"created_at":"2026-11-08 03:32:36","parcela_grupo":null,"parcela_numero":null,"parcela_total":null}
{"id":5,"amount":999999999.99,"description":"Prêmio","date":"2026-11-01","category_id":33,"parcelado":0,"user_id":3,"created_at":"2026-11-08 03:32:36","parcela_grupo":null,"parcela_numero":null,"parcela_total":null}

-- password_resets: 0 linha(s)

-- users: 3 linha(s)
{"id":1,"name":"Ana Souza","email":"ana@teste.local","password":"$2b$10$…(hash bcrypt)","created_at":"2026-11-08 03:32:34"}
{"id":2,"name":"Bruno Lima","email":"bruno.lima@teste.local","password":"$2b$10$…(hash bcrypt)","created_at":"2026-11-08 03:32:34"}
{"id":3,"name":"Carla","email":"carla@teste.local","password":"$2b$10$…(hash bcrypt)","created_at":"2026-11-08 03:32:35"}

