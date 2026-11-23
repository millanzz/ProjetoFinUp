# Reteste após as correções — comparativo antes × depois

| Item | Valor |
|---|---|
| Projeto | FinUp — Sistema de Gestão Financeira |
| 1º ciclo (falhas encontradas) | 07 a 09/11/2026 — evidências em `evidencias-ciclo1/` de cada pasta |
| Correções e reteste (2º ciclo) | 22/11/2026, 21:39 a 23:25 (UTC−3) — evidências em `evidencias/` de cada pasta e em [reteste/](reteste/) |
| Versão testada | branch `redesign-fusao-tema-escuro`, commit `e1376b8` + alterações locais (nada foi commitado) |
| Resultado | **Os 18 defeitos foram corrigidos e confirmados por teste.** Os testes de desempenho ainda têm **6 medições acima do limite** nos cenários de estresse (10 mil e 50 mil lançamentos de um só usuário); a causa e o que falta estão na seção 4 |

---

## 1. Resultado por bateria

| Bateria | 1º ciclo | Reteste | Diferença |
|---|---:|---:|---|
| 01 Unitário | 55/59 | **59/59** | +4 |
| 02 Funcional | 67/70 | **70/70** | +3 |
| 03 Integração | 24/25 | **25/25** | +1 |
| 04 Persistência | 14/14 | **14/14** | = |
| 05 Desempenho | 89/102 | **96/102** | +7 |
| 06 Compatibilidade | 201/222 | **222/222** | +21 |
| **Total (01–06)** | **450/492 (91,5%)** | **486/492 (98,8%)** | **+36** |
| 07 Estático: vulnerabilidades (`npm audit`) | 7 (2 críticas) | **0** | −7 |
| 07 Estático: provas de conceito | 2 falhas confirmadas | **0** | −2 |
| Reteste: testes novos ([reteste/](reteste/)) | — | **18 + 2 + 5 passaram**; APK e Web conferidos | novo |

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

### 4.1 Cenários de estresse de desempenho (6 medições)

Todas no usuário com **10 mil (V3) ou 50 mil (V4) lançamentos**:

- abrir a Início (2,2 s e 4,9 s);
- recarregar tudo (2,3 s em V4);
- `GET /expenses` (560 ms em V4);
- 20 acessos simultâneos ao resumo (1,4 s em V4);
- Histórico “Tudo” (1,2 s em V4).

A causa é a mesma: o app **baixa todos os lançamentos de uma vez** (12 MB em V4), e a API usa **uma única conexão** com o SQLite. A correção exige **paginação**: o app buscar por mês e a API paginar as listas. É uma mudança de arquitetura, fora desta rodada. No uso típico (até 1.000 lançamentos) todas as medições estão no limite.

### 4.2 Outros pontos

- **DEF-01:** os valores continuam gravados como número decimal (`REAL`). O arredondamento resolve o sintoma; a solução definitiva é guardar em centavos inteiros (migração de banco).
- **Infraestrutura (depende da equipe):** certificado real e hospedagem; e-mail de contato na política (`PRIVACIDADE_CONTATO`); `JWT_SECRET` forte; backup do banco; teste num celular físico; **versionar no git** os arquivos que ainda estão fora dele (nada foi commitado).
- **Melhorias registradas, não feitas:** token guardado sem criptografia no aparelho (`flutter_secure_storage`); layout próprio para telas grandes; fonte embutida na versão Web; testes automatizados e integração contínua dentro do projeto.

## 5. Avaliação

| | 1º ciclo | Depois das correções |
|---|---|---|
| Verificações aprovadas (01–06) | 91,5% | **98,8%** |
| Defeitos abertos | 18 | **0** (6 medições de estresse pendentes de paginação) |
| Vulnerabilidades em dependências | 7 | **0** |
| Requisitos de loja/LGPD | sem exclusão de conta, sem política, sem HTTPS | **implementados** |

Do ponto de vista do software, o FinUp está apto para produção com **uso típico** (centenas de usuários, até alguns milhares de lançamentos por pessoa). Para publicar, faltam os itens de infraestrutura da seção 4.2. Para usuários com dezenas de milhares de lançamentos, falta a paginação da seção 4.1.

## 6. Como reexecutar

Na raiz do repositório:

```bash
bash testes/reteste.sh
```

```bash
bash testes/reteste/executar.sh
```
