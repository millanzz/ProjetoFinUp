const express = require('express');
const cors = require('cors');
const app = express();
// Não anuncia "X-Powered-By: Express" nas respostas
app.disable('x-powered-by');

// Atrás de um proxy/hospedagem que faz o HTTPS (TRUST_PROXY=1), confia no
// cabeçalho X-Forwarded-Proto para saber se o acesso original foi HTTPS.
if (process.env.TRUST_PROXY === '1') app.set('trust proxy', 1);

// HTTPS obrigatório em produção: recusa acessos em HTTP (senhas e tokens não
// podem trafegar sem criptografia) e avisa o navegador para sempre usar HTTPS.
app.use((req, res, next) => {
  if (req.secure) {
    res.set('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  } else if (process.env.NODE_ENV === 'production' && req.path !== '/') {
    return res.status(403).json({ error: 'Use HTTPS para acessar a API' });
  }
  next();
});

// importa o banco (executa criação das tabelas)
require('./database/db');

// middlewares globais
// libera o acesso para o app Flutter; expõe os cabeçalhos de paginação para a versão Web
app.use(cors({ exposedHeaders: ['X-Total-Count', 'X-Next-Offset'] }));
app.use(express.json());

// rota de healthcheck
app.get('/', (req, res) => {
  res.json({ status: 'ok', message: 'API rodando 🚀' });
});

// Política de privacidade pública (sem login): página e versão para o app
const politica = require('./legal/politicaPrivacidade');
app.get('/privacidade', (req, res) => res.type('html').send(politica.html()));
app.get('/privacidade.json', (req, res) => res.json(politica.json()));

// importar rotas
const userRoutes = require('./routes/userRoutes');
const authRoutes = require('./routes/authRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const incomeRoutes = require('./routes/incomeRoutes');
const expenseRoutes = require('./routes/expenseRoutes');
const goalRoutes = require('./routes/goalRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');
const extratoRoutes = require('./routes/extratoRoutes');

// registrar rotas com prefixo
app.use('/users', userRoutes);
app.use('/auth', authRoutes);
app.use('/categories', categoryRoutes);
app.use('/incomes', incomeRoutes);
app.use('/expenses', expenseRoutes);
app.use('/goals', goalRoutes);
app.use('/dashboard', dashboardRoutes);
app.use('/lancamentos', extratoRoutes);

// middleware 404 (rota não encontrada)
app.use((req, res) => {
  res.status(404).json({ error: 'Rota não encontrada' });
});

// middleware de tratamento de erro genérico
// eslint-disable-next-line no-unused-vars -- o Express exige os 4 parâmetros
app.use((err, req, res, next) => {
  // Erros do próprio cliente (ex.: JSON malformado, corpo grande demais) vêm
  // com status 4xx: responde esse status em vez de 500 (DEF-04).
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ error: 'JSON inválido no corpo da requisição' });
  }
  const status = err.status || err.statusCode;
  if (status >= 400 && status < 500) {
    return res.status(status).json({ error: 'Requisição inválida' });
  }
  console.error(err);
  res.status(500).json({ error: 'Erro interno do servidor' });
});

module.exports = app;
