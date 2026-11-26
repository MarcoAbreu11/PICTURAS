#import "../template.typ": *

#heading(numbering: none, outlined: false)[Histórico de versões]

#orientacao[
  Secção opcional. Registem as versões relevantes do documento, uma linha por versão, com a data, um resumo do que mudou e
  as iniciais de quem fez a alteração. Sugere-se acompanhar os marcos do trabalho: entrega do Bloco 1 do Exercício 6,
  do Bloco 2, do Exercício 7 e a versão entregue da Fase 2.

  Este histórico serve a equipa e quem avalia: mostra a evolução do documento e facilita perceber que versão foi
  entregue. Se a equipa usar o controlo de versões (_git_), podem remeter também para os _commits_ correspondentes.
]

#tabela(
  colunas: (1.5cm, 2.3cm, 1fr, 3.5cm),
  [Versão], [Data], [Alterações], [Autores],
  [v1.0], [2026-11-25], [Primeira versão: capítulos 1, 6 a 10 e 12 e anexo A, sobre os dois requisitos (`d5e8c91`)], [MA],
  [v1.1], [2026-11-26], [Validação final: regressão da pré-visualização corrigida, testes e medições repetidos (`6969f42`)], [MA],
  [v1.2], [2026-11-26], [Capa, capítulos 2 a 5 e 11 (Exercícios 6 e 7), `AUTHORS.md` e `grupo.csv` (`cf21012`); referências dos _commits_ após o _rebase_ (`3fcc367`)], [NS, DC],
  [v2.0], [2026-11-27], [Versão entregue da Fase 2: correções após os testes manuais (`acf399d`), figuras do capítulo 2 e histórico de versões], [MA],
)
