/**
 * Cria o servidor da API: HTTPS quando há certificado, HTTP só quando é seguro.
 *
 *  - TLS_CERT e TLS_KEY definidos  → HTTPS direto no Node (certificado próprio).
 *  - TRUST_PROXY=1                 → HTTP interno atrás de um proxy/hospedagem que
 *                                    faz o HTTPS (Render, Railway, Nginx…).
 *  - NODE_ENV=production sem nada disso → recusa subir: senhas e tokens
 *                                    trafegariam sem criptografia.
 *  - desenvolvimento               → HTTP local, como antes.
 */
const fs = require('fs');
const http = require('http');
const https = require('https');

function criarServidor(app, env = process.env) {
  if (env.TLS_CERT && env.TLS_KEY) {
    return https.createServer(
      { cert: fs.readFileSync(env.TLS_CERT), key: fs.readFileSync(env.TLS_KEY) },
      app
    );
  }
  if (env.NODE_ENV === 'production' && env.TRUST_PROXY !== '1') {
    throw new Error(
      'Produção exige HTTPS: defina TLS_CERT e TLS_KEY, ou TRUST_PROXY=1 se um proxy/hospedagem já faz o HTTPS.'
    );
  }
  return http.createServer(app);
}

module.exports = { criarServidor };
