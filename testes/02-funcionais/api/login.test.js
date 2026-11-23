const { describe, test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { iniciar, cliente } = require('./servidor');

let srv, api, ana;

describe('Login (POST /auth/login) e acesso autenticado', () => {
  before(async () => {
    srv = await iniciar();
    api = cliente(srv.base);
    ana = await api.novoUsuario('Ana Souza', 'ana@teste.local', 'senha123');
  });
  after(() => srv.fechar());

  test('CT-LOG-01 login com e-mail e senha corretos devolve token e dados do usuário', async () => {
    const r = await api.post('/auth/login', { body: { email: 'ana@teste.local', password: 'senha123' } });
    assert.equal(r.status, 200);
    assert.ok(r.body.token && r.body.token.split('.').length === 3, 'token JWT');
    assert.deepEqual(r.body.user, { id: ana.user.id, name: 'Ana Souza', email: 'ana@teste.local' });
    assert.equal(r.body.user.password, undefined, 'não pode devolver a senha');
  });

  test('CT-LOG-02 e-mail com maiúsculas e espaços é aceito (não diferencia)', async () => {
    const r = await api.post('/auth/login', { body: { email: '  ANA@Teste.Local ', password: 'senha123' } });
    assert.equal(r.status, 200);
  });

  test('CT-LOG-03 senha errada é recusada com 401', async () => {
    const r = await api.post('/auth/login', { body: { email: 'ana@teste.local', password: 'errada' } });
    assert.equal(r.status, 401);
    assert.equal(r.body.error, 'Email ou senha inválidos');
    assert.equal(r.body.token, undefined);
  });

  test('CT-LOG-04 e-mail não cadastrado recebe a mesma mensagem (não revela quem tem conta)', async () => {
    const r = await api.post('/auth/login', { body: { email: 'ninguem@teste.local', password: 'senha123' } });
    assert.equal(r.status, 401);
    assert.equal(r.body.error, 'Email ou senha inválidos');
  });

  test('CT-LOG-05 senha diferencia maiúsculas', async () => {
    const r = await api.post('/auth/login', { body: { email: 'ana@teste.local', password: 'SENHA123' } });
    assert.equal(r.status, 401);
  });

  test('CT-LOG-06 campos vazios ou ausentes são recusados com 400', async () => {
    for (const body of [{}, { email: 'ana@teste.local' }, { password: 'senha123' }, { email: '', password: '' }]) {
      const r = await api.post('/auth/login', { body });
      assert.equal(r.status, 400, JSON.stringify(body));
    }
  });

  test('CT-LOG-07 senha enviada como número é recusada com erro de cliente (4xx)', async () => {
    const r = await api.post('/auth/login', { body: { email: 'ana@teste.local', password: 123456 } });
    assert.ok(r.status >= 400 && r.status < 500, `status veio ${r.status}: ${JSON.stringify(r.body)}`);
  });

  test('CT-LOG-08 corpo JSON malformado é recusado com 400', async () => {
    const r = await api.post('/auth/login', { raw: '{"email": "ana@teste.local", ' });
    assert.equal(r.status, 400, `status veio ${r.status}: ${JSON.stringify(r.body)}`);
  });

  test('CT-LOG-09 o token do login dá acesso a GET /users/me', async () => {
    const r = await api.get('/users/me', { token: ana.token });
    assert.equal(r.status, 200);
    assert.equal(r.body.email, 'ana@teste.local');
    assert.equal(r.body.password, undefined);
  });

  test('CT-LOG-10 rotas protegidas sem token respondem 401', async () => {
    for (const rota of ['/users/me', '/incomes', '/expenses', '/goals', '/categories', '/dashboard']) {
      const r = await api.get(rota);
      assert.equal(r.status, 401, rota);
      assert.equal(r.body.error, 'Token não fornecido');
    }
  });

  test('CT-LOG-11 token mal formatado, adulterado ou expirado responde 401', async () => {
    const mal = await api.get('/users/me', { headers: { Authorization: `Token ${ana.token}` } });
    assert.equal(mal.status, 401);
    const partes = ana.token.split('.');
    const adulterado = `${partes[0]}.${Buffer.from(JSON.stringify({ id: 999, email: 'x' })).toString('base64url')}.${partes[2]}`;
    assert.equal((await api.get('/users/me', { token: adulterado })).status, 401);
    const outraChave = srv.jwt.sign({ id: ana.user.id }, 'chave-errada');
    assert.equal((await api.get('/users/me', { token: outraChave })).status, 401);
    const expirado = srv.jwt.sign({ id: ana.user.id, exp: Math.floor(Date.now() / 1000) - 60 }, process.env.JWT_SECRET);
    const r = await api.get('/users/me', { token: expirado });
    assert.equal(r.status, 401);
    assert.equal(r.body.error, 'Token inválido ou expirado');
  });

  test('CT-LOG-12 token expira no prazo configurado (JWT_EXPIRES_IN)', async () => {
    const r = await api.post('/auth/login', { body: { email: 'ana@teste.local', password: 'senha123' } });
    const { iat, exp } = srv.jwt.decode(r.body.token);
    assert.equal(exp - iat, 3600);
  });
});
