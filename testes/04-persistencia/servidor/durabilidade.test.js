/**
 * Durabilidade do lado do servidor (API + arquivo SQLite).
 * Usa a mesma API de teste da bateria 03 (servidor.js), num arquivo próprio.
 * "Queda abrupta" = o processo da API é encerrado à força (TerminateProcess no
 * Windows), sem tempo para fechar o banco — como um travamento ou um kill -9.
 */
const { describe, test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { spawn } = require('child_process');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const SERVIDOR = path.resolve(__dirname, '..', '..', '03-integracao', 'servidor', 'servidor.js');
const EV = path.resolve(__dirname, '..', 'evidencias');
const BANCO = path.join(EV, 'banco-durabilidade.db');
const PORTA = 3989;
const API = `http://127.0.0.1:${PORTA}`;
const INSP = `http://127.0.0.1:${PORTA + 1}`;
const LOG = path.join(EV, 'durabilidade-log.txt');

let proc;
let reinicios = 0;
const anotar = (s) => fs.appendFileSync(LOG, `[${new Date().toISOString()}] ${s}\n`);

function subir() {
  return new Promise((ok, falha) => {
    proc = spawn(process.execPath, [SERVIDOR, BANCO, String(PORTA)]);
    const t = setTimeout(() => falha(new Error('API não subiu')), 20000);
    proc.stdout.on('data', (d) => {
      if (String(d).includes('PRONTO')) { clearTimeout(t); anotar(`API iniciada (pid ${proc.pid})`); ok(); }
    });
    proc.stderr.on('data', (d) => anotar(`stderr: ${String(d).trim()}`));
  });
}
function derrubar() {
  return new Promise((ok) => {
    const p = proc;
    p.once('exit', () => { anotar(`API derrubada à força (pid ${p.pid})`); setTimeout(ok, 200); });
    p.kill('SIGKILL');
  });
}
async function reiniciarAbrupto() { await derrubar(); await subir(); reinicios++; }

async function req(metodo, rota, { body, token } = {}) {
  const r = await fetch(API + rota, {
    method: metodo,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  const t = await r.text();
  return { status: r.status, body: t ? JSON.parse(t) : null };
}
async function sql(consulta, params = []) {
  const r = await fetch(`${INSP}/sql`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ sql: consulta, params }) });
  return r.json();
}
async function despejo() {
  const out = {};
  for (const t of ['users', 'categories', 'incomes', 'expenses', 'goals', 'password_resets']) out[t] = await sql(`SELECT * FROM ${t} ORDER BY id`);
  return JSON.stringify(out);
}
const sha = () => crypto.createHash('sha256').update(fs.readFileSync(BANCO)).digest('hex');

let token, catDespesa;

describe('Durabilidade da API + SQLite', () => {
  before(async () => {
    if (fs.existsSync(BANCO)) fs.unlinkSync(BANCO);
    if (fs.existsSync(LOG)) fs.unlinkSync(LOG);
    await subir();
    await req('POST', '/users', { body: { name: 'Duda', email: 'duda@teste.local', password: 'senha123' } });
    token = (await req('POST', '/auth/login', { body: { email: 'duda@teste.local', password: 'senha123' } })).body.token;
    catDespesa = (await req('GET', '/categories?type=expense', { token })).body[0].id;
  });
  after(async () => { if (proc && proc.exitCode === null) { proc.kill(); } });

  test('CT-PER-11 cada gravação confirmada sobrevive a uma queda abrupta logo em seguida (10 vezes)', async () => {
    const confirmados = [];
    for (let i = 1; i <= 10; i++) {
      const tipo = ['incomes', 'expenses', 'goals'][i % 3];
      const corpo = tipo === 'goals'
        ? { title: `Meta ${i}`, target_amount: 1000 + i }
        : { amount: i * 11.11, date: `2026-11-${String(i).padStart(2, '0')}`, description: `Gravação ${i}`, category_id: tipo === 'expenses' ? catDespesa : undefined };
      const r = await req('POST', `/${tipo}`, { body: corpo, token });
      assert.equal(r.status, 201);
      confirmados.push({ tipo, id: r.body.id, corpo });
      await reiniciarAbrupto(); // derruba imediatamente após o 201
    }
    for (const c of confirmados) {
      const [row] = await sql(`SELECT * FROM ${c.tipo} WHERE id = ?`, [c.id]);
      assert.ok(row, `${c.tipo} ${c.id} sumiu após a queda`);
      if (c.tipo === 'goals') assert.equal(row.target_amount, c.corpo.target_amount);
      else assert.deepEqual([row.amount, row.date, row.description], [c.corpo.amount, c.corpo.date, c.corpo.description]);
    }
    anotar(`CT-PER-11: ${confirmados.length} gravações confirmadas, ${confirmados.length} encontradas após ${confirmados.length} quedas`);
  });

  test('CT-PER-12 queda no meio de 300 gravações simultâneas: nenhuma confirmada se perde e o banco não corrompe', async () => {
    const confirmados = [];
    const promessas = [];
    let derrubou = null;
    for (let i = 0; i < 300; i++) {
      promessas.push(
        req('POST', '/incomes', { body: { amount: 100 + i, date: '2026-11-15', description: `Rajada ${i}` }, token })
          .then((r) => {
            if (r.status === 201) confirmados.push(r.body.id);
            if (confirmados.length === 20 && !derrubou) derrubou = derrubar();
          })
          .catch(() => {}) // conexões cortadas pela queda: não confirmadas
      );
    }
    await Promise.all(promessas);
    await (derrubou || derrubar());
    await subir();
    reinicios++;
    const gravados = (await sql("SELECT id FROM incomes WHERE description LIKE 'Rajada %'")).map((r) => r.id);
    const perdidos = confirmados.filter((id) => !gravados.includes(id));
    anotar(`CT-PER-12: ${confirmados.length} confirmadas antes da queda, ${gravados.length} no banco depois; perdidas: ${perdidos.length}`);
    assert.deepEqual(perdidos, []);
    assert.deepEqual(await sql('PRAGMA integrity_check'), [{ integrity_check: 'ok' }]);
  });

  test('CT-PER-13 reiniciar 3 vezes sem gravar nada não altera nenhum dado (migrações não mexem nos dados)', async () => {
    const antes = await despejo();
    const shaAntes = sha();
    for (let i = 0; i < 3; i++) { await reiniciarAbrupto(); }
    assert.equal(await despejo(), antes, 'conteúdo das tabelas mudou após reinícios');
    anotar(`CT-PER-13: sha256 antes=${shaAntes.slice(0, 16)}… depois=${sha().slice(0, 16)}…`);
  });

  test('CT-PER-14 após todas as quedas o arquivo está íntegro e com as proteções ativas', async () => {
    assert.deepEqual(await sql('PRAGMA integrity_check'), [{ integrity_check: 'ok' }]);
    assert.deepEqual(await sql('PRAGMA foreign_key_check'), []);
    assert.deepEqual(await sql('PRAGMA foreign_keys'), [{ foreign_keys: 1 }]);
    const [{ journal_mode }] = await sql('PRAGMA journal_mode');
    anotar(`CT-PER-14: ${reinicios} reinícios no total; journal_mode=${journal_mode}; integrity_check=ok`);
    const login = await req('POST', '/auth/login', { body: { email: 'duda@teste.local', password: 'senha123' } });
    assert.equal(login.status, 200, 'usuário e senha sobreviveram a todas as quedas');
    await derrubar();
  });
});
