#import "../template.typ": *

= Trade-offs, Medição e Preservação Funcional

#orientacao[
  *Origem:* Exercício 7, secção 5 do _template_ (e os riscos de preservação funcional do Bloco 2, secção 6).

  *Objetivo do capítulo:* mostrar que as decisões foram avaliadas além do atributo que melhoram (_trade-offs_), que a
  melhoria foi medida de forma comparável (antes e depois) e que o comportamento funcional foi preservado.

  A mesma medição é feita *antes e depois* do _refactoring_, no mesmo ambiente. *Não inventem valores* de _baseline_, alvo
  ou mínimo aceitável: fixam-se após a medição inicial. Guardem os _scripts_, os dados e o ambiente das medições para os
  reutilizar como _baseline_.
]

== Matriz de efeitos

#orientacao[
  Para cada decisão, indiquem se cada atributo *melhora* (↑), *degrada* (↓) ou fica *neutro* (=), e justifiquem. Incluam
  no mínimo quatro atributos, e entre eles a característica do outro cenário: uma melhoria num atributo costuma ter um
  custo noutro, e é isso que esta matriz deve revelar. Se uma decisão degradar um atributo, digam como a equipa vai
  gerir esse custo.
]

#paisagem[
#tab([Matriz de efeitos das decisões],
  tabela(
    colunas: (1.8cm, 2.6cm, 3.4cm, 2.4cm, 2.4cm, 3.6cm, 1fr),
    tamanho: 8.5pt,
    [Decisão], [Desempenho], [Disponibilidade / Fiabilidade], [Segurança], [Usabilidade], [Manutenibilidade / Testabilidade], [Justificação],
    [DA-1], [↑ memória; ↓ disco], [↑], [↑], [↑], [↓ / ↑], [A memória por serviço deixa de acompanhar o ficheiro e o tempo a 100 MB desce 25 %, mas o `projects` passa a usar até cerca de 1 GB de disco temporário por upload em curso (documentado; o temporário é apagado em todos os desfechos). O gateway deixa de ser morto por falta de memória, o que antes interrompia também os pedidos de outros utilizadores. O JWT é verificado antes de ler o corpo e o anónimo é recusado antes de enviar o ficheiro. A barra de progresso só é fiel sem _buffering_. O código de _streams_ é mais difícil de manter (cancelamentos, falhas a meio); a equipa compensou com 18 testes unitários, que também tornam o caminho testável sem a _stack_.],
    [DA-2], [=], [↑], [=], [↑], [↑], [Avaliar as regras a cada leitura do projeto é linear no número de ferramentas; não foi medido, mas o pipeline tem poucas ferramentas. Erros que antes falhavam no _worker_ de vídeo (e.g., _trim_ para lá da duração) passam a ser recusados ao configurar. Sem efeito na segurança: as permissões e as quotas não mudam. As regras de compatibilidade ficam num único módulo; o editor ainda repete os limites do _speed_ e a tolerância do _trim_ nos formulários (dívida registada).],
  ),
)
]

== Interação entre DA-1 e DA-2

#tab([Interação entre as decisões],
  tabela(
    colunas: (2.2cm, 2.2cm, 4.4cm, 1fr),
    [Decisão A], [Decisão B], [Efeito (pré-requisito, sinergia ou conflito)], [Razão / evidência],
    [DA-1], [DA-2], [Independentes, sem conflito funcional; partilham ficheiros], [As duas alteram `projects/routes/projects.js` (DA-1 nas rotas de carregamento, DA-2 nas de ferramentas, pré-visualização, execução e leitura) e `frontend/lib/projects.ts`. O histórico é linear e os 26 testes do `projects` passam no _commit_ entregue. A medição final do CAND-2 (`087cc9f`) já correu com o carregamento em _stream_ (DA-1), e as 19 verificações de regressão passaram nesse _commit_.],
  ),
)

== Plano de medição

