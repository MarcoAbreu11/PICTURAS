#import "../template.typ": *

// Capítulo inteiro na horizontal (tabelas largas). Para voltar ao vertical, retirar o #paisagem[ ].
#paisagem[
= Candidatos a Requisitos Não Funcionais

#orientacao[
  *Origem:* Exercício 6, Bloco 2, secção 5 do _template_.

  *Objetivo do capítulo:* escolher *dois* requisitos não funcionais *distintos* a melhorar nesta fase, a partir dos
  cenários de qualidade mais prioritários do capítulo 5. Cada um é classificado segundo a ISO/IEC 25010 (característica e,
  quando aplicável, subcaracterística) e parte de uma fragilidade concreta da solução de base, com evidência.

  Cada candidato é depois especificado, implementado e avaliado por si, ainda que os dois possam estar relacionados.
  A coluna do cenário liga o candidato ao `QS-nn` do capítulo 5, que é a entrada do Exercício 7 (capítulo 7).
]

As evidências deste capítulo referem-se ao _commit_ de partida `0523102` e estão numeradas a partir de `EV-41`
#preencher[renumerar a seguir às evidências dos capítulos 2 a 5]:

- *EV-41:* `apiGateway/routes/projects.js:23-24` — o gateway usa `multer.memoryStorage()`: o ficheiro inteiro fica num `Buffer`.
- *EV-42:* `projects/routes/projects.js:72-73, 1309, 1322, 1343` — o `projects` também usa `multer.memoryStorage()`, e o mesmo `Buffer` serve para o `ffprobe`, para o envio ao `img_storage` e para o SHA-256.
- *EV-43:* `imageStorageService/route/upload.js:6` e `services/uploadImage.js:15` — o `img_storage` recebe o ficheiro em memória e envia-o ao S3 num único `PutObject` (`Body: file.buffer`).
- *EV-44:* `apiGateway/routes/projects.js:458-470` — `upload.single("video")` corre *antes* de `auth.checkToken`, e o `Buffer` é reenviado num novo `FormData` pelo axios, com o `maxRedirects` por omissão (21): o `follow-redirects` guarda mais uma cópia do corpo para o poder reenviar.
- *EV-45:* `nginx/nginx.conf:33-39` — `/api-gateway/` não desativa o _buffering_ do pedido e usa o `proxy_read_timeout` por omissão (60 s).
- *EV-46:* `bench/upload/results/baseline-*.csv` (medição com 1 GB por serviço, sem _swap_) — com 100 MB o gateway cresce 332 MB (mediana); nenhum ficheiro de 500 MB ou mais é aceite (o gateway é morto por falta de memória).
- *EV-47:* `frontend/components/toolbar/toolbar.tsx:53, 67, 84-86` — com vídeos no projeto, as ferramentas de IA e a marca de água deixam de ser desenhadas, sem qualquer explicação.
- *EV-48:* `projects/routes/projects.js:1089-1114` e `1542-1560` — as incompatibilidades só são detetadas na pré-visualização e na execução (`Effects not available for video: …`, `No tools selected`).
- *EV-49:* `projects/routes/projects.js:1397-1426` e `1470-1480` — ao acrescentar ou reordenar ferramentas, o `projects` só valida a extração de fotogramas.
- *EV-50:* `bench/pipeline/results/baseline-*.csv` — na base, só 1 de 9 cenários inválidos (API) e 2 de 10 (editor) têm um aviso útil antes da execução.

