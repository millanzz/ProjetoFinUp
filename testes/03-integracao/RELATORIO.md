# Relatório de Teste 03 — Testes de integração: Flutter + API + SQLite

| Item | Valor |
|---|---|
| Projeto | FinUp — Sistema de Gestão Financeira |
| Tipo de teste | Integração entre as três camadas da arquitetura |
| Escopo | Autenticação/sessão, receitas e despesas, metas, persistência, disponibilidade e migração do banco |
| Data/hora da execução | 08/11/2026 00:32 (UTC−3) |
| Versão testada | branch `redesign-fusao-tema-escuro`, commit `e1376b8` + alterações locais não commitadas |
| Executado por | millanzz (com apoio do Claude Code) |
| Resultado geral | **24 de 25 casos aprovados (96%) — 1 reprovado, 1 defeito aberto** |


> **Reteste após as correções (2º ciclo).** Este relatório registra o **1º ciclo** de testes, com as falhas como foram encontradas; as evidências dele estão em [evidencias-ciclo1/](evidencias-ciclo1/). Os defeitos foram corrigidos e as baterias foram executadas de novo: os resultados novos estão em [evidencias/](evidencias/) e o comparativo antes × depois, em [../RETESTE.md](../RETESTE.md).

---

## 1. Arquitetura testada

```
┌──────────────────────────── App Flutter ─────────────────────────────┐
│ AuthService · LancamentoService · CategoriaService · MetaService      │
│ ApiClient (http + token JWT)  ·  shared_preferences (token no disco)  │
└───────────────────────────────┬──────────────────────────────────────┘
                                │ HTTP/JSON  (Authorization: Bearer)
┌───────────────────────────────▼──────────────────────────────────────┐
│ API Express — backend/src/app.js (rotas, authMiddleware, controllers) │
└───────────────────────────────┬──────────────────────────────────────┘
                                │ sqlite3 (uma conexão, foreign_keys = ON)
┌───────────────────────────────▼──────────────────────────────────────┐
│ Arquivo SQLite — schema e migrações do backend/src/database/db.js     │
└──────────────────────────────────────────────────────────────────────┘
```

Os testes anteriores olharam cada parte isolada: os cálculos (Relatório 01) e o comportamento visto pelo usuário (Relatório 02). Estes testes olham as **passagens entre as camadas**. Para cada ação feita pelo app, verificam três coisas:

- o que o app enviou;
- o que ficou de fato gravado no SQLite;
- o que o app leu de volta.

## 2. Ambiente

| Componente | Versão |
|---|---|
| Sistema operacional | Windows 11 Pro 10.0.26200 |
| Flutter | 3.41.1 (canal stable) — `flutter_test`, rede real |
| Node.js | v24.11.0 |
| API | `backend/src/app.js` real, porta 3999 |
| Banco | **arquivo** SQLite real, criado do zero a cada execução ([banco-integracao.db](evidencias-ciclo1/banco-integracao.db)) |

## 3. Estratégia

**Nenhum arquivo do projeto foi alterado.** O `backend/database.db` não foi aberto: a data de modificação dele continua sendo 07/11/2026 15:42.

- **Camada Flutter**: os testes usam o código de produção dos serviços do app (`AuthService`, `LancamentoService`, `CategoriaService`, `MetaService`, `ApiClient`), exatamente o que as telas chamam. O token é salvo no `shared_preferences`, como no aparelho.
- **Camada API**: o próprio teste sobe a API real como um processo separado ([servidor.js](servidor/servidor.js)). Ele também consegue derrubá-la e subi-la de novo, para testar queda e reinício.
- **Camada SQLite**: a API grava num arquivo `.db` do teste. Um "inspetor", que só existe no teste, consulta esse arquivo pela **mesma conexão da API** para conferir o que foi gravado.
- **Rastro de evidência**: as requisições HTTP feitas pelo app são registradas, com corpo e resposta (senhas e tokens mascarados), junto com as consultas ao SQLite. O resultado é um arquivo por caso em [evidencias/rastros/](evidencias-ciclo1/rastros/).

