# Diagrama de casos de uso atualizado (Fase 1, vídeo), desenhado à mão em SVG com a disposição do
# diagrama de base: atores à esquerda, casos de uso numa coluna dentro do sistema, linhas retas.
# A laranja: casos de uso novos ou alterados. Gerar (na pasta relatorio):
#   python3 images/src/diagrama_casos_uso.py images/diagrama_casos_uso.svg
import sys

BLUE, NEW = "#7ACFF5", "#FBE3CC"
UC_X, RX, RY = 600, 125, 27
TOP, STEP = 72, 66

# (texto, novo); a ordem define a linha na coluna do sistema
ucs = [
    (["Registo"], False),
    (["Carregar imagens", "e vídeos"], True),
    (["Aplicar encadeamento", "de ferramentas"], False),
    (["Login"], False),
    (["Criar filtro personalizado"], False),
    (["Partilhar projeto"], False),
    (["UC-VID-001", "Gerar legendas automáticas"], True),
    (["UC-VID-002", "Cortar vídeo"], True),
    (["UC-VID-003", "Extrair frames de vídeos"], True),
    (["UC-VID-004", "Desfocar caras de um vídeo"], True),
    (["UC-VID-005", "Converter ou comprimir vídeo"], True),
    (["Assistente IA na edição"], False),
]
row_y = [TOP + i * STEP for i in range(len(ucs))]

# atores: nome -> (x do centro, y do centro da cabeça)
actors = {
    "Anónimo": (230, 120),
    "Utilizador": (230, 420),
    "Utilizador Convidado": (75, 420),
    "Premium": (230, 730),
}
# associações ator -> índices dos casos de uso
assoc = {
    "Anónimo": [0, 1, 2, 7],
    "Utilizador": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    "Premium": [11],
}

out = []
add = out.append


def actor(name, x, y):
    add(f'<circle cx="{x}" cy="{y}" r="11" fill="{BLUE}" stroke="#000"/>')
    add(f'<line x1="{x}" y1="{y + 11}" x2="{x}" y2="{y + 42}" stroke="#000"/>')
    add(f'<line x1="{x - 20}" y1="{y + 22}" x2="{x + 20}" y2="{y + 22}" stroke="#000"/>')
    add(f'<polyline points="{x - 17},{y + 68} {x},{y + 42} {x + 17},{y + 68}" fill="none" stroke="#000"/>')
    add(f'<text x="{x}" y="{y + 86}" text-anchor="middle" font-size="13">{name}</text>')


def usecase(lines, new, y):
    add(f'<ellipse cx="{UC_X}" cy="{y}" rx="{RX}" ry="{RY}" fill="{NEW if new else BLUE}" stroke="#000"/>')
    first = y + 4.5 - (len(lines) - 1) * 7.5
    for i, t in enumerate(lines):
        add(f'<text x="{UC_X}" y="{first + i * 15}" text-anchor="middle" font-size="12.5">{t}</text>')


def line(x1, y1, x2, y2, marker=None, dash=False):
    m = f' marker-end="url(#{marker})"' if marker else ""
    d = ' stroke-dasharray="5,4"' if dash else ""
    add(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="#000"{d}{m}/>')


# sistema
add(f'<rect x="385" y="22" width="430" height="{row_y[-1] + 48 - 22}" fill="#fff" stroke="#000"/>')
add('<text x="600" y="40" text-anchor="middle" font-size="13">Sistema</text>')

# associações (do ombro do ator ao bordo esquerdo da elipse)
for name, idxs in assoc.items():
    ax, ay = actors[name]
    for i in idxs:
        line(ax + 22, ay + 22, UC_X - RX, row_y[i])

# generalizações (triângulo vazio no Utilizador)
ux, uy = actors["Utilizador"]
px, py = actors["Premium"]
cx, cy = actors["Utilizador Convidado"]
line(px, py - 13, ux, uy + 106, "heranca")
line(cx + 24, cy + 22, ux - 24, uy + 22, "heranca")

for lines_, new in ucs:
    usecase(lines_, new, row_y[ucs.index((lines_, new))])
for name, (x, y) in actors.items():
    actor(name, x, y)

# nota solta à direita do sistema, como no diagrama de base
ny = row_y[10] - 46
note = ["O Utilizador Convidado (partilha", "com permissão de edição) herda", "os casos de uso do Utilizador,",
        "exceto converter vídeos, que", "só o dono pode fazer (RNG-09)."]
add(f'<path d="M835,{ny} H1015 L1027,{ny + 12} V{ny + 92} H835 Z" fill="{BLUE}" stroke="#000"/>')
add(f'<path d="M1015,{ny} V{ny + 12} H1027" fill="none" stroke="#000"/>')
for i, t in enumerate(note):
    add(f'<text x="843" y="{ny + 19 + i * 16}" font-size="12">{t}</text>')

H = row_y[-1] + 60
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1040 {H}" width="1040" height="{H}" font-family="Carlito, Calibri, sans-serif">
<defs>
  <marker id="heranca" viewBox="0 0 14 14" refX="14" refY="7" markerWidth="14" markerHeight="14" orient="auto" markerUnits="userSpaceOnUse">
    <path d="M0,0 L14,7 L0,14 Z" fill="#fff" stroke="#000"/>
  </marker>
</defs>
<rect width="1040" height="{H}" fill="#fff"/>
{chr(10).join(out)}
</svg>
'''
open(sys.argv[1], "w").write(svg)
