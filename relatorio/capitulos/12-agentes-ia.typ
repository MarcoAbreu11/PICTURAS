#import "../template.typ": *

= Utilização de IA

#orientacao[
  *Origem:* Exercício 6, Bloco 2, secção 7, e Exercício 7, secção 6.

  Obrigatório: documentar as ferramentas, os modelos e as _skills_ utilizadas, enumerar as tarefas apoiadas e comprovar a
  validação realizada pela equipa, tanto na análise e na escrita como no código e nas medições. A equipa é responsável
  por todo o conteúdo entregue, incluindo o gerado por IA.

  Valoriza-se evidência concreta (_commits_, ficheiros de configuração dos agentes) e reflexão crítica: o que a IA
  fez bem, onde errou, como o erro foi detetado e o que foi rejeitado e porquê. Não basta dizer que a IA foi usada; é preciso mostrar
  que o resultado foi verificado.
]

== Ferramentas, modelos e configuração

#tabela(
  colunas: (3.5cm, 1fr),
  [Ferramenta / modelo], [Configuração e utilização (_skills_, instruções de projeto, MCP, …)],
  [Claude Code (aplicação de _desktop_ e CLI), modelo Claude Opus 5.5], [Instruções de projeto em `AGENTS.md` (arquitetura, comandos, convenções de _commits_, armadilhas conhecidas), atualizado nesta fase com as regras do pipeline (`8ec34f8`). Sessões com acesso de leitura e escrita ao repositório local; os comandos que falam com o GitHub (`push`, `fetch`) correram no terminal do utilizador. A auditoria usou subagentes do próprio Claude Code (dois auditores e um supervisor, só de leitura). Os 21 _commits_ de implementação e medição (`613f274` a `01e3d9f`) e as correções posteriores (`07627d6`, `1da87b1`, `845c27e`, `53e6749`, `3092bbd`) foram feitos com o Claude Code. O histórico entregue não tem o _trailer_ `Co-Authored-By`, por isso esta tabela é o registo dos _commits_ feitos com IA.],
)

== Tarefas apoiadas e validação

#tab([Tarefas apoiadas por IA e validação],
  tabela(
    colunas: (2.6cm, 2.4cm, 2.4cm, 2.8cm, 2.8cm),
    tamanho: 8.5pt,
    [Ferramenta / modelo / _skill_], [Tarefa apoiada (capítulo)], [O que foi aceite], [O que foi rejeitado e porquê], [Como foi validado pela equipa],
    [Claude Code / Opus 5.5], [Implementação do DA-1: _streaming_ em quatro serviços e barra de progresso (cap. 8)], [Os _commits_ `613f274` a `9390492`; depois dos testes manuais da equipa, `845c27e`, `53e6749` e `3092bbd`], [Nada rejeitado; as falhas encontradas depois foram corrigidas em _commits_ próprios: dois casos da auditoria (`44faaf5`, `31936e3`) e dois dos testes manuais (o «sem ligação» em vez do motivo, a barra que faltava ao criar um projeto)], [13 testes unitários novos; `regression.py` 19/19 na base e no final; medição com limites de memória (cap. 10); testes manuais da equipa no _browser_, com vídeos acima do limite do plano],
    [Claude Code / Opus 5.5], [_Scripts_ de medição e de regressão do CAND-1 (cap. 10, anexo A)], [`bench/upload/` (`16a33b4`, `3733acf`, `a5c7530`)], [Medir a base sem limites de memória: esgotou a memória da máquina e não era comparável; passou a usar 1 GB sem _swap_ (`3733acf`)], [CSV versionados; os valores do `RESULTS.md` foram recalculados a partir dos CSV],
    [Claude Code / Opus 5.5], [Implementação do DA-2: regras, validação e avisos do editor (cap. 8)], [`adc5b28` a `ce68e98`], [A primeira versão bloqueava a pré-visualização de uma imagem num projeto misto; foi substituída (`07627d6`) porque a base a permitia], [11 cenários válidos sem regressão; 9 testes unitários novos; validação final da equipa, que encontrou essa regressão],
    [Claude Code / Opus 5.5], [Cenários e medição do CAND-2 (cap. 10)], [`a5eee79`, `184c542`], [—], [Base e final com o mesmo _script_; a alteração do critério (`588544b`) está divulgada, com o resultado pelo critério original (89 %)],
    [Claude Code / Opus 5.5 (subagentes)], [Auditoria só de leitura aos dois RNF, com supervisor que confirmou veredictos sorteados no código], [Dois defeitos do DA-1, corrigidos com testes (`44faaf5`, `31936e3`); a falta da meta escrita (`3d546ca`, `01e3d9f`)], [Mostrar as ferramentas desativadas em vez de escondidas, limite antecipado para imagens e validação do reordenamento: fora do âmbito definido pela equipa; uma prova errada de um auditor, corrigida pelo supervisor], [O teste novo do cancelamento falha no código anterior e passa na correção; 34/34 testes unitários nesse momento (35/35 depois da validação final)],
    [Claude Code / Opus 5.5], [Validação final (lista da equipa): testes unitários, regressão, pré-visualização num projeto misto e benchmarks no _commit_ integrado], [A correção de uma regressão encontrada nesta validação (`07627d6`) e o teste que a cobre (`1da87b1`)], [—], [O teste da pré-visualização falhava antes da correção e passa depois (8/8); testes unitários 35/35; `regression.py` 19/19; benchmarks repetidos em `1da87b1` (CAND-1 e CAND-2, `bench/*/RESULTS.md`); o `ui_check.py` precisou de ajustes para SELinux e Podman sem _root_; testes unitários (35/35) e `regression.py` (19/19) repetidos no código entregue (`464929f`)],
    [Claude Code / Opus 5.5], [Redação dos capítulos 1, 6 a 10 e 12 e do anexo A, a partir do repositório], [Esses capítulos, completados pela equipa com os capítulos 2 a 5 e 11 e a capa (`cf21012`)], [Referências a _commits_ que deixaram de existir depois do _rebase_, substituídas pela equipa (`3fcc367`)], [Leitura crítica pela equipa e confronto com os exercícios 6 e 7; referências a _commits_ verificadas no histórico],
  ),
)

