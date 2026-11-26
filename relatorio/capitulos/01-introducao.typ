#import "../template.typ": *

= Introdução

#orientacao[
  Uma a duas páginas, no máximo. O leitor deve perceber, sem ler o resto, o que é este documento e em que se baseia.
  Respondam a:
  - *Propósito da fase*: que requisitos não funcionais do PictuRAS se pretende melhorar, por _refactoring_ e sem novas
    funcionalidades, e porquê.
  - *_Baseline_*: em que versão do sistema se basearam (_commit_ de partida), a mesma em todos os exercícios. Este
    relatório *estende* os documentos de base; não os reescreve.
  - *Âmbito do que é apresentado*: este relatório reúne os contributos dos Exercícios 6 (Blocos 1 e 2) e 7. Reutiliza
    os respetivos _templates_: copiem o conteúdo já preenchido, *mantendo os IDs* (`EV`, `H`, `ALT`, `QS`, `CAND`,
    `TAT`, `DA`), porque é através deles que os capítulos se encadeiam.
  - *Organização do documento*: Partes II (diagnóstico), III (qualidade), IV (táticas, decisões, medição e resultados)
    e V (síntese).
]

== Propósito e âmbito

A Fase 2 melhora, por _refactoring_ e sem acrescentar funcionalidades, dois requisitos não funcionais do PictuRAS,
classificados segundo a ISO/IEC 25010:2011:

- *CAND-1 — Eficiência de desempenho (utilização de recursos) no carregamento de ficheiros.* Na base, cada vídeo (até
  1 GB no perfil premium) é guardado inteiro em memória em cada serviço que atravessa, o que faz falhar os ficheiros
  grandes e não dá ao utilizador nenhuma indicação de progresso.
- *CAND-2 — Usabilidade (proteção contra erros do utilizador) na criação de pipelines.* Na base, num projeto com
  imagens e vídeos algumas ferramentas desaparecem sem explicação, e um pipeline inválido só é detetado quando o
  utilizador pede a pré-visualização ou executa o processamento.

Os dois requisitos tocam a extensão de vídeo, mas a partir do padrão global: o primeiro está no caminho de
carregamento comum a imagens e vídeos (nginx, `api_gateway`, `projects`, `img_storage`); o segundo nas regras de
composição do pipeline, que pertencem ao projeto e não a cada _media_. A restrição de toda a fase é preservar o
comportamento funcional: as alterações visíveis (barra de progresso, avisos do editor) são o próprio objeto da melhoria.

== _Baseline_ e repositório
#tab([Artefactos de partida],
  tabela(
    colunas: (5cm, 1fr),
    [Artefacto], [Versão / referência],
    [Documento de requisitos de base], [doc-ext-requisitos-2627.pdf],
    [Documento de solução arquitetural de base], [doc-sol-arquitetural.pdf #preencher[versão]],
    [Repositório de partida], [`https://github.com/picturas-um/picturas-27`, _commit_ `052310226c51fa57a17101c7bd1ad795674aac95` (`0523102`, 2026-11-04)],
    [Repositório entregue], [`https://github.com/MarcoAbreu11/PICTURAS`, ramo `main`, último _commit_ à data de entrega],
    [Diretrizes da Fase 2], [Versão 1, 4 de novembro de 2026],
  ),
)

== Exercícios e versões usadas

#orientacao[
  Indiquem, para cada exercício, a versão do enunciado e do _template_ que usaram, e a versão do vosso documento que
  serviu de entrada ao exercício seguinte (Bloco 1 → Bloco 2 → Exercício 7). Isto garante que quem avalia consegue
  perceber a que regras o trabalho respondeu, caso os enunciados tenham sido atualizados durante a fase.
]

#tab([Exercícios que alimentam este relatório],
  tabela(
    colunas: (3.6cm, 2.2cm, 2cm, 2cm, 1fr),
    [Exercício], [Capítulos], [Enunciado], [Template], [Versão do documento da equipa],
    [Exercício 6, Bloco 1: padrões arquiteturais], [2, 3 e 4], [#preencher[1.1]], [#preencher[1.1]], [#preencher[v1.0]],
    [Exercício 6, Bloco 2: trade-offs, cenários e candidatos a RNF], [5 e 6], [#preencher[1.2]], [#preencher[1.2]], [#preencher[v1.0]],
    [Exercício 7: táticas arquiteturais], [7 a 10], [#preencher[3.0]], [#preencher[3.0]], [#preencher[v1.0]],
  ),
)

== Organização do documento

A Parte II (capítulos 2 a 4) descreve a arquitetura da base, os seus padrões e as alternativas, com cada afirmação
apoiada numa evidência (`EV-nn`) ou assumida como hipótese (`H-nn`). A Parte III (capítulos 5 e 6) deriva os cenários de
qualidade (`QS-nn`) das fragilidades encontradas e escolhe os dois candidatos (`CAND-1`, `CAND-2`), com a sua
quantificação. A Parte IV (capítulos 7 a 10) parte desses cenários para as táticas (`TAT-nn`), regista as decisões
(`DA-1`, `DA-2`), mostra a arquitetura antes e depois e apresenta as medições da base e da versão final e os testes de
regressão. A Parte V (capítulos 11 e 12) fecha com as conclusões e com a utilização de IA. Os IDs encadeiam os
capítulos: `EV`/`H` → `ALT` → `QS`/`CAND` → `TAT` → `DA`.
