# Relatório de Teste 02 — Testes funcionais: login, cadastro, edição e exclusão

| Item | Valor |
|---|---|
| Projeto | FinUp — Sistema de Gestão Financeira |
| Tipo de teste | Funcional (caixa-preta), em duas camadas: API e interface |
| Escopo | Login, cadastro, edição e exclusão |
| Data/hora da execução | 08/11/2026 00:35 (UTC−3) — reexecução com os mesmos resultados da primeira rodada (07/11 23:45); serviu para gerar o `app-resultado.json`, que tinha faltado, e para corrigir uma espera do próprio teste no CT-UI-LOG-01 |
| Versão testada | branch `redesign-fusao-tema-escuro`, commit `e1376b8` + alterações locais não commitadas |
| Executado por | millanzz (com apoio do Claude Code) |
| Resultado geral | **67 de 70 casos aprovados (95,7%) — 3 reprovados, 2 defeitos abertos, 3 observações** |


> **Reteste após as correções (2º ciclo).** Este relatório registra o **1º ciclo** de testes, com as falhas como foram encontradas; as evidências dele estão em [evidencias-ciclo1/](evidencias-ciclo1/). Os defeitos foram corrigidos e as baterias foram executadas de novo: os resultados novos estão em [evidencias/](evidencias/) e o comparativo antes × depois, em [../RETESTE.md](../RETESTE.md).

---

## 1. Objetivo

Verificar, do ponto de vista de quem usa o sistema, se as funções principais se comportam como esperado:

- **Login**: entrar, recusar credenciais erradas, proteger as rotas, sair da conta.
- **Cadastro**: criar conta, recusar dados inválidos, cadastrar receitas, despesas, metas e categorias.
- **Edição**: perfil (nome, e-mail, senha), receitas, despesas, parcelas e metas.
- **Exclusão**: receitas, despesas, parcelas, parcelamentos inteiros, metas e categorias.

## 2. Ambiente

| Componente | Versão |
|---|---|
| Sistema operacional | Windows 11 Pro 10.0.26200 |
| Node.js | v24.11.0 (executor nativo `node:test`) |
| Flutter | 3.41.1 (canal stable) — `flutter_test` com `LiveTestWidgetsFlutterBinding` |
| API | `backend/src/app.js` real, servida em `127.0.0.1` |
| Banco nos testes | SQLite **em memória** (schema real do `db.js`) |
| Tela simulada | 412 × 915 dp (celular Android comum), tema claro |

## 3. Estratégia

**Nenhum arquivo do projeto foi alterado.** Tudo está em `testes/02-funcionais/`.

**Camada 1: API (54 casos).** O [servidor.js](api/servidor.js) sobe a API real do FinUp (Express, rotas, middleware de autenticação e controllers) com o banco SQLite redirecionado para a memória. Os testes fazem requisições HTTP de verdade, como o app faria. O `.env` do projeto não é lido; o `JWT_SECRET` usado é um valor só de teste. O `backend/database.db` não foi aberto: a data de modificação dele continua sendo 07/11/2026 15:42.

**Camada 2: interface (16 casos).** As **telas reais do app** são operadas como um usuário faria: digitar nos campos, tocar nos botões, confirmar diálogos. Elas conversam com a mesma API de teste por HTTP real (porta 3999). Depois de cada fluxo, o resultado é conferido também direto na API. Por exemplo, depois de excluir pela tela, o teste confirma que o registro sumiu do servidor. Cada passo importante gera uma **captura de tela** (26 no total) em [evidencias/telas/](evidencias-ciclo1/telas/).

## 4. Resumo dos resultados

| Funcionalidade | API | Interface | Total | Aprovados | Reprovados |
|---|---:|---:|---:|---:|---:|
| Login | 12 | 4 | 16 | 14 | 2 |
| Cadastro | 13 | 6 | 19 | 19 | 0 |
| Edição | 16 | 3 | 19 | 18 | 1 |
| Exclusão | 13 | 3 | 16 | 16 | 0 |
| **Total** | **54** | **16** | **70** | **67** | **3** |

## 5. Casos de teste: API

Legenda: ✅ aprovado · ❌ reprovado

### 5.1 Login (`POST /auth/login` e rotas protegidas)

