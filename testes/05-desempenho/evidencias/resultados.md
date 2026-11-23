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
| `POST /auth/login` | ✅ 62,2 | ✅ 61,4 | ✅ 68,4 | ✅ 61,3 | ✅ 64,8 | ✅ 63,4 |
| `GET /dashboard` | ✅ 3 | ✅ 3,9 | ✅ 15,2 | ✅ 64,7 | ✅ 5,1 | ✅ 4,1 |
| `GET /dashboard?month=AAAA-MM` | ✅ 3 | ✅ 3,4 | ✅ 9,7 | ✅ 44,7 | ✅ 4,4 | ✅ 3,7 |
| `GET /incomes (1ª página, até 500)` | ✅ 2,3 | ✅ 4,1 | ✅ 7 | ✅ 7,8 | ✅ 5,2 | ✅ 4,3 |
| `GET /expenses (1ª página, até 500)` | ✅ 3 | ✅ 7,1 | ✅ 7,9 | ✅ 10,9 | ✅ 9 | ✅ 7,7 |
| `GET /expenses?month=AAAA-MM` | ✅ 2,3 | ✅ 2,4 | ✅ 5,9 | ✅ 7 | ✅ 3,5 | ✅ 2,7 |
| `GET /goals` | ✅ 1,8 | ✅ 1,8 | ✅ 1,8 | ✅ 1,7 | ✅ 3,8 | ✅ 2,3 |
| `GET /categories` | ✅ 1,9 | ✅ 1,6 | ✅ 1,7 | ✅ 2,2 | ✅ 2,3 | ✅ 2,1 |
| `GET /lancamentos?from=<mês atual> (cache do app)` | ✅ 3,5 | ✅ 3,9 | ✅ 15,6 | ✅ 19,3 | ✅ 4,7 | ✅ 4 |
| `GET /lancamentos?limit=0 (só totais)` | ✅ 2,2 | ✅ 2,6 | ✅ 6,5 | ✅ 23,9 | ✅ 3,8 | ✅ 3,3 |
| `GET /lancamentos?limit=100 (1ª página do "Tudo")` | ✅ 3,7 | ✅ 4,8 | ✅ 8,2 | ✅ 27,7 | ✅ 6,4 | ✅ 4,7 |
| `GET /lancamentos?limit=100 (última página)` | ✅ 3,9 | ✅ 5,4 | ✅ 23,1 | ✅ 223 | ✅ 6,3 | ✅ 5,7 |
| `GET /lancamentos/meses` | ✅ 1,9 | ✅ 1,9 | ✅ 3,2 | ✅ 9,7 | ✅ 2 | ✅ 2,2 |
| `POST /expenses` | ✅ 10,9 | ✅ 9,7 | ✅ 10,8 | ✅ 9,7 | ✅ 11,1 | ✅ 78 |
| `PUT /expenses/:id` | ✅ 13,6 | ✅ 10,1 | ✅ 13,2 | ✅ 11 | ✅ 10,3 | ✅ 9,3 |
| `DELETE /expenses/:id` | ✅ 13,8 | ✅ 16,4 | ✅ 11 | ✅ 8,4 | ✅ 16 | ✅ 10,2 |
| `GET /dashboard` 20 simultâneos | ✅ 28,2 | ✅ 47 | ✅ 251,4 | ❌ 1.330,3 | ✅ 61,3 | ✅ 48,3 |
| Vazão com 20 simultâneos (req/s) | 719 | 433 | 82 | 15 | 380 | 407 |

## API — mediana (ms) e tamanho da resposta

