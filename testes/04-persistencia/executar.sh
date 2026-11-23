#!/usr/bin/env bash
# Teste de persistência: os dados continuam salvos depois de reiniciar?
# Uso (na raiz do repositório):  bash testes/04-persistencia/executar.sh
#
# Linha do tempo:
#   API sobe ─ FASE 1 (app usa e fecha) ─ API cai à força e sobe ─ FASE 2 (app reabre do zero, sai da conta)
#   ─ API cai à força e sobe ─ FASE 3 (app reabre no login) ─ API cai ─ comparação do banco ─ durabilidade
set -u
AQUI="$(cd "$(dirname "$0")" && pwd)"
RAIZ="$(cd "$AQUI/../.." && pwd)"
EV="$AQUI/evidencias"
BANCO="$EV/banco-persistencia.db"
SERVIDOR="$AQUI/../03-integracao/servidor/servidor.js"
EXPORTAR="$AQUI/../03-integracao/servidor/exportar-banco.js"
API_URL=http://127.0.0.1:3999
mkdir -p "$EV/telas" "$EV/aparelho"

# Limpa o estado da execução anterior (arquivos fixos, um a um)
node -e '
const fs = require("fs"), p = require("path"), ev = process.argv[1];
for (const f of ["banco-persistencia.db", "aparelho/shared_preferences.json", "diario.md",
  "estado-antes-de-reiniciar.json", "api-log.txt", "comparacao-banco.txt"]) fs.rmSync(p.join(ev, f), { force: true });
' "$EV"

PID_API=""
subir_api() {
  node "$SERVIDOR" "$BANCO" 3999 >> "$EV/api-log.txt" 2>&1 &
  PID_API=$!
  for _ in $(seq 1 40); do grep -q "PRONTO" <(tail -n 3 "$EV/api-log.txt") && break; sleep 0.5; done
  echo "[$(date '+%H:%M:%S')] API iniciada (pid $PID_API)" | tee -a "$EV/linha-do-tempo.txt"
}
derrubar_api() {
  kill -9 "$PID_API" 2>/dev/null; wait "$PID_API" 2>/dev/null
  echo "[$(date '+%H:%M:%S')] API derrubada à força (pid $PID_API)" | tee -a "$EV/linha-do-tempo.txt"
  sleep 1
}
fase() { # $1 = arquivo de teste, $2 = nome, $3.. = flags extras
  local arq="$1" nome="$2"; shift 2
  echo "[$(date '+%H:%M:%S')] $nome — processo novo do app" | tee -a "$EV/linha-do-tempo.txt"
  (cd "$RAIZ/frontend" && flutter test "../testes/04-persistencia/flutter/$arq" --dart-define=API_URL=$API_URL \
     -r expanded "$@" > "$EV/saida-$nome.txt" 2>&1)
  local st=$?
  echo "[$(date '+%H:%M:%S')] $nome terminou (exit $st)" | tee -a "$EV/linha-do-tempo.txt"
  echo "exit $nome: $st" >> "$EV/execucao.txt"
}

{
  date '+%Y-%m-%d %H:%M:%S %z'; node -v
  (cd "$RAIZ/frontend" && flutter --version 2>&1 | head -1)
  git -C "$RAIZ" rev-parse --short HEAD; git -C "$RAIZ" branch --show-current
} > "$EV/execucao.txt"
: > "$EV/linha-do-tempo.txt"
printf '# Diário da execução — teste de persistência\n' > "$EV/diario.md"

subir_api
fase fase1_uso_test.dart fase1 --update-goldens
node "$EXPORTAR" "$BANCO" > "$EV/banco-apos-fase1.sql"
sha256sum "$BANCO" | cut -c1-64 > "$EV/sha256-apos-fase1.txt"
derrubar_api

subir_api
fase fase2_reabertura_test.dart fase2
derrubar_api

subir_api
fase fase3_apos_sair_test.dart fase3
derrubar_api

node "$EXPORTAR" "$BANCO" > "$EV/banco-final.sql"
if diff -u "$EV/banco-apos-fase1.sql" "$EV/banco-final.sql" > "$EV/comparacao-banco.txt"; then
  echo "IDÊNTICO: o conteúdo do banco após 3 reinícios é igual ao do fim da fase 1." > "$EV/comparacao-banco.txt"
fi
echo "sha256 final: $(sha256sum "$BANCO" | cut -c1-64)" >> "$EV/comparacao-banco.txt"
echo "sha256 após fase 1: $(cat "$EV/sha256-apos-fase1.txt")" >> "$EV/comparacao-banco.txt"

(cd "$AQUI/servidor" && node --test --test-reporter=spec durabilidade.test.js > "$EV/saida-durabilidade.txt" 2>&1)
echo "exit durabilidade: $?" >> "$EV/execucao.txt"
cat "$EV/execucao.txt"; cat "$EV/comparacao-banco.txt"