| ID | Cenário | Esperado | Obtido | Status |
|---|---|---|---|---|
| CT-LOG-01 | E-mail e senha corretos | 200, token JWT, dados do usuário sem a senha | igual | ✅ |
| CT-LOG-02 | E-mail com maiúsculas e espaços | 200 | 200 | ✅ |
| CT-LOG-03 | Senha errada | 401 "Email ou senha inválidos", sem token | igual | ✅ |
| CT-LOG-04 | E-mail não cadastrado | 401 com a **mesma** mensagem (não revela quem tem conta) | igual | ✅ |
| CT-LOG-05 | Senha com caixa diferente | 401 | 401 | ✅ |
| CT-LOG-06 | Campos vazios ou ausentes (4 combinações) | 400 | 400 | ✅ |
| CT-LOG-07 | Senha enviada como número (`123456`) | 4xx | **500** "data and hash must be strings" | ❌ |
| CT-LOG-08 | Corpo JSON malformado | 400 | **500** "Erro interno do servidor" | ❌ |
| CT-LOG-09 | Token do login em `GET /users/me` | 200 com os dados, sem a senha | igual | ✅ |
| CT-LOG-10 | 6 rotas protegidas sem token | 401 "Token não fornecido" | igual | ✅ |
| CT-LOG-11 | Token mal formatado, adulterado, de outra chave e expirado | 401 em todos | igual | ✅ |
| CT-LOG-12 | Validade do token | igual ao `JWT_EXPIRES_IN` (1h no teste) | 3600 s | ✅ |

### 5.2 Cadastro

| ID | Cenário | Esperado | Obtido | Status |
|---|---|---|---|---|
| CT-CAD-01 | Cadastro válido (nome com espaços, e-mail com maiúsculas) | 201 só com id/nome/e-mail; nome aparado; e-mail em minúsculas; login funciona | igual | ✅ |
| CT-CAD-02 | Armazenamento da senha | hash bcrypt (`$2b$10$…`), nunca texto puro | igual | ✅ |
| CT-CAD-03 | Categorias padrão | 5 de receita + 9 de despesa | igual | ✅ |
| CT-CAD-04 | E-mail repetido (3 variações de caixa/espaço) | 409 "Email já cadastrado" | igual | ✅ |
| CT-CAD-05 | Campos ausentes ou nome só com espaços (5 casos) | 400 | 400 | ✅ |
| CT-CAD-06 | E-mails inválidos (4 casos) | 400 | 400 | ✅ |
| CT-CAD-07 | Senha de 5 caracteres / de 6 (limite) | 400 / 201 | igual | ✅ |
| CT-CAD-08 | Nome com SQL e HTML (`Robert'); DROP TABLE users;--`) | gravado como texto, tabela intacta | igual | ✅ |
| CT-CAD-09 | Cadastrar receita | aparece na listagem (com categoria) e no dashboard | igual | ✅ |
| CT-CAD-10 | Cadastrar despesa em 3x | 1 lançamento em cada um dos 3 meses, nenhum no 4º | igual | ✅ |
| CT-CAD-11 | Cadastrar meta | aparece com guardado 0 e ícone escolhido | igual | ✅ |
| CT-CAD-12 | Categoria personalizada / tipo inválido | 201 e usável em despesa / 400 | igual | ✅ |
| CT-CAD-13 | Isolamento entre usuários | dados de um não aparecem para outro | igual | ✅ |

### 5.3 Edição

| ID | Cenário | Esperado | Obtido | Status |
|---|---|---|---|---|
| CT-EDI-01 | Editar nome do perfil | reflete em `/users/me`, aparado | igual | ✅ |
| CT-EDI-02 | Editar e-mail | novo e-mail entra no login, antigo não | igual | ✅ |
| CT-EDI-03 | Trocar para e-mail de outra pessoa (2 variações de caixa) | 409, e-mail original mantido | igual | ✅ |
| CT-EDI-04 | Nome vazio / e-mail inválido / sem campos | 400, nada muda | igual | ✅ |
| CT-EDI-05 | Editar perfil sem token | 401 | 401 | ✅ |
| CT-EDI-06 | Trocar senha | nova entra no login, antiga não | igual | ✅ |
| CT-EDI-07 | Trocar senha com a atual errada | 401, senha antiga continua | igual | ✅ |
| CT-EDI-08 | Nova senha curta / campos ausentes | 400 | 400 | ✅ |
| CT-EDI-09 | Nova senha enviada como número | 4xx | **500** com mensagem interna do bcrypt | ❌ |
| CT-EDI-10 | Editar receita (valor, descrição, data, categoria) | reflete na listagem | igual | ✅ |
| CT-EDI-11 | Editar despesa com valor 0, data inexistente, categoria de receita, sem categoria, sem campos | 400 em todos, nada muda | igual | ✅ |
| CT-EDI-12 | Editar a 2ª parcela de 3 | só ela muda (100, 100, 120) | igual | ✅ |
| CT-EDI-13 | Editar lançamento inexistente / de outro usuário | 404, nada muda | igual | ✅ |
| CT-EDI-14 | Editar meta (título, alvo, guardado, ícone) | reflete na listagem | igual | ✅ |
| CT-EDI-15 | Aportes 250 + 100 | guardado 350 | 350 | ✅ |
| CT-EDI-16 | Meta com dados inválidos (5 casos) / de outro usuário | 400 / 404, nada muda | igual | ✅ |

