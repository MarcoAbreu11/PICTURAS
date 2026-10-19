# Exercício 1 — Casos de Uso
## Fase 1: Suporte a Vídeo no PictuRAS

## 0. Identificação

| Campo | Valor |
|---|---|
| Grupo / Equipa | [preencher] |
| Autores | Diogo Linhares Campos - PG63948<br>Marco António Ferreira Abreu - PG64003<br>Cláudio Rafael Oliveira Ferreira - PG63933<br>Nelson Daniel Araújo Sousa - PG64010 |
| Data | 2026-10-19 |
| Versão do documento | v1.3 |
| Unidade Curricular | Requisitos e Arquiteturas de Software — MEI, Universidade do Minho |

---

## 1. Funcionalidade de vídeo escolhida

| Campo | Valor |
|---|---|
| Funcionalidade | Ferramenta de vídeo "Desfocar caras": deteta automaticamente as caras presentes em cada vídeo do projeto e gera um novo vídeo com essas caras desfocadas ou pixelizadas, como mais uma ferramenta da pipeline de edição |
| Perfil(s) de utilizador abrangido(s) | Registado e premium. É uma ferramenta avançada, como as ferramentas de IA de imagem já existentes: o perfil registado consome uma operação da quota diária por vídeo processado, o premium não tem limite diário e o anónimo não tem acesso. Aplicam-se os limites de vídeo de cada perfil definidos no carregamento. |

### Justificação no contexto do MVP

A desfocagem automática de caras permite anonimizar vídeos antes da sua publicação, respondendo a preocupações de privacidade e RGPD. Valida a parte do suporte a vídeo que o corte (UC-VID-002) e a extração de frames (UC-VID-003) não cobrem: uma ferramenta de vídeo que analisa o conteúdo de cada frame com visão computacional, é demorada e está sujeita à quota, à semelhança das ferramentas avançadas já existentes para imagens.

---

# 2. Caso de Uso

## 2.1 Cabeçalho

| Secção | Detalhes |
|---|---|
| ID do Caso de Uso | UC-VID-004 |
| Nome | Desfocar caras de um vídeo |
| Versão | v1.3 |
| Autor | Diogo Linhares Campos<br>Marco António Ferreira Abreu<br>Cláudio Rafael Oliveira Ferreira<br>Nelson Daniel Araújo Sousa |
| Data | 2026-10-19 |
| Objetivo | Permitir ao utilizador obter, a partir dos vídeos de um projeto, novos vídeos em que as caras detetadas aparecem desfocadas ou pixelizadas. |
| Âmbito | Serviço `projects` (pipeline de ferramentas e processamento), novo worker de vídeo em `Tools/` e frontend (barra de ferramentas e resultados) |
| Ator Principal | Utilizador registado ou premium, dono do projeto ou com permissão de edição |
| Stakeholders e Interesses | - **Utilizador**: pretende partilhar vídeos sem expor a identidade das pessoas filmadas.<br>- **Proprietário do sistema**: pretende disponibilizar uma ferramenta avançada de vídeo, alinhada com a privacidade, que valorize os perfis registado e premium.<br>- **Equipa de desenvolvimento**: pretende validar o processamento de vídeo frame a frame com visão computacional na pipeline existente. |
| Pré-condições | - O utilizador tem sessão iniciada com um perfil registado ou premium.<br>- O utilizador é dono do projeto ou tem permissão de edição sobre ele.<br>- O projeto contém pelo menos um vídeo, carregado e validado no carregamento (formato, tamanho e duração por perfil).<br>- O utilizador registado tem operações disponíveis na quota diária. |
| Trigger | O utilizador pretende anonimizar as caras presentes nos vídeos de um projeto. |

## 2.2 Fluxo Principal

| Passo | Ação do Ator | Resposta do Sistema |
|---|---|---|
| 1 | O utilizador abre um projeto que contém vídeos e abre um dos vídeos. | O sistema reproduz o vídeo e apresenta a barra de ferramentas com as ferramentas de vídeo disponíveis. |
| 2 | O utilizador escolhe a ferramenta "Desfocar caras". | O sistema apresenta as opções da ferramenta: tipo de anonimização (desfocagem por omissão) e intensidade. |
| 3 | O utilizador define a intensidade e guarda a ferramenta. | O sistema valida as opções e adiciona a ferramenta à pipeline do projeto. |
| 4 | O utilizador carrega em "Aplicar". | O sistema valida a pipeline, verifica o perfil e a quota, debita as operações do perfil registado, cria um trabalho de processamento por vídeo e confirma a receção do pedido. |
| 5 | — | O sistema analisa os frames de cada vídeo, deteta as caras presentes e aplica a desfocagem nas regiões detetadas, atualizando a percentagem de progresso. As imagens do projeto não são processadas por esta ferramenta. |
| 6 | — | O sistema gera, para cada vídeo, um novo vídeo com a mesma duração e o áudio do original. |
| 7 | — | O sistema guarda os novos vídeos como resultados do projeto, identificando cada um com o nome do vídeo de origem, e notifica o utilizador de que o processamento terminou. |
| 8 | O utilizador consulta os resultados. | O sistema apresenta os vídeos anonimizados nos resultados do projeto, prontos a reproduzir e a descarregar. |

## 2.3 Fluxos Alternativos

| Fluxo | Descrição |
|---|---|
| FA1 — Pixelização | No passo 3, o utilizador escolhe a pixelização em vez da desfocagem. O sistema aplica a pixelização às regiões das caras. Continua no passo 3. |
| FA2 — Pré-visualização de um frame | No passo 3, antes de guardar, o utilizador pede a pré-visualização. O sistema processa apenas um frame do vídeo aberto e mostra-o com as caras desfocadas, sem processar o vídeo completo nem consumir operações. Continua no passo 3. |
| FA3 — Processamento em segundo plano | Após o passo 4, o utilizador abandona a página. O processamento continua e, ao regressar, o utilizador vê o estado (em fila, em curso, concluído, falhado ou cancelado) e a percentagem de progresso. |
| FA4 — Nenhuma cara detetada | No passo 7, num vídeo não foi detetada nenhuma cara. O sistema guarda o resultado, informa o utilizador e permite-lhe manter ou descartar esse resultado. |
| FA5 — Continuar a editar os vídeos anonimizados | No passo 8, o utilizador escolhe "Copiar para novo projeto". O sistema cria um projeto com os vídeos anonimizados como vídeos normais, aos quais o utilizador pode aplicar outras ferramentas de vídeo. |
| FA6 — Cancelar processamento | Após o passo 4, enquanto o processamento está em fila ou em curso, o utilizador cancela-o. O sistema termina o processamento, remove os resultados dessa execução e devolve as operações debitadas. |
| FA7 — Projeto com imagens e vídeos | No passo 4, o projeto contém também imagens. O sistema processa apenas os vídeos, debita operações apenas por estes e informa o utilizador do número de itens ignorados. |

## 2.4 Exceções

| Condição | Comportamento do Sistema |
|---|---|
| **Exceção 1** — O utilizador tem um perfil anónimo (passo 2) | O sistema não permite adicionar a ferramenta e indica que é necessário iniciar sessão com um perfil registado ou premium. |
| **Exceção 2** — A quota diária do utilizador registado não chega para os vídeos do projeto (passo 4) | O sistema não inicia o processamento e informa o utilizador. |
| **Exceção 3** — A ferramenta é combinada com outras ferramentas na mesma pipeline (passo 3) | O sistema recusa adicionar a ferramenta e explica que, nesta versão, as ferramentas de vídeo têm de ser a única ferramenta do projeto. |
| **Exceção 4** — O projeto não contém vídeos (passo 4) | O sistema não inicia o processamento e informa que nenhum item é compatível com a ferramenta. |
| **Exceção 5** — As opções estão fora dos valores permitidos (passo 3) | O sistema impede guardar a ferramenta e indica os valores permitidos. |
| **Exceção 6** — Um vídeo está corrompido ou não pode ser descodificado (passo 5) | O sistema marca esse vídeo como falhado, devolve a operação debitada por ele e continua com os restantes vídeos. |
| **Exceção 7** — O processamento de um vídeo falha (passos 5–6) | O sistema remove o resultado parcial desse vídeo, informa a causa, devolve a operação debitada por ele e mantém os resultados dos vídeos concluídos. O vídeo original permanece inalterado. |

## 2.5 Pós-condições

| Tipo | Resultado |
|---|---|
| Garantia de Sucesso | Os vídeos com as caras detetadas desfocadas estão nos resultados do projeto, com a duração e o áudio dos originais, e os vídeos originais permanecem inalterados. |
| Garantia Mínima | Em caso de falha ou cancelamento, não fica nenhum vídeo incompleto nos resultados, os vídeos originais permanecem inalterados, as operações dos vídeos não concluídos são devolvidas e o utilizador é informado. |

## 2.6 Regras de Negócio e Restrições

