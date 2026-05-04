const express = require('express');
const app = express();

// importa o banco (executa criação das tabelas)
require('./database/db');

// middlewares globais
app.use(express.json());

// rota de healthcheck
app.get('/', (req, res) => {
  res.json({ status: 'ok', message: 'API rodando 🚀' });
});

// importar rotas
const userRoutes = require('./routes/userRoutes');
const authRoutes = require('./routes/authRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const incomeRoutes = require('./routes/incomeRoutes');
const expenseRoutes = require('./routes/expenseRoutes');
const goalRoutes = require('./routes/goalRoutes');

// registrar rotas com prefixo
app.use('/users', userRoutes);
app.use('/auth', authRoutes);
app.use('/categories', categoryRoutes);
app.use('/incomes', incomeRoutes);
app.use('/expenses', expenseRoutes);
app.use('/goals', goalRoutes);

// middleware 404 (rota não encontrada)
app.use((req, res) => {
  res.status(404).json({ error: 'Rota não encontrada' });
});

// middleware de tratamento de erro genérico
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Erro interno do servidor' });
});

module.exports = app;
