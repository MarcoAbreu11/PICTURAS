#import "../template.typ": *

// Uma linha de requisito funcional: ID, requisito, prioridade, Novo/Alt, origem, justificação, critério.
#let rf(..c) = c.pos()
// Uma linha de requisito não funcional: ID, requisito, ISO/IEC 25010, alvo, prioridade, origem, critério.
#let rnf(..c) = c.pos()

// 5.1 e 5.2 em páginas na horizontal (tabelas largas).
#paisagem[
= Especificação de Requisitos do Sistema (ERS)

Catálogo único dos requisitos das cinco funcionalidades de vídeo, ordenado por ID. Os requisitos comuns a
várias funcionalidades têm um prefixo de área (SUBMIT, PIPE, STATUS, QUOTA, RESULT e, nos não funcionais, REL,
SEC, PERF, PORT, MAINT, COMP e OUTPUT) e aparecem uma só vez, com todas as origens; a secção 5.4 indica os
requisitos individuais que cada um substitui. Valores marcados com (†) são propostas da equipa. *Novo/Alt*:
NOVO = não existia no PictuRAS; ALT = altera um comportamento existente, com o elemento de base afetado
(UC04: aplicar ferramentas ao projeto; "Carregar imagens" e visualização dos itens: casos de uso de base sem
número nos documentos de base; RF45/UC07: partilha; RF64: sugestão de _upgrade_; RNF48: limite diário; T-01/T-02/T-07: tarefas de base sobre cancelamento, mensagens de erro e limite de operações).

== Requisitos Funcionais

