#!/usr/bin/env bash
# Roda o ESLint numa CÓPIA do backend (o ESLint 9 só analisa arquivos abaixo da
# pasta da configuração). O projeto não é alterado. Uso: bash analisar-backend.sh
set -u
AQUI="$(cd "$(dirname "$0")" && pwd)"
EV="$AQUI/../evidencias"
ALVO="$AQUI/alvo/backend"
node -e 'require("fs").rmSync(process.argv[1], { recursive: true, force: true })' "$AQUI/alvo"
mkdir -p "$ALVO"
cp -r "$AQUI/../../../backend/server.js" "$AQUI/../../../backend/src" "$ALVO/"
cd "$AQUI"
npx eslint -c eslint.config.js "alvo/backend" > "$EV/eslint-backend.txt" 2>&1
echo "exit eslint: $?"
npx eslint -c eslint.config.js "alvo/backend" -f json -o "$EV/eslint-backend.json"
node -e '
const r = require(process.argv[1]); const c = {}; let t = 0;
for (const f of r) for (const m of f.messages) { c[m.ruleId] = (c[m.ruleId] || 0) + 1; t++; }
console.log("total:", t); console.log(Object.entries(c).sort((a, b) => b[1] - a[1]));' "$EV/eslint-backend.json"
# Troca o caminho da cópia pelo do projeto nos relatórios e apaga a cópia
sed -i 's#[^ "]*alvo[\/]backend#backend#g' "$EV/eslint-backend.txt" "$EV/eslint-backend.json"
node -e 'require("fs").rmSync(process.argv[1], { recursive: true, force: true })' "$AQUI/alvo"
