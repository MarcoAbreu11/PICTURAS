#import "../template.typ": *

= Testes e Validação do MVP

== Estratégia e ambiente de testes

Os critérios de aceitação da ERS são a base dos testes, organizados em quatro níveis:

- *Unitários do `projects`* (`node --test`, em `projects/test/`): regras de cada ferramenta, capacidades e
  exclusividade, limpeza de temporários e o serviço de legendas, este último contra a MongoDB do próprio
  `projects` (o `projects_mongoDB` do `docker compose`, indicado em `SUBTITLES_TEST_MONGO`), numa base de dados
  temporária criada e apagada pelo teste, sem tocar nos dados da aplicação.
- *Unitários dos _workers_* (`python -m unittest`, em cada pasta de `Tools/`): validação, nomes, argumentos do
  FFmpeg, codecs por contentor, regras da estimativa e o módulo partilhado `Tools/utils/video.py`, este com
  FFmpeg real.
- *Ponta a ponta*, ou _end-to-end_ (e2e) (`bash projects/test/e2e/run.sh`): com a stack a correr em `docker compose`, cria
  utilizadores de teste, carrega vídeos, aplica cada ferramenta pela API diretamente no projects (sem browser/gateway) e verifica resultados, quota e
  mensagens; os ficheiros gerados são inspecionados com `ffprobe`.
- *Manuais e inspeção*: utilização no navegador, logs do `ws_gateway` e medições de tempo.

*Ambiente*: Linux com Docker (WSL2) e Fedora com Podman (CLI compatível com Docker); imagens
`node:22.11.0-bookworm` e `python:3.11.10-slim-bookworm`. Os testes de interface usam um navegador
automático (Chromium com Playwright), que não descodifica H.264: nesses testes os vídeos da desfocagem são
WebM (VP9), formato que a ferramenta mantém.
*Vídeos de teste*, gerados pelo próprio script com FFmpeg (sem material de terceiros): `aula.mp4` (10 s,
320×240, H.264/AAC, com tom de áudio), `curto.mp4` (3 s, 640×360, H.264, sem áudio), seis cópias de
`curto.mp4` para esgotar a quota e `foto.png`. Os testes de deteção de caras e de fala precisam de um vídeo
real com pessoas a falar, indicado em `BLUR_FACE_VIDEO`; por privacidade, nenhum é guardado no repositório.
A inferência real das legendas usa uma amostra de fala humana portuguesa do conjunto Google FLEURS (CC BY
4.0), descarregada só nesse teste.

== Testes realizados

As datas seguintes são as dos registos históricos, quando disponíveis. Nesta revisão de 2026-10-23: Node E4 6 passam, 1 integração Mongo ignorada por falta de serviço; Python E4 15/15; Compose config válido. O teste TST-SUB-CHR passou em Edge/Chromium com API simulada, painel e mutação de processamento reais: configuração e Save sem geração, Apply, English primeiro, idioma antes da faixa Original, cues WebVTT, desativação e reutilização. Não cobre sockets da página completa nem ativação automática pós-Apply. TypeScript passou. Mongo foi tentado explicitamente: ligação recusada em 27018. E2E foi tentado: falhou no arranque por indisponibilidade do motor Docker. Cada linha indica a data da execução registada. As execuções de 2026-10-20 e posteriores foram feitas para este
relatório; as mais recentes (2026-10-23) são as dos testes unitários do `projects` e da bateria ponta a ponta da
conversão, repetidas na versão entregue. As restantes estão registadas nos documentos de cada caso de uso.