## 4. Resumo dos resultados

| Grupo | Casos | Aprovados | Reprovados |
|---|---:|---:|---:|
| Autenticação e sessão | 7 | 7 | 0 |
| Receitas e despesas | 11 | 10 | 1 |
| Metas | 3 | 3 | 0 |
| Banco, persistência e disponibilidade | 4 | 4 | 0 |
| **Total** | **25** | **24** | **1** |

## 5. Casos de teste

Legenda: ✅ aprovado · ❌ reprovado. Cada ID abre o rastro do caso.

### 5.1 Autenticação e sessão

| ID | Integração verificada | Resultado | Status |
|---|---|---|---|
| [CT-INT-01](evidencias-ciclo1/rastros/CT-INT-01.md) | `AuthService.register` → `POST /users` + login → SQLite | linha em `users` com hash bcrypt; 9 + 5 categorias criadas; o token salvo no aparelho tem o `id` do usuário gravado no banco | ✅ |
| [CT-INT-02](evidencias-ciclo1/rastros/CT-INT-02.md) | Reabrir o app → token do `shared_preferences` → `GET /users/me` | sessão restaurada; nome e e-mail vêm do SQLite | ✅ |
| [CT-INT-03](evidencias-ciclo1/rastros/CT-INT-03.md) | Token expirado no aparelho → API 401 → app | sessão **não** restaurada e token apagado do aparelho | ✅ |
| [CT-INT-04](evidencias-ciclo1/rastros/CT-INT-04.md) | Senha errada → API 401 → `ApiException` | mensagem "Email ou senha inválidos" chega ao app; nada salvo no aparelho nem no banco | ✅ |
| [CT-INT-05](evidencias-ciclo1/rastros/CT-INT-05.md) | `AuthService.atualizarPerfil` → `PUT /users/me` → SQLite | nome e e-mail atualizados no banco (e-mail em minúsculas); login com o novo e-mail funciona | ✅ |
| [CT-INT-06](evidencias-ciclo1/rastros/CT-INT-06.md) | `AuthService.alterarSenha` → `PUT /users/me/password` → SQLite | hash trocado no banco; nova senha entra | ✅ |
| [CT-INT-07](evidencias-ciclo1/rastros/CT-INT-07.md) | Sair e entrar com outro usuário no mesmo aparelho | caches do app limpos; o novo usuário não vê os dados do anterior, que continuam gravados com o `user_id` certo | ✅ |

### 5.2 Receitas e despesas

| ID | Integração verificada | Resultado | Status |
|---|---|---|---|
| [CT-INT-08](evidencias-ciclo1/rastros/CT-INT-08.md) | Receita com acentos e emoji: app → API → SQLite → app | texto, valor (`REAL` 4500,75), data `2026-11-08` e categoria idênticos nas três camadas | ✅ |
| [CT-INT-09](evidencias-ciclo1/rastros/CT-INT-09.md) | Despesa sem categoria | o app usa "Outros" e o banco liga à categoria **de despesa** "Outros" | ✅ |
| [CT-INT-10](evidencias-ciclo1/rastros/CT-INT-10.md) | Categoria nova ("Pets") usada duas vezes | criada **uma única vez** no banco, com as 2 despesas ligadas a ela | ✅ |
| [CT-INT-11](evidencias-ciclo1/rastros/CT-INT-11.md) | R$ 1.000 em 3x | 3 linhas com o mesmo `parcela_grupo` (333,34/333,33/333,33; 30/11, 30/12, 30/01); o cache do app após criar é igual ao relido da API | ✅ |
| [CT-INT-12](evidencias-ciclo1/rastros/CT-INT-12.md) | `LancamentoService.editar` | mesma linha alterada (mesmo id, mesma quantidade de linhas); app relê os novos valores | ✅ |
| [CT-INT-13](evidencias-ciclo1/rastros/CT-INT-13.md) | `remover` e `removerParcelamento` (6x) | linhas apagadas do banco e do cache do app | ✅ |
| [CT-INT-14](evidencias-ciclo1/rastros/CT-INT-14.md) | Saldo nas três camadas | app (`LancamentoService.saldo`) = API (`/dashboard`) = SQLite (`SUM`) | ✅ |
| [CT-INT-15](evidencias-ciclo1/rastros/CT-INT-15.md) | Valores-limite R$ 0,01 e R$ 999.999.999,99 | gravados e relidos exatos; exibidos como "R$ 999.999.999,99" | ✅ |
| [CT-INT-16](evidencias-ciclo1/rastros/CT-INT-16.md) | Datas 29/02/2028, 31/12/2026, 01/01/2027 | iguais no banco e no app; `?month=2028-02` encontra a de 29/02 | ✅ |
| [CT-INT-17](evidencias-ciclo1/rastros/CT-INT-17.md) | Valor negativo enviado pelo app | API 400 vira `ApiException` com a mensagem da API; nada gravado nem no banco nem no cache | ✅ |
| [CT-INT-18](evidencias-ciclo1/rastros/CT-INT-18.md) | Categoria excluída em **outro aparelho** e depois usada no app | **o app manda o id antigo (40), que não existe mais; a API recusa com 400 "Categoria não encontrada para este usuário" e o lançamento não é salvo** | ❌ |

