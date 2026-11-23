# CT-INT-16 — datas especiais (29/02, virada de ano) chegam iguais ao SQLite, ao filtro por mês e ao app

Gerado em 2026-11-22T23:01:57.261561

### 01. Flutter → API: `POST /expenses` → **201**

Enviado pelo app:
```json
{
  "amount": 10.0,
  "description": "Data 2028-02-29",
  "date": "2028-02-29",
  "category_id": 42,
  "parcelado": false
}
```
Resposta da API:
```json
{
  "id": 16,
  "amount": 10,
  "description": "Data 2028-02-29",
  "date": "2028-02-29",
  "category_id": 42,
  "parcelado": 0,
  "user_id": 3
}
```

### 02. Flutter → API: `POST /expenses` → **201**

Enviado pelo app:
```json
{
  "amount": 10.0,
  "description": "Data 2026-12-31",
  "date": "2026-12-31",
  "category_id": 42,
  "parcelado": false
}
```
Resposta da API:
```json
{
  "id": 17,
  "amount": 10,
  "description": "Data 2026-12-31",
  "date": "2026-12-31",
  "category_id": 42,
  "parcelado": 0,
  "user_id": 3
}
```

### 03. Flutter → API: `POST /expenses` → **201**

Enviado pelo app:
```json
{
  "amount": 10.0,
  "description": "Data 2027-01-01",
  "date": "2027-01-01",
  "category_id": 42,
  "parcelado": false
}
```
Resposta da API:
```json
{
  "id": 18,
  "amount": 10,
  "description": "Data 2027-01-01",
  "date": "2027-01-01",
  "category_id": 42,
  "parcelado": 0,
  "user_id": 3
}
```

### 04. Conferência no SQLite

```sql
SELECT date FROM expenses WHERE id IN (16,17,18) ORDER BY id
```
```json
[
  {
    "date": "2028-02-29"
  },
  {
    "date": "2026-12-31"
  },
  {
    "date": "2027-01-01"
  }
]
```

### 05. Flutter → API: `GET /expenses?month=2028-02` → **200**

Resposta da API:
```json
[
  {
    "id": 16,
    "amount": 10,
    "description": "Data 2028-02-29",
    "date": "2028-02-29",
    "category_id": 42,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 02:01:57",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  }
]
```

### 06. Flutter → API: `GET /incomes` → **200**

Resposta da API:
```json
[
  {
    "id": 3,
    "amount": 1200.5,
    "description": "Freela",
    "date": "2026-11-20",
    "category_id": 30,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 02:01:57",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Freelance"
  },
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
  },
  {
    "id": 5,
    "amount": 999999999.99,
    "description": "Prêmio",
    "date": "2026-11-01",
    "category_id": 33,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 02:01:57",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  },
  {
    "id": 4,
    "amount": 0.01,
    "description": "Centavo",
    "date": "2026-11-01",
    "category_id": 33,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 02:01:57",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  }
]
```

### 07. Flutter → API: `GET /expenses` → **200**

Resposta da API:
```json
[
  {
    "id": 16,
    "amount": 10,
    "description": "Data 2028-02-29",
    "date": "2028-02-29",
    "category_id": 42,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 02:01:57",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  },
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
    "id": 18,
    "amount": 10,
    "description": "Data 2027-01-01",
    "date": "2027-01-01",
    "category_id": 42,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 02:01:57",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  },
  {
    "id": 17,
    "amount": 10,
    "description": "Data 2026-12-31",
    "date": "2026-12-31",
    "category_id": 42,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 02:01:57",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
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
    "id": 15,
    "amount": 250.25,
    "description": "Luz",
    "date": "2026-11-21",
    "category_id": 36,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 02:01:57",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Moradia"
  },
  {
    "id": 7,
    "amount": 95.5,
    "description": "Mercado do mês",
    "date": "2026-11-12",
    "category_id": 34,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 02:01:56",
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
