/**
 * Exporta o schema e o conteúdo de um arquivo SQLite de teste (evidência).
 * Senhas aparecem só como o prefixo do hash.  Uso: node exportar-banco.js <arquivo.db>
 */
const path = require('path');
const sqlite3 = require(path.resolve(__dirname, '..', '..', '..', 'backend', 'node_modules', 'sqlite3'));
const db = new sqlite3.Database(path.resolve(process.argv[2]), sqlite3.OPEN_READONLY);
const all = (sql) => new Promise((ok, err) => db.all(sql, (e, r) => (e ? err(e) : ok(r))));
(async () => {
  const out = [];
  const tabelas = await all("SELECT name, sql FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name");
  out.push('-- SCHEMA', ...tabelas.map((t) => `${t.sql};`), '');
  for (const { name } of tabelas) {
    let linhas = await all(`SELECT * FROM "${name}"`);
    if (name === 'users') linhas = linhas.map((u) => ({ ...u, password: `${u.password.slice(0, 7)}…(hash bcrypt)` }));
    out.push(`-- ${name}: ${linhas.length} linha(s)`, ...linhas.map((l) => JSON.stringify(l)), '');
  }
  console.log(out.join('\n'));
  db.close();
})();
