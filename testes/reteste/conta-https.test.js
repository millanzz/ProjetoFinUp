/**
 * Testes das funcionalidades novas, exigidas para produção:
 *   - Política de privacidade pública (GET /privacidade e /privacidade.json)
 *   - Exclusão de conta (DELETE /users/me) com apagamento de todos os dados
 *   - Encerramento de sessões ao trocar/redefinir senha e ao excluir a conta
 *   - HTTPS: servidor com TLS, recusa de HTTP em produção e cabeçalho HSTS
 * API real com banco em memória. Uso: node --test --test-reporter=spec conta-https.test.js
 */
process.env.TRUST_PROXY = '1'; // lido pelo app.js ao carregar (simula estar atrás de um proxy HTTPS)

const { describe, test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { execFileSync } = require('child_process');
const fs = require('fs');
const https = require('https');
const os = require('os');
const path = require('path');

const BACKEND = path.resolve(__dirname, '..', '..', 'backend');
const mailer = require(path.join(BACKEND, 'src', 'utils', 'mailer.js'));
const emails = [];
mailer.enviarEmail = async (msg) => { emails.push(msg); };

const { iniciar, cliente } = require('../02-funcionais/api/servidor');
const { criarServidor } = require(path.join(BACKEND, 'src', 'servidorHttp.js'));

let srv, api;
const sql = (q, p = []) => new Promise((ok, err) => srv.db.all(q, p, (e, r) => (e ? err(e) : ok(r))));

describe('Funcionalidades para produção', () => {
  before(async () => {
    srv = await iniciar();
    api = cliente(srv.base);
  });
  after(() => srv.fechar());

  // ── Política de privacidade ─────────────────────────────────
  test('PRIV-01 política pública em HTML e JSON, sem login', async () => {
    const h = await fetch(`${srv.base}/privacidade`);
    assert.equal(h.status, 200);
    assert.match(h.headers.get('content-type'), /text\/html/);
    const texto = await h.text();
    assert.match(texto, /Política de Privacidade — FinUp/);
    assert.match(texto, /Excluir conta/);
    const j = await api.get('/privacidade.json');
    assert.equal(j.status, 200);
    assert.equal(j.body.secoes.length, 9);
  });

  // ── Exclusão de conta ───────────────────────────────────────
  test('CONTA-01 excluir conta exige a senha atual (sem senha 400, errada 401)', async () => {
    const u = await api.novoUsuario('Ana', 'ana@teste.local', 'senha123');
    assert.equal((await api.del('/users/me', { token: u.token })).status, 400);
    assert.equal((await api.del('/users/me', { token: u.token, body: { password: 'errada' } })).status, 401);
    assert.equal((await api.get('/users/me', { token: u.token })).status, 200, 'conta continua');
  });

  test('CONTA-02 excluir conta apaga todos os dados do usuário e só dele', async () => {
    const u = await api.novoUsuario('Beto', 'beto@teste.local', 'senha123');
    const outro = await api.novoUsuario('Caio', 'caio@teste.local', 'senha123');
    const cat = u.categorias['expense:Moradia'];
    await api.post('/expenses', { token: u.token, body: { amount: 900, date: '2026-11-05', category_id: cat, parcelas: 3 } });
    await api.post('/incomes', { token: u.token, body: { amount: 3000, date: '2026-11-05' } });
    await api.post('/goals', { token: u.token, body: { title: 'Viagem', target_amount: 5000 } });
    await api.post('/categories', { token: u.token, body: { name: 'Pets', type: 'expense' } });
    await api.post('/auth/forgot-password', { body: { email: 'beto@teste.local' } });
    await api.post('/incomes', { token: outro.token, body: { amount: 10, date: '2026-11-05' } });

    const r = await api.del('/users/me', { token: u.token, body: { password: 'senha123' } });
    assert.equal(r.status, 204);
    const id = u.user.id;
    for (const t of ['incomes', 'expenses', 'goals', 'categories', 'password_resets']) {
      assert.deepEqual(await sql(`SELECT id FROM ${t} WHERE user_id = ?`, [id]), [], `${t} do usuário excluído`);
    }
    assert.deepEqual(await sql('SELECT id FROM users WHERE id = ?', [id]), []);
    assert.equal((await api.get('/incomes', { token: outro.token })).body.length, 1, 'dados de outro usuário intactos');
  });

  test('CONTA-03 token de conta excluída deixa de funcionar (401, nunca 500)', async () => {
    const u = await api.novoUsuario('Duda', 'duda@teste.local', 'senha123');
    await api.del('/users/me', { token: u.token, body: { password: 'senha123' } });
    for (const [m, rota, body] of [['get', '/users/me'], ['get', '/incomes'], ['post', '/incomes', { amount: 1, date: '2026-11-01' }]]) {
      const r = await api[m](rota, { token: u.token, body });
      assert.equal(r.status, 401, `${m} ${rota}`);
    }
  });

  test('CONTA-04 depois de excluir, o login falha e o e-mail pode ser usado de novo', async () => {
    const u = await api.novoUsuario('Eva', 'eva@teste.local', 'senha123');
    await api.del('/users/me', { token: u.token, body: { password: 'senha123' } });
    assert.equal((await api.post('/auth/login', { body: { email: 'eva@teste.local', password: 'senha123' } })).status, 401);
    assert.equal((await api.post('/users', { body: { name: 'Eva', email: 'eva@teste.local', password: 'outra123' } })).status, 201);
  });

  // ── Sessões ─────────────────────────────────────────────────
  test('SESS-01 trocar a senha encerra os outros tokens e devolve um novo', async () => {
    const u = await api.novoUsuario('Fabi', 'fabi@teste.local', 'senha123');
    await new Promise((r) => setTimeout(r, 1100)); // o token novo precisa de outro segundo
    const r = await api.put('/users/me/password', { token: u.token, body: { current_password: 'senha123', new_password: 'nova4567' } });
    assert.equal(r.status, 200);
    assert.ok(r.body.token, 'resposta traz o token novo');
    assert.equal((await api.get('/users/me', { token: u.token })).status, 401, 'token antigo recusado');
    assert.equal((await api.get('/users/me', { token: r.body.token })).status, 200, 'token novo funciona');
  });

  test('SESS-02 redefinir a senha pelo código encerra as sessões abertas', async () => {
    const u = await api.novoUsuario('Gabi', 'gabi@teste.local', 'senha123');
    await new Promise((r) => setTimeout(r, 1100));
    // a rota /auth/forgot-password tem limite por IP: chama o controller direto
    const ctrl = require(path.join(BACKEND, 'src', 'controllers', 'passwordResetController.js'));
    const res = { status() { return this; }, json() { return this; } };
    await ctrl.forgotPassword({ body: { email: 'gabi@teste.local' } }, res);
    const codigo = emails.filter((e) => e.para === 'gabi@teste.local').pop().texto.match(/\b\d{6}\b/)[0];
    const r = await api.post('/auth/reset-password', { body: { email: 'gabi@teste.local', code: codigo, new_password: 'nova4567' } });
    assert.equal(r.status, 200);
    assert.equal((await api.get('/users/me', { token: u.token })).status, 401);
  });

  // ── HTTPS ───────────────────────────────────────────────────
  test('HTTPS-01 com TLS_CERT/TLS_KEY a API atende em HTTPS (TLS) e envia HSTS', async () => {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'finup-tls-'));
    execFileSync('openssl', ['req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '1',
      '-keyout', path.join(dir, 'key.pem'), '-out', path.join(dir, 'cert.pem'), '-subj', '/CN=localhost'], { stdio: 'ignore' });
    const app = require(path.join(BACKEND, 'src', 'app.js'));
    const servidor = criarServidor(app, { TLS_CERT: path.join(dir, 'cert.pem'), TLS_KEY: path.join(dir, 'key.pem') });
    assert.ok(servidor instanceof https.Server);
    await new Promise((ok) => servidor.listen(0, '127.0.0.1', ok));
    const r = await new Promise((ok, err) => {
      https.get({ host: '127.0.0.1', port: servidor.address().port, path: '/', rejectUnauthorized: false, agent: false }, (res) => {
        const cifra = res.socket.getCipher(); // lido enquanto a conexão TLS está aberta
        let b = ''; res.on('data', (d) => { b += d; }); res.on('end', () => ok({ res, b, cifra }));
      }).on('error', err);
    });
    try {
      assert.equal(r.res.statusCode, 200);
      assert.ok(r.cifra && r.cifra.name, `conexão criptografada (${r.cifra && r.cifra.name})`);
      assert.match(r.res.headers['strict-transport-security'] || '', /max-age=/);
    } finally {
      servidor.closeAllConnections();
      await new Promise((ok) => servidor.close(ok));
    }
  });

  test('HTTPS-02 em produção sem TLS nem proxy HTTPS a API se recusa a subir', () => {
    const app = require(path.join(BACKEND, 'src', 'app.js'));
    assert.throws(() => criarServidor(app, { NODE_ENV: 'production' }), /HTTPS/);
  });

  test('HTTPS-03 em produção atrás de proxy: HTTP é recusado e HTTPS é aceito', async () => {
    const antes = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';
    try {
      const http = await fetch(`${srv.base}/privacidade.json`, { headers: { 'X-Forwarded-Proto': 'http' } });
      assert.equal(http.status, 403);
      assert.match((await http.json()).error, /HTTPS/);
      const seguro = await fetch(`${srv.base}/privacidade.json`, { headers: { 'X-Forwarded-Proto': 'https' } });
      assert.equal(seguro.status, 200);
      assert.match(seguro.headers.get('strict-transport-security') || '', /max-age=/);
    } finally {
      process.env.NODE_ENV = antes;
    }
  });
});
