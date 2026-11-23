# CT-INT-13 — excluir lançamento e parcelamento no app apaga as linhas do SQLite

Gerado em 2026-11-23T09:15:33.576862

### 01. Flutter → API: `POST /expenses` → **201**

Enviado pelo app:
```json
{
  "amount": 45.0,
  "description": "Cinema",
  "date": "2026-11-14",
  "category_id": 38,
  "parcelado": false
}
```
Resposta da API:
```json
{
  "id": 8,
  "amount": 45,
  "description": "Cinema",
  "date": "2026-11-14",
  "category_id": 38,
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
  "receitas": 4500.75,
  "despesas": 1523,
  "saldo": 2977.75,
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
      "categoria": "Lazer",
      "total": 45
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
  "amount": 600.0,
  "description": "Curso",
  "date": "2026-11-15",
  "category_id": 42,
  "parcelado": false,
  "parcelas": 6
}
```
Resposta da API:
```json
{
  "id": 9,
  "amount": 100,
  "date": "2026-11-15",
  "parcela_numero": 1,
  "description": "Curso",
  "category_id": 42,
  "parcelado": 1,
  "user_id": 3,
  "parcela_grupo": "36cedc95-8998-4036-9ea7-a54d3ac2b8be",
  "parcela_total": 6,
  "valor_total": 600,
  "parcelas": [
    {
      "id": 9,
      "amount": 100,
      "date": "2026-11-15",
      "parcela_numero": 1
    },
    {
      "id": 10,
      "amount": 100,
      "date": "2026-12-15",
      "parcela_numero": 2
    },
    {
      "id": 11,
      "amount": 100,
      "date": "2027-01-15",
      "parcela_numero": 3
    },
    {
      "id": 12,
      "amount": 100,
      "date": "2027-02-15",
      "parcela_numero": 4
    },
    {
      "id": 13,
      "amount": 100,
      "date": "2027-03-15",
      "parcela_numero": 5
    },
    {
      "id": 14,
      "amount": 100,
      "date": "2027-04-15",
      "parcela_numero": 6
    }
  ]
}
```

### 04. Flutter → API: `GET /lancamentos?limit=0` → **200**

Resposta da API:
```json
{
  "itens": [],
  "total": 15,
  "proximo_offset": null,
  "receitas": 4500.75,
  "despesas": 2123,
  "saldo": 2377.75,
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
      "categoria": "Outros",
      "total": 612.5
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
      "categoria": "Lazer",
      "total": 45
    }
  ]
}
```

### 05. Flutter → API: `DELETE /expenses/8` → **204**


### 06. Flutter → API: `GET /lancamentos?limit=0` → **200**

Resposta da API:
```json
{
  "itens": [],
  "total": 14,
  "proximo_offset": null,
  "receitas": 4500.75,
  "despesas": 2078,
  "saldo": 2422.75,
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
      "categoria": "Outros",
      "total": 612.5
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
    }
  ]
}
```

### 07. Conferência no SQLite

```sql
SELECT id FROM expenses WHERE id = ?   -- params: [8]
```
```json
[]
```

### 08. Flutter → API: `DELETE /expenses/grupo/36cedc95-8998-4036-9ea7-a54d3ac2b8be` → **200**

Resposta da API:
```json
{
  "removidas": 6
}
```

### 09. Flutter → API: `GET /lancamentos?limit=0` → **200**

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

### 10. Conferência no SQLite

```sql
SELECT id FROM expenses WHERE parcela_grupo = ?   -- params: [36cedc95-8998-4036-9ea7-a54d3ac2b8be]
```
```json
[]
```

---

**Resultado: APROVADO ✅**