#tab([Candidatos a requisitos não funcionais da Fase 2],
  tabela(
    colunas: (1.6cm, 2.6cm, 3cm, 2.4cm, 2.8cm, 2.6cm, 2cm, 3cm, 2.8cm),
    tamanho: 7.5pt,
    [\#], [Característica / subcaracterística (ISO/IEC 25010)], [Fragilidade na base (evidência)], [Origem (padrão global / vídeo / interação)], [Impacto nos stakeholders (pertinência)], [Exigência técnica (complexidade)], [Cenário (`QS-nn`, cap. 5)], [Escala e método de medição (esboço)], [Pré-requisitos / efeitos colaterais],
    [CAND-1], [Eficiência de desempenho / utilização de recursos], [O ficheiro inteiro é guardado em memória em três serviços (EV-41, EV-42, EV-43), mais uma cópia do axios (EV-44); 500 MB e 950 MB falham por falta de memória (EV-46)], [Interação: caminho de carregamento global (nginx, gateway, `projects`, `img_storage`), exercido sobretudo pelos vídeos (até 1 GB)], [Utilizador premium não consegue carregar vídeos dentro do seu limite; um upload grande pode derrubar o gateway para todos; sem progresso visível], [Alta: _streaming_ em quatro saltos, contrapressão, limpeza de temporários em todos os desfechos, validação antes de guardar], [#preencher[QS-nn]], [Crescimento de memória (MB) por serviço durante o upload; ficheiros de 100, 500 e 950 MB e 4 em simultâneo; limite de 1 GB por serviço], [Disco temporário no `projects`; segurança (token antes do corpo); comportamento temporal (REQ-VID-SUBMIT-008)],
    [CAND-2], [Usabilidade / proteção contra erros do utilizador], [Ferramentas escondidas sem explicação (EV-47); incompatibilidades detetadas só na pré-visualização ou execução (EV-48, EV-49); 1/9 e 2/10 com aviso antecipado (EV-50)], [Interação: regras do vídeo (`projects/utils/video.js`) aplicadas ao pipeline do projeto, que é global], [Utilizador configura um pipeline inválido sem o saber e recebe um erro tardio que não diz que ferramenta mudar (REQ-VID-FAIL-003)], [Média: regras numa fonte única no `projects`, consistência com o editor, não bloquear a correção], [#preencher[QS-nn]], [Percentagem de cenários inválidos com aviso específico e acionável antes da execução; 21 cenários (imagens, vídeos, mistos), API e editor], [Não rejeitar configurações válidas; mensagens consistentes entre editor, pré-visualização e execução],
  ),
)

== Quantificação

#orientacao[
  Indiquem a *escala* (o que se mede e em que unidade) e o *método de medição* (cenário, carga, ambiente e instrumento) de
  cada candidato. O objetivo é mostrar que o requisito é mensurável e que sabem como o medir.

  Os valores medidos na base, os valores-alvo e os valores mínimos aceitáveis *só são fixados após a medição inicial
  (_baseline_, capítulo 10)*. Não os inventem: preencham as três últimas linhas da tabela só depois de medir a base,
  indicando a origem de cada valor (e.g., medição, referência externa, necessidade de um _stakeholder_).
]

#tab([Quantificação dos requisitos não funcionais],
  tabela(
    colunas: (4.2cm, 1fr, 1fr),
    [], [CAND-1], [CAND-2],
    [Escala (o que se mede e em que unidade)], [Crescimento da memória residente (VmRSS) de cada serviço do caminho (`api_gateway`, `projects`, `img_storage`) durante o upload, em MB: pico menos o valor imediatamente antes; também uploads aceites e tempo (s)], [Percentagem de cenários inválidos com um aviso *antecipado* (antes de qualquer pré-visualização ou execução), *específico* (nomeia a ferramenta) e *acionável* (diz o que fazer); número de cenários válidos rejeitados ou com aviso],
    [Cenário de medição], [Upload de um vídeo MP4 por um utilizador premium para um projeto, através do nginx (`https://localhost:8080`)], [21 cenários (`bench/pipeline/scenarios.py`): 10 inválidos e 11 válidos, em projetos só com imagens, só com vídeos e mistos],
    [Carga], [Ficheiros de 100, 500 e 950 MB, 5 uploads de cada; 3 corridas de 4 uploads simultâneos de 100 MB], [Cada cenário executado uma vez, na API e no editor],
    [Ambiente], [Mesma máquina nas duas versões, 15 serviços da stack, `compose.memlimit.yaml`: 1 GB sem _swap_ nos três serviços medidos (`bench/upload/RESULTS.md`)], [Mesma máquina; Chromium (Playwright 1.49.0) a 1440 × 900 para o editor (`bench/pipeline/RESULTS.md`)],
    [Instrumento], [`bench/upload/measure_upload.py` (VmRSS lido de `/proc` a cada 0,25 s), `compare.py`], [`bench/pipeline/measure_pipeline.py` (API) e `ui_check.py` (editor)],
    [Valor medido na base], [405 MB no `api_gateway` com 100 MB (mediana 332 MB, cerca de 3,3× o ficheiro); 0/10 uploads de 500 e 950 MB e 0/12 simultâneos aceites (EV-46)], [1/9 (11 %) na API e 2/10 (20 %) no editor; 0 válidos rejeitados (EV-50)],
    [Valor-alvo (e origem)], [≤ 150 MB por serviço em todos os tamanhos e com 4 uploads simultâneos, e todos os uploads até 950 MB aceites. Origem: margem para os _buffers_ de _streaming_, duas partes S3 de 5 MB e o atraso do _garbage collector_, bem abaixo do orçamento de 1 GB; o limite premium é 1 GB (doc-ext-requisitos-2627, RN2)], [≥ 90 % dos inválidos com aviso útil; 0 válidos rejeitados. Origem: proposta da equipa antes da medição, mantida depois de a base dar 11–20 %],
    [Valor mínimo aceitável (e origem)], [≤ 25 % do tamanho do ficheiro por serviço a partir de 500 MB, e todos os uploads até 950 MB aceites. Origem: exclui qualquer serviço que guarde o ficheiro inteiro (a base guardava 200–330 %); a 100 MB domina o custo fixo. Tempo: no máximo +10 % face à base onde ambas funcionam], [≥ 80 % dos inválidos com aviso útil; 0 válidos rejeitados. Origem: proposta da equipa; abaixo disto, um em cada cinco erros continuaria a só aparecer na execução],
  ),
)

== Relação entre os dois candidatos

Os dois candidatos são independentes: nenhum é condição do outro, e cada um foi especificado, implementado e medido por
si. Partilham dois ficheiros (`projects/routes/projects.js`, em rotas diferentes — carregamento num caso, ferramentas,
pré-visualização e execução no outro — e `frontend/lib/projects.ts`), o que exige integração cuidada mas não cria
conflito funcional. O CAND-1 afeta também a segurança (o token passa a ser verificado antes de ler o corpo) e introduz
um custo de disco temporário no `projects`; o CAND-2 acrescenta uma avaliação das regras a cada leitura do projeto, sem
efeito medido no desempenho.

== Evidência exploratória (se existir)

#tab([Evidência exploratória],
  tabela(
    colunas: (4cm, 5cm, 1fr),
    [Descrição], [Localização (_scripts_, dados, resultados)], [Como repetir],
    [Upload de 500 MB na base sem limites de memória: o gateway cresceu cerca de 1,8 GB numa máquina com 6 GB e o _kernel_ terminou a sessão gráfica; numa corrida anterior sem limites, 3 uploads de 500 MB em 3 falharam com `504` ao fim de cerca de 64 s (nginx a 60 s)], [Registo da equipa (não versionado: medição sem limites, não comparável)], [Não repetir sem `compose.memlimit.yaml`; o método comparável está no anexo A],
    [Cenários de pipeline na base], [`bench/pipeline/results/baseline-api-20261115-152825.csv`, `baseline-ui-20261115-183054.csv`], [Anexo A, secção de medição do CAND-2],
  ),
)
]