| ID | Regra |
|---|---|
| RN1 | A desfocagem não altera o vídeo original; é sempre gerado um novo ficheiro. |
| RN2 | "Desfocar caras" é uma ferramenta avançada: disponível apenas para os perfis registado e premium. O perfil registado consome uma operação da quota diária por vídeo processado; o premium não tem limite diário. |
| RN3 | Uma operação só fica consumida quando o vídeo correspondente é processado com sucesso: é debitada no pedido e devolvida em caso de falha ou cancelamento. |
| RN4 | Os vídeos a processar respeitam os limites de duração e tamanho do perfil, validados no carregamento. |
| RN5 | A ferramenta aplica-se apenas a vídeos; as imagens do projeto são ignoradas e não consomem operações. |
| RN6 | O vídeo gerado mantém a duração e o áudio do vídeo original. |
| RN7 | Resultados incompletos não devem ser disponibilizados como válidos. |
| RN8 | No MVP, a ferramenta não pode ser combinada com outras ferramentas na mesma pipeline. |
| RN9 | Só o dono do projeto e os utilizadores com permissão de edição podem adicionar e aplicar a ferramenta; com permissão de leitura, apenas se consultam os resultados. |
| RN10 | As mesmas opções aplicam-se a todos os vídeos do projeto. |
| RN11 | Todas as caras detetadas são anonimizadas; o utilizador não escolhe caras a manter visíveis. |

## 2.7 Assunções

| ID | Assunção |
|---|---|
| A1 | O carregamento e a validação dos vídeos (formatos MP4, WebM e MOV; tamanho e duração por perfil) estão fora do âmbito deste caso de uso e já estão implementados. |
| A2 | A deteção facial usa um modelo executado localmente pelo worker (OpenCV com o detetor YuNet), sem serviços externos. |
| A3 | O processamento pode demorar em vídeos longos e necessita de estados intermédios. |
| A4 | Para o MVP, a deteção não é garantida para caras de perfil, tapadas ou muito pequenas (inferiores a 64×64 px). |
| A5 | Os resultados seguem a regra existente do PictuRAS: são substituídos na execução seguinte da pipeline e eliminados com o projeto; para os manter e continuar a editá-los, copiam-se para um novo projeto (FA5). |
| A6 | Os limites de vídeo por perfil já estão definidos no carregamento: registado 100 MB / 60 s, premium 500 MB / 10 min (o anónimo, 20 MB / 15 s, não tem acesso a esta ferramenta). |
| A7 | A desfocagem é executada por um worker em `Tools/` com OpenCV e `ffmpeg`, alimentado por uma fila RabbitMQ própria; o número de trabalhos simultâneos corresponde ao número de réplicas desse worker. |
| A8 | No MVP uma falha não é retomada automaticamente: o utilizador volta a aplicar a pipeline. |
| A9 | O perfil "registado" corresponde ao tipo `free` no serviço `users`. |
| A10 | A taxa de deteção é medida num conjunto de teste definido pela equipa, com imagens de licença livre ou de pessoas que deram consentimento. |

## 2.8 Questões em Aberto

| ID | Questão |
|---|---|
| Q1 | Deve o utilizador poder escolher quais caras desfocar ou manter visíveis? — **Resolução:** fora do âmbito do MVP; todas as caras detetadas são anonimizadas (RN11, DQ-414). |
| Q2 | Qual a taxa de deteção mínima aceitável para o MVP? — **Resolução:** ≥ 90 % das caras frontais com ≥ 64×64 px (†) no conjunto de teste (BLUR-023, DQ-412). |
| Q3 | Deve ser possível desfocar outros elementos, como matrículas? — **Resolução:** fora do âmbito do MVP (DQ-414). |
| Q4 | Deve a funcionalidade ser exclusiva do perfil premium? — **Resolução:** não; disponível para registados (com quota) e premium (sem limite) (RN2, BLUR-018, BLUR-019, DQ-402). |
| Q5 | Qual a duração máxima de vídeo suportada? — **Resolução:** a definida por perfil no carregamento (A6); esta ferramenta não acrescenta limites (DQ-403). |
| Q6 | Os resultados devem expirar ao fim de algum tempo? — **Resolução:** seguem a regra existente (A5); os vídeos copiados para um projeto mantêm-se até serem eliminados (BLUR-032, DQ-405). |
| Q7 | Os pedidos em fila ou em curso devem contar para a verificação da quota antes de concluírem? — **Resolução:** sim; a operação é debitada no pedido, o que impede ultrapassar a quota com pedidos simultâneos, e é devolvida se o vídeo falhar ou o processamento for cancelado (RN3, BLUR-030, DQ-402). |
| Q8 | A desfocagem deve poder ser seguida de outras ferramentas na mesma pipeline (ex.: cortar e desfocar)? — **Resolução:** não no MVP (RN8); o caminho é copiar os vídeos anonimizados para um novo projeto (FA5, DQ-409). |

---

# 3. Utilização de agentes de IA

| Ferramenta / skill | Tarefa apoiada | Validação realizada pela equipa |
|---|---|---|
| Claude | Apoio na definição do caso de uso, fluxos, exceções, regras de negócio, assunções e questões em aberto. | Revisão manual pela equipa comparando com o enunciado, template e exemplos fornecidos pelos docentes. |
| Claude | Elaboração da ERS do Exercício 2 (secção 4): classificação segundo a ISO/IEC 25010, proposta de valores (†) e decisões de qualidade, catálogo de requisitos, impacto e matriz de rastreabilidade. | [preencher: revisão da equipa] |
| Claude Code | Revisão v1.2: alinhamento com o sistema implementado (carregamento de vídeo e limites por perfil, pipeline de ferramentas, ferramentas avançadas e quota, partilha, falha isolada por vídeo) e com o UC-VID-002 e o UC-VID-003; resultados no projeto em vez de "biblioteca"; requisitos eliminados (4.1.4); renumeração das decisões de qualidade. | [preencher: revisão da equipa] |
| Claude Code | Implementação (v1.3): worker `Tools/blur_faces` (OpenCV/YuNet e `ffmpeg`), alterações ao `projects`, ao `apiGateway` e ao frontend (ferramenta, aviso de nenhuma cara e descarte); testes unitários (`unittest`, `node:test`) e ponta a ponta (`projects/test/e2e/blur.sh`); medição do tempo de processamento; tabela de realização e verificação (4.4). | [preencher: revisão da equipa — p. ex. teste manual no navegador da ferramenta, da pré-visualização e do descarte] |

---

# 4. Especificação de Requisitos do Sistema (ERS)

**Caso de Uso:** UC-VID-004 — Desfocar caras de um vídeo  
**Versão do dossiê:** v1.3  
**Baseline do Exercício 1:** v1.0 — REQ-VID-BLUR-001 a REQ-VID-BLUR-024

> O catálogo 4.1 é a fonte única dos requisitos desta ERS. A matriz 4.3 rastreia esses IDs até ao caso de uso ou às decisões de qualidade (DQ). A tabela 4.2 descreve o impacto no sistema existente. Nas tabelas 4.2 e 4.3 os IDs aparecem abreviados (por exemplo, BLUR-007 = REQ-VID-BLUR-007). Os elementos locais do caso de uso são qualificados (por exemplo, UC-VID-004/RN2). Valores marcados com (†) são propostas da equipa, a confirmar. Os IDs eliminados não são reutilizados (ver 4.1.4). As decisões de qualidade deste caso de uso usam a gama DQ-401 a DQ-499, para não colidirem com as do UC-VID-003 (DQ-001 a DQ-099) e do UC-VID-002 (DQ-101 a DQ-199).

## 4.1 Requisitos da ERS

### 4.1.1 Requisitos Funcionais

