# RNF de validação de pipelines: resumo para o relatório (Fase 2)

> Ficheiro de trabalho local, **não é para commit**. A evidência versionável está em
> `bench/pipeline/` (`README.md`, `RESULTS.md`, `results/*.csv`).

## 1. Requisito

**Usabilidade → proteção contra erros do utilizador** (ISO/IEC 25010:2011), na criação de
pipelines em projetos com imagens, vídeos ou ambos.

## 2. Diagnóstico (base `7590c4a`, igual à base oficial `0523102` nesta parte)

- **Regras duplicadas.** O backend tem as listas `VIDEO_TOOLS` e `VIDEO_ONLY_TOOLS` em
  `projects/utils/video.js`. O frontend repete-as como condições de interface:

  ```tsx
  // frontend/components/toolbar/toolbar.tsx (base)
  {hasVideos && <SubtitlesTool disabled={disabled} />}
  {!hasVideos && (<> <WatermarkTool …/> <BgRemovalAITool …/> … </>)}
  ```

- **Validação tardia.** Ao acrescentar uma ferramenta (`POST /tool`), só se valida a extração de
  frames. A compatibilidade com o tipo de média só é verificada na pré-visualização e no
  `/process`:

  ```js
  // projects/routes/projects.js (base), pré-visualização e /process
  const bad = unsupportedVideoTools(project);
  if (bad.length > 0) return res.status(400).jsonp(`Effects not available for video: ${…}`);
  ```

- **Mensagens pouco úteis.** "Effects not available for video: bg_remove_ai" não diz o que fazer.
  "No tools selected" aparece quando o pipeline tem efeitos, mas só de vídeo.
- **Ferramentas escondidas sem explicação** em projetos com vídeos (watermark e 7 de IA).
- **Lista desatualizada.** Depois de uma reordenação recusada, a lista "Applied" ficava com a
  ordem recusada.

## 3. Alternativas consideradas

| Alternativa | A favor | Contra |
| --- | --- | --- |
| **A. Validar no frontend** (regras em TypeScript) | Resposta imediata, sem pedidos. | Duplica as regras do backend, que é o que já causa inconsistências. Não protege a API. |
| **B. Partilhar um ficheiro de regras** (JSON) entre os dois serviços | Uma só fonte. | Cada serviço tem o seu contexto de build em Docker, por isso partilhar ficheiros complica o build e a arquitetura. |
| **C. Regras só no `projects`, que devolve os problemas com o projeto (escolhida)** | Uma só fonte, já perto da orquestração. O frontend só mostra o que recebe. A API fica protegida. | Os avisos dependem de um pedido ao servidor, mas o projeto já é pedido de novo depois de cada alteração. |

## 4. Decisão e implementação (commits `d035a5c` a `9c2d03f`)

- **`projects/utils/pipelineRules.js`** guarda as regras de compatibilidade e os textos com a
  correção sugerida. Há dois níveis de gravidade:
  - **erro**, que bloqueia a pré-visualização e o processamento;
  - **aviso**, que não bloqueia, por exemplo um efeito de vídeo sem efeito ao lado de efeitos de
    imagem.
- **Para não bloquear correções** (cuidado pedido pelo grupo):
  - ao acrescentar ou editar uma ferramenta, só essa ferramenta é avaliada;
  - remover ferramentas, carregar média ou apagar média nunca é bloqueado.
- **A resposta do projeto traz `pipelineIssues` e `unavailableTools`.** O editor continua a
  esconder as mesmas ferramentas (não as torna todas visíveis, como pediu o grupo) e mostra:
  - os problemas, em linhas `role="alert"` por cima do editor;
  - a explicação das ferramentas escondidas, numa linha `role="note"`.
- **A pré-visualização e o `/process`** usam as mesmas regras e as mesmas mensagens.
- **A lista "Applied"** volta à ordem aceite quando a reordenação é recusada.
- **Fora do âmbito:** permissões e quotas, como o grupo pediu.

## 5. Quantificação

| Campo | Valor |
| --- | --- |
| **Escala** | % de cenários inválidos em que o editor mostra, antes da pré-visualização ou do processamento, um aviso que identifica a ferramenta e diz o que fazer. |
| **Método** | Catálogo de 21 cenários (10 inválidos e 11 válidos; só imagens, só vídeos e mistos), em `bench/pipeline/scenarios.py`. Corre-se no editor com Playwright (`ui_check.py`) e na API (`measure_pipeline.py`). Utilizador premium; mesma máquina e mesmos serviços. |
| **Valor da base** | 2/10 (20%) no editor; 1/9 (11%) na API. 11/11 válidos sem avisos. |
| **Valor-alvo** | ≥ 90% (9/10), com 0 falsos avisos e 11/11 válidos a funcionar. |
| **Mínimo aceitável** | ≥ 80% (8/10), com 0 falsos avisos. |
| **Resultado final** | **10/10 (100%)** no editor, **9/9 (100%)** na API, 0 falsos avisos, 11/11 válidos a funcionar. |

Regressão: os 19 testes de regressão de uploads e os 21 testes unitários do `projects` passam.

**Nota de transparência.** Depois da primeira medição final, acrescentei `set`, `choose`, `open` e
`select a` à lista de palavras que contam como "diz o que fazer". A mensagem final do INV-10
("set an end time up to 5 s") é claramente uma instrução, mas nenhuma palavra da lista a
reconhecia. As mensagens guardadas da base foram reclassificadas com a lista nova e nada mudou.

## 6. Limitações

- O critério "específico e útil" é automático (palavras-chave), confirmado pelas capturas de ecrã.
  Uma avaliação com utilizadores reais seria mais forte.
- 10 cenários inválidos: cada um vale 10 pontos percentuais.
- A nota sobre ferramentas escondidas aparece sempre em projetos com vídeos. É informativa, mas
  ocupa uma linha.

## 7. Uso de IA

> Completar com o que o grupo fez nas outras sessões.

- **Ferramenta**: Claude Code (Claude Opus 5.5), com acesso ao repositório e ao Docker local.
- **Tarefas apoiadas**:
  - análise do código atual;
  - catálogo de cenários e scripts de medição (API e Playwright);
  - implementação das regras, das rotas e dos avisos no editor;
  - testes unitários, medições, `RESULTS.md` e este resumo.
- **Validação feita por nós**: _[a preencher; por exemplo: revisão dos commits, leitura das capturas em
  `bench/pipeline/results/screens/`, confirmação manual de alguns cenários no browser, revisão das
  mensagens]_.
