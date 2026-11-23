# Backend - API Financeira

API REST em Node.js + Express + SQLite com autenticação JWT.

## Como rodar

```bash
# 1. Instalar dependências
npm install

# 2. Criar o .env a partir do exemplo
cp .env.example .env

# 3. Rodar em modo de desenvolvimento (auto-reload ao salvar)
npm run dev

# OU rodar em modo normal
npm start
```

O servidor sobe em `http://localhost:3000`.

## Estrutura

```
backend/
├── server.js                 # entrada da aplicação
├── .env                      # variáveis de ambiente (não commitar!)
├── .env.example              # template do .env
└── src/
    ├── app.js                # configuração do Express (CORS, JSON, rotas)
    ├── database/
    │   └── db.js             # conexão, schema e migrações do SQLite
    ├── controllers/          # lógica de negócio
    ├── middlewares/
    │   └── authMiddleware.js # validação do JWT
    └── routes/               # definição das rotas
```

## Endpoints

### Autenticação e usuário

| Método | Rota | Descrição | Auth |
|--------|------|-----------|------|
| POST | `/users` | Cadastrar usuário (já cria as categorias padrão) | ❌ |
| POST | `/auth/login` | Login (retorna token) | ❌ |
| GET | `/users/me` | Dados do usuário logado | ✅ |
| PUT | `/users/me` | Atualizar nome/email | ✅ |
| PUT | `/users/me/password` | Trocar senha (exige a atual); encerra as outras sessões e devolve um token novo | ✅ |
| DELETE | `/users/me` | Excluir a conta e todos os dados (corpo: `{ "password": "..." }`) | ✅ |
| POST | `/auth/forgot-password` | Pedir código de recuperação por e-mail | ❌ |
| POST | `/auth/reset-password` | Redefinir a senha com o código (encerra as sessões) | ❌ |
| GET | `/privacidade` | Política de Privacidade (página pública) | ❌ |
| GET | `/privacidade.json` | Política de Privacidade (para o app) | ❌ |

Limites de tentativas (respondem `429`): 10 logins errados por IP + e-mail e 10 pedidos de código por IP a cada 15 min; 20 redefinições por IP + e-mail a cada 15 min; 50 cadastros por IP por hora; 5 senhas erradas ao excluir a conta a cada 15 min.

### Categorias (`/categories`)

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/` | Criar categoria |
| GET | `/` | Listar (use `?type=income` ou `?type=expense`) |
| DELETE | `/:id` | Deletar |

### Receitas (`/incomes`) e Despesas (`/expenses`)

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/` | Criar (aceita `parcelado: true/false`) |
| GET | `/` | Listar, paginado (inclui `category_name`). Ver abaixo |
| PUT | `/:id` | Atualizar |
| DELETE | `/:id` | Deletar |

A listagem devolve **no máximo 500 itens por padrão**, do mais recente para o mais antigo. Parâmetros: `?limit=` (0 a 1000), `?offset=`, `?month=AAAA-MM`, `?from=` e `?to=` (AAAA-MM-DD, inclusive). O total do filtro vem no cabeçalho `X-Total-Count` e, se houver mais páginas, o offset da próxima vem em `X-Next-Offset`.

### Extrato (`/lancamentos`)

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/` | Receitas e despesas juntas, paginadas. Mesmos parâmetros da listagem acima, mais `?tipo=receita\|despesa` |
| GET | `/meses` | Meses (`AAAA-MM`) que têm lançamentos, do mais recente ao mais antigo |

Resposta de `GET /lancamentos`: `itens` (cada um com `tipo`), `total`, `proximo_offset` (`null` na última página), `receitas`, `despesas`, `saldo` e, na primeira página, `categorias` (`[{ tipo, categoria, total }]`). Os totais são do **período inteiro**, não só da página. Com `limit=0` vêm só os totais.

### Metas (`/goals`)

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/` | Criar meta (title, target_amount, current_amount, icon) |
| GET | `/` | Listar metas |
| PATCH | `/:id` | Atualizar (title, target_amount, current_amount, icon) |
| DELETE | `/:id` | Deletar |

### Dashboard (`/dashboard`)

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/` | Resumo: saldo, totais, por categoria e evolução mensal. Aceita `?month=YYYY-MM` |

Resposta do dashboard:

```json
{
  "balance": 3555,
  "total_incomes": 3800,
  "total_expenses": 245,
  "expenses_by_category": [{ "category": "Alimentação", "total": 120 }],
  "incomes_by_category": [{ "category": "Salário", "total": 3000 }],
  "monthly": [{ "month": "2026-07", "incomes": 3800, "expenses": 245 }]
}
```

## Como autenticar

Todas as rotas protegidas exigem o header:

```
Authorization: Bearer <token>
```

O token você obtém ao fazer login.

## Exemplos com cURL

### 1. Cadastro

```bash
curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -d '{"name":"João","email":"joao@email.com","password":"123456"}'
```

### 2. Login

```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"joao@email.com","password":"123456"}'
```

### 3. Criar despesa (autenticado)

```bash
curl -X POST http://localhost:3000/expenses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  -d '{"amount":120.50,"description":"Mercado","date":"2026-07-11","category_id":1}'
```

### 4. Ver o dashboard

```bash
curl http://localhost:3000/dashboard \
  -H "Authorization: Bearer SEU_TOKEN_AQUI"
```

## Integração com o Flutter

O CORS já está liberado. No app, o `baseUrl` fica em
`frontend/lib/core/api_config.dart`:

- **Emulador Android:** `http://10.0.2.2:3000`
- **Dispositivo físico:** `http://SEU_IP_NA_REDE:3000` (ex: `http://192.168.0.10:3000`)
- **Web/desktop:** `http://localhost:3000`

## Produção (HTTPS obrigatório)

Com `NODE_ENV=production` a API **recusa acessos em HTTP** (403) e **não sobe** sem HTTPS configurado, porque senha e token não podem trafegar sem criptografia. Duas formas:

1. **A hospedagem faz o HTTPS** (Render, Railway, Fly.io, Nginx com Let's Encrypt…): defina `TRUST_PROXY=1`. A API confia no cabeçalho `X-Forwarded-Proto` enviado pelo proxy.
2. **HTTPS direto no Node**: defina `TLS_CERT` e `TLS_KEY` com os arquivos do certificado (ex.: Let's Encrypt).

Em HTTPS a API envia `Strict-Transport-Security` (HSTS). Para testar HTTPS na sua máquina: `bash scripts/gerar-certificado-dev.sh` e use `TLS_CERT=certs/dev-cert.pem` e `TLS_KEY=certs/dev-key.pem` (certificado autoassinado: só para desenvolvimento).

O app em **build de produção** só aceita endereço `https://`:

```bash
flutter build apk --release --dart-define=API_URL=https://api.seudominio.com.br
```

Antes de publicar, preencha `PRIVACIDADE_CONTATO` no `.env` (aparece na Política de Privacidade) e use um `JWT_SECRET` longo e aleatório.
