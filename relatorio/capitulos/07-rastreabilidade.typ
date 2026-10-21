#import "../template.typ": *

= Rastreabilidade

== Casos de uso → requisitos

Cada elemento relevante de cada caso de uso tem pelo menos um requisito; os elementos que não precisam de
requisito próprio indicam a razão. Todos os requisitos da ERS aparecem nesta matriz ou nas decisões de
qualidade (7.2).

#tab([Matriz de rastreabilidade: casos de uso → requisitos],
  tabela(
    colunas: (3.6cm, 1fr, 5.2cm),
    tamanho: 8pt,
    [Elemento de origem], [Descrição abreviada], [Requisito(s)],
    // ---------------- comuns
    [Pré-condições (todos)], [Projeto com vídeos carregados e validados], [SUBMIT-001 a 005, COMP-001],
    [Passos 1–2 (todos)], [Abrir vídeo, escolher ferramenta de vídeo], [PIPE-001, SUBMIT-005],
    [Passo 4 (todos)], [Aplicar, validar, confirmar], [PIPE-002, PERF-001],
    [FA de segundo plano (todos)], [Continuar fora da página, estado], [STATUS-001, 002, 003, 008],
    [Pós-condições mínimas (todos)], [Sem parciais, originais intactos, informado], [REL-001, SEC-001, STATUS-006, RESULT-005],
    // ---------------- UC-VID-001
    [UC-VID-001, passos 2–3], [Escolher idioma e guardar], [SUB-001],
    [UC-VID-001, passo 4], [Reserva de quota por vídeo], [QUOTA-001, QUOTA-003],
    [UC-VID-001, passo 5], [Transcrever ou traduzir a fala], [SUB-002, SUB-013, SUB-016, PERF-002],
    [UC-VID-001, passo 6], [Guardar faixa WebVTT e idioma], [SUB-003, SUB-007, SUB-015],
    [UC-VID-001, passo 7], [Notificar e ativar a faixa], [STATUS-005, SUB-005],
    [UC-VID-001, passo 8], [Legendas no leitor], [SUB-004, SUB-015],
    [UC-VID-001/FA1], [Faixa existente reutilizada], [SUB-006],
    [UC-VID-001/FA2], [Mostrar, esconder, trocar faixa], [SUB-004],
    [UC-VID-001/FA3], [Vídeo em inglês], [SUB-007],
    [UC-VID-001/FA4], [Partilha só de leitura], [SUB-011],
    [UC-VID-001/FA5], [Imagens ignoradas], [PIPE-003],
    [UC-VID-001/FA6], [Segundo plano], [STATUS-001],
    [UC-VID-001/Exc. 1, 2], [Anónimo; quota insuficiente], [QUOTA-005, QUOTA-003],
    [UC-VID-001/Exc. 3, 4], [Sem áudio; sem fala], [SUB-008, SUB-009, QUOTA-002],
    [UC-VID-001/Exc. 5], [Combinação com outras ferramentas], [PIPE-004],
    [UC-VID-001/Exc. 6], [Geração já em curso], [SUB-010, SUB-014],
    [UC-VID-001/Exc. 7], [Falha da inferência], [STATUS-006, QUOTA-002, REL-001],
    [UC-VID-001, pós-cond. sucesso], [Faixa no idioma, vídeo inalterado], [SUB-003, SEC-001],
    [UC-VID-001, pós-cond. mínima], [Sem faixa incompleta; faixas eliminadas com o vídeo], [REL-001, SUB-012, QUOTA-002],
    [UC-VID-001/RN1, RN5, RN7], [Faixa separada; uma por idioma; não herdada], [SUB-003, SUB-006],
    [UC-VID-001/RN2, RN3], [Avançada; premium sem limite], [QUOTA-001, QUOTA-004, SUB-006],
    [UC-VID-001/RN4], [Idiomas original e inglês], [SUB-001],
    [UC-VID-001/RN6], [Permissões], [PIPE-007, SUB-011, CONV-039],
    [UC-VID-001/RN8], [Sem combinação], [PIPE-004],
    [UC-VID-001/A1 a A3], [Modelo local; qualidade; uma réplica], [SUB-013, SUB-017, PERF-002],
    [UC-VID-001/A4, A5], [Idioma predominante; cancelamento], [SUB-007; limitação registada em 10.3],
    [UC-VID-001/Q1 a Q5], [Questões resolvidas], [SUB-001, SUB-003, QUOTA-001],
    // ---------------- UC-VID-002
    [UC-VID-002, passo 2], [Linha temporal], [TRIM-002],
    [UC-VID-002, passo 3], [Instantes e duração do excerto], [TRIM-003, TRIM-004],
    [UC-VID-002, passo 5], [Gerar vídeos cortados], [TRIM-006, TRIM-043, COMP-002, STATUS-003],
    [UC-VID-002, passo 6], [Guardar e nomear], [RESULT-001, TRIM-051],
    [UC-VID-002, passos 7–8], [Notificar; reproduzir e descarregar], [STATUS-005, RESULT-002, SEC-003],
    [UC-VID-002/FA1, FA2], [Pré-visualização; tempos manuais], [TRIM-009, TRIM-010],
    [UC-VID-002/FA3], [Copiar para novo projeto], [RESULT-003, RESULT-004],
    [UC-VID-002/FA5, FA6, FA7], [Desistir; cancelar; imagens], [TRIM-013, STATUS-004, PIPE-003],
    [UC-VID-002/Exc. 1, 2, 3], [Instantes inválidos; excerto curto; fim além da duração], [TRIM-014, TRIM-034, TRIM-015],
    [UC-VID-002/Exc. 4, 5], [Combinação; sem vídeos], [PIPE-004, PIPE-005],
    [UC-VID-002/Exc. 6, 7], [Vídeo corrompido; falha], [STATUS-007, STATUS-006, REL-001],
    [UC-VID-002, pós-cond. sucesso], [Duração do excerto, originais intactos], [TRIM-022, SEC-001],
    [UC-VID-002/RN1 a RN4], [Novo ficheiro; básica; limites; só vídeos], [SEC-001, TRIM-049, SUBMIT-002, PIPE-003],
    [UC-VID-002/RN5, RN9], [Instantes válidos; mesmo intervalo], [TRIM-014, 015, 034, PIPE-006],
    [UC-VID-002/RN6 a RN8], [Sem parciais; um excerto; permissões], [REL-001, TRIM-023, PIPE-004, PIPE-007],
    [UC-VID-002/A1 a A8], [Assunções], [SUBMIT-004, TRIM-023, PERF-002, PORT-001, TRIM-022],
    [UC-VID-002/Q1 a Q9], [Questões resolvidas], [TRIM-022, 023, 034, COMP-002, RESULT-004, TRIM-049, PIPE-004, PIPE-006],
    // ---------------- UC-VID-003
    [UC-VID-003, passo 2], [Modos e parâmetros], [FRAME-002],
    [UC-VID-003, passo 3], [Intervalo, formato, pré-visualização, estimativa], [FRAME-004, 009, 010, 049],
    [UC-VID-003, passo 4], [Débito por vídeo], [QUOTA-001],
    [UC-VID-003, passo 5], [Extrair com progresso], [FRAME-006, 009, 046, STATUS-003, PIPE-003],
    [UC-VID-003, passos 6–8], [Guardar, notificar, consultar], [FRAME-007, 036, STATUS-005, RESULT-003, SEC-003],
    [UC-VID-003/FA1, FA2], [Frame único; PNG por omissão], [FRAME-003, 004, 006, 025, FRAME-010, 047],
    [UC-VID-003/FA3], [Editar as imagens], [FRAME-008, FRAME-022, RESULT-003, RESULT-004],
    [UC-VID-003/FA5, FA6], [Cancelar; imagens], [STATUS-004, QUOTA-002, PIPE-003],
    [UC-VID-003/Exc. 1, 2], [Instante fora; demasiadas imagens], [FRAME-013, FRAME-014, FRAME-015],
    [UC-VID-003/Exc. 3, 4, 5], [Combinação; sem vídeos; quota], [PIPE-004, PIPE-005, QUOTA-003],
    [UC-VID-003/Exc. 6, 7], [Corrompido; falha], [STATUS-007, STATUS-006, QUOTA-002, REL-001],
    [UC-VID-003, pós-cond. sucesso], [Imagens identificadas, débito, originais], [FRAME-007, FRAME-036, QUOTA-001, SEC-001],
    [UC-VID-003/RN1 a RN4], [Originais; avançada; premium; anónimo], [SEC-001, QUOTA-001, 004, 005],
    [UC-VID-003/RN5 a RN8], [Máximo de imagens; sem combinação; regras; permissões], [FRAME-014, 015, PIPE-004, FRAME-022, PIPE-007],
    [UC-VID-003/A1 a A8], [Assunções], [SUBMIT-004, FRAME-023, FRAME-047, PERF-002, PORT-001, FRAME-015],
    [UC-VID-003/Q1 a Q10], [Questões resolvidas], [FRAME-010, 015, RESULT-003, 004, QUOTA-001, 002, PIPE-004, 006],
    // ---------------- UC-VID-004
    [UC-VID-004, passos 2–3], [Opções e validação], [BLUR-002, BLUR-050],
    [UC-VID-004, passo 4], [Quota e débito], [QUOTA-001, QUOTA-003],
    [UC-VID-004, passo 5], [Detetar e desfocar], [BLUR-004, 005, 023, 041, 042, STATUS-003],
    [UC-VID-004, passo 6], [Mesma duração e áudio], [OUTPUT-001, COMP-002],
    [UC-VID-004, passos 7–8], [Guardar, notificar, consultar], [RESULT-001, 002, STATUS-005, SEC-003],
    [UC-VID-004/FA1, FA2], [Pixelização; pré-visualização], [BLUR-009, BLUR-010],
    [UC-VID-004/FA4], [Nenhuma cara], [BLUR-013, BLUR-014],
    [UC-VID-004/FA5, FA6, FA7], [Copiar; cancelar; imagens], [RESULT-003, STATUS-004, QUOTA-002, PIPE-003],
    [UC-VID-004/Exc. 1 a 5], [Anónimo; quota; combinação; sem vídeos; opções], [QUOTA-005, 003, PIPE-004, 005, BLUR-050],
    [UC-VID-004/Exc. 6, 7], [Corrompido; falha], [STATUS-007, STATUS-006, QUOTA-002, REL-001],
    [UC-VID-004, pós-cond. sucesso], [Caras desfocadas, duração e áudio], [BLUR-005, OUTPUT-001, SEC-001],
    [UC-VID-004/RN1 a RN5], [Original; avançada; débito; limites; só vídeos], [SEC-001, QUOTA-001, 002, 004, SUBMIT-002, PIPE-003],
    [UC-VID-004/RN6 a RN11], [Duração; parciais; combinação; permissões; opções; todas as caras], [OUTPUT-001, REL-001, PIPE-004, 007, 006, BLUR-005],
    [UC-VID-004/A1 a A8], [Assunções], [SUBMIT-004, BLUR-042, BLUR-023, PERF-002, PORT-001],
    [UC-VID-004/Q1 a Q8], [Questões resolvidas], [BLUR-005, BLUR-023, QUOTA-001, 002, 004, RESULT-004, PIPE-004],
    // ---------------- UC-VID-005
    [UC-VID-005, passo 2], [Vídeo, formato, resolução, qualidade por perfil], [CONV-047, CONV-002, CONV-022, CONV-035],
    [UC-VID-005, passo 3], [Estimativa de tamanho], [CONV-003, CONV-024],
    [UC-VID-005, passo 4], [Validar entrada e debitar], [CONV-015, 026, 037, 042, QUOTA-001],
    [UC-VID-005, passo 5], [Recodificar com progresso], [CONV-005, CONV-045, CONV-046, STATUS-003],
    [UC-VID-005, passo 6], [Novo vídeo na biblioteca], [CONV-006, CONV-036],
    [UC-VID-005, passo 7], [Reproduzir, descarregar, tamanhos], [RESULT-002, CONV-008, SEC-003],
    [UC-VID-005/FA1 a FA3], [Só formato; só compressão; perfis], [CONV-009, CONV-010, CONV-011],
    [UC-VID-005/FA4, FA5], [Segundo plano; outro vídeo], [STATUS-001, CONV-047],
    [UC-VID-005/Exc. 1, 2], [Resolução acima do perfil; entrada não suportada], [CONV-014, CONV-015, 026, 037],
    [UC-VID-005/Exc. 3, 6], [Corrompido; falha], [STATUS-007, STATUS-006, REL-001, QUOTA-002],
    [UC-VID-005/Exc. 4], [Resultado maior], [CONV-017],
    [UC-VID-005/Exc. 5, 7, 8], [Quota; anónimo ou não dono; combinação], [QUOTA-003, QUOTA-005, CONV-039, PIPE-004],
    [UC-VID-005, pós-cond. sucesso], [Novo vídeo, tamanhos, original intacto], [CONV-006, 008, 033, SEC-001],
    [UC-VID-005/RN1 a RN3], [Original; débito; premium], [CONV-036, SEC-001, QUOTA-001, 002, 004],
    [UC-VID-005/RN4, RN5], [Entrada; resolução por perfil], [CONV-015, 026, 037, 042, CONV-022, 035],
    [UC-VID-005/RN6 a RN9], [Duração e áudio; só dono; saída; um vídeo], [OUTPUT-001, CONV-039, CONV-046, CONV-047, PIPE-004],
    [UC-VID-005/A1 a A8], [Assunções], [SUBMIT-001, CONV-024, PERF-002, REL-001],
    [UC-VID-005/Q1 a Q7], [Questões resolvidas], [CONV-046, 022, 035, 036, 011, 037, 033, QUOTA-001],
    // ---------------- transversais
    [RNG-01 a RNG-10], [Regras transversais], [Ver a coluna "Requisitos" da tabela de regras (3.4)],
  ),
) <tab-matriz>

