# UC-VID-001 — Gerar legendas automáticas (E4)

Base inspecionada: `main`, `41b4f2f6686d7609dc391fde4190acef89511960`.
O conteúdo versionado coincidia com o ZIP da auditoria anterior.
Branch de implementação: `feat/video-subtitles`. Não fazer merge automático.

## Comportamento

No carrossel de um vídeo, abrir **Automatic subtitles**, escolher Original (transcrição)
ou English (tradução para inglês) e carregar em **Save**: a ferramenta fica na pipeline do
projeto, como as outras ferramentas de vídeo. As legendas **só são geradas no Apply**,
para todos os vídeos do projeto (as imagens são ignoradas). No fim do Apply a página fica
na edição e ativa a faixa gerada em cada vídeo. O mesmo painel deixa mostrar ou esconder
as faixas que já existem ("Show subtitles"); escolher uma faixa não gera nada.
Quando a origem é inglês, a interface mostra apenas Original (Inglês), equivalente a English.

Só contas free/premium autenticadas podem consultar ou gerar. O proprietário ou uma
partilha edit podem gerar; partilhas read podem selecionar faixas existentes.
Vídeos convertidos conservam a restrição existente de acesso pelo proprietário.
Não são herdadas faixas de vídeos cortados, convertidos ou de outros resultados.

O contrato de geração aceita exclusivamente `{ "language": "original" | "en" }`.
Não aceita modo, burn-in, SRT, preview ou outros idiomas de destino.
O MVP guarda apenas o idioma predominante devolvido pelo modelo.

## Integração e decisões

| Componente | Alteração E4 e motivo |
|---|---|
| `projects/models/subtitles.js`, `controllers/subtitles.js` | Documento único por projeto/vídeo, hash da fonte, idiomas/faixas e bloqueio atómico. Coleção separada porque as atualizações atuais substituem os arrays do projeto e poderiam perder metadados concorrentes. |
| `services/subtitles.js`, `subtitleRuntime.js` | Reutilização antes da reserva, orquestração, finalização condicional, limpeza e recuperação. Usa Mongo, armazenamento e RabbitMQ existentes. |
| `routes/subtitles.js`, `app.js`, Gateway | GET/POST por vídeo, JWT validado pelo serviço users, autorização explícita de proprietário/partilha e perfil. Não confiar em `owner` ou `X-Caller-Id` como autorização. |
| `projects/routes/projects.js`, `utils/subtitlesTool.js`, `utils/toolCapabilities.js` | Registo como avançada e exclusiva, só para vídeos; validação de `{ language }` na pipeline; sem pré-visualização; no `/process` (Apply) chama o serviço de legendas para cada vídeo (`startSubtitleRun`); não entra na cobrança genérica, porque o serviço reserva e devolve a quota por vídeo; três pontos de limpeza (vídeo/projeto/conta). |
| Serviço de armazenamento | Stage `subtitles`; nome determinístico por job exclusivamente neste stage, para que repetir upload não crie objetos órfãos. MIME `text/vtt`. |
| `Tools/video_subtitles/`, Compose e RabbitMQ | Modelo small multilingue CPU/int8, cache persistente, filas E4 próprias. Preserva os contratos e o comportamento das outras tools. |
| Hook, toolbar e player | Estado por utilizador/projeto/vídeo, consulta com renovação de URLs, polling durante geração e uma única faixa ativa via `textTracks`. A ferramenta da toolbar usa o `ToolbarButton` das outras ferramentas (Save adiciona à pipeline). A página do projeto conta as legendas como ferramenta de vídeo e, no fim do Apply, ativa a faixa gerada. |

As legendas são uma ferramenta da pipeline e só são geradas no Apply (alteração
posterior à primeira versão, que usava uma ação própria por vídeo). O serviço de
legendas não mudou: o Apply chama-o para cada vídeo e o consumidor dos resultados avisa
a página de quem aplicou quando cada vídeo termina (faixa guardada) ou falha (com o
motivo), como as restantes ferramentas de vídeo. A seleção de faixas continua no painel
da ferramenta. Limitação: o Cancelar do Apply não interrompe uma inferência já enviada
ao worker; essa faixa fica guardada quando terminar. Não há pré-visualização.
A rota POST por vídeo mantém-se na API (usada pelos testes do serviço).

As chaves S3 persistem; URLs assinados são obtidos na consulta e renovados antes de
expirarem. A mesma chave física é associada a Original e English quando a origem é `en`.
A primeira geração válida, em qualquer ordem, guarda o idioma detetado.

## Concorrência, falhas e eliminação

- Aquisição condicional em Mongo: apenas um job por vídeo, incluindo sessões distintas.
  Faixas existentes podem ser reutilizadas enquanto outra opção está a ser gerada.
- O bloqueio dura até à publicação e persistência. Não expira por relógio durante IA.
- Filas duráveis e publisher confirms; o consumidor E4 confirma apenas depois de tratar
  a resposta. A alteração é local a E4 porque os helpers genéricos fazem ack antecipado.
- O worker executa fora do ciclo de heartbeat, com lock de ficheiro por vídeo no volume
  partilhado e recibo por job. Mensagens repetidas devolvem o mesmo recibo sem nova IA.
- O backend repete o mesmo job reservado após interrupções. Um pedido que caiu antes
  de reservar/publicar pode ser libertado após 60 s; a publicação exige CAS da reserva.
- Output temporário é renomeado só depois de WebVTT completo. Texto é escapado e tempos
  são validados. Erros de fala não publicam ficheiro nem idioma.
- Eliminação marca o registo como eliminado e apaga chaves físicas deduplicadas.
  A resposta tardia verifica existência/hash do vídeo e faz limpeza compensatória.
  O varrimento repete limpeza se o armazenamento estiver indisponível.
