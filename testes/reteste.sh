#!/usr/bin/env bash
# Reteste (2º ciclo) depois das correções: roda todas as baterias em sequência.
# As evidências do 1º ciclo ficam preservadas em cada pasta como evidencias-ciclo1/.
# Uso (na raiz do repositório):  bash testes/reteste.sh
set -u
T="$(cd "$(dirname "$0")" && pwd)"
LOG="$T/reteste.log"
: > "$LOG"
etapa() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"; }

etapa "01 unitários";       bash "$T/01-unitarios-calculos/executar.sh" >> "$LOG" 2>&1
etapa "02 funcionais";      bash "$T/02-funcionais/executar.sh" >> "$LOG" 2>&1
etapa "03 integração";      bash "$T/03-integracao/executar.sh" >> "$LOG" 2>&1
etapa "04 persistência";    bash "$T/04-persistencia/executar.sh" >> "$LOG" 2>&1
etapa "07 análise estática"; bash "$T/07-analise-estatica/executar.sh" >> "$LOG" 2>&1
etapa "06 compatibilidade"; bash "$T/06-compatibilidade/executar.sh" >> "$LOG" 2>&1
etapa "05 desempenho";      bash "$T/05-desempenho/executar.sh" >> "$LOG" 2>&1
etapa "05 carga";           bash "$T/05-desempenho/carga/executar-carga.sh" >> "$LOG" 2>&1
etapa "fim"
