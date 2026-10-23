#import "../template.typ": *

= Introdução

== Propósito do incremento

O PictuRAS é uma aplicação _web_ de edição de imagem, oferecida como _Software as a Service_, com três perfis de
utilização (anónimo, registado e premium) e ferramentas básicas e avançadas que se encadeiam numa _pipeline_
aplicada a todas as imagens de um projeto. Esta fase estende a aplicação com *suporte a vídeo digital*, numa
lógica de produto mínimo viável (MVP): o objetivo é validar funcionalmente a manipulação de vídeo dentro da
arquitetura existente, especificando também os requisitos não funcionais, mas sem exigir já o nível de uma
solução em produção.

O incremento tem duas partes. A primeira é transversal: os projetos passam a aceitar vídeos MP4, WebM e MOV ao
lado das imagens, com limites de tamanho e duração por perfil, e a reproduzi-los no editor. A segunda são
*cinco ferramentas de vídeo*, cada uma com o seu caso de uso, escolhidas para cobrir tipos de processamento
diferentes: produzir um novo vídeo a partir de um intervalo temporal (corte), extrair imagens (frames),
alterar o conteúdo dos frames com visão computacional (desfocar caras: deteção a cada 3 frames e desfocagem
de todos), recodificar o vídeo (converter ou
comprimir) e obter texto a partir do áudio (legendas automáticas). Todas usam o mesmo mecanismo: são
ferramentas da _pipeline_, executadas por _workers_ dedicados através do RabbitMQ, com estado, progresso,
cancelamento e quota por vídeo.

== _Baseline_ e repositório

#tabela(
  colunas: (5cm, 1fr),
  [Artefacto], [Versão / referência],
  [Documento de requisitos de base], [doc-ext-requisitos.pdf (PictuRAS, RAS 2025/2026: UC05–UC07, RF39–RF73, RNF43–RNF66)],
  [Documento de solução arquitetural de base], [doc-sol-arquitetural.pdf (RAS 2025/2026, Fase 2; tarefas T-01 a T-11)],
  [Repositório de partida], [#link("https://github.com/picturas-um/picturas-27")[picturas-um/picturas-27], _commit_ `781a63e` (2026-10-07), já com o SeaweedFS no lugar do MinIO],
  [Repositório da equipa], [#link("https://github.com/MarcoAbreu11/PICTURAS")[MarcoAbreu11/PICTURAS], ramo `main`],
  [Solução entregue], [solucao-ext-mvp.zip; commit de referência da solução (código e teste): `e092865fe2387765da1cbc9508facf6ffa5ec101`. O commit documental posterior regenera os artefactos e não se autorreferencia.],
)

Este relatório *estende* os documentos de base: descreve apenas o que muda com o vídeo e refere os elementos de
base pelos seus identificadores (UCnn, RFnn, RNFnn) quando são alterados.

== Resumo do que foi feito

Foram especificadas e implementadas cinco funcionalidades de vídeo (@tab-funcionalidades): legendas automáticas
(UC-VID-001), corte (UC-VID-002), extração de frames (UC-VID-003), desfocagem de caras (UC-VID-004) e conversão
ou compressão (UC-VID-005). Os requisitos comuns às cinco (carregar vídeo, aplicar uma ferramenta de vídeo na
_pipeline_, acompanhar o estado, quota, resultados, segurança e desempenho) foram especificados uma só vez,
com prefixos de área (`SUBMIT`, `PIPE`, `STATUS`, `QUOTA`, `RESULT`, …). Cada requisito está ligado aos
componentes que o realizam e aos testes que o verificam (Capítulo 7). Os testes automáticos (59 testes
unitários no serviço `projects`, 64 nos _workers_ Python e cinco baterias ponta a ponta, ou _end-to-end_ (e2e)) têm resultados históricos no Capítulo 10, separados das verificações reexecutadas na revisão final.

== Organização do documento

- *Parte I: Enquadramento e visão transversal*: introdução, perfis e _stakeholders_ revistos (Capítulo 2) e
  visão geral da extensão de vídeo, com o diagrama de casos de uso, o modelo de domínio e as regras de negócio
  transversais (Capítulo 3).
- *Parte II: Especificação, organizada por artefacto*: os cinco casos de uso (Capítulo 4), a especificação de
  requisitos do sistema (Capítulo 5), o impacto no sistema existente (Capítulo 6) e a rastreabilidade
  (Capítulo 7).
- *Parte III: Arquitetura, IA e validação*: alterações arquiteturais (Capítulo 8), implementação assistida por
  agentes de IA (Capítulo 9), testes (Capítulo 10), manutenção corretiva da solução de base (Capítulo 11) e
  conclusão (Capítulo 12). Os anexos têm as instruções de execução e o glossário.
