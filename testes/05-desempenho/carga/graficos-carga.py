"""Gráficos do teste de carga (10, 50 e 100 usuários). Uso: python graficos-carga.py <pasta-evidencias>"""
import json
import os
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

EV = sys.argv[1]
U = [10, 50, 100]
R = {u: json.load(open(os.path.join(EV, f"carga-{u}-usuarios.json"), encoding="utf-8")) for u in U}
AZUL, LARANJA, VERDE, CINZA = "#2a62d8", "#e0703f", "#2a9d6f", "#6b7280"
plt.rcParams.update({"font.size": 11, "axes.spines.top": False, "axes.spines.right": False})


def salvar(fig, nome):
    fig.tight_layout()
    fig.savefig(os.path.join(EV, nome), dpi=150)
    plt.close(fig)


# 1) Tempo médio e p95 por número de usuários
fig, ax = plt.subplots(figsize=(7, 4))
media = [R[u]["geral"]["media_ms"] for u in U]
p95 = [R[u]["geral"]["p95_ms"] for u in U]
ax.plot(U, media, marker="o", color=AZUL, label="Tempo médio")
ax.plot(U, p95, marker="o", color=LARANJA, label="p95 (95% das requisições)")
for x, y in zip(U, media):
    ax.annotate(f"{y:.0f} ms", (x, y), textcoords="offset points", xytext=(0, -16), ha="center", color=AZUL, fontsize=10)
for x, y in zip(U, p95):
    ax.annotate(f"{y:.0f} ms", (x, y), textcoords="offset points", xytext=(0, 8), ha="center", color=LARANJA, fontsize=10)
ax.axhline(500, color="#b91c1c", ls="--", lw=1)
ax.text(12, 520, "meta de leitura: 500 ms", color="#b91c1c", fontsize=9)
ax.set_xticks(U)
ax.set_xlabel("Usuários simultâneos")
ax.set_ylabel("Tempo de resposta (ms)")
ax.set_title("Tempo de resposta × usuários simultâneos")
ax.legend(frameon=False)
salvar(fig, "grafico-tempo.png")

# 2) Throughput real × demanda (cada usuário pede ~6 req por ciclo de ~1 s)
fig, ax = plt.subplots(figsize=(7, 4))
thr = [R[u]["geral"]["throughput_rps"] for u in U]
demanda = [u * 6 / 1.0 for u in U]
ax.bar([str(u) for u in U], thr, color=AZUL, width=0.5, label="Throughput medido")
ax.plot([str(u) for u in U], demanda, marker="o", color=CINZA, ls="--", label="Demanda se não houvesse fila (≈ 6 req/s por usuário)")
for i, v in enumerate(thr):
    ax.text(i, v + 8, f"{v:.0f} req/s", ha="center", fontsize=10)
ax.set_xlabel("Usuários simultâneos")
ax.set_ylabel("Requisições por segundo")
ax.set_title("Throughput: a API satura em ~130 req/s")
ax.legend(frameon=False, fontsize=9)
salvar(fig, "grafico-throughput.png")

# 3) Tempo médio por rota
rotas = ["GET /goals", "GET /incomes", "DELETE /expenses/:id", "GET /expenses", "GET /dashboard", "POST /expenses"]
fig, ax = plt.subplots(figsize=(7.5, 4.2))
larg = 0.26
for k, (u, cor) in enumerate(zip(U, [VERDE, AZUL, LARANJA])):
    vals = [R[u]["por_rota"][r]["media_ms"] for r in rotas]
    pos = [i + (k - 1) * larg for i in range(len(rotas))]
    ax.barh(pos, vals, height=larg, color=cor, label=f"{u} usuários")
ax.set_yticks(range(len(rotas)))
ax.set_yticklabels(rotas)
ax.invert_yaxis()
ax.set_xlabel("Tempo médio (ms)")
ax.set_title("Tempo médio por rota")
ax.legend(frameon=False, loc="upper center", bbox_to_anchor=(0.5, -0.16), ncol=3)
salvar(fig, "grafico-rotas.png")

# 4) Requisições e falhas
fig, ax = plt.subplots(figsize=(7, 3.4))
reqs = [R[u]["geral"]["requisicoes"] for u in U]
falhas = [R[u]["geral"]["falhas"] for u in U]
ax.bar([str(u) for u in U], reqs, color=AZUL, width=0.5, label="Requisições concluídas")
ax.bar([str(u) for u in U], falhas, color="#b91c1c", width=0.5, label="Falhas")
for i, (v, f) in enumerate(zip(reqs, falhas)):
    ax.text(i, v + 120, f"{v:,} req · {f} falhas".replace(",", "."), ha="center", fontsize=10)
ax.set_ylim(0, max(reqs) * 1.18)
ax.set_xlabel("Usuários simultâneos")
ax.set_ylabel("Requisições em 60 s")
ax.set_title("Volume atendido e falhas")
ax.legend(frameon=False, loc="upper left")
salvar(fig, "grafico-falhas.png")
print("ok")
