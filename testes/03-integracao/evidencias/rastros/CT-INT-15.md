# CT-INT-15 — valores-limite (R$ 0,01 e R$ 999.999.999,99) chegam iguais ao SQLite e voltam iguais ao app

Gerado em 2026-11-23T09:15:33.977926

### 01. Flutter → API: `POST /incomes` → **201**

Enviado pelo app:
```json
{
  "amount": 0.01,
  "description": "Centavo",
  "date": "2026-11-01",
  "category_id": 33,
  "parcelado": false
}
```
Resposta da API:
```json
{
  "id": 4,
  "amount": 0.01,
  "description": "Centavo",
  "date": "2026-11-01",
  "category_id": 33,
  "parcelado": 0,
  "user_id": 3
}
```

### 02. Flutter → API: `GET /lancamentos?limit=0` → **200**

Resposta da API:
```json
{
  "itens": [],
  "total": 11,
  "proximo_offset": null,
  "receitas": 5701.26,
  "despesas": 1728.25,
  "saldo": 3973.01,
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
      "tipo": "receita",
      "categoria": "Outros",
      "total": 0.01
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

### 03. Flutter → API: `POST /incomes` → **201**

Enviado pelo app:
```json
{
  "amount": 999999999.99,
  "description": "Prêmio",
  "date": "2026-11-01",
  "category_id": 33,
  "parcelado": false
}
```
Resposta da API:
```json
{
  "id": 5,
  "amount": 999999999.99,
  "description": "Prêmio",
  "date": "2026-11-01",
  "category_id": 33,
  "parcelado": 0,
  "user_id": 3
}
```

### 04. Flutter → API: `GET /lancamentos?limit=0` → **200**

Resposta da API:
```json
{
  "itens": [],
  "total": 12,
  "proximo_offset": null,
  "receitas": 1000005701.25,
  "despesas": 1728.25,
  "saldo": 1000003973,
  "categorias": [
    {
      "tipo": "receita",
      "categoria": "Outros",
      "total": 1000000000
    },
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

### 05. Conferência no SQLite

```sql
SELECT id, amount FROM incomes WHERE id IN (?, ?) ORDER BY amount   -- params: [4, 5]
```
```json
[
  {
    "id": 4,
    "amount": 0.01
  },
  {
    "id": 5,
    "amount": 999999999.99
  }
]
```

### 06. Flutter → API: `GET /lancamentos?from=2026-11-01&limit=1000&offset=0` → **200**

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
    },
    {
      "id": 5,
      "amount": 999999999.99,
      "description": "Prêmio",
      "date": "2026-11-01",
      "category_id": 33,
      "parcelado": 0,
      "user_id": 3,
      "created_at": "2026-11-23 12:15:34",
      "parcela_grupo": null,
      "parcela_numero": null,
      "parcela_total": null,
      "category_name": "Outros",
      "tipo": "receita"
    },
    {
      "id": 4,
      "amount": 0.01,
      "description": "Centavo",
      "date": "2026-11-01",
      "category_id": 33,
      "parcelado": 0,
      "user_id": 3,
      "created_at": "2026-11-23 12:15:33",
      "parcela_grupo": null,
      "parcela_numero": null,
      "parcela_total": null,
      "category_name": "Outros",
      "tipo": "receita"
    }
  ],
  "total": 12,
  "proximo_offset": null,
  "receitas": 1000005701.25,
  "despesas": 1728.25,
  "saldo": 1000003973,
  "categorias": [
    {
      "tipo": "receita",
      "categoria": "Outros",
      "total": 1000000000
    },
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

### 07. Flutter → API: `GET /lancamentos?limit=0` → **200**

Resposta da API:
```json
{
  "itens": [],
  "total": 12,
  "proximo_offset": null,
  "receitas": 1000005701.25,
  "despesas": 1728.25,
  "saldo": 1000003973,
  "categorias": [
    {
      "tipo": "receita",
      "categoria": "Outros",
      "total": 1000000000
    },
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

### 08. Flutter → API: `GET /lancamentos/meses` → **200**

Resposta da API:
```json
[
  "2027-01",
  "2026-12",
  "2026-11"
]
```

---

**Resultado: APROVADO ✅**
