#import "../template.typ": *

= Alterações Arquiteturais

O padrão de base mantém-se: microserviços com _reverse proxy_ (nginx), API Gateway, comunicação REST entre
serviços de negócio, AMQP (RabbitMQ) para o processamento assíncrono e uma base de dados por serviço. O
suporte a vídeo encaixa neste padrão sem o reestruturar (restrição R7): o processamento de média acontece
apenas em _workers_ novos, e os serviços existentes foram estendidos para validar, orquestrar e apresentar o
vídeo.

== Visão geral das alterações

#figure(
  image("../images/arquitetura_componentes.png", width: 100%),
  caption: [Vista de componentes da solução com suporte a vídeo (novos a laranja, alterados a laranja claro)],
) <fig-componentes>

#tab([Componentes novos e alterados],
  tabela(
    colunas: (3.4cm, 1.6cm, 1fr, 3.2cm),
    tamanho: 8.5pt,
    [Componente / serviço (ID)], [Estado], [Responsabilidade / alteração], [Requisitos],
    [`trim_tool` (W-TRIM)], [Novo], [Corta o excerto com FFmpeg, mantendo o contentor; 5 réplicas.],
    [TRIM-006, 022, 043, 051, COMP-002],
    [`extract_frames_tool` (W-FRAMES)], [Novo], [Extrai frames para PNG/JPEG; vários resultados por vídeo;
    5 réplicas.], [FRAME-006, 009, 010, 023, 047],
    [`blur_faces_tool` (W-BLUR)], [Novo], [Deteta caras com OpenCV (YuNet) e desfoca/pixeliza frame a frame;
    remonta o vídeo com o áudio; pré-visualização de um frame; 5 réplicas.], [BLUR-004, 005, 009, 010, 013, 041, 042],
    [`video_convert_tool` (W-CONV)], [Novo], [Recodifica com FFmpeg (MP4 H.264/AAC ou WebM VP9/Opus),
    verifica duração e áudio do resultado e calcula a estimativa de tamanho por amostras; 5 réplicas.],
    [CONV-003, 005, 015, 017, 024, 046, OUTPUT-001],
    [`video_subtitles_tool` (W-SUB)], [Novo], [Transcreve ou traduz com faster-whisper "small" (CPU, int8);
    publica WebVTT de forma atómica; recibos por trabalho para mensagens repetidas; 1 réplica; modelo no volume
    `whisper_models`.], [SUB-002, 007 a 009, 013, 014, 016, 017],
    [`Tools/utils` (MSG)], [Alterado], [`tool_msg.py`: progresso intermédio, vários resultados por item,
    metadados de resultado e correção do envio de erros; novo `video.py` com o ffprobe, o FFmpeg com progresso e
    a limitação da frequência do progresso, partilhados pelos _workers_ de vídeo.],
    [STATUS-003, 006, 008, MAINT-001],
    [`projects` — regras (P-RULES)], [Alterado], [Tabela de capacidades por tipo de média e de ferramentas
    exclusivas (`toolCapabilities.js`); validação de parâmetros de cada ferramenta de vídeo
    (`trim.js`, `frames.js`, `blurFaces.js`, `videoConvert.js`, `subtitlesTool.js`).],
    [PIPE-003 a 006, TRIM-014, 015, FRAME-013 a 015, BLUR-050, CONV-015, 026, 037],
    [`projects` — rotas (P-ROUTES)], [Alterado], [`/tool`, `/process` (só itens compatíveis, débito por vídeo,
    resposta antes da cópia dos vídeos), `/preview`, resultados (vídeo, frames, tamanhos, descarte),
    `results/project`, estimativa da conversão (pedido-resposta pela fila), vídeo convertido na biblioteca,
    tratamento de progresso e falhas por vídeo.], [PIPE-001, 002, 007, QUOTA-001 a 005, RESULT-001 a 003, STATUS-001, 004, 006, 007, PERF-001, CONV-006, 039],
    [`projects` — carregamento (P-UPLOAD)], [Alterado], [Tipo de média pela extensão, ffprobe e limites por
    perfil; guarda duração, resolução, tamanho e codecs.], [SUBMIT-001 a 004],
    [`projects` — legendas (P-SUBS)], [Novo], [Serviço, rotas e coleção próprios para as faixas: autorização,
    reserva atómica por vídeo, reutilização por _hash_, filas duráveis com confirmação, recuperação e
    eliminação.], [SUB-001, 003, 006, 010 a 012, QUOTA-001, 002],
    [`projects` — temporários (P-TEMP)], [Novo], [Elimina a cópia local depois de cada trabalho e varre a cada
    10 min os ficheiros de vídeo com mais de 50 min sem trabalho ativo.], [RESULT-005],
    [`users` (USERS)], [Mantido], [Reserva e devolução de operações (`/process/:n`, `/process/refund/:n`)
    reutilizadas.], [QUOTA-001 a 004],
    [`img_storage` (ST)], [Alterado], [Extensão do nome original na chave; _stage_ `subtitles` com nome
    determinístico e MIME `text/vtt`; limites de 500 MB.], [SUBMIT-001, SUB-003],
    [`api_gateway` (GW)], [Alterado], [Carregamentos até 500 MB com erro 413 legível; rotas da estimativa da
    conversão, das legendas e do descarte de um resultado.], [SUBMIT-001, CONV-003, BLUR-014, SUB-001],
    [`ws_gateway` (WS)], [Alterado], [Eventos `process-progress` e `process-item-error`.], [STATUS-003, 006],
    [_frontend_ (FE-TOOLS, FE-PAGE, FE-MEDIA)], [Alterado], [Ferramentas de vídeo na barra (linha temporal,
    opções, estimativa, idiomas); progresso e estados "Em fila"/"Em curso"; leitor de vídeo com faixas de
    legendas; grelha com o primeiro frame.], [PIPE-001, STATUS-002, 003, SUB-004, 005, SUBMIT-005, TRIM-002 a 004],
    [Infraestrutura (INFRA)], [Alterado], [`docker-compose.yaml` com os cinco _workers_ e o volume do modelo;
    filas em `rabbitMQ/definitions.json`; nginx com `client_max_body_size 500M` e _timeouts_ de 600 s.],
    [PORT-001, PERF-002],
  ),
) <tab-componentes>