#tab([Plano de medição],
  tabela(
    colunas: (1.6cm, 3.2cm, 3cm, 2.6cm, 2.4cm, 2.8cm),
    tamanho: 8pt,
    [Cenário], [Cenário de teste e carga], [Ambiente (máquina, recursos, versões)], [O que se regista], [Repetições e agregação], [Onde ficam os _scripts_ e os dados],
    [#preencher[QS-01]], [Upload de MP4 por um utilizador premium através do nginx: 100, 500 e 950 MB em série; 4 × 100 MB em simultâneo], [Intel Core Ultra 7 356H, 16 CPU lógicos, 15,4 GiB (WSL2, Ubuntu 26.04.1), Docker Engine 29.9.2, Compose v5.6.1; 15 serviços; 1 GB sem _swap_ em `api_gateway`, `projects` e `img_storage`], [VmRSS de cada serviço a cada 0,25 s (base e pico), estado HTTP, tempo, memória do _cgroup_ (contexto)], [5 uploads por tamanho, 3 corridas simultâneas; mediana e máximo], [`bench/upload/` (`measure_upload.py`, `compare.py`, `compose.memlimit.yaml`, `results/*.csv`, `RESULTS.md`)],
    [#preencher[QS-02]], [21 cenários (10 inválidos, 11 válidos) em projetos só com imagens, só com vídeos e mistos; um utilizador premium], [A mesma máquina; Chromium (Playwright 1.49.0) a 1440 × 900], [Onde o problema é reportado pela primeira vez, a mensagem, se é específica e acionável; nos válidos, se são aceites, sem aviso, e produzem os resultados], [1 execução por cenário, na API e no editor; percentagem], [`bench/pipeline/` (`scenarios.py`, `measure_pipeline.py`, `ui_check.py`, `results/*.csv`, `RESULTS.md`)],
  ),
)

A base do CAND-1 foi extraída com `git archive 0523102`, com os _scripts_ de medição copiados da versão final, e
corrida sob um nome de projeto Compose próprio, a partir de volumes vazios. A base do CAND-2 corresponde aos _commits_
`7590c4a` (API) e `6129bfd` (editor), cujo código de `projects` e `frontend` relevante é o de `0523102`.

== Resultados das medições

#orientacao[
  Para cada requisito não funcional, apresentem os valores medidos *antes* (_baseline_) e *depois* do _refactoring_, com o
  mesmo método e nas mesmas condições (plano acima), e comparem-nos com o valor-alvo e o valor mínimo aceitável fixados no
  capítulo 6. Os dados brutos e os _scripts_ ficam no repositório entregue.

  Na análise, sejam críticos: o que melhorou, o que não foi atingido e porquê, que outros atributos foram afetados
  (confirmando ou não a matriz de efeitos) e que ameaças à validade das medições existem.
]

#tab([Resultados das medições],
  tabela(
    colunas: (1.6cm, 1fr, 2cm, 2cm, 2cm, 2cm, 2cm),
    tamanho: 8.5pt,
    [Cenário], [Medição (o que se mede, unidade)], [Antes (_baseline_)], [Depois], [Valor-alvo], [Mínimo aceitável], [Atingido?],
    [QS-01], [Crescimento máximo por serviço, em série (MB)], [405 com 100 MB; ≥ 500 MB: OOM], [105 (950 MB)], [≤ 150], [—], [Alvo],
    [QS-01], [Crescimento máximo por serviço, 4 × 100 MB em simultâneo (MB)], [OOM (≥ 812)], [146], [≤ 150], [—], [Alvo],
    [QS-01], [Crescimento máximo por serviço face ao ficheiro, a partir de 500 MB (%)], [OOM (≥ 186 % a 500 MB, ≥ 94 % a 950 MB)], [17 % (500 MB), 11 % (950 MB)], [—], [≤ 25 %], [Mínimo e alvo],
    [QS-01], [Uploads aceites até 950 MB], [5/15 em série; 0/12 em simultâneo], [15/15; 12/12], [todos], [todos], [Alvo],
    [QS-01], [Tempo mediano de upload, 100 MB em série (s)], [2,0], [1,5], [≤ 2,2], [≤ 2,2], [Alvo],
    [QS-02], [Inválidos com aviso útil antes da execução, editor (%)], [20 % (2/10)], [100 % (10/10)], [≥ 90 %], [≥ 80 %], [Alvo],
    [QS-02], [Inválidos com aviso útil antes da execução, API (%)], [11 % (1/9)], [100 % (9/9); 89 % com o critério original], [≥ 90 %], [≥ 80 %], [Alvo (mínimo com o critério original)],
    [QS-02], [Válidos rejeitados ou com aviso], [0/11], [0/11], [0], [0], [Alvo],
  ),
)