#tab([Requisitos funcionais],
  tabela(
    colunas: (2.5cm, 1fr, 1.4cm, 1.4cm, 3cm, 3.6cm, 4.6cm),
    tamanho: 8pt,
    [ID], [Requisito], [Prioridade], [Novo/ Alt], [Origem], [Justificação], [Critério de aceitação],
    ..rf([BLUR-002], [O sistema deve apresentar as opções da desfocagem de caras: tipo de anonimização e
      intensidade.], must, [NOVO], [UC-VID-004, passo 2],
      [A intensidade determina o grau de anonimização.],
      [Dado a ferramenta aberta, então surgem o tipo (desfocagem por omissão) e a intensidade entre 1 e 10 (†).]),
    ..rf([BLUR-004], [O sistema deve detetar as caras presentes nos frames de cada vídeo.], must, [NOVO],
      [UC-VID-004, passo 5; UC-VID-004/A9; DQ-017, DQ-021], [Sem deteção não há o que desfocar.],
      [Dado um vídeo com uma cara frontal, então a cara é detetada nos frames onde aparece.]),
    ..rf([BLUR-005], [O sistema deve desfocar as regiões de todas as caras detetadas, sem alterar o resto do
      frame.], must, [NOVO], [UC-VID-004, passo 5; UC-VID-004/RN11], [Núcleo funcional do caso de uso.],
      [Dado uma cara detetada, então a sua região aparece desfocada e o resto do frame não muda.]),
    ..rf([BLUR-009], [O sistema deve permitir escolher entre desfocagem e pixelização das caras.], should,
      [NOVO], [UC-VID-004/FA1], [Algumas situações pedem pixelização.],
      [Dado a escolha pixelização, então as caras aparecem pixelizadas no vídeo gerado.]),
    ..rf([BLUR-010], [O sistema deve mostrar um frame do vídeo aberto com a anonimização aplicada antes de
      processar o vídeo completo, sem consumir operações.], should, [ALT (UC04)], [UC-VID-004/FA2; DQ-017],
      [Evita processar o vídeo completo com opções inadequadas.],
      [Dado o pedido de pré-visualização, então surge um frame anonimizado e a quota não muda.]),
    ..rf([BLUR-013], [O sistema deve informar o utilizador quando não é detetada nenhuma cara num vídeo.],
      must, [NOVO], [UC-VID-004/FA4; DQ-017], [Pode indicar falha de deteção ou vídeo sem pessoas.],
      [Dado um vídeo sem caras, quando termina, então o seu resultado surge com o aviso "nenhuma cara detetada".]),
    ..rf([BLUR-014], [O sistema deve permitir manter ou descartar o resultado de um vídeo em que não foi
      detetada nenhuma cara.], should, [ALT (UC04)], [UC-VID-004/FA4; DQ-017],
      [Evita guardar um vídeo quase igual ao original.],
      [Dado o aviso, quando escolhe "Descartar", então esse resultado sai e os restantes mantêm-se.]),
    ..rf([BLUR-050], [O sistema deve impedir guardar a desfocagem com opções fora dos valores permitidos,
      indicando esses valores.], must, [NOVO], [UC-VID-004/Exceção 5],
      [Evita pedidos que o _worker_ não consegue processar.],
      [Dado a intensidade 15, então guardar está bloqueado com a indicação "1 a 10"; com 10 é aceite.]),
    ..rf([CONV-002], [O sistema deve apresentar apenas as resoluções de saída permitidas pelo perfil do
      utilizador.], must, [NOVO], [UC-VID-005, passo 2; UC-VID-005/RN5],
      [Diferencia os perfis pela qualidade de saída.],
      [Dado um registado, então 1080p não surge; dado um premium, então surge.]),
    ..rf([CONV-003], [O sistema deve mostrar uma estimativa do tamanho do vídeo final depois de escolhidas as
      opções.], must, [NOVO], [UC-VID-005, passo 3; UC-VID-005/A4],
      [Permite decidir com base no tamanho final.],
      [Dado opções escolhidas, então surgem o tamanho original e o estimado.]),
    ..rf([CONV-005], [O sistema deve recodificar o vídeo com o formato, a resolução e a qualidade escolhidos.],
      must, [NOVO], [UC-VID-005, passo 5], [Núcleo funcional do caso de uso.],
      [Dado WebM a 360p, então o ficheiro gerado é WebM (VP9/Opus) com altura ≤ 360.]),
    ..rf([CONV-006], [O sistema deve acrescentar o vídeo convertido à biblioteca do projeto, ao lado do
      original, com um nome derivado do original.], must, [ALT (UC04)],
      [UC-VID-005, passo 6; UC-VID-005, pós-condição de sucesso; DQ-018],
      [O vídeo convertido é um novo item que o utilizador quer guardar e reutilizar.],
      [Dado a conversão de aula.mp4 para WebM, então a biblioteca contém aula.mp4 e aula_converted.webm.]),
    ..rf([CONV-008], [O sistema deve indicar o tamanho original e o tamanho final do vídeo convertido.],
      must, [NOVO], [UC-VID-005, passo 7], [Permite verificar o ganho de espaço.],
      [Dado o resultado, então surgem os dois tamanhos.]),
    ..rf([CONV-009], [O sistema deve permitir alterar apenas o formato, mantendo a resolução de origem.],
      must, [NOVO], [UC-VID-005/FA1], [Cobre a necessidade só de compatibilidade.],
      [Dado MOV para MP4 com resolução "Original", então a altura de saída é a de origem (até ao limite do perfil).]),
    ..rf([CONV-010], [O sistema deve permitir reduzir apenas a resolução ou a qualidade, mantendo o formato.],
      must, [NOVO], [UC-VID-005/FA2], [Cobre a necessidade só de tamanho.],
      [Dado MP4 e a redução para 480p, então o resultado é MP4 com altura 480.]),
    ..rf([CONV-011], [O sistema deve permitir escolher um perfil predefinido de conversão.], could, [NOVO],
      [UC-VID-005/FA3; UC-VID-005/Q4], [Facilita casos comuns de partilha.],
      [Dado "Web sharing", então as opções passam a MP4, 720p, qualidade média.]),
    ..rf([CONV-014], [O sistema deve recusar resoluções acima do limite do perfil e sugerir o _upgrade_ para
      premium.], must, [ALT (RF64)], [UC-VID-005/Exceção 1; UC-VID-005/RN5],
      [Aplica o limite do perfil e incentiva o _upgrade_.],
      [Dado um registado, quando pede 1080p, então é recusado com "Upgrade to Premium".]),
    ..rf([CONV-015], [O sistema deve recusar converter vídeos que não sejam MP4 ou MOV com vídeo H.264 e
      áudio AAC (†), indicando o vídeo.], must, [NOVO], [UC-VID-005/Exceção 2; UC-VID-005/RN4; DQ-018],
      [Protege o processamento de ficheiros que não está preparado para converter.],
      [Dado um MP4 sem áudio AAC, quando aplica, então é recusado com o nome do vídeo.]),
    ..rf([CONV-017], [O sistema deve avisar e pedir confirmação quando o tamanho estimado é maior do que o
      original e, sem confirmação, descartar um resultado real maior.], should, [NOVO],
      [UC-VID-005/Exceção 4], [Evita que a compressão aumente o ficheiro sem o utilizador saber.],
      [Dado um resultado maior sem confirmação, então não é guardado e surge a causa; com confirmação, é guardado.]),
    ..rf([CONV-022], [O sistema deve limitar a 720p (†) a resolução de saída dos utilizadores registados.],
      must, [NOVO], [UC-VID-005/RN5; UC-VID-005/Q2; DQ-018], [Restrição de perfil.],
      [Dado um registado, então nenhum vídeo gerado excede 720p.]),
    ..rf([CONV-026], [O sistema deve voltar a verificar, antes de converter, que o vídeo não excede 500 MB (†),
      recusando-o caso contrário.], must,
      [NOVO], [UC-VID-005/RN4; DQ-018; DA-09], [Defesa no servidor para vídeos que não passaram pela validação
      do carregamento (e.g., itens antigos sem metadados).],
      [Dado 501 MB, então é recusado com o limite; com 500 MB é aceite.]),
    ..rf([CONV-033], [O sistema deve manter o vídeo convertido na biblioteca até o utilizador o eliminar,
      mesmo depois de nova execução ou de remover a ferramenta.], must, [NOVO],
      [UC-VID-005, pós-condição de sucesso; UC-VID-005/Q6; DQ-018],
      [Não perder trabalho do utilizador.],
      [Dado um vídeo convertido, quando a ferramenta é removida, então continua na biblioteca.]),
    ..rf([CONV-035], [O sistema deve permitir aos utilizadores premium resoluções de saída até 1080p (†).],
      must, [NOVO], [UC-VID-005, passo 2; UC-VID-005/RN5; DQ-018], [Valor verificável da diferenciação.],
      [Dado um premium, quando escolhe 1080p, então é aceite.]),
    ..rf([CONV-036], [O sistema deve manter o vídeo original na biblioteca depois da conversão.], must,
      [NOVO], [UC-VID-005/RN1; UC-VID-005/Q3], [Evita perda irreversível do original.],
      [Dado uma conversão concluída, então a biblioteca tem o original e o novo vídeo.]),
    ..rf([CONV-037], [O sistema deve voltar a verificar, antes de converter, que o vídeo não excede 10 min (†),
      recusando-o caso contrário.], must,
      [NOVO], [UC-VID-005/RN4; DQ-018; DA-09], [Defesa no servidor para vídeos que não passaram pela validação
      do carregamento.],
      [Dado 11 min, então é recusado com o limite; com 10 min é aceite.]),
    ..rf([CONV-047], [O sistema deve permitir escolher o vídeo do projeto a converter e aplicar a conversão
      apenas a esse vídeo.], must, [NOVO], [UC-VID-005, passo 2; UC-VID-005/FA5; UC-VID-005/RN9],
      [Cada conversão produz um item na biblioteca; converter todos seria raramente pretendido.],
      [Dado 2 vídeos e o segundo escolhido, quando aplica, então só esse é convertido.]),
    ..rf([FRAME-002], [O sistema deve apresentar os modos de extração "intervalo regular" e "frame único".],
      must, [NOVO], [UC-VID-003, passo 2], [Cobrem o uso em série e o uso pontual.],
      [Dado a ferramenta aberta, então os dois modos estão disponíveis.]),
    ..rf([FRAME-003], [O sistema deve permitir indicar um instante do vídeo no modo frame único.], must,
      [NOVO], [UC-VID-003/FA1], [Define o frame a extrair.],
      [Dado o modo frame único, quando indica 00:12, então o parâmetro fica guardado.]),
    ..rf([FRAME-004], [O sistema deve mostrar a pré-visualização do frame do instante escolhido ou, no modo
      intervalo, do primeiro frame a extrair.], must, [ALT (UC04)], [UC-VID-003, passo 3; UC-VID-003/FA1],
      [A pré-visualização existente só tratava imagens.],
      [Dado o instante 00:12, quando pede a pré-visualização, então vê esse frame.]),
    ..rf([FRAME-006], [O sistema deve extrair como imagem o frame de cada instante calculado.], must, [NOVO],
      [UC-VID-003, passo 5; UC-VID-003/FA1], [Núcleo funcional do caso de uso.],
      [Dado o instante 00:12, então é criada uma imagem desse frame para cada vídeo.]),
    ..rf([FRAME-007], [O sistema deve guardar as imagens extraídas como resultados do projeto, várias por
      vídeo.], must, [ALT (UC04)], [UC-VID-003, passo 6; UC-VID-003, pós-condição de sucesso],
      [Até aqui cada item gerava um único resultado.],
      [Dado 6 imagens de um vídeo, então o projeto tem 6 resultados desse vídeo.]),
    ..rf([FRAME-008], [O sistema deve permitir aplicar as ferramentas de imagem às imagens extraídas depois
      de copiadas para um projeto.], must, [ALT (UC04)], [UC-VID-003/FA3; UC-VID-003/A3; DQ-014],
      [Reaproveita as ferramentas atuais.],
      [Dado imagens copiadas, quando aplica binarização, então conclui com sucesso.]),
    ..rf([FRAME-009], [O sistema deve extrair um frame a cada N segundos definidos pelo utilizador.], must,
      [NOVO], [UC-VID-003, passos 3 e 5], [Modo principal do caso de uso.],
      [Dado N = 10 e 60 s, então são extraídas 6 imagens.]),
    ..rf([FRAME-010], [O sistema deve permitir escolher entre PNG e JPEG, usando PNG por omissão.], should,
      [NOVO], [UC-VID-003, passo 3; UC-VID-003/FA2; UC-VID-003/Q2], [Formatos para usos diferentes.],
      [Dado JPEG, então as imagens são JPEG; sem escolha, PNG.]),
    ..rf([FRAME-013], [O sistema deve recusar iniciar quando o instante indicado ultrapassa a duração de algum
      vídeo, indicando os vídeos afetados.], must, [NOVO], [UC-VID-003/Exceção 1],
      [Evita pedir frames inexistentes antes de consumir quota.],
      [Dado vídeos de 10 s e 60 s e o instante 00:30, então é recusado com indicação do vídeo de 10 s.]),
    ..rf([FRAME-014], [O sistema deve indicar o limite e não iniciar quando o intervalo gera, em algum vídeo,
      mais imagens do que o permitido.], must, [NOVO], [UC-VID-003/Exceção 2; UC-VID-003/RN5],
      [Evita extrações desproporcionadas.], [Dado 600 s e N = 5 (120 imagens), então é recusado.]),
    ..rf([FRAME-015], [O sistema deve limitar a 100 (†) as imagens extraídas por vídeo em cada execução.],
      must, [NOVO], [UC-VID-003/RN5; UC-VID-003/Q1; DQ-015], [Protege armazenamento e capacidade.],
      [Dado 101 imagens, então é recusado; com 100, é aceite.]),
    ..rf([FRAME-022], [O sistema deve sujeitar as imagens copiadas às regras das imagens carregadas.], must,
      [ALT (UC04)], [UC-VID-003/RN7], [Tratamento igual ao de uma imagem carregada.],
      [Dado uma imagem copiada, então tem as mesmas permissões, operações e eliminação.]),
    ..rf([FRAME-036], [O sistema deve identificar cada imagem extraída com o nome do vídeo e o instante.],
      should, [NOVO], [UC-VID-003, passo 6; UC-VID-003/FA1], [Reconhecer a origem de cada imagem.],
      [Dado o frame de 12 s de aula.mp4, então o nome contém "aula" e "12s".]),
    ..rf([FRAME-049], [O sistema deve indicar, antes de aplicar, as imagens que vão ser geradas por vídeo e as
      operações que vão ser consumidas.], must, [NOVO], [UC-VID-003, passo 3],
      [Ajustar o intervalo antes de consumir quota.],
      [Dado 60 s e N = 10, então surge "6 imagens, 1 operação".]),
    ..rf([PIPE-001], [O sistema deve apresentar, quando o item aberto é um vídeo, as ferramentas de vídeo na
      barra de ferramentas em vez das de imagem, permitindo adicioná-las à _pipeline_.], must, [ALT (UC04)],
      [UC-VID-001 a 005, passos 1–2; DQ-001], [Ponto de entrada de todas as ferramentas de vídeo.],
      [Dado um vídeo aberto, então surgem as cinco ferramentas de vídeo e não as de imagem.]),
    ..rf([PIPE-002], [O sistema deve iniciar o processamento de uma ferramenta de vídeo apenas quando o
      utilizador carrega em "Aplicar" e a validação é bem-sucedida.], must, [ALT (UC04)],
      [UC-VID-001 a 005, passo 4], [Evita processamentos e consumo de quota por engano.],
      [Dado parâmetros válidos, quando aplica, então inicia; sem "Aplicar", nada é processado.]),
    ..rf([PIPE-003], [O sistema deve processar com uma ferramenta de vídeo apenas os vídeos do projeto e
      informar o número de itens ignorados.], must, [ALT (UC04)],
      [UC-VID-001/FA5; UC-VID-002/FA7; UC-VID-003/FA6; UC-VID-004/FA7; RNG-07; DQ-002],
      [As ferramentas de vídeo não sabem processar imagens.],
      [Dado 2 vídeos e 3 imagens, quando aplica, então são processados 2 itens e informado de 3 ignorados.]),
    ..rf([PIPE-004], [O sistema deve recusar combinar uma ferramenta de vídeo com outras ferramentas na mesma
      _pipeline_.], must, [ALT (UC04)],
      [UC-VID-001/Exc. 5; UC-VID-002/Exc. 4; UC-VID-003/Exc. 3; UC-VID-004/Exc. 3; UC-VID-005/Exc. 8; RNG-06; DQ-003],
      [A _pipeline_ é linear; no MVP cada ferramenta é validada isoladamente e o encadeamento fica fora do âmbito.],
      [Dado o brilho na _pipeline_, quando adiciona uma ferramenta de vídeo, então é recusado; e vice-versa.]),
    ..rf([PIPE-005], [O sistema deve recusar iniciar quando o projeto não contém vídeos compatíveis com a
      ferramenta, informando o utilizador.], must, [ALT (UC04)],
      [UC-VID-002/Exc. 5; UC-VID-003/Exc. 4; UC-VID-004/Exc. 4; RNG-07], [Evita trabalhos vazios.],
      [Dado um projeto só com imagens, quando aplica, então é recusado com mensagem.]),
    ..rf([PIPE-006], [O sistema deve aplicar os mesmos parâmetros da ferramenta de vídeo a todos os vídeos do
      projeto, exceto na conversão, que se aplica ao vídeo escolhido.], should, [ALT (UC04)],
      [UC-VID-002/RN9; UC-VID-003/Q10; UC-VID-004/RN10; UC-VID-005/RN9],
      [As ferramentas da _pipeline_ aplicam os mesmos parâmetros a todos os itens.],
      [Dado 2 vídeos e a pixelização 8, então ambos os resultados têm a mesma intensidade.]),
    ..rf([PIPE-007], [O sistema deve permitir adicionar e aplicar ferramentas de vídeo apenas ao dono do
      projeto e a partilhas com permissão de edição.], must, [ALT (RF45)],
      [UC-VID-001 a 004, pré-condições; UC-VID-002/RN8; UC-VID-003/RN8; UC-VID-004/RN9; RNG-09; DQ-008],
      [Aplica as permissões de partilha existentes.],
      [Dado uma partilha só de leitura, quando adiciona uma ferramenta de vídeo, então recebe erro de permissão.]),
    ..rf([QUOTA-001], [O sistema deve debitar ao utilizador registado uma operação por vídeo processado por
      uma ferramenta de vídeo avançada, no início do processamento, independentemente da duração e do número
      de imagens geradas.], must, [ALT (RNF48, T-07)],
      [UC-VID-001/RN2; UC-VID-003/RN2; UC-VID-004/RN2; UC-VID-005/RN2; RNG-03; DQ-005],
      [Reinterpreta a quota diária para vídeo; o débito no início impede ultrapassá-la com pedidos simultâneos.],
      [Dado um registado com 5 operações e 2 vídeos, quando aplica a extração, então ficam 3.]),
    ..rf([QUOTA-002], [O sistema deve devolver as operações dos vídeos cujo processamento falha e de todos os
      vídeos quando o processamento é cancelado.], must, [ALT (T-07)],
      [UC-VID-001/Exc. 3, 4, 7; UC-VID-003/Exc. 6–7; UC-VID-004/RN3; UC-VID-005/RN2, FA6; RNG-03; DQ-005],
      [Só os sucessos contam; falhas não penalizam o utilizador.],
      [Dado 2 vídeos e uma falha num deles, quando termina, então só 1 operação fica consumida.]),
    ..rf([QUOTA-003], [O sistema deve recusar iniciar quando a quota do registado não chega para os vídeos a
      processar, informando-o.], must, [ALT (T-07)],
      [UC-VID-001/Exc. 2; UC-VID-003/Exc. 5; UC-VID-004/Exc. 2; UC-VID-005/Exc. 5],
      [Aplica a regra de quotas às novas ferramentas.],
      [Dado 6 vídeos e quota inferior a 6, quando aplica, então é recusado e a quota não muda.]),
    ..rf([QUOTA-004], [O sistema não deve aplicar limite diário de operações aos utilizadores premium nas
      ferramentas de vídeo.], must, [ALT (RNF48)],
      [UC-VID-001/RN2; UC-VID-003/RN3; UC-VID-004/RN2; UC-VID-005/RN3; RNG-11],
      [Mantém a vantagem do perfil premium.],
      [Dado um premium com 20 operações no dia, quando aplica, então inicia.]),
    ..rf([QUOTA-005], [O sistema deve impedir utilizadores anónimos de usar ferramentas de vídeo avançadas,
      pedindo que iniciem sessão.], must, [ALT (UC04)],
      [UC-VID-001/Exc. 1; UC-VID-003/RN4, Exc. 8; UC-VID-004/Exc. 1; UC-VID-005/Exc. 7; RNG-04],
      [Regra existente das ferramentas avançadas.],
      [Dado uma sessão anónima, quando adiciona uma ferramenta avançada, então recebe 403 e a _pipeline_ não muda.]),
    ..rf([RESULT-001], [O sistema deve guardar o vídeo produzido por uma ferramenta de vídeo como resultado do
      projeto, com um nome que identifica o vídeo de origem.], must, [ALT (UC04)],
      [UC-VID-002, passo 6; UC-VID-004, passo 7; UC-VID-005, passo 6; DQ-014],
      [O PictuRAS guarda o resultado das ferramentas nos resultados do projeto.],
      [Dado o processamento de aula.mp4, então os resultados contêm um vídeo cujo nome contém "aula".]),
    ..rf([RESULT-002], [O sistema deve permitir reproduzir e descarregar os vídeos resultantes.], must,
      [ALT (UC04)], [UC-VID-002, passo 8; UC-VID-004, passo 8; UC-VID-005, passo 7],
      [O utilizador tem de poder ver e levar o resultado.],
      [Dado um vídeo nos resultados, então reproduz-se no leitor e está incluído na descarga.]),
    ..rf([RESULT-003], [O sistema deve permitir copiar os resultados (imagens ou vídeos) para um novo projeto,
      como itens normais.], must, [ALT (UC04)],
      [UC-VID-002/FA3; UC-VID-003/FA3; UC-VID-004/FA5; DQ-014],
      [Caminho para continuar a editar sem encadeamento na _pipeline_.],
      [Dado 2 vídeos cortados, quando copia, então o novo projeto tem 2 vídeos que aceitam ferramentas de vídeo.]),
    ..rf([RESULT-004], [O sistema deve manter os itens copiados para um projeto até o utilizador os eliminar.],
      must, [NOVO], [UC-VID-002/Q6; UC-VID-003/Q6; UC-VID-004/Q6; RNG-08; DQ-007],
      [Os resultados são substituídos na execução seguinte; as cópias não.],
      [Dado itens copiados há 30 dias, então continuam disponíveis.]),
    ..rf([RESULT-005], [O sistema deve eliminar os ficheiros temporários de processamento até 1 h (†) depois do
      fim do trabalho, com sucesso, falha ou cancelamento.], must, [NOVO],
      [Pós-condições mínimas de UC-VID-001 a 005; RNG-10; DQ-007],
      [Dados pessoais e custo de armazenamento.],
      [Dado um trabalho terminado, quando passa 1 h, então não há ficheiros temporários dele.]),
    ..rf([STATUS-001], [O sistema deve continuar o processamento quando o utilizador abandona a página.], must,
      [ALT (UC04)], [UC-VID-001/FA6; UC-VID-002/FA4; UC-VID-003/FA4; UC-VID-004/FA3; UC-VID-005/FA4],
      [Operações demoradas.], [Dado um processamento em curso, quando fecha e volta, então os resultados surgem no fim.]),
    ..rf([STATUS-002], [O sistema deve apresentar o estado do processamento: em fila, em curso, concluído,
      falhado ou cancelado.], must, [ALT (UC04)],
      [UC-VID-002/A3; UC-VID-003/FA4; UC-VID-004/A3; UC-VID-005/A3; DQ-010],
      [Acompanhar uma operação que não é instantânea.],
      [Dado um pedido à espera de um _worker_, então surge "Em fila"; quando arranca, "Em curso".]),
    ..rf([STATUS-003], [O sistema deve apresentar a percentagem de progresso de cada vídeo em processamento.],
      should, [ALT (UC04)], [UC-VID-002 a 005, passo 5; DQ-010],
      [O estado por si só não permite estimar o tempo restante.],
      [Dado um processamento em curso, então surge uma percentagem entre 0 % e 100 % que não diminui.]),
    ..rf([STATUS-004], [O sistema deve permitir cancelar o processamento em fila ou em curso, removendo os
      resultados dessa execução.], must, [ALT (T-01)],
      [UC-VID-002/FA6; UC-VID-003/FA5; UC-VID-004/FA6; UC-VID-005/FA6; DQ-010],
      [Evita ocupar capacidade e quota sem necessidade.],
      [Dado um processamento em curso, quando cancela, então fica "cancelado" e sem resultados dessa execução.]),
    ..rf([STATUS-005], [O sistema deve notificar o utilizador quando o processamento termina, com sucesso ou
      falha.], should, [ALT (UC04)], [UC-VID-001 a 004, passo 7; UC-VID-005/FA4; DQ-010],
      [Com processamento demorado, o utilizador precisa de saber quando voltar.],
      [Dado um processamento, quando termina, então surge uma notificação com o resultado.]),
    ..rf([STATUS-006], [O sistema deve apresentar, para cada vídeo cujo processamento falha, uma mensagem com
      a causa em linguagem corrente.], must, [ALT (T-02)],
      [UC-VID-001/Exc. 3–4, 7; UC-VID-002/Exc. 7; UC-VID-003/Exc. 7; UC-VID-004/Exc. 7; UC-VID-005/Exc. 6; DQ-006],
      [Perceber se pode repetir ou se o vídeo tem um problema.],
      [Dado uma falha num vídeo, então surge "Falha em «nome do vídeo»" com a causa.]),
    ..rf([STATUS-007], [O sistema deve marcar como falhado o vídeo que não pode ser descodificado e continuar
      com os restantes.], must, [NOVO],
      [UC-VID-002/Exc. 6; UC-VID-003/Exc. 6; UC-VID-004/Exc. 6; UC-VID-005/Exc. 3; DQ-006],
      [Um vídeo problemático não impede os restantes.],
      [Dado um vídeo inválido e um válido, então o inválido falha com mensagem e o válido gera resultado.]),
    ..rf([SUB-001], [O sistema deve permitir escolher o idioma das legendas, Original (transcrição) ou
      English (tradução), e guardar a ferramenta na _pipeline_.], must, [NOVO],
      [UC-VID-001, passos 2–3; UC-VID-001/RN4; UC-VID-001/Q2], [Define o resultado pretendido.],
      [Dado um idioma diferente destes, então é recusado; dado "en", então a ferramenta é guardada.]),
    ..rf([SUB-002], [O sistema deve gerar, ao aplicar, legendas a partir da fala de cada vídeo do projeto, no
      idioma escolhido.], must, [NOVO], [UC-VID-001, passo 5],
      [Núcleo funcional do caso de uso.],
      [Dado um vídeo com fala portuguesa e "Original", então a faixa contém a transcrição em português.]),
    ..rf([SUB-003], [O sistema deve guardar as legendas como uma faixa WebVTT associada ao vídeo, sem alterar
      o vídeo, até este ser eliminado.], must, [NOVO],
      [UC-VID-001, passo 6; UC-VID-001/RN1; UC-VID-001/Q5; RNG-05; DQ-019],
      [As legendas são texto ligado ao vídeo, não um novo ficheiro de média.],
      [Dado a geração concluída, então existe uma faixa `text/vtt` desse vídeo e o vídeo mantém o _hash_.]),
    ..rf([SUB-004], [O sistema deve permitir mostrar, esconder e trocar no leitor as faixas existentes, com
      uma única faixa ativa.], must, [NOVO], [UC-VID-001, passo 8; UC-VID-001/FA2],
      [O utilizador escolhe como vê o vídeo.],
      [Dado duas faixas, quando escolhe English, então só essa fica ativa; "Desligado" esconde-a.]),
    ..rf([SUB-005], [O sistema deve ativar no leitor, no fim do "Aplicar", a faixa gerada em cada vídeo.],
      should, [NOVO], [UC-VID-001, passo 7], [Mostra o resultado sem passos adicionais.],
      [Dado o fim da geração, então o vídeo aberto mostra a nova faixa.]),
    ..rf([SUB-006], [O sistema deve reutilizar uma faixa já gerada para o mesmo vídeo e idioma, sem nova
      geração nem consumo de quota.], must, [NOVO], [UC-VID-001/FA1; UC-VID-001/RN2, RN5; RNG-03; DQ-019],
      [Evita custo e espera repetidos.],
      [Dado uma faixa existente, quando aplica de novo, então a quota não muda.]),
    ..rf([SUB-007], [O sistema deve guardar o idioma predominante detetado e, quando é inglês, usar a mesma
      faixa para Original e English.], should, [NOVO], [UC-VID-001/FA3; UC-VID-001/A4],
      [Evita gerar duas vezes o mesmo texto.],
      [Dado um vídeo em inglês, então Original e English apontam para a mesma faixa.]),
    ..rf([SUB-008], [O sistema deve terminar a geração de um vídeo sem faixa de áudio com a mensagem "O vídeo
      não tem faixa de áudio".], must, [NOVO], [UC-VID-001/Exc. 3], [Causa clara e acionável.],
      [Dado um vídeo sem áudio, então a geração termina com o código 2303 e sem faixa.]),
    ..rf([SUB-009], [O sistema deve terminar a geração com uma mensagem quando não é detetada fala.], must,
      [NOVO], [UC-VID-001/Exc. 4], [Distingue vídeo sem fala de falha do sistema.],
      [Dado um tom sem fala, então termina com o código 2304, sem faixa, e a operação é devolvida.]),
    ..rf([SUB-010], [O sistema deve permitir no máximo uma geração em curso por vídeo, mesmo com pedidos
      concorrentes.], must, [NOVO], [UC-VID-001/Exc. 6; DQ-019],
      [Evita trabalho duplicado e cobranças repetidas.],
      [Dado 12 pedidos simultâneos para o mesmo vídeo, então é iniciada uma só geração.]),
    ..rf([SUB-011], [O sistema deve permitir a partilhas só de leitura selecionar faixas existentes, sem
      gerar legendas.], must, [ALT (RF45)], [UC-VID-001/FA4; UC-VID-001/RN6; RNG-09],
      [Aplica as permissões de partilha às legendas.],
      [Dado uma partilha de leitura, quando pede uma geração, então recebe 403; consulta as faixas.]),
    ..rf([SUB-012], [O sistema deve eliminar as faixas de legendas quando o vídeo, o projeto ou a conta são
      eliminados.], must, [NOVO], [UC-VID-001/RN9; RNG-08; DQ-020],
      [Os textos transcritos são dados pessoais (RGPD).],
      [Dado a eliminação do vídeo, então as chaves das faixas são apagadas do armazenamento.]),
    ..rf([SUBMIT-001], [O sistema deve permitir carregar vídeos MP4, WebM e MOV num projeto, isoladamente ou
      num `.zip`, ao lado das imagens.], must, [ALT ("Carregar imagens")],
      [Pré-condições de UC-VID-001 a 005; RNG-01; DQ-004], [Base de todas as funcionalidades de vídeo.],
      [Dado aula.mp4, clip.webm e clip.mov, então ficam no projeto como vídeos; um ficheiro .avi é recusado.]),
    ..rf([SUBMIT-002], [O sistema deve recusar um vídeo que exceda o tamanho ou a duração máximos do perfil
      de quem o carrega, indicando o limite.], must, [NOVO], [RNG-02; DQ-004],
      [Custo e diferenciação de perfis.],
      [Dado um registado e um vídeo de 70 s, então é recusado com indicação de 60 s.]),
    ..rf([SUBMIT-003], [O sistema deve recusar no carregamento ficheiros de vídeo que não podem ser lidos.],
      must, [NOVO], [Exceções de vídeo corrompido; DQ-004],
      [Evita itens que nenhuma ferramenta consegue processar.],
      [Dado um .mp4 com conteúdo inválido, então é recusado com "Invalid or unreadable video file".]),
    ..rf([SUBMIT-004], [O sistema deve guardar, no carregamento, a duração, a resolução, o tamanho e os codecs
      de cada vídeo.], must, [ALT ("Carregar imagens")],
      [UC-VID-002/A2; UC-VID-003/A4; UC-VID-005, passo 4; DQ-004],
      [Validar instantes, limites e codecs sem reler o vídeo.],
      [Dado um vídeo de 14 s em 1280×720, então o item fica com duração 14 s e 1280×720.]),
    ..rf([SUBMIT-005], [O sistema deve reproduzir os vídeos do projeto no editor e mostrar o primeiro frame na
      grelha.], must, [ALT (visualização dos itens)], [UC-VID-001 a 005, passo 1], [O utilizador tem de ver o vídeo para o editar.],
      [Dado um vídeo no projeto, então a grelha mostra o primeiro frame e o carrossel reproduz com controlos.]),
    ..rf([TRIM-002], [O sistema deve apresentar a linha temporal do vídeo aberto com a duração total.], must,
      [NOVO], [UC-VID-002, passo 2; UC-VID-002/A2], [Escolher os instantes.],
      [Dado um vídeo de 30 s, então surge a linha temporal e 00:30.]),
    ..rf([TRIM-003], [O sistema deve permitir definir os instantes inicial e final na linha temporal.], must,
      [NOVO], [UC-VID-002, passo 3], [Define o excerto.],
      [Dado a linha temporal, quando arrasta os marcadores, então os instantes mudam.]),
    ..rf([TRIM-004], [O sistema deve mostrar a duração do excerto selecionado.], must, [NOVO],
      [UC-VID-002, passo 3], [_Feedback_ antes de guardar.], [Dado 00:10 a 00:40, então surge 00:30.]),
    ..rf([TRIM-006], [O sistema deve gerar, para cada vídeo, um novo vídeo só com o excerto selecionado.],
      must, [NOVO], [UC-VID-002, passo 5], [Núcleo funcional.],
      [Dado 00:10–00:40 e um vídeo de 60 s, então o novo vídeo corresponde a esse intervalo.]),
    ..rf([TRIM-009], [O sistema deve reproduzir, num leitor dentro da ferramenta, apenas o excerto, sem criar
      ficheiros.], should, [NOVO], [UC-VID-002/FA1], [Verificar o excerto antes de aplicar.],
      [Dado 00:10–00:20, então a reprodução começa em 00:10 e para em 00:20.]),
    ..rf([TRIM-010], [O sistema deve permitir introduzir os instantes no formato hh:mm:ss.], should, [NOVO],
      [UC-VID-002/FA2], [Precisão que o arrastar não garante.], [Dado "00:01:30", então o início passa a 90 s.]),
    ..rf([TRIM-013], [O sistema deve permitir desistir antes de aplicar, sem alterar a _pipeline_ nem criar
      ficheiros.], should, [NOVO], [UC-VID-002/FA5], [Desistir sem efeitos.],
      [Dado a ferramenta aberta, quando fecha sem guardar, então a _pipeline_ fica igual.]),
    ..rf([TRIM-014], [O sistema deve impedir guardar o corte quando o instante inicial é maior ou igual ao
      final.], must, [NOVO], [UC-VID-002/Exc. 1; UC-VID-002/RN5], [Instantes incoerentes.],
      [Dado início 00:40 e fim 00:10, então guardar está bloqueado.]),
    ..rf([TRIM-015], [O sistema deve recusar iniciar quando o instante final ultrapassa a duração de algum
      vídeo, indicando os vídeos afetados.], must, [NOVO], [UC-VID-002/Exc. 3; UC-VID-002/RN5, RN9; DQ-016],
      [Evita cortes sobre instantes inexistentes.],
      [Dado vídeos de 10 s e 60 s e fim em 00:30, então é recusado com indicação do vídeo de 10 s.]),
    ..rf([TRIM-023], [O sistema deve processar um único excerto por operação.], must, [NOVO],
      [UC-VID-002/A4; UC-VID-002/RN7; UC-VID-002/Q1], [Mantém o MVP simples.],
      [Dado a ferramenta, então só há um par início/fim.]),
    ..rf([TRIM-034], [O sistema deve impedir guardar o corte quando o excerto tem menos de 1 s (†).], should,
      [NOVO], [UC-VID-002/Exc. 2; UC-VID-002/RN5; DQ-016], [Evita ficheiros sem utilidade.],
      [Dado 0,5 s, então é bloqueado; com 1 s, aceite.]),
    ..rf([TRIM-049], [O sistema deve disponibilizar o corte aos perfis anónimo, registado e premium sem
      consumir operações.], must, [ALT (UC04)], [UC-VID-002/RN2; UC-VID-002/Q7; RNG-03, RNG-04, RNG-11; DQ-005],
      [Ferramenta básica, como o recorte de imagem.],
      [Dado um anónimo, então aplica o corte; dado um registado, então a quota não muda.]),
    ..rf([TRIM-051], [O sistema deve identificar cada vídeo cortado com o nome do vídeo de origem e o
      intervalo.], should, [NOVO], [UC-VID-002, passo 6], [Reconhecer origem e excerto.],
      [Dado o corte 10–40 s de aula.mp4, então o nome contém "aula" e "10-40s".]),
  ),
) <tab-rf>

