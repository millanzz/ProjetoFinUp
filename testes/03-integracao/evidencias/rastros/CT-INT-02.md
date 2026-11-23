# CT-INT-02 — reabrir o app restaura a sessão a partir do token salvo e dos dados do SQLite

Gerado em 2026-11-23T09:15:31.581421

### 01. Flutter → API: `POST /auth/login` → **200**

Enviado pelo app:
```json
{
  "email": "ana@teste.local",
  "password": "***"
}
```
Resposta da API:
```json
{
  "token": "eyJhbGciOiJI…(JWT)",
  "user": {
    "id": 1,
    "name": "Ana Souza",
    "email": "ana@teste.local"
  }
}
```

### 02. Flutter → API: `GET /users/me` → **200**

Resposta da API:
```json
{
  "id": 1,
  "name": "Ana Souza",
  "email": "ana@teste.local",
  "created_at": "2026-11-23 12:15:31"
}
```

---

**Resultado: APROVADO ✅**
