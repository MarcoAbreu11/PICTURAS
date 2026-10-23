#import "../template.typ": *

== UC-VID-003: Extrair frames de vídeos

=== Cabeçalho

#tab([Caso de uso UC-VID-003: Extrair frames de vídeos],
  tabela-campos(
    [ID do Caso de Uso], [UC-VID-003],
    [Nome], [Extrair frames de vídeos],
    [Versão], [v1.5],
    [Autor], [Diogo Campos, Marco Abreu, Cláudio Ferreira, Nelson Sousa],
    [Data], [2026-10-23],
    [Objetivo], [Obter imagens a partir de frames dos vídeos de um projeto, para as consultar, descarregar ou
    editar com as ferramentas de imagem existentes.],
    [Âmbito], [Serviço `projects` (_pipeline_ e processamento), novo _worker_ `extract_frames`, `users`
    (quota) e _frontend_ (barra de ferramentas e resultados).],
    [Ator Principal], [Utilizador registado ou premium, dono do projeto ou com permissão de edição],
    [_Stakeholders_ e Interesses], [
      - *Utilizador*: obter imagens de momentos de um vídeo e editá-las.
      - *Proprietário do sistema*: reaproveitar as ferramentas de imagem em conteúdos de vídeo e manter o
        modelo de quotas.
      - *Equipa de desenvolvimento*: validar o mecanismo de ferramentas de vídeo na _pipeline_, que as
        restantes ferramentas de vídeo reutilizam.
    ],
    [Pré-condições], [
      - O utilizador é dono do projeto ou tem permissão de edição sobre ele.
      - O projeto contém pelo menos um vídeo, carregado e validado.
    ],
    [_Trigger_], [O utilizador pretende obter imagens a partir dos vídeos de um projeto.],
  ),
)

=== Fluxo Principal

#tab([UC-VID-003: Fluxo principal],
  tabela(
    colunas: (1.2cm, 1fr, 1fr),
    [Passo], [Ação do Ator], [Resposta do Sistema],
    [1], [O utilizador abre um projeto que contém vídeos e abre um dos vídeos.], [O sistema reproduz o vídeo
    e apresenta as ferramentas de vídeo.],
    [2], [O utilizador escolhe "Extrair frames".], [O sistema apresenta o modo (intervalo regular ou frame
    único), o intervalo em segundos ou o instante, e o formato (PNG ou JPEG).],
    [3], [O utilizador escolhe o intervalo regular, define N segundos e o formato, e adiciona a ferramenta.],
    [O sistema adiciona a ferramenta à _pipeline_, mostra a pré-visualização do primeiro frame e indica, por
    vídeo, o número de imagens e as operações que vão ser consumidas.],
    [4], [O utilizador carrega em "Aplicar".], [O sistema valida a _pipeline_, o número de imagens e a quota;
    debita uma operação por vídeo; cria um trabalho por vídeo e confirma o pedido.],
    [5], [—], [O sistema extrai, de cada vídeo, um frame a cada N segundos e atualiza o progresso. As imagens
    do projeto não são processadas.],
    [6], [—], [O sistema guarda as imagens como resultados do projeto, identificadas pelo vídeo e pelo
    instante.],
    [7], [—], [O sistema notifica o utilizador de que o processamento terminou.],
    [8], [O utilizador consulta os resultados.], [O sistema apresenta as imagens, que se podem descarregar ou
    copiar para um novo projeto.],
  ),
)

=== Fluxos Alternativos

#tab([UC-VID-003: Fluxos alternativos],
  tabela(
    colunas: (4cm, 1fr),
    [Fluxo], [Descrição (passo de origem: condição → comportamento → retorno)],
    [FA1 – Frame único], [Passo 3: o utilizador escolhe "frame único" e um instante → o sistema mostra a
    pré-visualização desse instante → passo 4; no passo 6 é guardada uma imagem por vídeo.],
    [FA2 – Formato por omissão], [Passo 3: o utilizador não escolhe o formato → o sistema usa PNG → continua no passo 3.],
    [FA3 – Editar as imagens extraídas], [Passo 8: o utilizador escolhe "Copiar para novo projeto" → o sistema
    cria um projeto "(frames)" com as imagens como imagens normais, às quais se aplicam as ferramentas de
    imagem → fim.],
    [FA4 – Processamento em segundo plano], [Após o passo 4: o utilizador abandona a página → o processamento
    continua; ao regressar, vê o resultado → continua no passo 8.],
    [FA5 – Cancelar processamento], [Após o passo 4: o utilizador cancela → o sistema termina, remove os
    resultados dessa execução e devolve as operações → fim.],
    [FA6 – Projeto com imagens e vídeos], [Passo 4: o projeto contém imagens → são processados apenas os
    vídeos, sem custo pelas imagens, e o utilizador é informado dos itens ignorados → continua no passo 5.],
  ),
)

=== Exceções

