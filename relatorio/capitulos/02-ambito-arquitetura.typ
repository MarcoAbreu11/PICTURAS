#import "../template.typ": *

= Âmbito e Vista da Arquitetura

#orientacao[
  *Origem:* Exercício 6, Bloco 1, secções 0 e 1 do _template_ (preparação, fontes, vista global e sequência).

  *Objetivo do capítulo:* situar o leitor. Mostra como a solução foi lançada, em que fontes se baseia a análise e como é
  a arquitetura da solução de base, com o caminho do vídeo em destaque. É a base factual dos capítulos seguintes.

  *Foco:* a *extensão de vídeo, enquadrada no padrão global* da solução. Não analisem o vídeo isoladamente: o que o vídeo
  faz só se percebe à luz do que a solução faz como um todo.

  *Rigor:* cada afirmação sobre o sistema atual cita uma evidência (`EV-nn`) ou é assumida como hipótese (`H-nn`). A
  secção 2.4 explica como se escreve uma evidência.
]

== Preparação e ambiente

#orientacao[
  Registem como a solução foi lançada, para que outra pessoa a consiga repetir e obtenha o mesmo resultado. Indiquem
  sempre o _commit_ de partida (o mesmo em todos os capítulos), os comandos exatos e o ambiente de execução. Se algum
  passo falhou ou exigiu um ajuste, escrevam-no: é informação útil para quem repetir o processo.

  A descrição do processamento em lote que se segue à tabela deve ser escrita pela equipa, com palavras próprias, e
  mostrar que perceberam o fluxo completo, do _Apply_ ao resultado, para imagens e vídeos.
]

#tab([Preparação e ambiente],
  tabela-campos(
    [Commit de partida], [`052310226c51fa57a17101c7bd1ad795674aac95` (`0523102`)],
    [Comando(s) de arranque], [`docker compose up -d --build` (e `docker compose -f docker-compose.yaml -f bench/upload/compose.memlimit.yaml up -d` nas medições de memória)],
    [Ambiente (SO, CPU, RAM, versões de Docker e Compose)], [Ubuntu 26.04.1 (WSL2), Intel Core Ultra 7 356H (16 CPU lógicos), 15,4 GiB RAM, Docker Engine 29.9.2, Docker Compose v5.6.1],
  ),
)

*Como é orquestrado o processamento em lote de imagens e de vídeos* (5 a 8 linhas):

O utilizador carrega imagens (`POST /:user/:project/img`) ou vídeos (`POST /:user/:project/video`), que são validados e
guardados no `img_storage` (SeaweedFS/S3) com `media_type` distinto (`"image"` ou `"video"`). O _pipeline_ de efeitos
pertence ao projeto, não a cada ficheiro. Quando o utilizador carrega em _Apply_ (`POST /:user/:project/process`), o
serviço `projects` percorre os ficheiros do projeto: para cada *imagem*, envia uma mensagem por passo para a fila da
respetiva ferramenta (`<tool>_queue`) e avança a cadeia quando recebe resposta em `project_queue`; para cada *vídeo*,
envia uma *única* mensagem para `video_queue` com todo o _pipeline_, que o `video_tool` descodifica uma vez com
`ffmpeg`, aplica os efeitos por fotograma em PIL, preserva o áudio e codifica uma única vez para MP4 (H.264 + AAC),
reportando o progresso em `ws_queue`.

== Fontes consultadas

#orientacao[
  Listem os documentos e o código que sustentam a análise, com a versão ou a data de cada um (_commit_, número de versão,
  data de acesso) e para que foram usados. Isto permite ao leitor perceber de onde vêm as afirmações e detetar
  fontes desatualizadas. Incluam os documentos de apoio da unidade curricular que influenciaram a análise.
]

#tab([Fontes consultadas],
  tabela(
    colunas: (5.5cm, 3cm, 1fr),
    [Fonte], [Versão / data], [Usada para],
    [`README.md`, `AGENTS.md`], [_commit_ `0523102`], [Visão global da arquitetura, convenções, limites e fluxos de imagem e vídeo],
    [`doc-ext-requisitos-2627.pdf`], [2026/2027], [Requisitos funcionais e regras de negócio da extensão de vídeo (`RN2`, `REQ-VID-*`)],
    [`doc-sol-arquitetural.pdf`], [Base Fase 1], [Referência da arquitetura inicial de microserviços e filas RabbitMQ],
    [Slides da aula 11 (_Arch. Styles_) e documento de apoio de padrões arquiteturais], [2026/2027], [Classificação dos estilos arquiteturais e critérios de comparação],
    [Código-fonte (`docker-compose.yaml`, `nginx/`, `apiGateway/`, `projects/`, `imageStorageService/`, `Tools/video/`)], [_commit_ `0523102`], [Recolha de evidências verificáveis (`EV-01` a `EV-20`)],
  ),
)

== Vista da arquitetura global

#orientacao[
  A vista mostra o *padrão global* da solução (serviços, filas, armazenamento, fronteiras) com o *caminho do vídeo
  destacado*, de modo a que se veja onde o vídeo segue o resto do sistema e onde se afasta dele.

  Usem a notação e a ferramenta que preferirem (C4 de contentores, componentes UML, PlantUML, Mermaid, draw.io), mas
  incluam sempre uma *legenda* e indiquem a ferramenta. O diagrama tem de ser legível no documento impresso e
  consistente com o que foi observado na solução em execução, não apenas com a documentação.
]

