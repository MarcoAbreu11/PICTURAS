# Modelo de domínio atualizado (Fase 1 — vídeo), desenhado à mão em SVG com a disposição do modelo de base.
# Gerar (na pasta relatorio): python3 images/src/modelo_dominio.py images/modelo_dominio.svg
import sys

W, H = 110, 34  # caixa de classe
BLUE, NEW = "#7ACFF5", "#FBE3CC"

classes = {
    # nome: (x, y, novo)
    "Gratuito": (40, 10, False),
    "Premium": (40, 125, False),
    "Anónimo": (40, 200, False),
    "Utilizador": (250, 115, False),
    "Preset": (420, 40, False),
    "Projeto": (420, 115, False),
    "Imagem": (420, 200, False),
    "Vídeo": (420, 270, True),
    "Legenda": (420, 345, True),
    "Básica": (760, 10, False),
    "Sugestão IA": (840, 70, False),
    "Ferramenta": (620, 115, False),
    "Avançada": (700, 190, False),
    "Assistente IA": (860, 190, False),
}

out = []
add = out.append


def box(name, x, y, new):
    add(f'<rect x="{x}" y="{y}" width="{W}" height="{H}" fill="{NEW if new else BLUE}" stroke="#000" stroke-width="1"/>')
    add(f'<line x1="{x}" y1="{y + 18}" x2="{x + W}" y2="{y + 18}" stroke="#000" stroke-width="1"/>')
    add(f'<text x="{x + W / 2}" y="{y + 13.5}" text-anchor="middle" font-weight="bold" font-size="12">{name}</text>')


def path(pts, end="arrow", dash=False):
    d = " ".join(f"{x},{y}" for x, y in pts)
    marker = {"arrow": "url(#seta)", "gen": "url(#heranca)"}[end]
    add(f'<polyline points="{d}" fill="none" stroke="#000" stroke-width="1" marker-end="{marker}"/>')


def label(x, y, t, anchor="start"):
    add(f'<text x="{x}" y="{y}" font-size="11" text-anchor="{anchor}">{t}</text>')


# generalizações ("é")
path([(150, 27), (290, 27), (290, 115)], "gen"); label(215, 22, "é")
path([(150, 140), (250, 140)], "gen"); label(195, 135, "é"); label(240, 135, "1", "end")
path([(150, 217), (300, 217), (300, 149)], "gen"); label(215, 212, "é")
path([(820, 44), (820, 125), (730, 125)], "gen"); label(800, 120, "é")
path([(765, 190), (765, 140), (730, 140)], "gen"); label(775, 160, "é")
path([(860, 207), (810, 207)], "gen"); label(835, 202, "é")

# Utilizador
path([(250, 122), (230, 122), (230, 75), (270, 75), (270, 115)]); label(250, 70, "convida", "middle"); label(262, 108, "0..*", "end")
path([(320, 115), (320, 27), (760, 27)]); label(560, 22, "aplica", "middle"); label(755, 40, "0..*", "end"); label(325, 105, "0..*")
path([(360, 122), (390, 122), (390, 57), (420, 57)]); label(395, 92, "cria"); label(365, 117, "1"); label(415, 70, "0..*", "end")
path([(360, 136), (420, 136)]); label(390, 131, "gere", "middle"); label(365, 148, "1..*"); label(415, 148, "0..*", "end")
path([(330, 149), (330, 224), (420, 224)]); label(375, 219, "upload", "middle"); label(335, 162, "1..*"); label(415, 237, "0..*", "end")
path([(315, 149), (315, 287), (420, 287)]); label(375, 282, "upload", "middle"); label(415, 300, "0..*", "end")
path([(40, 142), (25, 142), (25, 400), (765, 400), (765, 224)]); label(395, 395, "aplica", "middle"); label(22, 155, "0..*", "end"); label(770, 240, "0..*")

# Projeto
path([(475, 115), (475, 87), (840, 87)]); label(660, 82, "recebe", "middle"); label(480, 110, "1"); label(835, 100, "0..*", "end")
path([(530, 132), (620, 132)]); label(575, 127, "usa", "middle"); label(535, 127, "0..*"); label(615, 145, "0..*", "end")
path([(475, 149), (475, 200)]); label(470, 178, "contém", "end"); label(480, 160, "1"); label(480, 195, "0..*")
path([(530, 142), (555, 142), (555, 280), (530, 280)]); label(560, 182, "contém"); label(535, 277, "0..*"); label(535, 155, "1")

# Preset, Ferramenta, Assistente IA
path([(530, 57), (660, 57), (660, 115)]); label(600, 52, "contém", "middle"); label(535, 52, "0..1"); label(665, 108, "1..*")
path([(650, 149), (650, 217), (530, 217)]); label(600, 212, "altera", "middle"); label(645, 162, "0..*", "end"); label(535, 230, "0..*")
path([(685, 149), (685, 295), (530, 295)]); label(600, 290, "altera", "middle"); label(690, 162, "0..*"); label(535, 308, "0..*")
path([(915, 190), (915, 104)]); label(920, 150, "produz"); label(920, 185, "1"); label(920, 117, "0..*")

# Vídeo
path([(475, 234), (475, 270)]); label(480, 256, "extraída de"); label(470, 247, "0..*", "end"); label(470, 267, "0..1", "end")
path([(475, 304), (475, 345)]); label(480, 328, "tem"); label(470, 317, "1", "end"); label(470, 342, "0..2", "end")

for n, (x, y, new) in classes.items():
    box(n, x, y, new)

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="-10 0 1000 410" width="1000" height="410" font-family="Carlito, Calibri, sans-serif">
<defs>
  <marker id="seta" viewBox="0 0 10 10" refX="10" refY="5" markerWidth="9" markerHeight="9" orient="auto" markerUnits="userSpaceOnUse">
    <path d="M0,0 L10,5 L0,10" fill="none" stroke="#000" stroke-width="1"/>
  </marker>
  <marker id="heranca" viewBox="0 0 12 12" refX="12" refY="6" markerWidth="12" markerHeight="12" orient="auto" markerUnits="userSpaceOnUse">
    <path d="M0,0 L12,6 L0,12 Z" fill="#fff" stroke="#000" stroke-width="1"/>
  </marker>
</defs>
<rect x="-10" width="1000" height="410" fill="#fff"/>
{chr(10).join(out)}
</svg>
'''
open(sys.argv[1], "w").write(svg)
