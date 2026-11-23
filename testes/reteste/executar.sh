#!/usr/bin/env bash
# Testes das correções e das funcionalidades novas (reteste).
# Uso (na raiz do repositório):  bash testes/reteste/executar.sh
#   1. API: DEF-14, DEF-17, X-Powered-By, política, exclusão de conta, sessões e HTTPS
#   2. App: DEF-18 (logout) e arredondamento
#   3. Telas reais: excluir conta, política, trocar senha sem cair
#   4. DEF-10: permissão de Internet no APK de release
#   5. DEF-11 + HTTPS: build Web release falando com a API em HTTPS, no Chrome e no Edge
set -u
AQUI="$(cd "$(dirname "$0")" && pwd)"
RAIZ="$(cd "$AQUI/../.." && pwd)"
EV="$AQUI/evidencias"
TMPD="${TEMP:-/tmp}/finup-reteste"
mkdir -p "$EV" "$TMPD"
date '+%Y-%m-%d %H:%M:%S %z' > "$EV/execucao.txt"

(cd "$AQUI" && node --test --test-reporter=spec verificacoes.test.js conta-https.test.js > "$EV/api-saida.txt" 2>&1)
echo "exit api: $?" >> "$EV/execucao.txt"

(cd "$RAIZ/frontend" && flutter test ../testes/reteste/logout_test.dart -r expanded > "$EV/app-saida.txt" 2>&1)
echo "exit app: $?" >> "$EV/execucao.txt"

node -e 'require("fs").rmSync(process.argv[1], { force: true })' "$TMPD/ui.db"
node "$AQUI/../03-integracao/servidor/servidor.js" "$TMPD/ui.db" 3999 > "$TMPD/api-ui.log" 2>&1 &
PID=$!
for _ in $(seq 1 40); do grep -q PRONTO "$TMPD/api-ui.log" && break; sleep 0.5; done
(cd "$RAIZ/frontend" && flutter test ../testes/reteste/fluxos_novos_test.dart --dart-define=API_URL=http://127.0.0.1:3999 \
   --update-goldens -r expanded > "$EV/telas-saida.txt" 2>&1)
echo "exit telas: $?" >> "$EV/execucao.txt"
kill -9 $PID 2>/dev/null

(cd "$RAIZ/frontend" && flutter build apk --release > "$EV/build-apk.txt" 2>&1)
AAPT=$(ls "$LOCALAPPDATA"/Android/sdk/build-tools/*/aapt.exe 2>/dev/null | tail -1)
"$AAPT" dump permissions "$RAIZ/frontend/build/app/outputs/flutter-apk/app-release.apk" > "$EV/apk-release-permissoes.txt"
grep -q "android.permission.INTERNET" "$EV/apk-release-permissoes.txt"; echo "exit apk-internet: $?" >> "$EV/execucao.txt"

(cd "$RAIZ/frontend" && flutter build web --release --dart-define=API_URL=https://127.0.0.1:3443 > "$EV/build-web.txt" 2>&1)
MSYS_NO_PATHCONV=1 openssl req -x509 -newkey rsa:2048 -nodes -days 2 -keyout "$TMPD/key.pem" -out "$TMPD/cert.pem" \
  -subj "/CN=localhost" -addext "subjectAltName=IP:127.0.0.1,DNS:localhost" 2>/dev/null
node -e 'require("fs").rmSync(process.argv[1], { force: true })' "$TMPD/web.db"
node "$AQUI/servidor-https.js" "$TMPD/web.db" 3443 "$TMPD/cert.pem" "$TMPD/key.pem" > "$TMPD/https.log" 2>&1 &
PID=$!
for _ in $(seq 1 40); do grep -q PRONTO "$TMPD/https.log" && break; sleep 0.5; done
NODE_TLS_REJECT_UNAUTHORIZED=0 node "$AQUI/semear-https.js" https://127.0.0.1:3443 > "$TMPD/semear.log" 2>&1
(cd "$RAIZ/frontend/build/web" && python -m http.server 8090 --bind 127.0.0.1 > "$TMPD/web.log" 2>&1) &
WEB=$!
sleep 1
IGNORAR_CERTIFICADO=1 NODE_TLS_REJECT_UNAUTHORIZED=0 node "$AQUI/../06-compatibilidade/servidor/navegadores.js" \
  http://127.0.0.1:8090/ https://127.0.0.1:3443 "$EV/web" > "$EV/web-saida.txt" 2>&1
echo "exit web: $?" >> "$EV/execucao.txt"
kill $WEB $PID 2>/dev/null
pid=$(netstat -ano | grep "127.0.0.1:8090 .*LISTEN" | awk '{print $5}' | head -1); [ -n "$pid" ] && taskkill //PID "$pid" //F > /dev/null
cat "$EV/execucao.txt"
