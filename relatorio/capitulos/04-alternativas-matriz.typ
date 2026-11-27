#import "../template.typ": *

= Alternativas e Matriz de Comparação

#orientacao[
  *Origem:* Exercício 6, Bloco 1, secção 3 do _template_.

  *Objetivo do capítulo:* comparar o padrão atual com alternativas relevantes *para o processamento de vídeo*, de forma
  fundamentada, e concluir se o padrão atual é adequado. Entre duas e três alternativas. O padrão global é o contexto da
  comparação: indiquem sempre se cada alternativa o *mantém* ou o *altera*.

  *Restrição da fase:* é de _refactoring_. As alternativas têm de preservar o comportamento funcional; por isso, o
  custo e o risco de migração têm de ser analisados para cada uma. Consultem os slides da aula 11 e o documento de apoio
  de padrões arquiteturais; se for relevante, incluam uma alternativa ao próprio padrão global como termo de comparação.
]

== Alternativas consideradas

#tab([Alternativas consideradas],
  tabela(
    colunas: (1.6cm, 3.4cm, 1fr, 3cm, 2.4cm),
    tamanho: 8.5pt,
    [ID], [Nome / padrão], [Descrição breve], [Mantém ou altera o padrão global?], [Fonte],
    [ALT-1], [Microserviços por filtro de vídeo (coreografia por passo)], [Dividir o `video_tool` em _workers_ separados por efeito (à semelhança das ferramentas de imagem), trocando ficheiros intermédios via `image_data`], [Mantém o padrão global], [Slides Aula 11 (_Message-Driven_)],
    [ALT-2], [Upload direto ao S3 por URL pré-assinado (_Claim-Check_)], [O cliente carrega o vídeo diretamente para o SeaweedFS/S3 com um URL pré-assinado e envia apenas a referência ao `projects`], [Altera parcialmente o padrão global], [Padrão _Claim-Check_ / doc. apoio],
    [ALT-3], [_Streaming_ em _pipes_ com validação antecipada + réplicas de `video_tool`], [Manter o `video_tool` único por tarefa e o caminho HTTP atual, mas com _streaming_ em _buffers_ limitados nos 4 saltos e réplicas horizontais], [Mantém o padrão global], [Slides Aula 11 (_Pipes and Filters_)],
  ),
)

== Análise de cada alternativa

#orientacao[
  Copiem o bloco abaixo para cada alternativa. Para cada uma, descrevam a coerência com o padrão global, o efeito nos
  atributos de qualidade, as vantagens, as desvantagens ou riscos, e o custo e risco de migração. Evitem listas
  genéricas: cada ponto deve referir algo concreto da solução do PictuRAS (e citar evidência `EV-nn` ou hipótese `H-nn`).
]

*ALT-1 — Microserviços por filtro de vídeo (coreografia por passo)*

#tabela-campos(
  [Coerência com o padrão global], [Total: replica exatamente o modelo das ferramentas de imagem (`Tools/<tool>/` + `<tool>_queue`, EV-06).],
  [Efeito nos atributos de qualidade], [Degrada fortemente o comportamento temporal (várias descodificações/codificações por vídeo) e a utilização de disco em `image_data`; melhora ligeiramente a modularidade.],
  [Vantagens potenciais], [Uniformiza a orquestração entre imagens e vídeos em `projects` e elimina a duplicação de efeitos PIL em `Tools/video/effects.py` (EV-08).],
  [Desvantagens ou riscos], [Recodificar H.264/AAC em cada passo degrada a qualidade do vídeo e multiplica o tempo de processamento por um fator de N passos.],
  [Custo e risco de migração (a funcionalidade existente tem de ser preservada)], [Alto: obriga a partir `Tools/video/` em múltiplos serviços e filas e a reescrever a orquestração de vídeo em `projects`.],
)

*ALT-2 — Upload direto ao S3 por URL pré-assinado (_Claim-Check_)*

#tabela-campos(
  [Coerência com o padrão global], [Afasta-se parcialmente: contorna `api_gateway` e `projects` na transferência do ficheiro, expondo o S3 diretamente ao _browser_.],
  [Efeito nos atributos de qualidade], [Elimina o consumo de RAM no upload em `api_gateway`, `projects` e `img_storage` (EV-11 a EV-13), mas exige validação assíncrona após o upload.],
  [Vantagens potenciais], [Escalabilidade máxima no carregamento de vídeos grandes (até 1 GB) sem sobrecarregar os serviços Node.js.],
  [Desvantagens ou riscos], [A validação (`ffprobe`, codec, duração, limites por perfil em EV-01) passaria a correr sobre um objeto já guardado no S3, exigindo limpeza de órfãos e configuração CORS/políticas por utilizador.],
  [Custo e risco de migração], [Alto: altera o contrato da API de upload, o _frontend_ e o fluxo de validação síncrona.],
)

*ALT-3 — _Streaming_ em _pipes_ com validação antecipada + réplicas de `video_tool`*

#tabela-campos(
  [Coerência com o padrão global], [Total: preserva todos os serviços, rotas, filas RabbitMQ e o `video_tool`, com os efeitos convencionais em passagem única (EV-03, EV-09).],
  [Efeito nos atributos de qualidade], [Resolve o esgotamento de RAM no upload mantendo a validação antes de guardar no S3; permite escalar o processamento de vídeo com réplicas.],
  [Vantagens potenciais], [Preserva integralmente o contrato da API e a experiência do utilizador, permitindo ainda progresso real no carregamento.],
  [Desvantagens ou riscos], [Exige tratamento cuidadoso de _backpressure_ e limpeza de temporários em 4 serviços (`nginx`, `api_gateway`, `projects`, `img_storage`).],
  [Custo e risco de migração], [Médio e localizado: altera apenas o transporte do corpo HTTP no upload sem mexer na arquitetura global nem no formato das mensagens.],
)