*Análise dos resultados — CAND-1.* Na base, cada serviço guardava o ficheiro inteiro: com 100 MB o `api_gateway`
cresceu cerca de 3,3 vezes o ficheiro (o _buffer_ do multer, um novo `FormData` e a cópia que o axios guarda enquanto os
redirecionamentos estão ativos) e o caminho no total cerca de 7,5 vezes. Com 1 GB por serviço, a base não aceitou nenhum
ficheiro de 500 MB ou mais, nem nenhum lote de 4 × 100 MB: o processo do gateway foi terminado por falta de memória
(13 vezes). Na versão final, de 100 para 950 MB (9,5 vezes mais dados) o maior crescimento por serviço passou de 61 para
105 MB, e todos os uploads foram aceites. O alvo é atingido em todos os pontos medidos, mas a memória não é totalmente
independente do tamanho: o `img_storage` ainda cresce de 59 para 100 MB (mediana), o que pode ser atraso do
_garbage collector_ e não dados vivos (a medição não os separa); o alvo vale para os tamanhos testados, até ao limite
premium de 1 GiB. O tempo só é comparável a 100 MB, porque a base falha nos outros pontos (1,5 s contra 2,0 s). O nginx
da base usa um _timeout_ de 60 s e o final 300 s; neste ambiente isso não decidiu nenhum resultado (a base falhou por
falta de memória ao fim de no máximo cerca de 6 s, e o upload final mais lento demorou 14,1 s), mas em máquinas mais
lentas e sem limites a base falha com `504` aos 60 s. Confirma-se o custo previsto na matriz de efeitos: com 950 MB a
memória do _cgroup_ do `projects` chega a 578 MB por causa da _cache_ de páginas do ficheiro temporário, que o _kernel_
recupera sob pressão.

*Análise dos resultados — CAND-2.* Na base, quase todos os erros apareciam só no pedido de pré-visualização, com
mensagens como `No tools selected` num pipeline que não estava vazio, ou no _worker_ de vídeo (INV-10). Na versão final,
cada cenário inválido tem, no editor, uma linha de aviso que nomeia a ferramenta, explica o motivo e diz o que fazer, e a
API recusa o passo ou devolve o problema; os 11 cenários válidos, incluindo os dois de correção de um pipeline inválido
(VAL-10, VAL-11), continuam aceites, sem aviso, e produzem os resultados. A lista de palavras que conta uma mensagem
como «acionável» foi alargada depois da primeira corrida final, porque a mensagem do INV-10 («_set an end time up to 5 s_»)
é acionável mas não continha nenhuma palavra da lista; com o critério original, a API fica em 89 %: acima do mínimo e
logo abaixo do alvo. A alteração está documentada e foi aplicada também à base, sem mudar o seu resultado.