#tab([Testes e resultados],
  tabela(
    colunas: (2.4cm, 1.6cm, 1fr, 3cm, 2.2cm),
    tamanho: 8pt,
    [ID], [Tipo], [Descrição (Dado… Quando… Então…)], [Requisito(s)], [Resultado],
    [TST-SUBMIT-01], [Inspeção], [Dado um vídeo de 2 s gerado com FFmpeg e um ficheiro falso, quando passam
    pela validação do carregamento, então o vídeo fica com 2 s e 320×240 e o falso é recusado.],
    [SUBMIT-002 a 004], [Passa (2026-10-17)],
    [TST-SUBMIT-M1], [Manual], [Dado uma conta registada, quando carrega um vídeo de 14 s, então aparece na
    grelha e reproduz no carrossel.], [SUBMIT-001, 005], [Passa (2026-10-17)],
    [TST-SUB-P1 a P3], [Unitário], [Opções aceites (`original`, `en`), só vídeos, sem combinação.],
    [SUB-001, PIPE-003, 004], [3/3 (2026-10-20)],
    [TST-SUB-U], [Integração (MongoDB)], [Ciclo de vida das faixas: autorização, ambas as ordens de geração,
    equivalência inglesa, reutilização, 12 pedidos concorrentes, falhas e devolução, eliminação durante o
    carregamento, respostas duplicadas.], [SUB-003, 006, 007, 010 a 012, QUOTA-002, SEC-002],
    [26/26 (2026-10-20)],
    [TST-SUB-PY], [Unitário], [Validação do pedido, WebVTT (tempos, escape), escrita atómica, sem áudio
    (2303), sem fala (2304).], [SUB-008, 009, 015], [15/15 (2026-10-20)],
    [TST-SUB-01 a 07, 09, 11], [Ponta a ponta], [Dado idiomas inválidos, combinação com o corte, pré-visualização
    e um vídeo sem fala, quando se configura e aplica, então as recusas, o erro 2304, a devolução da operação
    e a recusa do anónimo ocorrem.], [SUB-001, 009, PIPE-002 a 004, QUOTA-002, 005], [10/10 (2026-10-20)],
    [TST-SUB-08, 10], [Ponta a ponta], [Dado um vídeo com fala, quando aplica duas vezes, então fica com a faixa
    e a segunda vez não gasta quota.], [SUB-002, SUB-006], [Ignorado sem vídeo com fala],
    [TST-SUB-INF], [Integração], [Dado fala portuguesa e inglesa, quando se gera Original e English, então a
    transcrição e a tradução são produzidas, `pt` é detetado, o _hash_ do vídeo mantém-se; sem áudio dá 2303
    e um tom sem fala dá 2304.], [SUB-002, 003, 007 a 009, SEC-001], [Histórico: passa segundo o autor; data de execução não registada; não reexecutado em 2026-10-23],
    [TST-SUB-CHR], [Integração (Chromium)], [Dado o leitor real com API simulada, então a faixa gerada fica
    selecionada é mostrada, desativar e reutilizar não geram nova faixa, os _cues_ carregam e English primeiro revela o idioma original.],
    [SUB-004, 015, 018], [Passa (2026-10-23, Edge/Chromium, API simulada); ativação automática SUB-005 não coberta],
    [TST-SUB-TR], [Integração (RabbitMQ)], [Dado a mesma mensagem duas vezes, então o _worker_ devolve o mesmo
    recibo sem nova inferência.], [SUB-014], [Histórico: passa segundo o autor; data de execução não registada; não reexecutado em 2026-10-23],
    [TST-TRIM-01 a 06], [Unitário], [Intervalo válido, início ≥ fim, excerto curto, parâmetros em falta, fim
    além da duração, capacidades e exclusividade.], [TRIM-003, 014, 015, 034, PIPE-003, 004], [6/6 (2026-10-20)],
    [TST-TRIM-PY], [Unitário], [Validação, nome, codecs por contentor e argumentos do FFmpeg.],
    [TRIM-015, 034, 051, COMP-002], [8/8 (2026-10-20)],
    [TST-TRIM-07 a 13, 15], [Ponta a ponta], [Dado 2 vídeos e 1 imagem, quando se valida e aplica o corte 1–2,5 s,
    então recusas corretas, 2 vídeos cortados com o intervalo no nome, 1 ignorado, quota inalterada, cópia
    para novo projeto e corte pelo anónimo.], [TRIM-006, 014, 015, 034, 049, 051, PIPE-001 a 005, RESULT-001, 003], [23/23 (2026-10-20)],
    [TST-TRIM-14], [Inspeção (`ffprobe`)], [Dado o corte 1–2,5 s de um MP4, então dura 1,500 s com H.264/AAC.],
    [TRIM-022, COMP-002, RESULT-002], [Passa (2026-10-20)],
    [TST-TRIM-16], [Inspeção], [Dado um corte em curso, então o progresso chega ao `ws_gateway` a cada ≈ 1 s.],
    [STATUS-003, 008], [Passa (2026-10-18)],
    [TST-TRIM-M1], [Manual], [Corte no navegador com a linha temporal.], [TRIM-002, 003, PIPE-001], [Passa (2026-10-18)],
    [TST-FRAME-01 a 10], [Unitário], [Instantes, limite de 100, instante além do fim, parâmetros, capacidades
    e exclusividade.], [FRAME-002, 003, 006, 009, 013 a 015, PIPE-003 a 005], [10/10 (2026-10-20)],
    [TST-FRAME-PY], [Unitário], [Instantes, validação e nomes no _worker_.], [FRAME-009, 013, 014, 036], [8/8 (2026-10-20)],
    [TST-FRAME-11 a 18], [Ponta a ponta], [Dado 2 vídeos e 1 imagem, então duração guardada, 7 frames com o
    instante no nome, 2 operações debitadas, recusas, cópia e brilho nas imagens copiadas, falha isolada com
    1 operação devolvida e recusa do anónimo.], [SUBMIT-004, FRAME-007, 008, 013 a 015, 022, 036, 049, QUOTA-001, 002, 005, STATUS-007, REL-001], [23/23 (2026-10-20)],
    [TST-FRAME-19, 20], [Inspeção], [Frame com a resolução do vídeo; progresso e erros com causa no
    `ws_gateway`.], [FRAME-023, STATUS-003, 006], [Passa (2026-10-18)],
    [TST-FRAME-M1], [Manual], [Extração de MP4 e MOV no navegador; WebM pela API.], [PIPE-001, COMP-001], [Passa (2026-10-18)],
    [TST-BLUR-U1 a U4], [Unitário], [Opções, opções inválidas, capacidades e exclusividade.],
    [BLUR-002, 009, 050, PIPE-003, 004], [4/4 (2026-10-20)],
    [TST-BLUR-PY], [Unitário], [Caixa e margem, _kernel_, pixelização, nomes, codecs, áudio e duração.],
    [BLUR-050, COMP-002, OUTPUT-001], [15/15 (2026-10-20)],
    [TST-BLUR-01 a 04, 10 a 14], [Ponta a ponta], [Recusas (anónimo, combinação, opções, sem vídeos, quota),
    pré-visualização sem custo, débito por vídeo, aviso e descarte sem caras.], [BLUR-010, 013, 014, 050,
    QUOTA-001, 003, 005, PIPE-001 a 005, RESULT-001], [21/21 (2026-10-20), 2 ignorados sem vídeo com caras],
    [TST-BLUR-03 (caras), 06, 07, 12], [Ponta a ponta e inspeção], [Dado um vídeo com pessoas, então 2 caras
    detetadas, MP4 H.264/AAC com 14,884 s e _hash_ do original igual; cópia para novo projeto.],
    [BLUR-004, 005, OUTPUT-001, SEC-001, RESULT-003], [Passa (registado pela equipa, 2026-10-19)],
    [TST-BLUR-08], [Inspeção], [Progresso no `ws_gateway` a cada ≈ 1 s.], [STATUS-003, 008], [Passa (2026-10-19)],
    [TST-BLUR-W1], [_Worker_], [MP4 e WebM sem caras com a mesma duração; ficheiro truncado dá erro sem parcial.],
    [STATUS-007, REL-001, COMP-001, 002], [Passa (2026-10-19)],
    [TST-BLUR-W2], [Medição], [Vídeo de 14,9 s (640×360): desfocagem em 7–8 s (≈ 0,5×).], [BLUR-041], [Passa (2026-10-19)],
    [TST-BLUR-M1], [Interface (navegador automático)], [Ferramenta, pré-visualização, resultados e descarte no navegador.],
    [BLUR-002, 009, 010, 013, 014], [Passa, 8/8, em navegador automático (Chromium/Playwright, 2026-10-21): painel, pré-visualização, Apply, aviso e descarte],
    [TST-STATUS-M1], [Interface (navegador automático)], [Dado um projeto com 1 e outro com 2 vídeos e a
    desfocagem, e um com legendas, quando se aplica, então o estado passa de "Em fila" a "Em curso" e a
    percentagem sobe até 100 % (nas legendas, 0 % até ao fim de cada vídeo).], [STATUS-002, 003, 008],
    [Passa (2026-10-21)],
    [TST-CONV-01 a 10], [Unitário], [Parâmetros, limites por perfil, codecs e fronteiras de 500 MB e 10 min,
    vídeo escolhido, nome único, exclusividade e varrimento de temporários.],
    [CONV-002, 014, 015, 022, 026, 035, 037, 047, PIPE-004, RESULT-005], [10/10 (2026-10-20)],
    [TST-CONV-PY], [Unitário], [Regras do _worker_: parâmetros, entrada, altura de saída, argumentos, amostras
    e extrapolação da estimativa.], [CONV-005, 009, 010, 015, 024], [13/13 (2026-10-20)],
    [TST-VIDEO-PY], [Unitário], [Módulo partilhado: ffprobe, ficheiro ilegível, progresso crescente com FFmpeg
    real, falha do FFmpeg, limitação do progresso.], [STATUS-003, 008, MAINT-001], [5/5 (2026-10-20)],
    [TST-CONV-11 a 20, 22], [Ponta a ponta], [Dado aula.mp4, quando se converte para WebM 360p, então 1080p é
    recusado com sugestão de _upgrade_, estimativa com erro de 8 %, confirmação em ≤ 2 s, só o vídeo
    escolhido, tamanhos no resultado, novo vídeo na biblioteca que fica após remover a ferramenta, 1 operação
    consumida, vídeo convertido e resultados da conversão escondidos a outro utilizador (que continua a ver o original), vídeo sem AAC recusado e anónimo recusado.],
    [CONV-003, 006, 008, 014, 015, 024, 033, 036, 039, 047, PERF-001, QUOTA-001, 003, 005], [23/23 (2026-10-23)],
    [TST-CONV-21], [Inspeção (`ffprobe`)], [O vídeo convertido é WebM VP9/Opus, 240 px (sem aumentar) e
    10,015 s para 10 s.], [CONV-005, 046, OUTPUT-001], [Passa (2026-10-20)],
    [TST-CONV-M1], [Manual; reteste em navegador automático], [Conversão no navegador.], [CONV-002, 003, 011, 017],
    [Encontrou D-01 e D-02, corrigidos; reteste em navegador automático (Chromium/Playwright, 2026-10-21): passa, 4/4 (estimativa 598 KB, Save visível, vídeo convertido no projeto)],
    [TST-QUOTA-01], [Ponta a ponta (API)], [Dado um premium e 6 vídeos, quando aplica a extração de frames, então
    os 6 são processados e não há limite diário (`remaining_operations` nulo).], [QUOTA-004],
    [Passa (2026-10-23)],
    [TST-STATUS-01], [Ponta a ponta (API)], [Dado um registado e um vídeo de 55 s com a desfocagem em curso,
    quando cancela, então não ficam resultados e a operação debitada é devolvida.], [STATUS-004, QUOTA-002],
    [Passa (2026-10-23)],
    [TST-FRAME-21], [Ponta a ponta (API)], [Dado o modo frame único no instante 1 s, quando pede a
    pré-visualização, então o _worker_ gera o frame e o `ws_gateway` envia-o ao _browser_.], [FRAME-004],
    [Passa (2026-10-23)],
    [TST-PIPE-01], [Ponta a ponta (API)], [Dado um projeto com uma partilha de leitura e outra de edição, quando
    o convidado adiciona e aplica o corte, então a leitura recebe 403 e a edição consegue.], [PIPE-007],
    [Passa (2026-10-23)],
    [TST-INSP-01], [Inspeção], [Dado o `docker-compose.yaml`, então cada ferramenta de vídeo tem 5 réplicas e
    as legendas 1.], [PERF-002], [Passa (2026-10-23)],
    [TST-INSP-02], [Inspeção], [Dado o `img_storage`, então as ligações de descarga são assinadas (S3) com
    expiração de 1 h.], [SEC-003], [Passa (2026-10-23)],
    [TST-INSP-03], [Inspeção (_git_)], [Dado o _commit_ que acrescenta cada ferramenta de vídeo, então nenhum
    altera os _workers_ anteriores.], [MAINT-001], [Passa com ressalva (2026-10-23): o da conversão refatorou
    também o corte e a extração para o módulo `video.py`],
    [TST-INSP-04], [Inspeção], [Dado o código dos _workers_ de desfocagem e de legendas, então não há chamadas a
    serviços externos; o YuNet vem na imagem e o modelo Whisper é descarregado uma vez para um volume.],
    [BLUR-042, SUB-013], [Passa (2026-10-23)],
    [TST-MED-01 a 05], [Medição], [Dado um vídeo de 10 min (640×360, H.264/AAC) e uma conta premium, sem outros
    trabalhos: frame único, 100 imagens (N = 6), excerto de 5 min e conversão para MP4 360p; e um vídeo de 70 s
    com fala em inglês nas legendas.], [FRAME-025, FRAME-046, TRIM-043, CONV-045, SUB-016],
    [Passa (2026-10-23): 1 s, 14 s, 12 s, 34 s e 8 s, todos dentro do alvo],
  ),
) <tab-testes>

