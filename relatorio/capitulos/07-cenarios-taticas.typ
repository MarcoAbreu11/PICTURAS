#import "../template.typ": *

// Capítulo inteiro na horizontal (tabelas largas). Para voltar ao vertical, retirar o #paisagem[ ].
#paisagem[
= Cenários de Entrada e Táticas Candidatas

#orientacao[
  *Origem:* Exercício 7, secções 1 e 2 do _template_.

  *Objetivo do capítulo:* partir dos dois cenários já caracterizados e identificar as táticas arquiteturais que os podem
  melhorar. Os cenários vêm do capítulo 5 e os candidatos do capítulo 6 (`QS-nn`, `CAND-n`) e *não são reescritos*: o
  capítulo 5 é o único sítio onde os cenários se caracterizam. Se tiverem de corrigir uma medida da resposta, corrijam-na
  no capítulo 5 e registem a alteração na secção 7.2.

  Nas tabelas seguintes, `QS-01` e `QS-02` designam os cenários de `CAND-1` e `CAND-2`: substituam-nos pelos IDs reais.
]

== Candidatos e cenários de entrada

#tab([Candidatos e cenários de entrada],
  tabela(
    colunas: (1.8cm, 2.2cm, 3cm, 1.8cm, 2.8cm, 3cm, 3.4cm, 3.4cm),
    tamanho: 8pt,
    [Candidato], [Cenário (`QS-nn`)], [Característica / subcaracterística (ISO/IEC 25010)], [Evidência], [Origem (padrão global / vídeo / interação)], [Estímulo a que a tática reage], [Resposta e medida (resumo)], [Escala e método (cap. 6)],
    [CAND-1], [QS-01], [Eficiência de desempenho / utilização de recursos], [EV-11 a EV-16], [Interação (caminho de carregamento global usado pelos vídeos)], [Um utilizador premium carrega um vídeo de até 1 GB (ou vários em simultâneo)], [O upload é aceite e nenhum serviço do caminho cresce mais de 150 MB, qualquer que seja o tamanho], [Crescimento de VmRSS por serviço; `measure_upload.py`],
    [CAND-2], [QS-02], [Usabilidade / proteção contra erros do utilizador], [EV-17 a EV-20], [Interação (regras do vídeo no pipeline do projeto)], [O utilizador compõe um pipeline incompatível com os _media_ do projeto (ou altera os _media_ depois)], [O editor avisa antes de qualquer pré-visualização ou execução, nomeando a ferramenta e a correção, em ≥ 90 % dos casos, sem avisar nos válidos], [% de inválidos com aviso útil; `measure_pipeline.py`, `ui_check.py`],
  ),
)

== Alterações feitas ao capítulo 5 (se existirem)

#tab([Alterações aos cenários],
  tabela(
    colunas: (2cm, 1fr, 4cm),
    [Cenário], [O que mudou e porquê], [Onde foi atualizado],
    [QS-01, QS-02], [Nenhuma: a resposta e a medida mantêm-se como no capítulo 5; os valores-alvo e mínimos foram fixados no capítulo 6 depois da medição da base. O critério de «acionável» da medição do QS-02 foi alargado depois da primeira corrida final (`588544b`), o que não altera o cenário], [Capítulo 6 (quantificação); capítulos 8 e 10 (critério)],
  ),
)

== Táticas candidatas

#orientacao[
  Identifiquem *pelo menos três táticas por cenário*, de categorias de atributo adequadas (e.g., Desempenho → gerir
  recursos; Disponibilidade → recuperar de falhas). Para cada tática, expliquem como produz a resposta pretendida
  (estímulo → tática → resposta) e se já existe, total ou parcialmente, na base (com evidência).

  Classifiquem cada tática: *A* = _refactoring_ puro; *B* = alteração visível que é o objeto da melhoria; *C* =
  funcionalidade nova, a *rejeitar* nesta fase. Táticas de classe C podem constar da lista, mas não podem ser escolhidas.
]

#tab([Táticas candidatas],
  tabela(
    colunas: (1.6cm, 1.8cm, 3.6cm, 3.4cm, 5cm, 3.4cm, 1.8cm),
    tamanho: 8pt,
    [ID], [Cenário], [Atributo → categoria], [Tática], [Como produz a resposta (estímulo → tática → resposta)], [Já existe na base? (evidência)], [Classe (A/B/C)],
    [TAT-01], [QS-01], [Desempenho → gerir recursos (limitar a memória por pedido)], [_Streaming_ de ponta a ponta com _buffers_ limitados: nginx sem _buffering_, gateway a encaminhar o pedido, `projects` a escrever para um temporário, S3 por partes], [Upload de N MB → cada salto só guarda alguns MB em trânsito → a memória deixa de depender de N], [Não: `memoryStorage` em três serviços (EV-11 a EV-13)], [A],
    [TAT-02], [QS-01], [Desempenho → controlar a procura (rejeitar cedo)], [Verificar o token e o limite do perfil (`Content-Length`) antes de ler o corpo], [Pedido sem token ou acima do limite → recusado antes de transferir o ficheiro → nenhum recurso gasto], [Não: o corpo é lido antes do token (EV-14); o limite só é verificado depois de receber o ficheiro], [A],
    [TAT-03], [QS-01], [Desempenho → aumentar recursos], [Subir a memória dos contentores], [Mais memória → ficheiros maiores cabem], [Parcial: memória fixa por serviço], [A],
    [TAT-04], [QS-01], [Desempenho → reduzir a procura (remover intermediários)], [URL pré-assinado: o _browser_ envia diretamente para o S3], [Nenhum serviço Node toca nos bytes → memória mínima], [Não], [B],
    [TAT-05], [QS-01], [Desempenho → gerir recursos], [Disco em todos os saltos (`multer.diskStorage` no gateway, no `projects` e no `img_storage`)], [Cada salto escreve o ficheiro em disco → memória limitada], [Não], [A],
    [TAT-06], [QS-02], [Usabilidade → manter um modelo do sistema], [Regras de compatibilidade numa fonte única no `projects`, que devolve os problemas do pipeline (`pipelineIssues`) e as ferramentas indisponíveis com o motivo], [Pipeline incompatível → o modelo calcula os problemas → o editor mostra-os enquanto o pipeline é construído], [Parcial: regras em `video.js`, mas o editor repete-as à sua maneira (EV-17)], [B],
    [TAT-07], [QS-02], [Usabilidade → prevenir erros (validar na entrada)], [Validar cada ferramenta ao acrescentar ou editar, com mensagem que diz a ferramenta, o motivo e a correção], [Passo inválido → recusado na hora, com a correção], [Parcial: só a extração de fotogramas é validada (EV-19)], [B],
    [TAT-08], [QS-02], [Usabilidade → informar o utilizador], [Explicar as ferramentas não oferecidas (nota no editor) em vez de as esconder em silêncio], [Ferramenta indisponível → nota com motivo e alternativa], [Não (EV-17)], [B],
    [TAT-09], [QS-02], [Usabilidade → prevenir erros], [Mostrar as ferramentas indisponíveis desativadas, com o motivo numa dica], [Ferramenta indisponível → visível mas inativa], [Não], [B],
    [TAT-10], [QS-02], [Usabilidade → prevenir erros], [Validação só no _frontend_ (regras duplicadas no editor)], [Passo inválido → bloqueado no cliente], [Parcial (EV-17)], [A],
    [TAT-11], [QS-02], [Usabilidade → suportar a iniciativa do utilizador], [Correção automática (reordenar ou remover ferramentas sozinho)], [Pipeline inválido → o sistema corrige-o], [Não], [C],
  ),
)
]
