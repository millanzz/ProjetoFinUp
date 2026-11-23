# CT-INT-10 — categoria nova digitada no app é criada uma única vez no SQLite

Gerado em 2026-11-23T09:15:33.060534

### 01. Flutter → API: `POST /categories` → **201**

Enviado pelo app:
```json
{
  "name": "Pets",
  "type": "expense"
}
```
Resposta da API:
```json
{
  "id": 43,
  "name": "Pets",
  "type": "expense",
  "user_id": 3
}
```

### 02. Flutter → API: `POST /expenses` → **201**

Enviado pelo app:
```json
{
  "amount": 120.0,
  "description": "Ração",
  "date": "2026-11-08",
  "category_id": 43,
  "parcelado": false
}
```
Resposta da API:
```json
{
  "id": 2,
  "amount": 120,
  "description": "Ração",
  "date": "2026-11-08",
  "category_id": 43,
  "parcelado": 0,
  "user_id": 3
}
```

### 03. Flutter → API: `GET /lancamentos?limit=0` → **200**

Resposta da API:
```json
{
  "itens": [],
  "total": 3,
  "proximo_offset": null,
  "receitas": 4500.75,
  "despesas": 132.5,
  "saldo": 4368.25,
  "categorias": [
    {
      "tipo": "receita",
      "categoria": "Salário",
      "total": 4500.75
    },
    {
      "tipo": "despesa",
      "categoria": "Pets",
      "total": 120
    },
    {
      "tipo": "despesa",
      "categoria": "Outros",
      "total": 12.5
    }
  ]
}
```

### 04. Flutter → API: `POST /expenses` → **201**

Enviado pelo app:
```json
{
  "amount": 250.0,
  "description": "Veterinário",
  "date": "2026-11-09",
  "category_id": 43,
  "parcelado": false
}
```
Resposta da API:
```json
{
  "id": 3,
  "amount": 250,
  "description": "Veterinário",
  "date": "2026-11-09",
  "category_id": 43,
  "parcelado": 0,
  "user_id": 3
}
```

### 05. Flutter → API: `GET /lancamentos?limit=0` → **200**

Resposta da API:
```json
{
  "itens": [],
  "total": 4,
  "proximo_offset": null,
  "receitas": 4500.75,
  "despesas": 382.5,
  "saldo": 4118.25,
  "categorias": [
    {
      "tipo": "receita",
      "categoria": "Salário",
      "total": 4500.75
    },
    {
      "tipo": "despesa",
      "categoria": "Pets",
      "total": 370
    },
    {
      "tipo": "despesa",
      "categoria": "Outros",
      "total": 12.5
    }
  ]
}
```

### 06. Conferência no SQLite

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

### 07. Conferência no SQLite

```sql
SELECT id, type FROM categories WHERE name = 'Pets' AND user_id = ?   -- params: [3]
```
```json
[
  {
    "id": 43,
    "type": "expense"
  }
]
```

### 08. Conferência no SQLite

```sql
SELECT COUNT(*) AS n FROM expenses WHERE category_id = ?   -- params: [43]
```
```json
[
  {
    "n": 2
  }
]
```

---

**Resultado: APROVADO ✅**