| **ID** | **Requisito** | **Prioridade** | **Evolução** | **Novo/Alt** | **Origem (UC / RN / decisão)** | **Justificação** | **Critério de aceitação / verificação** |
|---|---|---|---|---|---|---|---|
| REQ-VID-BLUR-001 | O sistema deve disponibilizar a ferramenta "Desfocar caras" na barra de ferramentas quando o item aberto é um vídeo, permitindo adicioná-la à pipeline do projeto. | Deve ter | Refinado | ALT | UC-VID-004/Trigger, UC-VID-004/Passos 1–2, DQ-401 | Ponto de entrada da funcionalidade, ao lado das restantes ferramentas de vídeo. | Dado um projeto com um vídeo aberto no carrossel, quando um utilizador registado abre a barra de ferramentas, então "Desfocar caras" está disponível. |
| REQ-VID-BLUR-002 | O sistema deve apresentar as opções da ferramenta: tipo de anonimização e intensidade. | Deve ter | Refinado | NOVO | UC-VID-004/Passo 2 | A intensidade determina o grau de anonimização. | Dado a ferramenta aberta, então são apresentados o tipo (desfocagem por omissão) e a intensidade, configurável entre 1 e 10 (†). |
| REQ-VID-BLUR-003 | O sistema deve iniciar o processamento apenas quando o utilizador carrega em "Aplicar" e a validação é bem-sucedida. | Deve ter | Refinado | NOVO | UC-VID-004/Passo 4 | Evita processamentos demorados e consumo de quota por engano. | Dado opções válidas, quando carrega em "Aplicar", então o processamento inicia; sem "Aplicar", nada é processado nem debitado. |
| REQ-VID-BLUR-004 | O sistema deve detetar as caras presentes nos frames de cada vídeo. | Deve ter | Refinado | NOVO | UC-VID-004/Passo 5, DQ-412 | Sem deteção não há o que desfocar. | Dado um vídeo com uma cara frontal, então a cara é detetada nos frames onde aparece. |
| REQ-VID-BLUR-005 | O sistema deve aplicar a desfocagem às regiões de todas as caras detetadas. | Deve ter | Refinado | NOVO | UC-VID-004/Passo 5, UC-VID-004/RN11, DQ-414 | Núcleo funcional do caso de uso. | Dado uma cara detetada, então a região da cara aparece desfocada no vídeo gerado e o resto do frame não é alterado. |
| REQ-VID-BLUR-006 | O sistema deve gerar, para cada vídeo, um novo vídeo que mantém o áudio original. | Deve ter | Refinado | NOVO | UC-VID-004/Passo 6, UC-VID-004/RN6 | O vídeo anonimizado tem de manter o áudio. | Dado um vídeo com áudio, então o vídeo gerado tem uma faixa de áudio com o mesmo conteúdo. |
| REQ-VID-BLUR-007 | O sistema deve guardar os vídeos anonimizados como resultados do projeto, identificando cada um com o nome do vídeo de origem. | Deve ter | Refinado | ALT | UC-VID-004/Passo 7, UC-VID-004/Pós-condição de sucesso, DQ-401 | O PictuRAS guarda o resultado das ferramentas nos resultados do projeto. | Dado o processamento concluído de "aula.mp4", então os resultados contêm um vídeo cujo nome contém "aula". |
| REQ-VID-BLUR-008 | O sistema deve permitir reproduzir e descarregar os vídeos anonimizados a partir dos resultados do projeto. | Deve ter | Refinado | ALT | UC-VID-004/Passo 8 | O utilizador tem de poder ver e levar o resultado. | Dado um vídeo anonimizado nos resultados, quando o utilizador o abre, então pode reproduzi-lo; quando descarrega os resultados, então o vídeo está incluído. |
| REQ-VID-BLUR-009 | O sistema deve permitir ao utilizador escolher entre desfocagem e pixelização das caras. | Deveria ter | Mantido | NOVO | UC-VID-004/FA1 | Algumas situações pedem pixelização em vez de desfocagem. | Dado a escolha pixelização, então as caras aparecem pixelizadas no vídeo gerado. |
| REQ-VID-BLUR-010 | O sistema deve mostrar um frame do vídeo aberto com a anonimização aplicada antes de processar o vídeo completo, sem consumir operações. | Deveria ter | Refinado | ALT | UC-VID-004/FA2, DQ-416 | Evita processar o vídeo completo com opções inadequadas. | Dado o pedido de pré-visualização, então é mostrado um frame com as caras anonimizadas e a quota não muda. |
| REQ-VID-BLUR-011 | O sistema deve continuar o processamento quando o utilizador abandona a página. | Deve ter | Mantido | ALT | UC-VID-004/FA3 | Operação demorada; reutiliza o processamento assíncrono existente. | Dado um processamento em curso, quando fecha e volta a abrir o projeto, então os vídeos anonimizados surgem nos resultados no fim. |
| REQ-VID-BLUR-012 | O sistema deve apresentar o estado do processamento (em fila, em curso, concluído, falhado ou cancelado). | Deve ter | Refinado | ALT | UC-VID-004/A3, UC-VID-004/FA3, DQ-408 | Permite acompanhar uma operação que não é instantânea. | Dado um processamento em curso, quando o utilizador volta ao projeto, então o estado é visível. |
| REQ-VID-BLUR-013 | O sistema deve informar o utilizador quando não for detetada nenhuma cara num vídeo. | Deve ter | Refinado | NOVO | UC-VID-004/FA4, DQ-417 | Pode indicar falha de deteção ou vídeo sem pessoas. | Dado um vídeo sem caras, quando o processamento termina, então o resultado desse vídeo surge com o aviso "nenhuma cara detetada". |
| REQ-VID-BLUR-014 | O sistema deve permitir ao utilizador manter ou descartar o resultado de um vídeo em que não foi detetada nenhuma cara. | Deveria ter | Refinado | NOVO | UC-VID-004/FA4, DQ-417 | Evita guardar um vídeo praticamente igual ao original sem o utilizador querer. | Dado o aviso de nenhuma cara, quando escolhe "Descartar", então esse resultado é removido e os restantes mantêm-se. |
| REQ-VID-BLUR-016 | O sistema deve marcar como falhado o vídeo que não pode ser descodificado, indicando a causa, e continuar com os restantes vídeos. | Deve ter | Refinado | NOVO | UC-VID-004/Exceção 6, DQ-404 | Um vídeo problemático não deve impedir os restantes. | Dado um projeto com um vídeo corrompido e um válido, quando aplica, então o corrompido fica "falhado" com mensagem e o válido gera resultado. |
| REQ-VID-BLUR-018 | O sistema deve recusar iniciar o processamento quando a quota diária do utilizador registado não chega para os vídeos do projeto. | Deve ter | Refinado | ALT | UC-VID-004/Exceção 2, UC-VID-004/RN2, DQ-402 | Aplica a regra de quotas existente das ferramentas avançadas. | Dado um registado com 1 operação disponível e 2 vídeos no projeto, quando aplica, então o processamento não inicia e é informado. |
| REQ-VID-BLUR-019 | O sistema não deve aplicar limite diário de operações de desfocagem a utilizadores premium. | Deve ter | Mantido | ALT | UC-VID-004/RN2, UC-VID-004/Q4, DQ-402 | Explicita que a funcionalidade não é exclusiva do premium e que este não tem limite. | Dado um premium com muitas operações no dia, quando aplica a desfocagem, então o processamento inicia. |
| REQ-VID-BLUR-026 | O sistema deve apresentar a percentagem de progresso da desfocagem de cada vídeo. | Deveria ter | Mantido | ALT | UC-VID-004/Passo 5, UC-VID-004/FA3, DQ-408 | Operação que dura minutos; o estado por si só não permite estimar o tempo restante. | Dado um processamento em curso, quando o utilizador consulta o estado, então vê uma percentagem entre 0 % e 100 % que não diminui. |
| REQ-VID-BLUR-027 | O sistema deve permitir cancelar o processamento em fila ou em curso, reutilizando o cancelamento existente. | Deve ter | Refinado | ALT | UC-VID-004/FA6, DQ-408 | Evita ocupar capacidade e quota com pedidos desnecessários. | Dado um processamento em curso, quando o utilizador cancela, então o estado passa a "cancelado" e não fica nenhum resultado dessa execução. |
| REQ-VID-BLUR-028 | O sistema deve notificar o utilizador quando o processamento termina, com sucesso ou com falha. | Deveria ter | Mantido | ALT | UC-VID-004/Passo 7, UC-VID-004/FA3, DQ-408 | Com processamento em segundo plano, o utilizador precisa de saber quando voltar. | Dado um processamento em segundo plano, quando termina, então surge uma notificação com o resultado. |
| REQ-VID-BLUR-029 | O sistema deve apresentar, para cada vídeo cujo processamento falha, uma mensagem com a causa em linguagem corrente. | Deve ter | Refinado | ALT | UC-VID-004/Exceção 7, UC-VID-004/Pós-condição mínima, DQ-404 | O utilizador precisa de perceber se pode repetir ou se o vídeo tem um problema. | Dado uma falha injetada na desfocagem de um vídeo, quando o utilizador consulta o estado, então vê "falhado" e a causa. |
| REQ-VID-BLUR-030 | O sistema deve debitar uma operação por vídeo ao utilizador registado no pedido e devolvê-la se o processamento desse vídeo falhar ou for cancelado. | Deve ter | Refinado | ALT | UC-VID-004/RN3, UC-VID-004/Q7, UC-VID-004/Pré-condições, DQ-402 | Falhas e cancelamentos não devem penalizar o utilizador; debitar no pedido impede ultrapassar a quota com pedidos simultâneos. | Dado um registado com 5 operações e 2 vídeos, um deles corrompido, quando aplica, então no fim tem 4 operações disponíveis; quando cancela antes do fim, então volta a ter 5. |
| REQ-VID-BLUR-031 | O sistema deve impedir utilizadores anónimos de adicionar a ferramenta "Desfocar caras". | Deve ter | Mantido | ALT | UC-VID-004/Exceção 1, UC-VID-004/RN2, DQ-402 | O caso de uso abrange apenas utilizadores registados e premium. | Dado uma sessão anónima, quando tenta adicionar a ferramenta, então é recusado com indicação para iniciar sessão e a pipeline não muda. |
| REQ-VID-BLUR-032 | O sistema deve manter os vídeos anonimizados copiados para um projeto até o utilizador os eliminar. | Deve ter | Refinado | NOVO | UC-VID-004/FA5, UC-VID-004/Q6, DQ-405 | Os vídeos copiados deixam de depender dos resultados, que são substituídos na execução seguinte. | Dado vídeos copiados há 30 dias, quando o utilizador abre o projeto, então continuam disponíveis. |
| REQ-VID-BLUR-033 | O sistema deve eliminar os ficheiros temporários da desfocagem até 1 h (†) após o termo do processamento, com sucesso, falha ou cancelamento. | Deve ter | Mantido | NOVO | UC-VID-004/Pós-condição mínima, DQ-405 | Evita acumular dados pessoais fora do armazenamento de objetos. | Dado um processamento terminado, quando passa 1 h, então o worker não tem ficheiros temporários desse trabalho. |
| REQ-VID-BLUR-045 | O sistema deve processar apenas os vídeos do projeto com esta ferramenta, debitar operações apenas por estes e informar o número de itens ignorados. | Deve ter | Novo | ALT | UC-VID-004/Passo 5, UC-VID-004/FA7, UC-VID-004/RN5, DQ-401 | A tabela de capacidades indica que a ferramenta aceita apenas vídeo. | Dado um projeto com 2 vídeos e 3 imagens, quando um registado aplica, então são processados 2 itens, são debitadas 2 operações e é informado de 3 ignorados. |
| REQ-VID-BLUR-046 | O sistema deve recusar combinar a ferramenta "Desfocar caras" com outras ferramentas na mesma pipeline. | Deve ter | Novo | ALT | UC-VID-004/Exceção 3, UC-VID-004/RN8, DQ-409 | A pipeline do MVP mantém cada ferramenta de vídeo isolada; o encadeamento fica para a Fase 2. | Dado um projeto com a ferramenta "Cortar vídeo", quando tenta adicionar "Desfocar caras", então é recusado com explicação; e vice-versa. |
| REQ-VID-BLUR-047 | O sistema deve recusar iniciar o processamento quando o projeto não contém vídeos, informando que nenhum item é compatível. | Deve ter | Novo | ALT | UC-VID-004/Exceção 4, DQ-401 | Evita trabalhos vazios. | Dado um projeto só com imagens e a ferramenta adicionada, quando aplica, então é recusado com mensagem e a quota não muda. |
| REQ-VID-BLUR-048 | O sistema deve permitir copiar os vídeos anonimizados para um novo projeto, como vídeos normais. | Deve ter | Novo | ALT | UC-VID-004/Passo 8, UC-VID-004/FA5, DQ-418 | Caminho para continuar a editar os vídeos com outras ferramentas e mantê-los independentemente dos resultados. | Dado 2 vídeos anonimizados, quando escolhe "Copiar para novo projeto", então é criado um projeto com 2 vídeos que se reproduzem e aceitam ferramentas de vídeo. |
| REQ-VID-BLUR-049 | O sistema deve permitir adicionar e aplicar a ferramenta apenas ao dono do projeto e a utilizadores com permissão de edição. | Deve ter | Novo | ALT | UC-VID-004/RN9, UC-VID-004/Pré-condições, DQ-406 | Aplica as permissões de partilha existentes à nova ferramenta. | Dado um utilizador com partilha só de leitura, quando tenta adicionar a ferramenta, então recebe erro de permissão; consegue ver os resultados. |
| REQ-VID-BLUR-050 | O sistema deve impedir guardar a ferramenta quando as opções estão fora dos valores permitidos, indicando esses valores. | Deve ter | Novo | NOVO | UC-VID-004/Exceção 5 | Evita pedidos que o worker não consegue processar. | Dado a intensidade 15, então guardar está bloqueado com a indicação "1 a 10"; com 10 é aceite. |
| REQ-VID-BLUR-051 | O sistema deve aplicar as mesmas opções a todos os vídeos do projeto. | Deve ter | Novo | ALT | UC-VID-004/RN10, DQ-419 | As ferramentas da pipeline aplicam os mesmos parâmetros a todos os itens. | Dado 2 vídeos e a pixelização com intensidade 8, quando aplica, então ambos os resultados estão pixelizados com a mesma intensidade. |

