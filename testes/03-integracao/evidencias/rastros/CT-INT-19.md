# CT-INT-19 — criar meta no app grava no SQLite e o app lê o progresso correto

Gerado em 2026-11-23T09:15:34.876974

### 01. Flutter → API: `POST /goals` → **201**

Enviado pelo app:
```json
{
  "title": "Viagem à Bahia",
  "target_amount": 5000.0,
  "current_amount": 1250.0,
  "icon": "flight"
}
```
Resposta da API:
```json
{
  "id": 1,
  "title": "Viagem à Bahia",
  "target_amount": 5000,
  "current_amount": 1250,
  "icon": "flight",
  "user_id": 3
}
```

### 02. Flutter → API: `GET /goals` → **200**

Resposta da API:
```json
[
  {
    "id": 1,
    "title": "Viagem à Bahia",
    "target_amount": 5000,
    "current_amount": 1250,
    "icon": "flight",
    "user_id": 3,
    "created_at": "2026-11-23 12:15:34"
  }
]
```

### 03. Conferência no SQLite

```sql
SELECT title, target_amount, current_amount, icon FROM goals WHERE title = 'Viagem à Bahia'
```
```json
[
  {
    "title": "Viagem à Bahia",
    "target_amount": 5000,
    "current_amount": 1250,
    "icon": "flight"
  }
]
```

---

**Resultado: APROVADO ✅**
