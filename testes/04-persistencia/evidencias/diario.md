# Diário da execução — teste de persistência

## Fase 1 — uso normal do app

O app cria, edita e exclui dados pelos próprios serviços e escolhe o tema escuro. No fim, o estado é guardado para comparação.

_Início: 2026-11-22T22:48:23.097060 · processo 18932_

| | Verificação | Esperado | Obtido |
|---|---|---|---|
| ✅ | Aparelho começa sem preferências salvas | `{}` | `{}` |
| ✅ | Usuário com nome editado | `"Paula M. Ribeiro"` | `"Paula M. Ribeiro"` |
| ✅ | Receitas cadastradas | `2` | `2` |
| ✅ | Despesas (1 avulsa + mercado + 3 parcelas restantes) | `5` | `5` |
| ✅ | Metas (Carro excluída) | `["Reserva de emergência","Viagem"]` | `["Reserva de emergência","Viagem"]` |
| ✅ | Valor guardado na reserva (2000 + 500 + 250,75) | `2750.75` | `2750.75` |
| ✅ | Tema escuro gravado no arquivo do aparelho | `"dark"` | `"dark"` |
| ✅ | Token de login gravado no arquivo do aparelho | `3` | `3` |

Captura: `telas/fase1-inicio-antes.png` (também salva como referência `inicio-referencia.png`).

## Fase 2 — app reaberto do zero, API reiniciada

Processo novo do app (memória vazia) e API derrubada e iniciada de novo sobre o mesmo arquivo SQLite. Repete o que o `main()` faz ao abrir o app.

_Início: 2026-11-22T22:48:34.862939 · processo 23936_

| | Verificação | Esperado | Obtido |
|---|---|---|---|
| ✅ | Memória do app começa vazia (sem sessão) | `false` | `false` |
| ✅ | Arquivo do aparelho ainda tem o tema | `"dark"` | `"dark"` |
| ✅ | Arquivo do aparelho ainda tem o token | `true` | `true` |
| ✅ | Tema restaurado ao abrir | `"dark"` | `"dark"` |
| ✅ | Sessão restaurada sem pedir login | `true` | `true` |
| ✅ | Nome editado continua (vindo do SQLite) | `"Paula M. Ribeiro"` | `"Paula M. Ribeiro"` |
| ✅ | `/users/me` idêntico ao de antes do reinício | `{"id":1,"name":"Paula M. Ribeiro","email":"paula@teste.local","created_at":"2026-11-23 01:48:23"}` | `{"id":1,"name":"Paula M. Ribeiro","email":"paula@teste.local","created_at":"2026-11-23 01:48:23"}` |
| ✅ | `/categories` idêntico ao de antes do reinício | `[{"id":6,"name":"Alimentação","type":"expense","user_id":1,"created_at":"2026-11-23 01:48:23"},{"id":12,"name":"Assinaturas","type":"expense","user_id":1,"cr…` | `[{"id":6,"name":"Alimentação","type":"expense","user_id":1,"created_at":"2026-11-23 01:48:23"},{"id":12,"name":"Assinaturas","type":"expense","user_id":1,"cr…` |
| ✅ | `/incomes` idêntico ao de antes do reinício | `[{"id":1,"amount":5200,"description":"Salário","date":"2026-11-05","category_id":1,"parcelado":0,"user_id":1,"created_at":"2026-11-23 01:48:23","parcela_grup…` | `[{"id":1,"amount":5200,"description":"Salário","date":"2026-11-05","category_id":1,"parcelado":0,"user_id":1,"created_at":"2026-11-23 01:48:23","parcela_grup…` |
| ✅ | `/expenses` idêntico ao de antes do reinício | `[{"id":7,"amount":900,"description":"Notebook","date":"2027-02-01","category_id":11,"parcelado":1,"user_id":1,"created_at":"2026-11-23 01:48:23","parcela_gru…` | `[{"id":7,"amount":900,"description":"Notebook","date":"2027-02-01","category_id":11,"parcelado":1,"user_id":1,"created_at":"2026-11-23 01:48:23","parcela_gru…` |
| ✅ | `/goals` idêntico ao de antes do reinício | `[{"id":2,"title":"Viagem","target_amount":6000,"current_amount":0,"icon":"flight","user_id":1,"created_at":"2026-11-23 01:48:23"},{"id":1,"title":"Reserva de…` | `[{"id":2,"title":"Viagem","target_amount":6000,"current_amount":0,"icon":"flight","user_id":1,"created_at":"2026-11-23 01:48:23"},{"id":1,"title":"Reserva de…` |
| ✅ | `/dashboard` idêntico ao de antes do reinício | `{"balance":1487.6,"total_incomes":6050.5,"total_expenses":4562.9,"expenses_by_category":[{"category":"Compras","total":2700},{"category":"Moradia","total":14…` | `{"balance":1487.6,"total_incomes":6050.5,"total_expenses":4562.9,"expenses_by_category":[{"category":"Compras","total":2700},{"category":"Moradia","total":14…` |
| ✅ | `/dashboard?month=2026-11` idêntico ao de antes do reinício | `{"balance":3287.6,"total_incomes":6050.5,"total_expenses":2762.9,"expenses_by_category":[{"category":"Moradia","total":1450},{"category":"Compras","total":90…` | `{"balance":3287.6,"total_incomes":6050.5,"total_expenses":2762.9,"expenses_by_category":[{"category":"Moradia","total":1450},{"category":"Compras","total":90…` |
| ✅ | Saldo calculado pelo app igual ao de antes | `1487.6` | `1487.6` |
| ✅ | Metas no app | `["Viagem|0.0|flight","Reserva de emergência|2750.75|wallet"]` | `["Viagem|0.0|flight","Reserva de emergência|2750.75|wallet"]` |
| ✅ | Despesa excluída (Cinema) continua fora do SQLite | `[]` | `[]` |
| ✅ | Parcela 2 excluída continua fora do SQLite | `[]` | `[]` |
| ✅ | Meta excluída (Carro) continua fora do SQLite | `[]` | `[]` |
| ✅ | Categoria criada pelo usuário (Projetos) persistiu | `[{"type":"income"}]` | `[{"type":"income"}]` |
| ✅ | Senha nova entra | `200` | `200` |
| ✅ | Senha antiga continua recusada | `401` | `401` |
| ✅ | Tela inicial reaberta idêntica, pixel a pixel, à da fase 1 | `inicio-referencia.png` | `fase2-inicio-depois.png` |
| ✅ | Após sair, o token foi apagado do arquivo do aparelho | `false` | `false` |
| ✅ | Após sair, o tema continua no arquivo do aparelho | `"dark"` | `"dark"` |