### 4.1.2 Requisitos Não Funcionais e de Qualidade

As regras de negócio e restrições funcionais (opções, perfis, quota e combinação de ferramentas) estão na tabela 4.1.1. Aqui ficam apenas os requisitos de qualidade, classificados segundo a ISO/IEC 25010.

| **ID** | **Requisito** | **Característica ISO/IEC 25010** | **Alvo MVP** | **Alvo produção** | **Evolução** | **Origem (UC / DQ)** | **Critério de aceitação / verificação** |
|---|---|---|---|---|---|---|---|
| REQ-VID-BLUR-020 | O sistema deve remover o resultado parcial do vídeo cujo processamento falha, e de todos os vídeos quando é cancelado, mantendo os resultados dos vídeos concluídos. | Fiabilidade (Recuperabilidade) | Remoção dos parciais por vídeo, sem retoma | Uma repetição automática por vídeo e retoma a partir do último ponto de controlo | Refinado | UC-VID-004/Exceção 6, UC-VID-004/Exceção 7, UC-VID-004/FA6, UC-VID-004/RN7, DQ-404 | Dado 2 vídeos e uma falha forçada a meio do segundo, então o resultado do primeiro mantém-se e não há resultado do segundo. |
| REQ-VID-BLUR-021 | O sistema deve manter o vídeo original inalterado, gerando sempre um novo ficheiro. | Segurança (Integridade) | Obrigatório | Obrigatório | Mantido | UC-VID-004/RN1, UC-VID-004/Pós-condição de sucesso | Dado o hash do original antes e depois, então são idênticos. |
| REQ-VID-BLUR-022 | O sistema deve gerar um vídeo com a mesma duração do original, com diferença máxima de 1 s (†). | Adequação Funcional (Correção funcional) | ≤ 1 s | ≤ 1 frame | Mantido | UC-VID-004/RN6 | Dado um original de 60 s, então o gerado tem entre 59 s e 61 s. |
| REQ-VID-BLUR-023 | O sistema deve detetar pelo menos 90 % (†) das caras frontais com ≥ 64×64 px num conjunto de teste definido pela equipa. | Adequação Funcional (Correção funcional) | ≥ 90 % (†) | ≥ 98 % (†) | Refinado | UC-VID-004/A4, UC-VID-004/A10, UC-VID-004/Q2, DQ-412 | Dado o conjunto de teste anotado, quando se corre o detetor, então a taxa de deteção (IoU ≥ 0,5) é ≥ 90 %. |
| REQ-VID-BLUR-024 | O sistema deve confirmar a receção do pedido em ≤ 2 s após "Aplicar", independentemente da duração dos vídeos. | Eficiência de Desempenho (Comportamento temporal) | ≤ 2 s | ≤ 1 s (†) | Refinado | UC-VID-004/Passo 4, UC-VID-004/FA3, DQ-410 | Dado vídeos de 15 s e 10 min, quando aplica, então a confirmação surge em ≤ 2 s. |
| REQ-VID-BLUR-034 | O sistema deve processar em simultâneo até 5 (†) desfocagens de vídeo, mantendo as restantes em fila. | Eficiência de Desempenho (Capacidade) | 5 réplicas do worker (†) | Réplicas ajustadas à carga, até 50 (†) | Refinado | UC-VID-004/A3, UC-VID-004/A7, DQ-407 | Dado 8 vídeos a desfocar em simultâneo, então 5 ficam em curso, 3 em fila e os 8 terminam com sucesso. |
| REQ-VID-BLUR-035 | O sistema deve restringir o acesso aos vídeos e aos resultados às permissões do projeto (dono e partilhas). | Segurança (Confidencialidade) | Obrigatório | Obrigatório | Refinado | UC-VID-004/RN9, UC-VID-004/Pré-condições, DQ-406 | Dado um utilizador sem acesso ao projeto, quando pede um vídeo ou resultado, então recebe erro de autorização. |
| REQ-VID-BLUR-036 | O sistema deve disponibilizar vídeos e resultados para descarga apenas através de ligações assinadas, não adivinháveis e com expiração. | Segurança (Confidencialidade) | Ligações assinadas com expiração de 1 h (mecanismo existente) | Expiração ≤ 15 min (†) | Refinado | UC-VID-004/Passo 8, DQ-406 | Dado uma ligação de descarga, quando um carácter da assinatura é alterado ou a ligação expirou, então o armazenamento devolve erro. |
| REQ-VID-BLUR-037 | O sistema deve atualizar o estado e a percentagem de progresso apresentados com um intervalo máximo de 10 s (†). | Usabilidade (Operabilidade) | ≤ 10 s | ≤ 2 s | Mantido | UC-VID-004/Passo 5, UC-VID-004/FA3, DQ-408 | Dado um processamento de 5 min, quando se observa o ecrã durante 1 min, então o valor é atualizado pelo menos a cada 10 s. |
| REQ-VID-BLUR-039 | O sistema deve poder ser instalado e executado, incluindo o novo worker com OpenCV, `ffmpeg` e o modelo de deteção, a partir de `docker compose up` num ambiente limpo. | Portabilidade (Instalabilidade) | Worker no `docker-compose.yaml`, com versões das dependências e do modelo fixadas | Instalação automatizada com uma só ação, com verificação de saúde do worker | Refinado | UC-VID-004/A7, DQ-411 | Dado uma máquina limpa, quando se executa `docker compose up`, então o teste de aceitação da desfocagem passa. |
| REQ-VID-BLUR-040 | O sistema deve permitir acrescentar uma nova ferramenta de vídeo registando-a na tabela de capacidades e num novo worker, sem alterar o código das ferramentas de vídeo existentes. | Manutenibilidade (Modularidade) | Obrigatório (a desfocagem é acrescentada sem alterar o corte nem a extração de frames) | Obrigatório | Refinado | DQ-401, DQ-409 | Dado a desfocagem acrescentada, então nenhum ficheiro dos workers `trim` e `extract_frames` foi alterado. |
| REQ-VID-BLUR-041 | O sistema deve concluir a desfocagem em tempo não superior a 3× a duração do vídeo (†). | Eficiência de Desempenho (Comportamento temporal) | ≤ 3× a duração do vídeo | ≤ 1× a duração do vídeo | Mantido | UC-VID-004/A3, DQ-410 | Dado um vídeo de 10 min, quando o processamento arranca sem outros trabalhos, então termina em ≤ 30 min. |
| REQ-VID-BLUR-042 | O sistema deve processar os vídeos apenas em componentes controlados pelo PictuRAS, sem os enviar a serviços externos. | Segurança (Confidencialidade) | Obrigatório | Obrigatório | Mantido | UC-VID-004/Passo 5, UC-VID-004/A2, DQ-413 | Dado um pedido de desfocagem, quando se inspeciona o tráfego de saída do worker durante o processamento, então não há envio do vídeo para destinos externos ao PictuRAS. |
| REQ-VID-BLUR-043 | O sistema deve produzir o vídeo anonimizado no mesmo contentor do original, recodificado com o codec habitual desse contentor (MP4/MOV: H.264 e AAC; WebM: VP9 e Opus). | Compatibilidade (Interoperabilidade) | Mesmo contentor, codecs indicados | Mesmo contentor e mesmos codecs do original | Refinado | UC-VID-004/Passo 6, DQ-415 | Dado um MP4 e um WebM, quando processados, então os ficheiros gerados são MP4 com H.264/AAC e WebM com VP9/Opus (verificado com `ffprobe`). |
| REQ-VID-BLUR-044 | O sistema deve desfocar vídeos de todos os formatos aceites no carregamento (MP4, WebM e MOV), incluindo os codecs H.264, H.265 e VP9. | Compatibilidade (Interoperabilidade) | MP4, WebM, MOV (H.264, H.265, VP9) | Mais formatos aceites no carregamento (†) | Novo | UC-VID-004/A1, DQ-403 | Dado um vídeo de cada formato e codec, quando aplica, então todos geram resultado. |

