#import "../template.typ": *

= Trade-offs, Cenários de Qualidade e Prioridades

#orientacao[
  *Origem:* Exercício 6, Bloco 2, secção 4 do _template_ (sem a justificação detalhada da matriz, que não faz parte
  deste relatório).

  *Objetivo do capítulo:* transformar o diagnóstico dos capítulos 2 a 4 em cenários de qualidade concretos e
  verificáveis, priorizá-los e perceber como os atributos se afetam uns aos outros.

  *Princípio central:* a caracterização dos cenários de qualidade *deve basear-se na identificação de fragilidades do
  sistema atual*. Cada cenário parte de uma fragilidade concreta, com evidência (`EV-nn`), observada na solução de
  base (e.g., uma falha sem recuperação, um ponto de contenção, uma dependência rígida). Um cenário sem fragilidade
  identificada é uma preferência, não uma necessidade. Reutilizem os `EV`, `H` e `ALT` já usados, sem os alterar.

  *Este é o único sítio onde os cenários de qualidade se caracterizam:* os capítulos 6 a 10 usam-nos sem os reescrever.
]

== Cenários de qualidade para a extensão de vídeo

#orientacao[
  Para cada fragilidade relevante, escrevam um cenário com os *seis elementos*:
  - *fonte do estímulo*: quem ou o que o origina (utilizador, serviço, falha de infraestrutura);
  - *estímulo*: o evento a que o sistema tem de reagir;
  - *artefacto*: a parte do sistema afetada;
  - *ambiente*: em que condições (carga normal, pico, degradado);
  - *resposta*: o que o sistema deve fazer;
  - *medida da resposta*: como se verifica, com métrica e escala. Definem-na vocês e tem de ser *verificável*.

  A coluna *Fragilidade* liga o cenário à evidência que o justifica. Não inventem valores de _baseline_, alvo ou
  mínimo: esses fixam-se após a medição inicial. A medida da resposta indica o que se mede, não o valor a atingir.
]

#tab([Cenários de qualidade],
  tabela(
    colunas: (1.2fr, 3.4fr, 2.6fr, 2.2fr, 2.2fr, 2.4fr, 2.2fr, 2.6fr, 3fr),
    tamanho: 7pt,
    [ID], [Fragilidade na base (EV-nn)], [Característica (ISO/IEC 25010)], [Fonte do estímulo], [Estímulo], [Artefacto], [Ambiente], [Resposta], [Medida da resposta],
    [QS-01], [Upload inteiro em RAM em 3 serviços + cópia do axios; 500 MB e 950 MB falham por OOM (EV-11 a EV-16)], [Eficiência de desempenho / utilização de recursos], [Utilizador _premium_], [Carrega um vídeo MP4 até 1 GB (ou vários em simultâneo)], [`nginx`, `api_gateway`, `projects`, `img_storage`], [Carga normal e concorrente (1 GB/serviço, sem _swap_)], [Processa o upload em _streaming_ sem acumular o ficheiro em memória e mostra progresso], [Crescimento de VmRSS (MB) por serviço, taxa de sucesso até 950 MB e tempo (s)],
    [QS-02], [Ferramentas escondidas sem explicação e erros só no _Apply_ / pré-visualização (EV-17 a EV-20)], [Usabilidade / proteção contra erros do utilizador], [Utilizador no editor ou cliente API], [Adiciona, edita ou reordena ferramentas num projeto com vídeos ou misto], [`projects` (rotas de ferramentas, pré-visualização e execução) e `frontend` (editor)], [Operação normal de composição de _pipeline_], [Deteta incompatibilidades na composição e apresenta aviso específico e acionável], [Percentagem de cenários inválidos com aviso antecipado útil; 0 válidos rejeitados],
    [QS-03], [Instância única de `video_tool` sem réplicas (EV-07)], [Eficiência de desempenho / capacidade], [Múltiplos utilizadores], [Submetem _Apply_ de vídeo em simultâneo], [`video_queue` e `video_tool`], [Carga concorrente], [Distribui tarefas por múltiplas instâncias sem perda de mensagens], [Tempo de espera em fila e taxa de conclusão concorrente],
  ),
)

#orientacao[
  *Priorização.* Avaliem cada cenário em duas dimensões: a *importância para os stakeholders* (quem sofre com a
  fragilidade e quanto) e a *dificuldade ou risco técnico* de a resolver. Justifiquem cada avaliação em poucas palavras
  e atribuam uma ordem de prioridade (1 = mais prioritário). Os dois cenários mais prioritários, e que dão origem aos
  candidatos a RNF do capítulo 6, são os mais importantes e viáveis, não necessariamente os mais fáceis.
]