### 5.4 Exclusão

| ID | Cenário | Esperado | Obtido | Status |
|---|---|---|---|---|
| CT-EXC-01 | Excluir receita | 204, some da listagem e do saldo | igual | ✅ |
| CT-EXC-02 | Excluir a mesma receita 2 vezes | 204 e depois 404 | igual | ✅ |
| CT-EXC-03 | Excluir despesa | 204, saldo volta de 600 para 1.000 | igual | ✅ |
| CT-EXC-04 | Excluir lançamento de outro usuário | 404, dado continua | igual | ✅ |
| CT-EXC-05 | Excluir sem token | 401 | 401 | ✅ |
| CT-EXC-06 | Excluir uma parcela de 3 | as parcelas 2 e 3 continuam | igual | ✅ |
| CT-EXC-07 | Excluir parcelamento de 12x | 12 removidas, despesa avulsa continua | igual | ✅ |
| CT-EXC-08 | Excluir parcelamento de outro usuário | 404, nada removido | igual | ✅ |
| CT-EXC-09 | Excluir meta com aporte / repetir | 204 e some / 404 | igual | ✅ |
| CT-EXC-10 | Excluir meta de outro usuário | 404, meta continua | igual | ✅ |
| CT-EXC-11 | Excluir categoria em uso / sem uso | 409 "em uso por 1 lançamento" / 204 | igual | ✅ |
| CT-EXC-12 | Excluir categoria de outro usuário / a própria | 404 / 204 | igual | ✅ |
| CT-EXC-13 | IDs inexistentes ou não numéricos (5 rotas) | 404 | 404 | ✅ |

## 6. Casos de teste: interface (telas reais + API)

