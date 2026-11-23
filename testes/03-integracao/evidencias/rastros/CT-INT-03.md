# CT-INT-03 — token expirado: a sessão não é restaurada e o token é apagado do aparelho

Gerado em 2026-11-23T09:15:31.662895

### 01. Conferência no SQLite

```sql
SELECT id FROM users WHERE email = ?   -- params: [ana@teste.local]
```
```json
[
  {
    "id": 1
  }
]
```

### 02. Flutter → API: `GET /users/me` → **401**

Resposta da API:
```json
{
  "error": "Token inválido ou expirado"
}
```

---

**Resultado: APROVADO ✅**
