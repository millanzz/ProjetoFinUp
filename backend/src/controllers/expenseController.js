// Despesas: categoria obrigatória (do tipo 'expense').
module.exports = require('./lancamentoController')({
  table: 'expenses',
  type: 'expense',
  categoryRequired: true,
  label: 'Despesa',
});
