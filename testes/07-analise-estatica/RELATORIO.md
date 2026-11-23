# Relatório de Teste 07 — Análise estática, inspeção de código e identificação de problemas

| Item | Valor |
|---|---|
| Projeto | FinUp — Sistema de Gestão Financeira |
| Tipo de teste | Análise estática automatizada + inspeção manual de código (com provas de conceito para confirmar achados) |
| Escopo | Backend (`backend/server.js`, `backend/src`), frontend (`frontend/lib`, `frontend/test`), dependências e configuração |
| Data/hora da execução | 08/11/2026 13:15 a 13:25 (UTC−3); execução final completa às 13:23 |
| Versão testada | branch `redesign-fusao-tema-escuro`, commit `e1376b8` + alterações locais não commitadas |
| Executado por | millanzz (com apoio do Claude Code) |
| Resultado geral | **Ferramentas:** Dart com as regras do projeto = 0 problemas; Dart com regras estritas = 69 avisos; ESLint = 0 erros e 37 avisos; `npm audit` = **7 vulnerabilidades (2 críticas, 4 altas)**. **Inspeção:** 6 defeitos novos (DEF-13 a DEF-18), **2 deles confirmados com prova de conceito**, e 9 observações de qualidade |


> **Reteste após as correções (2º ciclo).** Este relatório registra o **1º ciclo** de testes, com as falhas como foram encontradas; as evidências dele estão em [evidencias-ciclo1/](evidencias-ciclo1/). Os defeitos foram corrigidos e as baterias foram executadas de novo: os resultados novos estão em [evidencias/](evidencias/) e o comparativo antes × depois, em [../RETESTE.md](../RETESTE.md).

---

## 1. Objetivo

Examinar o código **sem executar o app** para encontrar defeitos, riscos de segurança, problemas de confiabilidade e pontos que dificultam a manutenção. Quando a inspeção levantou uma suspeita grave, ela foi **confirmada com uma prova de conceito** contra a API de teste.

## 2. Ferramentas e método

**Nenhum arquivo do projeto foi alterado.** As análises com regras extras rodam em cópias temporárias. As ferramentas do backend foram instaladas só em `testes/07-analise-estatica/ferramentas/`, com `.gitignore` próprio para `node_modules`.

| Etapa | Ferramenta | O que verifica |
|---|---|---|
| Métricas | [metricas.js](ferramentas/metricas.js) | Tamanho do código, comentários e maiores arquivos |
| Dart (projeto) | `flutter analyze` com o `analysis_options.yaml` do projeto (`flutter_lints` 4) | As regras que o projeto já adota |
| Dart (estrito) | `flutter analyze` numa cópia, com [analysis_options_estrito.yaml](ferramentas/analysis_options_estrito.yaml) | `strict-casts`, `strict-inference`, `strict-raw-types`, Futures não aguardados, chamadas dinâmicas, `catch` genérico e mais 20 regras |
| JavaScript | ESLint 9.39 + `eslint-plugin-security` 3.0 ([eslint.config.js](ferramentas/eslint.config.js)) | Erros comuns, padrões inseguros, complexidade ciclomática (≤ 10), tamanho de função (≤ 60 linhas), aninhamento |
| Dependências | `npm audit`, `npm outdated`, `flutter pub outdated` | Vulnerabilidades conhecidas e versões desatualizadas |
| Inspeção manual | Leitura guiada por checklist (seção 6) | Autenticação, autorização, validação, SQL, concorrência, tratamento de erros, configuração, versionamento |
| Provas de conceito | [provas-de-conceito.js](ferramentas/provas-de-conceito.js) | Confirma na prática os 2 achados mais graves, contra a API real com banco temporário |

## 3. Métricas do código

| Camada | Arquivos | Linhas | Código | Comentários | % comentários |
|---|---:|---:|---:|---:|---:|
| Backend (Node.js) | 24 | 1.559 | 1.207 | 131 | 11% |
| Frontend (Flutter) | 32 | 6.871 | 6.006 | 243 | 4% |
| Testes do frontend | 3 | 121 | 99 | 1 | 1% |
| Testes do backend | 0 | — | — | — | — |

Maiores arquivos: `fin_surface.dart` (508 linhas de código), `fin_layout.dart` (487), `fin_controls.dart` (480) e `lancamento_form_screen.dart` (458). Detalhes em [metricas.md](evidencias-ciclo1/metricas.md).

## 4. Resultados das ferramentas

### 4.1 Dart / Flutter

