## Cenários

| Cenário | Lançamentos do usuário | Lançamentos no banco | Tamanho do banco |
|---|---:|---:|---:|
| V1 | 100 | 100 | 0,1 MB |
| V2 | 1.000 | 1.000 | 0,2 MB |
| V3 | 10.000 | 10.000 | 1,4 MB |
| V4 | 50.000 | 50.000 | 6,6 MB |
| C1 | 1.000 | 101.000 | 13,7 MB |
| C2 | 1.000 | 501.000 | 69 MB |

## API — p95 (ms) por rota e cenário

| Rota | V1 | V2 | V3 | V4 | C1 | C2 |
|---|---:|---:|---:|---:|---:|---:|
| `POST /auth/login` | ✅ 88 | ✅ 62,7 | ✅ 96,8 | ✅ 64,3 | ✅ 95,8 | ✅ 63,1 |
| `GET /dashboard` | ✅ 2,9 | ✅ 3,9 | ✅ 14,9 | ✅ 69 | ✅ 12 | ✅ 4,1 |
| `GET /dashboard?month=AAAA-MM` | ✅ 3 | ✅ 4,3 | ✅ 17,1 | ✅ 80,4 | ✅ 6,9 | ✅ 4,2 |
| `GET /incomes` | ✅ 3,9 | ✅ 3,7 | ✅ 40,5 | ✅ 136,6 | ✅ 8,1 | ✅ 3,6 |
| `GET /expenses` | ✅ 4,4 | ✅ 10,2 | ✅ 96,9 | ❌ 560 | ✅ 14,6 | ✅ 10,1 |
| `GET /expenses?month=AAAA-MM` | ✅ 2,1 | ✅ 3,9 | ✅ 8 | ✅ 52,7 | ✅ 3,1 | ✅ 3,9 |
| `GET /goals` | ✅ 2,1 | ✅ 1,9 | ✅ 1,8 | ✅ 1,9 | ✅ 1,9 | ✅ 1,8 |
| `GET /categories` | ✅ 1,9 | ✅ 1,9 | ✅ 1,8 | ✅ 2,2 | ✅ 2 | ✅ 1,8 |
| `POST /expenses` | ✅ 11,8 | ✅ 32,8 | ✅ 20,5 | ✅ 9,6 | ✅ 11,1 | ✅ 19,2 |
| `PUT /expenses/:id` | ✅ 10,8 | ✅ 30 | ✅ 8,1 | ✅ 9,1 | ✅ 13,4 | ✅ 8,7 |
| `DELETE /expenses/:id` | ✅ 15,3 | ✅ 31,2 | ✅ 8,6 | ✅ 14,2 | ✅ 8,5 | ✅ 8,6 |
| `GET /dashboard` 20 simultâneos | ✅ 28,3 | ✅ 44,4 | ✅ 254,4 | ❌ 1.410,5 | ✅ 47,9 | ✅ 47,5 |
| Vazão com 20 simultâneos (req/s) | 752 | 426 | 80 | 15 | 424 | 426 |

## API — mediana (ms) e tamanho da resposta

| Rota | V1 mediana | V2 mediana | V3 mediana | V4 mediana | C1 mediana | C2 mediana | Resposta em V4 |
|---|---:|---:|---:|---:|---:|---:|---:|
| `POST /auth/login` | 64 | 60,8 | 74,9 | 61,1 | 73,1 | 60,4 | 0,3 KB |
| `GET /dashboard` | 2,5 | 3,5 | 14,2 | 66 | 5,7 | 3,4 | 2,7 KB |
| `GET /dashboard?month=AAAA-MM` | 2,6 | 3,8 | 16,7 | 79,5 | 5,3 | 4 | 2,7 KB |
| `GET /incomes` | 2,2 | 3,5 | 20,9 | 98 | 5,3 | 3,5 | 2.385,3 KB |
| `GET /expenses` | 3,5 | 9,5 | 79,4 | 491,4 | 10,7 | 9,5 | 9.991,9 KB |
| `GET /expenses?month=AAAA-MM` | 1,8 | 2,4 | 7,9 | 40,3 | 2,6 | 2,4 | 416,6 KB |
| `GET /goals` | 1,7 | 1,7 | 1,7 | 1,7 | 1,6 | 1,6 | 2,7 KB |
| `GET /categories` | 1,5 | 1,6 | 1,6 | 1,9 | 1,6 | 1,5 | 1,2 KB |
| `POST /expenses` | 8,9 | 8,8 | 9,3 | 8 | 9 | 10,6 | 0,1 KB |
| `PUT /expenses/:id` | 7,9 | 7,6 | 7,3 | 7,8 | 9,1 | 6,8 | 0 KB |
| `DELETE /expenses/:id` | 9,2 | 7,6 | 8,1 | 8 | 7,3 | 6,9 | 0 KB |

## App (Flutter, modo debug) — mediana (ms)

| Medida | Limite | V1 | V2 | V3 | V4 | C1 | C2 |
|---|---:|---:|---:|---:|---:|---:|---:|
| Entrar (login + carregar dados) | 3.000 | ✅ 162,7 | ✅ 213,8 | ✅ 631,3 | ✅ 2.554,9 | ✅ 227,3 | ✅ 210,9 |
| Recarregar todos os lançamentos | 2.000 | ✅ 26,6 | ✅ 60,8 | ✅ 457,5 | ❌ 2.292,9 | ✅ 56,7 | ✅ 56,8 |
|   ↳ parte de rede (download) |  | 9,5 | 16 | 110,3 | 620,7 | 15,8 | 15,8 |
|   ↳ parte de processamento (JSON → modelos) |  | 6,1 | 34,2 | 333,3 | 1.622,1 | 34 | 34,1 |
| Abrir a Início até mostrar o saldo | 2.000 | ✅ 1.391,2 | ✅ 1.417,6 | ❌ 2.204,4 | ❌ 4.930,7 | ✅ 1.452,3 | ✅ 1.372,3 |
| Trocar de aba (até recarregar e redesenhar) | 1.000 | ✅ 133,5 | ✅ 153,8 | ✅ 160,3 | ✅ 210,8 | ✅ 227,8 | ✅ 133,5 |
| Histórico → filtro "Tudo" | 1.000 | ✅ 114,2 | ✅ 176,9 | ✅ 352,4 | ❌ 1.187,1 | ✅ 148,5 | ✅ 148,7 |
| KB baixados a cada recarga |  | 24,1 | 243,2 | 2.455,7 | 12.377,2 | 243,2 | 243,2 |
