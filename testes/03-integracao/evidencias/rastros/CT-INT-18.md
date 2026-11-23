# CT-INT-18 — categoria excluída em outro aparelho: o app ainda consegue lançar nessa categoria

Gerado em 2026-11-22T23:01:57.464669

### 01. Conferência no SQLite

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

### 02. Conferência no SQLite

```sql
SELECT id FROM categories WHERE user_id = ? AND name = 'Assinaturas'   -- params: [3]
```
```json
[
  {
    "id": 40
  }
]
```

> Outro aparelho do mesmo usuário: `DELETE /categories/40` → 204

### 03. Flutter → API: `POST /expenses` → **400**

Enviado pelo app:
```json
{
  "amount": 39.9,
  "description": "Streaming",
  "date": "2026-11-08",
  "category_id": 40,
  "parcelado": false
}
```
Resposta da API:
```json
{
  "error": "Categoria não encontrada para este usuário"
}
```

### 04. Flutter → API: `GET /categories` → **200**

Resposta da API:
```json
[
  {
    "id": 34,
    "name": "Alimentação",
    "type": "expense",
    "user_id": 3,
    "created_at": "2026-11-23 02:01:56"
  },
  {
    "id": 32,
    "name": "Bônus",
    "type": "income",
    "user_id": 3,
    "created_at": "2026-11-23 02:01:56"
  },
  {
    "id": 39,
    "name": "Compras",
    "type": "expense",
    "user_id": 3,
    "created_at": "2026-11-23 02:01:56"
  },
  {
    "id": 30,
    "name": "Freelance",
    "type": "income",
    "user_id": 3,
    "created_at": "2026-11-23 02:01:56"
  },
  {
    "id": 41,
    "name": "Impostos",
    "type": "expense",
    "user_id": 3,
    "created_at": "2026-11-23 02:01:56"
  },
  {
    "id": 31,
    "name": "Investimentos",
    "type": "income",
    "user_id": 3,
    "created_at": "2026-11-23 02:01:56"
  },
  {
    "id": 38,
    "name": "Lazer",
    "type": "expense",
    "user_id": 3,
    "created_at": "2026-11-23 02:01:56"
  },
  {
    "id": 36,
    "name": "Moradia",
    "type": "expense",
    "user_id": 3,
    "created_at": "2026-11-23 02:01:56"
  },
  {
    "id": 42,
    "name": "Outros",
    "type": "expense",
    "user_id": 3,
    "created_at": "2026-11-23 02:01:56"
  },
  {
    "id": 33,
    "name": "Outros",
    "type": "income",
    "user_id": 3,
    "created_at": "2026-11-23 02:01:56"
  },
  {
    "id": 43,
    "name": "Pets",
    "type": "expense",
    "user_id": 3,
    "created_at": "2026-11-23 02:01:56"
  },
  {
    "id": 29,
    "name": "Salário",
    "type": "income",
    "user_id": 3,
    "created_at": "2026-11-23 02:01:56"
  },
  {
    "id": 37,
    "name": "Saúde",
    "type": "expense",
    "user_id": 3,
    "created_at": "2026-11-23 02:01:56"
  },
  {
    "id": 35,
    "name": "Transporte",
    "type": "expense",
    "user_id": 3,
    "created_at": "2026-11-23 02:01:56"
  }
]
```

### 05. Flutter → API: `POST /categories` → **201**

Enviado pelo app:
```json
{
  "name": "Assinaturas",
  "type": "expense"
}
```
Resposta da API:
```json
{
  "id": 44,
  "name": "Assinaturas",
  "type": "expense",
  "user_id": 3
}
```

### 06. Flutter → API: `POST /expenses` → **201**

Enviado pelo app:
```json
{
  "amount": 39.9,
  "description": "Streaming",
  "date": "2026-11-08",
  "category_id": 44,
  "parcelado": false
}
```
Resposta da API:
```json
{
  "id": 19,
  "amount": 39.9,
  "description": "Streaming",
  "date": "2026-11-08",
  "category_id": 44,
  "parcelado": 0,
  "user_id": 3
}
```

### 07. Conferência no SQLite

```sql
SELECT c.name FROM expenses e JOIN categories c ON c.id = e.category_id WHERE e.id = ?   -- params: [19]
```
```json
[
  {
    "name": "Assinaturas"
  }
]
```

---

**Resultado: APROVADO ✅**