| Análise | Erros | Avisos | Informativos |
|---|---:|---:|---:|
| Regras do projeto (`flutter_lints`) | 0 | 0 | 0 — **"No issues found!"** |
| Regras estritas | 0 | 0 | **69** |

As regras de tipagem estrita (`strict-casts` etc.) **não acusaram nada**: o código já converte tipos explicitamente. Os 69 itens se concentram em três temas:

| Regra | Qtde | O que significa | Onde |
|---|---:|---|---|
| `avoid_catches_without_on_clauses` | 25 | `catch (_)` que engole **qualquer** erro, inclusive bugs, sem registrar | Telas e serviços (ex.: `auth_service.dart`, `home_screen.dart`, `login_screen.dart`) |
| `avoid_dynamic_calls` | 22 | Leitura do JSON da API sem tipo (`dados['user']?['name']`): se a resposta mudar, o erro só aparece em tempo de execução | `auth_service.dart`, `categoria_service.dart`, `lancamento_service.dart` |
| `discarded_futures` + `unawaited_futures` | 16 | Operação assíncrona disparada sem esperar o fim nem tratar a falha | `auth_service.dart:169` (**logout**, ver DEF-18), `main_navigation_screen.dart:72` (recarga a cada aba, ver DEF-09), `home_screen.dart:36`, `login_screen.dart:73`… |
| Outras | 6 | `avoid_redundant_argument_values` (4), `unnecessary_lambdas` (1), `prefer_final_locals` (1) | Estilo |

Lista completa em [dart-analyze-estrito.txt](evidencias-ciclo1/dart-analyze-estrito.txt).

### 4.2 Backend (ESLint + segurança)

**0 erros e 37 avisos** ([eslint-backend.txt](evidencias-ciclo1/eslint-backend.txt)):

| Regra | Qtde | Análise |
|---|---:|---|
| `consistent-return` | 22 | Handlers que às vezes fazem `return res...` e às vezes não. Não é defeito no Express, mas dificulta a leitura e pode esconder respostas enviadas duas vezes. Baixa |
| `security/detect-object-injection` | 7 | **Falsos positivos, conferidos à mão**: os índices são do próprio código (`queries[key]`, `valores[i]`, `datas[i]`), nunca vindos do usuário |
| `complexity` (> 10) | 4 | `lancamentoController.create` = **20**, `passwordResetController.resetPassword` = 13, `goalController.update` = 12, `lancamentoController.update` = 12 |
| `max-lines-per-function` (> 60) | 3 | `lancamentoController` (fábrica com 188 linhas), `dashboardController.summary` (92), schema do `db.js` (90) |
| `no-unused-vars` | 1 | `next` não usado no tratador de erro do `app.js`. É exigido pela assinatura do Express, então é falso positivo |

**SQL montado com template** (5 lugares: `UPDATE ${table} SET ${fields.join(', ')}`…): **conferido e seguro**. `table` vem da configuração fixa do controller e `fields` só contém textos fixos do código; os **valores** sempre vão como parâmetros (`?`).

### 4.3 Dependências

**`npm audit` (backend): 7 vulnerabilidades**, todas com correção disponível ([npm-audit-backend.json](evidencias-ciclo1/npm-audit-backend.json)):

| Pacote | Gravidade | Chega por | Executa em produção? |
|---|---|---|---|
| `proxy-addr` | **crítica** (falsificação de IP com `trust proxy`) | express | Sim, mas o app **não** usa `trust proxy`, o que reduz o impacto |
| `tar` (6.2.1 e 7.5.19) | **crítica** (path traversal ao extrair) | bcrypt → node-pre-gyp; sqlite3 → node-gyp | Não, só na instalação/compilação |
| `body-parser` | alta (DoS por corpo comprimido) | express | **Sim**: é o `express.json()` de todas as rotas |
| `undici` | alta (vários) | sqlite3 → node-gyp | Não, só na compilação |
| `brace-expansion` | alta (DoS) | bcrypt → node-pre-gyp | Não, só na instalação |
| `@mapbox/node-pre-gyp` | alta (via tar) | bcrypt | Não, só na instalação |
| `qs` | moderada (DoS) | express | **Sim**: leitura de query string e corpo |

**Desatualizados:**

- **backend:** `express` 5.2.1 → 5.3.0 (corrige body-parser, qs e proxy-addr), `bcrypt` 5.1.1 → 6.0.0 (deixa de depender do node-pre-gyp/tar), `nodemailer` 10.3.1 → 10.4.0, `dotenv` 16 → 18;
- **frontend:** `google_fonts` 6.3 → 9.0, `flutter_lints` 4 → 6 (lints mais novos), `shared_preferences` 2.5.5 → 2.5.6.

