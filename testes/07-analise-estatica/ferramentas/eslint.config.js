// Configuração do ESLint usada só na análise estática do backend.
// Regras recomendadas + plugin de segurança + limites de complexidade.
const js = require('@eslint/js');
const globals = require('globals');
const security = require('eslint-plugin-security');

module.exports = [
  { ignores: ['node_modules/**'] },
  js.configs.recommended,
  security.configs.recommended,
  {
    files: ['**/*.js'],
    languageOptions: { ecmaVersion: 2023, sourceType: 'commonjs', globals: { ...globals.node } },
    rules: {
      complexity: ['warn', 10],             // caminhos independentes por função
      'max-depth': ['warn', 4],
      'max-lines-per-function': ['warn', { max: 60, skipBlankLines: true, skipComments: true }],
      'max-params': ['warn', 4],
      'max-nested-callbacks': ['warn', 3],
      'no-unused-vars': ['warn', { args: 'after-used', argsIgnorePattern: '^_' }],
      'no-return-await': 'warn',
      'require-await': 'warn',
      'prefer-const': 'warn',
      'no-var': 'warn',
      eqeqeq: ['warn', 'smart'],
      'no-console': 'off',
      'consistent-return': 'warn',
      'no-shadow': 'warn',
      'default-param-last': 'warn',
    },
  },
];
