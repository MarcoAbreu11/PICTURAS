#import "../template.typ": *

= Visão Geral da Extensão de Vídeo

== Funcionalidades de vídeo do MVP

#tab([Funcionalidades de vídeo do MVP],
  tabela(
    colunas: (1fr, 2cm, 2.6cm, 1.9cm, 3cm, 2.1cm),
    [Funcionalidade], [Caso de uso], [Prefixo(s) REQ], [Perfis], [Dependências], [Estado de implementação],
    [Gerar legendas automáticas (transcrição no idioma original ou tradução para inglês)], [UC-VID-001],
    [REQ-VID-SUB], [Reg., Prem.], [SUBMIT, PIPE, STATUS, QUOTA], [Implementada],
    [Cortar um intervalo temporal de vídeo], [UC-VID-002],
    [REQ-VID-TRIM], [Anón., Reg., Prem.], [SUBMIT, PIPE, STATUS, RESULT], [Implementada],
    [Extrair frames de vídeos como imagens], [UC-VID-003],
    [REQ-VID-FRAME], [Reg., Prem.], [SUBMIT, PIPE, STATUS, QUOTA, RESULT], [Implementada],
    [Desfocar ou pixelizar caras], [UC-VID-004],
    [REQ-VID-BLUR], [Reg., Prem.], [SUBMIT, PIPE, STATUS, QUOTA, RESULT], [Implementada],
    [Converter o formato ou comprimir (resolução, qualidade)], [UC-VID-005],
    [REQ-VID-CONV], [Reg., Prem.], [SUBMIT, PIPE, STATUS, QUOTA, RESULT], [Implementada],
    [Requisitos partilhados: carregar e reproduzir vídeo, ferramenta de vídeo na _pipeline_, estado e
    progresso, quota, resultados, qualidade], [Todos],
    [REQ-VID-SUBMIT, PIPE, STATUS, QUOTA, RESULT, REL, SEC, PERF, PORT, MAINT, COMP, OUTPUT], [Conforme o UC], [—],
    [Implementados (alguns parciais, ver 7.3)],
  ),
) <tab-funcionalidades>

Todas as funcionalidades estão implementadas. Os requisitos ainda parciais ou por medir estão identificados
na tabela de realização (secção 7.3) e no Capítulo 10.

*Justificação no contexto do MVP.* As cinco funcionalidades foram escolhidas para que cada uma valide uma
parte diferente do suporte a vídeo, e todas reutilizem o mesmo mecanismo comum:

- *UC-VID-001 — Gerar legendas automáticas*: é a única que trabalha sobre o *áudio* e cujo resultado é *texto
  associado ao vídeo* (uma faixa WebVTT), em vez de um novo ficheiro de média. Valida inferência de IA pesada
  (modelo de reconhecimento de fala) num _worker_ próprio, com reutilização de resultados e controlo de
  concorrência. Sem ela, o PictuRAS não tornaria acessível o conteúdo falado dos vídeos.
- *UC-VID-002 — Cortar vídeo*: é a operação base de qualquer editor de vídeo, o equivalente ao recorte de
  imagem. Valida uma ferramenta que recebe um vídeo e produz um novo vídeo, com parâmetros temporais (linha
  temporal, instantes) e recodificação. Sendo básica, valida também o vídeo no perfil anónimo.
- *UC-VID-003 — Extrair frames*: foi a primeira ferramenta de vídeo e liga o vídeo às ferramentas de imagem
  existentes (OCR, contagem de pessoas, …). Validou de ponta a ponta o caminho que as restantes reutilizam:
  capacidades por tipo de média, _worker_ via RabbitMQ, progresso, quota por vídeo e vários resultados por
  item.
- *UC-VID-004 — Desfocar caras*: valida processamento *frame a frame com visão computacional*, demorado e
  sujeito à quota, que altera o conteúdo do vídeo e mantém o áudio. Responde a uma necessidade de privacidade
  (RGPD) ao publicar vídeos.
- *UC-VID-005 — Converter ou comprimir*: valida a *recodificação* (formato, resolução, qualidade), a
  diferenciação de perfis pela qualidade de saída e o resultado como novo item da biblioteca. Resolve
  problemas frequentes de compatibilidade e tamanho dos ficheiros.

== Diagrama de casos de uso (atualizado)

#figure(
  image("../images/baseline/diagrama_casos_uso_base.png", width: 70%),
  caption: [Diagrama de casos de uso da solução de base],
)

