#import "../template.typ": *

== UC-VID-004 — Desfocar caras de um vídeo

=== Cabeçalho

#tab([Caso de uso UC-VID-004 — Desfocar caras de um vídeo],
  tabela-campos(
    [ID do Caso de Uso], [UC-VID-004],
    [Nome], [Desfocar caras de um vídeo],
    [Versão], [v1.3],
    [Autor], [Diogo Campos, Marco Abreu, Cláudio Ferreira, Nelson Sousa],
    [Data], [2026-10-19],
    [Objetivo], [Obter, a partir dos vídeos de um projeto, novos vídeos em que as caras detetadas aparecem
    desfocadas ou pixelizadas.],
    [Âmbito], [Serviço `projects` (_pipeline_ e processamento), novo _worker_ `blur_faces` e _frontend_
    (barra de ferramentas e resultados).],
    [Ator Principal], [Utilizador registado ou premium, dono do projeto ou com permissão de edição],
    [_Stakeholders_ e Interesses], [
      - *Utilizador*: partilhar vídeos sem expor a identidade das pessoas filmadas.
      - *Proprietário do sistema*: oferecer uma ferramenta avançada de vídeo alinhada com a privacidade, que
        valorize os perfis registado e premium.
      - *Administrador de Sistema*: os vídeos com pessoas são dados pessoais; o processamento é local.
      - *Equipa de desenvolvimento*: validar o processamento de vídeo com visão computacional (deteção de caras
        a cada 3 frames e desfocagem de todos os frames).
    ],
    [Pré-condições], [
      - O utilizador tem sessão iniciada com perfil registado ou premium.
      - O utilizador é dono do projeto ou tem permissão de edição sobre ele.
      - O projeto contém pelo menos um vídeo, carregado e validado.
      - O utilizador registado tem operações disponíveis.
    ],
    [_Trigger_], [O utilizador pretende anonimizar as caras presentes nos vídeos de um projeto.],
  ),
)

=== Fluxo Principal

#tab([UC-VID-004 — Fluxo principal],
  tabela(
    colunas: (1.2cm, 1fr, 1fr),
    [Passo], [Ação do Ator], [Resposta do Sistema],
    [1], [O utilizador abre um projeto que contém vídeos e abre um dos vídeos.], [O sistema reproduz o vídeo
    e apresenta as ferramentas de vídeo.],
    [2], [O utilizador escolhe "Desfocar caras".], [O sistema apresenta o tipo de anonimização (desfocagem por
    omissão) e a intensidade.],
    [3], [O utilizador define a intensidade e guarda a ferramenta.], [O sistema valida as opções e adiciona a
    ferramenta à _pipeline_.],
    [4], [O utilizador carrega em "Aplicar".], [O sistema valida a _pipeline_, o perfil e a quota, debita as
    operações do registado, cria um trabalho por vídeo e confirma o pedido.],
    [5], [—], [O sistema analisa os frames de cada vídeo, deteta as caras (a cada 3 frames, reutilizando as
    caixas nos intermédios — A9) e aplica a desfocagem nas regiões detetadas em todos os frames, atualizando o
    progresso. As imagens do projeto não são processadas.],
    [6], [—], [O sistema gera, para cada vídeo, um novo vídeo com a mesma duração e o áudio do original.],
    [7], [—], [O sistema guarda os novos vídeos como resultados, com o nome do vídeo de origem, e notifica o
    utilizador.],
    [8], [O utilizador consulta os resultados.], [O sistema apresenta os vídeos anonimizados, prontos a
    reproduzir e a descarregar.],
  ),
)

=== Fluxos Alternativos

#tab([UC-VID-004 — Fluxos alternativos],
  tabela(
    colunas: (4cm, 1fr),
    [Fluxo], [Descrição (passo de origem: condição → comportamento → retorno)],
    [FA1 – Pixelização], [Passo 3: o utilizador escolhe a pixelização → é aplicada às regiões das caras →
    passo 3.],
    [FA2 – Pré-visualização de um frame], [Passo 3: o utilizador pede a pré-visualização → o sistema processa
    apenas um frame do vídeo aberto e mostra-o anonimizado, sem consumir operações → passo 3.],
    [FA3 – Processamento em segundo plano], [Após o passo 4: o utilizador abandona a página → o processamento
    continua; ao regressar, vê o resultado.],
    [FA4 – Nenhuma cara detetada], [Passo 7: num vídeo não foi detetada nenhuma cara → o resultado é guardado
    com um aviso e o utilizador pode mantê-lo ou descartá-lo.],
    [FA5 – Continuar a editar os vídeos anonimizados], [Passo 8: "Copiar para novo projeto" → os vídeos
    anonimizados passam a vídeos normais de um novo projeto.],
    [FA6 – Cancelar processamento], [Após o passo 4: o utilizador cancela → o sistema termina, remove os
    resultados dessa execução e devolve as operações.],
    [FA7 – Projeto com imagens e vídeos], [Passo 4: o projeto contém imagens → são processados e debitados
    apenas os vídeos e o utilizador é informado dos itens ignorados.],
  ),
)

=== Exceções