## 5. Defeitos encontrados

A numeração continua a dos relatórios anteriores. Ordenados por gravidade.

### DEF-13 — O limite de 5 tentativas do código de recuperação de senha pode ser contornado ✅ confirmado

| Item | Detalhe |
|---|---|
| Onde | `backend/src/controllers/passwordResetController.js:121–129` |
| Causa | O código **lê** `attempts` (linha 121), faz o `bcrypt.compare` (~60 ms, linha 125) e só **depois** incrementa (linha 128). Requisições simultâneas leem todas `attempts = 0` antes de qualquer incremento |
| Prova de conceito | 40 palpites enviados ao mesmo tempo para um código com limite de 5: **os 40 foram conferidos pelo servidor** (`attempts = 40` no banco) ([provas-de-conceito.json](evidencias-ciclo1/provas-de-conceito.json)). Com rajadas maiores e um novo código a cada 60 s, o código de 6 dígitos pode ser descoberto por força bruta e a conta, tomada |
| Gravidade | **Alta (segurança)** |
| Sugestão | Reservar a tentativa **antes** de conferir, de forma atômica: `UPDATE password_resets SET attempts = attempts + 1 WHERE id = ? AND attempts < 5` e só fazer o `bcrypt.compare` se `changes = 1`. Combinar com o DEF-14 |

### DEF-14 — Nenhuma limitação de tentativas nas rotas de autenticação

| Item | Detalhe |
|---|---|
| Onde | `backend/src/routes/authRoutes.js:8,11,12` (`/auth/login`, `/auth/forgot-password`, `/auth/reset-password`) e `userRoutes.js:8` (cadastro); `app.js` não tem nenhum limitador |
| Causa | Não há rate limiting por IP nem por conta |
| Impacto | Força bruta de senha ilimitada (cerca de 16 tentativas/s por conexão; mais em paralelo), cadastro em massa e, junto com o DEF-13, ataque ao código de recuperação |
| Gravidade | **Média/alta (segurança)** |
| Sugestão | `express-rate-limit` (ex.: 10 logins por 15 min por IP + e-mail) e bloqueio temporário depois de várias falhas |

### DEF-15 — Dependências do backend com vulnerabilidades conhecidas

| Item | Detalhe |
|---|---|
| Onde | `backend/package-lock.json` |
| Evidência | `npm audit`: 7 vulnerabilidades (2 críticas, 4 altas, 1 moderada). Três delas (`body-parser`, `qs`, `proxy-addr`) estão no código que roda em produção (seção 4.3) |
| Gravidade | **Alta** (ferramenta); impacto prático médio, porque as críticas são de instalação ou dependem de `trust proxy` |
| Sugestão | Atualizar `express` para 5.3.0 e `bcrypt` para 6.0.0, rodar `npm audit fix` e repetir o `npm audit` |

### DEF-16 — Compras parceladas simultâneas falham: a transação é compartilhada entre requisições ✅ confirmado

| Item | Detalhe |
|---|---|
| Onde | `backend/src/controllers/lancamentoController.js:53–67` (`BEGIN`/`COMMIT`/`ROLLBACK`) + `backend/src/database/db.js` (**uma única conexão** SQLite para toda a API) |
| Causa | A transação é aberta na conexão compartilhada. Enquanto uma compra parcelada está no meio do `BEGIN … COMMIT`, outra requisição tenta abrir a sua (`cannot start a transaction within a transaction`), e as gravações de outras requisições **entram na transação alheia**: um `ROLLBACK` pode desfazer dados de outro usuário |
| Prova de conceito | 5 compras em 3x criadas ao mesmo tempo: **1 gravada e 4 com erro 500** ([provas-de-conceito.json](evidencias-ciclo1/provas-de-conceito.json)) |
| Gravidade | **Alta (confiabilidade e integridade dos dados)** |
| Sugestão | Gravar as parcelas numa **única instrução** (`INSERT … VALUES (…), (…), (…)`, que é atômica sem `BEGIN`) ou serializar as transações (fila/mutex). Também cabe avaliar uma biblioteca com transações por chamada (ex.: `better-sqlite3`) |

### DEF-17 — Nome do usuário entra sem escape no HTML do e-mail de recuperação

| Item | Detalhe |
|---|---|
| Onde | `backend/src/controllers/passwordResetController.js:67` e `:78` |
| Causa | O primeiro nome, que o próprio usuário cadastra, é colado no HTML do e-mail (`<p>Olá, ${primeiroNome}!</p>`) sem escapar `<`, `>`, `"` |
| Impacto | Quem controla o nome pode injetar HTML (links e imagens) no e-mail oficial do FinUp. Isso só é útil contra a própria conta, mas é uma injeção de conteúdo num e-mail da marca |
| Gravidade | Baixa |
| Sugestão | Escapar o texto antes de montar o HTML (função simples de `&`, `<`, `>`, `"`, `'`) |

