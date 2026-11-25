#import "../template.typ": *

= Vista Arquitetural Antes e Depois

#orientacao[
  *Origem:* Exercício 7, secção 4 do _template_.

  Duas vistas do mesmo diagrama: *antes* e *depois* das decisões. Usem o tipo de diagrama que melhor mostrar a alteração
  (componentes, implantação ou sequência). Destaquem os elementos ou as interações introduzidos ou alterados pelas
  táticas (com um estereótipo `«tática: …»` ou uma cor) e incluam uma *legenda*.

  As duas vistas devem ser comparáveis: mesma notação, mesma escala e os mesmos elementos de contexto, de modo a que a
  diferença se perceba a olho. A legenda e as notas explicam o que mudou entre elas e porquê.
]

As duas vistas são diagramas de componentes com a mesma disposição: em cima, o caminho de carregamento de um ficheiro
(CAND-1, DA-1); em baixo, os componentes que intervêm na composição do pipeline (CAND-2, DA-2). Ferramenta: SVG gerado
por um _script_ Python da equipa, com a mesma escala nas duas vistas.

== Antes

#figure(kind: image,
  image("../images/vista_antes.svg", width: 92%),
  caption: [Vista arquitetural antes das decisões DA-1 e DA-2],
)

== Depois

#figure(kind: image,
  image("../images/vista_depois.svg", width: 92%),
  caption: [Vista arquitetural depois das decisões DA-1 e DA-2],
)

== Legenda e notas

#tab([Legenda das vistas],
  tabela(
    colunas: (5cm, 1fr),
    [Elemento], [Significado],
    [Caixa cinzenta, contorno fino], [Componente sem alterações relevantes para os dois RNF],
    [Caixa e texto a laranja], [Componente ou interação alterados pelas decisões (táticas TAT-01, TAT-02, TAT-06 a TAT-08)],
    [Caixa a laranja com contorno tracejado], [Módulo novo (`projects/utils/pipelineRules.js`)],
    [Seta a laranja no caminho de carregamento], [Os _bytes_ passam pelo salto à medida que chegam (_stream_), sem o ficheiro inteiro em memória],
  ),
)

*DA-1.* Os componentes do caminho são os mesmos; muda a forma como cada salto trata o corpo do pedido. O nginx deixa
de o guardar antes de o enviar; o `api_gateway` verifica o JWT antes de ler o corpo e encaminha o próprio pedido; o
`projects` verifica o perfil e o `Content-Length` antes de ler, escreve o ficheiro num temporário e calcula o SHA-256 na
mesma passagem (a validação com `ffprobe` corre sobre esse ficheiro, antes de guardar); o `img_storage` envia ao S3 por
partes. A barra de progresso no _browser_ só é fiel porque o nginx deixou de fazer _buffering_.

*DA-2.* Aparece um módulo novo no `projects`, que passa a ser a única fonte das regras de compatibilidade (usando as
listas de `video.js`). As rotas de ferramentas, de leitura do projeto, de pré-visualização e de execução usam-no; o
editor deixa de ter regras próprias de compatibilidade e mostra os problemas e as ferramentas indisponíveis que o
`projects` devolve. As ferramentas indisponíveis continuam escondidas, agora com uma nota que explica porquê.