| ID | Fluxo do usuário | Esperado | Obtido | Evidência | Status |
|---|---|---|---|---|---|
| CT-UI-LOG-01 | Preenche e-mail e senha → Entrar | abre a Início com "Boa noite, Ana" | igual | [01a](evidencias-ciclo1/telas/CT-UI-LOG-01a-login-preenchido.png) · [01b](evidencias-ciclo1/telas/CT-UI-LOG-01b-inicio.png) | ✅ |
| CT-UI-LOG-02 | Toca em Entrar com campos vazios | aviso "Preencha e-mail e senha para entrar." e continua no login | igual | [02](evidencias-ciclo1/telas/CT-UI-LOG-02-campos-vazios.png) | ✅ |
| CT-UI-LOG-03 | Senha errada → Entrar | aviso "Email ou senha inválidos" e continua no login | igual | [03](evidencias-ciclo1/telas/CT-UI-LOG-03-senha-errada.png) | ✅ |
| CT-UI-LOG-04 | Avatar → Sair da conta → Sair | volta para o login | igual | [04a](evidencias-ciclo1/telas/CT-UI-LOG-04a-confirmar-saida.png) · [04b](evidencias-ciclo1/telas/CT-UI-LOG-04b-login.png) | ✅ |
| CT-UI-CAD-01 | Criar conta → preenche, aceita os termos → Criar conta | entra no app; a conta faz login na API | igual | [01a](evidencias-ciclo1/telas/CT-UI-CAD-01a-cadastro-preenchido.png) · [01b](evidencias-ciclo1/telas/CT-UI-CAD-01b-inicio.png) | ✅ |
| CT-UI-CAD-02 | Senha de 5 caracteres | aviso de mínimo 6; conta **não** criada na API | igual | [02](evidencias-ciclo1/telas/CT-UI-CAD-02-senha-curta.png) | ✅ |
| CT-UI-CAD-03 | Não marca os termos | aviso "Você precisa aceitar os termos de uso." | igual | [03](evidencias-ciclo1/telas/CT-UI-CAD-03-sem-termos.png) | ✅ |
| CT-UI-CAD-04 | E-mail já cadastrado | aviso "Email já cadastrado", continua no cadastro | igual | [04](evidencias-ciclo1/telas/CT-UI-CAD-04-email-duplicado.png) | ✅ |
| CT-UI-CAD-05 | − Despesa → R$ 1.250,90, "Aluguel", Moradia → Salvar | aviso "Despesa salva"; saldo −R$ 1.250,90; gravada na API com a categoria Moradia | igual | [05a](evidencias-ciclo1/telas/CT-UI-CAD-05a-form-despesa.png) · [05b](evidencias-ciclo1/telas/CT-UI-CAD-05b-saldo-atualizado.png) | ✅ |
| CT-UI-CAD-06 | + Receita → salvar sem valor; depois sem categoria | avisos de valor e de categoria; nada gravado | igual | [06](evidencias-ciclo1/telas/CT-UI-CAD-06-sem-categoria.png) | ✅ |
| CT-UI-EDI-01 | Perfil → Editar perfil → "João Pedro" → Salvar | aviso "Perfil atualizado"; nome novo na tela e na API | igual | [01a](evidencias-ciclo1/telas/CT-UI-EDI-01a-editar-perfil.png) · [01b](evidencias-ciclo1/telas/CT-UI-EDI-01b-perfil-atualizado.png) | ✅ |
| CT-UI-EDI-02 | Perfil → Alterar senha → Salvar | aviso "Senha alterada"; na API a nova entra e a antiga não | igual | [02](evidencias-ciclo1/telas/CT-UI-EDI-02-senha-alterada.png) | ✅ |
| CT-UI-EDI-03 | Despesas → toca no item → Editar → R$ 95,50 → Salvar alterações | aviso "Lançamento atualizado"; lista e API com 95,50 (mesmo id) | igual | [03a](evidencias-ciclo1/telas/CT-UI-EDI-03a-menu-lancamento.png) · [03b](evidencias-ciclo1/telas/CT-UI-EDI-03b-form-edicao.png) · [03c](evidencias-ciclo1/telas/CT-UI-EDI-03c-lista-atualizada.png) | ✅ |
| CT-UI-EXC-01 | Despesas → item → Excluir lançamento → Excluir | aviso "Lançamento excluído"; some da tela e da API | igual | [01a](evidencias-ciclo1/telas/CT-UI-EXC-01a-confirmar-exclusao.png) · [01b](evidencias-ciclo1/telas/CT-UI-EXC-01b-lista-sem-item.png) | ✅ |
| CT-UI-EXC-02 | Mesmo fluxo, mas toca em Cancelar | item continua na tela e na API | igual | [02](evidencias-ciclo1/telas/CT-UI-EXC-02-exclusao-cancelada.png) | ✅ |
| CT-UI-EXC-03 | Metas → toca e segura na meta → Excluir | aviso "Meta excluída"; some da tela e da API | igual | [03a](evidencias-ciclo1/telas/CT-UI-EXC-03a-metas.png) · [03b](evidencias-ciclo1/telas/CT-UI-EXC-03b-confirmar-exclusao.png) · [03c](evidencias-ciclo1/telas/CT-UI-EXC-03c-sem-metas.png) | ✅ |

## 7. Defeitos encontrados

A numeração continua a do Relatório 01 (DEF-01 e DEF-02).

### DEF-03 — Senha que não é texto derruba o login e a troca de senha com erro 500

| Item | Detalhe |
|---|---|
| Casos | CT-LOG-07, CT-EDI-09 |
| Severidade | Baixa/média. O app sempre envia texto, então só é atingível chamando a API direto |
| Onde | `authController.login` e `userController.updatePassword`: não conferem se `password` / `new_password` são texto antes de chamar o bcrypt. Em `updatePassword`, `new_password.length` de um número é `undefined`, então a regra de 6 caracteres também é pulada |
| Comportamento | Responde **500** e devolve a mensagem interna da biblioteca ("data and hash must be strings" / "data must be a string or Buffer…") |
| Esperado | 400 com mensagem amigável, como as outras validações |
| Sugestão | Conferir `typeof password === 'string'` (e o mesmo para `current_password` e `new_password`), como o cadastro (`userController.create`) já faz |

