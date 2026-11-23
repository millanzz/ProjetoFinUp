## Cenários

| Cenário | Lançamentos do usuário | Lançamentos no banco | Tamanho do banco |
|---|---:|---:|---:|
| V1 | 100 | 100 | 0 MB |
| V2 | 1.000 | 1.000 | 0,1 MB |
| V3 | 10.000 | 10.000 | 0,8 MB |
| V4 | 50.000 | 50.000 | 3,8 MB |
| C1 | 1.000 | 101.000 | 7,8 MB |
| C2 | 1.000 | 501.000 | 38,9 MB |

## API — p95 (ms) por rota e cenário

| Rota | V1 | V2 | V3 | V4 | C1 | C2 |
|---|---:|---:|---:|---:|---:|---:|
| `POST /auth/login` | ✅ 62,9 | ✅ 62,6 | ✅ 62,6 | ✅ 64,3 | ✅ 63,9 | ✅ 63,2 |
| `GET /dashboard` | ✅ 2,5 | ✅ 3,6 | ✅ 15,3 | ✅ 88 | ✅ 40,5 | ✅ 194,9 |
| `GET /dashboard?month=AAAA-MM` | ✅ 2,4 | ✅ 3,6 | ✅ 17,6 | ✅ 102,3 | ✅ 40,6 | ✅ 197,1 |
| `GET /incomes` | ✅ 1,7 | ✅ 3,5 | ✅ 35 | ✅ 109,2 | ✅ 5,1 | ✅ 16,3 |
| `GET /expenses` | ✅ 2,4 | ✅ 9,9 | ✅ 93 | ✅ 473,8 | ✅ 22,5 | ✅ 62,9 |
| `GET /expenses?month=AAAA-MM` | ✅ 1,6 | ✅ 2,2 | ✅ 9,3 | ✅ 36,7 | ✅ 13,1 | ✅ 54,1 |
| `GET /goals` | ✅ 1,6 | ✅ 1,5 | ✅ 14,1 | ✅ 1,7 | ✅ 1,9 | ✅ 2 |
| `GET /categories` | ✅ 1,7 | ✅ 1,5 | ✅ 2,3 | ✅ 2 | ✅ 1,7 | ✅ 1,9 |
| `POST /expenses` | ✅ 8,5 | ✅ 14,6 | ✅ 8,6 | ✅ 10,2 | ✅ 11,4 | ✅ 27,6 |
| `PUT /expenses/:id` | ✅ 8,2 | ✅ 8,4 | ✅ 7,9 | ✅ 9,7 | ✅ 10,8 | ✅ 25,9 |
| `DELETE /expenses/:id` | ✅ 7,1 | ✅ 7,6 | ✅ 7,7 | ✅ 8,5 | ✅ 10,1 | ✅ 29,6 |
| `GET /dashboard` 20 simultâneos | ✅ 23,9 | ✅ 39,4 | ✅ 284,5 | ❌ 1.791 | ❌ 787 | ❌ 3.875,6 |
| Vazão com 20 simultâneos (req/s) | 877 | 505 | 74 | 12 | 25 | 5 |

## API — mediana (ms) e tamanho da resposta

| Rota | V1 mediana | V2 mediana | V3 mediana | V4 mediana | C1 mediana | C2 mediana | Resposta em V4 |
|---|---:|---:|---:|---:|---:|---:|---:|
| `POST /auth/login` | 60,5 | 60,2 | 61,1 | 60,9 | 61,3 | 60,9 | 0,3 KB |
| `GET /dashboard` | 2,1 | 3,2 | 14,7 | 85,8 | 39,9 | 191,4 | 2,7 KB |
| `GET /dashboard?month=AAAA-MM` | 2,1 | 3,5 | 17,2 | 100,5 | 39,9 | 192,2 | 2,7 KB |
| `GET /incomes` | 1,5 | 3,2 | 19,9 | 97,8 | 4,7 | 15,3 | 2.385,3 KB |
| `GET /expenses` | 2,2 | 9,2 | 81,1 | 421,7 | 20 | 61,2 | 9.991,9 KB |
| `GET /expenses?month=AAAA-MM` | 1,4 | 1,9 | 8,2 | 35,3 | 12,7 | 53,6 | 416,6 KB |
| `GET /goals` | 1,4 | 1,3 | 1,8 | 1,3 | 1,4 | 1,4 | 2,7 KB |
| `GET /categories` | 1,3 | 1,2 | 1,6 | 1,2 | 1,5 | 1,5 | 1,2 KB |
| `POST /expenses` | 7,7 | 9 | 7,2 | 7,9 | 8,9 | 8,1 | 0,1 KB |
| `PUT /expenses/:id` | 6,6 | 6,7 | 6,1 | 6,9 | 8,5 | 7,2 | 0 KB |
| `DELETE /expenses/:id` | 6 | 6,2 | 5,8 | 7,1 | 6,9 | 7,5 | 0 KB |

## App (Flutter, modo debug) — mediana (ms)

| Medida | Limite | V1 | V2 | V3 | V4 | C1 | C2 |
|---|---:|---:|---:|---:|---:|---:|---:|
| Entrar (login + carregar dados) | 3.000 | ✅ 145,2 | ✅ 223,8 | ✅ 652,1 | ✅ 2.504,1 | ✅ 225,4 | ✅ 289,8 |
| Recarregar todos os lançamentos | 2.000 | ✅ 15,9 | ✅ 52,6 | ✅ 467,3 | ❌ 2.292,2 | ✅ 67 | ✅ 119,1 |
|   ↳ parte de rede (download) |  | 7,7 | 14,6 | 103,5 | 541,4 | 27,8 | 79,4 |
|   ↳ parte de processamento (JSON → modelos) |  | 4,6 | 35,3 | 356,2 | 1.762 | 34,6 | 34,7 |
| Abrir a Início até mostrar o saldo | 2.000 | ✅ 1.184,9 | ✅ 1.510,6 | ❌ 3.188,4 | ❌ 7.799,5 | ✅ 1.564,8 | ✅ 1.533 |
| Trocar de aba (até recarregar e redesenhar) | 1.000 | ✅ 377,6 | ✅ 629,4 | ❌ 1.761,9 | ❌ 5.201,4 | ✅ 746,6 | ✅ 739,5 |
| Histórico → filtro "Tudo" | 1.000 | ✅ 398,7 | ❌ 2.225,6 | ❌ 37.392,1 | ❌ 663.548,6 | ❌ 2.148,6 | ❌ 2.223,5 |
| KB baixados a cada recarga |  | 24,1 | 243,2 | 2.455,7 | 12.377,2 | 243,2 | 243,2 |