*Ameaças à validade.* (1) Uma só máquina (WSL2) e uma só corrida por cenário no CAND-2. (2) O amostrador lê a cada
0,25 s: os valores da base marcados como OOM são limites inferiores. (3) As medições finais são de `7590c4a` (CAND-1) e
`087cc9f` (CAND-2); as correções posteriores (`6b43ad0`, `870546b`) só acrescentam verificações antes do upload e não foram
medidas de novo. (4) O critério do CAND-2 é heurístico (listas de nomes de ferramentas e de palavras) e os cenários foram
escritos pela equipa, o que pode favorecer os casos que a solução trata. (5) O crescimento de memória inclui lixo ainda
não recolhido.

== Preservação funcional

#tab([Preservação funcional e testes de regressão],
  tabela(
    colunas: (2.4cm, 3.8cm, 2.8cm, 3.2cm, 1fr),
    tamanho: 8.5pt,
    [Zona alterada], [Testes de regressão existentes (`Tools/video/tests`, `projects/tests`, …)], [Lacunas de teste], [Testes acrescentados], [Resultado (imagem e vídeo)],
    [DA-1: nginx, `api_gateway`, `projects` (carregamento), `img_storage`, diálogo de importação], [`projects/tests`: processamento em lote, pipeline de vídeo e extração de fotogramas (8 testes)], [Nenhum teste do caminho de carregamento na base], [`bench/upload/regression.py` (19 verificações: imagem e vídeo aceites, transferência idêntica byte a byte, metadados, SHA-256, rejeições existentes, 401 sem token, pipeline sobre uma imagem e um vídeo); 18 testes unitários (`upload-storage`, `upload-profile`, `forward-upload`, `s3-stream-storage`)], [`regression.py` 19/19 na base e na versão final; testes unitários 34/34 no _commit_ entregue (`projects` 26, `apiGateway` 3, `imageStorageService` 5)],
    [DA-2: regras do pipeline no `projects`, barra de ferramentas e avisos do editor], [Os mesmos 8 testes do `projects`; `Tools/video/tests` não é afetado (sem alterações em `Tools/`)], [Regras de compatibilidade sem testes; nenhum teste do editor], [`pipeline-rules.test.js` (8 testes); 11 cenários válidos executados de ponta a ponta (`measure_pipeline.py`) e verificados no editor (`ui_check.py`)], [11/11 válidos aceites, sem aviso e com os resultados esperados (imagem, vídeo e misto); testes unitários a passar],
  ),
)

#tab([Riscos para a preservação funcional e mitigação],
  tabela(
    colunas: (3.4cm, 3.2cm, 4cm, 3.2cm),
    tamanho: 8.5pt,
    [Risco], [Funcionalidade afetada (imagem / vídeo)], [Mitigação], [Teste de regressão],
    [Validação do vídeo deixar de acontecer antes de guardar], [Carregamento de vídeo], [`ffprobe` e `validateVideo` correm sobre o temporário, antes de enviar ao `img_storage`], [`regression.py` (rejeições e projeto inalterado após rejeição)],
    [Ficheiro guardado diferente do enviado], [Imagem e vídeo], [SHA-256 calculado na mesma passagem; envio por partes], [`regression.py` (transferência idêntica byte a byte, SHA-256)],
    [Temporário deixado no disco], [Carregamento (disco do `projects`)], [Remoção quando a resposta termina e quando o cliente desliga (`870546b`)], [`upload-storage.test.js` (limite e cancelamento a meio)],
    [Perfil anónimo ou desconhecido sem limite antecipado], [Carregamento de vídeo], [403/503 antes de ler o corpo (`6b43ad0`)], [`upload-profile.test.js`],
    [A validação antecipada impedir a correção de um pipeline inválido], [Edição do pipeline], [Ao acrescentar ou editar, só a ferramenta alterada é avaliada; carregar ou apagar _media_ nunca é bloqueado], [Cenários VAL-10 e VAL-11],
    [Avisos em pipelines válidos], [Edição do pipeline], [Avisos só para erros e casos sem efeito; a explicação das ferramentas escondidas é uma nota, não um aviso], [11 cenários válidos sem aviso (`ui_check.py`)],
  ),
)
