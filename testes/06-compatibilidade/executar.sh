#!/usr/bin/env bash
# Teste de compatibilidade (tamanhos de tela, aparelhos, fonte, tema, teclado).
# Uso (na raiz do repositório):  bash testes/06-compatibilidade/executar.sh
set -u
AQUI="$(cd "$(dirname "$0")" && pwd)"
RAIZ="$(cd "$AQUI/../.." && pwd)"
EV="$AQUI/evidencias"
EVW="$(cygpath -m "$EV" 2>/dev/null || echo "$EV")"
TMPD="${TEMP:-/tmp}/finup-compat"
mkdir -p "$EV/telas" "$TMPD"
node -e 'require("fs").rmSync(process.argv[1], { force: true })' "$TMPD/compat.db"

{
  date '+%Y-%m-%d %H:%M:%S %z'; node -v
  (cd "$RAIZ/frontend" && flutter --version 2>&1 | head -1)
  git -C "$RAIZ" rev-parse --short HEAD; git -C "$RAIZ" branch --show-current
} > "$EV/execucao.txt"

node "$AQUI/../03-integracao/servidor/servidor.js" "$TMPD/compat.db" 3999 > "$TMPD/api.log" 2>&1 &
PID=$!
for _ in $(seq 1 40); do grep -q PRONTO "$TMPD/api.log" && break; sleep 0.5; done

(cd "$RAIZ/frontend" && flutter test ../testes/06-compatibilidade/flutter/compat_test.dart \
   --dart-define=API_URL=http://127.0.0.1:3999 -r expanded \
   --file-reporter json:"$EVW/resultado-testes.json" > "$EV/saida.txt" 2>&1)
echo "exit: $?" >> "$EV/execucao.txt"
kill -9 $PID 2>/dev/null

python "$AQUI/servidor/folhas.py" "$EV"
cat "$EV/execucao.txt"
