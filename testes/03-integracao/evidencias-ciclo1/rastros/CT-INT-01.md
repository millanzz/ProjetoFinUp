# CT-INT-01 — cadastro pelo app grava usuário (senha com hash) e categorias no SQLite e salva o token no aparelho

Gerado em 2026-11-22T21:37:50.424639

### 01. Flutter → API: `POST /users` → **201**

Enviado pelo app:
```json
{
  "name": "Ana Souza",
  "email": "Ana@Teste.Local",
  "password": "***"
}
```
Resposta da API:
```json
{
  "id": 1,
  "name": "Ana Souza",
  "email": "ana@teste.local"
}
```

### 02. Flutter → API: `POST /auth/login` → **200**

Enviado pelo app:
```json
{
  "email": "Ana@Teste.Local",
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

### 03. Conferência no SQLite

```sql
SELECT id, name, email, password FROM users WHERE email = ?   -- params: [ana@teste.local]
```
```json
[
  {
    "id": 1,
    "name": "Ana Souza",
    "email": "ana@teste.local",
    "password": "***"
  }
]
```

### 04. Conferência no SQLite

```sql
SELECT type, COUNT(*) AS n FROM categories WHERE user_id = ? GROUP BY type ORDER BY type   -- params: [1]
```
```json
[
  {
    "type": "expense",
    "n": 9
  },
  {
    "type": "income",
    "n": 5
  }
]
```

---

**Resultado: APROVADO ✅**