#tab([UC-VID-003: Exceções],
  tabela(
    colunas: (5.2cm, 1fr),
    [Condição], [Comportamento do Sistema],
    [*Exceção 1*: o instante é superior à duração de algum vídeo (FA1, passo 4).],
    [4.1 O sistema não inicia nem debita operações. \
    4.2 O sistema indica os vídeos afetados e a sua duração. \
    4.3 Volta ao passo 3, para escolher outro instante.],
    [*Exceção 2*: o intervalo gera, em algum vídeo, mais imagens do que o máximo (passos 3–4).],
    [4.1 O sistema não inicia nem debita operações. \
    4.2 O sistema indica o limite de 100 imagens por vídeo e os vídeos afetados. \
    4.3 Volta ao passo 3, para escolher um intervalo maior.],
    [*Exceção 3*: a ferramenta é combinada com outras na mesma _pipeline_ (passo 3).],
    [3.1 O sistema recusa adicionar a ferramenta. \
    3.2 O sistema explica que a extração tem de ser a única ferramenta do projeto. \
    3.3 Volta ao passo 2, com a _pipeline_ inalterada.],
    [*Exceção 4*: o projeto não contém vídeos (passo 4).],
    [4.1 O sistema não inicia nem debita operações. \
    4.2 O sistema informa que nenhum item é compatível com a ferramenta. \
    4.3 O caso de uso termina.],
    [*Exceção 5*: a quota do registado é insuficiente para os vídeos (passo 4).],
    [4.1 O sistema não inicia o processamento e não debita operações. \
    4.2 O sistema indica as operações necessárias e as disponíveis. \
    4.3 O caso de uso termina; a ferramenta fica na _pipeline_ para um novo "Aplicar".],
    [*Exceção 6*: um vídeo está corrompido (passo 5).],
    [5.1 O sistema marca esse vídeo como falhado e remove as imagens parciais. \
    5.2 O sistema devolve a operação desse vídeo. \
    5.3 Os restantes vídeos continuam no passo 5.],
    [*Exceção 7*: o processamento de um vídeo falha (passos 5–6).],
    [5.1 O sistema remove as imagens parciais e devolve a operação. \
    5.2 O sistema informa a causa. \
    5.3 Mantém os resultados dos vídeos concluídos e os restantes continuam no passo 5.],
    [*Exceção 8*: o utilizador é anónimo (passo 2).],
    [2.1 O sistema não deixa adicionar a ferramenta. \
    2.2 O sistema informa que a extração exige uma conta registada e propõe iniciar sessão. \
    2.3 O caso de uso termina sem alterações ao projeto.],
  ),
)

=== Pós-condições

#tabela(
  colunas: (4cm, 1fr),
  [Tipo], [Resultado],
  [Garantia de Sucesso], [As imagens estão nos resultados do projeto, identificadas pelo vídeo e pelo
  instante; foi debitada uma operação por vídeo processado (registado); os originais estão inalterados.],
  [Garantia Mínima], [Não ficam imagens incompletas, as operações dos vídeos não concluídos são devolvidas, os
  originais estão inalterados e o utilizador é informado.],
)

=== Regras de Negócio e Restrições

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Regra],
  [RN1], [A extração não altera os vídeos originais.],
  [RN2], ["Extrair frames" é uma ferramenta avançada: para o registado, consome uma operação por vídeo
  processado.],
  [RN3], [O premium não tem limite diário de operações.],
  [RN4], [O perfil anónimo não pode usar ferramentas avançadas, incluindo esta.],
  [RN5], [Existe um número máximo de imagens por vídeo em cada extração.],
  [RN6], [No MVP, a extração não se combina com outras ferramentas na mesma _pipeline_.],
  [RN7], [As imagens extraídas, quando copiadas para um projeto, seguem as regras das imagens carregadas.],
  [RN8], [Só o dono e as partilhas de edição adicionam e aplicam a ferramenta.],
)

=== Assunções

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Assunção],
  [A1], [Os vídeos chegam ao projeto pelo caso de uso de base "Carregar imagens", alterado para vídeo, onde o
  formato, o tamanho e a duração já são validados (requisitos SUBMIT); este caso de uso não os volta a validar.],
  [A2], [As imagens extraídas têm a resolução original do vídeo.],
  [A3], [As ferramentas de imagem existentes funcionam sobre as imagens extraídas sem alterações.],
  [A4], [A duração e a resolução de cada vídeo ficam guardadas no carregamento.],
  [A5], [Os resultados seguem a regra existente (RNG-08); para os editar, copiam-se para um novo projeto.],
  [A6], [A extração é executada por um _worker_ com FFmpeg e fila RabbitMQ própria.],
  [A7], [No MVP, uma falha não é retomada automaticamente.],
  [A8], [Um limite de 100 imagens por vídeo cobre os usos previstos no MVP.],
)

=== Questões em Aberto

#tabela(
  colunas: (1.4cm, 1fr, 5cm),
  [ID], [Questão], [Resolução],
  [Q1], [Qual o número máximo de imagens por extração?], [100 por vídeo (†) (FRAME-015, DQ-015).],
  [Q2], [Que formatos de imagem suportar?], [PNG e JPEG, PNG por omissão (FRAME-010).],
  [Q3], [Agrupar as imagens numa pasta ou ficheiro `.zip`?], [O PictuRAS não tem pastas; ficam nos
  resultados, descarregáveis, e copiáveis para um projeto (RESULT-003).],
  [Q4], [A extração conta como uma ou várias operações?], [Uma por vídeo (RNG-03, QUOTA-001).],
  [Q5], [Qual a duração máxima de vídeo?], [A do perfil no carregamento (RNG-02).],
  [Q6], [Os resultados devem expirar?], [Regra existente; cópias mantidas até eliminação (RESULT-004).],
  [Q7], [Os pedidos pendentes contam para a quota?], [Sim: débito no pedido, devolução em falha ou
  cancelamento (QUOTA-001, QUOTA-002).],
  [Q8], [Limites diferentes entre registado e premium?], [Sim, no carregamento (RNG-02).],
  [Q9], [Encadear a extração com ferramentas de imagem?], [Fora do MVP (RNG-06); trabalho futuro, com
  capacidades `{ accepts, produces }`.],
  [Q10], [Escolher apenas alguns vídeos do projeto?], [Fora do MVP (PIPE-006); trabalho futuro.],
)