### 5.3 Metas

| ID | Integração verificada | Resultado | Status |
|---|---|---|---|
| [CT-INT-19](evidencias-ciclo1/rastros/CT-INT-19.md) | `MetaService.criar` | linha gravada (alvo 5000, guardado 1250, ícone `flight`); app calcula progresso 25% | ✅ |
| [CT-INT-20](evidencias-ciclo1/rastros/CT-INT-20.md) | 5 aportes de R$ 100 disparados **ao mesmo tempo** | os 5 somados no banco (+500); app relê o mesmo valor | ✅ |
| [CT-INT-21](evidencias-ciclo1/rastros/CT-INT-21.md) | `MetaService.remover` | linha apagada do banco e do cache | ✅ |

### 5.4 Banco, persistência e disponibilidade

| ID | Integração verificada | Resultado | Status |
|---|---|---|---|
| [CT-INT-22](evidencias-ciclo1/rastros/CT-INT-22.md) | Integridade referencial | `PRAGMA foreign_keys = 1`; apagar categoria em uso direto no banco é barrado ("FOREIGN KEY constraint failed"); `expenses` tem `RESTRICT` para categorias e `CASCADE` para usuários | ✅ |
| [CT-INT-23](evidencias-ciclo1/rastros/CT-INT-23.md) | API derrubada e iniciada de novo sobre o mesmo arquivo | contagens iguais; o app restaura a sessão com o token salvo e relê exatamente os mesmos lançamentos | ✅ |
| [CT-INT-24](evidencias-ciclo1/rastros/CT-INT-24.md) | API fora do ar | o app recebe "Não foi possível conectar ao servidor…", mantém o cache e volta a sincronizar quando a API sobe | ✅ |
| [CT-INT-25](evidencias-ciclo1/rastros/CT-INT-25.md) | Banco de **versão anterior** (sem colunas de parcela, metas com emoji) | a API cria as colunas novas; o app entra com o usuário antigo e lê os lançamentos e as metas (🎯→`flag`, ✈️/🏖️→`flight`, vazio→`flag`); parcelar funciona no banco migrado | ✅ |

## 6. Defeito encontrado

A numeração continua a dos relatórios anteriores (DEF-01 a DEF-04).

### DEF-05 — Cache de categorias desatualizado impede lançar depois que a categoria é excluída em outro aparelho

