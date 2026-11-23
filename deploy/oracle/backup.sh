#!/usr/bin/env bash
# Cópia consistente do banco (funciona com a API rodando) e mantém as 14 últimas.
set -euo pipefail
DADOS=/var/lib/finup
DESTINO="$DADOS/backups/finup-$(date +%F).db"
[[ -f "$DADOS/database.db" ]] || exit 0
sqlite3 "$DADOS/database.db" ".backup '$DESTINO'"
ls -1t "$DADOS"/backups/finup-*.db | tail -n +15 | xargs -r rm --