== Decisões arquiteturais

#tab([Decisões arquiteturais],
  tabela(
    colunas: (1.1cm, 2.8cm, 1fr, 3.6cm, 2.2cm),
    tamanho: 8pt,
    [ID], [Decisão], [Contexto e alternativas consideradas], [Consequências], [Requisitos / DQ],
    [DA-01], [Um _worker_ por ferramenta de vídeo], [Alternativa: um serviço de vídeo único com todas as
    operações. Os _workers_ por ferramenta seguem o padrão das ferramentas de imagem e isolam dependências
    muito diferentes (FFmpeg, OpenCV, Whisper).], [Escala e falha por ferramenta; mais contentores; algum código
    comum, que passou para `Tools/utils/video.py`.], [MAINT-001, PERF-002; DQ-001],
    [DA-02], [Processamento assíncrono pelo RabbitMQ], [Alternativa: chamadas HTTP síncronas a um serviço de
    vídeo. Os trabalhos duram de segundos a minutos; uma chamada síncrona prenderia pedidos e ligações.],
    [Exige estado, progresso e tratamento de falhas por mensagem.], [STATUS-001, PERF-001; DQ-001, DQ-011],
    [DA-03], [Capacidades por tipo de média no `projects` e ferramentas de vídeo exclusivas], [Alternativas:
    deixar cada _worker_ recusar o que não sabe processar; ou capacidades `{ accepts, produces }` com
    encadeamento. A tabela simples evita trabalho inútil e quota mal gasta; o encadeamento seria demasiado para
    o MVP.], [Projetos mistos funcionam; não há encadeamento até à Fase 2.], [PIPE-003, PIPE-004; DQ-002, DQ-003],
    [DA-04], [Ficheiros de trabalho no volume partilhado `image_data`; resultados no SeaweedFS], [Alternativa:
    os _workers_ lerem e escreverem diretamente no armazenamento S3. O volume é o mecanismo existente das
    ferramentas; só o `projects` fala com o armazenamento.], [Os temporários têm de ser limpos (P-TEMP); os
    _workers_ precisam do mesmo volume.], [RESULT-005, SEC-002; DQ-007],
    [DA-05], [Progresso por mensagens "progress" encaminhadas para o _browser_ por Socket.IO], [Alternativa:
    _polling_ do _frontend_. Os eventos já existiam para o fim do processamento; o _worker_ envia 0 % ao sair
    da fila e no máximo uma atualização por segundo. As legendas usam _polling_ da faixa, por terem um ciclo
    de vida próprio.], [Atualização ≈ 1 s; o estado só é visível com a página aberta.], [STATUS-002, 003, 008; DQ-010],
    [DA-06], [Confirmar o pedido antes de copiar os vídeos para os _workers_], [Antes, o `/process`
    descarregava e validava cada vídeo antes de responder, o que passava os 2 s com vídeos grandes. Agora valida
    com os metadados guardados no carregamento, responde e copia depois; uma cópia falhada é tratada como falha
    desse vídeo.], [Resposta rápida; erros de cópia chegam como falha por vídeo.], [PERF-001; DQ-011],
    [DA-07], [Estimativa de tamanho calculada no _worker_ por pedido-resposta sobre o RabbitMQ], [Alternativa
    inicial: o `projects` correr o FFmpeg durante o pedido HTTP, o que punha processamento de média num serviço
    web, fora da fila e do limite de trabalhos. Agora o `projects` copia o vídeo para o volume, envia o pedido
    à fila da conversão e espera a resposta (até 50 s, abaixo do _timeout_ do nginx), correlacionada em memória.],
    [O `projects` não processa média; a correlação em memória pressupõe uma só instância do `projects`.],
    [CONV-003, CONV-024; DQ-012, DQ-018],
    [DA-08], [Legendas como serviço com coleção própria e transporte durável], [Alternativa: tratar a faixa
    como um resultado comum. As faixas sobrevivem às execuções, são reutilizadas e exigem uma geração por
    vídeo; a coleção separada evita que as escritas do projeto (que substituem arrays) percam metadados
    concorrentes.], [Mais código próprio; garantias de idempotência e concorrência mais fortes.],
    [SUB-003, 006, 010, 014; DQ-019],
    [DA-09], [Metadados do vídeo lidos com ffprobe no carregamento e guardados], [Alternativa: reler o vídeo
    em cada validação. Guardar permite validar instantes, limites e codecs sem descarregar o ficheiro.],
    [Itens antigos sem metadados são validados pelo _worker_.], [SUBMIT-004, PERF-001; DQ-004],
    [DA-10], [Vídeo convertido acrescentado à biblioteca do projeto], [Alternativa: deixá-lo só nos resultados,
    que são substituídos na execução seguinte. A conversão produz uma versão que o utilizador quer manter.],
    [O item fica marcado como derivado e só o dono lhe acede.], [CONV-006, 033, 039; DQ-018],
    [DA-11], [Versões das imagens base fixadas (Node 22.11, Python 3.11.10, Debian 12)], [Alternativa: imagens
    `latest`, que mudam sem aviso. Fixar a versão do Debian fixa também a série do FFmpeg (5.1).],
    [Instalação reprodutível; atualizações passam a ser explícitas.], [PORT-001; DQ-012],
  ),
) <tab-da>

