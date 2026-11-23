#!/usr/bin/env bash
# Gera um certificado AUTOASSINADO para testar a API em HTTPS na sua máquina.
# NÃO use em produção: lá o certificado deve vir de uma autoridade (ex.: Let's
# Encrypt) ou do provedor de hospedagem, que normalmente cuida do HTTPS.
#
# Uso (na pasta backend):  bash scripts/gerar-certificado-dev.sh
# Depois, no .env:  TLS_CERT=certs/dev-cert.pem  e  TLS_KEY=certs/dev-key.pem
set -eu
cd "$(dirname "$0")/.."
mkdir -p certs
MSYS_NO_PATHCONV=1 openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout certs/dev-key.pem -out certs/dev-cert.pem \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1,IP:10.0.2.2"
echo "Certificado de desenvolvimento criado em backend/certs/ (válido por 365 dias)."
