#!/usr/bin/env bash
# Teste de desempenho: tempo de resposta com diferentes quantidades de registros.
# Uso (na raiz do repositório):  bash testes/05-desempenho/executar.sh
#
# Cenários (lançamentos do usuário medido / lançamentos de outros usuários no banco):
#   V1    100 / 0     V2  1.000 / 0     V3  10.000 / 0     V4  50.000 / 0
#   C1  1.000 / 100.000                 C2   1.000 / 500.000
# Os bancos de cada cenário ficam numa pasta temporária (podem passar de 40 MB).
set -u
AQUI="$(cd "$(dirname "$0")" && pwd)"
RAIZ="$(cd "$AQUI/../.." && pwd)"
EV="$AQUI/evidencias"
RES="$EV/resultados"
TMPD="${TEMP:-/tmp}/finup-desempenho"
SERVIDOR="$AQUI/../03-integracao/servidor/servidor.js"
mkdir -p "$RES" "$TMPD"

if [ -n "${SO_CENARIO:-}" ]; then
  # Reexecução de um cenário só: acrescenta aos registros existentes
  echo "--- reexecução do cenário $SO_CENARIO em $(date '+%Y-%m-%d %H:%M:%S %z') ---" | tee -a "$EV/execucao.txt" "$EV/saida-api.txt" "$EV/saida-app.txt"
else
{
  date '+%Y-%m-%d %H:%M:%S %z'; node -v
  (cd "$RAIZ/frontend" && flutter --version 2>&1 | head -1)
  git -C "$RAIZ" rev-parse --short HEAD; git -C "$RAIZ" branch --show-current
  powershell -NoProfile -Command "'CPU: ' + (Get-CimInstance Win32_Processor).Name; 'RAM: ' + [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1) + ' GB'; 'Disco: ' + (Get-CimInstance Win32_DiskDrive | Select -First 1).Model" 2>/dev/null
} > "$EV/execucao.txt"
: > "$EV/saida-api.txt"; : > "$EV/saida-app.txt"
fi

cenario() { # $1 nome  $2 lançamentos do usuário  $3 lançamentos de outros
  local nome=$1 db="$TMPD/$1.db"
  echo "== Cenário $nome: usuário=$2 outros=$3 ==" | tee -a "$EV/saida-api.txt" "$EV/saida-app.txt"
  node "$AQUI/servidor/semear.js" "$db" "$2" "$3" > "$RES/banco-$nome.json"
  echo "   banco: $(cat "$RES/banco-$nome.json")"
  node "$SERVIDOR" "$db" 3999 > "$TMPD/api-$nome.log" 2>&1 &
  local pid=$!
  for _ in $(seq 1 60); do grep -q PRONTO "$TMPD/api-$nome.log" && break; sleep 0.5; done
  node "$AQUI/servidor/medir-api.js" "$nome" "$RES/api-$nome.json" >> "$EV/saida-api.txt" 2>&1
  echo "exit api $nome: $?" >> "$EV/execucao.txt"
  (cd "$RAIZ/frontend" && flutter test ../testes/05-desempenho/flutter/medir_app_test.dart \
     --dart-define=API_URL=http://127.0.0.1:3999 --dart-define=CENARIO="$nome" >> "$EV/saida-app.txt" 2>&1)
  echo "exit app $nome: $?" >> "$EV/execucao.txt"
  kill -9 "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
  sleep 1
}

[ "${SO_CENARIO:-}" = "" ] || { cenario "$SO_CENARIO" "$SO_USUARIO" "$SO_OUTROS"; node "$AQUI/servidor/consolidar.js" "$RES" > "$EV/resultados.md"; python "$AQUI/servidor/graficos.py" "$RES" "$EV"; exit 0; }
cenario V1 100 0
cenario V2 1000 0
cenario V3 10000 0
cenario V4 50000 0
cenario C1 1000 100000
cenario C2 1000 500000

node "$AQUI/servidor/consolidar.js" "$RES" > "$EV/resultados.md"
python "$AQUI/servidor/graficos.py" "$RES" "$EV"
cat "$EV/execucao.txt"
