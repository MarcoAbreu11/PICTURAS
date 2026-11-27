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
  [Claude Code (aplicação de _desktop_ e CLI), modelo Claude Opus 5.5], [Usado como assistente de programação no repositório local, a partir das instruções de projeto em `AGENTS.md` (atualizado nesta fase com as regras do pipeline, `8ec34f8`). A equipa fixou o âmbito (os dois RNF e o que fazer em cada um), testou e aceitou cada alteração; os comandos que falam com o GitHub correram no terminal da equipa. _Commits_ feitos com este apoio: `613f274` a `01e3d9f` e as correções `07627d6`, `1da87b1`, `845c27e`, `53e6749` e `3092bbd` (o histórico não tem o _trailer_ `Co-Authored-By`, por isso esta lista é o registo).],
)

== Tarefas apoiadas e validação

#tab([Tarefas apoiadas por IA e validação],
  tabela(
    colunas: (2.6cm, 2.4cm, 2.4cm, 2.8cm, 2.8cm),
    tamanho: 8.5pt,
    [Ferramenta / modelo / _skill_], [Tarefa apoiada (capítulo)], [O que foi aceite], [O que foi rejeitado e porquê], [Como foi validado pela equipa],
    [Claude Code / Opus 5.5], [Implementação do DA-1: _streaming_ em quatro serviços e barra de progresso (cap. 8)], [Os _commits_ `613f274` a `9390492`; depois dos testes manuais da equipa, `845c27e`, `53e6749` e `3092bbd`], [Nada rejeitado; as falhas encontradas depois foram corrigidas em _commits_ próprios: dois casos encontrados numa revisão posterior do código (`44faaf5`, `31936e3`) e dois dos testes manuais (o «sem ligação» em vez do motivo, a barra que faltava ao criar um projeto)], [13 testes unitários novos; `regression.py` 19/19 na base e no final; medição com limites de memória (cap. 10); testes manuais da equipa no _browser_, com vídeos acima do limite do plano],
    [Claude Code / Opus 5.5], [_Scripts_ de medição e de regressão do CAND-1 (cap. 10, anexo A)], [`bench/upload/` (`16a33b4`, `3733acf`, `a5c7530`)], [Medir a base sem limites de memória: esgotou a memória da máquina e não era comparável; passou a usar 1 GB sem _swap_ (`3733acf`)], [CSV versionados; os valores do `RESULTS.md` foram recalculados a partir dos CSV],
    [Claude Code / Opus 5.5], [Implementação do DA-2: regras, validação e avisos do editor (cap. 8)], [`adc5b28` a `ce68e98`], [A primeira versão bloqueava a pré-visualização de uma imagem num projeto misto; foi substituída (`07627d6`) porque a base a permitia], [11 cenários válidos sem regressão; 9 testes unitários novos; validação final da equipa, que encontrou essa regressão],
    [Claude Code / Opus 5.5], [Cenários e medição do CAND-2 (cap. 10)], [`a5eee79`, `184c542`], [—], [Base e final com o mesmo _script_; a alteração do critério (`588544b`) está divulgada, com o resultado pelo critério original (89 %)],
    [Claude Code / Opus 5.5], [Validação final (lista da equipa): testes unitários, regressão, pré-visualização num projeto misto e benchmarks no _commit_ integrado], [A correção de uma regressão encontrada nesta validação (`07627d6`) e o teste que a cobre (`1da87b1`)], [—], [O teste da pré-visualização falhava antes da correção e passa depois (8/8); _benchmarks_ repetidos em `1da87b1` (`bench/*/RESULTS.md`); testes unitários (35/35) e `regression.py` (19/19) repetidos no código entregue (`464929f`)],
  ),
)

== Análise crítica

A IA foi uma ferramenta de apoio, útil sobretudo em trabalho extenso e fácil de verificar: percorrer os quatro serviços do
caminho de carregamento, escrever o código de _streaming_ e os seus casos de erro, e preparar os _scripts_ de medição e
os cenários. Nada foi aceite sem verificação: cada alteração passou por testes unitários, pela regressão e pelas
medições, e os números do relatório podem ser recalculados a partir dos CSV.

Essa verificação mostrou que o apoio não dispensa a equipa. A primeira versão do DA-1 não apagava o ficheiro temporário
quando o cliente cancelava o upload e deixava o perfil anónimo sem limite antecipado; os dois casos foram reproduzidos com
um teste que falha antes da correção e passa depois. A validação final da equipa encontrou uma regressão na
pré-visualização de imagens em projetos mistos, que os cenários de medição não cobriam. E as duas falhas mais visíveis
para o utilizador (a mensagem «sem ligação» quando o vídeo excede o limite do plano e a falta de progresso ao criar um
projeto) só apareceram quando a equipa usou a aplicação no _browser_.

Na reflexão da equipa, faríamos de outra forma três coisas: fixar a métrica de cada requisito antes de medir (o critério
do CAND-2 foi alargado depois do resultado final, de forma documentada e aplicada também à base), incluir nos cenários a
pré-visualização de imagens em projetos mistos e testar no _browser_ mais cedo, a cada alteração visível.