| Item | Detalhe |
|---|---|
| Caso | CT-INT-18 |
| Severidade | Média: o usuário fica sem conseguir salvar naquela categoria até sair e entrar de novo no app |
| Onde | `frontend/lib/services/categoria_service.dart`: o mapa nome → id é carregado só ao abrir o app, entrar ou se cadastrar, e `obterOuCriarId` confia nele sem conferir de novo. O formulário (`lancamento_form_screen.dart`) mostra uma lista fixa de nomes, então a categoria continua aparecendo |
| Passos | 1) O app abre e carrega as categorias. 2) Em outro aparelho, o mesmo usuário exclui "Assinaturas" (`DELETE /categories/40` → 204). 3) No app, lança uma despesa em "Assinaturas" |
| Esperado | O app percebe que a categoria não existe mais, cria de novo e salva a despesa |
| Obtido | O app envia `category_id: 40` e a API responde 400 "Categoria não encontrada para este usuário". O lançamento não é salvo, e o erro se repete até o app recarregar as categorias |
| Sugestão | Em `LancamentoService.adicionar`/`editar`, ao receber esse erro, chamar `CategoriaService.carregar(force: true)` e tentar uma vez de novo (`obterOuCriarId` então recria a categoria). Outra opção é a API aceitar o **nome** da categoria e resolver o id no servidor |

## 7. Observações

| ID | Observação |
|---|---|
| OBS-05 | O mesmo cache vale para lançamentos e metas: o que outro aparelho altera só aparece no app quando ele recarrega (abrir, entrar ou puxar os dados de novo). Isso é esperado num app sem sincronização em tempo real; aqui fica registrado para conhecimento. |
| OBS-06 | Valores são guardados como `REAL` no SQLite (confirmado com `typeof(amount) = 'real'`). Nos casos de integração os valores chegaram exatos; a imprecisão em somas de centavos já foi registrada no DEF-01 (Relatório 01). |

## 8. Evidências

Na pasta [evidencias-ciclo1/](evidencias-ciclo1/):

| Arquivo | Conteúdo |
|---|---|
| [rastros/](evidencias-ciclo1/rastros/) | **Um arquivo por caso**: cada requisição do app (método, rota, corpo enviado, status, resposta) e cada consulta ao SQLite com as linhas retornadas, em ordem, com o resultado no fim |
| [execucao.txt](evidencias-ciclo1/execucao.txt) | Data/hora, versões, commit, branch e código de saída |
| [saida.txt](evidencias-ciclo1/saida.txt) | Saída completa do `flutter test` |
| [resultado.json](evidencias-ciclo1/resultado.json) | Resultado em JSON, evento por evento |
| [banco-integracao.db](evidencias-ciclo1/banco-integracao.db) | O arquivo SQLite resultante da execução (pode ser aberto no DB Browser for SQLite) |
| [banco-integracao-conteudo.sql](evidencias-ciclo1/banco-integracao-conteudo.sql) | Schema e todas as linhas desse banco em texto (senhas reduzidas ao prefixo do hash) |
| [banco-legado-migrado.db](evidencias-ciclo1/banco-legado-migrado.db) e [banco-legado-migrado-conteudo.sql](evidencias-ciclo1/banco-legado-migrado-conteudo.sql) | O banco antigo depois da migração feita pela API (CT-INT-25) |
| [api-log.txt](evidencias-ciclo1/api-log.txt) e [api-log-legado.txt](evidencias-ciclo1/api-log-legado.txt) | Logs dos processos da API |

Código: [flutter/integracao_test.dart](flutter/integracao_test.dart) (casos), [flutter/suporte.dart](flutter/suporte.dart) (controle da API, inspetor e rastro), [servidor/](servidor/) (API com arquivo SQLite, gerador do banco antigo e exportador do banco).

## 9. Como reexecutar

Na raiz do repositório (os testes sobem e derrubam a API sozinhos, na porta 3999):

```bash
bash testes/03-integracao/executar.sh
```

## 10. Conclusão

A integração entre o app Flutter, a API e o SQLite está correta nos fluxos principais:

- o que o app envia é o que fica gravado, e o que está gravado é o que o app mostra, inclusive acentos, emoji, centavos, valores altos, datas especiais e parcelamentos;
- a sessão sobrevive ao reinício do app e da API e é descartada quando o token expira;
- erros da API chegam ao app com mensagem legível;
- a integridade referencial está ativa;
- um banco de versão anterior é migrado sem perda.

A única falha (DEF-05) aparece quando dois aparelhos usam a mesma conta: o cache de categorias do app fica desatualizado e impede salvar lançamentos até ele ser recarregado.
