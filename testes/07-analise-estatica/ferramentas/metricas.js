/**
 * Métricas de tamanho do código-fonte (linhas totais, de código, comentários e
 * em branco) por arquivo e por camada. Uso: node metricas.js <raiz-do-repo>  > metricas.md
 */
const fs = require('fs');
const path = require('path');
const raiz = path.resolve(process.argv[2]);
const alvos = [
  ['Backend (Node.js)', 'backend', ['server.js', 'src'], '.js'],
  ['Frontend (Flutter)', 'frontend', ['lib'], '.dart'],
  ['Testes do frontend', 'frontend', ['test'], '.dart'],
];
function arquivos(dir, ext) {
  if (!fs.existsSync(dir)) return [];
  if (fs.statSync(dir).isFile()) return dir.endsWith(ext) ? [dir] : [];
  return fs.readdirSync(dir).flatMap((f) => arquivos(path.join(dir, f), ext));
}
function contar(arq) {
  const linhas = fs.readFileSync(arq, 'utf8').split(/\r?\n/);
  let branco = 0, comentario = 0, emBloco = false;
  for (const l of linhas) {
    const t = l.trim();
    if (emBloco) { comentario++; if (t.includes('*/')) emBloco = false; continue; }
    if (!t) branco++;
    else if (t.startsWith('//')) comentario++;
    else if (t.startsWith('/*')) { comentario++; if (!t.includes('*/')) emBloco = true; }
  }
  const funcoes = (fs.readFileSync(arq, 'utf8').match(arq.endsWith('.js')
    ? /(function\s+\w+|=>\s*{|async\s*\(|exports\.\w+\s*=)/g
    : /^\s*(static\s+)?(Future<[^>]*>|void|Widget|String\??|int|double|bool|List<[^>]*>|[A-Z]\w*\??)\s+\w+\s*\(/gm) || []).length;
  return { total: linhas.length, codigo: linhas.length - branco - comentario, comentario, branco, funcoes };
}
const out = ['| Camada | Arquivos | Linhas | Código | Comentários | % comentários |', '|---|---:|---:|---:|---:|---:|'];
const det = ['', '## Maiores arquivos (linhas de código)', '', '| Arquivo | Código | Comentários |', '|---|---:|---:|'];
const todos = [];
for (const [nome, base, dirs, ext] of alvos) {
  const fs_ = dirs.flatMap((d) => arquivos(path.join(raiz, base, d), ext));
  const m = fs_.map((f) => ({ f: path.relative(raiz, f).split(path.sep).join('/'), ...contar(f) }));
  todos.push(...m);
  const s = (k) => m.reduce((a, x) => a + x[k], 0);
  out.push(`| ${nome} | ${m.length} | ${s('total')} | ${s('codigo')} | ${s('comentario')} | ${((100 * s('comentario')) / Math.max(1, s('codigo'))).toFixed(0)}% |`);
}
for (const x of todos.sort((a, b) => b.codigo - a.codigo).slice(0, 12)) det.push(`| \`${x.f}\` | ${x.codigo} | ${x.comentario} |`);
console.log(out.concat(det).join('\n'));