#tab([UC-VID-004 — Exceções],
  tabela(
    colunas: (1fr, 1fr),
    [Condição], [Comportamento do Sistema],
    [*Exceção 1* — O utilizador é anónimo (passo 2).], [O sistema não permite adicionar a ferramenta e pede
    que inicie sessão.],
    [*Exceção 2* — A quota do registado não chega para os vídeos (passo 4).], [O sistema não inicia e informa
    o utilizador.],
    [*Exceção 3* — A ferramenta é combinada com outras (passo 3).], [O sistema recusa e explica que as
    ferramentas de vídeo têm de ser a única ferramenta do projeto.],
    [*Exceção 4* — O projeto não contém vídeos (passo 4).], [O sistema não inicia e informa que nenhum item é
    compatível.],
    [*Exceção 5* — As opções estão fora dos valores permitidos (passo 3).], [O sistema impede guardar e indica
    os valores permitidos.],
    [*Exceção 6* — Um vídeo está corrompido (passo 5).], [O sistema marca esse vídeo como falhado, devolve a
    operação e continua com os restantes.],
    [*Exceção 7* — O processamento de um vídeo falha (passos 5–6).], [O sistema remove o resultado parcial,
    informa a causa, devolve a operação e mantém os resultados concluídos.],
  ),
)

=== Pós-condições

#tabela(
  colunas: (4cm, 1fr),
  [Tipo], [Resultado],
  [Garantia de Sucesso], [Os vídeos com as caras desfocadas estão nos resultados do projeto, com a duração e
  o áudio dos originais, e os originais permanecem inalterados.],
  [Garantia Mínima], [Não fica nenhum vídeo incompleto, os originais permanecem inalterados, as operações dos
  vídeos não concluídos são devolvidas e o utilizador é informado.],
)

=== Regras de Negócio e Restrições

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Regra],
  [RN1], [A desfocagem não altera o vídeo original; é sempre gerado um novo ficheiro.],
  [RN2], ["Desfocar caras" é uma ferramenta avançada: registado e premium; o registado consome uma operação
  por vídeo processado; o premium não tem limite.],
  [RN3], [Uma operação só fica consumida quando o vídeo é processado com sucesso: é debitada no pedido e
  devolvida em falha ou cancelamento.],
  [RN4], [Os vídeos respeitam os limites do perfil, validados no carregamento.],
  [RN5], [A ferramenta aplica-se apenas a vídeos; as imagens são ignoradas e não consomem operações.],
  [RN6], [O vídeo gerado mantém a duração e o áudio do original.],
  [RN7], [Resultados incompletos não são disponibilizados como válidos.],
  [RN8], [No MVP, a ferramenta não se combina com outras na mesma _pipeline_.],
  [RN9], [Só o dono e as partilhas de edição adicionam e aplicam a ferramenta.],
  [RN10], [As mesmas opções aplicam-se a todos os vídeos do projeto.],
  [RN11], [Todas as caras detetadas são anonimizadas; o utilizador não escolhe caras a manter visíveis.],
)

=== Assunções

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Assunção],
  [A1], [O carregamento e a validação dos vídeos estão fora deste caso de uso (SUBMIT).],
  [A2], [A deteção usa um modelo executado localmente pelo _worker_ (OpenCV, detetor YuNet), sem serviços
  externos.],
  [A3], [O processamento pode demorar em vídeos longos e necessita de estados intermédios.],
  [A4], [A deteção não é garantida para caras de perfil, tapadas ou com menos de 64×64 px.],
  [A5], [Os resultados seguem a regra existente (RNG-08).],
  [A6], [A desfocagem é executada por um _worker_ com OpenCV e FFmpeg e fila RabbitMQ própria.],
  [A7], [No MVP, uma falha não é retomada automaticamente.],
  [A8], [A taxa de deteção é medida num conjunto de teste da equipa, com imagens de licença livre ou de
  pessoas que deram consentimento.],
  [A9], [A deteção corre a cada 3 frames (DQ-021): uma cara que entre no enquadramento, ou que se mova muito
  depressa, entre duas deteções pode ficar visível ou fora da caixa durante até 2 frames (≈ 80 ms a 25 fps).
  A margem à volta da cara (20 % por omissão) atenua o desalinhamento.],
)

=== Questões em Aberto

#tabela(
  colunas: (1.4cm, 1fr, 5cm),
  [ID], [Questão], [Resolução],
  [Q1], [O utilizador pode escolher caras a desfocar ou a manter?], [Fora do MVP; todas as caras (RN11,
  DQ-017).],
  [Q2], [Qual a taxa de deteção mínima aceitável?], [≥ 90 % das caras frontais com ≥ 64×64 px (†)
  (BLUR-023).],
  [Q3], [Desfocar outros elementos, como matrículas?], [Fora do MVP (DQ-017).],
  [Q4], [Deve ser exclusiva do premium?], [Não; registado com quota e premium sem limite (RN2).],
  [Q5], [Qual a duração máxima de vídeo?], [A do perfil no carregamento (RNG-02).],
  [Q6], [Os resultados devem expirar?], [Regra existente; cópias mantidas até eliminação (RESULT-004).],
  [Q7], [Os pedidos pendentes contam para a quota?], [Sim: débito no pedido e devolução em falha ou
  cancelamento (QUOTA-001, QUOTA-002).],
  [Q8], [Encadear a desfocagem com outras ferramentas?], [Não no MVP (RNG-06); copiar para um novo projeto
  (FA5).],
)
