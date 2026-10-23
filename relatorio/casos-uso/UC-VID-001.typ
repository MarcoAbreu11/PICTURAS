#import "../template.typ": *

== UC-VID-001: Gerar legendas automáticas

=== Cabeçalho

#tab([Caso de uso UC-VID-001: Gerar legendas automáticas],
  tabela-campos(
    [ID do Caso de Uso], [UC-VID-001],
    [Nome], [Gerar legendas automáticas],
    [Versão], [v1.3],
    [Autor], [Cláudio Ferreira, Marco Abreu, Nelson Sousa, Diogo Campos],
    [Data], [2026-10-23],
    [Objetivo], [Obter, para os vídeos de um projeto, legendas geradas a partir da fala, no idioma original
    (transcrição) ou em inglês (tradução), e vê-las no leitor de vídeo.],
    [Âmbito], [Serviço `projects` (_pipeline_ e serviço de legendas), novo _worker_ `video_subtitles`,
    serviço de armazenamento (faixas WebVTT) e _frontend_ (ferramenta e leitor).],
    [Ator Principal], [Utilizador registado ou premium, dono do projeto ou com permissão de edição],
    [_Stakeholders_ e Interesses], [
      - *Utilizador*: compreender e tornar acessível o conteúdo falado dos seus vídeos, incluindo noutra língua.
      - *Proprietário do sistema*: oferecer uma ferramenta avançada de IA que valorize os perfis registado e
        premium, controlando o custo de inferência.
      - *Administrador de Sistema*: a voz é um dado pessoal; o áudio não sai da infraestrutura do PictuRAS.
      - *Equipa de desenvolvimento*: validar uma ferramenta de IA sobre áudio cujo resultado fica associado
        ao vídeo, em vez de gerar um novo ficheiro.
    ],
    [Pré-condições], [
      - O utilizador é dono do projeto ou tem permissão de edição sobre ele.
      - O projeto contém pelo menos um vídeo, carregado e validado.
    ],
    [_Trigger_], [O utilizador pretende legendas para os vídeos de um projeto.],
  ),
)

=== Fluxo Principal

#tab([UC-VID-001: Fluxo principal],
  tabela(
    colunas: (1.2cm, 1fr, 1fr),
    [Passo], [Ação do Ator], [Resposta do Sistema],
    [1], [O utilizador abre um projeto e abre um dos vídeos.], [O sistema reproduz o vídeo e apresenta as
    ferramentas de vídeo.],
    [2], [O utilizador escolhe "Legendas automáticas".], [O sistema apresenta o idioma das legendas
    (Original ou English), o idioma detetado junto de Original mesmo sem essa faixa e as faixas já existentes desse vídeo.],
    [3], [O utilizador escolhe o idioma e guarda a ferramenta.], [O sistema valida a opção e adiciona a
    ferramenta à _pipeline_ do projeto.],
    [4], [O utilizador carrega em "Aplicar".], [O sistema valida a _pipeline_, o perfil e a quota, reserva
    uma operação por vídeo que ainda não tem legendas nesse idioma, cria um trabalho por vídeo e confirma o
    pedido.],
    [5], [—], [O sistema extrai o áudio de cada vídeo, deteta a fala e o idioma predominante e transcreve (ou
    traduz para inglês) a fala, mantendo o estado de cada trabalho atualizado.],
    [6], [—], [O sistema guarda, para cada vídeo, uma faixa de legendas WebVTT associada ao vídeo e o idioma
    detetado, sem alterar o vídeo.],
    [7], [—], [O sistema notifica o fim de cada vídeo e ativa no leitor a faixa acabada de gerar.],
    [8], [O utilizador reproduz o vídeo.], [O sistema mostra as legendas sincronizadas com o vídeo.],
  ),
)

=== Fluxos Alternativos

#tab([UC-VID-001: Fluxos alternativos],
  tabela(
    colunas: (4cm, 1fr),
    [Fluxo], [Descrição (passo de origem: condição → comportamento → retorno)],
    [FA1 – Legendas já existentes], [Passo 4: o vídeo já tem uma faixa nesse idioma, gerada a partir do mesmo
    ficheiro → o sistema reutiliza-a, sem nova geração nem consumo de quota → continua no passo 7.],
    [FA2 – Mostrar, esconder ou trocar faixa], [Passo 2: o utilizador escolhe uma faixa existente ou
    "Desligado" → o sistema mostra ou esconde essa faixa no leitor, sem gerar nada → fim.],
    [FA3 – Vídeo falado em inglês], [Passo 6: o idioma detetado é inglês → a faixa Original e a faixa English
    são a mesma, com uma só geração e um ficheiro físico em qualquer ordem dos pedidos; a interface mostra apenas "Original (Inglês)" → continua no passo 7.],
    [FA4 – Partilha só de leitura], [Passo 2: o utilizador acede por uma partilha de leitura → pode selecionar
    as faixas existentes (FA2), mas não adicionar a ferramenta nem gerar legendas → fim.],
    [FA5 – Projeto com imagens e vídeos], [Passo 4: o projeto contém imagens → o sistema processa apenas os
    vídeos e informa o número de itens ignorados → continua no passo 5.],
    [FA6 – Processamento em segundo plano], [Após o passo 4: o utilizador abandona a página → a geração
    continua; ao regressar, as faixas geradas estão disponíveis no leitor → continua no passo 8.],
  ),
)

=== Exceções