== Requisitos Não Funcionais e de Qualidade

O *Alvo* indica o valor exigido no MVP e, depois da seta, o alvo de uma solução em produção (referência para
a Fase 2).

#tab([Requisitos não funcionais],
  tabela(
    colunas: (2.5cm, 1fr, 2.7cm, 2.8cm, 1.4cm, 2.8cm, 4.4cm),
    tamanho: 8pt,
    [ID], [Requisito], [ISO/IEC 25010], [Alvo (MVP → produção)], [Prioridade], [Origem], [Critério de aceitação],
    ..rnf([BLUR-023], [O sistema deve detetar as caras frontais com pelo menos 64×64 px num conjunto de teste
      definido pela equipa.], [Adequação Funcional (Correção)], [≥ 90 % (†) → ≥ 98 % (†)], should,
      [UC-VID-004/A4, A8; UC-VID-004/Q2; DQ-017],
      [Dado o conjunto anotado, quando se corre o detetor, então a taxa (IoU ≥ 0,5) cumpre o alvo.]),
    ..rnf([BLUR-041], [O sistema deve concluir a desfocagem em tempo proporcional à duração do vídeo.],
      [Eficiência de Desempenho (Comportamento temporal)], [≤ 3× a duração → ≤ 1×], should,
      [UC-VID-004/A3; DQ-011, DQ-021], [Dado 10 min sem outros trabalhos, então termina em ≤ 30 min.]),
    ..rnf([BLUR-042], [O sistema deve desfocar os vídeos apenas em componentes do PictuRAS, sem os enviar a
      serviços externos.], [Segurança (Confidencialidade)], [Obrigatório], must,
      [UC-VID-004/A2; DQ-020], [Dado um pedido, quando se inspeciona o tráfego do _worker_, então o vídeo não sai da rede interna.]),
    ..rnf([COMP-001], [O sistema deve processar com o corte, a extração, a desfocagem e as legendas vídeos de
      todos os formatos aceites no carregamento.], [Compatibilidade (Interoperabilidade)],
      [MP4, WebM, MOV (H.264, H.265, VP9) → mais formatos (†)], must,
      [UC-VID-002 a 004/A1; RNG-01; DQ-004], [Dado um vídeo de cada formato e codec, então todos geram resultado.]),
    ..rnf([COMP-002], [O sistema deve produzir o vídeo cortado ou anonimizado no contentor do original, com os
      codecs habituais desse contentor (MP4/MOV: H.264 e AAC; WebM: VP9 e Opus).],
      [Compatibilidade (Interoperabilidade)], [Codecs indicados → codecs do original], must,
      [UC-VID-002/Q3; UC-VID-004, passo 6; DQ-013], [Dado um MP4 e um WebM, então os resultados são MP4 H.264/AAC e WebM VP9/Opus (`ffprobe`).]),
    ..rnf([CONV-024], [O sistema deve estimar o tamanho do vídeo convertido com um erro limitado face ao
      tamanho real.], [Adequação Funcional (Correção)], [≤ 20 % (†) → ≤ 10 % (†)], should,
      [UC-VID-005, passo 3; UC-VID-005/A4; DQ-018], [Dado conversões de teste, então a estimativa difere do real no máximo o alvo.]),
    ..rnf([CONV-039], [O sistema deve restringir ao dono do projeto o acesso aos vídeos convertidos e aos
      resultados de uma conversão, mantendo o resto do projeto acessível às partilhas.], [Segurança (Confidencialidade)], [Obrigatório], must,
      [UC-VID-005/RN7; RNG-09; DQ-008], [Dado outro utilizador, quando pede os itens do projeto, então vê o original mas não o vídeo convertido, e pedir o vídeo convertido dá 403.]),
    ..rnf([CONV-042], [O sistema deve aceitar na conversão vídeos MP4 e MOV com vídeo H.264 e áudio AAC.],
      [Compatibilidade (Interoperabilidade)], [MP4, MOV (H.264/AAC) → mais WebM e MKV (†)], must,
      [UC-VID-005/RN4; DQ-018], [Dado um MP4 e um MOV H.264/AAC, então são aceites; um vídeo sem AAC é recusado.]),
    ..rnf([CONV-045], [O sistema deve concluir a conversão em tempo proporcional à duração do vídeo.],
      [Eficiência de Desempenho (Comportamento temporal)], [≤ 2× a duração → ≤ 0,5×], should,
      [UC-VID-005/A3; DQ-011], [Dado 10 min sem outros trabalhos, então termina em ≤ 20 min.]),
    ..rnf([CONV-046], [O sistema deve produzir vídeos MP4 (H.264/AAC) e WebM (VP9/Opus) reproduzíveis nos
      navegadores atuais.], [Compatibilidade (Interoperabilidade)], [MP4 e WebM → mais formatos (†)], must,
      [UC-VID-005/RN8; UC-VID-005/Q1; DQ-018], [Dado uma conversão para cada formato, então reproduz com vídeo e áudio.]),
    ..rnf([FRAME-023], [O sistema deve extrair as imagens com a resolução original do vídeo.],
      [Adequação Funcional (Correção)], [Igual à do vídeo], must, [UC-VID-003/A2; DQ-015],
      [Dado um vídeo 640×360, então a imagem tem 640×360 px.]),
    ..rnf([FRAME-025], [O sistema deve extrair um frame único rapidamente, mesmo em vídeos longos.],
      [Eficiência de Desempenho (Comportamento temporal)], [≤ 5 s (†) → ≤ 2 s], should,
      [UC-VID-003/FA1; DQ-011], [Dado um vídeo de 10 min sem outros trabalhos, então o resultado surge no alvo.]),
    ..rnf([FRAME-046], [O sistema deve extrair 100 imagens de um vídeo de até 10 min em tempo limitado.],
      [Eficiência de Desempenho (Comportamento temporal)], [≤ 60 s (†) → ≤ 20 s], should,
      [UC-VID-003, passo 5; DQ-011], [Dado 10 min e N = 6, então os 100 resultados surgem no alvo.]),
    ..rnf([FRAME-047], [O sistema deve produzir imagens PNG e JPEG aceites pelas ferramentas de imagem sem
      conversão.], [Compatibilidade (Interoperabilidade)], [PNG e JPEG], must,
      [UC-VID-003/A3; UC-VID-003/FA2; DQ-015], [Dado uma imagem copiada, quando se aplica uma ferramenta de imagem, então executa sem erro.]),
    ..rnf([MAINT-001], [O sistema deve permitir acrescentar uma ferramenta de vídeo registando-a nas
      capacidades e num novo _worker_, sem alterar o código das ferramentas de vídeo existentes.],
      [Manutenibilidade (Modularidade)], [Obrigatório], must, [DQ-001, DQ-003],
      [Dado uma nova ferramenta de vídeo, então nenhum ficheiro dos _workers_ existentes muda.]),
    ..rnf([OUTPUT-001], [O sistema deve gerar vídeos anonimizados e convertidos com a mesma duração e o áudio
      do original.], [Adequação Funcional (Correção)], [≤ 1 s de diferença (†) → ≤ 1 frame], must,
      [UC-VID-004/RN6; UC-VID-005/RN6; DQ-013], [Dado um original de 10 s com áudio, então o gerado dura 9 a 11 s e tem áudio.]),
    ..rnf([PERF-001], [O sistema deve confirmar a receção do pedido de processamento rapidamente,
      independentemente da duração dos vídeos.], [Eficiência de Desempenho (Comportamento temporal)],
      [≤ 2 s → ≤ 1 s (†)], must, [UC-VID-001 a 005, passo 4; DQ-011],
      [Dado vídeos de 15 s e 10 min, quando aplica, então a confirmação surge no alvo.]),
    ..rnf([PERF-002], [O sistema deve processar em simultâneo um número limitado de trabalhos por ferramenta
      de vídeo, mantendo os restantes em fila.], [Eficiência de Desempenho (Capacidade)],
      [5 por ferramenta (†), 1 nas legendas → ajustado à carga, até 50 (†)], should,
      [UC-VID-002 a 005/A3; DQ-009], [Dado 8 vídeos em simultâneo, então 5 ficam em curso, 3 em fila e os 8 terminam.]),
    ..rnf([PORT-001], [O sistema deve poder ser instalado e executado, incluindo os _workers_ de vídeo e as suas
      dependências, com `docker compose up` num ambiente limpo.], [Portabilidade (Instalabilidade)],
      [Versões das imagens base fixadas → instalação com verificação de saúde], must,
      [UC-VID-002 a 004/A6; DQ-012], [Dado uma máquina limpa, quando se executa `docker compose up`, então os testes de aceitação passam.]),
    ..rnf([REL-001], [O sistema deve remover o resultado parcial de um vídeo cujo processamento falha, e de
      todos quando é cancelado, mantendo os vídeos concluídos.], [Fiabilidade (Recuperabilidade)],
      [Remoção dos parciais, sem retoma → repetição automática e retoma], must,
      [Pós-condições mínimas de UC-VID-001 a 005; DQ-006], [Dado 2 vídeos e uma falha no segundo, então o primeiro mantém-se e não há parcial do segundo.]),
    ..rnf([SEC-001], [O sistema deve manter o vídeo original inalterado em todas as ferramentas de vídeo.],
      [Segurança (Integridade)], [Obrigatório], must, [RNG-05; UC-VID-002 a 005/RN1; UC-VID-001/RN1],
      [Dado o _hash_ do original antes e depois, então são iguais.]),
    ..rnf([SEC-002], [O sistema deve restringir o acesso aos vídeos, resultados e legendas às permissões do
      projeto (dono e partilhas).], [Segurança (Confidencialidade)], [Obrigatório], must,
      [RNG-09; DQ-008; RNF44], [Dado um utilizador sem acesso, quando pede um vídeo ou resultado, então recebe erro de autorização.]),
    ..rnf([SEC-003], [O sistema deve disponibilizar vídeos e resultados apenas através de ligações assinadas,
      não adivinháveis e com expiração.], [Segurança (Confidencialidade)], [Expiração de 1 h → ≤ 15 min (†)],
      must, [UC-VID-002 a 005 (consulta de resultados); DQ-008], [Dado uma ligação com a assinatura alterada ou expirada, então o armazenamento devolve erro.]),
    ..rnf([STATUS-008], [O sistema deve atualizar o estado e a percentagem de progresso apresentados com um
      intervalo máximo.], [Usabilidade (Operabilidade)], [≤ 10 s (†) → ≤ 2 s], should, [DQ-010],
      [Dado um processamento de 5 min, então o valor é atualizado pelo menos a cada 10 s.]),
    ..rnf([SUB-013], [O sistema deve transcrever o áudio apenas em componentes do PictuRAS, sem o enviar a
      serviços externos.], [Segurança (Confidencialidade)], [Obrigatório], must,
      [UC-VID-001/A1; DQ-019, DQ-020], [Dado uma geração, então o modelo corre no _worker_, sem chamadas de rede externas.]),
    ..rnf([SUB-014], [O sistema deve garantir que uma mensagem de geração repetida não origina nova inferência
      nem nova cobrança.], [Fiabilidade (Tolerância a falhas)], [Obrigatório], must,
      [UC-VID-001/Exc. 6; DQ-019], [Dado a mesma mensagem entregue duas vezes, então o _worker_ devolve o mesmo resultado sem nova inferência.]),
    ..rnf([SUB-015], [O sistema deve produzir faixas WebVTT que o leitor de vídeo dos navegadores atuais
      carrega e mostra.], [Compatibilidade (Interoperabilidade)], [Chromium atual → todos os navegadores de R4],
      must, [UC-VID-001/Q5; DQ-019], [Dado uma faixa gerada, quando ativada no leitor, então as legendas aparecem sincronizadas.]),
    ..rnf([SUB-016], [O sistema deve gerar as legendas em tempo proporcional à duração do vídeo.],
      [Eficiência de Desempenho (Comportamento temporal)], [≤ 2× a duração (†) → ≤ 0,5×], could,
      [UC-VID-001/A1, A3; DQ-011], [Dado um vídeo de 60 s com fala, então a faixa surge no alvo.]),
    ..rnf([SUB-017], [O sistema deve guardar o modelo de reconhecimento de fala num volume persistente,
      descarregado uma única vez.], [Portabilidade (Instalabilidade)], [Volume `whisper_models` → modelo na imagem],
      should, [UC-VID-001/A1; DQ-012], [Dado o _worker_ recriado, então não volta a descarregar o modelo.]),
    ..rnf([TRIM-022], [O sistema deve gerar um excerto cuja duração difere da selecionada no máximo um valor
      limitado.], [Adequação Funcional (Correção)], [≤ 1 s (†) → ≤ 1 frame], must,
      [UC-VID-002/Q2; DQ-016], [Dado um excerto de 1,5 s, então o novo vídeo dura entre 0,5 s e 2,5 s.]),
    ..rnf([TRIM-043], [O sistema deve concluir o corte em tempo proporcional à duração do excerto.],
      [Eficiência de Desempenho (Comportamento temporal)], [≤ 0,5× o excerto (†) → ≤ 0,2×], should,
      [UC-VID-002/A3; DQ-011], [Dado um excerto de 5 min sem outros trabalhos, então termina em ≤ 2,5 min.]),
  ),
) <tab-rnf>
]

