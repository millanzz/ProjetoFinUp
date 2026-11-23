# CT-INT-24 — API fora do ar: o app recebe erro amigável, mantém o cache e volta a funcionar quando a API sobe

Gerado em 2026-11-22T21:37:54.034975

### 01. Flutter → API: `POST /auth/login` → **200**

Enviado pelo app:
```json
{
  "email": "carla@teste.local",
  "password": "***"
}
```
Resposta da API:
```json
{
  "token": "eyJhbGciOiJI…(JWT)",
  "user": {
    "id": 3,
    "name": "Carla",
    "email": "carla@teste.local"
  }
}
```

### 02. Flutter → API: `GET /incomes` → **200**

Resposta da API:
```json
[
  {
    "id": 3,
    "amount": 1200.5,
    "description": "Freela",
    "date": "2026-11-20",
    "category_id": 30,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Freelance"
  },
  {
    "id": 2,
    "amount": 4500.75,
    "description": "Salário de novembro — açaí, pão & café ☕🍇",
    "date": "2026-11-08",
    "category_id": 29,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:51",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Salário"
  },
  {
    "id": 5,
    "amount": 999999999.99,
    "description": "Prêmio",
    "date": "2026-11-01",
    "category_id": 33,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  },
  {
    "id": 4,
    "amount": 0.01,
    "description": "Centavo",
    "date": "2026-11-01",
    "category_id": 33,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  }
]
```

### 03. Flutter → API: `GET /expenses` → **200**

Resposta da API:
```json
[
  {
    "id": 16,
    "amount": 10,
    "description": "Data 2028-02-29",
    "date": "2028-02-29",
    "category_id": 42,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  },
  {
    "id": 6,
    "amount": 333.33,
    "description": "Geladeira",
    "date": "2027-01-30",
    "category_id": 39,
    "parcelado": 1,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": "12eedf61-0082-4913-a2f5-39de74064cd2",
    "parcela_numero": 3,
    "parcela_total": 3,
    "category_name": "Compras"
  },
  {
    "id": 18,
    "amount": 10,
    "description": "Data 2027-01-01",
    "date": "2027-01-01",
    "category_id": 42,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  },
  {
    "id": 17,
    "amount": 10,
    "description": "Data 2026-12-31",
    "date": "2026-12-31",
    "category_id": 42,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  },
  {
    "id": 5,
    "amount": 333.33,
    "description": "Geladeira",
    "date": "2026-12-30",
    "category_id": 39,
    "parcelado": 1,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": "12eedf61-0082-4913-a2f5-39de74064cd2",
    "parcela_numero": 2,
    "parcela_total": 3,
    "category_name": "Compras"
  },
  {
    "id": 4,
    "amount": 333.34,
    "description": "Geladeira",
    "date": "2026-11-30",
    "category_id": 39,
    "parcelado": 1,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": "12eedf61-0082-4913-a2f5-39de74064cd2",
    "parcela_numero": 1,
    "parcela_total": 3,
    "category_name": "Compras"
  },
  {
    "id": 15,
    "amount": 250.25,
    "description": "Luz",
    "date": "2026-11-21",
    "category_id": 36,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Moradia"
  },
  {
    "id": 7,
    "amount": 95.5,
    "description": "Mercado do mês",
    "date": "2026-11-12",
    "category_id": 34,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Alimentação"
  },
  {
    "id": 3,
    "amount": 250,
    "description": "Veterinário",
    "date": "2026-11-09",
    "category_id": 43,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:51",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Pets"
  },
  {
    "id": 19,
    "amount": 39.9,
    "description": "Streaming",
    "date": "2026-11-08",
    "category_id": 44,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Assinaturas"
  },
  {
    "id": 2,
    "amount": 120,
    "description": "Ração",
    "date": "2026-11-08",
    "category_id": 43,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:51",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Pets"
  },
  {
    "id": 1,
    "amount": 12.5,
    "description": "Sem categoria",
    "date": "2026-11-08",
    "category_id": 42,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:51",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  }
]
```

> API derrubada.

> API iniciada de novo.

### 04. Flutter → API: `GET /incomes` → **200**

Resposta da API:
```json
[
  {
    "id": 3,
    "amount": 1200.5,
    "description": "Freela",
    "date": "2026-11-20",
    "category_id": 30,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Freelance"
  },
  {
    "id": 2,
    "amount": 4500.75,
    "description": "Salário de novembro — açaí, pão & café ☕🍇",
    "date": "2026-11-08",
    "category_id": 29,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:51",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Salário"
  },
  {
    "id": 5,
    "amount": 999999999.99,
    "description": "Prêmio",
    "date": "2026-11-01",
    "category_id": 33,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  },
  {
    "id": 4,
    "amount": 0.01,
    "description": "Centavo",
    "date": "2026-11-01",
    "category_id": 33,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  }
]
```

### 05. Flutter → API: `GET /expenses` → **200**

Resposta da API:
```json
[
  {
    "id": 16,
    "amount": 10,
    "description": "Data 2028-02-29",
    "date": "2028-02-29",
    "category_id": 42,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  },
  {
    "id": 6,
    "amount": 333.33,
    "description": "Geladeira",
    "date": "2027-01-30",
    "category_id": 39,
    "parcelado": 1,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": "12eedf61-0082-4913-a2f5-39de74064cd2",
    "parcela_numero": 3,
    "parcela_total": 3,
    "category_name": "Compras"
  },
  {
    "id": 18,
    "amount": 10,
    "description": "Data 2027-01-01",
    "date": "2027-01-01",
    "category_id": 42,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  },
  {
    "id": 17,
    "amount": 10,
    "description": "Data 2026-12-31",
    "date": "2026-12-31",
    "category_id": 42,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  },
  {
    "id": 5,
    "amount": 333.33,
    "description": "Geladeira",
    "date": "2026-12-30",
    "category_id": 39,
    "parcelado": 1,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": "12eedf61-0082-4913-a2f5-39de74064cd2",
    "parcela_numero": 2,
    "parcela_total": 3,
    "category_name": "Compras"
  },
  {
    "id": 4,
    "amount": 333.34,
    "description": "Geladeira",
    "date": "2026-11-30",
    "category_id": 39,
    "parcelado": 1,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": "12eedf61-0082-4913-a2f5-39de74064cd2",
    "parcela_numero": 1,
    "parcela_total": 3,
    "category_name": "Compras"
  },
  {
    "id": 15,
    "amount": 250.25,
    "description": "Luz",
    "date": "2026-11-21",
    "category_id": 36,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Moradia"
  },
  {
    "id": 7,
    "amount": 95.5,
    "description": "Mercado do mês",
    "date": "2026-11-12",
    "category_id": 34,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Alimentação"
  },
  {
    "id": 3,
    "amount": 250,
    "description": "Veterinário",
    "date": "2026-11-09",
    "category_id": 43,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:51",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Pets"
  },
  {
    "id": 19,
    "amount": 39.9,
    "description": "Streaming",
    "date": "2026-11-08",
    "category_id": 44,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:52",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Assinaturas"
  },
  {
    "id": 2,
    "amount": 120,
    "description": "Ração",
    "date": "2026-11-08",
    "category_id": 43,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:51",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Pets"
  },
  {
    "id": 1,
    "amount": 12.5,
    "description": "Sem categoria",
    "date": "2026-11-08",
    "category_id": 42,
    "parcelado": 0,
    "user_id": 3,
    "created_at": "2026-11-23 00:37:51",
    "parcela_grupo": null,
    "parcela_numero": null,
    "parcela_total": null,
    "category_name": "Outros"
  }
]
```

---

**Resultado: APROVADO ✅**
