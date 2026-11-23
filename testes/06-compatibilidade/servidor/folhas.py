"""Monta as "folhas de contato" (todas as telas de um perfil lado a lado, com a
marca ✔/✘ de cada uma) e a tabela-resumo em Markdown.
Uso: python folhas.py <pasta-evidencias>
"""
import json
import os
import sys
from collections import OrderedDict

from PIL import Image, ImageDraw, ImageFont

EV = sys.argv[1]
res = json.load(open(os.path.join(EV, "resultados.json"), encoding="utf-8"))
perfis = OrderedDict()
for r in res:
    perfis.setdefault(r["perfil"], []).append(r)

try:
    fonte = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 15)
    fonte_b = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 18)
except OSError:
    fonte = fonte_b = ImageFont.load_default()

os.makedirs(os.path.join(EV, "folhas"), exist_ok=True)
for pid, linhas in perfis.items():
    alvo_h = 520  # altura de cada miniatura
    ims = []
    for r in linhas:
        p = os.path.join(EV, r["captura"])
        if os.path.exists(p):
            im = Image.open(p).convert("RGB")
            esc = alvo_h / im.height
            ims.append((r, im.resize((max(1, int(im.width * esc)), alvo_h))))
    if not ims:
        continue
    larg_max = 1900
    linhas_img, atual, x = [], [], 0
    for r, im in ims:
        if x + im.width + 12 > larg_max and atual:
            linhas_img.append(atual)
            atual, x = [], 0
        atual.append((r, im))
        x += im.width + 12
    linhas_img.append(atual)
    W = min(larg_max, max(sum(im.width + 12 for _, im in l) for l in linhas_img)) + 12
    H = 50 + len(linhas_img) * (alvo_h + 40)
    folha = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(folha)
    r0 = linhas[0]
    d.text((12, 12), f"{pid} — {r0['aparelho']}  ({int(r0['largura'])}×{int(r0['altura'])} dp · {r0['plataforma']}"
           f" · fonte {int(r0['fonte'] * 100)}%{' · escuro' if r0['escuro'] else ''}{' · teclado aberto' if r0['teclado'] else ''})",
           fill="black", font=fonte_b)
    y = 50
    for l in linhas_img:
        x = 12
        for r, im in l:
            ok = r["ok"]
            d.text((x, y), f"{'OK' if ok else 'FALHA'} · {r['nome_tela']}", fill="#15803d" if ok else "#b91c1c", font=fonte)
            folha.paste(im, (x, y + 24))
            d.rectangle([x - 1, y + 23, x + im.width, y + 24 + alvo_h], outline="#15803d" if ok else "#b91c1c", width=2)
            x += im.width + 12
        y += alvo_h + 40
    folha.save(os.path.join(EV, "folhas", f"{pid}.png"))

# Resumo em Markdown
out = ["| Perfil | Aparelho | Tamanho (dp) | Plataforma | Telas OK | Problemas |", "|---|---|---|---|---:|---|"]
for pid, linhas in perfis.items():
    r0 = linhas[0]
    ok = sum(1 for r in linhas if r["ok"])
    probs = []
    for r in linhas:
        if not r["ok"]:
            itens = r["erros"] + ([] if r["acao_principal"] == "tocável" else [f"ação principal {r['acao_principal']}"])
            probs.append(f"**{r['nome_tela']}**: " + "; ".join(sorted(set(itens))))
    out.append(f"| [{pid}](folhas/{pid}.png) | {r0['aparelho']} | {int(r0['largura'])}×{int(r0['altura'])} | {r0['plataforma']} | "
               f"{'✅' if ok == len(linhas) else '❌'} {ok}/{len(linhas)} | {'<br>'.join(probs) or '—'} |")
open(os.path.join(EV, "resultados.md"), "w", encoding="utf-8").write("\n".join(out) + "\n")
print(f"{len(perfis)} folhas geradas")
