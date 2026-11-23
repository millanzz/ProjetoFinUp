# CT-INT-21 — excluir meta no app apaga a linha do SQLite

Gerado em 2026-11-22T21:37:53.069916

### 01. Flutter → API: `GET /goals` → **200**

Resposta da API:
```json
[
  {
    "id": 1,
    "title": "Viagem à Bahia",
    "target_amount": 5000,
    "current_amount": 1750,
    "icon": "flight",
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52"
  }
]
```

### 02. Flutter → API: `DELETE /goals/1` → **204**


### 03. Conferência no SQLite

```sql
SELECT id FROM goals WHERE id = ?   -- params: [1]
```
```json
[]
```

---

**Resultado: APROVADO ✅**
