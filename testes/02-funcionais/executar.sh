#!/usr/bin/env bash
# Executa a bateria de testes funcionais e grava as evidências.
# Uso (na raiz do repositório):  bash testes/02-funcionais/executar.sh
set -u
AQUI="$(cd "$(dirname "$0")" && pwd)"
RAIZ="$(cd "$AQUI/../.." && pwd)"
EV="$AQUI/evidencias"
EVW="$(cygpath -m "$EV" 2>/dev/null || echo "$EV")"  # caminho que o Flutter entende no Windows
PORTA=3999
mkdir -p "$EV/telas"

{
  date '+%Y-%m-%d %H:%M:%S %z'
  node -v
  (cd "$RAIZ/frontend" && flutter --version 2>&1 | head -1)
  git -C "$RAIZ" rev-parse --short HEAD
  git -C "$RAIZ" branch --show-current
} > "$EV/execucao.txt"

# 1) API (cada arquivo sobe a própria API com banco em memória)
(cd "$AQUI/api" && node --test --test-concurrency=1 \
  --test-reporter=spec --test-reporter-destination=stdout \
  --test-reporter=junit --test-reporter-destination="$EV/api-junit.xml" \
  login.test.js cadastro.test.js edicao.test.js exclusao.test.js > "$EV/api-saida.txt" 2>&1)
echo "exit api: $?" >> "$EV/execucao.txt"

# 2) Interface: sobe a API de teste na porta 3999 e roda as telas reais contra ela
node "$AQUI/api/servidor.js" $PORTA > "$EV/app-servidor-log.txt" 2>&1 &
SRV=$!
sleep 2
(cd "$RAIZ/frontend" && flutter test ../testes/02-funcionais/app/fluxos_test.dart \
  --dart-define=API_URL=http://127.0.0.1:$PORTA --update-goldens -r expanded \
  --file-reporter json:"$EVW/app-resultado.json" > "$EV/app-saida.txt" 2>&1)
echo "exit app: $?" >> "$EV/execucao.txt"
kill $SRV 2>/dev/null
cat "$EV/execucao.txt"
