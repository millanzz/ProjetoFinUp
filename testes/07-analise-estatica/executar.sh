#!/usr/bin/env bash
# Análise estática do FinUp: métricas, analisador Dart (regras do projeto e
# estritas), ESLint + plugin de segurança no backend, auditoria de dependências
# e provas de conceito dos achados da inspeção manual.
# Uso (na raiz do repositório):  bash testes/07-analise-estatica/executar.sh
# Nenhum arquivo do projeto é alterado: as análises "estritas" rodam em cópias.
set -u
AQUI="$(cd "$(dirname "$0")" && pwd)"
RAIZ="$(cd "$AQUI/../.." && pwd)"
EV="$AQUI/evidencias"
F="$AQUI/ferramentas"
T="${TEMP:-/tmp}/finup-analise"
mkdir -p "$EV"

{
  date '+%Y-%m-%d %H:%M:%S %z'; node -v
  (cd "$RAIZ/frontend" && flutter --version 2>&1 | head -1)
  git -C "$RAIZ" rev-parse --short HEAD; git -C "$RAIZ" branch --show-current
} > "$EV/execucao.txt"

# 0) Ferramentas do backend (ficam só em testes/07-analise-estatica/ferramentas)
[ -d "$F/node_modules" ] || (cd "$F" && npm install --no-audit --no-fund)

# 1) Métricas de tamanho
node "$F/metricas.js" "$RAIZ" > "$EV/metricas.md"

# 2) Dart — regras do próprio projeto
(cd "$RAIZ/frontend" && flutter analyze --no-pub lib test > "$EV/dart-analyze-projeto.txt" 2>&1)
echo "exit dart projeto: $?" >> "$EV/execucao.txt"

# 3) Dart — regras estritas, numa cópia do frontend
node -e 'require("fs").rmSync(process.argv[1], { recursive: true, force: true })' "$T"
mkdir -p "$T/frontend/.dart_tool"
cp -r "$RAIZ/frontend/lib" "$RAIZ/frontend/test" "$RAIZ/frontend/pubspec.yaml" "$RAIZ/frontend/pubspec.lock" "$T/frontend/"
cp "$RAIZ/frontend/.dart_tool/package_config.json" "$T/frontend/.dart_tool/"
cp "$F/analysis_options_estrito.yaml" "$T/frontend/analysis_options.yaml"
(cd "$T/frontend" && flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings lib 2>&1 | tr '\\' '/' > "$EV/dart-analyze-estrito.txt")
echo "dart estrito: $(tail -1 "$EV/dart-analyze-estrito.txt")" >> "$EV/execucao.txt"

# 4) ESLint + segurança no backend (numa cópia)
bash "$F/analisar-backend.sh" >> "$EV/execucao.txt"

# 5) Dependências
(cd "$RAIZ/backend" && npm audit --json > "$EV/npm-audit-backend.json" 2>/dev/null; npm outdated > "$EV/npm-outdated-backend.txt" 2>&1)
(cd "$RAIZ/frontend" && flutter pub outdated > "$EV/flutter-pub-outdated.txt" 2>&1)

# 6) Provas de conceito dos achados da inspeção manual (API de teste, banco temporário)
node "$F/provas-de-conceito.js" "$EV/provas-de-conceito.json" > /dev/null
cat "$EV/execucao.txt"