> O alvo de produção é uma referência para a evolução futura (Fase 2), não um critério de aprovação do MVP.

### 4.1.3 Verificação da completude e dos limites do âmbito

| **Tópico a verificar** | **Aplicável?** | **Decisão / justificação** | **Requisito(s) relacionado(s)** |
|---|---|---|---|
| Formato, codec, duração e dimensão do vídeo | Parcial | A validação de formato, tamanho e duração por perfil é feita no carregamento (fora do âmbito, A1). Este caso de uso garante o processamento dos formatos aceites e trata vídeos corrompidos. | BLUR-016, BLUR-044 |
| Estado, progresso, cancelamento e resultado | Sim | Reutiliza o processamento assíncrono, o cancelamento e as notificações existentes, bem como a percentagem de progresso introduzida no UC-VID-003; o resultado é um vídeo reproduzível nos resultados. | BLUR-007, BLUR-008, BLUR-011, BLUR-012, BLUR-026, BLUR-027, BLUR-028, BLUR-037 |
| Falhas durante o processamento | Sim | Falha isolada por vídeo: remoção do resultado parcial desse vídeo, devolução da operação e mensagem com a causa, sem retoma automática no MVP. | BLUR-016, BLUR-020, BLUR-029, BLUR-030, BLUR-033 |
| Persistência e expiração dos ficheiros | Sim | Resultados seguem a regra existente (substituídos na execução seguinte); vídeos copiados mantêm-se até eliminação; temporários eliminados até 1 h; descarga por ligações assinadas. | BLUR-032, BLUR-033, BLUR-035, BLUR-036 |
| Perfis e contagem de operações | Sim | Ferramenta avançada: anónimo excluído; registado com uma operação por vídeo, debitada no pedido e devolvida em falha ou cancelamento; premium sem limite. Os limites de vídeo por perfil aplicam-se no carregamento. | BLUR-018, BLUR-019, BLUR-030, BLUR-031, BLUR-045 |
| Itens de tipos diferentes no mesmo projeto | Sim | A tabela de capacidades restringe a ferramenta a vídeos; as imagens são ignoradas, não consomem operações e o utilizador é informado. | BLUR-045, BLUR-047 |
| Encadeamento de ferramentas e processamento em lote | Parcial | A ferramenta aplica-se a todos os vídeos do projeto com as mesmas opções (lote dentro do projeto). O encadeamento com outras ferramentas fica fora do MVP (RN8); os vídeos anonimizados podem ser editados com outras ferramentas depois de copiados para um novo projeto. | BLUR-040, BLUR-046, BLUR-048, BLUR-051 |
| Partilha do projeto | Sim | As permissões existentes (leitura/edição) aplicam-se à nova ferramenta e aos resultados. | BLUR-035, BLUR-049 |
| Privacidade dos dados (RGPD) | Sim | Os vídeos contêm dados pessoais: processamento apenas local, temporários eliminados e acesso restrito às permissões do projeto. | BLUR-033, BLUR-035, BLUR-042 |

**Evolução:** *Mantido* = requisito preservado; *Refinado* = clarificado, tornado verificável ou alinhado com o sistema existente, sem mudar a intenção; *Novo* = acrescentado nesta versão. **NOVO/ALT** indica o impacto face ao PictuRAS existente, não a novidade face ao Exercício 1.

### 4.1.4 Requisitos eliminados

| **ID** | **Motivo** | **Substituído por** |
|---|---|---|
| REQ-VID-BLUR-015 | A validação de formato e codec é feita no carregamento do vídeo, fora deste caso de uso. | Requisitos de carregamento de vídeo; BLUR-044 (formatos que a desfocagem processa) |
| REQ-VID-BLUR-017 | O limite de duração é validado no carregamento, por perfil; a ferramenta não acrescenta limites. | Requisitos de carregamento de vídeo (A6) |
| REQ-VID-BLUR-025 | O limite de tamanho é validado no carregamento, por perfil. | Requisitos de carregamento de vídeo (A6) |
| REQ-VID-BLUR-038 | Os formatos de entrada são os aceites no carregamento (MP4, WebM e MOV). | BLUR-044 |

## 4.2 Impacto no sistema existente

| **Elemento existente afetado** | **Impacto (Manter / Estender / Alterar)** | **Descrição do impacto** | **Requisito(s) relacionado(s)** |
|---|---|---|---|
| Barra de ferramentas (`frontend/components/toolbar/toolbar.tsx`) | Alterar | Num vídeo aberto, passa a mostrar também a ferramenta "Desfocar caras", com o tipo de anonimização, a intensidade e a pré-visualização de um frame. | BLUR-001, BLUR-002, BLUR-009, BLUR-010, BLUR-050 |
| Pipeline de ferramentas do projeto (`POST /:user/:project/tool`) | Alterar | Aceita a nova ferramenta, valida as opções, recusa o perfil anónimo e recusa combiná-la com outras. | BLUR-001, BLUR-031, BLUR-046, BLUR-049, BLUR-050 |
| Tabela de capacidades (`projects/utils/toolCapabilities.js`) | Estender | Regista `blur_faces` como ferramenta que aceita vídeo e como ferramenta exclusiva no MVP. | BLUR-040, BLUR-045, BLUR-046, BLUR-047 |
| Processamento (`POST /:user/:project/process`) | Manter | Já processa só os itens compatíveis, informa os ignorados e debita as operações apenas por estes. | BLUR-003, BLUR-045, BLUR-047 |
| Quota diária e ferramentas avançadas (`advanced_tools`, `users`) | Estender | `blur_faces` entra nas ferramentas avançadas: debita uma operação por vídeo ao perfil registado e não limita o premium. | BLUR-018, BLUR-019, BLUR-030, BLUR-031 |
| Perfis de utilização (anónimo / registado / premium) | Manter | A regra atual das ferramentas avançadas (anónimo excluído) aplica-se à nova ferramenta. | BLUR-031 |
| Contrato de mensagens das ferramentas (`project_msg.js` ↔ `Tools/utils/tool_msg.py`) | Estender | Reutiliza o contrato já estendido no UC-VID-003 (progresso intermédio, erros com causa) e o tipo de saída `video` do UC-VID-002; regista a fila `blur_faces_queue` e acrescenta o número de caras detetadas à resposta de sucesso. | BLUR-013, BLUR-026, BLUR-029 |
| Tratamento das respostas das ferramentas (`process_msg`) | Alterar | Guarda o número de caras detetadas no resultado; a falha de um vídeo é isolada e devolve a operação (mecanismo do UC-VID-003). | BLUR-007, BLUR-013, BLUR-016, BLUR-020, BLUR-030 |
| Resultados do projeto (`models/result.js`, `GET /process/url`) e grelha de resultados | Estender | Resultado do tipo vídeo com o número de caras detetadas; aviso e opção "Descartar" quando é zero, através de uma nova rota para remover um resultado. | BLUR-007, BLUR-008, BLUR-013, BLUR-014 |
| Pré-visualização (`POST /:user/:project/preview/:img`) | Alterar | Para esta ferramenta, pede ao worker um único frame, devolvido como imagem e mostrado na janela de pré-visualização existente. | BLUR-010 |
| Workers de ferramentas (`Tools/`) | Estender | Novo worker `blur_faces` com OpenCV (detetor YuNet), `ffmpeg` e fila RabbitMQ própria. | BLUR-004, BLUR-005, BLUR-006, BLUR-009, BLUR-034, BLUR-041, BLUR-042, BLUR-043, BLUR-044 |
| Cópia de resultados para novo projeto (`POST /:user/:project/results/project`) | Manter | Já copia vídeos com a respetiva duração (UC-VID-002). | BLUR-032, BLUR-048 |
| Cancelamento (`DELETE /:user/:project/process`) | Manter | Reutilizado sem alterações: token, remoção dos resultados da execução e devolução das operações. | BLUR-020, BLUR-027, BLUR-030 |
| Notificações (`wsGateway`) | Manter | Reutiliza os eventos de progresso e de falha por item introduzidos no UC-VID-003. | BLUR-012, BLUR-026, BLUR-028, BLUR-037 |
| Partilha e permissões (`checkSharePermission`, `requireEditPermission`) | Manter | Aplicadas à nova ferramenta e aos resultados. | BLUR-035, BLUR-049 |
| Ligações de descarga (`getPresignedUrl.js`) | Manter | Já assinadas e com expiração de 1 h. | BLUR-036 |
| Instalação (`docker-compose.yaml`, `rabbitMQ/definitions.json`) | Estender | Novo serviço para o worker de desfocagem, com 5 réplicas, e nova fila. | BLUR-034, BLUR-039 |
| API Gateway (`apiGateway/routes/projects.js`) | Estender | Reencaminha a nova rota de remoção de um resultado. | BLUR-014 |