== Matriz de comparação de padrões

#orientacao[
  Atribuam um nível a cada atributo para o padrão global (referência), para o padrão atual do vídeo e para cada
  alternativa. A escala é à vossa escolha (e.g., Alto / Médio / Baixo) e deve ser a mesma em toda a matriz.

  *Justifiquem cada célula* com evidência da solução (`EV-nn` ou `H-nn`) numa frase curta, logo na própria célula: as
  avaliações sem fundamento não são valorizadas. A matriz inclui o padrão global como referência para se ver o que
  cada alternativa ganha ou perde em relação a ele. Os atributos e subcaracterísticas seguem a ISO/IEC 25010; podem
  acrescentar linhas para outros atributos relevantes.
]

#tab([Matriz de comparação de padrões],
  tabela(
    colunas: (4fr, 3.4fr, 3.4fr, 3.4fr, 3.4fr, 3.4fr),
    tamanho: 7.5pt,
    [Atributo de qualidade (ISO/IEC 25010)], [Padrão global atual (referência)], [Padrão atual do vídeo], [ALT-1 (coreografia por filtro)], [ALT-2 (URL pré-assinado)], [ALT-3 (_streaming_ + réplicas)],
    [Relação com o padrão global], [—], [Afasta-se na orquestração (EV-03)], [Mantém (EV-06)], [Altera parcialmente: o ficheiro deixa de passar pelo `api_gateway` e pelo `projects` (EV-01, EV-09)], [Mantém (EV-03, EV-09)],
    [Eficiência de desempenho: comportamento temporal], [Médio — filas assíncronas, uma mensagem por passo (EV-06)], [Alto — uma descodificação e uma codificação para os efeitos convencionais (EV-03)], [Baixo — uma recodificação por filtro, N por vídeo (EV-03, EV-08)], [Alto no carregamento, sem saltos intermédios (EV-09); processamento igual ao atual (EV-03)], [Alto — mantém a passagem única (EV-03)],
    [Eficiência de desempenho: capacidade / elasticidade], [Médio — um contentor por ferramenta, sem réplicas nem ajuste à carga (EV-06)], [Baixo — instância única do `video_tool` (EV-07)], [Médio — cada filtro escala à parte, mas multiplica mensagens e ficheiros intermédios (EV-06)], [Médio — o carregamento deixa de limitar, o processamento continua num só _worker_ (EV-07)], [Alto — réplicas do `video_tool` a consumir a mesma fila (EV-07)],
    [Eficiência de desempenho: utilização de recursos], [Baixo — upload inteiro em RAM (EV-11 a EV-13)], [Baixo — herda o upload em RAM (EV-16)], [Baixo — um ficheiro intermédio por passo no `image_data` (EV-06)], [Alto — nenhum serviço Node toca nos _bytes_ (EV-11 a EV-13 deixam de se aplicar)], [Alto — _buffers_ limitados em vez de `memoryStorage` (EV-11 a EV-13)],
    [Fiabilidade: tolerância a falhas / recuperabilidade], [Médio — as ferramentas de imagem confirmam a mensagem ao recebê-la, ao contrário do vídeo (EV-05)], [Alto — _ack_ apenas no fim (EV-05)], [Médio — uma falha a meio deixa ficheiros intermédios entre passos (EV-06)], [Médio — um envio interrompido deixa objetos órfãos no S3, a limpar à parte (EV-01)], [Alto — mantém o _ack_ no fim (EV-05)],
    [Manutenibilidade: modularidade / modificabilidade], [Alto — serviços isolados por domínio e por ferramenta (EV-06)], [Médio — efeitos PIL duplicados (EV-08)], [Alto — reutiliza as ferramentas de imagem (EV-08)], [Médio — a validação passa a um passo assíncrono, com fluxo novo no _frontend_ e no `projects` (EV-01)], [Médio — mantém o `video_tool` e a duplicação (EV-08)],
    [Segurança], [Médio — token verificado depois de receber o ficheiro (EV-14)], [Médio — herda do gateway (EV-14)], [Médio — igual ao global (EV-14)], [Baixo — S3 exposto ao _browser_, com CORS e políticas por utilizador (EV-09)], [Alto — token validado antes de ler o corpo (EV-14)],
    [Usabilidade: operabilidade], [Baixo — erros tardios no _Apply_ (EV-18)], [Baixo — ferramentas escondidas sem aviso (EV-17)], [Baixo — não resolve as regras de composição (EV-17, EV-18)], [Médio — progresso nativo do envio, mas as recusas só chegam depois de guardar (EV-01)], [Médio/Alto — progresso real e combinável com uma fonte única de regras (EV-17, EV-18)],
  ),
)

== Adequação do padrão atual

O padrão global de microserviços com RabbitMQ e o padrão do `video_tool` (efeitos convencionais em passagem única) são *adequados na sua
estrutura base*: desacoplam o processamento pesado do pedido HTTP e evitam recodificações sucessivas (EV-03, EV-05).
As fragilidades observadas não exigem substituir o padrão global (como faria ALT-2) nem partir o `video_tool` (ALT-1, que
degradaria o desempenho e a qualidade de vídeo). O caminho mais adequado numa fase de _refactoring_ é manter a
arquitetura atual (alinhado com ALT-3) e corrigir os dois pontos de rutura identificados: o carregamento em memória nos
quatro saltos HTTP e a ausência de validação antecipada e fonte única de regras na composição do _pipeline_.
