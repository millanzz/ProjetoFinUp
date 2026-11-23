# CT-INT-05 — editar perfil no app atualiza o SQLite e o novo e-mail passa a valer no login

Gerado em 2026-11-22T23:01:55.593896

### 01. Flutter → API: `POST /users` → **201**

Enviado pelo app:
```json
{
  "name": "Bruno",
  "email": "bruno@teste.local",
  "password": "***"
}
```
Resposta da API:
```json
{
  "id": 2,
  "name": "Bruno",
  "email": "bruno@teste.local"
}
```

### 02. Flutter → API: `POST /auth/login` → **200**

Enviado pelo app:
```json
{
  "email": "bruno@teste.local",
  "password": "***"
}
```
Resposta da API:
```json
{
  "token": "eyJhbGciOiJI…(JWT)",
  "user": {
    "id": 2,
    "name": "Bruno",
    "email": "bruno@teste.local"
  }
}
```

### 03. Flutter → API: `PUT /users/me` → **200**

Enviado pelo app:
```json
{
  "name": "Bruno Lima",
  "email": "Bruno.Lima@Teste.Local"
}
```
Resposta da API:
```json
{
  "message": "Usuário atualizado"
}
```

### 04. Conferência no SQLite

```sql
SELECT name, email FROM users WHERE email LIKE ?   -- params: [bruno%]
```
```json
[
  {
    "name": "Bruno Lima",
    "email": "bruno.lima@teste.local"
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
