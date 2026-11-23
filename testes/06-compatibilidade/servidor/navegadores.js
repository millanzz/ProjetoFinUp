/**
 * Abre o build WEB real do app (flutter build web) em navegadores reais
 * (Chrome e Edge, sem janela) em vários tamanhos, e salva capturas:
 *   - tela de login (sem sessão)
 *   - tela inicial (com sessão: o token do login na API vai para o localStorage,
 *     exatamente onde o shared_preferences do app web guarda)
 *
 * Usa o Chrome DevTools Protocol direto (WebSocket nativo do Node 24).
 * Uso: node navegadores.js <url-do-app> <url-da-api> <pasta-saida>
 */
const { spawn } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const [APP, API, SAIDA] = process.argv.slice(2);
const NAVEGADORES = [
  ['chrome', 'C:/Program Files/Google/Chrome/Application/chrome.exe'],
  ['edge', 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'],
];
const TAMANHOS = [
  ['celular-390x844', 390, 844, 3, true],
  ['tablet-810x1080', 810, 1080, 2, true],
  ['desktop-1280x800', 1280, 800, 1, false],
];
const esperar = (ms) => new Promise((r) => setTimeout(r, ms));

async function cdp(wsUrl) {
  const ws = new WebSocket(wsUrl);
  await new Promise((ok) => ws.addEventListener('open', ok, { once: true }));
  let id = 0;
  const pend = new Map();
  const rede = [];
  ws.addEventListener('message', (ev) => {
    const m = JSON.parse(ev.data);
    if (m.id && pend.has(m.id)) { pend.get(m.id)(m); pend.delete(m.id); }
    if (m.method === 'Network.responseReceived' && m.params.response.url.startsWith(API)) rede.push(`${m.params.response.status} ${m.params.response.url.slice(API.length)}`);
    if (m.method === 'Network.loadingFailed') rede.push(`FALHA ${m.params.errorText}`);
  });
  const enviar = (method, params = {}) => new Promise((ok) => { const i = ++id; pend.set(i, ok); ws.send(JSON.stringify({ id: i, method, params })); });
  return { enviar, rede, fechar: () => ws.close() };
}

async function rodar(nome, exe, token) {
  const perfil = fs.mkdtempSync(path.join(os.tmpdir(), `finup-${nome}-`));
  const porta = nome === 'chrome' ? 9333 : 9334;
  const proc = spawn(exe, ['--headless=new', `--remote-debugging-port=${porta}`, `--user-data-dir=${perfil}`,
    '--no-first-run', '--no-default-browser-check', '--disable-extensions',
    ...(process.env.IGNORAR_CERTIFICADO === '1' ? ['--ignore-certificate-errors'] : []), 'about:blank']);
  let alvo;
  for (let i = 0; i < 40 && !alvo; i++) {
    await esperar(250);
    try { alvo = (await (await fetch(`http://127.0.0.1:${porta}/json`)).json()).find((t) => t.type === 'page'); } catch {}
  }
  const versao = (await (await fetch(`http://127.0.0.1:${porta}/json/version`)).json()).Browser;
  const c = await cdp(alvo.webSocketDebuggerUrl);
  await c.enviar('Page.enable');
  await c.enviar('Runtime.enable');
  await c.enviar('Network.enable');
  const erros = [];
  const registros = [];
  for (const [rotulo, w, h, dpr, movel] of TAMANHOS) {
    await c.enviar('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: dpr, mobile: movel });
    // estado: [nome, com sessão?, endereço aberto]
    for (const [estado, comSessao, rota] of [
      ['login', false, ''],
      ['inicio', true, ''],
      ['rota-home-sem-sessao', false, '#/home'],
    ]) {
      await c.enviar('Page.navigate', { url: 'about:blank' });
      await esperar(300);
      await c.enviar('Page.navigate', { url: APP });
      await esperar(1500);
      await c.enviar('Runtime.evaluate', {
        expression: comSessao
          ? `localStorage.clear(); localStorage.setItem('flutter.auth_token', JSON.stringify(${JSON.stringify(token)})); localStorage.setItem('flutter.theme_mode', JSON.stringify('light'))`
          : `localStorage.clear(); localStorage.setItem('flutter.theme_mode', JSON.stringify('light'))`,
      });
      c.rede.length = 0;
      await c.enviar('Page.navigate', { url: 'about:blank' });
      await esperar(300);
      await c.enviar('Page.navigate', { url: APP + rota }); // abre do zero, como digitar o endereço
      await esperar(comSessao || rota ? 12000 : 6000); // CanvasKit + fontes + dados da API
      const shot = await c.enviar('Page.captureScreenshot', { format: 'png' });
      const arq = `${nome}-${rotulo}-${estado}.png`;
      fs.writeFileSync(path.join(SAIDA, arq), Buffer.from(shot.result.data, 'base64'));
      const info = await c.enviar('Runtime.evaluate', {
        expression: `JSON.stringify({ url: location.href, largura: innerWidth, altura: innerHeight, dpr: devicePixelRatio, ua: navigator.userAgent, canvas: !!document.querySelector('flt-glass-pane, flutter-view') })`,
        returnByValue: true,
      });
      const ls = await c.enviar('Runtime.evaluate', { expression: 'Object.keys(localStorage).join(",")', returnByValue: true });
      registros.push({ navegador: nome, versao, tamanho: rotulo, estado, captura: arq, chaves_localStorage: ls.result.result.value, chamadas_api: [...c.rede], ...JSON.parse(info.result.result.value) });
      console.log(`${nome} ${rotulo} ${estado}: ${arq}  api=[${c.rede.join(' | ')}]`);
    }
  }
  c.fechar();
  proc.kill();
  return { versao, registros, erros };
}

(async () => {
  fs.mkdirSync(SAIDA, { recursive: true });
  const login = await (await fetch(`${API}/auth/login`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'compat@teste.local', password: 'senha123' }),
  })).json();
  const todos = [];
  for (const [nome, exe] of NAVEGADORES) {
    if (!fs.existsSync(exe)) { console.log(`${nome}: não instalado`); continue; }
    todos.push(...(await rodar(nome, exe, login.token)).registros);
  }
  fs.writeFileSync(path.join(SAIDA, 'navegadores.json'), JSON.stringify(todos, null, 2));
})().catch((e) => { console.error(e); process.exit(1); });
