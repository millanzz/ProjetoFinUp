# CT-INT-07 — trocar de usuário no mesmo aparelho não mostra dados do anterior

Gerado em 2026-11-23T09:15:32.288341

### 01. Flutter → API: `POST /auth/login` → **200**

Enviado pelo app:
```json
{
  "email": "ana@teste.local",
  "password": "***"
}
```
Resposta da API:
```json
{
  "token": "eyJhbGciOiJI…(JWT)",
  "user": {
    "id": 1,
    "name": "Ana Souza",
    "email": "ana@teste.local"
  }
}
```

### 02. Flutter → API: `GET /categories` → **200**

Resposta da API:
```json
[
  {
    "id": 6,
    "name": "Alimentação",
    "type": "expense",
    "user_id": 1,
    "created_at": "2026-11-23 12:15:31"
  },
  {
    "id": 12,
    "name": "Assinaturas",
    "type": "expense",
    "user_id": 1,
    "created_at": "2026-11-23 12:15:31"
  },
  {
    "id": 4,
    "name": "Bônus",
    "type": "income",
    "user_id": 1,
    "created_at": "2026-11-23 12:15:31"
  },
  {
    "id": 11,
    "name": "Compras",
    "type": "expense",
    "user_id": 1,
    "created_at": "2026-11-23 12:15:31"
  },
  {
    "id": 2,
    "name": "Freelance",
    "type": "income",
    "user_id": 1,
    "created_at": "2026-11-23 12:15:31"
  },
  {
    "id": 13,
    "name": "Impostos",
    "type": "expense",
    "user_id": 1,
    "created_at": "2026-11-23 12:15:31"
  },
  {
    "id": 3,
    "name": "Investimentos",
    "type": "income",
    "user_id": 1,
    "created_at": "2026-11-23 12:15:31"
  },
  {
    "id": 10,
    "name": "Lazer",
    "type": "expense",
    "user_id": 1,
    "created_at": "2026-11-23 12:15:31"
  },
  {
    "id": 8,
    "name": "Moradia",
    "type": "expense",
    "user_id": 1,
    "created_at": "2026-11-23 12:15:31"
  },
  {
    "id": 14,
    "name": "Outros",
    "type": "expense",
    "user_id": 1,
    "created_at": "2026-11-23 12:15:31"
  },
  {
    "id": 5,
    "name": "Outros",
    "type": "income",
    "user_id": 1,
    "created_at": "2026-11-23 12:15:31"
  },
  {
    "id": 1,
    "name": "Salário",
    "type": "income",
    "user_id": 1,
    "created_at": "2026-11-23 12:15:31"
  },
  {
    "id": 9,
    "name": "Saúde",
    "type": "expense",
    "user_id": 1,
    "created_at": "2026-11-23 12:15:31"
  },
  {
    "id": 7,
    "name": "Transporte",
    "type": "expense",
    "user_id": 1,
    "created_at": "2026-11-23 12:15:31"
  }
]
```

### 03. Flutter → API: `POST /incomes` → **201**

Enviado pelo app:
```json
{
  "amount": 4000.0,
  "description": "Salário da Ana",
  "date": "2026-11-05",
  "category_id": 1,
  "parcelado": false
}
```
Resposta da API:
```json
{
  "id": 1,
  "amount": 4000,
  "description": "Salário da Ana",
  "date": "2026-11-05",
  "category_id": 1,
  "parcelado": 0,
  "user_id": 1
}
```

### 04. Flutter → API: `GET /lancamentos?limit=0` → **200**

Resposta da API:
```json
{
  "itens": [],
  "total": 1,
  "proximo_offset": null,
  "receitas": 4000,
  "despesas": 0,
  "saldo": 4000,
  "categorias": [
    {
      "tipo": "receita",
      "categoria": "Salário",
      "total": 4000
    }
  ]
}
```

### 05. Flutter → API: `POST /users` → **201**

Enviado pelo app:
```json
{
  "name": "Carla",
  "email": "carla@teste.local",
  "password": "***"
}
```
Resposta da API:
```json
{
  "id": 3,
  "name": "Carla",
  "email": "carla@teste.local"
}
```

