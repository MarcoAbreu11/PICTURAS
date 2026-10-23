#import "../template.typ": *

#set heading(numbering: "A.1.")
#counter(heading).update(0)

= Instruções de execução

*Pré-requisitos*: Docker com Docker Compose; espaço em disco para as imagens dos workers (FFmpeg, OpenCV, Whisper); ligação à internet na
primeira construção (imagens base, pacotes e modelos). Testado em Linux e em WSL2.

*Lançar a solução* (na raiz de `solucao-ext-mvp.zip`):

```bash
docker compose up -d --build
docker compose restart nginx
```

O segundo comando só é necessário depois de reconstruir o _frontend_ ou os gateways (o nginx guarda o IP
antigo, T-22). A aplicação fica em `https://localhost:8080` (certificado autoassinado). Criar uma conta em
"Register"; para testar o perfil premium, fazer o _upgrade_ na página da conta (pagamento simulado). O modelo
das legendas é descarregado na primeira utilização para o volume `whisper_models`.

*Utilização rápida*: criar um projeto, carregar um vídeo MP4 (até 60 s numa conta registada), abri-lo no
carrossel, escolher uma ferramenta de vídeo na barra lateral, guardar e carregar em "Apply". Os resultados
aparecem em "Results"; o vídeo convertido aparece também na lista de itens do projeto.

*Testes automáticos*:

```bash
# unitários do projects; o teste das legendas usa o projects_mongoDB (base temporária, apagada no fim)
docker compose up -d projects_mongoDB
cd projects && SUBTITLES_TEST_MONGO=mongodb://127.0.0.1:27018 node --test test/*.test.js

# unitários dos workers (dentro das imagens, que já têm FFmpeg e OpenCV)
docker run --rm --entrypoint sh picturas-video_convert_tool -c "python -m unittest test_convert_rules utils.test_video"

# ponta a ponta, com a stack a correr (opcional: vídeo com caras e fala)
BLUR_FACE_VIDEO=/caminho/video_com_pessoas.mp4 bash projects/test/e2e/run.sh
```

Os restantes _workers_ testam-se da mesma forma com `test_trim_rules`, `test_frames`, `test_blur_faces_rules`
e `test_subtitles`, nas imagens respetivas.

*Problemas conhecidos*: se o `users` ou o `subscriptions` tiverem arrancado antes da sua base de dados,
reiniciá-los (`docker compose restart users subscriptions`, T-23).

= Glossário

#tabela(
  colunas: (4cm, 1fr),
  [Termo], [Definição],
  [Biblioteca (do projeto)], [Conjunto dos itens de média de um projeto (imagens e vídeos carregados, copiados
  ou convertidos). Os itens mantêm-se até serem eliminados.],
  [Resultado], [Ficheiro produzido por uma execução da _pipeline_ (imagem, vídeo ou frames). É substituído na
  execução seguinte; para o manter, copia-se para um novo projeto.],
  [Faixa de legendas], [Texto com tempos, em formato WebVTT, associado a um vídeo e a um idioma; não altera o
  vídeo.],
  [Ferramenta de vídeo], [Ferramenta da _pipeline_ que aceita apenas vídeos: corte, extração de frames,
  desfocagem de caras, conversão e legendas.],
  [Ferramenta avançada], [Ferramenta que consome uma operação da quota diária do registado por item
  processado e não está disponível ao anónimo.],
  [_Pipeline_], [Sequência ordenada de ferramentas de um projeto, aplicada a todos os itens compatíveis ao
  carregar em "Aplicar".],
  [Trabalho de processamento], [Processamento de um item por uma ferramenta, criado em cada "Aplicar", com
  estado (em fila, em curso, concluído, falhado, cancelado), progresso e causa da falha.],
  [_Worker_], [Microserviço que consome uma fila do RabbitMQ e executa uma ferramenta.],
  [Operação (quota)], [Unidade da quota diária do perfil registado (5 por dia).],
  [_Codec_ / contentor], [Formato de compressão do vídeo ou do áudio (H.264, VP9, AAC, Opus) e formato do
  ficheiro que os contém (MP4, MOV, WebM).],
  [WebVTT], [Formato de legendas suportado nativamente pelo elemento de vídeo dos navegadores.],
  [Ligação assinada], [URL temporário, com assinatura e expiração, para descarregar um ficheiro do
  armazenamento.],
)