#figure(
  image("../images/diagrama_casos_uso.png", width: 100%),
  caption: [Diagrama de casos de uso atualizado (Fase 1 — vídeo)],
) <fig-casos-uso>

Os cinco casos de uso de vídeo (a laranja) estendem o caso de uso de base que aplica ferramentas a um projeto
(UC04), porque todas as ferramentas de vídeo são ferramentas da _pipeline_: são adicionadas ao projeto e
executadas ao carregar em "Aplicar". O carregamento de ficheiros é um caso de uso de base *alterado* (passa a
aceitar vídeos, com limites por perfil) e é pré-condição de todos os casos de uso de vídeo. Os atores seguem
as regras de perfil (RNG-04): o *anónimo* acede apenas ao corte; o *registado* acede às cinco ferramentas, e o
*premium* herda tudo o que o registado faz (generalização), sem limite diário. O *convidado por link* com
permissão de edição aplica as ferramentas de vídeo de um projeto partilhado; a conversão é a exceção, porque
o vídeo convertido fica na biblioteca do proprietário e só ele lhe acede (RNG-09). Os casos de uso de base
UC05 a UC07 ficam a cinzento, para contexto.

== Modelo de domínio (atualizado)

#figure(
  image("../images/baseline/modelo_dominio_base.png", width: 85%),
  caption: [Modelo de domínio da solução de base],
)

#figure(
  image("../images/modelo_dominio.png", width: 100%),
  caption: [Modelo de domínio atualizado (Fase 1 — vídeo)],
) <fig-modelo-dominio>

O modelo de base era centrado em `Imagem`. As alterações respondem às questões das diretrizes:

- *Vídeo e Imagem* são especializações de um conceito comum, *Item de Média* (nome, formato, tamanho). Um
  `Vídeo` acrescenta duração, resolução e codecs, que são lidos no carregamento e usados para validar pedidos
  sem reler o ficheiro. Um vídeo pode ser *convertido a partir de* outro vídeo (UC-VID-005).
- Um *Projeto* contém uma *biblioteca* de itens de média que pode misturar imagens e vídeos.
- O processamento é demorado: cada "Aplicar" cria um *Trabalho de Processamento* por item compatível, com
  estado (em fila, em curso, concluído, falhado, cancelado), progresso e causa da falha. O trabalho produz
  *Resultados* (imagens ou vídeos) ou uma *Faixa de Legendas*, que fica associada ao vídeo e não é um novo
  ficheiro de média.
- Uma *Ferramenta aceita* um ou mais *Tipos de Média*. As cinco ferramentas de vídeo aceitam apenas vídeo; as
  ferramentas de imagem não se aplicam a frames diretamente — as imagens extraídas tornam-se itens normais
  quando copiadas para um projeto. O corte é uma ferramenta básica; as outras quatro são avançadas e consomem
  uma operação por item processado.
- As quotas e limites por perfil são representados pelos *Limites de Vídeo do Perfil* (tamanho, duração,
  resolução máxima de saída) e pela *Quota Diária* do registado.

Os termos são os dos casos de uso e da ERS: *biblioteca* (itens do projeto), *resultados* (o que uma
execução da _pipeline_ produz) e *trabalho de processamento*.

== Regras de negócio transversais

