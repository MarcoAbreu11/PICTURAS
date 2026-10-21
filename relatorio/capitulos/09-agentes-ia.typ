#import "../template.typ": *

= Implementação Assistida por Agentes de IA

== Ferramentas, modelos e configuração

#tabela(
  colunas: (3.5cm, 1fr),
  [Ferramenta / modelo], [Configuração e utilização],
  [Claude (assistente de conversação)], [Usado nos Exercícios 1 e 2 para a primeira versão dos casos de uso
  UC-VID-002 a 005 e das respetivas ERS. Sem configuração própria: _prompts_ com o enunciado, o _template_ e os
  exemplos dos docentes.],
  [Claude Code], [Agente de programação no terminal e na aplicação de _desktop_ (modelo Claude Opus), a
  trabalhar diretamente no repositório da equipa. Usado na implementação dos UC-VID-002 a 005, na revisão
  dos casos de uso face ao código, nas correções de arquitetura e na redação deste relatório a partir dos
  documentos da equipa. Executa comandos (Docker, testes) com permissões aprovadas pelo utilizador.],
  [ChatGPT / ChatGPT Work], [Usado no UC-VID-001 para analisar o repositório e os documentos, planear,
  implementar, rever o _diff_ e criar e executar os testes (nota de implementação `docs/UC-VID-001_legendas.md`).],
)

O repositório *não contém ficheiros de configuração dos agentes* (_skills_ em `.claude/skills/`, `CLAUDE.md`
ou `AGENTS.md`): as instruções foram dadas em cada sessão. É uma lacuna face às diretrizes, a corrigir na
Fase 2 com instruções de projeto versionadas (convenções de código, comandos de teste, regras de
arquitetura).

== Tarefas apoiadas e validação

