# CT-INT-08 — receita com acentos e emoji: Flutter → API → SQLite → Flutter sem perder nada

Gerado em 2026-11-23T09:15:32.718432

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

### 02. Flutter → API: `GET /lancamentos?limit=0` → **200**

Resposta da API:
```json
{
  "itens": [],
  "total": 1,
  "proximo_offset": null,
  "receitas": 4500.75,
  "despesas": 0,
  "saldo": 4500.75,
  "categorias": [
    {
      "tipo": "receita",
      "categoria": "Salário",
      "total": 4500.75
    }
  ]
}
```

### 03. Conferência no SQLite

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

### 04. Flutter → API: `GET /lancamentos?from=2026-11-01&limit=1000&offset=0` → **200**

Resposta da API:
```json
{
  "itens": [
    {
      "id": 2,
      "amount": 4500.75,
      "description": "Salário de novembro — açaí, pão & café ☕🍇",
      "date": "2026-11-08",
      "category_id": 29,
      "parcelado": 0,
      "user_id": 3,
      "created_at": "2026-11-23 12:15:32",
      "parcela_grupo": null,
      "parcela_numero": null,
      "parcela_total": null,
      "category_name": "Salário",
      "tipo": "receita"
    }
  ],
  "total": 1,
  "proximo_offset": null,
  "receitas": 4500.75,
  "despesas": 0,
  "saldo": 4500.75,
  "categorias": [
    {
      "tipo": "receita",
      "categoria": "Salário",
      "total": 4500.75
    }
  ]
}
```

### 05. Flutter → API: `GET /lancamentos?limit=0` → **200**

Resposta da API:
```json
{
  "itens": [],
  "total": 1,
  "proximo_offset": null,
  "receitas": 4500.75,
  "despesas": 0,
  "saldo": 4500.75,
  "categorias": [
    {
      "tipo": "receita",
      "categoria": "Salário",
      "total": 4500.75
    }
  ]
}
```

### 06. Flutter → API: `GET /lancamentos/meses` → **200**

Resposta da API:
```json
[
  "2026-11"
]
```

---

**Resultado: APROVADO ✅**
