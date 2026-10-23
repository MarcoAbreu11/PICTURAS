#import "../template.typ": *

== UC-VID-005: Converter ou comprimir vídeo

=== Cabeçalho

#tab([Caso de uso UC-VID-005: Converter ou comprimir vídeo],
  tabela-campos(
    [ID do Caso de Uso], [UC-VID-005],
    [Nome], [Converter ou comprimir vídeo],
    [Versão], [v1.4],
    [Autor], [Diogo Campos, Marco Abreu, Cláudio Ferreira, Nelson Sousa],
    [Data], [2026-10-23],
    [Objetivo], [Obter uma nova versão de um vídeo noutro formato e/ou com menor tamanho, mantendo o original.],
    [Âmbito], [Serviço `projects` (_pipeline_, validação, biblioteca), novo _worker_ `video_convert`
    (conversão e estimativa de tamanho) e _frontend_ (ferramenta e resultados).],
    [Ator Principal], [Utilizador registado ou premium, dono do projeto],
    [_Stakeholders_ e Interesses], [
      - *Utilizador*: reproduzir ou partilhar o vídeo em qualquer plataforma e reduzir o tamanho do ficheiro.
      - *Proprietário do sistema*: diferenciar os perfis pela qualidade máxima de saída e incentivar o
        _upgrade_.
      - *Equipa de desenvolvimento*: validar a recodificação de vídeo.
    ],
    [Pré-condições], [
      - O utilizador tem acesso ao projeto (é o dono ou o projeto foi partilhado com ele).
      - O projeto contém pelo menos um vídeo, carregado e validado.
    ],
    [_Trigger_], [O utilizador abre um vídeo e escolhe "Converter / comprimir".],
  ),
)

=== Fluxo Principal

#tab([UC-VID-005: Fluxo principal],
  tabela(
    colunas: (1.2cm, 1fr, 1fr),
    [Passo], [Ação do Ator], [Resposta do Sistema],
    [1], [O utilizador abre um projeto e um dos vídeos.], [O sistema reproduz o vídeo e apresenta as
    ferramentas de vídeo.],
    [2], [O utilizador escolhe "Converter / comprimir".], [O sistema apresenta o vídeo a converter (por
    omissão, o vídeo aberto), os formatos de saída, as resoluções permitidas pelo perfil, a qualidade e os
    perfis predefinidos.],
    [3], [O utilizador escolhe as opções.], [O sistema mostra o tamanho original e uma estimativa do tamanho
    final.],
    [4], [O utilizador guarda a ferramenta e carrega em "Aplicar".], [O sistema valida as opções e o vídeo
    (formato, _codec_, tamanho, duração), debita a operação do registado e confirma o pedido.],
    [5], [—], [O sistema recodifica o vídeo com as opções escolhidas, atualizando o progresso.],
    [6], [—], [O sistema acrescenta o novo vídeo à biblioteca do projeto, ao lado do original, e regista-o
    também como resultado.],
    [7], [O utilizador consulta o resultado.], [O sistema disponibiliza o novo vídeo para reproduzir e
    descarregar e indica o tamanho original e o final.],
  ),
)

=== Fluxos Alternativos

#tab([UC-VID-005: Fluxos alternativos],
  tabela(
    colunas: (4cm, 1fr),
    [Fluxo], [Descrição (passo de origem: condição → comportamento → retorno)],
    [FA1 – Apenas conversão], [Passo 3: o utilizador muda só o formato (ex.: MOV para MP4), mantendo
    "Original" na resolução → o sistema mantém a resolução de origem (até ao limite do perfil) → continua no passo 3.],
    [FA2 – Apenas compressão], [Passo 3: o utilizador mantém o formato e reduz a resolução ou a qualidade → continua no passo 3.],
    [FA3 – Perfis predefinidos], [Passo 2: o utilizador escolhe "Web sharing" (MP4, 720p) ou "Messaging" (MP4,
    480p, qualidade baixa) → as opções são preenchidas → passo 3.],
    [FA4 – Processamento em segundo plano], [Após o passo 4: o utilizador abandona a página → a conversão
    continua; ao regressar, o novo vídeo está na biblioteca → continua no passo 7.],
    [FA5 – Escolher outro vídeo], [Passo 2: o utilizador escolhe outro vídeo do projeto → a estimativa e a
    validação passam a ser feitas para esse vídeo → continua no passo 3.],
    [FA6 – Cancelar processamento], [Após o passo 4: o utilizador cancela → o sistema termina a conversão, não
    acrescenta nenhum vídeo à biblioteca e devolve a operação → fim.],
  ),
)

=== Exceções

