#import "../template.typ": *

= Impacto no Sistema Existente

#tab([Impacto no sistema existente],
  tabela(
    colunas: (3.6cm, 1.6cm, 1fr, 2.2cm, 3cm),
    tamanho: 8.5pt,
    [Elemento existente afetado], [Impacto], [Descrição do impacto], [Caso(s) de uso], [Requisitos],
    [Carregamento de ficheiros para o projeto ("Carregar imagens")], [Alterar],
    [Passa a aceitar vídeos MP4, WebM e MOV (também em `.zip`), recusa extensões desconhecidas (antes o filtro
    estava só no _frontend_), aplica limites por perfil e guarda duração, resolução e codecs.],
    [Todos], [SUBMIT-001 a 004],
    [Visualização dos itens (grelha, carrossel, pré-visualização de carregamento)], [Estender],
    [Os vídeos são reproduzidos no carrossel e mostram o primeiro frame na grelha.], [Todos], [SUBMIT-005],
    [Aplicar ferramentas ao projeto (UC04; _pipeline_)], [Alterar],
    [Cada ferramenta declara o tipo de média que aceita; o processamento ignora os itens incompatíveis e
    informa quantos; as ferramentas de vídeo são exclusivas na _pipeline_; a confirmação do pedido deixou de
    esperar pela cópia dos ficheiros.], [Todos], [PIPE-001 a 006, PERF-001],
    [Pré-visualização de ferramentas (UC04)], [Alterar],
    [Só tratava imagens (a base não suportava vídeo); passa a pré-visualizar um frame na extração e na desfocagem. O corte pré-visualiza no
    leitor; a conversão e as legendas não têm pré-visualização no servidor.], [UC-VID-002 a 004],
    [FRAME-004, BLUR-010, TRIM-009],
    [Limite diário de operações (RNF48; T-07)], [Alterar],
    [Para vídeo, uma operação por vídeo processado por uma ferramenta avançada, debitada no pedido e devolvida
    em falha ou cancelamento (antes, a devolução só existia no cancelamento). O corte não consome.],
    [UC-VID-001, 003, 004, 005], [QUOTA-001 a 003, TRIM-049],
    [Perfil premium (sem limite)], [Manter], [A regra aplica-se às novas ferramentas.], [UC-VID-001, 003 a 005],
    [QUOTA-004],
    [Diferenciação de funcionalidades por perfil (RF64)], [Estender],
    [A sugestão de _upgrade_ passa a aparecer também quando o registado pede uma resolução de conversão
    acima do seu limite (CONV-014). Relacionados (novos): resolução de saída por perfil (CONV-002, 022, 035)
    e limites de carregamento por perfil (SUBMIT-002).], [UC-VID-005], [CONV-014; CONV-002, 022, 035,
    SUBMIT-002],
    [Perfil anónimo], [Manter], [A regra das ferramentas avançadas (sem acesso) aplica-se às novas; o corte,
    básico, fica disponível.], [Todos], [QUOTA-005, TRIM-049],
    [Resultados do projeto], [Estender],
    [Resultados do tipo vídeo, vários resultados por item (frames), tamanhos original e final, número de caras
    detetadas e descarte de um resultado.], [UC-VID-002 a 005], [RESULT-001, 002, FRAME-007, CONV-008, BLUR-014],
    [Biblioteca do projeto (itens)], [Estender],
    [Recebe os vídeos convertidos como novos itens, ao lado do original; os vídeos derivados ficam só
    acessíveis ao dono.], [UC-VID-005], [CONV-006, 033, 036, 039],
    [Resultados do projeto: cópia para um novo projeto], [Estender], [Não existia na base: os resultados
    (imagens e vídeos) passam a poder ser copiados para um novo projeto como itens normais, com a duração e os
    codecs dos vídeos.], [UC-VID-002 a 004], [RESULT-003, RESULT-004],
    [Cancelamento do processamento (T-01, T-10)], [Estender], [Mantém o _token_ de execução, a remoção dos
    resultados e a devolução das operações. Passa também a retirar da biblioteca os vídeos convertidos nessa
    execução.], [Todos; UC-VID-005/FA6], [STATUS-004, REL-001, QUOTA-002],
    [Mensagens de erro das ferramentas (T-02)], [Alterar], [Os erros dos _workers_ chegavam ao `projects` com
    os argumentos desalinhados e eram descartados; passam a chegar com a causa e são mostrados por vídeo.],
    [Todos], [STATUS-006, STATUS-007],
    [Notificações em tempo real (`ws_gateway`)], [Estender], [Novos eventos de progresso e de falha por vídeo.],
    [Todos], [STATUS-002, 003, 005, 008],
    [Partilha de projetos (RF45, UC07)], [Manter], [As permissões de leitura e edição aplicam-se às
    ferramentas de vídeo e às legendas.], [Todos], [PIPE-007, SEC-002, SUB-011],
    [Segurança e privacidade (RNF44)], [Estender], [Processamento local das caras e da voz; eliminação dos
    temporários e das faixas de legendas.], [UC-VID-001, 004], [BLUR-042, SUB-012, SUB-013, RESULT-005],
    [Armazenamento (img_storage e SeaweedFS)], [Estender], [Extensão do ficheiro original na chave (o `.mov`
    era guardado como `.quicktime`); novo _stage_ para as faixas de legendas, com nome determinístico.],
    [Todos], [SUBMIT-001, SUB-003],
    [Ligações de descarga assinadas], [Manter], [Mecanismo existente, com expiração de 1 h.], [Todos],
    [SEC-003],
    [Instalação (`docker-compose.yaml`, RabbitMQ, nginx)], [Estender], [Cinco novos _workers_, novas filas,
    volume do modelo de legendas e limite de carregamento de 500 MB no nginx e no gateway.], [Todos],
    [PORT-001, PERF-002, SUB-017],
    [Encadeamento de ferramentas e processamento em lote], [Manter], [Sem alterações no MVP: as ferramentas de
    vídeo não se encadeiam; aplicam-se a todos os vídeos do projeto.], [Todos], [PIPE-004, PIPE-006],
  ),
) <tab-impacto>