### DEF-18 — Sair da conta não espera o token ser apagado do aparelho

| Item | Detalhe |
|---|---|
| Onde | `frontend/lib/services/auth_service.dart:169` (`ApiClient.limparToken()` sem `await`, apontado pela regra `discarded_futures`) |
| Causa | `logout()` é síncrono e dispara a remoção do token no `shared_preferences` sem esperar |
| Impacto | Se o app for fechado logo depois de "Sair" (antes de a escrita terminar), o token continua salvo e a sessão volta ao reabrir. Nos testes de persistência (Relatório 04) foi preciso esperar alguns milissegundos depois do logout para o arquivo refletir a saída |
| Gravidade | Baixa/média |
| Sugestão | Tornar `logout()` `Future<void>` com `await ApiClient.limparToken()` e aguardar nas telas |

## 6. Inspeção manual — checklist

| Item verificado | Resultado |
|---|---|
| Senhas guardadas com hash forte | ✅ bcrypt, custo 10 |
| Segredo do JWT fora do código | ✅ vem do `.env`; `.env` e `database.db` estão no `.gitignore` e não estão versionados; o servidor não sobe sem `JWT_SECRET` |
| Autorização por usuário em todas as consultas | ✅ toda consulta de dados filtra por `user_id` do token (confirmado também nos Relatórios 02 e 03) |
| SQL com parâmetros | ✅ valores sempre como `?`; os trechos montados com template usam só nomes fixos (seção 4.2) |
| Validação de entrada | ⚠️ boa no geral, mas sem checagem de tipo de senha (DEF-03), sem limite de tamanho em nomes, descrições e categorias, e categorias com nome repetido permitidas |
| Tratamento de erros da API | ⚠️ JSON malformado → 500 (DEF-04); **14 lugares** devolvem `err.message` ao cliente (OBS-03) |
| Limites contra abuso | ❌ sem rate limiting (DEF-14); limite de tentativas contornável (DEF-13) |
| Concorrência | ❌ transação compartilhada (DEF-16); aportes em metas são atômicos ✅ |
| Sessão | ⚠️ token de 7 dias sem revogação após troca de senha (OBS-02); token no `shared_preferences` sem criptografia (OBS-15) |
| Cabeçalhos HTTP / CORS | ⚠️ CORS aberto para qualquer origem (`app.js:9`); sem `helmet`; cabeçalho `X-Powered-By: Express` exposto (OBS-16) |
| Configuração de plataforma | ❌ APK de release sem permissão de Internet (DEF-10); API em HTTP sem TLS (OBS-14) |
| Testes automatizados no projeto | ⚠️ backend sem nenhum teste nem script `test`; frontend com 3 arquivos de teste (OBS-17) |
| Versionamento | ⚠️ arquivos essenciais **não versionados** (OBS-18) |

## 7. Observações de qualidade

| ID | Observação |
|---|---|
| OBS-15 | O token de login fica no `shared_preferences` em texto puro (`api_client.dart:39`). Em aparelho comprometido ou backup sem criptografia, ele pode ser lido. Sugestão: `flutter_secure_storage` |
| OBS-16 | `cors()` sem restrição de origem e sem `helmet`; o Express expõe `X-Powered-By`. Como a autenticação é por `Authorization: Bearer` (não por cookie), o risco é baixo, mas o ideal é restringir as origens à Web do app e desligar o cabeçalho (`app.disable('x-powered-by')`) |
| OBS-17 | **Cobertura de testes no projeto**: o backend não tem testes automatizados (as baterias destes relatórios ficam em `testes/`, fora do app) e o frontend tem 99 linhas de teste para 6.006 de código. Não há integração contínua para rodar análise e testes a cada mudança |
| OBS-18 | **Arquivos essenciais não versionados**: `lancamentoController.js`, `passwordResetController.js`, `src/utils/` (validators, dbAsync, parcelas, mailer), `esqueci_senha_screen.dart` e dois testes estão como "não rastreados" no git, enquanto os arquivos que dependem deles estão modificados. Um commit só dos arquivos modificados (`git commit -a`) **quebraria o backend** (`require('./lancamentoController')` não encontrado) |
| OBS-19 | Funções complexas: `lancamentoController.create` (complexidade 20) mistura validação, parcelamento e gravação. Separar a validação deixaria a função mais fácil de testar |
| OBS-20 | 25 `catch (_)` genéricos no app escondem falhas reais (ex.: `ThemeController.carregar`, `AuthService.restaurarSessao`, `.catchError((_) {})` nas recargas). Sugestão: tratar só os erros esperados (`on ApiException`) e registrar o resto |
| OBS-21 | O JSON da API é lido com acesso dinâmico em 22 pontos. Criar classes de resposta tipadas evitaria erros silenciosos se a API mudar |
| OBS-22 | Sem limite de tamanho para nome, descrição, título de meta e categoria (só o limite geral de 100 KB do corpo); também é possível criar categorias com o mesmo nome |
| OBS-23 | Sem `npm audit`/`flutter analyze` automatizados e com `flutter_lints` 4 (há a versão 6, com regras mais novas) |