#tab([Regras de negócio transversais],
  tabela(
    colunas: (1.4cm, 1fr, 3.6cm, 3cm),
    [ID], [Regra], [Origem / justificação], [Requisitos],
    [RNG-01], [São aceites vídeos MP4, WebM e MOV, carregados isoladamente ou dentro de um `.zip`.],
    [Formatos reproduzíveis nos navegadores atuais (R4) e frequentes em telemóveis (MOV).],
    [SUBMIT-001, COMP-001],
    [RNG-02], [O tamanho e a duração de um vídeo são limitados por perfil no carregamento: anónimo 20 MB / 15 s,
    registado 100 MB / 60 s, premium 500 MB / 10 min.],
    [Custo de processamento e armazenamento; diferenciação de perfis (suporte base a vídeo).],
    [SUBMIT-002],
    [RNG-03], [Cada vídeo processado por uma ferramenta de vídeo *avançada* (extrair frames, desfocar caras,
    converter, legendas) consome uma operação da quota diária do registado, independentemente da duração ou
    do número de imagens geradas. A operação é debitada no pedido e devolvida se o vídeo falhar ou o
    processamento for cancelado: só os sucessos contam. Reutilizar legendas já geradas não consome. O corte é
    básico e não consome.],
    [Reinterpreta "até 5 operações por dia" para vídeo de forma simples e previsível; o débito no pedido
    impede ultrapassar a quota com pedidos simultâneos.],
    [QUOTA-001 a 004, TRIM-049, SUB-006],
    [RNG-04], [O perfil anónimo acede apenas a ferramentas de vídeo básicas (corte); as avançadas exigem sessão
    de registado ou premium, que não tem limite diário.],
    [Regra existente das ferramentas avançadas de imagem.],
    [QUOTA-004, QUOTA-005, TRIM-049],
    [RNG-05], [Uma ferramenta de vídeo nunca altera o vídeo original: gera sempre um novo ficheiro ou uma
    faixa de legendas separada.],
    [Evita perda irreversível de conteúdo.],
    [SEC-001, CONV-036, SUB-003],
    [RNG-06], [No MVP, uma ferramenta de vídeo é a única ferramenta da _pipeline_ do projeto (não se combina
    com outras).],
    [A _pipeline_ é linear e as ferramentas de vídeo produzem tipos de saída diferentes; o encadeamento fica
    para a Fase 2.],
    [PIPE-004],
    [RNG-07], [As ferramentas de vídeo aplicam-se apenas aos vídeos do projeto; as imagens são ignoradas, sem
    custo, e o utilizador é informado.],
    [Capacidades por tipo de média.],
    [PIPE-003, PIPE-005],
    [RNG-08], [Os resultados seguem a regra existente: são substituídos na execução seguinte e eliminados com
    o projeto; para os manter e continuar a editar, copiam-se para um novo projeto. Exceções: o vídeo
    convertido entra na biblioteca e as legendas ficam associadas ao vídeo, ambos até serem eliminados.],
    [Coerência com o comportamento de base; a conversão e as legendas produzem algo que o utilizador quer
    guardar.],
    [RESULT-003, RESULT-004, CONV-006, CONV-033, SUB-003],
    [RNG-09], [Só o dono e as partilhas com permissão de edição adicionam e aplicam ferramentas de vídeo; as
    partilhas de leitura consultam resultados e legendas. Os vídeos convertidos só são acessíveis ao dono.],
    [Permissões de partilha de base (RF45, UC07); a conversão produz conteúdo pessoal do dono.],
    [PIPE-007, SEC-002, CONV-039, SUB-011],
    [RNG-10], [Os ficheiros temporários de processamento são eliminados até 1 h depois do fim do trabalho, com
    sucesso, falha ou cancelamento.],
    [Os vídeos contêm dados pessoais; reduz o custo de armazenamento.],
    [RESULT-005],
  ),
) <tab-rng>

== Convenções de identificação

#tabela(
  colunas: (4.2cm, 1fr),
  [Identificador], [Utilização],
  [UC-VID-nnn], [Caso de uso de vídeo (numeração única no relatório, a partir de UC-VID-001)],
  [REQ-VID-{FUNC}-nnn], [Requisito (funcional ou não funcional). {FUNC} identifica a funcionalidade (SUB,
  TRIM, FRAME, BLUR, CONV) ou a área partilhada (SUBMIT, PIPE, STATUS, QUOTA, RESULT, REL, SEC, PERF, PORT,
  MAINT, COMP, OUTPUT). Os IDs nunca se reutilizam; os requisitos individuais que deram origem a um requisito
  partilhado ficam registados na secção 5.4. Nas tabelas, o prefixo `REQ-VID-` pode ser omitido
  (TRIM-002 = REQ-VID-TRIM-002).],
  [RN#emph[k], A#emph[k], Q#emph[k], FA#emph[k]], [Regra, assunção, questão em aberto e fluxo alternativo de
  um caso de uso (locais ao caso de uso; qualificados, e.g. `UC-VID-002/RN2`, nas tabelas partilhadas)],
  [RNG-nn / DQ-nnn], [Regra de negócio transversal / decisão de qualidade (globais)],
  [DA-nn], [Decisão arquitetural (Capítulo 8)],
  [TST-{FUNC}-nn], [Teste (automático ou manual); TST-{FUNC}-PY e -U são baterias unitárias],
  [T-nn], [Tarefa de manutenção corretiva; continua a numeração do documento de base (T-01 a T-11)],
  [UCnn, RFnn, RNFnn], [Elementos dos documentos de base (referidos quando são alterados — ALT)],
)
