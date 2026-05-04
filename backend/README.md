<<<<<<< HEAD
# 💰 Personal Finance Manager

<p align="center">
  <strong>A modern mobile solution for personal financial management</strong><br>
  Organize your finances, track expenses, and achieve your financial goals.
</p>

---

## 📖 Overview

**Personal Finance Manager** is a mobile application designed to help individuals manage their finances efficiently and intuitively.  

The system enables users to track income and expenses, visualize financial data, and set goals — all in a centralized and user-friendly environment.

The project focuses on **simplicity, usability, and financial awareness**, making it accessible even for users with no prior financial knowledge.

---

## 🎯 Key Features

- 🔐 User authentication and account management  
- 💵 Income (receitas) tracking  
- 💸 Expense (despesas) tracking  
- 🏷️ Custom categories for better organization  
- 📊 Real-time balance overview  
- 📈 Financial reports and data visualization  
- 🎯 Financial goal creation and tracking  
- 🧾 Transaction history with filters  
- 📱 Mobile-first intuitive interface  

---

## 🧱 Tech Stack

### 📱 Frontend
- Flutter  
- Dart  

### ⚙️ Backend
- Node.js  
- RESTful API  

### 🗄️ Database
- SQLite  

### 📊 Data Visualization
- fl_chart (Flutter charting library for financial data visualization)

---

## 🏗️ Architecture

The system follows a **client-server architecture**:

```
Mobile App (Flutter)
        ↓
   REST API (Node.js)
        ↓
   Database (SQLite)
```

- The mobile app handles user interaction and UI  
- The backend processes business logic and authentication  
- The database stores financial data securely  

---

## 📱 Application Screens

- Login & Registration  
- Dashboard (Financial Overview)  
- Income Management  
- Expense Management  
- Financial Goals  
- Transaction History  
- User Profile  

---

## 🔐 Non-Functional Requirements

- High usability and intuitive UX  
- Secure data handling and authentication  
- Fast response time  
- Cross-device compatibility  
- Data consistency and reliability  

---

## 📊 Project Goals

- Improve personal financial organization  
- Provide clear financial insights  
- Reduce dependency on manual tools (spreadsheets, notes)  
- Encourage better financial habits  
- Support financial planning and decision-making  

---

## ⚠️ Limitations

- Designed for **individual users only**  
- No enterprise or business features  
- No direct bank API integration (manual input required)  

---

## 🚧 Project Status

> 🟡 **In Development**

- ✅ UI/UX structure implemented  
- ✅ Core features defined  
- 🚧 Backend integration in progress  
- 🚧 Data persistence improvements planned  
- 🔜 UI refinements and performance optimization  

---

## 👨‍💻 Team

Developed by students from **USCS – Universidade Municipal de São Caetano do Sul**:

- Gustavo Nascimento Millan  
- Lucas Valério Banhara Copeski  
- Lucas Theodoro Ribas  
- Lucas Zezi Razzante  
- Rebeca Mendes de Souza  
- Thiago Silva Rodrigues  
- Paulo Henrique do Santos Xavier  

---

## 📄 License

This project is intended for **academic and educational purposes only**.

---

## ⭐ Contribution

Contributions, suggestions, and improvements are welcome!

If you like this project, consider giving it a ⭐ on GitHub.
=======
# Backend - API Financeira

API REST em Node.js + Express + SQLite com autenticação JWT.

## Como rodar

```bash
# 1. Instalar dependências
npm install

# 2. Copiar o .env de exemplo (já vem um .env pronto para dev)
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
    ├── app.js                # configuração do Express
    ├── database/
    │   └── db.js             # conexão e schema do SQLite
    ├── controllers/          # lógica de negócio
    ├── middlewares/
    │   └── authMiddleware.js # validação do JWT
    └── routes/               # definição das rotas
```

## Endpoints

### Autenticação

| Método | Rota | Descrição | Auth |
|--------|------|-----------|------|
| POST | `/users` | Cadastrar usuário | ❌ |
| POST | `/auth/login` | Login (retorna token) | ❌ |
| GET | `/users/me` | Dados do usuário logado | ✅ |

### Categorias (`/categories`)

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/` | Criar categoria |
| GET | `/` | Listar (use `?type=income` ou `?type=expense` para filtrar) |
| DELETE | `/:id` | Deletar |

### Receitas (`/incomes`) e Despesas (`/expenses`)

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/` | Criar |
| GET | `/` | Listar |
| DELETE | `/:id` | Deletar |

### Metas (`/goals`)

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/` | Criar meta |
| GET | `/` | Listar metas |
| PATCH | `/:id` | Atualizar (title, target_amount, current_amount) |
| DELETE | `/:id` | Deletar |

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

Resposta:
```json
{
  "token": "eyJhbGciOiJI...",
  "user": { "id": 1, "name": "João", "email": "joao@email.com" }
}
```

### 3. Criar categoria (autenticado)

```bash
curl -X POST http://localhost:3000/categories \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  -d '{"name":"Alimentação","type":"expense"}'
```

### 4. Criar despesa

```bash
curl -X POST http://localhost:3000/expenses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  -d '{"amount":120.50,"description":"Mercado","date":"2026-05-04","category_id":1}'
```

## Próximos passos sugeridos

- [ ] Criar endpoint de resumo (`GET /dashboard`) com totais agregados
- [ ] Adicionar paginação nas listagens
- [ ] Adicionar testes (Jest + Supertest)
- [ ] Configurar CORS para o frontend Flutter consumir
>>>>>>> 49d78c8 (subindo pasta backend)