### 06. Flutter → API: `POST /auth/login` → **200**

Enviado pelo app:
```json
{
  "email": "carla@teste.local",
  "password": "***"
}
```
Resposta da API:
```json
{
  "token": "eyJhbGciOiJI…(JWT)",
  "user": {
    "id": 3,
    "name": "Carla",
    "email": "carla@teste.local"
  }
}
```

### 07. Flutter → API: `GET /lancamentos?from=2026-11-01&limit=1000&offset=0` → **200**

Resposta da API:
```json
{
  "itens": [],
  "total": 0,
  "proximo_offset": null,
  "receitas": 0,
  "despesas": 0,
  "saldo": 0,
  "categorias": []
}
```

### 08. Flutter → API: `GET /lancamentos?limit=0` → **200**

Resposta da API:
```json
{
  "itens": [],
  "total": 0,
  "proximo_offset": null,
  "receitas": 0,
  "despesas": 0,
  "saldo": 0,
  "categorias": []
}
```

### 09. Flutter → API: `GET /lancamentos/meses` → **200**

Resposta da API:
```json
[]
```

### 10. Flutter → API: `GET /categories` → **200**

Resposta da API:
```json
[
  {
    "id": 34,
    "name": "Alimentação",
    "type": "expense",
    "user_id": 3,
    "created_at": "2026-11-23 12:15:32"
  },
  {
    "id": 40,
    "name": "Assinaturas",
    "type": "expense",
    "user_id": 3,
    "created_at": "2026-11-23 12:15:32"
  },
  {
    "id": 32,
    "name": "Bônus",
    "type": "income",
    "user_id": 3,
    "created_at": "2026-11-23 12:15:32"
  },
  {
    "id": 39,
    "name": "Compras",
    "type": "expense",
    "user_id": 3,
    "created_at": "2026-11-23 12:15:32"
  },
  {
    "id": 30,
    "name": "Freelance",
    "type": "income",
    "user_id": 3,
    "created_at": "2026-11-23 12:15:32"
  },
  {
    "id": 41,
    "name": "Impostos",
    "type": "expense",
    "user_id": 3,
    "created_at": "2026-11-23 12:15:32"
  },
  {
    "id": 31,
    "name": "Investimentos",
    "type": "income",
    "user_id": 3,
    "created_at": "2026-11-23 12:15:32"
  },
  {
    "id": 38,
    "name": "Lazer",
    "type": "expense",
    "user_id": 3,
    "created_at": "2026-11-23 12:15:32"
  },
  {
    "id": 36,
    "name": "Moradia",
    "type": "expense",
    "user_id": 3,
    "created_at": "2026-11-23 12:15:32"
  },
  {
    "id": 42,
    "name": "Outros",
    "type": "expense",
    "user_id": 3,
    "created_at": "2026-11-23 12:15:32"
  },
  {
    "id": 33,
    "name": "Outros",
    "type": "income",
    "user_id": 3,
    "created_at": "2026-11-23 12:15:32"
  },
  {
    "id": 29,
    "name": "Salário",
    "type": "income",
    "user_id": 3,
    "created_at": "2026-11-23 12:15:32"
  },
  {
    "id": 37,
    "name": "Saúde",
    "type": "expense",
    "user_id": 3,
    "created_at": "2026-11-23 12:15:32"
  },
  {
    "id": 35,
    "name": "Transporte",
    "type": "expense",
    "user_id": 3,
    "created_at": "2026-11-23 12:15:32"
  }
]
```

### 11. Conferência no SQLite

```sql
SELECT id FROM users WHERE email = ?   -- params: [carla@teste.local]
```
```json
[
  {
    "id": 3
  }
]
```

### 12. Conferência no SQLite

```sql
SELECT user_id, description FROM incomes WHERE description = ?   -- params: [Salário da Ana]
```
```json
[
  {
    "user_id": 1,
    "description": "Salário da Ana"
  }
]
```

---

**Resultado: APROVADO ✅**
