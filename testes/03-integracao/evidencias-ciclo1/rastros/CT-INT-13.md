# CT-INT-13 — excluir lançamento e parcelamento no app apaga as linhas do SQLite

Gerado em 2026-11-22T21:37:52.213588

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

### 02. Flutter → API: `POST /expenses` → **201**

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
  "parcela_grupo": "a78f2279-1aef-4a43-a748-060a9e47d0e6",
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

### 03. Flutter → API: `DELETE /expenses/8` → **204**


### 04. Conferência no SQLite

```sql
SELECT id FROM expenses WHERE id = ?   -- params: [8]
```
```json
[]
```

### 05. Flutter → API: `DELETE /expenses/grupo/a78f2279-1aef-4a43-a748-060a9e47d0e6` → **200**

Resposta da API:
```json
{
  "removidas": 6
}
```

### 06. Conferência no SQLite

```sql
SELECT id FROM expenses WHERE parcela_grupo = ?   -- params: [a78f2279-1aef-4a43-a748-060a9e47d0e6]
```
```json
[]
```

---

**Resultado: APROVADO ✅**