- Recibos pequenos de transporte ficam em `/app/images/subtitles/receipts`, sem áudio
  ou texto de legendas, para impedir reprocessamento de mensagens antigas. Não apagar
  estes recibos com filas E4 ainda pendentes. As fontes temporárias e VTT saem do
  diretório de trabalho quando o resultado é tratado.

## Quotas e limitações conhecidas

Uma geração nova reserva uma operação avançada através do endpoint já existente em
users; reutilização, troca e desativação reservam zero. Não há novos limites quantitativos.
Falhas conhecidas do worker reembolsam uma vez no fluxo normal.

A API transversal de quotas não oferece reserva/reembolso idempotente por job nem
transação com Mongo de projects. Uma queda entre a resposta de users e a gravação
local, ou uma resposta perdida de reembolso, pode exigir reconciliação de quota.
Não se alterou users nem se alegam garantias de contabilização exatamente uma vez
perante falhas distribuídas. Q1 continua a ser uma decisão transversal.

Outras limitações preexistentes, fora do âmbito: eliminação genérica faz operações de
ficheiros antes de confirmar a versão; transporte das outras tools confirma cedo;
as regras de exclusividade impedem os encadeamentos do guião antigo. Não foram corrigidas.

O idioma/qualidade dependem do modelo e da gravação. Uma primeira amostra portuguesa
sintetizada com eSpeak foi identificada como latim; o teste com fala humana portuguesa
foi bem-sucedido. Não se força um idioma para fazer o teste passar.

## Validação

Os testes não afirmam que houve revisão humana. Comandos:

```sh
# Backend: testes existentes e E4; usar um Mongo exclusivo para testes.
cd projects
SUBTITLES_TEST_MONGO=mongodb://127.0.0.1:27018 node --test test/*.test.js

# Worker e regras, sem descarregar modelo.
PYTHONPATH=Tools python -m unittest discover -s Tools/video_subtitles -p 'test_*.py'

# Inferência real opt-in: ffmpeg, espeak-ng e dependências do worker.
PYTHONPATH=Tools python Tools/video_subtitles/smoke_inference.py

# Player real em Chromium; dependência de testes opcional.
cd frontend
npm install --no-save playwright
npx playwright install chromium
node test/subtitles-player.cjs
```

O teste de Mongo cria e remove uma base exclusiva com nome aleatório. O teste do
player usa os componentes/hook reais com API simulada, e verifica `textTracks` e
cues WebVTT reais; não é uma prova de toda a stack HTTP/S3 num único browser.
`smoke_transport.py` destina-se a um broker/worker e volume de testes isolados.

Resultados recolhidos:

| Verificação | Resultado |
|---|---|
| Backend Node + Mongo real | 47/47 passaram; inclui autorização, ambas as ordens, equivalência inglesa, reutilização, 12 pedidos concorrentes, falhas, eliminação durante upload e respostas duplicadas. |
| Python Linux | 64/64 passaram: 15 E4, 8 trim, 8 frames, 15 blur, 13 conversão, 5 utilitários FFmpeg. |
| Inferência real CPU/int8 | Português→Original e Português→English com `pt` detetado; inglês em ambas as tarefas; sem áudio 2303; tom sem fala 2304. Hash dos vídeos preservado. |
| Chromium | Geração ativa; desativar/trocar/reabrir reutiliza; cues reais carregam; resposta tardia fica no vídeo correto; nenhum erro JavaScript. |
| RabbitMQ + worker reais | Pedido sem áudio devolve 2303; mensagem repetida devolve o mesmo recibo sem novo processamento. |
| Serviço de armazenamento + S3 real (MinIO isolado) | Repetição de upload conserva a chave; conteúdo UTF-8 e MIME `text/vtt` corretos; leitura e eliminação passaram. Não foi uma execução com SeaweedFS. |
| TypeScript/Next | Tipos e compilação passaram; 13 páginas geradas. Empacotamento standalone no Windows falhou por EPERM na criação de symlinks, mesmo fora da sandbox. |
| Compose | `docker compose config --quiet` passou. Imagem do worker construída com sucesso. |
| Regressão Windows | A mesma falha de separador de caminho da conversão registada na auditoria; em Linux passa. Nenhum ficheiro das quatro tools foi alterado. |

Áudio português de teste: [Google FLEURS](https://huggingface.co/datasets/google/fleurs),
CC BY 4.0, `pt_br/audio/dev/10021311324523185658.wav`. É descarregado apenas para o
teste opt-in, sem o incluir no repositório. O vídeo WebM do teste do player é um
retângulo preto gerado com FFmpeg, sem áudio nem material de terceiros.
API Whisper confirmada no [código da versão 1.2.1](https://github.com/SYSTRAN/faster-whisper/blob/v1.2.1/faster_whisper/transcribe.py).

## Uso de IA

ChatGPT/ChatGPT Work foi usado para análise do repositório e documentos, planeamento,
implementação assistida, revisão do diff, criação e execução de testes.
A funcionalidade e a documentação foram revistas posteriormente pelo Cláudio/Rafael.

## Revisão final de 2026-10-23

Resultados acima são históricos. Nesta revisão: Node E4 6 passam e 1 integração Mongo ignorada; tentativa explícita de Mongo falhou com ECONNREFUSED em 27018. Python E4 15/15, TypeScript e Compose config passaram. Teste atualizado passou em Edge/Chromium com painel e mutação Apply reais e API simulada: Save sem geração, Apply, English primeiro e idioma junto de Original antes da sua faixa, cues, desativação e reutilização. Não valida a página completa/sockets nem ativação automática após Apply. E2E tentou arrancar e falhou: motor Docker indisponível. Datas históricas de inferência e transporte não comprovadas; não reexecutados.