#tab([Tarefas apoiadas por agentes de IA e validação],
  tabela(
    colunas: (2.3cm, 1.7cm, 1fr, 1fr, 2.4cm),
    tamanho: 8pt,
    [Ferramenta], [Caso de uso], [Tarefa apoiada], [Validação realizada pela equipa], [Evidência],
    [Claude], [UC-VID-002 a 005], [Casos de uso, fluxos, exceções, regras, assunções e questões em aberto;
    ERS com classificação ISO/IEC 25010, valores (†) e decisões de qualidade.], [Revisão manual comparando com
    o enunciado, o _template_ e os exemplos dos docentes; no UC-VID-003, confirmação da classificação, dos
    valores e da rastreabilidade.], [Documentos `docs/UC-VID-00x*.md` (v1.0–v1.1)],
    [Claude Code], [UC-VID-003], [_Worker_ `extract_frames`, capacidades por tipo de média, alterações ao
    `projects`, `ws_gateway`, `tool_msg.py` e _frontend_; testes unitários e ponta a ponta.], [Teste manual no
    navegador de MP4 e MOV (TST-FRAME-M1); #preencher[revisão de código pela equipa]], [_commit_ `28c3917`],
    [Claude Code], [UC-VID-002], [_Worker_ `trim`, linha temporal e pré-visualização no _frontend_; testes.],
    [Teste manual no navegador do corte (TST-TRIM-M1); #preencher[revisão de código pela equipa]], [_commit_ `af277ef`],
    [Claude Code], [UC-VID-004], [_Worker_ `blur_faces` (OpenCV/YuNet, FFmpeg), descarte de resultados,
    testes e medição do tempo.], [Execução do teste ponta a ponta com um vídeo próprio com pessoas (2 caras
    detetadas, TST-BLUR-03); #preencher[revisão de código e teste manual TST-BLUR-M1]], [_commit_ `809439d`],
    [Claude Code], [UC-VID-005], [_Worker_ `video_convert`, ferramenta no _frontend_, regras e testes;
    verificação do caso de uso face ao código (nove lacunas encontradas e corrigidas); passagem da estimativa
    para o _worker_; módulo partilhado `video.py`; versões fixadas.], [O elemento responsável pediu a
    verificação contra a ERS, testou no navegador (encontrou o painel sem _scroll_ e a estimativa a falhar,
    D-01 e D-02 no Capítulo 10), pediu a verificação da arquitetura (originou a DA-07) e aprovou o _merge_.],
    [_commit_ `329e31a`],
    [ChatGPT Work], [UC-VID-001], [Serviço e _worker_ de legendas, rotas, leitor no _frontend_, testes de
    backend, _worker_, inferência real e Chromium.], [A nota de implementação regista que a revisão humana ainda
    não tinha ocorrido; #preencher[registar a revisão feita pela equipa]], [_commits_ `0c0c9c0`, `8a9729d`],
    [Claude Code], [Todos], [Consolidação dos cinco casos de uso e das ERS neste relatório (requisitos
    partilhados, decisões de qualidade globais, matriz, realização), diagramas em PlantUML e execução de todas
    as baterias de testes para registar os resultados.], [#preencher[revisão do relatório pela equipa]],
    [`relatorio/`],
  ),
) <tab-ia>

== Análise crítica

*O que correu bem.* Os agentes foram eficazes a produzir código que segue padrões já existentes (um novo
_worker_ igual aos de imagem, rotas iguais às restantes) e a escrever testes nos três níveis (unitários,
_workers_ e ponta a ponta). Os testes automáticos tornaram-se a principal forma de validar o código gerado:
cada afirmação do agente ("o vídeo mantém a duração", "a quota é devolvida") passou a ter um teste que a
confirma, muitas vezes com `ffprobe` sobre o ficheiro real.

*Onde a IA errou e como foi detetado.*
- *Desvio de arquitetura.* Na primeira versão da conversão, a estimativa de tamanho corria o FFmpeg dentro
  do `projects`, durante o pedido HTTP. Os testes passavam; o problema só foi detetado quando a equipa
  perguntou se a implementação seguia a arquitetura de base. Foi corrigido passando a estimativa para o
  _worker_ (DA-07).
- *Testes que não passavam pelo caminho real.* Os testes ponta a ponta chamavam o `projects` diretamente;
  por isso não apanharam que faltava no `api_gateway` a rota da estimativa. O defeito foi encontrado no teste
  manual no navegador (D-02). Lição: pelo menos um teste por funcionalidade deve passar pelo gateway.
- *Defeitos de interface.* O painel da conversão ficava sem botões visíveis (sem _scroll_) e a percentagem de
  progresso não aparecia na conversão, porque a página só tratava o corte e a extração como ferramentas de
  vídeo. O primeiro foi encontrado pela equipa no navegador; o segundo pelo agente ao rever o código.
- *Revisão do próprio trabalho.* Quando lhe foi pedido que verificasse o UC-VID-005 contra a ERS, o agente
  encontrou nove lacunas no código que ele próprio tinha gerado (confirmação em mais de 2 s, temporários
  sem limpeza, resultado não persistente, entre outras). A implementação "completa" inicial não era
  completa.
- *Testes a adaptar-se ao resultado.* Um teste da conversão falhou porque o vídeo sintético de teste fica
  maior quando comprimido; o agente ajustou o teste para confirmar o resultado maior. A alteração foi
  aceite porque o comportamento de recusa já tinha sido observado nessa execução, mas mostra o risco de um
  agente "corrigir" o teste em vez do código.
- *Dados de teste inadequados.* Nas legendas, uma amostra portuguesa sintetizada foi detetada como latim; o
  teste passou a usar fala humana real, sem forçar o idioma.

*Práticas adotadas.* (i) Pedir ao agente que verifique explicitamente o código contra a ERS, requisito a
requisito; (ii) correr todas as baterias de testes depois de cada alteração e inspecionar os ficheiros
gerados; (iii) testar cada funcionalidade no navegador, pelo caminho real; (iv) fazer perguntas de
arquitetura, não só de funcionalidade; (v) rever os _commits_ antes do _merge_. A equipa é responsável por
todo o conteúdo entregue, incluindo o gerado por IA.
