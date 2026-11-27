#import "../template.typ": *

= Conclusões e Recomendações

#orientacao[
  *Origem:* Exercício 6, Bloco 2, secção 6 do _template_.

  Sintetizem os contributos do relatório, sem repetir o conteúdo dos capítulos anteriores: o que o diagnóstico concluiu
  sobre a adequação do padrão atual, que otimizações sugerem e que considerações ficam para a evolução futura.

  Terminem com o que ficou por fazer e porquê (e.g., valores-alvo não atingidos, hipóteses por confirmar) e com a
  ligação à Fase 3: de que forma o _refactoring_ facilita, ou não, a integração de novas funcionalidades. Sejam realistas e honestos quanto às limitações da
  análise e às hipóteses que ficaram por confirmar.
]

== Adequação do padrão atual (global e do vídeo)
A análise dos capítulos 3 e 4 mostrou que o padrão global de microserviços com RabbitMQ e o processamento de vídeo num único _worker_ (`video_tool`), que agrupa os efeitos convencionais numa única passagem de descodificação e codificação, são adequados na sua estrutura base, evitando recodificações sucessivas; a legendagem automática e a extração de fotogramas têm percursos próprios. Os dois requisitos melhorados mostram que as
fragilidades não estavam no padrão global de microserviços, mas na forma como alguns serviços o realizavam: o caminho de
carregamento já tinha os saltos certos e bastou que cada um passasse a tratar o corpo em _stream_; as regras de
compatibilidade já existiam no `projects` e bastou torná-las a fonte única do editor. Ambas as melhorias foram feitas
estendendo a arquitetura, sem serviços novos.

== Sugestões de otimização

- *Limite antecipado para imagens.* O carregamento de imagens não tem limite por perfil: uma imagem pode ocupar até
  1100 MB do disco temporário do `projects` antes de ser recusada. Dar a `receiveUpload("image")` um limite por perfil,
  verificado pelo `Content-Length`.
- *Disco temporário explícito.* Definir `UPLOAD_TMP_DIR` no `docker-compose.yaml` (volume ou `tmpfs` dimensionado), em
  vez da camada gravável do contentor.
- *Validação completa no `projects`.* Avaliar sempre os parâmetros de uma ferramenta, mesmo quando o vídeo indicado em
  `imgId` já não existe (hoje um _speed_ de 99× com um `imgId` inexistente é aceite pela API), e validar cada ferramenta
  ao reordenar.
- *Uma só origem para os limites dos formulários.* O editor ainda repete os limites do _speed_ e a tolerância do _trim_;
  podem vir na resposta do projeto, como as restantes regras.

== Considerações para evolução futura

- Mostrar as ferramentas indisponíveis desativadas, com o motivo numa dica, em vez de as esconder com uma nota; o mesmo
  para a exportação em PDF, hoje escondida em projetos com vídeos sem explicação.
- Se o volume de carregamentos crescer, o URL pré-assinado (TAT-04) volta a ser uma opção, desde que a validação passe a
  um passo assíncrono sobre o objeto guardado.
- O `img_storage` ainda cresce ligeiramente com o tamanho do ficheiro; vale a pena medir separadamente a memória viva e o
  atraso do _garbage collector_.

== Trabalho futuro

Os valores-alvo dos dois requisitos foram atingidos nas condições medidas. Na confirmação do CAND-1 na versão
integrada, noutra máquina, o caso de 4 uploads simultâneos ficou 1 MB acima do alvo (151 MB no `img_storage`), o que
indica que o alvo de 150 MB está no limite para essa carga; reduzir as partes S3 em trânsito ou medir o _heap_ vivo
separadamente esclareceria se é uma margem real. Ficam por fazer: repetir a base nessa máquina, para comparar tempos; e fixar o critério de mensagem acionável do CAND-2 antes de medir, já que foi alargado depois
da primeira corrida final (89 % com o critério original). Para a Fase 3, o carregamento em _stream_ remove o limite
prático de tamanho imposto pela memória, e o módulo de regras dá um único sítio onde declarar a compatibilidade de uma
ferramenta nova com imagens e vídeos (e.g., novas ferramentas de edição ou filtros de vídeo integrarão diretamente as regras em `pipelineRules.js` e beneficiarão do carregamento em _streaming_).
