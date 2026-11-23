#!/usr/bin/env bash
# Instala a API do FinUp com HTTPS num servidor Ubuntu (Oracle Cloud Free).
#
# Uso (no servidor, dentro da pasta clonada do repositório):
#   sudo bash deploy/oracle/instalar.sh SEU-NOME.duckdns.org seu-email@exemplo.com
#
# O que faz:
#   - instala Node.js 22, SQLite e Caddy (proxy que obtém e renova sozinho o
#     certificado HTTPS do Let's Encrypt);
#   - copia o código para /opt/finup e o banco fica em /var/lib/finup (fora do
#     código, sobrevive às atualizações);
#   - gera /etc/finup/finup.env com um JWT_SECRET aleatório (só na 1ª vez);
#   - cria o serviço finup-api (sobe sozinho quando o servidor liga);
#   - libera as portas 80 e 443 no firewall do Ubuntu;
#   - agenda um backup diário do banco (guarda os últimos 14).
#
# Pode ser executado de novo sem perder dados.
set -euo pipefail

DOMINIO="${1:-}"
CONTATO="${2:-}"
if [[ -z "$DOMINIO" || -z "$CONTATO" ]]; then
  echo "Uso: sudo bash deploy/oracle/instalar.sh SEU-NOME.duckdns.org seu-email@exemplo.com" >&2
  exit 1
fi
if [[ $EUID -ne 0 ]]; then
  echo "Execute com sudo." >&2
  exit 1
fi

ORIGEM="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP=/opt/finup
DADOS=/var/lib/finup
CONF=/etc/finup

echo "==> Pacotes do sistema"
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q ca-certificates curl gnupg git sqlite3 build-essential python3 \
  debian-keyring debian-archive-keyring apt-transport-https iptables-persistent rsync

if ! command -v node >/dev/null || [[ "$(node -v | cut -d. -f1)" != "v22" ]]; then
  echo "==> Node.js 22"
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt-get install -y -q nodejs
fi

if ! command -v caddy >/dev/null; then
  echo "==> Caddy"
  curl -1sLf https://dl.cloudsmith.io/public/caddy/stable/gpg.key \
    | gpg --dearmor --yes -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt \
    > /etc/apt/sources.list.d/caddy-stable.list
  apt-get update -q
  apt-get install -y -q caddy
fi

echo "==> Usuário e pastas"
id finup >/dev/null 2>&1 || useradd --system --home "$APP" --shell /usr/sbin/nologin finup
mkdir -p "$APP" "$DADOS/backups" "$CONF"
chown -R finup:finup "$DADOS"
chmod 750 "$DADOS"

echo "==> Código"
rsync -a --delete --exclude node_modules --exclude .env --exclude database.db \
  --exclude certs "$ORIGEM/backend/" "$APP/backend/"
cd "$APP/backend"
npm ci --omit=dev --no-audit --no-fund
chown -R root:root "$APP"

if [[ ! -f "$CONF/finup.env" ]]; then
  echo "==> Configuração (/etc/finup/finup.env)"
  cat > "$CONF/finup.env" <<EOF
NODE_ENV=production
TRUST_PROXY=1
HOST=127.0.0.1
PORT=3000
DB_PATH=$DADOS/database.db
JWT_SECRET=$(openssl rand -hex 48)
JWT_EXPIRES_IN=7d
PRIVACIDADE_CONTATO=$CONTATO
# E-mail do "Esqueci minha senha". Sem SMTP_HOST o código só aparece no log.
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=
SMTP_FROM=
EOF
fi
chown root:finup "$CONF/finup.env"
chmod 640 "$CONF/finup.env"

echo "==> Serviço finup-api"
install -m 644 "$ORIGEM/deploy/oracle/finup-api.service" /etc/systemd/system/finup-api.service
install -m 644 "$ORIGEM/deploy/oracle/finup-backup.service" /etc/systemd/system/finup-backup.service
install -m 644 "$ORIGEM/deploy/oracle/finup-backup.timer" /etc/systemd/system/finup-backup.timer
install -m 755 "$ORIGEM/deploy/oracle/backup.sh" /usr/local/bin/finup-backup
systemctl daemon-reload
systemctl enable --now finup-backup.timer
systemctl enable finup-api
systemctl restart finup-api

echo "==> HTTPS (Caddy) para $DOMINIO"
sed "s/__DOMINIO__/$DOMINIO/" "$ORIGEM/deploy/oracle/Caddyfile" > /etc/caddy/Caddyfile
systemctl enable caddy
systemctl reload caddy 2>/dev/null || systemctl restart caddy

echo "==> Firewall do Ubuntu (portas 80 e 443)"
# As imagens Ubuntu da Oracle terminam a cadeia INPUT com um REJECT; as regras
# novas entram antes dele.
for porta in 80 443; do
  iptables -C INPUT -p tcp --dport "$porta" -m state --state NEW -j ACCEPT 2>/dev/null && continue
  pos="$(iptables -L INPUT --line-numbers -n | awk '$2=="REJECT"{print $1; exit}')"
  if [[ -n "$pos" ]]; then
    iptables -I INPUT "$pos" -p tcp --dport "$porta" -m state --state NEW -j ACCEPT
  else
    iptables -A INPUT -p tcp --dport "$porta" -m state --state NEW -j ACCEPT
  fi
done
netfilter-persistent save

echo "==> Conferindo"
for i in $(seq 1 20); do
  curl -fs http://127.0.0.1:3000/ >/dev/null && break
  sleep 1
done
if curl -fs http://127.0.0.1:3000/ >/dev/null; then
  echo "API no ar internamente."
else
  echo "A API não respondeu. Veja: sudo journalctl -u finup-api -n 50" >&2
  exit 1
fi
echo
echo "Pronto. Em 1 ou 2 minutos (tempo do certificado) abra:"
echo "  https://$DOMINIO/"
echo "  https://$DOMINIO/privacidade"
echo "Se não abrir, confira as portas 80 e 443 na Security List da Oracle e veja:"
echo "  sudo journalctl -u caddy -n 50"
