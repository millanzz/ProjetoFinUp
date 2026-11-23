# CT-INT-11 — compra parcelada: 3 linhas no SQLite ligadas pelo grupo e o app lê as mesmas parcelas

Gerado em 2026-11-22T23:01:56.706227

### 01. Flutter → API: `POST /expenses` → **201**

Enviado pelo app:
```json
{
  "amount": 1000.0,
  "description": "Geladeira",
  "date": "2026-11-30",
  "category_id": 39,
  "parcelado": false,
  "parcelas": 3
}
```
Resposta da API:
```json
{
  "id": 4,
  "amount": 333.34,
  "date": "2026-11-30",
  "parcela_numero": 1,
  "description": "Geladeira",
  "category_id": 39,
  "parcelado": 1,
  "user_id": 3,
  "parcela_grupo": "2010b031-556a-4af9-8ff0-cfd67f66eafe",
  "parcela_total": 3,
  "valor_total": 1000,
  "parcelas": [
    {
      "id": 4,
      "amount": 333.34,
      "date": "2026-11-30",
      "parcela_numero": 1
    },
    {
      "id": 5,
      "amount": 333.33,
      "date": "2026-12-30",
      "parcela_numero": 2
    },
    {
      "id": 6,
      "amount": 333.33,
      "date": "2027-01-30",
      "parcela_numero": 3
    }
  ]
}
```

### 02. Conferência no SQLite

```sql
SELECT id, amount, date, parcelado, parcela_numero, parcela_total FROM expenses WHERE parcela_grupo = ? ORDER BY parcela_numero   -- params: [2010b031-556a-4af9-8ff0-cfd67f66eafe]
```
```json
[
  {
    "id": 4,
    "amount": 333.34,
    "date": "2026-11-30",
    "parcelado": 1,
    "parcela_numero": 1,
    "parcela_total": 3
  },
  {
    "id": 5,
    "amount": 333.33,
    "date": "2026-12-30",
    "parcelado": 1,
    "parcela_numero": 2,
    "parcela_total": 3
  },
  {
    "id": 6,
    "amount": 333.33,
    "date": "2027-01-30",
    "parcelado": 1,
    "parcela_numero": 3,
    "parcela_total": 3
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
    "created_at": "2026-11-23 02:01:56",
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
[
  {
    "id": 6,
    "amount": 333.33,
    "description": "Geladeira",
    "date": "2027-01-30",
    "category_id": 39,
    "parcelado": 1,
    "user_id": 3,
    "created_at": "2026-11-23 02:01:56",
    "parcela_grupo": "2010b031-556a-4af9-8ff0-cfd67f66eafe",
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
    "created_at": "2026-11-23 02:01:56",
    "parcela_grupo": "2010b031-556a-4af9-8ff0-cfd67f66eafe",
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
    "created_at": "2026-11-23 02:01:56",
    "parcela_grupo": "2010b031-556a-4af9-8ff0-cfd67f66eafe",
    "parcela_numero": 1,
    "parcela_total": 3,
    "category_name": "Compras"
  },
  {
    "id": 3,
    "amount": 250,
    "description": "Veterinário",
    "date": "2026-11-09",
    "category_id": 43,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 02:01:56",
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
    "created_at": "2026-11-23 02:01:56",
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
    "created_at": "2026-11-23 02:01:56",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  }
]
```

---

**Resultado: APROVADO ✅**