== Análise crítica

A IA foi útil para tarefas extensas e verificáveis: percorrer os quatro serviços do caminho de carregamento, escrever o
código de _streaming_ com os seus casos de erro, gerar os _scripts_ de medição e os cenários, e recalcular os resultados a
partir dos dados brutos. A sua principal fragilidade foi a de qualquer implementação não verificada: a primeira versão
do DA-1 não removia o ficheiro temporário quando o cliente cancelava o upload e deixava o perfil anónimo sem limite
antecipado. Os dois casos foram encontrados por uma auditoria independente (também com IA, mas com a regra de provar
cada afirmação com ficheiro e linha ou com a saída de um comando) e só foram aceites depois de reproduzidos: o teste do
cancelamento falha no código anterior e passa no corrigido. A validação final da equipa encontrou ainda uma regressão que nem a implementação nem a auditoria tinham visto: as regras novas bloqueavam a pré-visualização de uma imagem num projeto misto com uma ferramenta só de imagem, o que a base permitia. Os cenários de medição pré-visualizavam sempre o vídeo, por isso não a apanharam. A auditoria também errou: um auditor citou uma linha que não
provava o que afirmava, e o supervisor detetou-o ao confirmar os veredictos no código.

Duas práticas reduziram o risco: medir antes de mudar, com o mesmo _script_ e no mesmo ambiente, e não aceitar números que
não se possam recalcular a partir dos CSV. Um ponto a assinalar é a alteração do critério do CAND-2 depois de ver o
resultado final: está documentada e foi aplicada também à base, mas mostra que a métrica deve ser fixada antes de medir.
Na reflexão da equipa, três pontos. Primeiro, a IA não substituiu os testes manuais: as duas falhas mais visíveis para o utilizador (a mensagem «sem ligação» quando o vídeo excede o limite do plano e a falta de progresso ao criar um projeto) só apareceram quando a equipa usou a aplicação no _browser_, depois de testes, regressão e auditoria terem passado. Segundo, a equipa reviu os textos gerados contra o repositório e os exercícios, completou os capítulos da base e corrigiu as referências que o _rebase_ tornou inválidas. Terceiro, faríamos de outra forma: fixar a métrica de cada requisito antes de medir, incluir nos cenários de medição a pré-visualização de imagens em projetos mistos e testar no _browser_ mais cedo, a cada alteração visível.