*Totais históricos declarados da execução de 2026-10-21* (com um vídeo com pessoas a falar em `BLUR_FACE_VIDEO`): 59/59 testes
unitários no `projects` (repetidos a 2026-10-23 contra o `projects_mongoDB`, sem nenhum ignorado),
64/64 nos _workers_ Python (desfocagem 15, legendas 15, corte 8, extração 8, conversão 13, módulo partilhado 5)
e 106 verificações ponta a ponta sem falhas (UC-VID-001: 13; UC-VID-002: 23; UC-VID-003: 23; UC-VID-004: 24;
UC-VID-005: 23, repetida a 2026-10-23 depois da alteração da CONV-039), mais as inspeções com `ffprobe`, o _hash_ do original e a faixa WebVTT. Sem esse vídeo, os
testes de deteção de caras e de fala são ignorados.

== Limitações e defeitos conhecidos

*Defeitos encontrados durante o desenvolvimento (corrigidos):*

#tabela(
  colunas: (1.2cm, 1fr, 2.6cm, 2.4cm),
  tamanho: 8.5pt,
  [ID], [Defeito], [Detetado por], [Estado],
  [D-01], [O painel da conversão não tinha _scroll_ e o botão de guardar ficava fora do ecrã.], [Teste manual], [Corrigido (painéis de todas as ferramentas)],
  [D-02], [Faltava no `api_gateway` a rota da estimativa da conversão (404).], [Teste manual], [Corrigido],
  [D-03], [A percentagem de progresso não aparecia na conversão.], [Revisão de código], [Corrigido],
  [D-04], [O _script_ ponta a ponta abortava antes das legendas quando não havia vídeo com caras.], [Execução para este relatório], [Corrigido],
  [D-05], [O texto de estado ficava em "Em fila" e a barra só avançava quando cada vídeo terminava (versão de 2026-10-19).], [Teste no navegador automático], [Não se reproduz na versão final (TST-STATUS-M1)],
  [D-06], [Nas legendas, a página mostrava "Em fila" durante toda a geração, porque o _worker_ não envia percentagem.], [Teste no navegador automático], [Corrigido: o `projects` envia 0 % quando o pedido segue para o _worker_],
)

