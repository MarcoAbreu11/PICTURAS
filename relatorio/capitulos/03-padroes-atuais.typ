#import "../template.typ": *

= Padrões Arquiteturais Atuais

#orientacao[
  *Origem:* Exercício 6, Bloco 1, secções 2.1 a 2.3 do _template_.

  *Objetivo do capítulo:* identificar o estilo (ou a combinação de estilos) arquitetural que organiza o PictuRAS como um
  todo, o padrão que o processamento de vídeo segue, e como os dois se relacionam. O padrão global é o *ponto de
  partida*: define o contexto e as restrições a que qualquer alternativa terá de responder (capítulo 4).

  *Rigor:* factos citam uma evidência (`EV-nn`, ver a explicação na secção 2.4); o que não tem evidência é uma hipótese
  (`H-nn`). Nunca reutilizem um ID eliminado. Benefícios e desafios classificam-se segundo a ISO/IEC 25010
  (característica e, quando aplicável, subcaracterística).
]

== Padrão global da solução

#orientacao[
  Nomeiem o estilo ou os estilos (e.g., microserviços, orientado a eventos, filas de mensagens) e descrevam-no em poucas
  linhas, com as vossas palavras. Depois, indiquem as *decisões globais* que condicionam o vídeo (e.g., comunicação
  assíncrona por filas, armazenamento partilhado) e o efeito que têm. Fechem com os benefícios e desafios do padrão,
  cada um ligado a um atributo de qualidade.
]

#tabela-campos(
  [Nome(s) do padrão / estilo], [Microserviços + Arquitetura orientada a mensagens (*Message-Driven / Pub-Sub* via RabbitMQ) com _API Gateway_ e _Reverse Proxy_],
  [Descrição], [A aplicação divide-se em serviços independentes (`users`, `subscriptions`, `projects`, `img_storage`, `ws_gateway` e um _worker_ Python por ferramenta) atrás de um `nginx` e de um `api_gateway` que valida o JWT. Os pedidos de processamento são assíncronos através da _exchange_ direta `picturas` no RabbitMQ, com partilha de ficheiros em disco através do volume `image_data`.],
)

#tab([Decisões globais que condicionam o vídeo],
  tabela(
    colunas: (4.5cm, 2.6cm, 1fr),
    [Decisão global], [Evidência], [Efeito no vídeo],
    [Entrada única por `nginx` → `api_gateway` → `projects` → `img_storage`], [EV-09: `nginx/nginx.conf:1-40`], [Todos os uploads de vídeo atravessam 4 saltos síncronos HTTP antes de chegar ao S3; sem _streaming_, cada salto amplifica o uso de RAM],
    [Comunicação assíncrona por RabbitMQ e volume partilhado `image_data`], [EV-06: `docker-compose.yaml:77-272`], [Permite desacoplar o pedido HTTP do processamento longo de vídeo e evitar passar o ficheiro na fila],
    [Pipeline definido ao nível do projeto, não por ficheiro], [EV-02], [Obrigou a criar regras de compatibilidade entre ferramentas exclusivas de vídeo e projetos com imagens],
  ),
)

#tab([Benefícios e desafios do padrão global],
  tabela(
    colunas: (2cm, 1fr, 4.2cm, 2.4cm),
    tamanho: 8.5pt,
    [Tipo], [Descrição], [Característica / subcaracterística (ISO/IEC 25010)], [Facto / hipótese],
    [Benefício], [Serviços independentes por domínio e por ferramenta facilitam a evolução isolada de cada componente], [Manutenibilidade / modularidade], [EV-06],
    [Desafio], [Cadeia HTTP síncrona de 4 saltos no upload sem _streaming_ nem controlo de contrapressão esgota a memória com ficheiros grandes], [Eficiência de desempenho / utilização de recursos], [EV-11 a EV-16],
  ),
)

== Padrão do processamento de vídeo

#orientacao[
  Identifiquem o padrão que organiza o processamento de vídeo (que pode coincidir com o global ou ser diferente) e
  contrastem-no com o caminho de imagens. Se o padrão do vídeo for diferente do global, expliquem porquê e que custos
  isso traz. Indiquem benefícios e desafios, com o mesmo critério da secção anterior.
]