### DEF-04 — Corpo JSON malformado responde 500 em vez de 400

| Item | Detalhe |
|---|---|
| Caso | CT-LOG-08 (vale para todas as rotas, já que o `express.json()` é global) |
| Severidade | Baixa |
| Onde | Tratador de erro genérico em `backend/src/app.js`: sempre responde 500 e ignora o `status: 400` que o `express.json()` coloca no erro |
| Comportamento | Requisição com JSON quebrado → 500 "Erro interno do servidor" e o erro completo impresso no log do servidor |
| Sugestão | No tratador, usar `err.status` quando existir (ex.: `if (err.type === 'entity.parse.failed') return res.status(400).json({ error: 'JSON inválido' })`) |

## 8. Observações (não são falhas dos testes, mas merecem decisão)

| ID | Observação |
|---|---|
| OBS-01 | **Não existe exclusão de conta.** A API não tem `DELETE /users/me` e o Perfil não tem a opção. Se o requisito do projeto (ou a LGPD) pede que o usuário possa apagar a conta e os dados, é uma funcionalidade faltando. O banco já está preparado: as tabelas usam `ON DELETE CASCADE`. |
| OBS-02 | **Token antigo continua válido depois da troca de senha.** Como o JWT não é invalidado, um token emitido antes da troca funciona até expirar (7 dias no `.env.example`). |
| OBS-03 | Algumas respostas 500 devolvem `err.message` ao cliente (DEF-03 e outros `res.status(500).json({ error: err.message })`), o que expõe detalhes internos. |
| OBS-04 | "Esqueci minha senha" (`/auth/forgot-password` e `/auth/reset-password`) ficou fora do escopo desta rodada. Pode entrar numa próxima bateria. |

## 9. Evidências

Na pasta [evidencias-ciclo1/](evidencias-ciclo1/):

| Arquivo | Conteúdo |
|---|---|
| [execucao.txt](evidencias-ciclo1/execucao.txt) | Data/hora, versões, commit, branch e código de saída de cada camada |
| [api-saida.txt](evidencias-ciclo1/api-saida.txt) | Saída completa dos testes de API, com as mensagens dos reprovados |
| [api-junit.xml](evidencias-ciclo1/api-junit.xml) | Resultado da API em JUnit XML |
| [app-saida.txt](evidencias-ciclo1/app-saida.txt) | Saída completa dos testes de interface |
| [app-resultado.json](evidencias-ciclo1/app-resultado.json) | Resultado da interface em JSON, evento por evento |
| [app-servidor-log.txt](evidencias-ciclo1/app-servidor-log.txt) | Log da API de teste usada pela interface |
| [telas/](evidencias-ciclo1/telas/) | 26 capturas de tela dos fluxos (PNG, 412 × 915) |

Código dos testes: [api/](api/) (`login`, `cadastro`, `edicao`, `exclusao` + `servidor.js`) e [app/](app/) (`fluxos_test.dart` + `suporte.dart`).

## 10. Como reexecutar

Tudo de uma vez, na raiz do repositório (gera de novo todas as evidências):

```bash
bash testes/02-funcionais/executar.sh
```

Só a API (na pasta `testes/02-funcionais/api`):

```bash
node --test --test-concurrency=1 --test-reporter=spec login.test.js cadastro.test.js edicao.test.js exclusao.test.js
```

## 11. Conclusão

Login, cadastro, edição e exclusão funcionam corretamente tanto na API quanto nas telas do app:

- credenciais erradas, tokens inválidos e dados de outros usuários são barrados;
- as validações aparecem para o usuário com mensagens claras;
- o que é feito na tela é de fato gravado ou removido no servidor.

Os 3 casos reprovados vêm de entradas que o app nunca envia (senha como número e JSON quebrado). Eles mostram que a API responde 500 em vez de 400 e expõe mensagens internas (DEF-03 e DEF-04). Recomenda-se corrigir esses dois defeitos e decidir sobre as observações OBS-01 (exclusão de conta) e OBS-02 (token após troca de senha).
