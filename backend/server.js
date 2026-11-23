require('dotenv').config();

// Sem JWT_SECRET o login quebraria com erro 500 genérico.
if (!process.env.JWT_SECRET) {
  console.error(
    'ERRO: JWT_SECRET não está definido. Copie .env.example para .env e preencha.'
  );
  process.exit(1);
}

const app = require('./src/app');
const { criarServidor } = require('./src/servidorHttp');

const PORT = process.env.PORT || 3000;
// HOST=127.0.0.1 deixa a API acessível só pelo proxy HTTPS da mesma máquina.
const HOST = process.env.HOST || undefined;

let servidor;
try {
  servidor = criarServidor(app);
} catch (err) {
  console.error(`ERRO: ${err.message}`);
  process.exit(1);
}

servidor.listen(PORT, HOST, () => {
  const https = Boolean(process.env.TLS_CERT && process.env.TLS_KEY);
  console.log(`Servidor rodando na porta ${PORT} (${https ? 'HTTPS' : 'HTTP'})`);
  if (!https && process.env.NODE_ENV !== 'production') {
    console.log('Aviso: HTTP só para desenvolvimento. Em produção use HTTPS (veja o .env.example).');
  }
});
