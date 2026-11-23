#!/usr/bin/env bash
# Testes de integração Flutter + API + SQLite. Uso (na raiz do repositório):
#   bash testes/03-integracao/executar.sh
# Os próprios testes sobem e derrubam a API (node servidor/servidor.js) na porta 3999
# e recriam os arquivos .db de evidência a cada execução.
set -u
AQUI="$(cd "$(dirname "$0")" && pwd)"
RAIZ="$(cd "$AQUI/../.." && pwd)"
EV="$AQUI/evidencias"
EVW="$(cygpath -m "$EV" 2>/dev/null || echo "$EV")"  # caminho que o Flutter entende no Windows
mkdir -p "$EV/rastros"
{
  date '+%Y-%m-%d %H:%M:%S %z'
  node -v
  (cd "$RAIZ/frontend" && flutter --version 2>&1 | head -1)
  git -C "$RAIZ" rev-parse --short HEAD
  git -C "$RAIZ" branch --show-current
} > "$EV/execucao.txt"
(cd "$RAIZ/frontend" && flutter test ../testes/03-integracao/flutter/integracao_test.dart \
  --dart-define=API_URL=http://127.0.0.1:3999 -r expanded \
  --file-reporter json:"$EVW/resultado.json" > "$EV/saida.txt" 2>&1)
echo "exit: $?" >> "$EV/execucao.txt"
node "$AQUI/servidor/exportar-banco.js" "$EV/banco-integracao.db" > "$EV/banco-integracao-conteudo.sql"
node "$AQUI/servidor/exportar-banco.js" "$EV/banco-legado-migrado.db" > "$EV/banco-legado-migrado-conteudo.sql"
cat "$EV/execucao.txt"
