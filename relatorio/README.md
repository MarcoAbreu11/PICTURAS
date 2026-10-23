# PictuRAS · RAS 2026/2027 · Relatório da Fase 1 (suporte a vídeo), grupo 5

Fontes Typst do documento de extensão de requisitos (`doc-ext-requisitos.pdf`).

## Compilar

Requer o [Typst](https://typst.app) 0.14 (CLI). A fonte usada é a Carlito (licença OFL), incluída em `fonts/`.

```bash
typst compile --font-path fonts main.typ doc-ext-requisitos.pdf
```

## Estrutura

```
main.typ             capa, índices e ordem dos capítulos
template.typ         estilos e componentes (tabelas, caixas, prioridades)
cover.typ            capa
capitulos/           capítulos (Partes I, II e III) e anexos
casos-uso/           UC-VID-001 a UC-VID-005 (incluídos no capítulo 4)
images/              figuras do relatório
images/baseline/     diagramas da solução de base (casos de uso e modelo de domínio)
images/src/          fontes dos diagramas
```

## Diagramas

| Figura | Ficheiro | Fonte | Gerar (na pasta `relatorio`) |
|---|---|---|---|
| Casos de uso | `images/diagrama_casos_uso.svg` | `images/src/diagrama_casos_uso.py` | `python3 images/src/diagrama_casos_uso.py images/diagrama_casos_uso.svg` |
| Modelo de domínio | `images/modelo_dominio.svg` | `images/src/modelo_dominio.py` | `python3 images/src/modelo_dominio.py images/modelo_dominio.svg` |
| Componentes | `images/arquitetura_componentes.png` | `images/src/arquitetura_componentes.puml` | ver abaixo |
| Sequência | `images/sequencia_processamento.png` | `images/src/sequencia_processamento.puml` | ver abaixo |

Os diagramas PlantUML partilham o estilo `images/src/estilo-vp.iuml` e geram-se com:

```bash
docker run --rm -v "$PWD":/w -v "$PWD/fonts":/usr/share/fonts/carlito:ro -w /w plantuml/plantuml:1.2024.7 \
  -tpng -Sdpi=200 images/src/arquitetura_componentes.puml images/src/sequencia_processamento.puml -o ..
```
