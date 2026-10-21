#import "../template.typ": *

= Manutenção Corretiva da Solução de Base

Problemas encontrados na solução de base durante o estudo e a integração do vídeo. A numeração continua a do
documento de solução arquitetural de base (T-01 a T-11).

#tab([Tarefas de manutenção corretiva],
  tabela(
    colunas: (1.2cm, 1fr, 2.2cm, 1.6cm, 2cm, 1.8cm),
    tamanho: 8.5pt,
    [ID], [Descrição do problema], [Impacto], [Prioridade], [Rel. Req.], [Estado],
    [T-12], [O nginx não definia `client_max_body_size`: qualquer ficheiro acima de 1 MB era recusado com 413.],
    [Funcional], [Alta], [SUBMIT-001], [Corrigido],
    [T-13], [O axios em Node corta pedidos acima de 10 MB por omissão: os vídeos falhavam entre o gateway, o
    `projects` e o armazenamento.], [Funcional], [Alta], [SUBMIT-001], [Corrigido],
    [T-14], [A chave no armazenamento usava o MIME como extensão: um `.mov` ficava guardado como `.quicktime`.],
    [Funcional], [Média], [SUBMIT-001], [Corrigido],
    [T-15], [Os ficheiros extraídos de um `.zip` não tinham MIME e eram descartados pelo filtro de tipos.],
    [Funcional], [Média], [SUBMIT-001], [Corrigido],
    [T-16], [O envio de erros das ferramentas desalinhava os argumentos e usava `error.msg` em vez de
    `error.message`: os erros eram descartados e o utilizador não via a causa.], [Funcional], [Alta],
    [STATUS-006], [Corrigido (todas as ferramentas)],
    [T-17], [O backend aceitava qualquer ficheiro no carregamento (o filtro estava só no _frontend_).],
    [Segurança], [Média], [SUBMIT-001], [Corrigido],
    [T-18], [O "Aplicar" falhava com conflito de versão (409) quando a marca de alterações não guardadas tinha
    incrementado a versão, mesmo sem alterações às ferramentas.], [Funcional], [Média], [PIPE-002], [Corrigido],
    [T-19], [O `/process` descarrega todos os ficheiros antes de responder; com ficheiros grandes, a resposta
    passa dos 2 s.], [Desempenho], [Média], [PERF-001], [Corrigido para vídeo; pendente para imagens],
    [T-20], [O `projects` usava a imagem `node` sem versão (`latest`).], [Portabilidade], [Média], [PORT-001], [Corrigido],
    [T-21], [O `ws_gateway` não volta a ligar-se ao RabbitMQ se este reiniciar; o ecrã fica em "Processing".],
    [Fiabilidade], [Média], [STATUS-002], [Pendente],
    [T-22], [O nginx guarda o IP do contentor do _frontend_; depois de o reconstruir, devolve 502 até ser
    reiniciado.], [Operação], [Baixa], [PORT-001], [Pendente (documentado no Anexo A)],
    [T-23], [O `users` termina se a sua base de dados reiniciar e não recupera sozinho (o `nodemon` fica à espera
    de alterações).], [Fiabilidade], [Média], [—], [Pendente],
    [T-24], [Os carregamentos ficam em memória no gateway, no `projects` e no armazenamento: um vídeo de 500 MB
    ocupa essa memória em cada serviço.], [Desempenho], [Média], [SUBMIT-002], [Pendente (Fase 2)],
    [T-25], [Os auxiliares genéricos do RabbitMQ confirmam as mensagens antes de as tratar; uma queda a meio
    perde o pedido.], [Fiabilidade], [Média], [REL-001], [Pendente (corrigido só nas legendas)],
    [T-26], [A eliminação genérica de itens mexe nos ficheiros antes de confirmar a versão do projeto.],
    [Fiabilidade], [Baixa], [—], [Pendente],
  ),
) <tab-manutencao>
