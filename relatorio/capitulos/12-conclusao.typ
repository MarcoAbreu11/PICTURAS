#import "../template.typ": *

= Conclusão

*O que o MVP valida.* O PictuRAS passou a tratar o vídeo como um tipo de média de primeira classe: os projetos
misturam imagens e vídeos, com limites por perfil, e cinco ferramentas de vídeo de natureza diferente
funcionam de ponta a ponta sobre um mecanismo comum: temporal (corte), de extração (frames), de visão
computacional (caras), de recodificação (conversão) e de reconhecimento de fala (legendas). Esse mecanismo é a
contribuição mais reutilizável: capacidades por tipo de média, _workers_ dedicados atrás do RabbitMQ, estado e
progresso por vídeo, falha isolada por vídeo e quota por vídeo com devolução. Foi acrescentado sem
reestruturar a arquitetura de base, e cada ferramenta nova entrou como um _worker_ próprio, registado nas
capacidades. A rastreabilidade distingue validação realizada e parcial: TRIM-004, TRIM-009/010/013,
H.265 (COMP-001) e RESULT-004 mantêm validação parcial. PERF-002 (carga) e BLUR-023 (taxa de deteção)
não foram medidos. A bateria automática completa foi reexecutada na versão final (2026-10-23: 59/59, 64/64
e 104 verificações ponta a ponta sem falhas); os testes de deteção de caras e de fala, a inferência real e os
testes manuais ficam com os resultados históricos do Capítulo 10.
A auditoria final encontrou dois defeitos nas legendas, corrigidos (D-07 e D-08), e três defeitos que ficam
registados para a Fase 2 (D-09 a D-11): dois herdados do código de base (o parâmetro `owner` no `api_gateway`
e a reserva de quota não atómica no `users`) e o seletor de faixas nas partilhas só de leitura; por isso
PIPE-007 e SUB-011 ficam parciais.

*O que ficou por fazer e porquê.* Ficaram parciais o acompanhamento do estado depois de sair da página e as
notificações fora dela, porque exigem persistir o estado dos trabalhos, fora do âmbito do MVP. Ficou por
medir a taxa de deteção de caras, por falta de um conjunto de teste anotado com consentimento. O encadeamento de ferramentas de vídeo foi adiado deliberadamente: a cópia para um
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
