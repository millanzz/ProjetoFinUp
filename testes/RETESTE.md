# Reteste após as correções — comparativo antes × depois

| Item | Valor |
|---|---|
| Projeto | FinUp — Sistema de Gestão Financeira |
| 1º ciclo (falhas encontradas) | 07 a 09/11/2026 — evidências em `evidencias-ciclo1/` de cada pasta |
| Correções e reteste (2º ciclo) | 22/11/2026, 21:39 a 23:25 (UTC−3) — evidências em `evidencias/` de cada pasta e em [reteste/](reteste/) |
| Versão testada | branch `redesign-fusao-tema-escuro`, commit `e1376b8` + alterações locais (nada foi commitado) |
| Paginação (3º ciclo) | 23/11/2026 (UTC−3): paginação das listas implementada e baterias 01–06 executadas de novo; ver a [seção 4.1](#41-paginação-3º-ciclo-23112026) |
| Resultado | **Os 18 defeitos foram corrigidos e confirmados por teste.** Depois da paginação (3º ciclo), resta **1 medição de desempenho acima do limite**: 20 acessos simultâneos ao `/dashboard` com 50 mil lançamentos, rota que o app não usa (seção 4.1) |

---

## 1. Resultado por bateria

| Bateria | 1º ciclo | Reteste | Diferença |
|---|---:|---:|---|
| 01 Unitário | 55/59 | **59/59** | +4 |
| 02 Funcional | 67/70 | **70/70** | +3 |
| 03 Integração | 24/25 | **25/25** | +1 |
| 04 Persistência | 14/14 | **14/14** | = |
| 05 Desempenho | 89/102 | **101/102** (3º ciclo; 96/102 antes da paginação) | +12 |
| 06 Compatibilidade | 201/222 | **222/222** | +21 |
| **Total (01–06)** | **450/492 (91,5%)** | **491/492 (99,8%)** | **+41** |
| 07 Estático: vulnerabilidades (`npm audit`) | 7 (2 críticas) | **0** | −7 |
| 07 Estático: provas de conceito | 2 falhas confirmadas | **0** | −2 |
| Reteste: testes novos ([reteste/](reteste/)) | — | **26 (API) + 2 + 5 + 2 (telas) passaram**; APK e Web conferidos | novo |
| 05: medições novas da paginação | — | **35/35** | novo |

Execução registrada em [reteste.log](reteste.log) (4ª passada) e [reteste-passadas-1-e-2.log](reteste-passadas-1-e-2.log).

## 2. Cada defeito: correção e confirmação

| Defeito | O que foi feito | Onde | Como foi confirmado | Status |
|---|---|---|---|---|
| **DEF-01** centavos em ponto flutuante | Somas arredondadas a 2 casas no banco (`ROUND`), na API e no app (`Fmt.centavos`) | `dashboardController.js`, `goalController.js`, `formatters.dart`, `lancamento_service.dart` | CT-SAL-10, CT-SAL-12, CT-MET-10 passaram | ✅ (ver 4.2) |
| **DEF-02** “−R$ 0,00” | Saldo arredondado antes de decidir o sinal | `saldo_card.dart`, `formatters.dart` | CT-FE-SAL-05 passou | ✅ |
| **DEF-03** senha não-texto → 500 | Validação de tipo antes do bcrypt | `authController.js`, `userController.js` | CT-LOG-07, CT-EDI-09: agora 400 | ✅ |
| **DEF-04** JSON malformado → 500 | Tratador de erros devolve o status 4xx do próprio erro | `app.js` | CT-LOG-08: agora 400 | ✅ |
| **DEF-05** categoria apagada em outro aparelho | O app recarrega as categorias e tenta de novo (e reaproveita a existente ao receber 409) | `lancamento_service.dart`, `categoria_service.dart` | CT-INT-18 passou | ✅ |
| **DEF-06** sem índices | Índices por usuário + data, “cobrindo” categoria e valor | `db.js` | Resumo, usuário de 1.000 lançamentos num banco de 501 mil: **195 → 4 ms** | ✅ |
| **DEF-07** resumo com acessos simultâneos | Índices cobrindo (o resumo soma direto do índice) | `db.js` | 20 simultâneos, banco de 501 mil: **3,9 s → 48 ms**; V4: 1,8 → 1,4 s | ⚠️ ver 4.1 |
| **DEF-08** Histórico trava | Lista sob demanda (`ListView.builder`) | `historico_screen.dart` | “Tudo”: 2,2 s → **0,18 s** (1 mil); 37 s → **0,35 s** (10 mil); **11 min → 1,2 s** (50 mil) | ✅ (V4 ver 4.1) |
| **DEF-09** recarga a cada aba | Recarrega só se o cache tiver mais de 1 min | `main_navigation_screen.dart`, `lancamento_service.dart` | Trocar de aba com 10 mil: **1,8 s → 0,16 s** | ✅ |
| **DEF-10** APK sem Internet | Permissão no manifesto principal | `android/app/src/main/AndroidManifest.xml` | `aapt dump permissions` mostra `android.permission.INTERNET` ([apk-release-permissoes.txt](reteste/evidencias/apk-release-permissoes.txt)) | ✅ |
| **DEF-11** rotas da Web ignoram a sessão | Rota inicial depende só de estar logado | `main.dart` | Chrome e Edge, 3 tamanhos: `/#/home` sem login vai para `/#/login` ([navegadores.json](reteste/evidencias/web/navegadores.json)) | ✅ |
| **DEF-12** fonte 200% e tela 280 dp | Campos com altura mínima (não fixa); linhas que quebram; textos flexíveis | `fin_controls.dart`, `login/register/esqueci_senha_screen.dart`, `saldo_card.dart` | Compatibilidade **222/222** | ✅ |
| **DEF-13** força bruta no código | Tentativa reservada de forma atômica antes de conferir | `passwordResetController.js` | Prova de conceito: 40 palpites → **5 conferidos** (antes 40) | ✅ |
| **DEF-14** sem limite de tentativas | Limitador em memória: login, recuperação, redefinição, cadastro e exclusão de conta | `middlewares/limiteTentativas.js`, rotas | DEF-14a–e (429 no limite; senha certa não conta) | ✅ |
| **DEF-15** dependências vulneráveis | express 5.3, bcrypt 6.0, nodemailer 10.6 + `npm audit fix` | `package.json` | `npm audit`: **0 vulnerabilidades** | ✅ |
| **DEF-16** transação compartilhada | Parcelas num único `INSERT` (atômico, sem BEGIN/COMMIT) | `lancamentoController.js` | Prova de conceito: 5 compras simultâneas → **5 gravadas, 3 parcelas cada** (antes 1) | ✅ |
| **DEF-17** HTML no e-mail | Nome escapado antes de entrar no HTML | `passwordResetController.js`, `validators.js` | DEF-17: `<img…>` chega como `&lt;img…` | ✅ |
| **DEF-18** logout sem aguardar | `logout()` passa a esperar o token ser apagado | `auth_service.dart`, `perfil_screen.dart` | DEF-18: token ausente assim que o logout termina | ✅ |

## 3. Itens de produção implementados

| Item | O que foi feito | Confirmação |
|---|---|---|
| **HTTPS** | A API sobe em HTTPS com `TLS_CERT`/`TLS_KEY` (ou atrás de proxy com `TRUST_PROXY=1`); em produção recusa HTTP (403), **não sobe sem HTTPS** e envia HSTS. O app em build de produção só aceita `https://`. Script de certificado de desenvolvimento | HTTPS-01 a 03; build Web **release** usando a API em **HTTPS** no Chrome e no Edge, com dados carregados |
| **Exclusão de conta** | `DELETE /users/me` (exige a senha) apaga conta, lançamentos, parcelas, categorias, metas e pedidos de recuperação; botão **Perfil → Excluir conta** | CONTA-01 a 04 e UI-CONTA-01/02 (telas reais) |
| **Encerramento de sessões** | Trocar/redefinir a senha e excluir a conta invalidam os tokens antigos; o aparelho que trocou a senha recebe um token novo | SESS-01, SESS-02, CONTA-03, UI-SESS-01 |
| **Política de Privacidade** | Texto único (LGPD) servido em `GET /privacidade` (página pública) e `/privacidade.json`; tela no app (Perfil e link “termos de uso” do cadastro) | PRIV-01, UI-PRIV-01/02 |
| **Defeito novo achado no reteste** | O cadastro respondia antes de gravar as 14 categorias padrão (podia criar categorias repetidas). Agora grava tudo num único `INSERT` antes de responder | REG-01 (10 cadastros seguidos, 14 categorias, nenhuma repetida) |

## 4. O que ainda não está resolvido

### 4.1 Paginação (3º ciclo, 23/11/2026)

No 2º ciclo restavam 6 medições acima do limite, todas no usuário com **10 mil (V3) ou 50 mil (V4) lançamentos**. A causa: o app **baixava todos os lançamentos a cada recarga** (12 MB em V4) e montava listas inteiras na tela. O que foi feito:

| Onde | Mudança |
|---|---|
| API `GET /incomes` e `/expenses` | Paginadas: no máximo **500 por padrão** (`?limit=` até 1.000, `?offset=`), total no cabeçalho `X-Total-Count` e próxima página em `X-Next-Offset`. Filtros `?from=`/`?to=`; o `?month=` passou a usar faixa de datas (aproveita o índice) |
| API `GET /lancamentos` (nova) | Extrato de receitas **e** despesas juntas, paginado, com **totais, quantidade e soma por categoria do período inteiro** calculados no banco. `GET /lancamentos/meses` lista os meses com dados |
| App: cache | Guarda só o **mês atual em diante** (inclui parcelas futuras). Totais gerais vêm da API |
| App: Histórico "3 meses", "6 meses", "Tudo" e meses antigos em Entradas/Despesas | Buscados página por página (100 itens) com os totais do período vindos da API; a próxima página vem quando o fim da lista aparece |
| App: Entradas/Despesas do mês | Monta 30 linhas por vez (a aba fica viva desde a abertura do app) |

Resultado (evidências em [05-desempenho/evidencias/](05-desempenho/evidencias/resultados.md)):

| Medição que falhava | Antes (2º ciclo) | Depois |
|---|---:|---:|
| Abrir a Início, V3 / V4 | 2.204 / 4.931 ms ❌ | **1.681 / 1.846 ms** ✅ |
| Recarregar, V4 | 2.293 ms ❌ | **388 ms** ✅ (baixa 1,4 MB em vez de 12 MB) |
| `GET /expenses`, V4 | 560 ms ❌ | **11 ms** ✅ (agora devolve a 1ª página, até 500) |
| Histórico "Tudo", V4 | 1.187 ms ❌ | **223 ms** ✅ (até mostrar a 1ª página e os totais) |
| `GET /dashboard` 20 simultâneos, V4 | 1.411 ms ❌ | **1.330 ms ❌** |

Testes novos: **PAG-01 a 08** (API: limite padrão, percorrer páginas sem repetir, totais do período, filtros, parâmetros inválidos, isolamento entre usuários) e **UI-PAG-01/02** (telas reais: o Histórico "Tudo" com 289 lançamentos antigos mostra o total certo e carrega as páginas ao rolar até o fim; Despesas de um mês antigo mostra lista e total vindos da API). Capturas em [reteste/evidencias/telas/](reteste/evidencias/telas/).

**Ajustes em testes antigos, por causa da mudança de comportamento:** o CT-INT-25 lia do cache lançamentos de 12/2025 e agora os lê pela consulta paginada; a imitação do `res` do Express nos testes unitários ganhou `set()`, que a API passou a usar para os cabeçalhos; a medição de desempenho do app passou a medir o que o app faz agora (recarregar o cache do mês e o "Tudo" até a 1ª página aparecer), e as rotas `/incomes` e `/expenses` sem parâmetros aparecem como "1ª página, até 500".

**O que continua pendente:**
- **20 acessos simultâneos ao `/dashboard` com 50 mil lançamentos (1,3 s).** O resumo soma todos os lançamentos do usuário a cada chamada, numa única conexão SQLite. O app não usa essa rota: calcula a partir do cache e de `/lancamentos`. Resolver exige guardar o resumo pronto (cache por usuário) ou trocar o SQLite por um banco com várias conexões.
- **V4 ficou perto do limite** ao abrir a Início (1,85 s de 2 s, em modo debug): quem lança cerca de 2 mil itens **por mês** ainda baixa o mês inteiro ao abrir o app.
- A última página de uma lista longa demora mais que a primeira (V4: 257 ms contra 28 ms), porque a paginação é por `offset`. Ainda está dentro do limite.

### 4.2 Outros pontos

- **DEF-01:** os valores continuam gravados como número decimal (`REAL`). O arredondamento resolve o sintoma; a solução definitiva é guardar em centavos inteiros (migração de banco).
- **Infraestrutura (depende da equipe):** certificado real e hospedagem; e-mail de contato na política (`PRIVACIDADE_CONTATO`); `JWT_SECRET` forte; backup do banco; teste num celular físico.
- **Melhorias registradas, não feitas:** token guardado sem criptografia no aparelho (`flutter_secure_storage`); layout próprio para telas grandes; fonte embutida na versão Web; testes automatizados e integração contínua dentro do projeto.

## 5. Avaliação

| | 1º ciclo | Depois das correções |
|---|---|---|
| Verificações aprovadas (01–06) | 91,5% | **99,8%** (98,8% antes da paginação) |
| Defeitos abertos | 18 | **0** (1 medição de estresse pendente: `/dashboard` simultâneo em V4) |
| Vulnerabilidades em dependências | 7 | **0** |
| Requisitos de loja/LGPD | sem exclusão de conta, sem política, sem HTTPS | **implementados** |

Do ponto de vista do software, o FinUp está apto para produção, inclusive para quem tem dezenas de milhares de lançamentos: com a paginação, o app guarda e baixa só o mês atual. Para publicar, faltam os itens de infraestrutura da seção 4.2.

## 6. Como reexecutar

Na raiz do repositório:

```bash
bash testes/reteste.sh
```

```bash
bash testes/reteste/executar.sh
```