## 4.3 Matriz de Rastreabilidade Atualizada

| **Elemento de origem** | **Descrição abreviada** | **Requisito(s) relacionado(s)** |
|---|---|---|
| UC-VID-004/Passo 1 | Abrir projeto e vídeo | BLUR-001 |
| UC-VID-004/Passo 2 | Escolher ferramenta, opções | BLUR-001, BLUR-002 |
| UC-VID-004/Passo 3 | Definir intensidade e guardar | BLUR-002, BLUR-050 |
| UC-VID-004/Passo 4 | Aplicar, validar e debitar | BLUR-003, BLUR-018, BLUR-024, BLUR-030 |
| UC-VID-004/Passo 5 | Detetar e desfocar com progresso | BLUR-004, BLUR-005, BLUR-023, BLUR-026, BLUR-037, BLUR-041, BLUR-042, BLUR-045, BLUR-051 |
| UC-VID-004/Passo 6 | Gerar vídeo com áudio | BLUR-006, BLUR-043 |
| UC-VID-004/Passo 7 | Guardar como resultados e notificar | BLUR-007, BLUR-028 |
| UC-VID-004/Passo 8 | Reproduzir e descarregar | BLUR-008, BLUR-036, BLUR-048 |
| UC-VID-004/FA1 | Pixelização | BLUR-009 |
| UC-VID-004/FA2 | Pré-visualização de um frame | BLUR-010 |
| UC-VID-004/FA3 | Segundo plano | BLUR-011, BLUR-012, BLUR-024, BLUR-026, BLUR-028, BLUR-037 |
| UC-VID-004/FA4 | Nenhuma cara detetada | BLUR-013, BLUR-014 |
| UC-VID-004/FA5 | Copiar para novo projeto | BLUR-032, BLUR-048 |
| UC-VID-004/FA6 | Cancelar processamento | BLUR-020, BLUR-027 |
| UC-VID-004/FA7 | Projeto com imagens e vídeos | BLUR-045 |
| UC-VID-004/Exceção 1 | Perfil anónimo | BLUR-031 |
| UC-VID-004/Exceção 2 | Quota insuficiente | BLUR-018 |
| UC-VID-004/Exceção 3 | Combinação com outras ferramentas | BLUR-046 |
| UC-VID-004/Exceção 4 | Projeto sem vídeos | BLUR-047 |
| UC-VID-004/Exceção 5 | Opções inválidas | BLUR-050 |
| UC-VID-004/Exceção 6 | Vídeo corrompido | BLUR-016, BLUR-020, BLUR-030 |
| UC-VID-004/Exceção 7 | Falha no processamento | BLUR-020, BLUR-021, BLUR-029, BLUR-030 |
| UC-VID-004/Pós-condição de sucesso | Vídeos anonimizados, originais intactos | BLUR-007, BLUR-021, BLUR-022 |
| UC-VID-004/Pós-condição mínima | Sem vídeo incompleto, operações devolvidas | BLUR-020, BLUR-029, BLUR-030, BLUR-033 |
| UC-VID-004/Pré-condições | Perfil, permissão, vídeo validado, quota | BLUR-018, BLUR-030, BLUR-031, BLUR-035, BLUR-049 |
| UC-VID-004/RN1 | Novo ficheiro | BLUR-021 |
| UC-VID-004/RN2 | Ferramenta avançada | BLUR-018, BLUR-019, BLUR-031 |
| UC-VID-004/RN3 | Operação só com sucesso | BLUR-030 |
| UC-VID-004/RN4 | Limites do carregamento por perfil | BLUR-044 |
| UC-VID-004/RN5 | Só vídeos | BLUR-045 |
| UC-VID-004/RN6 | Mantém duração e áudio | BLUR-006, BLUR-022 |
| UC-VID-004/RN7 | Sem resultados incompletos | BLUR-020 |
| UC-VID-004/RN8 | Sem combinação | BLUR-046 |
| UC-VID-004/RN9 | Permissões do projeto | BLUR-035, BLUR-049 |
| UC-VID-004/RN10 | Mesmas opções para todos | BLUR-051 |
| UC-VID-004/RN11 | Todas as caras | BLUR-005 |
| UC-VID-004/A1 | Carregamento validado fora do UC | BLUR-044 |
| UC-VID-004/A2 | Deteção local | BLUR-042 |
| UC-VID-004/A3 | Estados intermédios | BLUR-012, BLUR-034, BLUR-041 |
| UC-VID-004/A4 | Deteção não garantida em casos difíceis | BLUR-023 |
| UC-VID-004/A7 | Worker com OpenCV e ffmpeg | BLUR-034, BLUR-039 |
| UC-VID-004/A10 | Conjunto de teste | BLUR-023 |
| UC-VID-004/Q1 | Escolha de caras | BLUR-005 |
| UC-VID-004/Q2 | Taxa de deteção | BLUR-023 |
| UC-VID-004/Q4 | Exclusividade premium | BLUR-018, BLUR-019 |
| UC-VID-004/Q6 | Persistência | BLUR-032 |
| UC-VID-004/Q7 | Quota de pedidos pendentes | BLUR-030 |
| DQ-401 | Desfocagem como ferramenta de vídeo da pipeline | BLUR-001, BLUR-007, BLUR-040, BLUR-045, BLUR-047 |
| DQ-402 | Ferramenta avançada e contagem de operações | BLUR-018, BLUR-019, BLUR-030, BLUR-031 |
| DQ-403 | Validação no carregamento | BLUR-044 |
| DQ-404 | Falha isolada por vídeo, sem retoma | BLUR-016, BLUR-020, BLUR-029 |
| DQ-405 | Persistência e temporários | BLUR-032, BLUR-033 |
| DQ-406 | Permissões do projeto e ligações assinadas | BLUR-035, BLUR-036, BLUR-049 |
| DQ-407 | Réplicas do worker e fila | BLUR-034 |
| DQ-408 | Estado, progresso, cancelamento e notificação | BLUR-012, BLUR-026, BLUR-027, BLUR-028, BLUR-037 |
| DQ-409 | Sem combinação; modularidade | BLUR-040, BLUR-046 |
| DQ-410 | Alvos de desempenho | BLUR-024, BLUR-041 |
| DQ-411 | Instalação com docker compose | BLUR-039 |
| DQ-412 | Detetor e taxa de deteção | BLUR-004, BLUR-023 |
| DQ-413 | Processamento local | BLUR-042 |
| DQ-414 | Todas as caras; outros elementos fora do MVP | BLUR-005 |
| DQ-415 | Contentor mantido, recodificação | BLUR-043 |
| DQ-416 | Pré-visualização de um frame | BLUR-010 |
| DQ-417 | Nenhuma cara detetada | BLUR-013, BLUR-014 |
| DQ-418 | Cópia para novo projeto | BLUR-048 |
| DQ-419 | Mesmas opções para todos os vídeos | BLUR-051 |

**Decisões de qualidade (v1.2)**

