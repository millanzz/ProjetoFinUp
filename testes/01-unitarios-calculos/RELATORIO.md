# Relatório de Teste 01 — Testes unitários de cálculos

| Item | Valor |
|---|---|
| Projeto | FinUp — Sistema de Gestão Financeira |
| Tipo de teste | Unitário (lógica de cálculo) |
| Escopo | Saldo, receitas, despesas e metas |
| Data/hora da execução | 07/11/2026 23:02 (UTC−3) |
| Versão testada | branch `redesign-fusao-tema-escuro`, commit `e1376b8` + alterações locais não commitadas |
| Executado por | millanzz (com apoio do Claude Code) |
| Resultado geral | **55 de 59 casos aprovados (93,2%) — 4 reprovados, 2 defeitos abertos** |


> **Reteste após as correções (2º ciclo).** Este relatório registra o **1º ciclo** de testes, com as falhas como foram encontradas; as evidências dele estão em [evidencias-ciclo1/](evidencias-ciclo1/). Os defeitos foram corrigidos e as baterias foram executadas de novo: os resultados novos estão em [evidencias/](evidencias/) e o comparativo antes × depois, em [../RETESTE.md](../RETESTE.md).

---

## 1. Objetivo

Verificar se os cálculos financeiros do FinUp produzem os valores corretos:

- **Saldo**: receitas − despesas, total por mês, por categoria e evolução mensal.
- **Receitas** e **despesas**: cadastro, validação de valores e datas, edição, exclusão e parcelamento.
- **Metas**: valor guardado, aportes, progresso e conclusão.

## 2. Ambiente

| Componente | Versão |
|---|---|
| Sistema operacional | Windows 11 Pro 10.0.26200 |
| Node.js | v24.11.0 (executor nativo `node:test`) |
| Flutter | 3.41.1 (canal stable) — `flutter_test` |
| Banco nos testes | SQLite **em memória** (schema real do `backend/src/database/db.js`) |

## 3. Estratégia

- **Nenhum arquivo do projeto foi alterado.** Os testes ficam em `testes/01-unitarios-calculos/` e importam o código real do app.
- **Backend**: os controllers (`dashboardController`, `incomeController`, `expenseController`, `goalController`) são chamados diretamente com requisição e resposta simuladas. O sqlite3 é redirecionado para um banco em memória antes de carregar o `db.js`, então o `backend/database.db` real não é aberto (a data de modificação dele continua 07/11/2026 15:42, antes da execução). O banco é limpo e repovoado antes de cada caso (2 usuários e 6 categorias).
- **Frontend**: o `SaldoCard` é renderizado num teste de widget para conferir o saldo exibido na tela; `MetaModel` e `LancamentoModel` são testados direto.
- Cada caso tem um identificador (`CT-…`) para rastreabilidade.

## 4. Resumo dos resultados

| Módulo | Casos | Aprovados | Reprovados |
|---|---:|---:|---:|
| Saldo — backend (`GET /dashboard`) | 12 | 10 | 2 |
| Receitas — backend (`/incomes`) | 12 | 12 | 0 |
| Despesas — backend (`/expenses`) | 12 | 12 | 0 |
| Metas — backend (`/goals`) | 10 | 9 | 1 |
| Saldo — frontend (`SaldoCard`) | 5 | 4 | 1 |
| Metas — frontend (`MetaModel`) | 5 | 5 | 0 |
| Lançamentos — frontend (`LancamentoModel`/`Fmt`) | 3 | 3 | 0 |
| **Total** | **59** | **55** | **4** |

## 5. Casos de teste

Legenda: ✅ aprovado · ❌ reprovado

### 5.1 Saldo — backend