*Limitações e requisitos parciais no MVP:*
- O estado "em fila/em curso" e o aviso de fim só são visíveis com a página aberta (STATUS-002, STATUS-005
  parciais); ao regressar, vêem-se os resultados mas não o estado. Nas legendas, a página mostra "Em curso"
  sem percentagem intermédia (o modelo não a reporta) até ao fim de cada vídeo.
- Os tempos com vídeos longos foram medidos num vídeo sintético (TST-MED-01 a 05), fácil de codificar; com
  vídeos reais, a conversão e o corte devem demorar mais. A taxa de deteção de caras continua por medir, por
  falta de um conjunto anotado (BLUR-023). Não houve teste de carga (PERF-002).
- A estimativa da conversão espera pela fila: com os 5 _workers_ ocupados mais de 50 s, devolve "converter
  ocupado". A correlação da resposta é feita em memória e pressupõe uma só instância do `projects`.
- Cancelar o "Aplicar" não interrompe uma inferência de legendas já enviada (UC-VID-001/A5).
- A API de quotas não tem reserva e devolução idempotentes por trabalho: uma queda entre o `users` e o
  `projects` pode exigir reconciliação manual da quota.
- Vídeos HEVC (frequentes em telemóveis) são aceites, mas podem não reproduzir em todos os navegadores.
- Legendas: o modelo "small" deteta o idioma automaticamente e pode errar com sotaques fortes (num vídeo em
  inglês detetou galês e transcreveu nesse idioma); nesses casos a opção English dá melhor resultado.
- Os códigos de erro do corte (2100–2103) e da conversão (2100–2102) sobrepõem-se; não afeta o
  funcionamento (cada resposta é associada ao pedido pelo identificador), mas dificulta o diagnóstico.
- Os testes unitários da conversão e das legendas usam separadores de caminho de Linux; no Windows falham
  (a stack corre em Linux, nos contentores).
