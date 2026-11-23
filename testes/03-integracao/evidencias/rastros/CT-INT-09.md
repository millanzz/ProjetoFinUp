# CT-INT-09 — despesa sem categoria: o app usa "Outros" e o SQLite liga à categoria de despesa

Gerado em 2026-11-22T23:01:56.497011

### 01. Flutter → API: `POST /expenses` → **201**

Enviado pelo app:
```json
{
  "amount": 12.5,
  "description": "Sem categoria",
  "date": "2026-11-08",
  "category_id": 42,
  "parcelado": false
}
```
Resposta da API:
```json
{
  "id": 1,
  "amount": 12.5,
  "description": "Sem categoria",
  "date": "2026-11-08",
  "category_id": 42,
  "parcelado": 0,
  "user_id": 3
}
```

### 02. Conferência no SQLite

```sql
SELECT c.name, c.type FROM expenses e JOIN categories c ON c.id = e.category_id WHERE e.id = ?   -- params: [1]
```
```json
[
  {
    "name": "Outros",
    "type": "expense"
  }
]
```

---

**Resultado: APROVADO ✅**
