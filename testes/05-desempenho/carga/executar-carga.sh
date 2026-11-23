#!/usr/bin/env bash
# Teste de carga: 10, 50 e 100 usuários simultâneos, 60 s cada, na API real.
# Uso (na raiz do repositório):  bash testes/05-desempenho/carga/executar-carga.sh
# Banco: o mesmo gerador do teste de desempenho, com 51 contas
# (perf@teste.local + outro1..50@teste.local, senha "senha123"), 1.000 lançamentos
# para a conta principal e 50.000 divididos entre as outras (1.000 cada).
set -u
AQUI="$(cd "$(dirname "$0")" && pwd)"
EV="$AQUI/evidencias"
TMPD="${TEMP:-/tmp}/finup-carga"
SERVIDOR="$AQUI/../../03-integracao/servidor/servidor.js"
mkdir -p "$EV" "$TMPD"

node "$AQUI/../servidor/semear.js" "$TMPD/carga.db" 1000 50000 > "$EV/banco.json"
{
  date '+%Y-%m-%d %H:%M:%S %z'; node -v
  powershell -NoProfile -Command "'CPU: ' + (Get-CimInstance Win32_Processor).Name; 'RAM: ' + [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1) + ' GB'" 2>/dev/null
  echo "banco: $(cat "$EV/banco.json")"
} > "$EV/execucao.txt"

for U in 10 50 100; do
  node "$SERVIDOR" "$TMPD/carga.db" 3999 > "$TMPD/api-$U.log" 2>&1 &
  PID=$!
  for _ in $(seq 1 60); do grep -q PRONTO "$TMPD/api-$U.log" && break; sleep 0.5; done
  node "$AQUI/carga.js" "$U" 60 "$EV/carga-$U-usuarios.json" | tee -a "$EV/execucao.txt"
  kill -9 $PID 2>/dev/null; wait $PID 2>/dev/null
  sleep 2
done
