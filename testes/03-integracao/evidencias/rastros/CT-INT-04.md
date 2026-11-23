# CT-INT-04 — login com senha errada: o erro da API chega ao app e nada é salvo

Gerado em 2026-11-22T23:01:55.517169

### 01. Conferência no SQLite

```sql
SELECT password FROM users WHERE email = ?   -- params: [ana@teste.local]
```
```json
[
  {
    "password": "***"
  }
]
```

### 02. Flutter → API: `POST /auth/login` → **401**

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
  "error": "Email ou senha inválidos"
}
```

### 03. Conferência no SQLite

```sql
SELECT password FROM users WHERE email = ?   -- params: [ana@teste.local]
```
```json
[
  {
    "password": "***"
  }
]
```

---

**Resultado: APROVADO ✅**
