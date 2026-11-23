#!/usr/bin/env bash
# Testes unitários dos cálculos (backend e app). Uso (na raiz do repositório):
#   bash testes/01-unitarios-calculos/executar.sh
set -u
AQUI="$(cd "$(dirname "$0")" && pwd)"
RAIZ="$(cd "$AQUI/../.." && pwd)"
EV="$AQUI/evidencias"
mkdir -p "$EV"
{
  date '+%Y-%m-%d %H:%M:%S %z'; node -v
  (cd "$RAIZ/frontend" && flutter --version 2>&1 | head -1)
  git -C "$RAIZ" rev-parse --short HEAD; git -C "$RAIZ" branch --show-current
} > "$EV/execucao.txt"
(cd "$AQUI/backend" && node --test --test-reporter=spec --test-reporter-destination=stdout \
  --test-reporter=junit --test-reporter-destination=../evidencias/backend-junit.xml *.test.js > ../evidencias/backend-saida.txt 2>&1)
echo "exit backend: $?" >> "$EV/execucao.txt"
(cd "$RAIZ/frontend" && flutter test ../testes/01-unitarios-calculos/frontend/calculos_test.dart -r expanded > "$EV/frontend-saida.txt" 2>&1)
echo "exit frontend: $?" >> "$EV/execucao.txt"
(cd "$RAIZ/frontend" && flutter test ../testes/01-unitarios-calculos/frontend/calculos_test.dart \
  --file-reporter json:"$(cygpath -m "$EV" 2>/dev/null || echo "$EV")/frontend-resultado.json" -r silent > /dev/null 2>&1)
cat "$EV/execucao.txt"
