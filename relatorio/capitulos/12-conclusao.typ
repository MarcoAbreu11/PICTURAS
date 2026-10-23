#import "../template.typ": *

= Conclusão

*O que o MVP valida.* O PictuRAS passou a tratar o vídeo como um tipo de média de primeira classe: os projetos
misturam imagens e vídeos, com limites por perfil, e cinco ferramentas de vídeo de natureza diferente
funcionam de ponta a ponta sobre um mecanismo comum: temporal (corte), de extração (frames), de visão
computacional (caras), de recodificação (conversão) e de reconhecimento de fala (legendas). Esse mecanismo é a
contribuição mais reutilizável: capacidades por tipo de média, _workers_ dedicados atrás do RabbitMQ, estado e
progresso por vídeo, falha isolada por vídeo e quota por vídeo com devolução. Foi acrescentado sem
reestruturar a arquitetura de base, e cada ferramenta nova entrou sem alterar as anteriores. O ciclo caso de
uso → requisito → componente → teste está fechado para todos os requisitos, com 59 testes unitários no
`projects`, 64 nos _workers_ e 106 verificações ponta a ponta a passar.

*O que ficou por fazer e porquê.* Ficaram parciais o acompanhamento do estado depois de sair da página e as
notificações fora dela, porque exigem persistir o estado dos trabalhos, fora do âmbito do MVP. Ficaram por
medir os tempos com vídeos longos e a taxa de deteção de caras, por falta de tempo e de um conjunto de teste
anotado com consentimento. O encadeamento de ferramentas de vídeo foi adiado deliberadamente: a cópia para um
novo projeto cobre o caso de uso sem mudar o modelo da _pipeline_.

*Lições.* Escrever os casos de uso em paralelo levou a requisitos duplicados e a pequenas incoerências (quota,
biblioteca/resultados, limites), que só a consolidação deste relatório resolveu; numa próxima fase, os
requisitos partilhados devem ser definidos antes dos específicos. Com agentes de IA, os testes automáticos
foram indispensáveis, mas não suficientes: dois defeitos e um desvio de arquitetura só apareceram com teste
manual no navegador e com perguntas explícitas sobre a arquitetura.

*Ligação à Fase 2.* Os requisitos não funcionais que consideramos prioritários para melhoria por
_refactoring_ são:
+ *Fiabilidade*: estado persistente dos trabalhos, confirmação das mensagens só depois de tratadas em todas
  as ferramentas (T-25), religação do `ws_gateway` ao RabbitMQ (T-21) e retoma automática de trabalhos
  falhados (REL-001, alvo de produção).
+ *Eficiência de desempenho*: carregamentos em _streaming_ em vez de memória (T-24), medição e otimização dos
  tempos de processamento e réplicas ajustadas à carga (PERF-002), e correlação da estimativa que suporte
  várias instâncias do `projects`.