== Verificação da completude e dos limites do âmbito

#tab([Verificação da completude],
  tabela(
    colunas: (3.2cm, 1.8cm, 1.4cm, 1fr, 2.8cm),
    tamanho: 8pt,
    [Tópico a verificar], [Caso de uso], [Aplicável?], [Decisão / justificação], [Requisito(s)],
    [Formato, _codec_, duração e dimensão do vídeo], [Todos], [Sim],
    [Validados uma vez no carregamento, por perfil (SUBMIT); duração, resolução e codecs guardados para validar
    pedidos sem reler o vídeo.], [SUBMIT-001 a 004, COMP-001],
    [], [UC-VID-002, 003], [Sim], [Instantes e número de imagens validados contra a duração guardada.],
    [TRIM-014, 015, 034; FRAME-013 a 015],
    [], [UC-VID-005], [Sim], [Entrada H.264/AAC; tamanho e duração do carregamento, verificados de novo como
    defesa (500 MB, 10 min); resolução de saída por perfil.], [CONV-015, 022, 026, 035, 037, 042],
    [], [UC-VID-001], [Sim], [Vídeo sem áudio ou sem fala termina com mensagem própria.], [SUB-008, SUB-009],
    [Estado, progresso, cancelamento e resultado], [Todos], [Sim],
    [Mecanismos existentes estendidos com "em fila", percentagem por vídeo e falha por vídeo.],
    [STATUS-001 a 008, RESULT-001, 002],
    [], [UC-VID-001], [Parcial], [O cancelamento do "Aplicar" não interrompe uma inferência já enviada (A5);
    o resultado é uma faixa associada ao vídeo.], [SUB-003, SUB-005],
    [Falhas durante o processamento], [Todos], [Sim], [Falha isolada por vídeo: parcial removido, causa
    apresentada, operação devolvida, sem retoma automática no MVP.], [STATUS-006, 007, REL-001, QUOTA-002],
    [Persistência e expiração dos ficheiros], [UC-VID-002, 003, 004], [Sim],
    [Resultados substituídos na execução seguinte; cópias mantidas até eliminação; temporários até 1 h.],
    [RESULT-003 a 005],
    [], [UC-VID-005], [Sim], [O vídeo convertido entra na biblioteca e fica até ser eliminado.],
    [CONV-006, 033, 036],
    [], [UC-VID-001], [Sim], [Faixas mantidas até o vídeo ser eliminado e reutilizadas enquanto o vídeo não
    muda.], [SUB-003, 006, 012],
    [Perfis e contagem de operações], [UC-VID-002], [Sim], [Ferramenta básica: todos os perfis, sem quota.],
    [TRIM-049],
    [], [UC-VID-001, 003, 004, 005], [Sim], [Avançadas: anónimo excluído, uma operação por vídeo, premium sem
    limite.], [QUOTA-001 a 005],
    [Itens de tipos diferentes no mesmo projeto], [Todos], [Sim], [Só os vídeos são processados; as imagens
    são ignoradas sem custo.], [PIPE-003, PIPE-005],
    [Encadeamento de ferramentas e processamento em lote], [Todos], [Parcial], [Lote dentro do projeto (todos
    os vídeos, exceto na conversão); encadeamento fora do MVP, substituído pela cópia para um novo projeto.],
    [PIPE-004, 006, RESULT-003, MAINT-001],
    [Partilha do projeto], [Todos], [Sim], [Permissões de leitura e edição aplicadas; conversão só do dono.],
    [PIPE-007, SEC-002, CONV-039, SUB-011],
    [Privacidade dos dados (RGPD)], [UC-VID-001, 004], [Sim], [Caras e vozes processadas apenas localmente;
    temporários e faixas eliminados.], [BLUR-042, SUB-012, SUB-013, RESULT-005],
  ),
) <tab-completude>

