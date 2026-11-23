# CT-INT-06 — trocar senha no app troca o hash no SQLite

Gerado em 2026-11-22T21:37:51.114270

### 01. Flutter → API: `POST /auth/login` → **200**

Enviado pelo app:
```json
{
  "email": "bruno.lima@teste.local",
  "password": "***"
}
```
Resposta da API:
```json
{
  "token": "eyJhbGciOiJI…(JWT)",
  "user": {
    "id": 2,
    "name": "Bruno Lima",
    "email": "bruno.lima@teste.local"
  }
}
```

### 02. Conferência no SQLite

```sql
SELECT password FROM users WHERE email = ?   -- params: [bruno.lima@teste.local]
```
```json
[
  {
    "password": "***"
  }
]
```

### 03. Flutter → API: `PUT /users/me/password` → **200**

Enviado pelo app:
```json
{
  "current_password": "***",
  "new_password": "***"
}
```
Resposta da API:
```json
{
  "message": "Senha atualizada"
}
```

### 04. Conferência no SQLite

```sql
SELECT password FROM users WHERE email = ?   -- params: [bruno.lima@teste.local]
```
```json
[
  {
    "password": "***"
  }
]
```

### 05. Flutter → API: `POST /auth/login` → **200**

Enviado pelo app:
```json
{
  "email": "bruno.lima@teste.local",
  "password": "***"
}
```
Resposta da API:
```json
{
  "token": "eyJhbGciOiJI…(JWT)",
  "user": {
    "id": 2,
    "name": "Bruno Lima",
    "email": "bruno.lima@teste.local"
  }
}
```

---

**Resultado: APROVADO ✅**