#tab([Priorização dos cenários],
  tabela(
    colunas: (1.6cm, 4.8cm, 4.8cm, 2cm),
    [ID], [Importância para os stakeholders], [Dificuldade / risco técnico], [Prioridade],
    [QS-01], [Alta — utilizadores _premium_ não conseguem carregar vídeos dentro do limite de 1 GB e um upload pode derrubar o gateway], [Alta — exige _streaming_ com contrapressão em 4 serviços e limpeza de temporários], [1],
    [QS-02], [Alta — utilizadores configuram _pipelines_ inválidos sem feedback e recebem erros tardios sem saber o que corrigir], [Média — requer fonte única de regras no `projects` sem quebrar correções], [2],
    [QS-03], [Média — afeta apenas picos de concorrência no processamento, sem impedir o uso normal], [Baixa/Média — escalar réplicas exige apenas gestão de concorrência no `video_tool`], [3],
  ),
)

== Atributos de qualidade por ordem de prioridade

#orientacao[
  Com base nos cenários mais importantes, ordenem os atributos de qualidade (ISO/IEC 25010) do mais para o menos
  prioritário, indicando os cenários que justificam cada posição. A ordem tem de ser coerente com a tabela de
  priorização acima.
]

+ *Eficiência de desempenho (utilização de recursos)* — cenário `QS-01`; é o bloqueio mais grave da solução atual, pois impede o cumprimento do limite _premium_ de 1 GB e compromete a estabilidade do `api_gateway`.
+ *Usabilidade (proteção contra erros do utilizador)* — cenário `QS-02`; afeta diretamente a experiência de composição de _pipelines_ sempre que existem vídeos ou projetos mistos.
+ *Eficiência de desempenho (capacidade)* — cenário `QS-03`; relevante para escalabilidade em carga concorrente, mas secundário face aos bloqueios funcionais/operacionais de `QS-01` e `QS-02`.

== Pré-requisitos e efeitos colaterais entre atributos

#orientacao[
  Os atributos não são independentes. Identifiquem os pares em que melhorar um é *pré-requisito* do outro (e.g.,
  observabilidade antes de otimizar desempenho), em que há *sinergia*, ou em que há *conflito* (melhorar um degrada
  o outro). Expliquem a razão e, se possível, citem evidência.
]

#tab([Pré-requisitos e efeitos colaterais entre atributos],
  tabela(
    colunas: (2.8cm, 2.8cm, 4cm, 1fr),
    [Atributo A], [Atributo B], [Efeito (pré-requisito, sinergia ou conflito)], [Razão / evidência],
    [Segurança (validação de token)], [Eficiência de desempenho (upload)], [Sinergia], [Validar o JWT e o `Content-Length` antes de ler o corpo evita consumir RAM/disco com pedidos não autorizados (EV-14)],
    [Eficiência de desempenho (RAM)], [Utilização de disco temporário], [Conflito (_trade-off_)], [Para validar com `ffprobe` e calcular SHA-256 sem guardar em RAM (EV-12), o `projects` passa a usar um ficheiro temporário em disco],
    [Manutenibilidade (fonte única)], [Usabilidade (avisos antecipados)], [Pré-requisito], [Centralizar as regras de compatibilidade no `projects` (`video.js`) é necessário para garantir mensagens consistentes no editor e na API (EV-17, EV-18)],
  ),
)

== Recomendações de melhoria à solução atual

#orientacao[
  Recomendações concretas que respondem às fragilidades identificadas, indicando o atributo que melhoram, o padrão
  (global ou vídeo) a que se aplicam, o esforço estimado e o risco de regressão. Esta fase é de _refactoring_: as
  recomendações têm de poder ser aplicadas sem acrescentar funcionalidades.
]

#tab([Recomendações de melhoria],
  tabela(
    colunas: (1fr, 2.6cm, 3cm, 1.8cm, 2.2cm),
    tamanho: 8.5pt,
    [Recomendação], [Atributo(s)], [Padrão a que se refere (global / vídeo)], [Esforço], [Risco de regressão],
    [Converter o caminho de upload (`nginx`, `api_gateway`, `projects`, `img_storage`) para _streaming_ com um único temporário no `projects` e validação antecipada de token/perfil], [Eficiência de desempenho; Segurança], [Padrão global (exercido pelo vídeo)], [Alto], [Médio],
    [Extrair as regras de compatibilidade para um módulo único no `projects` e expor `pipelineIssues` e `unavailableTools` ao editor], [Usabilidade; Manutenibilidade], [Interação entre padrão global e vídeo], [Médio], [Baixo / Médio],
    [Configurar réplicas horizontais para `video_tool` quando houver carga concorrente elevada], [Eficiência de desempenho (capacidade)], [Padrão do vídeo], [Baixo], [Baixo],
  ),
)