| **ID** | **Decisão de qualidade** | **Justificação** | **Requisito(s) relacionado(s)** |
|---|---|---|---|
| DQ-401 | A desfocagem é uma ferramenta de vídeo da pipeline (`blur_faces`, aceita vídeo e produz vídeo), executada por um worker em `Tools/` via RabbitMQ, como as restantes ferramentas. | Reutiliza fila, estados, cancelamento, partilha e descarga, e segue a arquitetura do corte (UC-VID-002) e da extração de frames (UC-VID-003). | BLUR-001, BLUR-007, BLUR-040, BLUR-045, BLUR-047 |
| DQ-402 | "Desfocar caras" é uma ferramenta avançada: anónimo excluído; registado com uma operação por vídeo, debitada no pedido e devolvida se esse vídeo falhar ou o processamento for cancelado; premium sem limite. | Equipara a ferramenta às de IA de imagem; debitar no pedido impede ultrapassar a quota com pedidos simultâneos e a devolução garante que falhas não penalizam o utilizador. | BLUR-018, BLUR-019, BLUR-030, BLUR-031 |
| DQ-403 | Os formatos, o tamanho e a duração dos vídeos são validados no carregamento, por perfil; a desfocagem processa todos os formatos aí aceites. | Evita validar duas vezes e mantém uma só lista de formatos e limites. | BLUR-044 |
| DQ-404 | A falha é isolada por vídeo: o resultado parcial desse vídeo é removido, a operação é devolvida e os restantes continuam; no MVP não há retoma automática. | Um vídeo problemático não deve anular o trabalho dos restantes. | BLUR-016, BLUR-020, BLUR-029 |
| DQ-405 | Os resultados seguem a regra existente; os vídeos copiados para um projeto mantêm-se até eliminação; os temporários são eliminados até 1 h após o termo (†). | Evita perda de trabalho e retenção desnecessária de dados pessoais. | BLUR-032, BLUR-033 |
| DQ-406 | O acesso segue as permissões do projeto (dono e partilhas) e a descarga usa as ligações assinadas existentes. | Reutiliza o modelo de segurança atual sem exceções para vídeo. | BLUR-035, BLUR-036, BLUR-049 |
| DQ-407 | O MVP corre 5 réplicas (†) do worker de desfocagem; os restantes vídeos ficam em fila no RabbitMQ. | Limita o consumo de CPU e mantém a aplicação responsiva. | BLUR-034 |
| DQ-408 | Estado, cancelamento e notificação reutilizam os mecanismos existentes; a percentagem de progresso é atualizada no máximo a cada 10 s no MVP (†). | Operações que duram minutos exigem feedback ao utilizador. | BLUR-012, BLUR-026, BLUR-027, BLUR-028, BLUR-037 |
| DQ-409 | No MVP a desfocagem não se combina com outras ferramentas; novas ferramentas de vídeo acrescentam-se pela tabela de capacidades sem alterar as existentes. | Cada ferramenta de vídeo fica isolada na pipeline; o encadeamento fica para a Fase 2. | BLUR-040, BLUR-046 |
| DQ-410 | Alvos de desempenho: confirmação do pedido em ≤ 2 s e desfocagem em ≤ 3× a duração do vídeo (†). | Distingue o tempo de resposta do pedido do tempo de processamento. | BLUR-024, BLUR-041 |
| DQ-411 | O worker de desfocagem é um serviço do `docker-compose.yaml`, com OpenCV, `ffmpeg` e o modelo de deteção incluídos na imagem, em versões fixadas. | Mantém a instalação reprodutível com binários e modelos externos. | BLUR-039 |
| DQ-412 | A deteção usa o detetor YuNet do OpenCV, com o objetivo de ≥ 90 % das caras frontais (≥ 64×64 px) no MVP e ≥ 98 % em produção (†). | Modelo leve que corre em CPU dentro do worker; responde a Q2 e torna a qualidade da deteção verificável (A4). | BLUR-004, BLUR-023 |
| DQ-413 | Os vídeos são processados apenas em componentes controlados pelo PictuRAS, sem envio a serviços externos. | Os vídeos contêm imagens de pessoas, dados pessoais (RGPD). | BLUR-042 |
| DQ-414 | A anonimização aplica-se a todas as caras detetadas, sem seleção pelo utilizador; matrículas e outros elementos ficam fora do MVP. | Mantém o âmbito do MVP; responde a Q1 e Q3. | BLUR-005 |
| DQ-415 | O vídeo anonimizado mantém o contentor do original e é recodificado (MP4/MOV: H.264 e AAC; WebM: VP9 e Opus). | Alterar os píxeis obriga a recodificar o vídeo; os codecs indicados são os habituais de cada contentor, como no corte (UC-VID-002). | BLUR-043 |
| DQ-416 | A pré-visualização processa um único frame do vídeo aberto, através do mecanismo de pré-visualização existente, sem consumir operações. | Permite avaliar as opções em segundos, sem processar o vídeo completo. | BLUR-010 |
| DQ-417 | Quando não é detetada nenhuma cara, o resultado é guardado com essa indicação e o utilizador pode descartá-lo. | O processamento é assíncrono e não pode perguntar a meio; a decisão passa para os resultados. | BLUR-013, BLUR-014 |
| DQ-418 | Os vídeos anonimizados ficam nos resultados do projeto; para os editar com outras ferramentas, copiam-se para um novo projeto como vídeos. | Permite continuar a editar sem encadeamento na pipeline. | BLUR-048 |
| DQ-419 | As mesmas opções aplicam-se a todos os vídeos do projeto. | As ferramentas da pipeline aplicam os mesmos parâmetros a todos os itens. | BLUR-051 |

**Correspondência com a numeração da v1.1** (as DQ foram renumeradas para não colidirem com as do UC-VID-002 e do UC-VID-003): DQ-001 e DQ-002 → DQ-403; DQ-003 e DQ-010 → DQ-402; DQ-004 → DQ-404; DQ-005 → DQ-405; DQ-006 → DQ-406; DQ-007 → DQ-407; DQ-008 → DQ-408; DQ-009 → DQ-409; DQ-011 → DQ-410; DQ-012 → DQ-411; DQ-013 → DQ-412; DQ-014 → DQ-413; DQ-015 → DQ-414; DQ-016 → DQ-415. DQ-416 a DQ-419 são novas.

**Verificações de cobertura**
- [x] Cada requisito funcional e não funcional aparece na matriz.
- [x] Cada requisito tem origem identificada: elemento do caso de uso, regra de negócio ou decisão de qualidade.
- [x] Todos os elementos relevantes do caso de uso (passos, fluxos alternativos, exceções, regras de negócio e pós-condições) têm requisito associado.
- [x] Os tópicos parciais na secção 4.1.3 estão justificados e os requisitos eliminados estão registados em 4.1.4.
- [x] O impacto no sistema existente está ligado aos elementos de código afetados e aos requisitos relevantes.

## 4.4 Realização e verificação

> Corresponde ao Cap. 7.3 do relatório: para cada requisito, componente(s) que o realizam, estado de implementação, teste(s) e resultado. Estado à data de 2026-10-19 (branch `feat/blur-faces`).

**Componentes**

| **ID** | **Componente** | **Ficheiro(s)** |
|---|---|---|
| W-BLUR | Worker de desfocagem | `Tools/blur_faces/` (`blur_faces.py`, `blur_faces_rules.py`, `Dockerfile`, `requirements.txt`, `models/face_detection_yunet_2023mar.onnx`) |
| P-ROUTES | Rotas e orquestração do `projects` | `projects/routes/projects.js` (`advanced_tools`, `/tool`, `/process`, `/preview`, `/process/url`, `DELETE /results/:result`, `process_msg`) |
| P-RULES | Regras de vídeo do `projects` | `projects/utils/toolCapabilities.js`, `projects/utils/blurFaces.js` |
| P-DATA | Resultados | `projects/models/result.js` (`faces_detected`), `projects/controllers/result.js` |
| MSG | Contrato de mensagens | `Tools/utils/tool_msg.py` (fila e campo `extra`), `projects/utils/project_msg.js` |
| GW | API Gateway | `apiGateway/routes/projects.js` (`DELETE /:user/:project/results/:result`) |
| WS | Notificações | `wsGateway/index.js` (eventos do UC-VID-003, sem alterações) |
| FE-TOOL | Ferramenta no frontend | `frontend/components/toolbar/blur-faces-tool.tsx`, `toolbar.tsx`, `lib/blur-faces.ts`, `lib/tool-types.ts` |
| FE-PAGE | Resultados no frontend | `frontend/components/project-page/project-image.tsx`, `lib/projects.ts`, `lib/mutations/projects.ts` |
| INFRA | Instalação | `docker-compose.yaml`, `rabbitMQ/definitions.json` |

**Testes**

