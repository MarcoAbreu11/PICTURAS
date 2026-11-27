#import "../template.typ": *

= Decisões Arquiteturais

#orientacao[
  *Origem:* Exercício 7, secção 3 do _template_.

  Uma decisão por cenário (`DA-1` para `QS-01`, `DA-2` para `QS-02`). Cada decisão é um pequeno registo, ao estilo ADR: o
  contexto, a tática escolhida, a estrutura ou padrão que a realiza, as alternativas consideradas e a razão da sua
  rejeição, as consequências positivas e negativas, e os elementos arquiteturais afetados.

  Só vale a pena registar uma decisão se havia *alternativas reais* (as táticas do capítulo 7 que não foram escolhidas).
  Justifiquem a escolha pelo cenário e pelas restrições da fase: rejeitem as táticas de classe C, porque a fase é de
  _refactoring_, e avaliem o risco de regressão do âmbito da alteração.

  *Depois de implementada*, completem cada decisão com as referências da implementação (_commits_ ou _pull requests_ no
  repositório entregue) e com os desvios face ao que foi decidido, explicando porquê. A vista «depois» do capítulo 9
  deve corresponder ao que foi efetivamente implementado.
]

== DA-1 — Carregamento em _streaming_ com um único temporário (cenário QS-01)

#tab([Decisão arquitetural DA-1],
  tabela-campos(
    [Contexto], [Cada serviço do caminho guarda o ficheiro inteiro em memória (EV-11 a EV-14); com 1 GB por serviço, nenhum vídeo de 500 MB ou mais é aceite (EV-16), embora o limite premium seja 1 GB. A correção tem de manter as rotas, o contrato da API, a validação dos vídeos antes de guardar e os limites por perfil.],
    [Tática(s) escolhida(s)], [TAT-01 (_streaming_ com _buffers_ limitados) e TAT-02 (rejeitar cedo).],
    [Estrutura / padrão que a realiza], [_Pipes and filters_ sobre _streams_ com contrapressão: nginx (`proxy_request_buffering off`, 300 s) → `api_gateway` (verifica o token e encaminha o próprio pedido, `data: req`, `maxRedirects: 0`) → `projects` (motor de armazenamento do multer que escreve num temporário e calcula o SHA-256 na mesma passagem; verifica o perfil e o `Content-Length` antes de ler) → `img_storage` (multipart S3, partes de 5 MB, 2 em trânsito). O _frontend_ mostra o progresso do envio.],
    [Alternativas consideradas e razão de rejeição], [TAT-04 (URL pré-assinado): a validação (`ffprobe`, codec, duração, limites por perfil) passaria a correr sobre um objeto já guardado, obrigava a expor o S3 ao _browser_ (CORS, políticas por utilizador) e mudava o fluxo do _frontend_ e do `projects` — contra «estender em vez de reescrever». · TAT-05 (disco em todos os saltos): três escritas e leituras completas por upload, mais disco e mais tempo, e o gateway continuaria a receber tudo antes de verificar o token. · TAT-03 (mais memória): não resolve, porque a memória continua a crescer com o ficheiro e com o número de uploads simultâneos.],
    [Consequências positivas], [Memória por serviço deixa de acompanhar o tamanho do ficheiro (≤ 146 MB, cap. 10); ficheiros até 950 MB aceites; o gateway deixa de poder ser derrubado por um upload; pedidos sem token ou acima do limite são recusados sem transferir o ficheiro; progresso real no editor.],
    [Consequências negativas / riscos], [Disco temporário no `projects` (até cerca de 1 GB por upload em curso); mais código de tratamento de erros em _streams_ (cancelamento do cliente, falhas do S3); o `img_storage` ainda cresce ligeiramente com o tamanho (59 → 100 MB).],
    [Elementos arquiteturais afetados], [`nginx/nginx.conf`; `apiGateway/routes/projects.js`, `apiGateway/utils/forwardUpload.js`; `projects/routes/projects.js` (rotas de upload), `projects/utils/uploadStorage.js`, `projects/utils/uploadProfile.js`, `projects/utils/video.js`; `imageStorageService/route/upload.js`, `services/uploadImage.js`, `services/s3StreamStorage.js`; `frontend/lib/projects.ts`, `components/project-page/add-images-dialog.tsx`, `components/dashboard-sidebar/new-project-dialog.tsx`.],
    [Origem e âmbito do _refactoring_], [Padrão global (caminho de carregamento comum a imagens e vídeos), exercido sobretudo pelo vídeo. Risco de regressão médio: toca quatro serviços, mitigado por 18 testes unitários novos (13 do _refactoring_ e 5 das correções) e pelas 19 verificações de regressão (`bench/upload/regression.py`).],
    [Classe (A/B/C)], [A, com uma parte B: o _streaming_ e a rejeição antecipada não mudam o comportamento funcional; a barra de progresso é uma alteração visível que faz parte da melhoria (o progresso só é real sem _buffering_) e realiza o REQ-VID-SUBMIT-006, especificado na Fase 1 e não implementado, pelo que não é uma funcionalidade nova.],
    [Implementação (_commits_ / _pull requests_)], [`613f274` (S3 em _stream_), `1cdcddf` (temporário + SHA-256), `175a809` (token primeiro, encaminhamento em _stream_), `ec9184d` (nginx), `9390492` (progresso), `16a33b4` (medição e regressão); correções após auditoria: `44faaf5` (perfil anónimo ou desconhecido recusado antes do corpo), `31936e3` (temporário apagado quando o cliente desliga); correções após os testes da equipa: `845c27e` e `53e6749` (limite do plano verificado no editor antes do envio), `3092bbd` (progresso também no diálogo de criar projeto).],
    [Desvios face à decisão], [Nenhum na estrutura. A auditoria interna encontrou dois casos que a primeira implementação não cobria (perfil anónimo sem limite antecipado; temporário deixado no disco quando o cliente cancela), corrigidos com testes. As medições do cap. 10 são de `16a33b4`; as duas correções só acrescentam verificações antes do upload e não alteram o caminho medido. Os testes manuais da equipa encontraram mais dois casos: a rejeição antecipada fecha a ligação enquanto o _browser_ ainda envia, e o editor mostrava «sem ligação» em vez do motivo; o editor passou a comparar o tamanho com o limite do plano antes de enviar (`845c27e`, `53e6749`), com a mesma fonte de limites do `projects`. Não é uma regra nova: os limites e a recusa já existiam (UC-VID-001/RN2, REQ-VID-SUBMIT-004), e a mensagem com a causa é a que o REQ-VID-FAIL-003 pede. A barra de progresso só existia no diálogo de importação e passou a existir também no de criar projeto, que deixa de aceitar um segundo clique durante o envio (`3092bbd`). Nenhuma altera o caminho medido.],
  ),
)

