# CT-INT-12 — editar lançamento no app altera a mesma linha no SQLite (id e quantidade preservados)

Gerado em 2026-11-22T21:37:52.101812

### 01. Flutter → API: `POST /expenses` → **201**

Enviado pelo app:
```json
{
  "amount": 80.0,
  "description": "Mercado",
  "date": "2026-11-10",
  "category_id": 34,
  "parcelado": false
}
```
Resposta da API:
```json
{
  "id": 7,
  "amount": 80,
  "description": "Mercado",
  "date": "2026-11-10",
  "category_id": 34,
  "parcelado": 0,
  "user_id": 3
}
```

### 02. Conferência no SQLite

```sql
SELECT COUNT(*) AS n FROM expenses
```
```json
[
  {
    "n": 7
  }
]
```

### 03. Flutter → API: `PUT /expenses/7` → **200**

Enviado pelo app:
```json
{
  "amount": 95.5,
  "description": "Mercado do mês",
  "date": "2026-11-12",
  "category_id": 34,
  "parcelado": false
}
```
Resposta da API:
```json
{
  "message": "Despesa atualizada"
}
```

### 04. Conferência no SQLite

```sql
SELECT e.amount, e.description, e.date, c.name AS categoria FROM expenses e JOIN categories c ON c.id = e.category_id WHERE e.id = ?   -- params: [7]
```
```json
[
  {
    "amount": 95.5,
    "description": "Mercado do mês",
    "date": "2026-11-12",
    "categoria": "Alimentação"
  }
]
```

### 05. Conferência no SQLite

```sql
SELECT COUNT(*) AS n FROM expenses
```
```json
[
  {
    "n": 7
  }
]
```

### 06. Flutter → API: `GET /incomes` → **200**

Resposta da API:
```json
[
  {
    "id": 2,
    "amount": 4500.75,
    "description": "Salário de novembro — açaí, pão & café ☕🍇",
    "date": "2026-11-08",
    "category_id": 29,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:51",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Salário"
  }
]
```

### 07. Flutter → API: `GET /expenses` → **200**

Resposta da API:
```json
[
  {
    "id": 6,
    "amount": 333.33,
    "description": "Geladeira",
    "date": "2027-01-30",
    "category_id": 39,
    "parcelado": 1,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": "12eedf61-0082-4913-a2f5-39de74064cd2",
    "parcela_numero": 3,
    "parcela_total": 3,
    "category_name": "Compras"
  },
  {
    "id": 5,
    "amount": 333.33,
    "description": "Geladeira",
    "date": "2026-12-30",
    "category_id": 39,
    "parcelado": 1,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": "12eedf61-0082-4913-a2f5-39de74064cd2",
    "parcela_numero": 2,
    "parcela_total": 3,
    "category_name": "Compras"
  },
  {
    "id": 4,
    "amount": 333.34,
    "description": "Geladeira",
    "date": "2026-11-30",
    "category_id": 39,
    "parcelado": 1,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": "12eedf61-0082-4913-a2f5-39de74064cd2",
    "parcela_numero": 1,
    "parcela_total": 3,
    "category_name": "Compras"
  },
  {
    "id": 7,
    "amount": 95.5,
    "description": "Mercado do mês",
    "date": "2026-11-12",
    "category_id": 34,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Alimentação"
  },
  {
    "id": 3,
    "amount": 250,
    "description": "Veterinário",
    "date": "2026-11-09",
    "category_id": 43,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:51",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Pets"
  },
  {
    "id": 2,
    "amount": 120,
    "description": "Ração",
    "date": "2026-11-08",
    "category_id": 43,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:51",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Pets"
  },
  {
    "id": 1,
    "amount": 12.5,
    "description": "Sem categoria",
    "date": "2026-11-08",
    "category_id": 42,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:51",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  }
]
```

---

**Resultado: APROVADO ✅**