#figure(kind: image,
  image("../images/arquitetura_global.svg", width: 100%),
  caption: [Vista da arquitetura global com o caminho do vídeo destacado],
)

*Ferramenta / notação:* diagrama de contentores ao estilo C4, desenhado em SVG (`relatorio/images/arquitetura_global.svg`), com a mesma notação das vistas antes/depois do capítulo 9.

#tab([Legenda da vista da arquitetura],
  tabela(
    colunas: (5cm, 1fr),
    [Elemento (cor, forma ou estilo)], [Significado],
    [Seta contínua (destaque)], [Caminho do vídeo: `nginx` → `api_gateway` → `projects` → `img_storage` (upload) e `projects` → `video_queue` → `video_tool` → `project_queue` / `ws_queue`],
    [Seta tracejada], [Caminho das ferramentas de imagem (`<tool>_queue` passo a passo)],
    [Seta cinzenta fina], [Outras interações (_frontend_, autenticação e quota, estado em MongoDB, volume partilhado)],
    [Cilindro / armazenamento], [MongoDB (estado por serviço), SeaweedFS/S3 (`img_storage`) e volume partilhado `image_data`],
  ),
)

== Sequência de um pedido completo

#orientacao[
  Descrevam, passo a passo, o que acontece num pedido completo para um projeto com vídeos: carregamento → definição do
  _pipeline_ → _Apply_ → progresso → resultado. O diagrama de sequência mostra a ordem das interações; a tabela
  identifica, para cada passo, quem fala com quem e através de que mensagem, _endpoint_ ou fila.

  *O que é uma evidência (`EV-nn`).* Uma evidência é a referência *verificável* que sustenta uma afirmação sobre o
  sistema atual. Deve permitir que outra pessoa, no _commit_ de partida, confirme o que afirmam sem ter de adivinhar.
  Pode ser:
  - *código*, com ficheiro e linhas (e.g., `video.py:8-9`);
  - *configuração*, com ficheiro e linha (e.g., `docker-compose.yml`, definição de uma fila ou de um volume);
  - *mensagem* observada (e.g., conteúdo de uma mensagem na fila, resposta de um _endpoint_);
  - *medição* ou *registo de execução*, com o comando usado e o resultado;
  - *documento*, com a secção (e.g., `doc-sol-arquitetural.pdf`, secção 3).

  Regras: o ID é sequencial (`EV-01`, `EV-02`, …), único, e nunca se reutiliza. Como o relatório não tem um registo
  separado, *descrevam a evidência no sítio onde a usam pela primeira vez* (formato: `EV-nn`: localização — o que
  mostra); nas ocorrências seguintes basta o ID. Uma afirmação sem evidência não é um facto: marquem-na como
  *hipótese* (`H-nn`) e indiquem como a confirmar ou refutar.
]

#figure(kind: image,
  image("../images/sequencia_pedido.svg", width: 100%),
  caption: [Sequência do processamento em lote de um projeto com vídeos],
)

*Ferramenta / notação:* diagrama de sequência UML simplificado, desenhado em SVG (`relatorio/images/sequencia_pedido.svg`). Setas contínuas são pedidos e mensagens; setas tracejadas são respostas ao _browser_.

#tab([Passos do pedido completo],
  tabela(
    colunas: (3cm, 3.6cm, 1fr, 3.4cm),
    [Passo], [Origem → Destino], [Mensagem / _endpoint_ / fila], [Evidência],
    [Carregamento do vídeo], [_Browser_ → `nginx` → `api_gateway` → `projects` → `img_storage`], [`POST /api-gateway/projects/:user/:project/video`; valida com `ffprobe` e limites do perfil e guarda com `media_type: "video"`], [EV-01: `projects/routes/projects.js` (`POST /:user/:project/video`) — validação e registo de vídeo],
    [Definição do _pipeline_], [_Browser_ → `api_gateway` → `projects`], [`POST/PUT` de ferramentas no projeto; guarda a lista ordenada `tools` no documento do projeto], [EV-02: `projects/routes/projects.js:1397-1480` — gestão do array `tools`],
    [_Apply_], [`projects` → RabbitMQ (`video_queue`) → `video_tool`], [Uma mensagem única com o vídeo e todo o _pipeline_; `video_tool` lê/escreve no volume `image_data`], [EV-03: `projects/routes/projects.js` (`POST /:user/:project/process`) e `Tools/video/video.py:25-27`],
    [Progresso], [`video_tool` → `ws_queue` → `ws_gateway` → _Browser_], [Eventos `video-progress` com percentagem enviados para `ws_queue` e reencaminhados via Socket.IO], [EV-04: `Tools/video/video.py:25-27` e `wsGateway/index.js`],
    [Resultado], [`video_tool` → `project_queue` → `projects` → `img_storage`], [Resposta final em `project_queue` com _ack_ apenas no fim; resultado guardado no S3 e associado ao projeto], [EV-05: `Tools/video/video.py:8-10` — _ack_ apenas após conclusão],
  ),
)