#tab([UC-VID-001: Exceções],
  tabela(
    colunas: (5.2cm, 1fr),
    [Condição], [Comportamento do Sistema],
    [*Exceção 1*: o utilizador é anónimo (passo 2).],
    [2.1 O sistema não deixa adicionar a ferramenta. \
    2.2 O sistema informa que as legendas exigem uma conta registada e propõe iniciar sessão. \
    2.3 O caso de uso termina sem alterações ao projeto.],
    [*Exceção 2*: a quota do utilizador registado não chega para os vídeos (passo 4).],
    [4.1 O sistema não inicia o processamento e não debita operações. \
    4.2 O sistema indica as operações necessárias e as disponíveis. \
    4.3 O caso de uso termina; a ferramenta fica na _pipeline_ para um novo "Aplicar".],
    [*Exceção 3*: o vídeo não tem faixa de áudio (passo 5).],
    [5.1 O sistema termina esse vídeo com a mensagem "O vídeo não tem faixa de áudio". \
    5.2 O sistema não guarda faixa nem idioma e devolve a operação. \
    5.3 Os restantes vídeos continuam no passo 5.],
    [*Exceção 4*: não é detetada fala no áudio (passo 5).],
    [5.1 O sistema termina esse vídeo com a mensagem "Não foi possível detetar fala para gerar legendas". \
    5.2 O sistema devolve a operação. \
    5.3 Os restantes vídeos continuam no passo 5.],
    [*Exceção 5*: a ferramenta é combinada com outras na mesma _pipeline_ (passo 3).],
    [3.1 O sistema recusa adicionar a ferramenta. \
    3.2 O sistema explica que as ferramentas de vídeo têm de ser a única ferramenta do projeto. \
    3.3 Volta ao passo 2, com a _pipeline_ inalterada.],
    [*Exceção 6*: já está a decorrer uma geração para o mesmo vídeo (passo 4).],
    [4.1 O sistema não inicia uma segunda geração para esse vídeo nem debita outra operação. \
    4.2 As faixas existentes continuam disponíveis no leitor. \
    4.3 Os restantes vídeos continuam no passo 5.],
    [*Exceção 7*: a inferência falha (passos 5–6).],
    [5.1 O sistema termina esse vídeo com uma mensagem para tentar novamente. \
    5.2 O sistema não deixa faixa incompleta e devolve a operação. \
    5.3 Os restantes vídeos continuam no passo 5; o utilizador pode voltar a aplicar (passo 4).],
  ),
)

=== Pós-condições

#tabela(
  colunas: (4cm, 1fr),
  [Tipo], [Resultado],
  [Garantia de Sucesso], [Cada vídeo processado tem uma faixa WebVTT no idioma pedido e o idioma detetado
  registado; os vídeos permanecem inalterados.],
  [Garantia Mínima], [Não fica nenhuma faixa incompleta; as operações dos vídeos que falharam são devolvidas;
  os vídeos permanecem inalterados e o utilizador é informado da causa.],
)

=== Regras de Negócio e Restrições

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Regra],
  [RN1], [As legendas são uma faixa separada: o vídeo não é alterado nem recodificado (sem legendas
  "queimadas" na imagem).],
  [RN2], ["Legendas automáticas" é uma ferramenta avançada: o registado consome uma operação por cada geração
  nova (por vídeo e idioma); reutilizar uma faixa existente não consome; o premium não tem limite.],
  [RN3], [O perfil anónimo não tem acesso.],
  [RN4], [No MVP, os idiomas de saída são o idioma original (transcrição) e o inglês (tradução).],
  [RN5], [Cada vídeo tem no máximo uma faixa por idioma; só é gerada de novo se o ficheiro do vídeo mudar.],
  [RN6], [Só o dono e as partilhas de edição geram legendas; as partilhas de leitura apenas selecionam faixas
  existentes. Nos vídeos convertidos, só o dono acede.],
  [RN7], [Os vídeos cortados, convertidos ou copiados não herdam as faixas do vídeo de origem.],
  [RN8], [No MVP, a ferramenta não se combina com outras na mesma _pipeline_.],
  [RN9], [As faixas de legendas são eliminadas com o vídeo, o projeto ou a conta a que pertencem (a voz é um
  dado pessoal).],
)

=== Assunções

#tabela(
  colunas: (1.4cm, 1fr),
  [ID], [Assunção],
  [A1], [A transcrição usa um modelo de reconhecimento de fala executado localmente (faster-whisper "small",
  multilingue, CPU com int8), descarregado uma vez para um volume persistente.],
  [A2], [A qualidade da transcrição depende do modelo e da gravação. Na opção Original o idioma não é escolhido
  pelo utilizador: é o idioma predominante detetado pelo modelo (passo 5, FA3).],
  [A3], [O _worker_ corre numa réplica, por causa da memória ocupada pelo modelo.],
  [A4], [O MVP guarda apenas o idioma predominante devolvido pelo modelo.],
  [A5], [Cancelar o "Aplicar" não interrompe uma inferência já enviada ao _worker_; a faixa fica guardada
  quando terminar.],
  [A6], [Os vídeos chegam ao projeto pelo caso de uso de base "Carregar imagens", alterado para vídeo, onde o
  formato, o tamanho e a duração já são validados (requisitos SUBMIT); este caso de uso não os volta a validar.],
)

=== Questões em Aberto

#tabela(
  colunas: (1.4cm, 1fr, 5cm),
  [ID], [Questão], [Resolução],
  [Q1], [As legendas devem poder ser gravadas na imagem do vídeo (_burn-in_)?], [Fora do MVP (RN1); trabalho
  futuro.],
  [Q2], [Que idiomas de destino suportar?], [Original e inglês (RN4, SUB-001); outros idiomas adiados.],
  [Q3], [O utilizador deve poder editar as legendas?], [Fora do MVP; adiada.],
  [Q4], [A quota conta por vídeo ou por minuto de áudio?], [Por vídeo (RNG-03, QUOTA-001).],
  [Q5], [Que formato de legendas usar?], [WebVTT, o formato nativo do elemento de vídeo dos navegadores
  (SUB-003, SUB-015).],
)
