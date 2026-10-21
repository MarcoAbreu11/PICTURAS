#import "../template.typ": *

== UC-VID-002 — Cortar vídeo

=== Cabeçalho

#tab([Caso de uso UC-VID-002 — Cortar vídeo],
  tabela-campos(
    [ID do Caso de Uso], [UC-VID-002],
    [Nome], [Cortar vídeo],
    [Versão], [v1.3],
    [Autor], [Diogo Campos, Marco Abreu, Cláudio Ferreira, Nelson Sousa],
    [Data], [2026-10-18],
    [Objetivo], [Obter novos vídeos com apenas o excerto entre um instante inicial e um instante final
    escolhidos, a partir dos vídeos de um projeto.],
    [Âmbito], [Serviço `projects` (_pipeline_ e processamento), novo _worker_ `trim` e _frontend_ (barra de
    ferramentas, linha temporal e resultados).],
    [Ator Principal], [Utilizador (anónimo, registado ou premium), dono do projeto ou com permissão de edição],
    [_Stakeholders_ e Interesses], [
      - *Utilizador*: remover partes indesejadas de um vídeo sem recorrer a software externo.
      - *Proprietário do sistema*: disponibilizar uma operação de vídeo essencial a todos os perfis, como
        acontece com o recorte de imagem.
      - *Equipa de desenvolvimento*: validar uma ferramenta de vídeo que produz um novo vídeo na _pipeline_
        existente.
    ],
    [Pré-condições], [
      - O utilizador é dono do projeto ou tem permissão de edição sobre ele.
      - O projeto contém pelo menos um vídeo, carregado e validado (formato, tamanho e duração por perfil).
    ],
    [_Trigger_], [O utilizador pretende obter um excerto dos vídeos de um projeto.],
  ),
)

=== Fluxo Principal

#tab([UC-VID-002 — Fluxo principal],
  tabela(
    colunas: (1.2cm, 1fr, 1fr),
    [Passo], [Ação do Ator], [Resposta do Sistema],
    [1], [O utilizador abre um projeto que contém vídeos e abre um dos vídeos.], [O sistema reproduz o vídeo
    e apresenta a barra de ferramentas com as ferramentas de vídeo.],
    [2], [O utilizador escolhe a ferramenta "Cortar vídeo".], [O sistema apresenta a linha temporal do vídeo
    aberto, com a duração total e os marcadores de início e de fim.],
    [3], [O utilizador define o instante inicial e o final e guarda a ferramenta.], [O sistema mostra a
    duração do excerto, indica os vídeos do projeto em que o excerto não cabe e adiciona a ferramenta à
    _pipeline_.],
    [4], [O utilizador carrega em "Aplicar".], [O sistema valida a _pipeline_ e os instantes face à duração
    de cada vídeo, cria um trabalho de processamento por vídeo e confirma o pedido.],
    [5], [—], [O sistema gera, para cada vídeo, um novo vídeo apenas com o excerto e atualiza a percentagem de
    progresso. As imagens do projeto não são processadas.],
    [6], [—], [O sistema guarda os novos vídeos como resultados do projeto, com o nome do vídeo de origem e o
    intervalo cortado.],
    [7], [—], [O sistema notifica o utilizador de que o processamento terminou.],
    [8], [O utilizador consulta os resultados.], [O sistema apresenta os vídeos cortados, prontos a reproduzir
    e a descarregar.],
  ),
)

=== Fluxos Alternativos

#tab([UC-VID-002 — Fluxos alternativos],
  tabela(
    colunas: (4cm, 1fr),
    [Fluxo], [Descrição (passo de origem: condição → comportamento → retorno)],
    [FA1 – Pré-visualização do excerto], [Passo 3: o utilizador pede a pré-visualização → o sistema reproduz,
    num leitor dentro da ferramenta, apenas o intervalo escolhido, sem criar ficheiros → passo 3.],
    [FA2 – Introdução manual de tempos], [Passo 3: o utilizador escreve os instantes no formato hh:mm:ss → o
    sistema atualiza os marcadores → passo 3.],
    [FA3 – Continuar a editar os vídeos cortados], [Passo 8: o utilizador escolhe "Copiar para novo projeto" →
    o sistema cria um projeto com os vídeos cortados como vídeos normais, aos quais se podem aplicar outras
    ferramentas de vídeo.],
    [FA4 – Processamento em segundo plano], [Após o passo 4: o utilizador abandona a página → o processamento
    continua e, ao regressar, o utilizador vê o resultado.],
    [FA5 – Desistir antes de aplicar], [Passos 2–3: o utilizador fecha a ferramenta sem guardar ou repõe os
    valores por omissão → a _pipeline_ não muda e não é criado nenhum ficheiro.],
    [FA6 – Cancelar processamento], [Após o passo 4: o utilizador cancela → o sistema termina o
    processamento e remove os resultados dessa execução.],
    [FA7 – Projeto com imagens e vídeos], [Passo 4: o projeto contém imagens → são processados apenas os
    vídeos e o utilizador é informado do número de itens ignorados.],
  ),
)

=== Exceções

