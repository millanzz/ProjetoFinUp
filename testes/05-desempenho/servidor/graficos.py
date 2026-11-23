"""Gera os gráficos do teste de desempenho (PNG) a partir dos JSON de resultados.
Uso: python graficos.py <pasta-resultados> <pasta-evidencias>
"""
import json
import os
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

RES, EV = sys.argv[1], sys.argv[2]
ler = lambda f: json.load(open(os.path.join(RES, f), encoding="utf-8")) if os.path.exists(os.path.join(RES, f)) else None
V = ["V1", "V2", "V3", "V4"]
banco = {c: ler(f"banco-{c}.json") for c in V + ["C1", "C2"]}
api = {c: ler(f"api-{c}.json") for c in V + ["C1", "C2"]}
app = {c: ler(f"app-{c}.json") for c in V + ["C1", "C2"]}
x = [banco[c]["lancamentos_usuario"] for c in V if banco[c]]
CORES = ["#2a62d8", "#e0703f", "#2a9d6f", "#8a5cd0", "#c23b6b", "#6b7280"]

plt.rcParams.update({"font.size": 10, "axes.spines.top": False, "axes.spines.right": False})


def rota(c, nome, campo="p95"):
    r = next((r for r in api[c]["rotas"] if r["rota"] == nome), None) if api[c] else None
    return r[campo] if r else None


# 1) API: p95 x volume do usuário
fig, ax = plt.subplots(figsize=(8, 4.6))
for cor, nome in zip(CORES, ["GET /dashboard", "GET /expenses", "GET /incomes", "GET /expenses?month=AAAA-MM", "POST /expenses", "POST /auth/login"]):
    ax.plot(x, [rota(c, nome) for c in V], marker="o", color=cor, label=nome)
ax.axhline(500, color="#b91c1c", ls="--", lw=1)
ax.text(x[0], 520, "limite leitura: 500 ms", color="#b91c1c", fontsize=8)
ax.set_xscale("log"); ax.set_yscale("log")
ax.set_xlabel("Lançamentos do usuário (escala log)"); ax.set_ylabel("p95 (ms, escala log)")
ax.set_title("API — tempo de resposta (p95) × quantidade de registros")
ax.legend(fontsize=8, frameon=False)
fig.tight_layout(); fig.savefig(os.path.join(EV, "grafico-api-volume.png"), dpi=130)

# 2) App: medidas x volume
fig, ax = plt.subplots(figsize=(8, 4.6))
for cor, (k, nome) in zip(CORES, [("entrar_ms", "Entrar"), ("recarga_mediana_ms", "Recarregar lançamentos"),
                                  ("troca_aba_ate_atualizar_mediana_ms", "Trocar de aba"), ("historico_tudo_mediana_ms", 'Histórico "Tudo"'),
                                  ("abrir_inicio_ate_saldo_ms", "Abrir a Início")]):
    ax.plot(x, [app[c][k] if app[c] else None for c in V], marker="o", color=cor, label=nome)
ax.axhline(1000, color="#b91c1c", ls="--", lw=1)
ax.text(x[0], 1080, "1 s", color="#b91c1c", fontsize=8)
ax.set_xscale("log"); ax.set_yscale("log")
ax.set_xlabel("Lançamentos do usuário (escala log)"); ax.set_ylabel("mediana (ms, escala log)")
ax.set_title("App Flutter (modo debug) — tempo × quantidade de registros")
ax.legend(fontsize=8, frameon=False)
fig.tight_layout(); fig.savefig(os.path.join(EV, "grafico-app-volume.png"), dpi=130)

# 3) Banco compartilhado: usuário com 1.000 lançamentos, banco crescendo
C = ["V2", "C1", "C2"]
rot = ["GET /dashboard", "GET /expenses", "GET /expenses?month=AAAA-MM", "GET /goals"]
fig, ax = plt.subplots(figsize=(8, 4.2))
larg = 0.2
for i, nome in enumerate(rot):
    vals = [rota(c, nome, "mediana") or 0 for c in C]
    pos = [j + (i - 1.5) * larg for j in range(len(C))]
    b = ax.bar(pos, vals, width=larg, color=CORES[i], label=nome)
    ax.bar_label(b, labels=[f"{v:.0f}" for v in vals], fontsize=7, padding=2)
ax.set_xticks(range(len(C)))
ax.set_xticklabels([f"{c}\n{banco[c]['lancamentos_banco']:,} no banco".replace(",", ".") for c in C])
ax.set_ylabel("mediana (ms)")
ax.set_title("Mesmo usuário (1.000 lançamentos), banco com cada vez mais dados de outros")
ax.legend(fontsize=8, frameon=False)
fig.tight_layout(); fig.savefig(os.path.join(EV, "grafico-banco-compartilhado.png"), dpi=130)
print("gráficos gerados")