| ID | Cenário | Esperado | Obtido | Status |
|---|---|---|---|---|
| CT-SAL-01 | Usuário sem lançamentos | saldo 0, totais 0 | saldo 0, totais 0 | ✅ |
| CT-SAL-02 | Receitas 5.000 + 1.500,50; despesas 1.200 + 300,25 | saldo 5.000,25 | 5.000,25 | ✅ |
| CT-SAL-03 | Receita 1.000; despesa 1.500,75 | saldo −500,75 | −500,75 | ✅ |
| CT-SAL-04 | Filtro `?month=2026-11` com lançamentos em out/nov/dez | só nov: 2.000 − 500 = 1.500 | 1.500 | ✅ |
| CT-SAL-05 | Lançamentos de dois usuários | cada um vê só o seu saldo (1.000 / 2.222) | 1.000 / 2.222 | ✅ |
| CT-SAL-06 | `month` inválido (`2026-13`, `2026-7`, `11/2026`, vazio) | HTTP 400 | 400 | ✅ |
| CT-SAL-07 | Evolução mensal set/out | set 1.000/400; out 1.200/500 | igual | ✅ |
| CT-SAL-08 | Despesas por categoria + receita sem categoria | Aluguel 1.200, Mercado 400 (decrescente); "Sem categoria" 500 | igual | ✅ |
| CT-SAL-09 | Compra de 100 em 3x a partir de 31/01 | jan −33,34; fev −33,33; mar −33,33; total 100 | igual | ✅ |
| CT-SAL-10 | Receitas 0,10 + 0,20; despesa 0,30 | saldo **0** | **5,55 × 10⁻¹⁷** (receitas = 0,30000000000000004) | ❌ |
| CT-SAL-11 | 100 receitas de 0,01; despesa 1,00 | saldo 0 | 0 | ✅ |
| CT-SAL-12 | Receita 0,30; despesas 0,10 + 0,20 | saldo **0** | **−5,55 × 10⁻¹⁷** (despesas = 0,30000000000000004) | ❌ |

### 5.2 Receitas — backend

| ID | Cenário | Esperado | Obtido | Status |
|---|---|---|---|---|
| CT-REC-01 | Receita 4.500,90 válida | 201, gravada, entra no total | igual | ✅ |
| CT-REC-02 | Receita sem categoria | 201, `category_id` nulo | igual | ✅ |
| CT-REC-03 | Valor 0, −10, `"100"`, Infinity, NaN | 400 em todos, nada gravado | igual | ✅ |
| CT-REC-04 | Sem valor / sem data | 400 | 400 | ✅ |
| CT-REC-05 | Datas `2026-02-30`, `2026-13-01`, `07/11/2026`, `2026-1-5` | 400 | 400 | ✅ |
| CT-REC-06 | Categoria do tipo despesa | 400 "não é de receita" | igual | ✅ |
| CT-REC-07 | Categoria de outro usuário | 400 | 400 | ✅ |
| CT-REC-08 | 1.000 em 3x a partir de 10/11 | 333,34 + 333,33 + 333,33 = 1.000; 10/11, 10/12, 10/01 | igual | ✅ |
| CT-REC-09 | Listagem de nov com lançamentos de out/nov | só as 2 de nov (300, 200); total 500 | igual | ✅ |
| CT-REC-10 | Editar 100 → 250,50 | total 250,50 | 250,50 | ✅ |
| CT-REC-11 | Outro usuário tenta excluir | 404, valor continua | igual | ✅ |
| CT-REC-12 | Excluir a própria receita | 204, total cai para 50 | igual | ✅ |

### 5.3 Despesas — backend

