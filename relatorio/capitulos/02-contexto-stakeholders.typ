#import "../template.typ": *

= Contexto, Perfis e _Stakeholders_ (revisão)

Este capítulo regista apenas o que muda com o vídeo. Os perfis, os _stakeholders_ e as restrições do documento
de base mantêm-se; a restrição R7 (manter a arquitetura base, sem a reestruturar) foi seguida em todo o
incremento.

== Perfis de utilização e vídeo

Os três perfis continuam válidos. O vídeo acrescenta *limites de carregamento por perfil* e reinterpreta a regra
"até 5 operações por dia" do perfil registado: *uma operação por vídeo processado* por uma ferramenta de vídeo
avançada, independentemente da duração do vídeo ou do número de imagens produzidas (RNG-03). O corte é uma
ferramenta básica, como o recorte de imagem, e não consome operações.

#tab([Perfis de utilização e respetivo acesso a vídeo],
  tabela(
    colunas: (2.2cm, 3.4cm, 1fr, 3cm),
    [Perfil], [Situação na _baseline_], [Alteração introduzida para vídeo], [Regras / requisitos],
    [Anónimo], [Operações limitadas, imagens pequenas],
    [Carrega vídeos até *20 MB e 15 s*. Usa apenas a ferramenta de vídeo básica (corte); não acede às
    ferramentas de vídeo avançadas (frames, desfocar caras, converter, legendas).],
    [RNG-02, RNG-04; SUBMIT-002, QUOTA-005, TRIM-049],
    [Registado], [Gratuito, até 5 operações/dia],
    [Carrega vídeos até *100 MB e 60 s*. Cada vídeo processado por uma ferramenta avançada consome uma
    operação, debitada no pedido e devolvida em falha ou cancelamento. Resolução máxima de saída da conversão:
    *720p*.],
    [RNG-02, RNG-03; SUBMIT-002, QUOTA-001 a 003, CONV-022],
    [Premium], [Pago, uso ilimitado],
    [Carrega vídeos até *500 MB e 10 min*. Sem limite diário nas ferramentas de vídeo. Resolução máxima de
    saída da conversão: *1080p*.],
    [RNG-02; SUBMIT-002, QUOTA-004, CONV-035],
  ),
) <tab-perfis>

Os limites são verificados no carregamento, uma só vez, e aplicam-se a todas as ferramentas. A conversão
acrescenta restrições próprias à entrada (H.264/AAC, até 500 MB e 10 min); para um utilizador registado, o
limite efetivo é o do carregamento (100 MB e 60 s), que é mais restritivo.

== _Stakeholders_ e interesses

Os nomes coincidem com os usados na secção "_Stakeholders_ e Interesses" de cada caso de uso.

#tab([_Stakeholders_ e interesses (novos ou revistos)],
  tabela(
    colunas: (2.8cm, 1.6cm, 1fr, 1.8cm, 2.8cm),
    [_Stakeholder_], [Estado], [Interesse(s) relativamente ao vídeo], [Influência], [UC / requisitos],
    [Utilizador (anónimo, registado, premium)], [Revisto],
    [Editar vídeos sem software externo: cortar, extrair imagens, anonimizar pessoas, reduzir o tamanho ou
    mudar o formato, obter legendas. Saber em que estado está um processamento demorado e não perder quota
    quando ele falha.],
    [Alta], [UC-VID-001 a 005; STATUS, QUOTA],
    [Convidado por Link], [Revisto],
    [Com permissão de edição, aplicar ferramentas de vídeo num projeto partilhado; com permissão de leitura,
    consultar resultados e legendas.],
    [Média], [PIPE-007, SUB-011, SEC-002],
    [Proprietário do sistema], [Revisto],
    [Diferenciar os perfis (limites de carregamento, ferramentas avançadas, resolução de saída) e controlar o
    *custo de processamento e armazenamento* do vídeo, muito superior ao de uma imagem.],
    [Alta], [RNG-02, RNG-03; PERF-002, RESULT-005],
    [Administrador de Sistema], [Revisto],
    [Os vídeos contêm dados pessoais (caras, vozes): processamento apenas local, temporários eliminados,
    acesso restrito às permissões do projeto (RGPD, R3).],
    [Alta], [SEC-001 a 003, BLUR-042, SUB-013, RESULT-005],
    [Equipa de desenvolvimento / DevOps], [Revisto],
    [Validar o mecanismo comum das ferramentas de vídeo na _pipeline_ existente e manter a instalação
    reprodutível com dependências externas pesadas (FFmpeg, OpenCV, modelo Whisper).],
    [Alta], [MAINT-001, PORT-001, DA-01 a DA-11],
  ),
) <tab-stakeholders>

Não surgiram novos tipos de _stakeholder_. O "Serviço IA Externo" do documento de base não é usado pelas
ferramentas de vídeo: a deteção de caras e a transcrição correm em _workers_ do próprio PictuRAS
(DQ-020).

== Elicitação de requisitos

As funcionalidades foram escolhidas pela equipa a partir do enunciado e da análise da solução existente, com
o critério de cobrirem tipos de processamento de vídeo diferentes e de complexidade adequada (Capítulo 3). Os
casos de uso foram escritos nos Exercícios 1 e 2 e revistos depois da implementação, para os alinhar com o
sistema real (por exemplo, "biblioteca" passou a "resultados do projeto" onde a ferramenta gera resultados).
Os valores numéricos têm três origens identificáveis: (i) *limites já implementados* na solução de base ou no
suporte base a vídeo (quota de 5 operações/dia; limites de carregamento por perfil em
`projects/utils/media.js`; ligações assinadas com expiração de 1 h); (ii) *medições* feitas pela equipa
durante a implementação (por exemplo, desfocagem a ≈ 0,5× a duração do vídeo; estimativa de tamanho com erro
de 8 %); e (iii) *propostas da equipa*, marcadas com (†) e registadas como decisões de qualidade (por exemplo,
100 imagens por vídeo, 5 trabalhos em simultâneo por ferramenta, 720p/1080p). Na conversão, os formatos de
saída MP4 e WebM resultam da compatibilidade nativa dos navegadores atuais (restrição R4).