#tabela-campos(
  [Nome do padrão], [_Worker_ monolítico por tarefa (*Batch Pipeline* / *Pipes and Filters* interno em processo único)],
  [Descrição], [Ao contrário das imagens (que encadeiam mensagens por ferramenta), um vídeo é enviado numa única mensagem para `video_queue` com toda a lista de efeitos. O `video_tool` descodifica o vídeo uma vez com `ffmpeg`, aplica os filtros em sequência por fotograma em memória e codifica uma única vez para MP4/AAC.],
  [Contraste com o caminho de imagens], [As imagens seguem coreografia passo-a-passo (`projects` → `<tool>_queue` → `project_queue` por cada ferramenta); o vídeo concentra todos os efeitos num único _worker_ (`video_tool`) para evitar múltiplas descodificações e recodificações com perda de qualidade e latência elevada.],
)

#tab([Benefícios e desafios do padrão do vídeo],
  tabela(
    colunas: (2cm, 1fr, 4.2cm, 2.4cm),
    tamanho: 8.5pt,
    [Tipo], [Descrição], [Característica / subcaracterística (ISO/IEC 25010)], [Facto / hipótese],
    [Benefício], [Uma única descodificação e codificação por vídeo reduz drasticamente o tempo de CPU e evita degradação sucessiva; _ack_ apenas no fim evita perda silenciosa], [Eficiência de desempenho / comportamento temporal; Fiabilidade / tolerância a falhas], [EV-03, EV-05],
    [Desafio], [Instância única de `video_tool` sem réplicas cria fila em carga concorrente e os efeitos PIL estão duplicados face às ferramentas de imagem], [Eficiência de desempenho / capacidade; Manutenibilidade / reutilização], [EV-07: `docker-compose.yaml:256-272`; EV-08: `Tools/video/effects.py`],
  ),
)

== Relação entre o padrão global e o padrão do vídeo

#orientacao[
  Esta secção responde a: em que pontos o vídeo *segue* o padrão global, em que pontos se *afasta* dele e com que
  consequências? Cada linha da tabela é um aspeto concreto (e.g., comunicação entre serviços, gestão de estado,
  tratamento de falhas, armazenamento). É aqui que costumam surgir as fragilidades que alimentam os cenários de
  qualidade do capítulo 5, por isso escrevam as consequências com cuidado e com evidência.

  Terminem com um parágrafo de síntese: o que o vídeo herda do padrão global, que restrições este lhe impõe e que
  fragilidades resultam do desvio.
]

#tab([Relação entre o padrão global e o padrão do vídeo],
  tabela(
    colunas: (2.4cm, 3cm, 3cm, 1.9cm, 2.6cm, 1.8cm),
    tamanho: 8pt,
    [Aspeto], [O que o padrão global prescreve], [O que o vídeo faz], [Segue / afasta-se], [Consequência], [Evidência],
    [Carregamento de ficheiros], [Upload HTTP através de `nginx` → `api_gateway` → `projects` → `img_storage`], [Usa exatamente o mesmo caminho síncrono em memória], [Segue], [Vídeos até 1 GB esgotam a RAM dos serviços e falham por OOM], [EV-01, EV-11 a EV-16],
    [Orquestração do _pipeline_], [Um microserviço por ferramenta, encadeado por `projects` via RabbitMQ], [Envia todo o _pipeline_ numa só mensagem para `video_tool`], [Afasta-se], [Evita recodificações, mas duplica efeitos PIL e concentra carga num só _worker_], [EV-03, EV-07, EV-08],
    [Regras de composição], [Pipeline único ao nível do projeto], [Ferramentas de vídeo (`trim`, `speed`, `subtitles`, `extract_frames`) misturam-se com projetos de imagem], [Segue], [Sem fonte única nem avisos antecipados, o utilizador só descobre erros no _Apply_], [EV-02, EV-10: `projects/utils/video.js`],
  ),
)

O vídeo herda do padrão global a fronteira de entrada (`nginx` + `api_gateway` + `projects` + `img_storage`), a
comunicação assíncrona por RabbitMQ e o modelo de _pipeline_ único por projeto. As restrições impostas por esta herança
explicam as duas maiores fragilidades observadas: o carregamento em memória colapsa com ficheiros de vídeo grandes e a
mistura de regras entre imagens e vídeos num _pipeline_ partilhado gera erros tardios na interface.
