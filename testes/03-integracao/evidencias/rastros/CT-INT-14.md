# CT-INT-14 — saldo igual nas três camadas: app (cache), API (/dashboard) e SQLite (SUM)

Gerado em 2026-11-23T09:15:33.781865

### 01. Flutter → API: `POST /incomes` → **201**

Enviado pelo app:
```json
{
  "amount": 1200.5,
  "description": "Freela",
  "date": "2026-11-20",
  "category_id": 30,
  "parcelado": false
}
```
Resposta da API:
```json
{
  "id": 3,
  "amount": 1200.5,
  "description": "Freela",
  "date": "2026-11-20",
  "category_id": 30,
  "parcelado": 0,
  "user_id": 3
}
```

### 02. Flutter → API: `GET /lancamentos?limit=0` → **200**

Resposta da API:
```json
{
  "itens": [],
  "total": 9,
  "proximo_offset": null,
  "receitas": 5701.25,
  "despesas": 1478,
  "saldo": 4223.25,
  "categorias": [
    {
      "tipo": "receita",
      "categoria": "Salário",
      "total": 4500.75
    },
    {
      "tipo": "receita",
      "categoria": "Freelance",
      "total": 1200.5
    },
    {
      "tipo": "despesa",
      "categoria": "Compras",
      "total": 1000
    },
    {
      "tipo": "despesa",
      "categoria": "Pets",
      "total": 370
    },
    {
      "tipo": "despesa",
      "categoria": "Alimentação",
      "total": 95.5
    },
    {
      "tipo": "despesa",
      "categoria": "Outros",
      "total": 12.5
    }
  ]
}
```

### 03. Flutter → API: `POST /expenses` → **201**

Enviado pelo app:
```json
{
  "amount": 250.25,
  "description": "Luz",
  "date": "2026-11-21",
  "category_id": 36,
  "parcelado": false
}
```
Resposta da API:
```json
{
  "id": 15,
  "amount": 250.25,
  "description": "Luz",
  "date": "2026-11-21",
  "category_id": 36,
  "parcelado": 0,
  "user_id": 3
}
```

### 04. Flutter → API: `GET /lancamentos?limit=0` → **200**

Resposta da API:
```json
{
  "itens": [],
  "total": 10,
  "proximo_offset": null,
  "receitas": 5701.25,
  "despesas": 1728.25,
  "saldo": 3973,
  "categorias": [
    {
      "tipo": "receita",
      "categoria": "Salário",
      "total": 4500.75
    },
    {
      "tipo": "receita",
      "categoria": "Freelance",
      "total": 1200.5
    },
    {
      "tipo": "despesa",
      "categoria": "Compras",
      "total": 1000
    },
    {
      "tipo": "despesa",
      "categoria": "Pets",
      "total": 370
    },
    {
      "tipo": "despesa",
      "categoria": "Moradia",
      "total": 250.25
    },
    {
      "tipo": "despesa",
      "categoria": "Alimentação",
      "total": 95.5
    },
    {
      "tipo": "despesa",
      "categoria": "Outros",
      "total": 12.5
    }
  ]
}
```

### 05. Flutter → API: `GET /lancamentos?from=2026-11-01&limit=1000&offset=0` → **200**

