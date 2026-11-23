# CT-INT-25 — banco de versão anterior é migrado pela API e lido corretamente pelo app

Gerado em 2026-11-22T21:37:56.979165

> Banco antigo criado (sem colunas de parcela, metas com emoji): Banco legado criado em C:\Users\Pingo\Desktop\FableFinUp\testes\03-integracao\evidencias\banco-legado-migrado.db

### 01. Conferência no SQLite

```sql
SELECT name FROM pragma_table_info('incomes')
```
```json
[
  {
    "name": "id"
  },
  {
    "name": "amount"
  },
  {
    "name": "description"
  },
  {
    "name": "date"
  },
  {
    "name": "category_id"
  },
  {
    "name": "user_id"
  },
  {
    "name": "created_at"
  },
  {
    "name": "parcelado"
  },
  {
    "name": "parcela_grupo"
  },
  {
    "name": "parcela_numero"
  },
  {
    "name": "parcela_total"
  }
]
```

### 02. Flutter → API: `POST /auth/login` → **200**

Enviado pelo app:
```json
{
  "email": "legado@teste.local",
  "password": "***"
}
```
Resposta da API:
```json
{
  "token": "eyJhbGciOiJI…(JWT)",
  "user": {
    "id": 1,
    "name": "Usuária Antiga",
    "email": "legado@teste.local"
  }
}
```

### 03. Flutter → API: `GET /incomes` → **200**

Resposta da API:
```json
[
  {
    "id": 1,
    "amount": 5000,
    "description": "Salário antigo",
    "date": "2025-12-05",
    "category_id": 1,
    "user_id": 1,
    "created_at": "2026-11-23 00:37:57",
    "parcelado": 0,
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
    "id": 1,
    "amount": 1500,
    "description": "Aluguel antigo",
    "date": "2025-12-10",
    "category_id": 2,
    "user_id": 1,
    "created_at": "2026-11-23 00:37:57",
    "parcelado": 0,
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Moradia"
  }
]
```

### 05. Flutter → API: `GET /goals` → **200**

Resposta da API:
```json
[
  {
    "id": 4,
    "title": "Sem ícone",
    "target_amount": 500,
    "current_amount": 0,
    "icon": "flag",
    "user_id": 1,
    "created_at": "2026-11-23 00:37:57"
  },
  {
    "id": 3,
    "title": "Praia",
    "target_amount": 3000,
    "current_amount": 100,
    "icon": "flight",
    "user_id": 1,
    "created_at": "2026-11-23 00:37:57"
  },
  {
    "id": 2,
    "title": "Viagem",
    "target_amount": 8000,
    "current_amount": 0,
    "icon": "flight",
    "user_id": 1,
    "created_at": "2026-11-23 00:37:57"
  },
  {
    "id": 1,
    "title": "Reserva",
    "target_amount": 10000,
    "current_amount": 2500,
    "icon": "flag",
    "user_id": 1,
    "created_at": "2026-11-23 00:37:57"
  }
]
```

### 06. Flutter → API: `GET /categories` → **200**

Resposta da API:
```json
[
  {
    "id": 2,
    "name": "Moradia",
    "type": "expense",
    "user_id": 1,
    "created_at": "2026-11-23 00:37:57"
  },
  {
    "id": 1,
    "name": "Salário",
    "type": "income",
    "user_id": 1,
    "created_at": "2026-11-23 00:37:57"
  }
]
```

### 07. Flutter → API: `POST /expenses` → **201**

Enviado pelo app:
```json
{
  "amount": 900.0,
  "description": "Sofá",
  "date": "2026-11-08",
  "category_id": 2,
  "parcelado": false,
  "parcelas": 3
}
```
Resposta da API:
```json
{
  "id": 2,
  "amount": 300,
  "date": "2026-11-08",
  "parcela_numero": 1,
  "description": "Sofá",
  "category_id": 2,
  "parcelado": 1,
  "user_id": 1,
  "parcela_grupo": "44ed5abf-120e-4484-9da8-20313795b781",
  "parcela_total": 3,
  "valor_total": 900,
  "parcelas": [
    {
      "id": 2,
      "amount": 300,
      "date": "2026-11-08",
      "parcela_numero": 1
    },
    {
      "id": 3,
      "amount": 300,
      "date": "2026-12-08",
      "parcela_numero": 2
    },
    {
      "id": 4,
      "amount": 300,
      "date": "2027-01-08",
      "parcela_numero": 3
    }
  ]
}
```

### 08. Conferência no SQLite

```sql
SELECT COUNT(*) AS n FROM expenses WHERE parcela_grupo = ?   -- params: [44ed5abf-120e-4484-9da8-20313795b781]
```
```json
[
  {
    "n": 3
  }
]
```

---

**Resultado: APROVADO ✅**
