# CT-INT-20 — 5 aportes disparados ao mesmo tempo pelo app somam todos no SQLite

Gerado em 2026-11-23T09:15:34.980739

### 01. Flutter → API: `GET /goals` → **200**

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

### 02. Conferência no SQLite

```sql
SELECT current_amount FROM goals WHERE id = ?   -- params: [1]
```
```json
[
  {
    "current_amount": 1250
  }
]
```

### 03. Flutter → API: `POST /goals/1/aportes` → **200**

Enviado pelo app:
```json
{
  "amount": 100.0
}
```
Resposta da API:
```json
{
  "id": 1,
  "title": "Viagem à Bahia",
  "target_amount": 5000,
  "current_amount": 1550,
  "icon": "flight",
  "user_id": 3,
  "created_at": "2026-11-23 12:15:34"
}
```

### 04. Flutter → API: `POST /goals/1/aportes` → **200**

Enviado pelo app:
```json
{
  "amount": 100.0
}
```
Resposta da API:
```json
{
  "id": 1,
  "title": "Viagem à Bahia",
  "target_amount": 5000,
  "current_amount": 1550,
  "icon": "flight",
  "user_id": 3,
  "created_at": "2026-11-23 12:15:34"
}
```

### 05. Flutter → API: `POST /goals/1/aportes` → **200**

Enviado pelo app:
```json
{
  "amount": 100.0
}
```
Resposta da API:
```json
{
  "id": 1,
  "title": "Viagem à Bahia",
  "target_amount": 5000,
  "current_amount": 1550,
  "icon": "flight",
  "user_id": 3,
  "created_at": "2026-11-23 12:15:34"
}
```

### 06. Flutter → API: `POST /goals/1/aportes` → **200**

Enviado pelo app:
```json
{
  "amount": 100.0
}
```
Resposta da API:
```json
{
  "id": 1,
  "title": "Viagem à Bahia",
  "target_amount": 5000,
  "current_amount": 1750,
  "icon": "flight",
  "user_id": 3,
  "created_at": "2026-11-23 12:15:34"
}
```

### 07. Flutter → API: `POST /goals/1/aportes` → **200**

Enviado pelo app:
```json
{
  "amount": 100.0
}
```
Resposta da API:
```json
{
  "id": 1,
  "title": "Viagem à Bahia",
  "target_amount": 5000,
  "current_amount": 1750,
  "icon": "flight",
  "user_id": 3,
  "created_at": "2026-11-23 12:15:34"
}
```

### 08. Flutter → API: `GET /goals` → **200**

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
    "created_at": "2026-11-23 12:15:34"
  }
]
```

### 09. Flutter → API: `GET /goals` → **200**

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
    "created_at": "2026-11-23 12:15:34"
  }
]
```

### 10. Flutter → API: `GET /goals` → **200**

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
    "created_at": "2026-11-23 12:15:34"
  }
]
```

### 11. Flutter → API: `GET /goals` → **200**

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
    "created_at": "2026-11-23 12:15:34"
  }
]
```

### 12. Flutter → API: `GET /goals` → **200**

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
    "created_at": "2026-11-23 12:15:34"
  }
]
```

### 13. Conferência no SQLite

```sql
SELECT current_amount FROM goals WHERE id = ?   -- params: [1]
```
```json
[
  {
    "current_amount": 1750
  }
]
```

### 14. Flutter → API: `GET /goals` → **200**

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
    "created_at": "2026-11-23 12:15:34"
  }
]
```

---

**Resultado: APROVADO ✅**