| ID | Cenário | Esperado | Obtido | Status |
|---|---|---|---|---|
| CT-DES-01 | Despesa 1.250,75 válida | 201, entra no total | igual | ✅ |
| CT-DES-02 | Sem categoria | 400 "category_id é obrigatório" | igual | ✅ |
| CT-DES-03 | Categoria do tipo receita | 400 "não é de despesa" | igual | ✅ |
| CT-DES-04 | Valor 0, −0,01, `"50"`, null | 400, nada gravado | igual | ✅ |
| CT-DES-05 | 100 em 3x a partir de 31/01/2026 | 33,34/33,33/33,33; 31/01, 28/02, 31/03 | igual | ✅ |
| CT-DES-06 | 50 em 2x a partir de 31/01/2028 (bissexto) | 25 + 25; 31/01, 29/02 | igual | ✅ |
| CT-DES-07 | 1.999,99 em 12x | soma exata de 199.999 centavos; 1ª 166,73, demais 166,66 | igual | ✅ |
| CT-DES-08 | Parcelas 0, 49, 2,5, −3 | 400, nada gravado | igual | ✅ |
| CT-DES-09 | 0,05 em 10x | 400 (valor pequeno demais) | 400 | ✅ |
| CT-DES-10 | Excluir grupo de 6 parcelas | 6 removidas, total 0 | igual | ✅ |
| CT-DES-11 | Editar para valor −80 | 400, valor 80 mantido | igual | ✅ |
| CT-DES-12 | Mudar data de nov para dez | nov 0, dez 80 | igual | ✅ |

### 5.4 Metas — backend

| ID | Cenário | Esperado | Obtido | Status |
|---|---|---|---|---|
| CT-MET-01 | Meta "  Viagem  " de 5.000 | título aparado, guardado 0, ícone `flag` | igual | ✅ |
| CT-MET-02 | Alvo 0, −1, `"500"`, ausente | 400 | 400 | ✅ |
| CT-MET-03 | Guardado inicial −5 | 400 | 400 | ✅ |
| CT-MET-04 | Aportes 200 + 150,50 | 350,50 | 350,50 | ✅ |
| CT-MET-05 | Aportes 0, −50, `"10"` | 400, valor 100 mantido | igual | ✅ |
| CT-MET-06 | 10 aportes simultâneos de 10 | 100 (nenhum perdido) | 100 | ✅ |
| CT-MET-07 | 900 + aporte de 300 em meta de 1.000 | aceito, 1.200 | 1.200 | ✅ |
| CT-MET-08 | Aporte em meta de outro usuário | 404, valor mantido | igual | ✅ |
| CT-MET-09 | Editar guardado/alvo; guardado −1; ícone emoji | 200; 400; 400 | igual | ✅ |
| CT-MET-10 | Aportes 0,10 + 0,20 | **0,30** | **0,30000000000000004** | ❌ |

### 5.5 Frontend (Flutter)

| ID | Cenário | Esperado | Obtido | Status |
|---|---|---|---|---|
| CT-FE-SAL-01 | Card de saldo sem lançamentos | "R$ 0,00", "Saldo de novembro" | igual | ✅ |
| CT-FE-SAL-02 | Entradas 6.500,50; saídas 1.500,25 | saldo "R$ 5.000,25" e caixas corretas | igual | ✅ |
| CT-FE-SAL-03 | Entrada 1.000; saída 1.500,75 | "−R$ 500,75" | igual | ✅ |
| CT-FE-SAL-04 | Entradas 0,10 + 0,20; saída 0,30 | "R$ 0,00" | "R$ 0,00" | ✅ |
| CT-FE-SAL-05 | Entrada 0,30; saídas 0,10 + 0,20 | "R$ 0,00" | **"−R$ 0,00"** | ❌ |
| CT-FE-MET-01 | 250 de 1.000 | progresso 25%, não concluída | igual | ✅ |
| CT-FE-MET-02 | Alvo 0 | progresso 0 (sem divisão por zero) | 0 | ✅ |
| CT-FE-MET-03 | 1.000/1.000 e 1.200/1.000 | concluída; card mostra no máximo 100% | igual | ✅ |
| CT-FE-MET-04 | API com `current_amount: null` | guardado 0 | 0 | ✅ |
| CT-FE-MET-05 | 0,10 + 0,20 numa meta de 0,30 | concluída | concluída | ✅ |
| CT-FE-LAN-01 | Conversão do JSON da API | valores, tipo, título e "Parcela 1/3" corretos | igual | ✅ |
| CT-FE-LAN-02 | Divisão de parcelas no app | igual ao backend (33,34/33,33/33,33; 12x exato) | igual | ✅ |
| CT-FE-LAN-03 | JSON enviado à API | `amount` 1200.5, `date` 2026-02-03, sem `parcelas` em 1x | igual | ✅ |