== Requisitos consolidados e eliminados

Os requisitos partilhados substituem requisitos equivalentes que cada caso de uso tinha especificado na
sua primeira versão. Os IDs substituídos não são reutilizados.

#tab([Requisitos partilhados e requisitos individuais que substituem],
  tabela(
    colunas: (2.6cm, 1fr),
    tamanho: 8.5pt,
    [Requisito partilhado], [Substitui],
    [PIPE-001], [TRIM-001, FRAME-001, BLUR-001, CONV-001],
    [PIPE-002], [TRIM-005, FRAME-005, BLUR-003, CONV-004],
    [PIPE-003], [TRIM-045, FRAME-050, BLUR-045],
    [PIPE-004], [TRIM-046, FRAME-051, BLUR-046],
    [PIPE-005], [TRIM-047, FRAME-052, BLUR-047],
    [PIPE-006], [BLUR-051],
    [PIPE-007], [TRIM-050, FRAME-054, BLUR-049],
    [QUOTA-001, QUOTA-002], [FRAME-024, FRAME-031, BLUR-030, CONV-031],
    [QUOTA-003], [FRAME-018, BLUR-018, CONV-018],
    [QUOTA-004], [FRAME-019, BLUR-019, CONV-019],
    [QUOTA-005], [FRAME-032, BLUR-031, CONV-032],
    [RESULT-001], [TRIM-007, BLUR-007],
    [RESULT-002], [TRIM-008, BLUR-008, CONV-007],
    [RESULT-003], [TRIM-048, FRAME-011, BLUR-048],
    [RESULT-004], [TRIM-032, FRAME-033, BLUR-032],
    [RESULT-005], [TRIM-033, FRAME-034, BLUR-033, CONV-034],
    [STATUS-001], [TRIM-011, BLUR-011, CONV-012, parte de FRAME-012],
    [STATUS-002], [TRIM-012, FRAME-012, BLUR-012, CONV-013],
    [STATUS-003], [TRIM-026, FRAME-027, BLUR-026, CONV-027],
    [STATUS-004], [TRIM-027, FRAME-028, BLUR-027, CONV-028],
    [STATUS-005], [TRIM-028, FRAME-029, BLUR-028, CONV-029],
    [STATUS-006], [TRIM-029, FRAME-030, BLUR-029, CONV-030],
    [STATUS-007], [TRIM-017, FRAME-017, BLUR-016, CONV-016],
    [STATUS-008], [TRIM-039, FRAME-042, BLUR-037, CONV-041],
    [SUBMIT-004], [FRAME-053],
    [REL-001], [TRIM-020, FRAME-020, BLUR-020, CONV-020],
    [SEC-001], [TRIM-021, FRAME-021, BLUR-021, CONV-021],
    [SEC-002], [TRIM-037, FRAME-040, BLUR-035],
    [SEC-003], [TRIM-038, FRAME-041, BLUR-036, CONV-040],
    [PERF-001], [TRIM-024, FRAME-038, BLUR-024, CONV-025],
    [PERF-002], [TRIM-036, FRAME-039, BLUR-034, CONV-038],
    [PORT-001], [TRIM-041, FRAME-044, BLUR-039, CONV-043],
    [MAINT-001], [TRIM-042, FRAME-045, BLUR-040, CONV-044],
    [COMP-001], [TRIM-052, FRAME-043, BLUR-044],
    [COMP-002], [TRIM-044, BLUR-043],
    [OUTPUT-001], [BLUR-006, BLUR-022, CONV-023],
  ),
)

Foram eliminados na revisão dos casos de uso, sem substituição por um requisito novo: TRIM-016 e FRAME-016
(formato validado no carregamento), TRIM-018, TRIM-019, TRIM-030 e TRIM-031 (o corte não consome quota e
passou a estar disponível ao anónimo), TRIM-025, TRIM-035, FRAME-026, FRAME-037, BLUR-017 e BLUR-025
(limites validados no carregamento, SUBMIT-002), TRIM-040, BLUR-015 e BLUR-038 (formatos aceites no
carregamento, COMP-001), FRAME-035 (o PictuRAS não tem pastas) e FRAME-048 (a contagem dos pedidos pendentes
resulta do débito no início, QUOTA-001).