| Rota | V1 mediana | V2 mediana | V3 mediana | V4 mediana | C1 mediana | C2 mediana | Resposta em V4 |
|---|---:|---:|---:|---:|---:|---:|---:|
| `POST /auth/login` | 59 | 59,2 | 59,4 | 59,3 | 62,1 | 60,5 | 0,3 KB |
| `GET /dashboard` | 2,5 | 3,5 | 13,6 | 63,9 | 3,8 | 3,7 | 2,7 KB |
| `GET /dashboard?month=AAAA-MM` | 2,5 | 3,1 | 9,4 | 43,7 | 3,4 | 3,3 | 2,7 KB |
| `GET /incomes (1ª página, até 500)` | 2,1 | 3,7 | 6,7 | 7,3 | 4,2 | 3,8 | 120,6 KB |
| `GET /expenses (1ª página, até 500)` | 2,7 | 6,6 | 7,1 | 10,6 | 7,4 | 7,1 | 129,4 KB |
| `GET /expenses?month=AAAA-MM` | 1,9 | 2,2 | 5,2 | 6,6 | 2,4 | 2,3 | 125 KB |
| `GET /goals` | 1,7 | 1,5 | 1,6 | 1,5 | 1,9 | 1,7 | 2,7 KB |
| `GET /categories` | 1,6 | 1,4 | 1,5 | 1,6 | 1,7 | 1,7 | 1,2 KB |
| `GET /lancamentos?from=<mês atual> (cache do app)` | 2,7 | 3,5 | 13,9 | 17,8 | 4 | 3,8 | 276,2 KB |
| `GET /lancamentos?limit=0 (só totais)` | 2 | 2,4 | 6,1 | 23,3 | 2,6 | 2,6 | 1 KB |
| `GET /lancamentos?limit=100 (1ª página do "Tudo")` | 3,5 | 4,1 | 7,9 | 27,1 | 5,1 | 4,3 | 28,6 KB |
| `GET /lancamentos?limit=100 (última página)` | 3,4 | 5 | 22 | 218,7 | 5,4 | 5,2 | 26,1 KB |
| `GET /lancamentos/meses` | 1,5 | 1,6 | 3,1 | 9,3 | 1,8 | 1,7 | 0,3 KB |
| `POST /expenses` | 8,9 | 8,6 | 9,1 | 8,6 | 9,1 | 10,1 | 0,1 KB |
| `PUT /expenses/:id` | 9,1 | 8,1 | 7,4 | 8,1 | 8,7 | 7,5 | 0 KB |
| `DELETE /expenses/:id` | 9,2 | 9,6 | 8,2 | 7,9 | 9,7 | 8,4 | 0 KB |

## App (Flutter, modo debug) — mediana (ms)

| Medida | Limite | V1 | V2 | V3 | V4 | C1 | C2 |
|---|---:|---:|---:|---:|---:|---:|---:|
| Entrar (login + carregar dados) | 3.000 | ✅ 131,4 | ✅ 149 | ✅ 236,7 | ✅ 571,3 | ✅ 158,5 | ✅ 150,9 |
| Recarregar o cache do app (mês atual em diante) | 2.000 | ✅ 15,9 | ✅ 19,6 | ✅ 65,9 | ✅ 384,6 | ✅ 22,1 | ✅ 22 |
|   ↳ parte de rede (download do cache) |  | 4,9 | 6,4 | 20,1 | 180,6 | 7,2 | 6,3 |
|   ↳ parte de processamento (JSON → modelos) |  | 0,3 | 4,1 | 32,5 | 173,3 | 4,4 | 4 |
| Abrir a Início até mostrar o saldo | 2.000 | ✅ 1.132,1 | ✅ 1.372,3 | ✅ 1.680,6 | ✅ 1.845,8 | ✅ 1.795,3 | ✅ 1.439,1 |
| Trocar de aba (até recarregar e redesenhar) | 1.000 | ✅ 125,4 | ✅ 127,3 | ✅ 153 | ✅ 436 | ✅ 146,3 | ✅ 141,4 |
| Histórico → filtro "Tudo" (até mostrar a 1ª página e os totais) | 1.000 | ✅ 220,9 | ✅ 279,7 | ✅ 177,4 | ✅ 596,9 | ✅ 231,4 | ✅ 229,9 |
| Histórico "Tudo" → carregar mais uma página | 1.000 | — | ✅ 12,4 | ✅ 12,2 | ✅ 712,2 | ✅ 10,9 | ✅ 12,6 |
| Lançamentos guardados no aparelho |  | 3 | 96 | 951 | 5.260 | 96 | 96 |
| KB baixados a cada recarga do cache |  | 1 | 26,2 | 255,9 | 1.425,5 | 26,2 | 26,2 |