## Fase 3 — app reaberto depois de sair da conta

Processo novo do app e a API reiniciada mais uma vez. O app deve abrir no login, mantendo o tema, e os dados devem estar intactos ao entrar.

_Início: 2026-11-22T22:48:48.022704 · processo 21472_

| | Verificação | Esperado | Obtido |
|---|---|---|---|
| ✅ | Tema continua escuro | `"dark"` | `"dark"` |
| ✅ | Sem token no aparelho: abre no login (não restaura sessão) | `false` | `false` |
| ✅ | App abriu na tela de login, no tema escuro | tela de login | `telas/fase3-login-tema-escuro.png` |
| ✅ | Login com a senha trocada na fase 1 | `"Paula M. Ribeiro"` | `"Paula M. Ribeiro"` |
| ✅ | `/incomes` idêntico ao da fase 1 | `[{"id":1,"amount":5200,"description":"Salário","date":"2026-11-05","category_id":1,"parcelado":0,"user_id":1,"created_at":"2026-11-23 01:48:23","parcela_grup…` | `[{"id":1,"amount":5200,"description":"Salário","date":"2026-11-05","category_id":1,"parcelado":0,"user_id":1,"created_at":"2026-11-23 01:48:23","parcela_grup…` |
| ✅ | `/expenses` idêntico ao da fase 1 | `[{"id":7,"amount":900,"description":"Notebook","date":"2027-02-01","category_id":11,"parcelado":1,"user_id":1,"created_at":"2026-11-23 01:48:23","parcela_gru…` | `[{"id":7,"amount":900,"description":"Notebook","date":"2027-02-01","category_id":11,"parcelado":1,"user_id":1,"created_at":"2026-11-23 01:48:23","parcela_gru…` |
| ✅ | `/goals` idêntico ao da fase 1 | `[{"id":2,"title":"Viagem","target_amount":6000,"current_amount":0,"icon":"flight","user_id":1,"created_at":"2026-11-23 01:48:23"},{"id":1,"title":"Reserva de…` | `[{"id":2,"title":"Viagem","target_amount":6000,"current_amount":0,"icon":"flight","user_id":1,"created_at":"2026-11-23 01:48:23"},{"id":1,"title":"Reserva de…` |
| ✅ | `/categories` idêntico ao da fase 1 | `[{"id":6,"name":"Alimentação","type":"expense","user_id":1,"created_at":"2026-11-23 01:48:23"},{"id":12,"name":"Assinaturas","type":"expense","user_id":1,"cr…` | `[{"id":6,"name":"Alimentação","type":"expense","user_id":1,"created_at":"2026-11-23 01:48:23"},{"id":12,"name":"Assinaturas","type":"expense","user_id":1,"cr…` |
| ✅ | `/dashboard` idêntico ao da fase 1 | `{"balance":1487.6,"total_incomes":6050.5,"total_expenses":4562.9,"expenses_by_category":[{"category":"Compras","total":2700},{"category":"Moradia","total":14…` | `{"balance":1487.6,"total_incomes":6050.5,"total_expenses":4562.9,"expenses_by_category":[{"category":"Compras","total":2700},{"category":"Moradia","total":14…` |
| ✅ | Saldo no app igual ao da fase 1 | `1487.6` | `1487.6` |
| ✅ | Integridade do arquivo SQLite | `[{"integrity_check":"ok"}]` | `[{"integrity_check":"ok"}]` |