| **ID** | **Tipo** | **Descrição (Dado … Quando … Então …)** | **Requisitos** | **Resultado** |
|---|---|---|---|---|
| TST-BLUR-U1 a U4 | Unitário (`node:test`) | Opções por omissão e válidas, opções inválidas, capacidades (só vídeo) e exclusividade (`projects/test/blurFaces.test.js`) | BLUR-002, 009, 045, 046, 047, 050 | ✅ 4/4 |
| TST-BLUR-PY | Unitário (`unittest`) | Validação, margem e corte da caixa aos limites do frame, kernel ímpar e proporcional, blocos da pixelização, nomes, codecs por contentor, áudio do original e tolerância de duração (`Tools/blur_faces/test_blur_faces_rules.py`) | BLUR-022, 043, 050 | ✅ 15/15 |
| TST-BLUR-01 | Ponta a ponta | Dado um utilizador anónimo, quando adiciona a ferramenta, então é recusado (403) | BLUR-031 | ✅ |
| TST-BLUR-02 | Ponta a ponta | Dado a desfocagem na pipeline, quando adiciona o corte, então é recusado | BLUR-046 | ✅ |
| TST-BLUR-03 | Ponta a ponta | Dado um registado, 2 vídeos (um com pessoas) e 1 imagem, quando aplica, então há 2 vídeos anonimizados do tipo vídeo, com o nome de origem, 1 item ignorado, 2 operações previstas e debitadas, e caras detetadas no vídeo com pessoas | BLUR-001–008, 018, 030, 045 | ✅ |
| TST-BLUR-04 | Ponta a ponta | Dado um vídeo sem caras, então o resultado tem `faces_detected = 0`; quando é descartado, então desaparece e os restantes mantêm-se | BLUR-013, 014 | ✅ |
| TST-BLUR-06 | Inspeção (`ffprobe`) | Dado o vídeo com pessoas (MP4 H.264/AAC, 14,884 s), então o anonimizado é MP4 com H.264 e AAC e dura 14,884 s | BLUR-006, 022, 043 | ✅ |
| TST-BLUR-07 | Inspeção (`sha256`) | Dado o original antes e depois da desfocagem, então o hash é igual | BLUR-021 | ✅ |
| TST-BLUR-08 | Inspeção | Dado uma desfocagem em curso, quando se observam os logs do `ws_gateway`, então chega o progresso cerca de uma vez por segundo | BLUR-026, 037 | ✅ |
| TST-BLUR-10 | Ponta a ponta | Dado um vídeo, quando pede a pré-visualização, então é aceite e a quota não muda | BLUR-010 | ✅ (pedido e quota); imagem no navegador por confirmar |
| TST-BLUR-11 | Ponta a ponta | Dado intensidade 15 ou tipo desconhecido, quando adiciona a ferramenta, então é recusado | BLUR-050 | ✅ |
| TST-BLUR-12 | Ponta a ponta | Dado o vídeo anonimizado, quando o copia para um novo projeto, então o projeto tem 1 vídeo | BLUR-032, 048 | ✅ |
| TST-BLUR-13 | Ponta a ponta | Dado 6 vídeos e quota inferior a 6, quando aplica, então é recusado com a mensagem de operações esgotadas e a quota não muda | BLUR-018 | ✅ |
| TST-BLUR-14 | Ponta a ponta | Dado um projeto só com imagens, quando aplica, então é recusado | BLUR-047 | ✅ |
| TST-BLUR-W1 | Worker (sem RabbitMQ) | Dado um vídeo sem caras em MP4 e em WebM, então os resultados são MP4 H.264/AAC e WebM VP9/Opus com a mesma duração e 0 caras; dado um ficheiro truncado, então erro 2501 sem resultado parcial | BLUR-016, 020, 043, 044 | ✅ |
| TST-BLUR-W2 | Medição | Dado um vídeo de 14,9 s (640×360) com pessoas, então a desfocagem demora 7–8 s (≈ 0,5×) e a pixelização ≈ 0,45×, com a stack completa a correr | BLUR-041 | ✅ |
| TST-BLUR-M1 | Manual (equipa, navegador) | Ferramenta "Blur faces" num vídeo, pré-visualização, resultados e descarte | BLUR-001, 002, 009, 010, 013, 014 | Por fazer |

Os testes ponta a ponta correm com `bash projects/test/e2e/run.sh` (stack a correr); para incluir a deteção de caras, indica-se um vídeo com pessoas em `BLUR_FACE_VIDEO` (nenhum é guardado no repositório). Os unitários correm com `npm test` em `projects/` e `python3 -m unittest` em `Tools/blur_faces/` (com OpenCV instalado, ou dentro da imagem do worker).

**Realização por requisito**

| **Requisito** | **Componente(s)** | **Estado** | **Teste(s)** | **Resultado / observação** |
|---|---|---|---|---|
| BLUR-001 | FE-TOOL, P-ROUTES | Implementado | TST-BLUR-03 | ✅ Na barra de ferramentas por confirmar no navegador (M1) |
| BLUR-002 | FE-TOOL, P-RULES | Implementado | TST-BLUR-03, U1 | ✅ |
| BLUR-003 | P-ROUTES | Implementado (mecanismo existente) | TST-BLUR-03 | ✅ |
| BLUR-004 | W-BLUR | Implementado | TST-BLUR-03 | ✅ 2 caras detetadas no vídeo de teste |
| BLUR-005 | W-BLUR | Implementado | TST-BLUR-03, inspeção visual | ✅ |
| BLUR-006 | W-BLUR | Implementado | TST-BLUR-06 | ✅ |
| BLUR-007 | P-ROUTES, MSG | Implementado | TST-BLUR-03 | ✅ |
| BLUR-008 | P-ROUTES (`/process/url`), FE-PAGE | Implementado | TST-BLUR-03, 06 | ✅ Reprodução no navegador por confirmar |
| BLUR-009 | W-BLUR, FE-TOOL | Implementado | TST-BLUR-W2, U1 | ✅ |
| BLUR-010 | W-BLUR, P-ROUTES (`/preview`) | Implementado | TST-BLUR-10 | Pedido e quota verificados; imagem na janela de pré-visualização por confirmar |
| BLUR-011 | P-ROUTES | Implementado (mecanismo existente) | TST-BLUR-03 | ✅ Os testes ponta a ponta correm sem navegador |
| BLUR-012 | P-ROUTES, FE-PAGE | Parcial | — | Como no TRIM-012: o estado só é visível com a página aberta |
| BLUR-013 | W-BLUR, P-DATA, FE-PAGE | Implementado | TST-BLUR-04 | ✅ Aviso no navegador por confirmar |
| BLUR-014 | GW, P-ROUTES, FE-PAGE | Implementado | TST-BLUR-04 | ✅ Botões no navegador por confirmar |
| BLUR-016 | W-BLUR, P-ROUTES | Implementado | TST-BLUR-W1 | Falha isolada e devolução partilhadas com a extração (TST-FRAME-17) |
| BLUR-018 | P-ROUTES (`advanced_tools`) | Implementado | TST-BLUR-03, 13 | ✅ |
| BLUR-019 | P-ROUTES, `users` | Implementado (mecanismo existente) | — | Regra existente das ferramentas avançadas; sem teste próprio com premium |
| BLUR-020 | W-BLUR, P-ROUTES | Implementado | TST-BLUR-W1 | ✅ No worker; o cancelamento reutiliza o mecanismo existente |
| BLUR-021 | W-BLUR | Implementado | TST-BLUR-07 | ✅ |
| BLUR-022 | W-BLUR | Implementado | TST-BLUR-06, W1, PY | ✅ Verificado também pelo próprio worker (erro 2502 se falhar) |
| BLUR-023 | W-BLUR | Por medir | — | Falta o conjunto de teste anotado (A10) |
| BLUR-024 | P-ROUTES | Por medir | — | O `/process` descarrega os vídeos antes de responder |
| BLUR-026 | W-BLUR, WS, FE-PAGE | Implementado | TST-BLUR-08 | ✅ |
| BLUR-027 | P-ROUTES (cancelamento existente) | Implementado | — | Por testar automaticamente |
| BLUR-028 | WS, FE-PAGE | Implementado (mecanismo existente) | — | Por confirmar no navegador |
| BLUR-029 | W-BLUR, MSG | Implementado | TST-BLUR-W1 | ✅ Mensagens com a causa |
| BLUR-030 | P-ROUTES | Implementado | TST-BLUR-03 | ✅ Débito verificado; devolução em falha pelo mecanismo do TST-FRAME-17 |
| BLUR-031 | P-ROUTES | Implementado | TST-BLUR-01 | ✅ |
| BLUR-032 | P-ROUTES (`/results/project`) | Implementado (mecanismo existente) | TST-BLUR-12 | ✅ |
| BLUR-033 | W-BLUR, P-ROUTES | Implementado | — | Temporários do worker num diretório temporário apagado no fim; o vídeo gerado sai do volume após o envio |
| BLUR-034 | INFRA | Implementado | — | 5 réplicas no `docker-compose.yaml`; 8 pedidos em simultâneo por testar |
| BLUR-035 | P-ROUTES | Implementado (mecanismo existente) | — | Permissões existentes |
| BLUR-036 | `getPresignedUrl.js` | Implementado (mecanismo existente) | — | Ligações assinadas, 1 h |
| BLUR-037 | W-BLUR, WS | Implementado | TST-BLUR-08 | ✅ ≈ 1 s |
| BLUR-039 | INFRA, W-BLUR | Implementado | Toda a bateria | ✅ `docker compose up` com versões e modelo fixados |
| BLUR-040 | P-RULES, INFRA | Implementado | — | ✅ Nenhum ficheiro dos workers `trim` e `extract_frames` foi alterado |
| BLUR-041 | W-BLUR | Implementado | TST-BLUR-W2 | ✅ ≈ 0,5× num vídeo de 640×360 |
| BLUR-042 | W-BLUR | Implementado | — | Modelo incluído na imagem; sem chamadas externas no código |
| BLUR-043 | W-BLUR | Implementado | TST-BLUR-06, W1, PY | ✅ |
| BLUR-044 | W-BLUR | Implementado | TST-BLUR-W1 | MP4 e WebM verificados; MOV e H.265 por testar |
| BLUR-045 | P-RULES, P-ROUTES | Implementado | TST-BLUR-03, U3 | ✅ |
| BLUR-046 | P-RULES | Implementado | TST-BLUR-02, U4 | ✅ |
| BLUR-047 | P-RULES, P-ROUTES | Implementado | TST-BLUR-14, U3 | ✅ |
| BLUR-048 | P-ROUTES (`/results/project`) | Implementado (mecanismo existente) | TST-BLUR-12 | ✅ |
| BLUR-049 | P-ROUTES (`requireEditPermission`) | Implementado (mecanismo existente) | — | Permissões existentes; sem teste próprio |
| BLUR-050 | P-RULES, FE-TOOL, W-BLUR | Implementado | TST-BLUR-11, U2, PY | ✅ |
| BLUR-051 | P-ROUTES | Implementado (mecanismo existente) | TST-BLUR-03 | ✅ |