## 6. Defeitos encontrados

### DEF-01 — Somas de valores com centavos têm erro de arredondamento no backend

| Item | Detalhe |
|---|---|
| Casos | CT-SAL-10, CT-SAL-12, CT-MET-10 |
| Severidade | Média |
| Onde | Colunas `amount`, `target_amount` e `current_amount` são `REAL` (ponto flutuante) em `backend/src/database/db.js`; as somas ficam em `SUM(amount)` (`dashboardController.js`) e em `current_amount + ?` (`goalController.js`) |
| Comportamento | 0,10 + 0,20 resulta em 0,30000000000000004. O saldo que deveria ser 0 volta como 5,55 × 10⁻¹⁷ ou −5,55 × 10⁻¹⁷ |
| Impacto | O valor bruto da API não bate com o esperado (comparações `== 0`, `saldo < 0`, `guardado >= alvo` podem falhar). Somado ao DEF-02, aparece para o usuário |
| Sugestão | Guardar os valores em **centavos inteiros** (`INTEGER`) ou, no mínimo, arredondar para 2 casas os resultados (`ROUND(SUM(amount), 2)` e `ROUND(current_amount + ?, 2)`) |

### DEF-02 — Saldo zerado aparece como "−R$ 0,00" na tela inicial

| Item | Detalhe |
|---|---|
| Caso | CT-FE-SAL-05 |
| Severidade | Baixa (visual), mas visível ao usuário |
| Onde | `frontend/lib/widgets/saldo_card.dart`: soma com `fold` em `double` e sinal decidido por `saldo < 0` antes de arredondar |
| Comportamento | Com entrada 0,30 e saídas 0,10 + 0,20, o saldo é −5,55 × 10⁻¹⁷ e o card mostra "−R$ 0,00" |
| Sugestão | Arredondar para centavos antes de comparar (ex.: `(saldo * 100).round() < 0`) ou somar em centavos inteiros |

Os dois defeitos foram só registrados; nada foi corrigido nesta etapa, como combinado.

## 7. Evidências

Na pasta [evidencias-ciclo1/](evidencias-ciclo1/):

| Arquivo | Conteúdo |
|---|---|
| [execucao.txt](evidencias-ciclo1/execucao.txt) | Data/hora, versões do Node e do Flutter, commit, branch e código de saída de cada bateria |
| [backend-saida.txt](evidencias-ciclo1/backend-saida.txt) | Saída completa do `node --test` (formato spec), com as mensagens de erro dos reprovados |
| [backend-junit.xml](evidencias-ciclo1/backend-junit.xml) | Resultado do backend em JUnit XML (pode ser importado em ferramentas de CI e relatórios) |
| [frontend-saida.txt](evidencias-ciclo1/frontend-saida.txt) | Saída completa do `flutter test` (formato expanded) |
| [frontend-resultado.json](evidencias-ciclo1/frontend-resultado.json) | Resultado do frontend em JSON, evento por evento |

Código dos testes: [backend/](backend/) (`saldo`, `receitas`, `despesas`, `metas` + `helpers.js`) e [frontend/calculos_test.dart](frontend/calculos_test.dart).

## 8. Como reexecutar

Backend (na pasta `testes/01-unitarios-calculos/backend`):

```bash
node --test --test-reporter=spec *.test.js
```

Frontend (na pasta `frontend`):

```bash
flutter test ../testes/01-unitarios-calculos/frontend/calculos_test.dart -r expanded
```

## 9. Conclusão

As regras de cálculo estão corretas: saldo, filtros por mês, separação por usuário, agrupamento por categoria, parcelamento (centavos e datas de fim de mês, inclusive ano bissexto), validações e aportes simultâneos. Os 4 casos reprovados vêm da mesma causa: valores em ponto flutuante sem arredondamento para centavos (DEF-01), que no app aparece como "−R$ 0,00" (DEF-02). Recomenda-se corrigir antes dos próximos testes e depois reexecutar esta bateria para confirmar.