== DA-2 — Regras do pipeline numa fonte única, verificadas durante a composição (cenário QS-02)

#tab([Decisão arquitetural DA-2],
  tabela-campos(
    [Contexto], [As ferramentas incompatíveis desaparecem do editor sem explicação (EV-17) e as incompatibilidades só aparecem na pré-visualização ou na execução, com mensagens que não dizem o que mudar (EV-18, EV-19). As regras existem no `projects` (`video.js`), mas o editor tem a sua própria versão.],
    [Tática(s) escolhida(s)], [TAT-06 (modelo do sistema numa fonte única), TAT-07 (validar na entrada) e TAT-08 (explicar as ferramentas não oferecidas).],
    [Estrutura / padrão que a realiza], [Módulo de regras no `projects` (`projects/utils/pipelineRules.js`) que, a partir de `video.js`, calcula os problemas de uma ferramenta (`toolErrors`), do pipeline (`pipelineIssues`) e as ferramentas indisponíveis (`unavailableTools`), cada um com ferramenta, motivo e correção. O `projects` usa-o ao acrescentar e editar ferramentas e antes da pré-visualização e da execução; a resposta do projeto leva os problemas e o editor mostra-os (`PipelineNotices`, `role="alert"`/`role="note"`).],
    [Alternativas consideradas e razão de rejeição], [TAT-10 (validação só no _frontend_): duplicaria as regras e deixaria a API aceitar pipelines inválidos, com risco de divergência. · TAT-09 (desativar em vez de esconder): mudava mais a barra de ferramentas do que o necessário; manteve-se o comportamento de esconder e acrescentou-se a explicação. · TAT-11 (correção automática): classe C, funcionalidade nova.],
    [Consequências positivas], [Todos os cenários inválidos passam a ter aviso antes da execução (100 % na API e no editor, cap. 10); a mesma mensagem no editor, na pré-visualização e na execução; o editor deixa de repetir as regras de compatibilidade.],
    [Consequências negativas / riscos], [Um passo inválido passa a ser recusado ao ser acrescentado (alteração visível, é o objeto da melhoria); a regra de não bloquear correções obriga a avaliar só a ferramenta alterada; o editor ainda repete os limites do _speed_ e a tolerância do _trim_ nos formulários; o reordenamento só valida a extração de fotogramas.],
    [Elementos arquiteturais afetados], [`projects/utils/pipelineRules.js`, `projects/utils/video.js`, `projects/routes/projects.js` (ferramentas, reordenação, pré-visualização, execução e leitura do projeto); `frontend/components/toolbar/toolbar.tsx`, `components/project-page/pipeline-notices.tsx`, `lib/projects.ts`, `providers/project-provider.tsx`, `app/dashboard/[pid]/page.tsx`; `AGENTS.md`.],
    [Origem e âmbito do _refactoring_], [Interação: regras do vídeo aplicadas ao pipeline do projeto. Risco de regressão baixo a médio: mitigado pelos 11 cenários válidos (incluindo dois de correção, VAL-10 e VAL-11) e por 9 testes unitários novos.],
    [Classe (A/B/C)], [B: avisos e recusas antecipadas são alterações visíveis e são o objeto da melhoria; nenhuma ferramenta nova. As recusas já eram exigidas (REQ-VID-EDIT-008) e as mensagens com a causa também (REQ-VID-FAIL-003); muda o momento em que aparecem.],
    [Implementação (_commits_ / _pull requests_)], [`a5eee79` (cenários e medição da base), `adc5b28` (regras), `84a9a8a` (validação e `pipelineIssues`), `eb05e74` (avisos no editor), `ce68e98` (ordem reposta quando o servidor recusa), `8ec34f8` (`AGENTS.md`), `588544b` (critério de mensagem acionável), `184c542` (resultados finais), `01e3d9f` (confirmação das metas); correção após a validação final: `07627d6` (pré-visualização de imagens), com o teste `1da87b1`.],
    [Desvios face à decisão], [A primeira implementação bloqueava *todas* as pré-visualizações quando o pipeline tinha um erro, incluindo a de uma imagem num projeto misto com uma ferramenta só de imagem, que a base aceitava (só a do vídeo era recusada). Foi uma regressão funcional, encontrada na validação final e corrigida: a pré-visualização de uma imagem só é travada por problemas que afetam imagens (`previewBlockingIssue`). O critério «acionável» da medição foi alargado depois da primeira corrida final (`588544b`); com o critério original, a API dá 8/9 (89 %). A alteração está documentada em `bench/pipeline/RESULTS.md`.],
  ),
)