*Inconsistências entre funcionalidades e respetiva resolução.* Os casos de uso foram escritos em paralelo e
divergiam em cinco pontos, resolvidos assim:

+ *Contagem da quota.* O UC-VID-005 pedia que só as operações concluídas contassem; os UC-VID-003 e 004
  debitavam no início. Ficou a regra única RNG-03: débito no pedido e devolução em falha ou cancelamento, o que
  satisfaz as duas intenções (só os sucessos ficam consumidos e os pedidos simultâneos não ultrapassam a
  quota).
+ *Onde fica o resultado.* O UC-VID-005 falava de "biblioteca" e os restantes de "resultados do projeto".
  Mantiveram-se os dois conceitos, com significados distintos (glossário): a conversão acrescenta um item à
  biblioteca (CONV-006) e as outras ferramentas produzem resultados (RESULT-001). As legendas ficam associadas
  ao vídeo.
+ *Limites de entrada.* A conversão propunha 500 MB e 10 min para todos; o carregamento limita cada perfil.
  Ficaram os limites do carregamento; a conversão só os volta a verificar como defesa (UC-VID-005/RN4).
+ *Acesso partilhado.* As ferramentas seguem as permissões de partilha (SEC-002); a conversão restringe ao
  dono (CONV-039). A restrição é coerente porque o resultado da conversão entra na biblioteca do dono.
+ *Mecanismo de cobrança das legendas.* As legendas reservam e devolvem a operação no seu próprio serviço,
  por vídeo e idioma, para poderem reutilizar faixas sem custo (SUB-006); o efeito para o utilizador é o da
  regra RNG-03.
