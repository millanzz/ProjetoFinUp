# CT-INT-12 — editar lançamento no app altera a mesma linha no SQLite (id e quantidade preservados)

Gerado em 2026-11-23T09:15:33.392199

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

### 02. Flutter → API: `GET /lancamentos?limit=0` → **200**

Resposta da API:
```json
{
  "itens": [],
  "total": 8,
  "proximo_offset": null,
  "receitas": 4500.75,
  "despesas": 1462.5,
  "saldo": 3038.25,
  "categorias": [
    {
      "tipo": "receita",
      "categoria": "Salário",
      "total": 4500.75
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
      "total": 80
    },
    {
      "tipo": "despesa",
      "categoria": "Outros",
      "total": 12.5
    }
  ]
}
```

### 03. Conferência no SQLite

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

### 04. Flutter → API: `PUT /expenses/7` → **200**

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

### 05. Flutter → API: `GET /lancamentos?limit=0` → **200**

Resposta da API:
```json
{
  "itens": [],
  "total": 8,
  "proximo_offset": null,
  "receitas": 4500.75,
  "despesas": 1478,
  "saldo": 3022.75,
  "categorias": [
    {
      "tipo": "receita",
      "categoria": "Salário",
      "total": 4500.75
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

### 06. Conferência no SQLite

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

### 07. Conferência no SQLite

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

### 08. Flutter → API: `GET /lancamentos?limit=0` → **200**

Resposta da API:
```json
{
  "itens": [],
  "total": 8,
  "proximo_offset": null,
  "receitas": 4500.75,
  "despesas": 1478,
  "saldo": 3022.75,
  "categorias": [
    {
      "tipo": "receita",
      "categoria": "Salário",
      "total": 4500.75
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

### 09. Flutter → API: `GET /lancamentos/meses` → **200**

Resposta da API:
```json
[
  "2027-01",
  "2026-12",
  "2026-11"
]
```

### 10. Flutter → API: `GET /lancamentos?from=2026-11-01&limit=1000&offset=0` → **200**

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
  "total": 8,
  "proximo_offset": null,
  "receitas": 4500.75,
  "despesas": 1478,
  "saldo": 3022.75,
  "categorias": [
    {
      "tipo": "receita",
      "categoria": "Salário",
      "total": 4500.75
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

---

**Resultado: APROVADO ✅**
