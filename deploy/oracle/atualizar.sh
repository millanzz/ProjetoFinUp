#!/usr/bin/env bash
# Atualiza a API com a versão mais nova do GitHub, sem perder dados.
# Uso (no servidor, dentro da pasta clonada): sudo bash deploy/oracle/atualizar.sh
set -euo pipefail
ORIGEM="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
sudo -u "$(stat -c %U "$ORIGEM")" git -C "$ORIGEM" pull --ff-only
/usr/local/bin/finup-backup || true
rsync -a --delete --exclude node_modules --exclude .env --exclude database.db \
  --exclude certs "$ORIGEM/backend/" /opt/finup/backend/
cd /opt/finup/backend
npm ci --omit=dev --no-audit --no-fund
systemctl restart finup-api
sleep 2
curl -fs http://127.0.0.1:3000/ && echo && echo "Atualizado."