== Decisões de qualidade

As decisões de qualidade de cada caso de uso (gamas DQ-001 a 020, 101 a 115 e 401 a 419 nos documentos dos
exercícios) foram consolidadas numa numeração global.

#tab([Decisões de qualidade],
  tabela(
    colunas: (1.4cm, 1fr, 4.2cm, 3cm),
    tamanho: 8.5pt,
    [ID], [Decisão de qualidade], [Justificação], [Requisitos],
    [DQ-001], [As ferramentas de vídeo são ferramentas da _pipeline_, executadas de forma assíncrona por
    _workers_ dedicados através do RabbitMQ.], [Reutiliza fila, estados, cancelamento, quota, partilha e
    descarga.], [PIPE-001, PIPE-002, MAINT-001],
    [DQ-002], [Cada ferramenta declara o tipo de média que aceita; as ferramentas de vídeo aceitam só vídeo e
    as imagens são ignoradas sem custo.], [Projetos podem misturar imagens e vídeos.], [PIPE-003, PIPE-005],
    [DQ-003], [No MVP, as ferramentas de vídeo são exclusivas na _pipeline_; o encadeamento, com capacidades
    `{ accepts, produces }`, fica para a Fase 2.], [A _pipeline_ é linear e as saídas são de tipos diferentes.],
    [PIPE-004, MAINT-001],
    [DQ-004], [Formato, tamanho e duração são validados no carregamento, por perfil, e os metadados ficam
    guardados.], [Uma só validação e uma só lista de formatos.], [SUBMIT-001 a 004, COMP-001],
    [DQ-005], [Ferramentas avançadas: uma operação por vídeo, debitada no pedido e devolvida em falha ou
    cancelamento; o corte é básico.], [Simples e previsível; não ultrapassa a quota com pedidos simultâneos.],
    [QUOTA-001 a 005, TRIM-049],
    [DQ-006], [A falha é isolada por vídeo: parcial removido, causa mostrada, operação devolvida; sem retoma
    automática no MVP.], [Um vídeo problemático não anula os restantes.], [STATUS-006, STATUS-007, REL-001],
    [DQ-007], [Resultados segundo a regra existente; cópias mantidas até eliminação; temporários eliminados
    até 1 h (†).], [Evita perda de trabalho e retenção de dados pessoais.], [RESULT-004, RESULT-005],
    [DQ-008], [O acesso segue as permissões do projeto e a descarga usa ligações assinadas; os vídeos
    convertidos só são acessíveis ao dono.], [Reutiliza o modelo de segurança.], [PIPE-007, SEC-002, SEC-003, CONV-039],
    [DQ-009], [Cinco réplicas (†) por _worker_ de vídeo, uma no das legendas (memória do modelo); o resto fica
    em fila.], [Limita o consumo de CPU e mantém a aplicação responsiva.], [PERF-002],
    [DQ-010], [Estado, progresso, cancelamento e notificação reutilizam os mecanismos existentes; o _worker_
    envia 0 % ao sair da fila e depois no máximo uma atualização por segundo.], [Operações que duram minutos
    exigem _feedback_.], [STATUS-002 a 005, STATUS-008],
    [DQ-011], [Confirmação do pedido em ≤ 2 s (a cópia dos vídeos para o _worker_ é feita depois da resposta);
    tempos de processamento proporcionais à duração (†).], [Distingue o tempo de resposta do tempo de
    processamento.], [PERF-001, BLUR-041, CONV-045, FRAME-025, FRAME-046, SUB-016, TRIM-043],
    [DQ-012], [Instalação com `docker compose`, com as imagens base em versões fixadas e as dependências pesadas
    (FFmpeg, OpenCV, Whisper) só nos _workers_.], [Instalação reprodutível; serviço web leve.], [PORT-001, SUB-017],
    [DQ-013], [Os vídeos gerados mantêm o contentor (corte, desfocagem) e são recodificados com os codecs
    habituais; mantêm duração e áudio.], [A cópia direta só corta em _keyframes_; alterar píxeis obriga a
    recodificar.], [COMP-002, OUTPUT-001],
    [DQ-014], [Os resultados ficam no projeto; para continuar a editar, copiam-se para um novo projeto.],
    [Substitui o encadeamento no MVP.], [RESULT-001, RESULT-003, FRAME-008],
    [DQ-015], [Extração: máximo de 100 imagens por vídeo (†), PNG ou JPEG, na resolução do vídeo.], [Protege
    armazenamento; compatibilidade com as ferramentas de imagem.], [FRAME-015, FRAME-023, FRAME-047],
    [DQ-016], [Corte: excerto de pelo menos 1 s e precisão de ±1 s (†); o mesmo intervalo para todos os
    vídeos.], [Valores verificáveis.], [TRIM-015, TRIM-022, TRIM-034],
    [DQ-017], [Desfocagem: detetor YuNet local, objetivo de 90 % (†), todas as caras, aviso e descarte quando
    não há caras, pré-visualização de um frame.], [Modelo leve em CPU; âmbito do MVP.],
    [BLUR-004, 005, 010, 013, 014, 023],
    [DQ-018], [Conversão: entrada MP4/MOV H.264/AAC até 500 MB e 10 min, saída MP4 ou WebM, 720p/1080p por
    perfil, estimativa por amostras com erro ≤ 20 % (†), resultado na biblioteca.], [Formatos reproduzíveis nos
    navegadores; diferenciação de perfis.], [CONV-006, 015, 022, 024, 026, 033, 035, 037, 042, 046],
    [DQ-019], [Legendas: faster-whisper "small" local em CPU, faixa WebVTT por vídeo e idioma, reutilizada
    enquanto o vídeo não muda; uma geração por vídeo; mensagens idempotentes.], [Custo de inferência; formato
    nativo do navegador.], [SUB-003, 006, 010, 013, 014, 015],
    [DQ-020], [Caras e vozes são processadas apenas em componentes do PictuRAS, sem serviços externos.],
    [Dados pessoais (RGPD, R3).], [BLUR-042, SUB-013],
  ),
) <tab-dq>