#tab([UC-VID-002 — Exceções],
  tabela(
    colunas: (1fr, 1fr),
    [Condição], [Comportamento do Sistema],
    [*Exceção 1* — O instante inicial é maior ou igual ao final (passo 3).], [O sistema impede guardar a
    ferramenta e informa o utilizador.],
    [*Exceção 2* — O excerto tem menos de 1 s (passo 3).], [O sistema impede guardar a ferramenta e indica a
    duração mínima.],
    [*Exceção 3* — O instante final ultrapassa a duração de algum vídeo (passos 3–4).], [O sistema não inicia
    o processamento e indica os vídeos afetados e a sua duração.],
    [*Exceção 4* — A ferramenta é combinada com outras na mesma _pipeline_ (passo 3).], [O sistema recusa
    adicionar a ferramenta e explica que o corte tem de ser a única ferramenta do projeto.],
    [*Exceção 5* — O projeto não contém vídeos (passo 4).], [O sistema não inicia o processamento e informa
    que nenhum item é compatível.],
    [*Exceção 6* — Um vídeo está corrompido ou não pode ser descodificado (passo 5).], [O sistema marca esse
    vídeo como falhado, remove o resultado parcial e continua com os restantes.],
    [*Exceção 7* — O processamento de um vídeo falha (passos 5–6).], [O sistema remove o resultado parcial,
    informa a causa e mantém os resultados dos vídeos concluídos; o original fica inalterado.],
  ),
)

=== Pós-condições

#tabela(
  colunas: (4cm, 1fr),
  [Tipo], [Resultado],
  [Garantia de Sucesso], [Os vídeos cortados estão nos resultados do projeto, com a duração do excerto, e os
  originais permanecem inalterados.],
  [Garantia Mínima], [Em caso de falha ou cancelamento, não fica nenhum vídeo incompleto nos resultados, os
  originais permanecem inalterados e o utilizador é informado.],
)

=== Regras de Negócio e Restrições

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Regra],
  [RN1], [O corte não altera o vídeo original; é sempre gerado um novo ficheiro.],
  [RN2], ["Cortar vídeo" é uma ferramenta básica: não consome operações e está disponível para os perfis
  anónimo, registado e premium.],
  [RN3], [Os vídeos respeitam os limites de duração e tamanho do perfil, validados no carregamento.],
  [RN4], [A ferramenta aplica-se apenas a vídeos; as imagens do projeto são ignoradas.],
  [RN5], [O instante inicial é inferior ao final, o excerto tem pelo menos 1 s e o final não ultrapassa a
  duração de nenhum vídeo do projeto.],
  [RN6], [Resultados incompletos não são disponibilizados como válidos.],
  [RN7], [No MVP, cada operação corta um único excerto e o corte não se combina com outras ferramentas.],
  [RN8], [Só o dono e as partilhas de edição adicionam e aplicam a ferramenta; com permissão de leitura,
  apenas se consultam os resultados.],
  [RN9], [O mesmo intervalo aplica-se a todos os vídeos do projeto.],
)

=== Assunções

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Assunção],
  [A1], [O carregamento e a validação dos vídeos estão fora deste caso de uso (SUBMIT).],
  [A2], [A duração de cada vídeo fica guardada no carregamento e permite validar os instantes antes de
  processar.],
  [A3], [O corte pode demorar em vídeos longos e necessita de estados intermédios.],
  [A4], [Para o MVP, apenas é suportado um excerto por operação.],
  [A5], [Os resultados seguem a regra existente (RNG-08); para os manter, copiam-se para um novo projeto
  (FA3).],
  [A6], [O corte é executado por um _worker_ com FFmpeg, alimentado por uma fila RabbitMQ própria.],
  [A7], [No MVP, uma falha não é retomada automaticamente: o utilizador volta a aplicar.],
  [A8], [Uma precisão de corte de ±1 s é aceitável no MVP.],
)

=== Questões em Aberto

#tabela(
  colunas: (1.4cm, 1fr, 5cm),
  [ID], [Questão], [Resolução],
  [Q1], [Cortar vários excertos e juntá-los numa só operação?], [Fora do MVP; um excerto por operação
  (RN7, TRIM-023).],
  [Q2], [Qual a precisão mínima do corte?], [±1 s no MVP; 1 frame em produção (†) (TRIM-022, DQ-016).],
  [Q3], [O novo vídeo mantém a qualidade original ou é recodificado?], [Mantém o contentor e é recodificado
  com os codecs habituais desse contentor, o que garante a precisão (COMP-002, DQ-013).],
  [Q4], [Deve existir uma duração mínima de excerto?], [1 s (†) (TRIM-034).],
  [Q5], [Qual a duração máxima de vídeo?], [A do perfil no carregamento (RNG-02); o corte não acrescenta
  limites.],
  [Q6], [Os resultados devem expirar?], [Seguem a regra existente; os vídeos copiados mantêm-se até serem
  eliminados (RNG-08, RESULT-004).],
  [Q7], [Os pedidos pendentes contam para a quota?], [Não se aplica: o corte não consome operações (RN2).],
  [Q8], [O corte pode ser seguido de outras ferramentas na mesma _pipeline_?], [Não no MVP (RNG-06); copiar
  para um novo projeto (FA3).],
  [Q9], [Intervalos diferentes por vídeo?], [Não no MVP (RN9); adiada para a Fase 2.],
)
