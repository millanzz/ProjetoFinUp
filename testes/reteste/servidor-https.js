/**
 * Sobe a API REAL em HTTPS (certificado de desenvolvimento autoassinado) com
 * um arquivo SQLite de teste, usando o mesmo criarServidor do server.js.
 * Uso: node servidor-https.js <arquivo.db> <porta> <cert.pem> <key.pem>
 */
const path = require('path');

const BACKEND = path.resolve(__dirname, '..', '..', 'backend');
const [arquivo, porta, cert, key] = process.argv.slice(2);

process.env.JWT_SECRET = 'segredo-somente-para-testes';
process.env.JWT_EXPIRES_IN = '7d';
delete process.env.SMTP_HOST;

const sqlite3 = require(path.join(BACKEND, 'node_modules', 'sqlite3'));
const Original = sqlite3.Database;
sqlite3.Database = function (_f, ...r) { return new Original(path.resolve(arquivo), ...r); };

const app = require(path.join(BACKEND, 'src', 'app.js'));
const { criarServidor } = require(path.join(BACKEND, 'src', 'servidorHttp.js'));
const servidor = criarServidor(app, { TLS_CERT: cert, TLS_KEY: key });
servidor.listen(Number(porta), '127.0.0.1', () => console.log(`PRONTO https://127.0.0.1:${porta}`));