== Fluxo de processamento de vídeo

#figure(
  image("../images/sequencia_processamento.png", width: 100%),
  caption: [Sequência de processamento de um vídeo entre componentes],
) <fig-sequencia>

O utilizador carrega em "Aplicar" e o _frontend_ envia o pedido ao `api_gateway`, que o reencaminha para o
`projects` com a identidade validada. O `projects` verifica as capacidades e a exclusividade da ferramenta e
valida os parâmetros com os metadados guardados no carregamento; para uma ferramenta avançada, reserva no
`users` uma operação por vídeo. Responde de imediato (≤ 2 s) e só depois copia cada vídeo do armazenamento
para o volume partilhado e publica um pedido na fila da ferramenta. Um _worker_ livre consome o pedido e
envia 0 % (o _frontend_ passa de "Em fila" a "Em curso"); durante o processamento envia o progresso, no
máximo uma vez por segundo, que o `projects` reencaminha para a `ws_queue` e o `ws_gateway` entrega ao
_browser_. No fim, o _worker_ responde com o ficheiro gerado e os metadados; o `projects` guarda o resultado
no armazenamento, regista-o no projeto (ou na biblioteca, na conversão), apaga os ficheiros de trabalho e
notifica o _frontend_. Se o vídeo falhar, o _worker_ remove o ficheiro parcial e envia o código e a causa; o
`projects` devolve a operação e envia uma falha desse vídeo, sem interromper os restantes. Quando todos os
vídeos terminam, o _frontend_ pede os resultados, servidos por ligações assinadas. O cancelamento invalida o
_token_ da execução, devolve as operações e remove os resultados dessa execução; as respostas que cheguem
depois são ignoradas e os seus ficheiros apagados. As legendas seguem o mesmo início (Aplicar), mas o
`projects` delega no serviço de legendas, que usa filas duráveis próprias e confirma cada mensagem só depois
de a tratar.

== Impacto na instalação e execução

- *Novos contentores*: `trim_tool`, `extract_frames_tool`, `blur_faces_tool` e `video_convert_tool` (5
  réplicas cada) e `video_subtitles_tool` (1 réplica). Todos dependem do RabbitMQ e partilham o volume
  `image_data` com o `projects`.
- *Dependências externas*: FFmpeg/ffprobe (série 5.1, do Debian 12) no `projects` e nos _workers_; OpenCV e o
  modelo YuNet (incluído na imagem) na desfocagem; faster-whisper e o modelo "small", descarregado no
  primeiro uso para o volume `whisper_models`.
- *Novas filas*: `trim_queue`, `extract_frames_queue`, `blur_faces_queue`, `video_convert_queue`,
  `video_subtitles_queue` e `video_subtitles_results_queue`.
- *Configuração*: nginx com `client_max_body_size 500M` e _timeouts_ de 600 s; limites de 500 MB no
  gateway e no armazenamento. Não há variáveis de ambiente novas obrigatórias.
- *Recursos*: a desfocagem e as legendas usam CPU de forma intensiva; o modelo de legendas fica carregado em memória
  durante toda a vida do _worker_, daí uma só réplica. Instruções completas no Anexo A.