#tab([UC-VID-005: Exceções],
  tabela(
    colunas: (5.2cm, 1fr),
    [Condição], [Comportamento do Sistema],
    [*Exceção 1*: resolução superior à permitida pelo perfil (passo 2).],
    [2.1 O sistema não apresenta essa resolução. \
    2.2 O sistema indica o limite do perfil e sugere o _upgrade_ para premium; um pedido direto é recusado. \
    2.3 Continua no passo 3, com as resoluções permitidas.],
    [*Exceção 2*: formato ou _codec_ não suportado (passos 3–4).],
    [4.1 O sistema recusa o vídeo antes de processar e não debita operações. \
    4.2 O sistema indica o motivo e o vídeo. \
    4.3 Volta ao passo 2, para escolher outro vídeo.],
    [*Exceção 3*: o vídeo está corrompido (passo 5).],
    [5.1 O sistema termina a conversão com uma mensagem. \
    5.2 O sistema devolve a operação; nenhum vídeo é acrescentado à biblioteca. \
    5.3 O caso de uso termina.],
    [*Exceção 4*: o ficheiro final seria maior do que o original (passos 3 e 5).],
    [3.1 Com base na estimativa, o sistema avisa e pede confirmação; com confirmação, continua no passo 4. \
    5.1 Sem confirmação, um resultado real maior é descartado e o utilizador é informado. \
    5.2 O caso de uso termina.],
    [*Exceção 5*: quota do registado esgotada (passo 4).],
    [4.1 O sistema não inicia a conversão nem debita operações. \
    4.2 O sistema informa que a quota diária está esgotada. \
    4.3 O caso de uso termina.],
    [*Exceção 6*: o processamento falha (passo 5).],
    [5.1 O sistema remove o resultado parcial; o original fica inalterado. \
    5.2 O sistema informa a causa e devolve a operação. \
    5.3 O caso de uso termina.],
    [*Exceção 7*: utilizador anónimo ou que não é o dono (passo 2).],
    [2.1 O sistema não permite a conversão. \
    2.2 Ao anónimo, propõe iniciar sessão; a um convidado, indica que só o dono converte vídeos (RNG-09). \
    2.3 O caso de uso termina sem alterações ao projeto.],
    [*Exceção 8*: a ferramenta é combinada com outras (passo 4).],
    [4.1 O sistema recusa a ferramenta. \
    4.2 O sistema explica que as ferramentas de vídeo têm de ser a única ferramenta do projeto. \
    4.3 Volta ao passo 2, com a _pipeline_ inalterada.],
  ),
)

=== Pós-condições

#tabela(
  colunas: (4cm, 1fr),
  [Tipo], [Resultado],
  [Garantia de Sucesso], [Existe um novo vídeo na biblioteca do projeto, no formato e qualidade escolhidos,
  com os tamanhos original e final registados; o vídeo original permanece inalterado.],
  [Garantia Mínima], [Em caso de falha, não fica nenhum vídeo incompleto na biblioteca, a operação é devolvida
  e o utilizador é informado.],
)

=== Regras de Negócio e Restrições

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Regra],
  [RN1], [A conversão não altera o vídeo original; é sempre gerado um novo ficheiro.],
  [RN2], [Para o registado, cada conversão concluída consome uma operação (debitada no pedido e devolvida em
  falha ou cancelamento).],
  [RN3], [O premium não tem limite diário de operações.],
  [RN4], [A entrada é MP4 ou MOV com vídeo H.264 e áudio AAC. O tamanho e a duração são os limites do
  carregamento por perfil (RNG-02); antes de converter, o servidor volta a verificar 500 MB e 10 min como
  defesa, para vídeos que não tenham passado pela validação do carregamento.],
  [RN5], [Resolução máxima de saída: 720p para o registado e 1080p para o premium; o vídeo nunca é aumentado.],
  [RN6], [O vídeo gerado mantém a duração (±1 s) e o áudio do original.],
  [RN7], [Só o dono do projeto pode converter e aceder aos vídeos convertidos.],
  [RN8], [A saída é MP4 (H.264/AAC) ou WebM (VP9/Opus).],
  [RN9], [No MVP, a conversão não se combina com outras ferramentas e aplica-se a um vídeo por operação.],
)

=== Assunções

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Assunção],
  [A1], [O vídeo já está na biblioteca do projeto (carregado e validado).],
  [A2], [A recodificação é feita com FFmpeg num _worker_ dedicado.],
  [A3], [A recodificação pode demorar e necessita de estados intermédios.],
  [A4], [A estimativa do tamanho é aproximada, calculada a partir de amostras do vídeo.],
  [A5], [A biblioteca já permite eliminar ficheiros; os vídeos convertidos são eliminados por esse mecanismo.],
  [A6], [Os vídeos do projeto já respeitam os limites do carregamento do perfil; o máximo (premium, 500 MB /
  10 min) coincide com a verificação de defesa da conversão.],
  [A7], [A infraestrutura do MVP suporta 5 conversões em simultâneo; as restantes ficam em fila.],
  [A8], [No MVP, uma falha não é retomada automaticamente.],
)

=== Questões em Aberto

#tabela(
  colunas: (1.4cm, 1fr, 5cm),
  [ID], [Questão], [Resolução],
  [Q1], [Que formatos de saída suportar?], [MP4 e WebM (†) (CONV-046).],
  [Q2], [Qual a resolução máxima por perfil?], [720p registado, 1080p premium (†) (CONV-022, CONV-035).],
  [Q3], [Substituir o original pelo convertido?], [Não; o original é sempre preservado (CONV-036).],
  [Q4], [Devem existir perfis predefinidos?], [Sim, como "Poderia ter" (CONV-011).],
  [Q5], [Qual a duração máxima de vídeo?], [A do perfil no carregamento (RNG-02); a conversão volta a verificar
  10 min como defesa (CONV-037).],
  [Q6], [Os vídeos convertidos devem expirar?], [Não no MVP; mantêm-se na biblioteca até serem eliminados
  (CONV-033).],
  [Q7], [Os pedidos em curso contam para a quota?], [Sim, por débito no pedido; a devolução em falha garante
  que só as conversões concluídas contam (QUOTA-001, QUOTA-002).],
)