Resposta da API:
```json
{
  "itens": [
    {
      "id": 6,
      "amount": 333.33,
      "description": "Geladeira",
      "date": "2027-01-30",
      "category_id": 39,
      "parcelado": 1,
      "user_id": 3,
      "created_at": "2026-11-23 12:15:33",
      "parcela_grupo": "d6d2002a-9421-4d98-a447-a23dce88d482",
      "parcela_numero": 3,
      "parcela_total": 3,
      "category_name": "Compras",
      "tipo": "despesa"
    },
    {
      "id": 5,
      "amount": 333.33,
      "description": "Geladeira",
      "date": "2026-12-30",
      "category_id": 39,
      "parcelado": 1,
      "user_id": 3,
      "created_at": "2026-11-23 12:15:33",
      "parcela_grupo": "d6d2002a-9421-4d98-a447-a23dce88d482",
      "parcela_numero": 2,
      "parcela_total": 3,
      "category_name": "Compras",
      "tipo": "despesa"
    },
    {
      "id": 4,
      "amount": 333.34,
      "description": "Geladeira",
      "date": "2026-11-30",
      "category_id": 39,
      "parcelado": 1,
      "user_id": 3,
      "created_at": "2026-11-23 12:15:33",
      "parcela_grupo": "d6d2002a-9421-4d98-a447-a23dce88d482",
      "parcela_numero": 1,
      "parcela_total": 3,
      "category_name": "Compras",
      "tipo": "despesa"
    },
    {
      "id": 15,
      "amount": 250.25,
      "description": "Luz",
      "date": "2026-11-21",
      "category_id": 36,
      "parcelado": 0,
      "user_id": 3,
      "created_at": "2026-11-23 12:15:33",
      "parcela_grupo": null,
      "parcela_numero": null,
      "parcela_total": null,
      "category_name": "Moradia",
      "tipo": "despesa"
    },
    {
      "id": 3,
      "amount": 1200.5,
      "description": "Freela",
      "date": "2026-11-20",
      "category_id": 30,
      "parcelado": 0,
      "user_id": 3,
      "created_at": "2026-11-23 12:15:33",
      "parcela_grupo": null,
      "parcela_numero": null,
      "parcela_total": null,
      "category_name": "Freelance",
      "tipo": "receita"
    },
    {
      "id": 7,
      "amount": 95.5,
      "description": "Mercado do mês",
      "date": "2026-11-12",
      "category_id": 34,
      "parcelado": 0,
      "user_id": 3,
      "created_at": "2026-11-23 12:15:33",
      "parcela_grupo": null,
      "parcela_numero": null,
      "parcela_total": null,
      "category_name": "Alimentação",
      "tipo": "despesa"
    },
    {
      "id": 3,
      "amount": 250,
      "description": "Veterinário",
      "date": "2026-11-09",
      "category_id": 43,
      "parcelado": 0,
      "user_id": 3,
      "created_at": "2026-11-23 12:15:33",
      "parcela_grupo": null,
      "parcela_numero": null,
      "parcela_total": null,
      "category_name": "Pets",
      "tipo": "despesa"
    },
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
    },
    {
      "id": 2,
      "amount": 120,
      "description": "Ração",
      "date": "2026-11-08",
      "category_id": 43,
      "parcelado": 0,
      "user_id": 3,
      "created_at": "2026-11-23 12:15:33",
      "parcela_grupo": null,
      "parcela_numero": null,
      "parcela_total": null,
      "category_name": "Pets",
      "tipo": "despesa"
    },
    {
      "id": 1,
      "amount": 12.5,
      "description": "Sem categoria",
      "date": "2026-11-08",
      "category_id": 42,
      "parcelado": 0,
      "user_id": 3,
      "created_at": "2026-11-23 12:15:32",
      "parcela_grupo": null,
      "parcela_numero": null,
      "parcela_total": null,
      "category_name": "Outros",
      "tipo": "despesa"
    }
  ],
  "total": 10,
  "proximo_offset": null,
  "receitas": 5701.25,
  "despesas": 1728.25,
  "saldo": 3973,
  "categorias": [
    {
      "tipo": "receita",
      "categoria": "Salário",
      "total": 4500.75
    },
    {
      "tipo": "receita",
      "categoria": "Freelance",
      "total": 1200.5
    },
    {
      "tipo": "despesa",
      "categoria": "Compras",
      "total": 1000
    },
    {
      "tipo": "despesa",
      "categoria": "Pets",
      "total": 370
    },
    {
      "tipo": "despesa",
      "categoria": "Moradia",
      "total": 250.25
    },
    {
      "tipo": "despesa",
      "categoria": "Alimentação",
      "total": 95.5
    },
    {
      "tipo": "despesa",
      "categoria": "Outros",
      "total": 12.5
    }
  ]
}
```

### 06. Flutter → API: `GET /lancamentos?limit=0` → **200**

Resposta da API:
```json
{
  "itens": [],
  "total": 10,
  "proximo_offset": null,
  "receitas": 5701.25,
  "despesas": 1728.25,
  "saldo": 3973,
  "categorias": [
    {
      "tipo": "receita",
      "categoria": "Salário",
      "total": 4500.75
    },
    {
      "tipo": "receita",
      "categoria": "Freelance",
      "total": 1200.5
    },
    {
      "tipo": "despesa",
      "categoria": "Compras",
      "total": 1000
    },
    {
      "tipo": "despesa",
      "categoria": "Pets",
      "total": 370
    },
    {
      "tipo": "despesa",
      "categoria": "Moradia",
      "total": 250.25
    },
    {
      "tipo": "despesa",
      "categoria": "Alimentação",
      "total": 95.5
    },
    {
      "tipo": "despesa",
      "categoria": "Outros",
      "total": 12.5
    }
  ]
}
```

### 07. Flutter → API: `GET /lancamentos/meses` → **200**

Resposta da API:
```json
[
  "2027-01",
  "2026-12",
  "2026-11"
]
```

### 08. Conferência no SQLite

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

### 09. Conferência no SQLite

```sql
SELECT (SELECT COALESCE(SUM(amount),0) FROM incomes WHERE user_id = ?) AS receitas,
                  (SELECT COALESCE(SUM(amount),0) FROM expenses WHERE user_id = ?) AS despesas   -- params: [3, 3]
```
```json
[
  {
    "receitas": 5701.25,
    "despesas": 1728.25
  }
]
```

### 10. Flutter → API: `GET /dashboard` → **200**

Resposta da API:
```json
{
  "balance": 3973,
  "total_incomes": 5701.25,
  "total_expenses": 1728.25,
  "expenses_by_category": [
    {
      "category": "Compras",
      "total": 1000
    },
    {
      "category": "Pets",
      "total": 370
    },
    {
      "category": "Moradia",
      "total": 250.25
    },
    {
      "category": "Alimentação",
      "total": 95.5
    },
    {
      "category": "Outros",
      "total": 12.5
    }
  ],
  "incomes_by_category": [
    {
      "category": "Salário",
      "total": 4500.75
    },
    {
      "category": "Freelance",
      "total": 1200.5
    }
  ],
  "monthly": [
    {
      "month": "2026-11",
      "incomes": 5701.25,
      "expenses": 1061.59
    },
    {
      "month": "2026-12",
      "incomes": 0,
      "expenses": 333.33
    },
    {
      "month": "2027-01",
      "incomes": 0,
      "expenses": 333.33
    }
  ]
}
```

> Saldo — app: 3973.0 | API: 3973 | SQLite: 3973.0

---

**Resultado: APROVADO ✅**
