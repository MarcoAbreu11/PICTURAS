# Revisão do relatório da Fase 1 — incoerências encontradas

Relatório revisto: `relatorio/doc-ext-requisitos.pdf` (72 páginas, Typst 0.14).
Comparado com: diretrizes da Fase 1 (`docs/fase-1-guidelines.pdf`), enunciado
(`docs/202609_pictoRAS_Enunciado_Base__v1 (1).pdf`), documento de requisitos de base
(`docs/doc-ext-requisitos.pdf`, RAS 2025/2026) e documento de solução arquitetural
(`docs/doc-sol-arquitetural.pdf`). Data da revisão: 2026-10-23.

## A. Diagramas (introduzidos na simplificação dos diagramas; os mais graves)

1. ✅ **Corrigido:** redesenhado com a disposição do diagrama de base (SVG gerado por
   `images/src/diagrama_casos_uso.py`): IDs e nomes do capítulo 4, Anónimo com associações próprias
   (sem herdar do Utilizador), "Utilizador Convidado" mantido (nome do diagrama de base) e nota da
   conversão ao lado do UC-VID-005. **Diagrama de casos de uso (3.2) contradiz a RNG-04.** O Anónimo herda de Utilizador, e o
   Utilizador está ligado aos 5 casos de uso de vídeo, o que se lê como "o anónimo acede a tudo".
   - Os UC-VID-nnn não aparecem identificados.
   - Os nomes não coincidem com os do capítulo 4 ("Gerar legendas" em vez de "Gerar legendas
     automáticas", etc.).
   - O convidado chama-se "Utilizador Convidado", mas "Convidado por Link" no resto do relatório.
2. ✅ **Corrigido:** acrescentados Trabalho de Processamento (estado, progresso, causa da falha) e
   Resultado; "Legenda" passou a "Faixa de Legendas"; "Gratuito" a "Registado"; a biblioteca aparece nas
   associações "contém (biblioteca)"; texto da 3.3 alinhado. **Modelo de domínio (3.3) incompleto e com nomes diferentes.**
   - Falta "Trabalho de Processamento", que as diretrizes pedem e que os casos de uso e o
     glossário usam.
   - Falta "Biblioteca" (RNG-08, UC-VID-005).
   - "Legenda" não coincide com "Faixa de legendas" do glossário.
   - "Gratuito" não coincide com "registado", usado no resto do texto.
3. **Diagrama de sequência (8.3) contradiz o texto e a vista de componentes.**
   - Mostra `projects → ws_gateway` direto; o texto diz que passa pela `ws_queue` do RabbitMQ.
   - Mostra `projects → frontend` sem passar pelo `api_gateway`.
4. **Secção 9.2** diz "diagramas em PlantUML", mas o modelo de domínio é agora SVG gerado por
   `images/src/modelo_dominio.py`.

## B. Contradições internas

5. ✅ **Parcial: unitários do projects resolvidos.** O teste do ciclo de vida das legendas passou a
   correr contra o `projects_mongoDB` (arquitetura existente; base temporária apagada no fim) em vez de
   uma MongoDB à parte na porta 27028. Com ele a correr, `node --test` dá **59/59** (2026-10-23), por isso
   ficam 59 na Introdução, em 10.2 e na Conclusão; 10.1 e o Anexo A foram atualizados. 95 vs 101 resolvido: 106 verificações
   (conversão repetida a 2026-10-23). Falta acertar as datas de 10.2.
   **Números dos testes:**
   - **Unitários do projects:** 59 na Introdução (1.3) e na Conclusão, 36 de 37 em 10.2. Os 37
     são os testes de topo dos ficheiros e os 59 são os casos dentro deles; é preciso usar o
     mesmo critério nos três sítios.
   - **Ponta a ponta:** 101 verificações em 10.2, mas 95 na Conclusão.
   - **Datas:** 10.2 diz que as execuções repetidas são as de 2026-10-20, mas os totais referem
     a execução de 2026-10-21.
6. **Conclusão** diz "o ciclo… está fechado para todos os requisitos", mas há 6 requisitos
   "Por medir" em 7.3 (BLUR-023, CONV-045, FRAME-025, FRAME-046, TRIM-043, SUB-016).
7. ✅ **Corrigido no código e no relatório:** os convidados continuam a ver o projeto; só os vídeos convertidos
   e os resultados da conversão ficam escondidos (`projects/routes/projects.js`, `visibleItems`/`visibleResults`);
   TST-CONV-19 com 6 verificações novas (incluindo pré-visualizar, apagar e processar como convidado); e2e 23/23. **CONV-039** restringe ao dono "os vídeos convertidos e os projetos que os contêm". Um projeto
   partilhado ficaria inacessível aos convidados depois de uma conversão, o que contradiz a
   RNG-09 e a PIPE-007.
8. ✅ **Corrigido:** o UC-VID-005 ganhou a FA6 (cancelar); STATUS-004, QUOTA-002 e 7.1 atualizados.
   **Cancelamento no UC-VID-005:** a STATUS-004 cita "UC-VID-005 (cancelar)" e a 5.3 diz que o
   cancelamento se aplica a todos, mas o UC-VID-005 não tem fluxo de cancelamento.
9. ✅ **Corrigido nos 5 casos de uso:** pré-condições de perfil e de quota retiradas; exceções reescritas
   como fluxos com passos numerados e fim explícito; todos os FA com retorno; UC-VID-003 ganhou a
   Exceção 8 (anónimo).
   **Pré-condição contra exceção:**
   - **UC-VID-001:** a pré-condição exige sessão registada, mas a Exceção 1 trata o anónimo.
   - **UC-VID-004 e UC-VID-005:** a pré-condição exige quota disponível, mas a Exceção 2/5 trata
     a quota esgotada.
10. ✅ **Corrigido (Estado "Novo" e frase alterada).** **Stakeholders (2.2):** "Proprietário do sistema" não existe no documento de base, mas está
    marcado "Revisto". O texto logo a seguir diz que "não surgiram novos tipos de stakeholder".
    O template dá precisamente "Proprietário do sistema — Novo — custo de
    processamento/armazenamento" como exemplo, e os 5 casos de uso usam-no. Correção: manter o
    stakeholder, marcá-lo "Novo" e trocar a frase.
11. ✅ **Corrigido (Estender, com UC-VID-005/FA6 e QUOTA-002).** **Impacto (Cap. 6):** o cancelamento (T-01, T-10) está como "Manter", mas a descrição é de
    uma extensão (passa a remover os vídeos convertidos).
12. ✅ **Corrigido (nova UC-VID-001/RN9; origem passa a RN9, RNG-08, DQ-020; linha na 7.1).** **Origem da SUB-012:** cita a UC-VID-001/RN7 e a RNG-10, mas nenhuma trata da eliminação das
    faixas.
13. ✅ **Corrigido (referências aos Exercícios 1 e 2 removidas do relatório).** **Secção 2.3** diz que os casos de uso foram escritos nos Exercícios 1 e 2, mas, segundo o
    histórico de versões, só o UC-VID-002 a 005 o foram; o UC-VID-001 veio depois.

## C. Face ao enunciado e às diretrizes

14. ✅ **Corrigido (trocado por "fora do MVP / trabalho futuro" nos 8 sítios).** **Funcionalidades adiadas "para a Fase 2"** (RNG-06, PIPE-004, DQ-003, DA-03,
    UC-VID-002/Q9, UC-VID-003/Q9–Q10). No enunciado, a Fase 2 é refactoring de requisitos não
    funcionais "sem introduzir novas funcionalidades"; o termo certo é "fora do MVP" ou
    "trabalho futuro".
15. **Requisitos implementados verificados só por "Inspeção", sem teste:** PIPE-007, QUOTA-004,
    STATUS-004, FRAME-004, PERF-002, SEC-003, MAINT-001 e BLUR-042/SUB-013. A lista de
    verificação das diretrizes pede pelo menos um teste por requisito implementado.
16. **Falta a configuração dos agentes no repositório** (`.claude/skills/…/SKILL.md`,
    `CLAUDE.md`), que as diretrizes listam como entregável. O relatório admite a lacuna (9.1).

## D. Menores

17. ✅ **Corrigido (limites por perfil passam a proposta da equipa, com (†) na 2.1, RNG-02 e DQ-004).** **Marca (†):** os limites do premium (500 MB / 10 min) têm (†) na CONV-026 e na CONV-037,
    mas não na RNG-02 nem na tabela 2.1.
18. ✅ **Corrigido (CONV-002, 022 e 035 passaram a NOVO; CONV-014 fica ALT (RF64); Cap. 6 ajustado).** **ALT (RF64):** a RF64 de base é a sugestão de upgrade. Serve de origem à CONV-014, mas não
    à CONV-022 nem à CONV-035, que só limitam a resolução.
19. ✅ **Corrigido (SUBMIT-001 e 004: ALT ("Carregar imagens"); SUBMIT-005: ALT (visualização dos itens); legenda da ERS e Cap. 6 ajustados).** **ALT (UC04) no carregamento:** a SUBMIT-001, 004 e 005 estão marcadas ALT (UC04), mas o
    carregamento é outro caso de uso de base ("Carregar imagens").
20. ~~Stakeholder do armazenamento~~ — **retirado.** Um serviço (MinIO, SeaweedFS, IA externa) é um
    sistema externo, não um stakeholder; o relatório não tem de rever o "Serviço Cloud (MinIO)"
    que o documento de base pôs na tabela.
21. ✅ **Corrigido** (UC-VID-005: "carregado e validado"). **Pré-condições:** o UC-VID-005 diz "vídeo carregado" e os outros dizem "carregado e
    validado".
22. ✅ **Corrigido:** a RNG-04 foi dividida em RNG-04 (anónimo: só o corte) e RNG-11 (registado e
    premium: todas as ferramentas; registado com quota, premium sem limite); referências atualizadas.
    **Redação da RNG-04:** "registado ou premium, que não tem limite diário" pode ler-se como se
    o registado também não tivesse limite.

## D2. Afirmações sobre a base, verificadas no repositório original (picturas-um/picturas-27) — corrigidas

25. ✅ **Origem dos valores (2.3) e RNG-02:** os limites de carregamento por perfil não existem no
    original (`media.js` foi criado pela equipa a 2026-10-17); passaram de "limites já existentes" a
    "propostas da equipa", com (†).
26. ✅ **Cópia de resultados para um novo projeto (Cap. 6):** estava como "Alterar — copiava só
    imagens", mas a funcionalidade não existia no original (introduzida no commit 28c3917, UC-VID-003);
    passou a "Estender — não existia na base".
27. ✅ **Pré-visualização (Cap. 6 e FRAME-004):** "recusava vídeos" passou a "só tratava imagens" (a base
    não tinha vídeo).
28. ✅ **Imagens base fixadas (DA-11, 7.3, T-20):** só o `projects` e os workers de vídeo têm versões
    fixadas; o `api_gateway`, o `users` e o `subscriptions` continuam com `node` sem versão. T-20 passou a
    "Corrigido no projects; pendente nos restantes".

29. ✅ **DA-06 (8.2):** "Antes, o /process descarregava e validava cada vídeo" misturava a base (que
    descarregava todos os ficheiros, T-19) com a primeira versão da equipa (que validava os vídeos); a
    frase passou a distinguir as duas.

Confirmado no original e correto no relatório: quota de 5 operações/dia (`users/routes/users.js`),
expiração de 1 h das ligações assinadas, nginx sem `client_max_body_size` (T-12), devolução de
operações só no cancelamento, conflito 409 (T-18), filtro de tipos só no frontend (T-17) e commit de
partida 781a63e (último do original). Também confirmados: anónimo sem ferramentas avançadas e
premium sem limite (RNG-04, QUOTA-004), permissão de edição nas partilhas (PIPE-007), resultados
substituídos na execução seguinte (RNG-08), eventos de fim do processamento no ws_gateway (DA-05),
volume `image_data` partilhado (DA-04), `.zip` no carregamento (RNG-01), grelha e carrossel, rotas
`/process/:n` e `/process/refund/:n` do users, e as tarefas T-14, T-15, T-16, T-21, T-23, T-25 e T-26.

## E. Limpeza antes de gerar o `src-doc-ext-requisitos.zip`

23. **README de `relatorio/`:** ainda é o README do template.
24. **Ficheiros Mermaid:** os `.mmd` e o `mermaid-config.json` em `relatorio/images/src` já não
    são usados.

## O que está bem

- **Requisitos:** os 125 IDs são referidos corretamente, todos têm origem em 7.1/7.2 e linha em
  7.3, e nenhum ID substituído (5.4) é usado noutro sítio.
- **RNG, DQ e DA:** RNG-01 a 10, DQ-001 a 021 e DA-01 a 11 batem certo com o que é referido.
- **Repositório:** os commits citados (781a63e, 28c3917, af277ef, 809439d, 329e31a, 0c0c9c0,
  8a9729d) e os ficheiros citados existem.
- **Documentos de base:** as referências estão corretas (UC05–07, RF39–73, RNF43–66, T-01 a
  T-11, que existem nos dois documentos de base).

Não foi confirmado que cada teste citado passa de facto, porque isso exige voltar a correr as
baterias com a stack ligada.
