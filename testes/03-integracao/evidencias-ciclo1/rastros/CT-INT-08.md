# CT-INT-08 — receita com acentos e emoji: Flutter → API → SQLite → Flutter sem perder nada

Gerado em 2026-11-22T21:37:51.706699

### 01. Flutter → API: `POST /incomes` → **201**

Enviado pelo app:
```json
{
  "amount": 4500.75,
  "description": "Salário de novembro — açaí, pão & café ☕🍇",
  "date": "2026-11-08",
  "category_id": 29,
  "parcelado": false
}
```
Resposta da API:
```json
{
  "id": 2,
  "amount": 4500.75,
  "description": "Salário de novembro — açaí, pão & café ☕🍇",
  "date": "2026-11-08",
  "category_id": 29,
  "parcelado": 0,
  "user_id": 3
}
```

### 02. Conferência no SQLite

```sql
SELECT i.id, i.amount, typeof(i.amount) AS tipo_amount, i.description, i.date, i.parcelado,
                  c.name AS categoria, c.type AS tipo_categoria, u.email
           FROM incomes i JOIN categories c ON c.id = i.category_id JOIN users u ON u.id = i.user_id
           WHERE i.id = ?   -- params: [2]
```
```json
[
  {
    "id": 2,
    "amount": 4500.75,
    "tipo_amount": "real",
    "description": "Salário de novembro — açaí, pão & café ☕🍇",
    "date": "2026-11-08",
    "parcelado": 0,
    "categoria": "Salário",
    "tipo_categoria": "income",
    "email": "carla@teste.local"
  }
]
```

### 03. Flutter → API: `GET /incomes` → **200**

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

### 04. Flutter → API: `GET /expenses` → **200**

Resposta da API:
```json
[]
```

---

**Resultado: APROVADO ✅**