## 8. Resumo consolidado de todos os defeitos (Relatórios 01 a 07)

| Gravidade | Defeitos |
|---|---|
| **Alta** | DEF-08 (Histórico trava com muitos lançamentos) · DEF-10 (APK sem Internet) · **DEF-13** (força bruta no código de recuperação) · **DEF-15** (dependências vulneráveis) · **DEF-16** (transação compartilhada) |
| **Média** | DEF-01 (centavos em ponto flutuante) · DEF-05 (cache de categorias) · DEF-06 (sem índices) · DEF-07 (dashboard com acessos simultâneos) · DEF-09 (recarga a cada aba) · DEF-11 (rotas da Web) · DEF-12 (fonte 200%) · **DEF-14** (sem rate limiting) |
| **Baixa** | DEF-02 (−R$ 0,00) · DEF-03 (senha não-texto → 500) · DEF-04 (JSON malformado → 500) · **DEF-17** (HTML no e-mail) · **DEF-18** (logout sem aguardar) |

## 9. Evidências

Na pasta [evidencias-ciclo1/](evidencias-ciclo1/):

| Arquivo | Conteúdo |
|---|---|
| [metricas.md](evidencias-ciclo1/metricas.md) | Tamanho do código por camada e maiores arquivos |
| [dart-analyze-projeto.txt](evidencias-ciclo1/dart-analyze-projeto.txt) | `flutter analyze` com as regras do projeto ("No issues found!") |
| [dart-analyze-estrito.txt](evidencias-ciclo1/dart-analyze-estrito.txt) | Os 69 itens das regras estritas, com arquivo:linha |
| [eslint-backend.txt](evidencias-ciclo1/eslint-backend.txt) e [eslint-backend.json](evidencias-ciclo1/eslint-backend.json) | Os 37 avisos do ESLint |
| [npm-audit-backend.json](evidencias-ciclo1/npm-audit-backend.json), [npm-outdated-backend.txt](evidencias-ciclo1/npm-outdated-backend.txt), [flutter-pub-outdated.txt](evidencias-ciclo1/flutter-pub-outdated.txt) | Vulnerabilidades e versões das dependências |
| [provas-de-conceito.json](evidencias-ciclo1/provas-de-conceito.json) | Resultado das provas de conceito do DEF-13 e do DEF-16 |
| [execucao.txt](evidencias-ciclo1/execucao.txt) | Data, versões e resumo de cada etapa |

## 10. Como reexecutar

Na raiz do repositório (cerca de 1 minuto; na primeira vez instala o ESLint em `testes/07-analise-estatica/ferramentas`):

```bash
bash testes/07-analise-estatica/executar.sh
```

## 11. Conclusão

O código do FinUp está **organizado e sem erros de compilação ou de lint** nas regras que o projeto adota:

- a tipagem é cuidadosa (as regras estritas de conversão não acusaram nada);
- as consultas SQL são parametrizadas;
- as senhas usam bcrypt;
- os dados são sempre filtrados pelo usuário dono.

A inspeção encontrou problemas que as ferramentas automáticas não pegam, **dois deles graves e confirmados na prática**:

- o **limite de tentativas da recuperação de senha pode ser contornado** com requisições simultâneas (DEF-13), agravado pela **falta de limitação de tentativas** nas rotas de autenticação (DEF-14);
- a **transação compartilhada** faz compras parceladas simultâneas falharem e pode misturar gravações de usuários diferentes (DEF-16).

Somam-se a eles as **dependências com vulnerabilidades conhecidas** (DEF-15). Correção simples: atualizar o express e o bcrypt e rodar o `npm audit fix`.

Antes do próximo commit, recomenda-se versionar os arquivos ainda não rastreados (OBS-18), para que o repositório não fique com o backend quebrado.
