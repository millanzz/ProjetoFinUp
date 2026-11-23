# CT-INT-17 — erro de validação da API chega ao app como ApiException e nada é gravado

Gerado em 2026-11-22T23:01:57.380310

### 01. Conferência no SQLite

```sql
SELECT COUNT(*) AS n FROM incomes
```
```json
[
  {
    "n": 5
  }
]
```

### 02. Flutter → API: `POST /incomes` → **400**

Enviado pelo app:
```json
{
  "amount": -10.0,
  "description": "Negativo",
  "date": "2026-11-01",
  "category_id": 33,
  "parcelado": false
}
```
Resposta da API:
```json
{
  "error": "amount deve ser um número positivo"
}
```

### 03. Conferência no SQLite

```sql
SELECT COUNT(*) AS n FROM incomes
```
```json
[
  {
    "n": 5
  }
]
```

---

**Resultado: APROVADO ✅**