== Realização e verificação dos requisitos

Estado à data de 2026-10-20 (ramo `main`). Os componentes estão descritos na tabela de componentes (8.1) e
os testes no Capítulo 10. "Inspeção" indica verificação por leitura de código ou de configuração.

#tab([Realização e verificação dos requisitos],
  tabela(
    colunas: (2.6cm, 3.2cm, 2cm, 2.6cm, 1fr),
    tamanho: 8pt,
    [Requisito], [Componente(s)], [Estado], [Teste(s)], [Resultado / observações],
    [SUBMIT-001], [P-UPLOAD, GW, ST, FE-MEDIA], [Implementado], [TST-FRAME-11, TST-TRIM-13], [Passa (MP4); WebM e MOV verificados manualmente (TST-SUBMIT-M1)],
    [SUBMIT-002], [P-UPLOAD], [Implementado], [TST-TRIM-13, TST-SUBMIT-01], [Passa: limite do anónimo aceita 10 s; recusa por excesso verificada por inspeção, sem teste automático],
    [SUBMIT-003], [P-UPLOAD], [Implementado], [TST-SUBMIT-01], [Passa (ficheiro falso recusado)],
    [SUBMIT-004], [P-UPLOAD], [Implementado], [TST-FRAME-11], [Passa],
    [SUBMIT-005], [FE-MEDIA], [Implementado], [TST-SUBMIT-M1], [Passa (manual)],
    [PIPE-001], [FE-TOOLS, P-RULES], [Implementado], [TST-FRAME-13, TST-TRIM-09, TST-BLUR-03, TST-CONV-13, TST-SUB-02], [Passa],
    [PIPE-002], [P-ROUTES, FE-PAGE], [Implementado], [TST-SUB-05, TST-FRAME-13, TST-CONV-13], [Passa],
    [PIPE-003], [P-RULES, P-ROUTES], [Implementado], [TST-FRAME-07, 13, TST-TRIM-09, TST-BLUR-03, TST-SUB-06], [Passa],
    [PIPE-004], [P-RULES, P-ROUTES], [Implementado], [TST-FRAME-10, 12, TST-TRIM-08, TST-BLUR-02, TST-CONV-09, TST-SUB-03, P3], [Passa],
    [PIPE-005], [P-RULES, P-ROUTES], [Implementado], [TST-FRAME-16, TST-TRIM-15, TST-BLUR-14], [Passa],
    [PIPE-006], [P-ROUTES], [Implementado], [TST-BLUR-03, TST-CONV-07], [Passa],
    [PIPE-007], [P-ROUTES (permissões existentes)], [Implementado], [Inspeção], [Mecanismo existente; sem teste automático com partilha de leitura nas ferramentas de imagem/vídeo],
    [QUOTA-001], [P-ROUTES, USERS, P-SUBS], [Implementado], [TST-FRAME-13, TST-BLUR-03, TST-CONV-18, TST-SUB-09], [Passa],
    [QUOTA-002], [P-ROUTES, USERS, P-SUBS], [Implementado], [TST-FRAME-17, TST-SUB-09], [Passa (falha); devolução no cancelamento por inspeção],
    [QUOTA-003], [P-ROUTES, USERS], [Implementado], [TST-BLUR-13, TST-CONV-20], [Passa],
    [QUOTA-004], [USERS], [Implementado (existente)], [Inspeção], [Sem teste próprio com conta premium],
    [QUOTA-005], [P-ROUTES, P-SUBS], [Implementado], [TST-FRAME-18, TST-BLUR-01, TST-CONV-22, TST-SUB-11], [Passa],
    [RESULT-001], [P-ROUTES, MSG], [Implementado], [TST-TRIM-09, TST-BLUR-03, TST-CONV-15], [Passa],
    [RESULT-002], [P-ROUTES, FE-PAGE, ST], [Implementado], [TST-TRIM-14, TST-CONV-21], [Passa (descarga e `ffprobe`); reprodução no navegador manual],
    [RESULT-003], [P-ROUTES], [Implementado], [TST-FRAME-15, TST-TRIM-12, TST-BLUR-12], [Passa],
    [RESULT-004], [P-ROUTES], [Implementado], [TST-FRAME-15, TST-TRIM-12], [Passa; persistência ao longo do tempo não testada],
    [RESULT-005], [P-TEMP, W-\*], [Implementado], [TST-CONV-10], [Passa (varrimento); eliminação imediata por inspeção],
    [STATUS-001], [P-ROUTES], [Implementado (existente)], [Baterias e2e], [Passa: os testes correm sem navegador],
    [STATUS-002], [W-\*, WS, FE-PAGE], [Parcial], [Inspeção], ["Em fila" e "Em curso" só com a página aberta; ao regressar, vêem-se os resultados mas não o estado],
    [STATUS-003], [W-\*, WS, FE-PAGE], [Implementado], [TST-TRIM-16, TST-FRAME-20, TST-BLUR-08], [Passa],
    [STATUS-004], [P-ROUTES (existente)], [Implementado], [Inspeção], [Mecanismo existente; sem teste automático],
    [STATUS-005], [WS, FE-PAGE], [Parcial], [Inspeção], [Aviso de fim só com a página aberta],
    [STATUS-006], [MSG, W-\*, FE-PAGE], [Implementado], [TST-FRAME-17, 20, TST-SUB-07], [Passa],
    [STATUS-007], [W-\*, P-ROUTES], [Implementado], [TST-FRAME-17, TST-BLUR-W1], [Passa],
    [SUB-001], [FE-TOOLS, P-SUBS], [Implementado], [TST-SUB-01, 02, P1], [Passa],
    [SUB-002], [W-SUB, P-SUBS], [Implementado], [TST-SUB-INF, TST-SUB-08], [Passa com fala portuguesa e inglesa (TST-SUB-INF); TST-SUB-08 exige um vídeo com fala],
    [SUB-003], [P-SUBS, ST], [Implementado], [TST-SUB-U, TST-SUB-INF], [Passa],
    [SUB-004, SUB-005], [FE-TOOLS, FE-MEDIA], [Implementado], [TST-SUB-CHR], [Passa (Chromium, API simulada)],
    [SUB-006], [P-SUBS], [Implementado], [TST-SUB-U, TST-SUB-10], [Passa],
    [SUB-007], [W-SUB, P-SUBS], [Implementado], [TST-SUB-U, TST-SUB-INF], [Passa],
    [SUB-008, SUB-009], [W-SUB], [Implementado], [TST-SUB-PY, TST-SUB-07, TST-SUB-INF], [Passa],
    [SUB-010], [P-SUBS], [Implementado], [TST-SUB-U], [Passa (12 pedidos concorrentes)],
    [SUB-011], [P-SUBS (rotas)], [Implementado], [TST-SUB-U], [Passa],
    [SUB-012], [P-SUBS, ST], [Implementado], [TST-SUB-U], [Passa],
    [TRIM-002, 003, 004], [FE-TOOLS], [Implementado], [TST-TRIM-M1, TST-TRIM-01], [Passa (manual); TRIM-004 não verificado no navegador],
    [TRIM-006, 051], [W-TRIM], [Implementado], [TST-TRIM-09, 14, PY], [Passa],
    [TRIM-009, 010, 013], [FE-TOOLS], [Implementado], [TST-TRIM-11], [Recusa no servidor verificada; leitor, hh:mm:ss e desistência por testar no navegador],
    [TRIM-014, 015, 034], [P-RULES, FE-TOOLS, W-TRIM], [Implementado], [TST-TRIM-01 a 05, 07, 10], [Passa],
    [TRIM-023, 049], [FE-TOOLS, P-RULES], [Implementado], [TST-TRIM-09, 13], [Passa],
    [FRAME-002, 003, 006, 009, 013 a 015], [P-RULES, W-FRAMES, FE-TOOLS], [Implementado], [TST-FRAME-01 a 06, 12 a 14, PY], [Passa],
    [FRAME-004], [P-ROUTES, W-FRAMES], [Implementado], [Inspeção], [Pré-visualização por testar no navegador],
    [FRAME-007, 008, 022, 036, 049], [P-ROUTES, W-FRAMES], [Implementado], [TST-FRAME-13, 15], [Passa],
    [FRAME-010], [FE-TOOLS, W-FRAMES], [Implementado], [TST-FRAME-06, PY], [PNG ponta a ponta; JPEG por teste unitário],
    [BLUR-002, 009, 050], [P-RULES, FE-TOOLS, W-BLUR], [Implementado], [TST-BLUR-U1, U2, 11, PY], [Passa],
    [BLUR-004, 005], [W-BLUR], [Implementado], [TST-BLUR-03 (com vídeo com caras)], [Passa no teste da equipa (2 caras detetadas); exige `BLUR_FACE_VIDEO`],
    [BLUR-010], [W-BLUR, P-ROUTES], [Implementado], [TST-BLUR-10], [Passa (pedido e quota); imagem no navegador por confirmar],
    [BLUR-013, 014], [W-BLUR, P-ROUTES, GW, FE-PAGE], [Implementado], [TST-BLUR-04], [Passa],
    [CONV-002, 014, 022, 035], [FE-TOOLS, P-RULES, W-CONV], [Implementado], [TST-CONV-03, 04, 11], [Passa],
    [CONV-003], [P-ROUTES, W-CONV, GW], [Implementado], [TST-CONV-12, TST-CONV-M1], [Passa (API); defeito encontrado no navegador e corrigido (D-02, 10.3)],
    [CONV-005, 009, 010], [W-CONV], [Implementado], [TST-CONV-13, 21, PY], [Passa],
    [CONV-006, 033, 036], [P-ROUTES], [Implementado], [TST-CONV-17, 19], [Passa],
    [CONV-008], [P-ROUTES, FE-PAGE], [Implementado], [TST-CONV-15], [Passa],
    [CONV-011, 047], [FE-TOOLS, P-ROUTES], [Implementado], [TST-CONV-07, 13], [Passa (CONV-047); perfis predefinidos por inspeção],
    [CONV-015, 026, 037], [P-RULES, W-CONV], [Implementado], [TST-CONV-05, 06, 20, PY], [Passa],
    [CONV-017], [FE-TOOLS, W-CONV], [Implementado], [TST-CONV-02, 13], [Passa com confirmação; a recusa sem confirmação foi observada numa execução ponta a ponta durante a implementação, mas não tem teste automático próprio],
    [BLUR-023], [W-BLUR], [Por medir], [—], [Falta o conjunto de teste anotado (UC-VID-004/A8)],
    [BLUR-041], [W-BLUR], [Implementado], [TST-BLUR-W2], [≈ 0,5× a duração (640×360)],
    [BLUR-042, SUB-013], [W-BLUR, W-SUB], [Implementado], [Inspeção], [Modelos na imagem ou no volume; sem chamadas externas no código],
    [COMP-001], [W-\*], [Implementado], [TST-FRAME-M1, TST-BLUR-W1], [MP4, WebM, MOV verificados; H.265 por testar],
    [COMP-002], [W-TRIM, W-BLUR], [Implementado], [TST-TRIM-14, TST-BLUR-W1, PY], [Passa],
    [CONV-024], [W-CONV], [Implementado], [TST-CONV-16], [Passa: erro de 8 % (222 892 vs. 205 754 bytes); uma só amostra],
    [CONV-039], [P-ROUTES], [Implementado], [TST-CONV-19], [Passa],
    [CONV-042, CONV-046], [W-CONV], [Implementado], [TST-CONV-05, 20, 21], [Passa (WebM VP9/Opus; MP4 por teste unitário)],
    [CONV-045, FRAME-025, FRAME-046, TRIM-043, SUB-016], [W-\*], [Por medir], [—], [Não houve medições com vídeos longos],
    [FRAME-023, FRAME-047], [W-FRAMES], [Implementado], [TST-FRAME-19, 15], [Passa],
    [MAINT-001], [P-RULES, INFRA, Tools/utils], [Implementado], [Inspeção], [Cada ferramenta foi acrescentada sem alterar os _workers_ anteriores; o módulo partilhado `video.py` foi introduzido depois, sem mudar comportamento],
    [OUTPUT-001], [W-BLUR, W-CONV], [Implementado], [TST-CONV-21, TST-BLUR-06, W1, PY], [Passa (10,015 s para 10 s); verificado também pelos próprios _workers_],
    [PERF-001], [P-ROUTES], [Implementado], [TST-CONV-14], [Passa com vídeo pequeno; com vídeos grandes a cópia já não bloqueia a resposta],
    [PERF-002], [INFRA], [Implementado], [Inspeção], [5 consumidores por fila (1 nas legendas); sem teste de carga],
    [PORT-001, SUB-017], [INFRA], [Implementado], [Toda a bateria], [`docker compose up --build` num ambiente com Docker; imagens base fixadas],
    [REL-001], [W-\*, P-ROUTES], [Implementado], [TST-FRAME-17, TST-BLUR-W1], [Passa],
    [SEC-001], [W-\*], [Implementado], [TST-BLUR-07, TST-SUB-INF, inspeção], [Passa (hash igual)],
    [SEC-002], [P-ROUTES, P-SUBS], [Implementado (existente)], [TST-SUB-U, inspeção], [Passa nas legendas],
    [SEC-003], [ST (existente)], [Implementado], [Inspeção], [Ligações assinadas com expiração de 1 h],
    [STATUS-008], [W-\*, WS], [Implementado], [TST-TRIM-16, TST-FRAME-20, TST-BLUR-08], [≈ 1 s],
    [SUB-014], [W-SUB], [Implementado], [TST-SUB-TR], [Passa (mesmo recibo sem nova inferência)],
    [SUB-015], [FE-MEDIA], [Implementado], [TST-SUB-CHR], [Passa (Chromium)],
    [TRIM-022], [W-TRIM], [Implementado], [TST-TRIM-14], [Passa (1,500 s exatos)],
  ),
) <tab-realizacao>
