# CT-INT-22 — integridade referencial do SQLite está ativa (foreign_keys e RESTRICT)

Gerado em 2026-11-22T21:37:53.087002

### 01. Conferência no SQLite

```sql
PRAGMA foreign_keys
```
```json
[
  {
    "foreign_keys": 1
  }
]
```

### 02. Conferência no SQLite

```sql
SELECT category_id FROM expenses LIMIT 1
```
```json
[
  {
    "category_id": 34
  }
]
```

> Ação direta no SQLite (outro cliente): `DELETE FROM categories WHERE id = ?` [34] → {"error":"SQLITE_CONSTRAINT: FOREIGN KEY constraint failed"}

### 03. Conferência no SQLite

```sql
SELECT id FROM categories WHERE id = ?   -- params: [34]
```
```json
[
  {
    "id": 34
  }
]
```

### 04. Conferência no SQLite

```sql
SELECT "table", "on_delete" FROM pragma_foreign_key_list('expenses') ORDER BY "table"
```
```json
[
  {
    "table": "categories",
    "on_delete": "RESTRICT"
  },
  {
    "table": "users",
    "on_delete": "CASCADE"
  }
]
```

---

**Resultado: APROVADO ✅**
