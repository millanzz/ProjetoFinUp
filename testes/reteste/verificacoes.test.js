/**
 * Verificações específicas das correções que nenhuma bateria anterior
 * cobria diretamente: DEF-14 (limite de tentativas), DEF-17 (HTML no e-mail)
 * e o cabeçalho X-Powered-By. Rodam contra a API real com banco em memória.
 * Uso: node --test --test-reporter=spec verificacoes.test.js
 */
const { describe, test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const path = require('path');

const BACKEND = path.resolve(__dirname, '..', '..', 'backend');

// O e-mail de recuperação é capturado antes de carregar a API.
const mailer = require(path.join(BACKEND, 'src', 'utils', 'mailer.js'));
const emails = [];
mailer.enviarEmail = async (msg) => { emails.push(msg); };

const { iniciar, cliente } = require('../02-funcionais/api/servidor');

let srv, api;

describe('Verificação das correções sem bateria própria', () => {
  before(async () => {
    srv = await iniciar();
    api = cliente(srv.base);
    await api.novoUsuario('Ana', 'ana@teste.local');
  });
  after(() => srv.fechar());

  test('DEF-14a login: depois de 10 senhas erradas a 11ª tentativa recebe 429', async () => {
    for (let i = 0; i < 10; i++) {
      const r = await api.post('/auth/login', { body: { email: 'ana@teste.local', password: `errada${i}` } });
      assert.equal(r.status, 401, `tentativa ${i + 1}`);
    }
    const bloqueada = await api.post('/auth/login', { body: { email: 'ana@teste.local', password: 'senha123' } });
    assert.equal(bloqueada.status, 429, 'nem a senha certa passa durante o bloqueio');
    assert.match(bloqueada.body.error, /Muitas tentativas/);
  });

  test('DEF-14b o bloqueio é por e-mail: outra conta continua entrando normalmente', async () => {
    await api.novoUsuario('Beto', 'beto@teste.local');
    const r = await api.post('/auth/login', { body: { email: 'beto@teste.local', password: 'senha123' } });
    assert.equal(r.status, 200);
  });

  test('DEF-14c logins certos não contam para o limite (20 seguidos passam)', async () => {
    for (let i = 0; i < 20; i++) {
      const r = await api.post('/auth/login', { body: { email: 'beto@teste.local', password: 'senha123' } });
      assert.equal(r.status, 200, `login ${i + 1}`);
    }
  });

  test('DEF-14d pedir código de recuperação: o 11º pedido do mesmo IP recebe 429', async () => {
    const status = [];
    for (let i = 0; i < 11; i++) {
      status.push((await api.post('/auth/forgot-password', { body: { email: `x${i}@teste.local` } })).status);
    }
    assert.deepEqual(status.slice(0, 10), Array(10).fill(200));
    assert.equal(status[10], 429);
  });

  test('DEF-14e redefinir senha: a 21ª tentativa para o mesmo e-mail recebe 429', async () => {
    const status = [];
    for (let i = 0; i < 21; i++) {
      status.push((await api.post('/auth/reset-password', {
        body: { email: 'beto@teste.local', code: String(100000 + i), new_password: 'novasenha1' },
      })).status);
    }
    assert.ok(status.slice(0, 20).every((s) => s === 400), `primeiras 20: ${status.slice(0, 20)}`);
    assert.equal(status[20], 429);
  });

  test('DEF-17 nome com HTML chega escapado no e-mail de recuperação', async () => {
    await api.novoUsuario('<img src=x onerror=alert(1)>', 'html@teste.local');
    // A rota /auth/forgot-password já está no limite deste IP (DEF-14d), então
    // este caso chama o controller direto, com uma requisição simulada.
    const ctrl = require(path.join(BACKEND, 'src', 'controllers', 'passwordResetController.js'));
    const res = { status() { return this; }, json() { return this; } };
    await ctrl.forgotPassword({ body: { email: 'html@teste.local' } }, res);
    const msg = emails.find((e) => e.para === 'html@teste.local');
    assert.ok(msg, 'e-mail enviado');
    assert.ok(!msg.html.includes('<img'), 'a tag não pode aparecer crua no HTML');
    assert.ok(msg.html.includes('&lt;img'), 'a tag aparece escapada');
  });

  test('REG-01 quando o cadastro responde, as 14 categorias padrão já estão gravadas (sem repetir)', async () => {
    const contar = (email) => new Promise((ok, err) => srv.db.get(
      `SELECT COUNT(*) AS n, COUNT(DISTINCT c.type || c.name) AS unicas FROM categories c JOIN users u ON u.id = c.user_id WHERE u.email = ?`,
      [email], (e, r) => (e ? err(e) : ok(r))));
    for (let i = 0; i < 10; i++) {
      const email = `reg${i}@teste.local`;
      const r = await api.post('/users', { body: { name: `Reg ${i}`, email, password: 'senha123' } });
      assert.equal(r.status, 201);
      assert.deepEqual(await contar(email), { n: 14, unicas: 14 }, `cadastro ${i + 1}`);
    }
  });

  test('OBS-16 a API não anuncia X-Powered-By: Express', async () => {
    const r = await fetch(`${srv.base}/`);
    assert.equal(r.headers.get('x-powered-by'), null);
  });
});
