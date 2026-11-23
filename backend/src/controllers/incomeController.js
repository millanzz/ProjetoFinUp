// Receitas: categoria opcional (do tipo 'income').
module.exports = require('./lancamentoController')({
  table: 'incomes',
  type: 'income',
  categoryRequired: false,
  label: 'Receita',
});
