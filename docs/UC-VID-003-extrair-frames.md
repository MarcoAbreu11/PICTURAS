# Exercício 1 — Casos de Uso
## Fase 1: Suporte a Vídeo no PictuRAS

## 0. Identificação

| Campo | Valor |
|---|---|
| Grupo / Equipa | [preencher] |
| Autores | Diogo Linhares Campos - PG63948<br>Marco António Ferreira Abreu - PG64003<br>Cláudio Rafael Oliveira Ferreira - PG63933<br>Nelson Daniel Araújo Sousa - PG64010 |
| Data | 2026-10-18 |
| Versão do documento | v1.3 |
| Unidade Curricular | Requisitos e Arquiteturas de Software — MEI, Universidade do Minho |

---

## 1. Funcionalidade de vídeo escolhida

| Campo | Valor |
|---|---|
| Funcionalidade | Ferramenta de vídeo "Extrair frames": obtém imagens a partir dos vídeos de um projeto, como mais uma ferramenta da pipeline de edição |
| Perfil(s) de utilizador abrangido(s) | Registado e premium. É uma ferramenta avançada (consome operações da quota diária), pelo que, tal como as restantes ferramentas avançadas do PictuRAS, não está disponível para o perfil anónimo. |

### Justificação no contexto do MVP

A extração de frames é a primeira ferramenta de vídeo da pipeline e liga a nova componente de vídeo às ferramentas de imagem existentes (OCR, contagem de pessoas, binarização, …). Valida de ponta a ponta o caminho que todas as ferramentas de vídeo vão seguir: tabela de capacidades por tipo de media, execução por um worker via RabbitMQ, estado e cancelamento do processamento, quota por vídeo e resultados com várias imagens por item. Sem ela, o suporte a vídeo fica limitado a carregar e reproduzir ficheiros.

---

# 2. Caso de Uso

## 2.1 Cabeçalho

| Secção | Detalhes |
|---|---|
| ID do Caso de Uso | UC-VID-003 |
| Nome | Extrair frames de vídeos |
| Versão | v1.3 |
| Autor | Diogo Linhares Campos<br>Marco António Ferreira Abreu<br>Cláudio Rafael Oliveira Ferreira<br>Nelson Daniel Araújo Sousa |
| Data | 2026-10-18 |
| Objetivo | Permitir ao utilizador obter imagens a partir de frames dos vídeos de um projeto, para as consultar, descarregar ou editar com as ferramentas de imagem existentes. |
| Âmbito | Serviço `projects` (pipeline de ferramentas e processamento), novo worker de vídeo em `Tools/`, `users` (quota) e frontend (barra de ferramentas e resultados) |
| Ator Principal | Utilizador registado ou premium, dono do projeto ou com permissão de edição |
| Stakeholders e Interesses | - **Utilizador**: pretende obter imagens de momentos específicos de um vídeo e editá-las.<br>- **Proprietário do sistema**: pretende reaproveitar as ferramentas de imagem existentes em conteúdos de vídeo e manter o modelo de quotas.<br>- **Equipa de desenvolvimento**: pretende validar o mecanismo de ferramentas de vídeo na pipeline existente, que as próximas ferramentas de vídeo vão reutilizar. |
| Pré-condições | - O utilizador tem sessão iniciada com perfil registado ou premium.<br>- O utilizador é dono do projeto ou tem permissão de edição sobre ele.<br>- O projeto contém pelo menos um vídeo, carregado e validado no carregamento (formato, tamanho e duração por perfil). |
| Trigger | O utilizador pretende obter imagens a partir dos vídeos de um projeto. |

## 2.2 Fluxo Principal

| Passo | Ação do Ator | Resposta do Sistema |
|---|---|---|
| 1 | O utilizador abre um projeto que contém vídeos e abre um dos vídeos. | O sistema reproduz o vídeo e apresenta a barra de ferramentas com as ferramentas de vídeo disponíveis. |
| 2 | O utilizador escolhe a ferramenta "Extrair frames". | O sistema apresenta os parâmetros da ferramenta: modo (intervalo regular ou frame único), intervalo em segundos ou instante, e formato das imagens (PNG ou JPEG). |
| 3 | O utilizador escolhe o modo intervalo regular, define um intervalo de N segundos e o formato, e adiciona a ferramenta ao projeto. | O sistema adiciona a ferramenta à pipeline do projeto, mostra a pré-visualização do primeiro frame do vídeo aberto e indica, para cada vídeo do projeto, o número de imagens que vão ser geradas e as operações de quota que vão ser consumidas. |
| 4 | O utilizador carrega em "Aplicar". | O sistema valida a pipeline, o número de imagens por vídeo e a quota; debita uma operação por vídeo a processar; cria um trabalho de processamento por vídeo e confirma a receção do pedido. |
| 5 | — | O sistema extrai, de cada vídeo, um frame a cada N segundos e atualiza a percentagem de progresso. As imagens do projeto não são processadas por esta ferramenta. |
| 6 | — | O sistema guarda as imagens como resultados do projeto, identificando cada uma com o nome do vídeo e o instante do frame. |
| 7 | — | O sistema notifica o utilizador de que o processamento terminou. |
| 8 | O utilizador consulta os resultados. | O sistema apresenta as imagens extraídas nos resultados do projeto, com a possibilidade de as descarregar ou copiar para um novo projeto. |

## 2.3 Fluxos Alternativos

| Fluxo | Descrição |
|---|---|
| FA1 — Extração de frame único | No passo 3, o utilizador escolhe "frame único" e indica um instante. O sistema mostra a pré-visualização desse instante no vídeo aberto. Continua no passo 4; no passo 6 é guardada uma imagem por vídeo, identificada com o nome do vídeo e o instante. |
| FA2 — Formato por omissão | No passo 3, se o utilizador não escolher o formato, o sistema usa PNG. |
| FA3 — Editar as imagens extraídas | No passo 8, o utilizador escolhe "Copiar para novo projeto". O sistema cria um projeto com o nome do projeto de origem seguido de "(frames)", com as imagens extraídas como imagens normais, às quais o utilizador pode aplicar as ferramentas de imagem existentes. |
| FA4 — Processamento em segundo plano | Após o passo 4, o utilizador abandona a página. O processamento continua e, ao regressar, o utilizador vê o estado (em fila, em curso, concluído, falhado ou cancelado) e a percentagem de progresso. |
| FA5 — Cancelar processamento | Após o passo 4, enquanto o processamento está em fila ou em curso, o utilizador cancela-o. O sistema termina o processamento, remove os resultados dessa execução e devolve as operações debitadas. |
| FA6 — Projeto com imagens e vídeos | No passo 4, o projeto contém também imagens. O sistema processa apenas os vídeos, não debita operações pelas imagens e informa o utilizador do número de itens ignorados. |

## 2.4 Exceções

| Condição | Comportamento do Sistema |
|---|---|
| **Exceção 1** — O instante indicado é superior à duração de algum vídeo do projeto (FA1, passo 4) | O sistema não inicia o processamento e indica os vídeos afetados e a respetiva duração. |
| **Exceção 2** — O intervalo gera, em algum vídeo, mais imagens do que o máximo permitido (passos 3–4) | O sistema indica o limite e os vídeos afetados e não inicia o processamento. |
| **Exceção 3** — A ferramenta de extração é combinada com outras ferramentas na mesma pipeline (passo 3) | O sistema recusa adicionar a ferramenta e explica que, nesta versão, a extração de frames tem de ser a única ferramenta do projeto. |
| **Exceção 4** — O projeto não contém vídeos (passo 4) | O sistema não inicia o processamento e informa que nenhum item é compatível com a ferramenta. |
| **Exceção 5** — Quota do utilizador registado insuficiente para o número de vídeos (passo 4) | O sistema não inicia o processamento e indica as operações necessárias e as disponíveis. |
| **Exceção 6** — Um vídeo está corrompido ou não pode ser descodificado (passo 5) | O sistema marca esse vídeo como falhado, remove as imagens parciais desse vídeo, devolve a operação correspondente e continua com os restantes vídeos. |
| **Exceção 7** — O processamento de um vídeo falha (passos 5–6) | O sistema remove as imagens parciais desse vídeo, devolve a operação correspondente, informa a causa e mantém os resultados dos vídeos concluídos. O vídeo original permanece inalterado. |

## 2.5 Pós-condições

| Tipo | Resultado |
|---|---|
| Garantia de Sucesso | As imagens extraídas estão nos resultados do projeto, identificadas pelo vídeo e pelo instante; foi debitada uma operação por vídeo processado (perfil registado); os vídeos originais permanecem inalterados. |
| Garantia Mínima | Em caso de falha ou cancelamento, não ficam imagens incompletas nos resultados, as operações dos vídeos não concluídos são devolvidas, os vídeos originais permanecem inalterados e o utilizador é informado. |

## 2.6 Regras de Negócio e Restrições

| ID | Regra |
|---|---|
| RN1 | A extração de frames não altera os vídeos originais. |
| RN2 | "Extrair frames" é uma ferramenta avançada: para o utilizador registado, consome uma operação da quota diária por vídeo processado. |
| RN3 | Utilizadores premium não possuem limite diário de operações. |
| RN4 | O perfil anónimo não pode usar ferramentas avançadas, incluindo esta. |
| RN5 | Existe um número máximo de imagens por vídeo em cada extração. |
| RN6 | No MVP, a ferramenta de extração não pode ser combinada com outras ferramentas na mesma pipeline. |
| RN7 | As imagens extraídas, quando copiadas para um projeto, ficam sujeitas às mesmas regras das imagens carregadas diretamente. |
| RN8 | Só o dono do projeto e os utilizadores com permissão de edição podem adicionar e aplicar a ferramenta; com permissão de leitura, apenas se consultam os resultados. |

## 2.7 Assunções

| ID | Assunção |
|---|---|
| A1 | O carregamento e a validação dos vídeos (formatos MP4, WebM e MOV; tamanho e duração por perfil) estão fora do âmbito deste caso de uso e já estão implementados. |
| A2 | As imagens extraídas têm a resolução original do vídeo. |
| A3 | As ferramentas de imagem existentes funcionam sobre as imagens extraídas sem alterações. |
| A4 | A duração e a resolução de cada vídeo, já lidas com `ffprobe` no carregamento, passam a ficar guardadas no item, para validar instantes e calcular o número de imagens antes do processamento. |
| A5 | Os resultados seguem a regra existente do PictuRAS: são substituídos na execução seguinte da pipeline e eliminados com o projeto; para manter as imagens e editá-las, copiam-se para um novo projeto (FA3). |
| A6 | Os limites de vídeo por perfil já estão definidos no carregamento: anónimo 20 MB / 15 s, registado 100 MB / 60 s, premium 500 MB / 10 min. |
| A7 | A extração é executada por um worker em `Tools/` com `ffmpeg`, alimentado por uma fila RabbitMQ própria; o número de trabalhos simultâneos corresponde ao número de réplicas desse worker. |
| A8 | No MVP uma falha não é retomada automaticamente: o utilizador volta a aplicar a pipeline. |
| A9 | Um limite de 100 imagens por vídeo cobre os usos previstos no MVP. |
| A10 | O perfil "registado" corresponde ao tipo `free` no serviço `users`. |

## 2.8 Questões em Aberto

| ID | Questão |
|---|---|
| Q1 | Qual o número máximo de imagens por extração? — **Resolução:** 100 imagens por vídeo (†) (FRAME-015); a confirmar. |
| Q2 | Que formatos de imagem devem ser suportados no MVP? — **Resolução:** PNG e JPEG, com PNG por omissão (FRAME-010). |
| Q3 | As imagens extraídas devem ser agrupadas numa pasta ou ficheiro .zip? — **Resolução:** o PictuRAS não tem pastas; as imagens ficam nos resultados do projeto, podem ser descarregadas com o download existente e podem ser copiadas para um novo projeto (FRAME-011, DQ-018). |
| Q4 | A extração deve contar como uma ou várias operações na quota? — **Resolução:** uma operação por vídeo processado, independentemente do número de imagens (FRAME-024, DQ-019). |
| Q5 | Qual a duração máxima de vídeo suportada? — **Resolução:** a definida por perfil no carregamento (A6); esta ferramenta não acrescenta limites de duração. |
| Q6 | Os resultados devem expirar ao fim de algum tempo? — **Resolução:** seguem a regra existente (A5); as imagens copiadas para um projeto mantêm-se até serem eliminadas (FRAME-033). |
| Q7 | Os pedidos em fila ou em curso devem contar para a quota antes de concluírem? — **Resolução:** sim; as operações são debitadas no início do processamento (mecanismo existente) e devolvidas em falha ou cancelamento (FRAME-024, FRAME-031). |
| Q8 | Os limites devem ser diferentes para registado e premium? — **Resolução:** sim, já estão definidos por perfil no carregamento (A6). |
| Q9 | A extração deve poder ser encadeada com ferramentas de imagem na mesma pipeline (ex.: extrair frames e aplicar brilho)? — **Resolução:** não no MVP (RN6); o caminho é copiar as imagens para um novo projeto (FA3). Na Fase 2 a tabela de capacidades passa a `{ accepts, produces }` para permitir o encadeamento. |
| Q10 | O utilizador deve poder escolher apenas alguns vídeos do projeto? — **Resolução:** não no MVP; a ferramenta aplica-se a todos os vídeos do projeto, como as restantes ferramentas se aplicam a todas as imagens. Avaliar na Fase 2. |

---

# 3. Utilização de agentes de IA

| Ferramenta / skill | Tarefa apoiada | Validação realizada pela equipa |
|---|---|---|
| Claude | Apoio na definição do caso de uso, fluxos, exceções, regras de negócio, assunções e questões em aberto. | Revisão manual pela equipa comparando com o enunciado, template e exemplos fornecidos pelos docentes. |
| Claude | Elaboração da ERS do Exercício 2 (secção 4): classificação segundo a ISO/IEC 25010, proposta de valores (†) e decisões de qualidade, catálogo de requisitos, impacto e matriz de rastreabilidade. | Revisão manual pela equipa: confirmação da classificação ISO/IEC 25010, dos valores propostos (†) e da rastreabilidade entre requisitos, caso de uso e decisões de qualidade. |
| Claude Code | Revisão v1.3: alinhamento do caso de uso e da ERS com o código já implementado (upload de vídeo, limites por perfil, quota, cancelamento, partilha) e com o guião interno (`docs/GUIAO_VIDEO.md`), adotando a extração como ferramenta de vídeo da pipeline. | [preencher: revisão da equipa] |

---

# 4. Especificação de Requisitos do Sistema (ERS)

**Caso de Uso:** UC-VID-003 — Extrair frames de vídeos  
**Versão do dossiê:** v1.3  
**Baseline do Exercício 1:** v1.0 — REQ-VID-FRAME-001 a REQ-VID-FRAME-025

> O catálogo 4.1 é a fonte única dos requisitos desta ERS. A matriz 4.3 rastreia esses IDs até ao caso de uso ou às decisões de qualidade (DQ). A tabela 4.2 descreve o impacto no sistema existente. Nas tabelas 4.2 e 4.3 os IDs aparecem abreviados (por exemplo, FRAME-007 = REQ-VID-FRAME-007). Os elementos locais do caso de uso são qualificados (por exemplo, UC-VID-003/RN2). Valores marcados com (†) são propostas da equipa, a confirmar. Os IDs eliminados não são reutilizados (ver 4.1.4).

## 4.1 Requisitos da ERS

### 4.1.1 Requisitos Funcionais

| **ID** | **Requisito** | **Prioridade** | **Evolução** | **Novo/Alt** | **Origem (UC / RN / decisão)** | **Justificação** | **Critério de aceitação / verificação** |
|---|---|---|---|---|---|---|---|
| REQ-VID-FRAME-001 | O sistema deve disponibilizar a ferramenta "Extrair frames" na barra de ferramentas quando o item aberto é um vídeo, permitindo adicioná-la à pipeline do projeto. | Deve ter | Refinado | ALT | UC-VID-003/Trigger, UC-VID-003/Passos 1–2, DQ-017 | Ponto de entrada da funcionalidade; substitui o aviso "Video tools coming soon". | Dado um projeto com um vídeo aberto no carrossel, quando o utilizador abre a barra de ferramentas, então "Extrair frames" está disponível. |
| REQ-VID-FRAME-002 | O sistema deve apresentar os modos de extração "intervalo regular" e "frame único". | Deve ter | Mantido | NOVO | UC-VID-003/Passo 2 | Os dois modos cobrem o uso em série e o uso pontual. | Dado a ferramenta aberta, então os dois modos estão disponíveis. |
| REQ-VID-FRAME-003 | O sistema deve permitir ao utilizador indicar um instante do vídeo no modo frame único. | Deve ter | Mantido | NOVO | UC-VID-003/FA1 | Define que frame extrair no modo frame único. | Dado o modo frame único, quando indica 00:12, então o parâmetro fica guardado na ferramenta. |
| REQ-VID-FRAME-004 | O sistema deve mostrar a pré-visualização, no vídeo aberto, do frame do instante escolhido ou, no modo intervalo, do primeiro frame a extrair. | Deve ter | Refinado | ALT | UC-VID-003/Passo 3, UC-VID-003/FA1 | Permite confirmar o conteúdo antes de aplicar; estende a pré-visualização existente, que hoje recusa vídeos. | Dado o modo frame único e o instante 00:12, quando o utilizador pede a pré-visualização, então vê o frame desse instante. |
| REQ-VID-FRAME-005 | O sistema deve iniciar o processamento apenas quando o utilizador carrega em "Aplicar" e a validação é bem-sucedida. | Deve ter | Mantido | NOVO | UC-VID-003/Passo 4 | Evita processamentos e consumo de quota por engano. | Dado parâmetros válidos, quando carrega em "Aplicar", então o processamento inicia; sem "Aplicar", nada é processado. |
| REQ-VID-FRAME-006 | O sistema deve extrair o frame do instante indicado como imagem. | Deve ter | Mantido | NOVO | UC-VID-003/Passo 5, UC-VID-003/FA1 | Núcleo funcional do caso de uso. | Dado o instante 00:12, então é criada uma imagem desse frame para cada vídeo. |
| REQ-VID-FRAME-007 | O sistema deve guardar as imagens extraídas como resultados do projeto, várias por vídeo. | Deve ter | Refinado | ALT | UC-VID-003/Passo 6, UC-VID-003/Pós-condição de sucesso, DQ-017 | Hoje cada item gera um único resultado; a extração gera vários. | Dado uma extração de 6 imagens de um vídeo, quando termina, então o projeto tem 6 resultados associados a esse vídeo. |
| REQ-VID-FRAME-008 | O sistema deve permitir aplicar as ferramentas de imagem existentes às imagens extraídas depois de copiadas para um projeto. | Deve ter | Refinado | ALT | UC-VID-003/FA3, UC-VID-003/A3, DQ-018 | Concretiza o objetivo de reaproveitar as ferramentas atuais. | Dado imagens copiadas para um novo projeto, quando o utilizador aplica binarização, então o processamento conclui com sucesso. |
| REQ-VID-FRAME-009 | O sistema deve permitir ao utilizador definir um intervalo de N segundos e extrair um frame a cada intervalo. | Deve ter | Refinado | NOVO | UC-VID-003/Passo 3, UC-VID-003/Passo 5 | Modo principal do caso de uso. | Dado N = 10 e um vídeo de 60 s, então são extraídas 6 imagens. |
| REQ-VID-FRAME-010 | O sistema deve permitir escolher o formato das imagens extraídas entre PNG e JPEG, usando PNG por omissão. | Deveria ter | Refinado | NOVO | UC-VID-003/Passo 3, UC-VID-003/FA2, UC-VID-003/Q2 | Formatos diferentes servem usos diferentes. | Dado a escolha JPEG, então as imagens são JPEG; dado nenhuma escolha, então são PNG. |
| REQ-VID-FRAME-011 | O sistema deve permitir copiar as imagens extraídas para um novo projeto, como imagens normais. | Deve ter | Refinado | ALT | UC-VID-003/Passo 8, UC-VID-003/FA3, UC-VID-003/Q3, DQ-018 | Caminho para editar as imagens e mantê-las independentemente dos resultados. | Dado 6 imagens extraídas, quando escolhe "Copiar para novo projeto", então é criado um projeto com 6 imagens. |
| REQ-VID-FRAME-012 | O sistema deve continuar o processamento quando o utilizador abandona a página e apresentar o estado (em fila, em curso, concluído, falhado ou cancelado) quando regressa. | Deve ter | Refinado | ALT | UC-VID-003/FA4, DQ-008 | Reutiliza o processamento assíncrono existente. | Dado uma extração em curso, quando fecha e volta a abrir o projeto, então vê o estado atual e, no fim, os resultados. |
| REQ-VID-FRAME-013 | O sistema deve recusar iniciar o processamento quando o instante indicado for superior à duração de algum vídeo do projeto, indicando os vídeos afetados. | Deve ter | Refinado | NOVO | UC-VID-003/Exceção 1, DQ-020 | Evita pedir frames inexistentes antes de consumir quota. | Dado um projeto com vídeos de 10 s e 60 s e o instante 00:30, quando carrega em "Aplicar", então é recusado com indicação do vídeo de 10 s. |
| REQ-VID-FRAME-014 | O sistema deve indicar o limite e não iniciar o processamento quando o intervalo gerar, em algum vídeo, mais imagens do que o permitido. | Deve ter | Mantido | NOVO | UC-VID-003/Exceção 2, UC-VID-003/RN5 | Evita extrações desproporcionadas. | Dado um vídeo de 600 s e N = 5 (120 imagens), quando carrega em "Aplicar", então é recusado com indicação do limite de 100 (†). |
| REQ-VID-FRAME-015 | O sistema deve limitar a 100 (†) o número de imagens extraídas por vídeo em cada execução. | Deve ter | Refinado | NOVO | UC-VID-003/RN5, UC-VID-003/Q1, DQ-013 | Protege armazenamento e capacidade de processamento. | Dado um intervalo que gera 101 imagens, então é recusado; com 100, é aceite. |
| REQ-VID-FRAME-017 | O sistema deve marcar como falhado o vídeo que não pode ser descodificado e continuar com os restantes vídeos. | Deve ter | Refinado | NOVO | UC-VID-003/Exceção 6 | Um vídeo problemático não deve impedir os restantes. | Dado um projeto com um vídeo corrompido e um válido, quando aplica, então o corrompido fica "falhado" com mensagem e o válido gera resultados. |
| REQ-VID-FRAME-018 | O sistema deve impedir o início do processamento quando a quota diária do utilizador registado for inferior ao número de vídeos a processar. | Deve ter | Refinado | ALT | UC-VID-003/Exceção 5, UC-VID-003/RN2, DQ-019 | Aplica a regra de quotas existente à nova ferramenta. | Dado um registado com 2 operações disponíveis e 3 vídeos, quando aplica, então não inicia e vê "necessárias 3, disponíveis 2". |
| REQ-VID-FRAME-019 | O sistema não deve aplicar limite diário de operações a utilizadores premium ao usar esta ferramenta. | Deve ter | Mantido | ALT | UC-VID-003/RN3 | Mantém a vantagem do perfil premium. | Dado um premium com 20 operações hoje, quando aplica a extração, então o processamento inicia. |
| REQ-VID-FRAME-022 | O sistema deve sujeitar as imagens copiadas para um projeto às mesmas regras das imagens carregadas diretamente. | Deve ter | Refinado | ALT | UC-VID-003/RN7 | Garante tratamento igual ao de uma imagem carregada. | Dado uma imagem copiada, então aplicam-se as mesmas permissões, operações e eliminação de uma imagem carregada. |
| REQ-VID-FRAME-024 | O sistema deve debitar uma operação por vídeo processado, no início do processamento, independentemente do número de imagens extraídas. | Deve ter | Refinado | ALT | UC-VID-003/RN2, UC-VID-003/Q4, UC-VID-003/Q7, DQ-016, DQ-019 | Define a contagem da quota para vídeo; o débito no início faz contar os pedidos pendentes. | Dado um registado com 5 operações e um projeto com 2 vídeos e 3 imagens, quando aplica, então ficam 3 operações disponíveis. |
| REQ-VID-FRAME-027 | O sistema deve apresentar a percentagem de progresso da extração de cada vídeo. | Deveria ter | Mantido | ALT | UC-VID-003/Passo 5, UC-VID-003/FA4, DQ-008 | Um vídeo pode demorar minutos; o estado por passo não chega para estimar o tempo restante. | Dado um processamento em curso, quando o utilizador consulta o estado, então vê uma percentagem entre 0 % e 100 % que não diminui. |
| REQ-VID-FRAME-028 | O sistema deve permitir cancelar o processamento em fila ou em curso, reutilizando o cancelamento existente. | Deve ter | Refinado | ALT | UC-VID-003/FA5, DQ-008 | Evita ocupar capacidade e quota com pedidos desnecessários. | Dado um processamento em curso, quando o utilizador cancela, então o estado passa a "cancelado" e não fica nenhum resultado dessa execução. |
| REQ-VID-FRAME-029 | O sistema deve notificar o utilizador quando o processamento termina, com sucesso ou com falha. | Deveria ter | Mantido | ALT | UC-VID-003/Passo 7, UC-VID-003/FA4, DQ-008 | Com processamento em segundo plano, o utilizador precisa de saber quando voltar. | Dado um processamento em segundo plano, quando termina, então surge uma notificação com o resultado. |
| REQ-VID-FRAME-030 | O sistema deve apresentar, para cada vídeo cujo processamento falha, uma mensagem com a causa em linguagem corrente. | Deve ter | Refinado | ALT | UC-VID-003/Exceção 7, UC-VID-003/Pós-condição mínima, DQ-004 | O utilizador precisa de perceber se pode repetir ou se o vídeo tem um problema. Exige corrigir o envio de erros das ferramentas (`error.message` vs `error.msg`). | Dado uma falha injetada na extração de um vídeo, quando o utilizador consulta o estado, então vê "falhado" e a causa. |
| REQ-VID-FRAME-031 | O sistema deve devolver as operações debitadas dos vídeos que falham e de todos os vídeos quando o processamento é cancelado. | Deve ter | Refinado | ALT | UC-VID-003/Exceção 6, UC-VID-003/Exceção 7, UC-VID-003/FA5, UC-VID-003/Pós-condição mínima, DQ-003 | Falhas e cancelamentos não devem penalizar o utilizador; a devolução já existe no cancelamento e passa a existir também em falhas. | Dado um registado com 5 operações, 2 vídeos e uma falha injetada num deles, quando o processamento termina, então ficam 4 operações disponíveis. |
| REQ-VID-FRAME-032 | O sistema deve impedir utilizadores anónimos de adicionar a ferramenta "Extrair frames". | Deve ter | Refinado | ALT | UC-VID-003/RN4, UC-VID-003/Pré-condição (perfil), DQ-010 | Aplica a regra existente das ferramentas avançadas. | Dado uma sessão anónima com um vídeo aberto, quando tenta adicionar a ferramenta, então é recusado com indicação de que precisa de conta. |
| REQ-VID-FRAME-033 | O sistema deve manter as imagens copiadas para um projeto até o utilizador as eliminar. | Deve ter | Refinado | NOVO | UC-VID-003/FA3, UC-VID-003/Q6, DQ-005 | As imagens copiadas deixam de depender dos resultados, que são substituídos na execução seguinte. | Dado imagens copiadas há 30 dias, quando o utilizador abre o projeto, então continuam disponíveis. |
| REQ-VID-FRAME-034 | O sistema deve eliminar os ficheiros temporários da extração até 1 h (†) após o termo do processamento, com sucesso, falha ou cancelamento. | Deve ter | Mantido | NOVO | UC-VID-003/Pós-condição mínima, DQ-005 | Evita acumular dados fora do armazenamento de objetos. | Dado um processamento terminado, quando passa 1 h, então o worker não tem ficheiros temporários desse trabalho. |
| REQ-VID-FRAME-036 | O sistema deve identificar cada imagem extraída com o nome do vídeo e o instante do frame. | Deveria ter | Mantido | NOVO | UC-VID-003/Passo 6, UC-VID-003/FA1 | Permite reconhecer a origem de cada imagem. | Dado o frame de 12 s de "aula.mp4", então o nome da imagem contém "aula" e "12s". |
| REQ-VID-FRAME-049 | O sistema deve indicar, antes de aplicar, o número de imagens que vão ser geradas por vídeo e as operações de quota que vão ser consumidas. | Deve ter | Refinado | NOVO | UC-VID-003/Passo 3, DQ-020 | Permite ajustar o intervalo antes de consumir quota e capacidade. | Dado um vídeo de 60 s e N = 10, quando adiciona a ferramenta, então vê "6 imagens, 1 operação". |
| REQ-VID-FRAME-050 | O sistema deve processar apenas os vídeos do projeto com esta ferramenta, sem debitar operações pelas imagens, e informar o número de itens ignorados. | Deve ter | Novo | ALT | UC-VID-003/Passo 5, UC-VID-003/FA6, DQ-017 | A tabela de capacidades indica que a ferramenta aceita apenas vídeo. | Dado um projeto com 2 vídeos e 3 imagens, quando aplica, então são processados 2 itens e o utilizador é informado de 3 ignorados. |
| REQ-VID-FRAME-051 | O sistema deve recusar combinar a ferramenta "Extrair frames" com outras ferramentas na mesma pipeline. | Deve ter | Novo | ALT | UC-VID-003/Exceção 3, UC-VID-003/RN6, DQ-009 | A pipeline atual é linear (um resultado por passo); o encadeamento fica para a Fase 2. | Dado um projeto com a ferramenta de brilho, quando tenta adicionar "Extrair frames", então é recusado com explicação; e vice-versa. |
| REQ-VID-FRAME-052 | O sistema deve recusar iniciar o processamento quando o projeto não contém vídeos, informando que nenhum item é compatível. | Deve ter | Novo | ALT | UC-VID-003/Exceção 4, DQ-017 | Evita trabalhos vazios. | Dado um projeto só com imagens e a ferramenta adicionada, quando aplica, então é recusado com mensagem. |
| REQ-VID-FRAME-053 | O sistema deve guardar a duração e a resolução de cada vídeo no momento do carregamento. | Deve ter | Novo | ALT | UC-VID-003/A4, UC-VID-003/Passo 3, UC-VID-003/Exceção 1, DQ-020 | São necessárias para validar instantes e calcular o número de imagens sem reler o vídeo. | Dado o carregamento de um vídeo de 14 s em 1280×720, então o item fica com duração 14 s e resolução 1280×720. |
| REQ-VID-FRAME-054 | O sistema deve permitir adicionar e aplicar a ferramenta apenas ao dono do projeto e a utilizadores com permissão de edição. | Deve ter | Novo | ALT | UC-VID-003/RN8, UC-VID-003/Pré-condição (permissão), DQ-006 | Aplica as permissões de partilha existentes à nova ferramenta. | Dado um utilizador com partilha só de leitura, quando tenta adicionar a ferramenta, então recebe erro de permissão; consegue ver os resultados. |

### 4.1.2 Requisitos Não Funcionais e de Qualidade

As regras de negócio e restrições funcionais (limites de imagens, quota, combinação de ferramentas) estão na tabela 4.1.1. Aqui ficam apenas os requisitos de qualidade, classificados segundo a ISO/IEC 25010.

| **ID** | **Requisito** | **Característica ISO/IEC 25010** | **Alvo MVP** | **Alvo produção** | **Evolução** | **Origem (UC / DQ)** | **Critério de aceitação / verificação** |
|---|---|---|---|---|---|---|---|
| REQ-VID-FRAME-020 | O sistema deve remover os resultados parciais do vídeo cujo processamento falha, e de todos os vídeos quando é cancelado, mantendo os resultados dos vídeos concluídos. | Fiabilidade (Recuperabilidade) | Remoção dos parciais por vídeo, sem retoma | Uma repetição automática por vídeo e retoma a partir do último frame extraído | Refinado | UC-VID-003/Exceção 6, UC-VID-003/Exceção 7, UC-VID-003/FA5, UC-VID-003/Pós-condição mínima, DQ-004 | Dado 2 vídeos e uma falha forçada a meio do segundo, então os resultados do primeiro mantêm-se e não há resultados do segundo. |
| REQ-VID-FRAME-021 | O sistema deve manter os vídeos originais inalterados após a extração. | Segurança (Integridade) | Obrigatório | Obrigatório | Mantido | UC-VID-003/RN1, UC-VID-003/Pós-condição de sucesso | Dado o hash do original antes e depois, então são idênticos. |
| REQ-VID-FRAME-023 | O sistema deve extrair as imagens com a resolução original do vídeo. | Adequação Funcional (Correção funcional) | Resolução igual à do vídeo | Resolução igual à do vídeo | Mantido | UC-VID-003/A2, DQ-015 | Dado um vídeo 1920×1080, então a imagem tem 1920×1080 px. |
| REQ-VID-FRAME-025 | O sistema deve concluir a extração de um frame único em ≤ 5 s (†) por vídeo de até 10 min, sem outros trabalhos em fila. | Eficiência de Desempenho (Comportamento temporal) | ≤ 5 s | ≤ 2 s | Refinado | UC-VID-003/FA1, DQ-011 | Dado um vídeo de 10 min, quando aplica em modo frame único, então o resultado surge em ≤ 5 s. |
| REQ-VID-FRAME-038 | O sistema deve confirmar a receção do pedido em ≤ 2 s após "Aplicar", independentemente da duração dos vídeos. | Eficiência de Desempenho (Comportamento temporal) | ≤ 2 s | ≤ 1 s (†) | Mantido | UC-VID-003/Passo 4, UC-VID-003/FA4, DQ-011 | Dado vídeos de 15 s e 10 min, quando aplica, então a confirmação surge em ≤ 2 s. |
| REQ-VID-FRAME-039 | O sistema deve processar em simultâneo até 5 (†) vídeos, mantendo os restantes em fila. | Eficiência de Desempenho (Capacidade) | 5 réplicas do worker (†) | Réplicas ajustadas à carga, até 50 (†) | Refinado | UC-VID-003/FA4, DQ-007 | Dado 8 vídeos a processar em simultâneo, então 5 ficam em curso, 3 em fila e os 8 terminam com sucesso. |
| REQ-VID-FRAME-040 | O sistema deve restringir o acesso aos vídeos e aos resultados às permissões do projeto (dono e partilhas). | Segurança (Confidencialidade) | Obrigatório | Obrigatório | Refinado | UC-VID-003/RN8, UC-VID-003/Pré-condição (permissão), DQ-006 | Dado um utilizador sem acesso ao projeto, quando pede um vídeo ou resultado, então recebe erro de autorização. |
| REQ-VID-FRAME-041 | O sistema deve disponibilizar vídeos e resultados para descarga apenas através de ligações assinadas, não adivinháveis e com expiração. | Segurança (Confidencialidade) | Ligações assinadas com expiração de 1 h (mecanismo existente) | Expiração ≤ 15 min (†) | Refinado | UC-VID-003/Passo 8, DQ-006 | Dado uma ligação de descarga, quando um carácter da assinatura é alterado ou a ligação expirou, então o armazenamento devolve erro. |
| REQ-VID-FRAME-042 | O sistema deve atualizar o estado e a percentagem de progresso apresentados com um intervalo máximo de 10 s (†). | Usabilidade (Operabilidade) | ≤ 10 s | ≤ 2 s | Mantido | UC-VID-003/Passo 5, UC-VID-003/FA4, DQ-008 | Dado um processamento de 5 min, quando se observa o ecrã durante 1 min, então o valor é atualizado pelo menos a cada 10 s. |
| REQ-VID-FRAME-043 | O sistema deve extrair frames de todos os formatos aceites no carregamento (MP4, WebM e MOV), incluindo os codecs H.264, H.265 e VP9. | Compatibilidade (Interoperabilidade) | MP4, WebM, MOV (H.264, H.265, VP9) | Mais formatos aceites no carregamento (†) | Refinado | UC-VID-003/A1, DQ-001 | Dado um vídeo de cada formato e codec, quando aplica, então todos geram resultados. |
| REQ-VID-FRAME-044 | O sistema deve poder ser instalado e executado, incluindo o novo worker com `ffmpeg`, a partir de `docker compose up` num ambiente limpo. | Portabilidade (Instalabilidade) | Worker no `docker-compose.yaml`, com a versão do `ffmpeg` fixada | Instalação automatizada com uma só ação, com verificação de saúde do worker | Refinado | UC-VID-003/A7, DQ-012 | Dado uma máquina limpa, quando se executa `docker compose up`, então o teste de aceitação da extração passa. |
| REQ-VID-FRAME-045 | O sistema deve permitir acrescentar uma nova ferramenta de vídeo registando-a na tabela de capacidades e num novo worker, sem alterar o código das ferramentas existentes. | Manutenibilidade (Modularidade) | Objetivo (demonstrado quando existir uma segunda ferramenta de vídeo) | Obrigatório | Refinado | DQ-009, DQ-017 | Dado uma segunda ferramenta de vídeo acrescentada, então nenhum ficheiro das ferramentas existentes foi alterado. |
| REQ-VID-FRAME-046 | O sistema deve concluir a extração de 100 imagens de um vídeo de até 10 min em ≤ 60 s (†). | Eficiência de Desempenho (Comportamento temporal) | ≤ 60 s | ≤ 20 s | Mantido | UC-VID-003/Passo 5, DQ-011 | Dado um vídeo de 10 min e N = 6, quando aplica sem outros trabalhos, então os 100 resultados surgem em ≤ 60 s. |
| REQ-VID-FRAME-047 | O sistema deve produzir imagens PNG e JPEG que as ferramentas de imagem existentes aceitam sem conversão. | Compatibilidade (Interoperabilidade) | PNG e JPEG | PNG e JPEG | Mantido | UC-VID-003/A3, UC-VID-003/FA2, DQ-015 | Dado uma imagem extraída em cada formato, copiada para um projeto, quando se aplica uma ferramenta de imagem, então executa sem erro. |

> O alvo de produção é uma referência para a evolução futura (Fase 2), não um critério de aprovação do MVP.

### 4.1.3 Verificação da completude e dos limites do âmbito

| **Tópico a verificar** | **Aplicável?** | **Decisão / justificação** | **Requisito(s) relacionado(s)** |
|---|---|---|---|
| Formato, codec, duração e dimensão do vídeo | Parcial | A validação de formato, tamanho e duração por perfil é feita no carregamento (fora do âmbito, A1). Este caso de uso garante a descodificação dos formatos aceites, valida instantes e número de imagens com a duração guardada no carregamento e trata vídeos corrompidos. | FRAME-013, FRAME-014, FRAME-017, FRAME-043, FRAME-053 |
| Estado, progresso, cancelamento e resultado | Sim | Reutiliza o processamento assíncrono, o cancelamento e as notificações existentes; acrescenta a percentagem de progresso e vários resultados por vídeo. | FRAME-007, FRAME-012, FRAME-027, FRAME-028, FRAME-029, FRAME-042 |
| Falhas durante o processamento | Sim | Falha isolada por vídeo: remoção dos parciais desse vídeo, devolução da operação, mensagem com a causa, sem retoma automática no MVP. | FRAME-017, FRAME-020, FRAME-030, FRAME-031, FRAME-034 |
| Persistência e expiração dos ficheiros | Sim | Resultados seguem a regra existente (substituídos na execução seguinte); imagens copiadas mantêm-se até eliminação; temporários eliminados até 1 h; descarga por ligações assinadas. | FRAME-033, FRAME-034, FRAME-040, FRAME-041 |
| Perfis e contagem de operações | Sim | Ferramenta avançada: anónimo excluído, registado com uma operação por vídeo debitada no início e devolvida em falha ou cancelamento, premium sem limite. | FRAME-018, FRAME-019, FRAME-024, FRAME-031, FRAME-032 |
| Itens de tipos diferentes no mesmo projeto | Sim | A tabela de capacidades restringe a ferramenta a vídeos; as imagens são ignoradas sem custo e o utilizador é informado. | FRAME-050, FRAME-052 |
| Encadeamento de ferramentas e processamento em lote | Parcial | A ferramenta aplica-se a todos os vídeos do projeto (lote dentro do projeto). O encadeamento com outras ferramentas fica fora do MVP (RN6); as imagens são usadas com as ferramentas existentes através da cópia para um novo projeto. | FRAME-008, FRAME-011, FRAME-045, FRAME-051 |
| Partilha do projeto | Sim | As permissões existentes (leitura/edição) aplicam-se à nova ferramenta e aos resultados. | FRAME-040, FRAME-054 |

**Evolução:** *Mantido* = requisito preservado; *Refinado* = clarificado, tornado verificável ou alinhado com o sistema existente, sem mudar a intenção; *Novo* = acrescentado nesta versão. **NOVO/ALT** indica o impacto face ao PictuRAS existente, não a novidade face ao Exercício 1.

### 4.1.4 Requisitos eliminados

| **ID** | **Motivo** | **Substituído por** |
|---|---|---|
| REQ-VID-FRAME-016 | A validação de formato e codec é feita no carregamento do vídeo, fora deste caso de uso. | Requisitos de submissão de vídeo; FRAME-043 (descodificação) |
| REQ-VID-FRAME-026 | O limite de tamanho é validado no carregamento, por perfil. | Requisitos de submissão de vídeo (A6) |
| REQ-VID-FRAME-035 | O PictuRAS não tem pastas. | FRAME-011 (cópia para novo projeto) |
| REQ-VID-FRAME-037 | O limite de duração é validado no carregamento, por perfil. | Requisitos de submissão de vídeo (A6) |
| REQ-VID-FRAME-048 | A contagem dos pedidos pendentes resulta do débito no início, já existente. | FRAME-024 |

## 4.2 Impacto no sistema existente

| **Elemento existente afetado** | **Impacto (Manter / Estender / Alterar)** | **Descrição do impacto** | **Requisito(s) relacionado(s)** |
|---|---|---|---|
| Barra de ferramentas (`frontend/components/toolbar/toolbar.tsx`) | Alterar | Num vídeo aberto, passa a mostrar a ferramenta "Extrair frames" em vez de "Video tools coming soon"; mostra o número de imagens e operações. | FRAME-001, FRAME-049 |
| Pipeline de ferramentas do projeto (`POST /:user/:project/tool`) | Alterar | Aceita a nova ferramenta e recusa combiná-la com outras; recusa o perfil anónimo, como nas ferramentas avançadas. | FRAME-001, FRAME-032, FRAME-051, FRAME-054 |
| Tabela de capacidades (`projects/utils/toolCapabilities.js`, prevista no guião) | Estender | Regista `extract_frames` como ferramenta que aceita vídeo; as restantes aceitam imagem. | FRAME-045, FRAME-050, FRAME-052 |
| Processamento (`POST /:user/:project/process`) | Alterar | Processa só os itens compatíveis, valida instante e número de imagens, conta e informa os itens ignorados. | FRAME-005, FRAME-013, FRAME-014, FRAME-050, FRAME-052 |
| Contagem de operações avançadas (`advanced_tool_num`) | Alterar | Inclui `extract_frames` nas ferramentas avançadas e conta apenas os vídeos processados. | FRAME-018, FRAME-024 |
| Quota e devolução de operações (`users`: `/process/:n` e `/process/refund/:n`) | Estender | A devolução, que hoje só ocorre no cancelamento, passa a ocorrer também por vídeo falhado. | FRAME-031 |
| Perfil premium (sem limite) | Manter | Regra atual aplicada à nova ferramenta. | FRAME-019 |
| Contrato de mensagens das ferramentas (`project_msg.js` ↔ `Tools/utils/tool_msg.py`) | Alterar | Passa a permitir várias imagens de saída por item e progresso intermédio; corrige o envio de erros (`error.message` vs `error.msg`). | FRAME-007, FRAME-027, FRAME-030 |
| Tratamento das respostas das ferramentas (`process_msg`) | Alterar | A saída da extração termina a pipeline e cria um resultado por imagem; falha de um vídeo não afeta os restantes. | FRAME-007, FRAME-017, FRAME-020 |
| Resultados do projeto (`models/result.js`) | Estender | Vários resultados por item, com nome do vídeo e instante. | FRAME-007, FRAME-036 |
| Workers de ferramentas (`Tools/`) | Estender | Novo worker `extract_frames` com `ffmpeg` e fila RabbitMQ própria. | FRAME-006, FRAME-009, FRAME-039, FRAME-043, FRAME-044 |
| Pré-visualização (`POST /:user/:project/preview/:img`) | Alterar | Hoje recusa vídeos; passa a aceitar a pré-visualização de um frame com `extract_frames`. | FRAME-004 |
| Carregamento de vídeo (`POST /:user/:project/img`, `imgSchema`) | Alterar | Guarda a duração e a resolução já lidas com `ffprobe`. | FRAME-053 |
| Criação de projetos | Estender | Novo projeto criado a partir dos resultados de outro. | FRAME-011, FRAME-022, FRAME-033 |
| Cancelamento (`DELETE /:user/:project/process`) | Manter | Reutilizado sem alterações: token, remoção dos resultados da execução e devolução. | FRAME-020, FRAME-028 |
| Notificações (`wsGateway`) | Estender | Passa a transmitir a percentagem de progresso da extração. | FRAME-012, FRAME-027, FRAME-029, FRAME-042 |
| Partilha e permissões (`checkSharePermission`, `requireEditPermission`) | Manter | Aplicadas à nova ferramenta e aos resultados. | FRAME-040, FRAME-054 |
| Ligações de descarga (`getPresignedUrl.js`) | Manter | Já assinadas e com expiração de 1 h. | FRAME-041 |
| Instalação (`docker-compose.yaml`) | Estender | Novo serviço para o worker de extração. | FRAME-044 |

## 4.3 Matriz de Rastreabilidade Atualizada

| **Elemento de origem** | **Descrição abreviada** | **Requisito(s) relacionado(s)** |
|---|---|---|
| UC-VID-003/Passo 1 | Abrir projeto e vídeo | FRAME-001 |
| UC-VID-003/Passo 2 | Escolher ferramenta, parâmetros | FRAME-001, FRAME-002 |
| UC-VID-003/Passo 3 | Definir intervalo e formato, pré-visualização, estimativa | FRAME-004, FRAME-009, FRAME-010, FRAME-049, FRAME-053 |
| UC-VID-003/Passo 4 | Aplicar, validar, debitar | FRAME-005, FRAME-024, FRAME-038 |
| UC-VID-003/Passo 5 | Extrair frames com progresso | FRAME-006, FRAME-009, FRAME-027, FRAME-042, FRAME-046, FRAME-050 |
| UC-VID-003/Passo 6 | Guardar como resultados | FRAME-007, FRAME-036 |
| UC-VID-003/Passo 7 | Notificar fim | FRAME-029 |
| UC-VID-003/Passo 8 | Consultar e descarregar resultados | FRAME-011, FRAME-041 |
| UC-VID-003/FA1 | Frame único | FRAME-003, FRAME-004, FRAME-006, FRAME-025, FRAME-036 |
| UC-VID-003/FA2 | Formato por omissão | FRAME-010, FRAME-047 |
| UC-VID-003/FA3 | Copiar para novo projeto e editar | FRAME-008, FRAME-011, FRAME-033 |
| UC-VID-003/FA4 | Segundo plano | FRAME-012, FRAME-027, FRAME-029, FRAME-038, FRAME-039, FRAME-042 |
| UC-VID-003/FA5 | Cancelar processamento | FRAME-020, FRAME-028, FRAME-031 |
| UC-VID-003/FA6 | Projeto com imagens e vídeos | FRAME-050 |
| UC-VID-003/Exceção 1 | Instante fora da duração | FRAME-013, FRAME-053 |
| UC-VID-003/Exceção 2 | Demasiadas imagens | FRAME-014, FRAME-015 |
| UC-VID-003/Exceção 3 | Combinação com outras ferramentas | FRAME-051 |
| UC-VID-003/Exceção 4 | Projeto sem vídeos | FRAME-052 |
| UC-VID-003/Exceção 5 | Quota insuficiente | FRAME-018 |
| UC-VID-003/Exceção 6 | Vídeo corrompido | FRAME-017, FRAME-020, FRAME-031 |
| UC-VID-003/Exceção 7 | Falha no processamento | FRAME-020, FRAME-030, FRAME-031 |
| UC-VID-003/Pós-condição de sucesso | Resultados no projeto, originais intactos | FRAME-007, FRAME-021 |
| UC-VID-003/Pós-condição mínima | Sem parciais, operações devolvidas | FRAME-020, FRAME-030, FRAME-031, FRAME-034 |
| UC-VID-003/Pré-condição (perfil) | Registado ou premium | FRAME-032 |
| UC-VID-003/Pré-condição (permissão) | Dono ou edição | FRAME-040, FRAME-054 |
| UC-VID-003/RN1 | Não altera originais | FRAME-021 |
| UC-VID-003/RN2 | Ferramenta avançada, 1 operação por vídeo | FRAME-018, FRAME-024 |
| UC-VID-003/RN3 | Premium sem limite | FRAME-019 |
| UC-VID-003/RN4 | Anónimo excluído | FRAME-032 |
| UC-VID-003/RN5 | Máximo de imagens por vídeo | FRAME-014, FRAME-015 |
| UC-VID-003/RN6 | Sem combinação com outras ferramentas | FRAME-051 |
| UC-VID-003/RN7 | Mesmas regras das imagens | FRAME-022 |
| UC-VID-003/RN8 | Permissões do projeto | FRAME-040, FRAME-054 |
| UC-VID-003/A1 | Carregamento validado fora do UC | FRAME-043 |
| UC-VID-003/A2 | Resolução original | FRAME-023 |
| UC-VID-003/A3 | Ferramentas sem alterações | FRAME-008, FRAME-047 |
| UC-VID-003/A4 | Duração guardada no carregamento | FRAME-053 |
| UC-VID-003/A7 | Worker com ffmpeg | FRAME-044 |
| UC-VID-003/Q1 | Máximo de imagens | FRAME-015 |
| UC-VID-003/Q2 | Formatos de imagem | FRAME-010 |
| UC-VID-003/Q3 | Agrupamento | FRAME-011 |
| UC-VID-003/Q4 | Contagem na quota | FRAME-024 |
| UC-VID-003/Q6 | Persistência | FRAME-033 |
| UC-VID-003/Q7 | Pedidos pendentes na quota | FRAME-024 |
| DQ-001 | Formatos aceites no carregamento | FRAME-043 |
| DQ-003 | Devolução de operações | FRAME-031 |
| DQ-004 | Falha isolada por vídeo, sem retoma | FRAME-020, FRAME-030 |
| DQ-005 | Persistência e temporários | FRAME-033, FRAME-034 |
| DQ-006 | Permissões do projeto e ligações assinadas | FRAME-040, FRAME-041, FRAME-054 |
| DQ-007 | Réplicas do worker e fila | FRAME-039 |
| DQ-008 | Estado, progresso, cancelamento e notificação | FRAME-012, FRAME-027, FRAME-028, FRAME-029, FRAME-042 |
| DQ-009 | Sem encadeamento; modularidade | FRAME-045, FRAME-051 |
| DQ-010 | Anónimo excluído | FRAME-032 |
| DQ-011 | Alvos de desempenho | FRAME-025, FRAME-038, FRAME-046 |
| DQ-012 | Instalação com docker compose | FRAME-044 |
| DQ-013 | 100 imagens por vídeo | FRAME-015 |
| DQ-015 | Resolução e compatibilidade das imagens | FRAME-023, FRAME-047 |
| DQ-016 | Pedidos pendentes contam | FRAME-024 |
| DQ-017 | Extração como ferramenta de vídeo da pipeline | FRAME-001, FRAME-007, FRAME-045, FRAME-050, FRAME-052 |
| DQ-018 | Cópia para novo projeto | FRAME-008, FRAME-011 |
| DQ-019 | Ferramenta avançada, 1 operação por vídeo | FRAME-018, FRAME-024 |
| DQ-020 | Duração e resolução guardadas no carregamento | FRAME-013, FRAME-049, FRAME-053 |

**Decisões de qualidade (v1.3)**

| **ID** | **Decisão de qualidade** | **Justificação** | **Requisito(s) relacionado(s)** |
|---|---|---|---|
| DQ-001 | *Revista em v1.3.* A extração suporta todos os formatos aceites no carregamento (MP4, WebM, MOV); a validação de formato é feita no carregamento. | Evita validar duas vezes e mantém uma só lista de formatos. | FRAME-043 |
| DQ-002 | *Substituída em v1.3.* Os limites de duração e tamanho são definidos por perfil no carregamento (A6), fora deste caso de uso. | Os limites já estão implementados e aplicam-se a todas as ferramentas de vídeo. | — |
| DQ-003 | As operações de vídeos que falham ou de processamentos cancelados são devolvidas. | Falhas e cancelamentos não devem penalizar o utilizador. | FRAME-031 |
| DQ-004 | A falha é isolada por vídeo: os parciais desse vídeo são removidos e os restantes vídeos continuam; no MVP não há retoma automática. | Um vídeo problemático não deve anular o trabalho dos restantes. | FRAME-020, FRAME-030 |
| DQ-005 | Os resultados seguem a regra existente; as imagens copiadas para um projeto mantêm-se até eliminação; os temporários são eliminados até 1 h após o termo (†). | Evita perda de trabalho e retenção desnecessária de dados. | FRAME-033, FRAME-034 |
| DQ-006 | O acesso segue as permissões do projeto (dono e partilhas) e a descarga usa as ligações assinadas existentes. | Reutiliza o modelo de segurança atual sem criar exceções para vídeo. | FRAME-040, FRAME-041, FRAME-054 |
| DQ-007 | O MVP corre 5 réplicas (†) do worker de extração; os restantes vídeos ficam em fila no RabbitMQ. | Limita o consumo de CPU e mantém a aplicação responsiva. | FRAME-039 |
| DQ-008 | Estado, cancelamento e notificação reutilizam os mecanismos existentes; acrescenta-se a percentagem de progresso, atualizada no máximo a cada 10 s no MVP (†). | Operações que duram minutos exigem feedback ao utilizador. | FRAME-012, FRAME-027, FRAME-028, FRAME-029, FRAME-042 |
| DQ-009 | No MVP a extração não se combina com outras ferramentas; novas ferramentas de vídeo acrescentam-se pela tabela de capacidades sem alterar as existentes. | A pipeline atual é linear; o encadeamento com `{ accepts, produces }` fica para a Fase 2. | FRAME-045, FRAME-051 |
| DQ-010 | O perfil anónimo não tem acesso a esta ferramenta. | Decorre da regra existente das ferramentas avançadas. | FRAME-032 |
| DQ-011 | Alvos de desempenho: confirmação do pedido em ≤ 2 s e tempo de extração proporcional ao número de imagens (valores em 4.1.2) (†). | Distingue o tempo de resposta do pedido do tempo de processamento. | FRAME-025, FRAME-038, FRAME-046 |
| DQ-012 | O worker de extração é um serviço do `docker-compose.yaml`, com o `ffmpeg` instalado na imagem e versão fixada. | Mantém a instalação reprodutível com binários externos. | FRAME-044 |
| DQ-013 | Máximo de 100 imagens por vídeo em cada execução (†). | Protege armazenamento e capacidade. | FRAME-015 |
| DQ-014 | *Substituída em v1.3 pela DQ-018* (o PictuRAS não tem pastas). | — | — |
| DQ-015 | As imagens extraídas têm a resolução do vídeo e são aceites pelas ferramentas de imagem existentes sem conversão. | Garante a integração entre vídeo e imagem. | FRAME-023, FRAME-047 |
| DQ-016 | Os pedidos pendentes contam para a quota, porque as operações são debitadas no início do processamento (mecanismo existente). | Impede ultrapassar a quota com pedidos simultâneos. | FRAME-024 |
| DQ-017 | A extração é uma ferramenta de vídeo da pipeline (`extract_frames`, aceita vídeo), executada por um worker em `Tools/` via RabbitMQ, como as ferramentas de imagem. | Reutiliza fila, estados, cancelamento, quota, partilha e descarga; segue o guião interno (tabela de capacidades). | FRAME-001, FRAME-007, FRAME-045, FRAME-050, FRAME-052 |
| DQ-018 | As imagens extraídas ficam nos resultados do projeto; para as editar, copiam-se para um novo projeto. | Permite usar as ferramentas de imagem sem encadeamento na pipeline. | FRAME-008, FRAME-011 |
| DQ-019 | "Extrair frames" é uma ferramenta avançada: uma operação por vídeo processado, independentemente do número de imagens. | Responde à questão "operação por vídeo, por minuto ou por fotograma?" de forma simples e coerente com as ferramentas avançadas. | FRAME-018, FRAME-024 |
| DQ-020 | A duração e a resolução de cada vídeo são guardadas no carregamento. | Permite validar e estimar antes de processar, sem reler o vídeo. | FRAME-013, FRAME-049, FRAME-053 |

**Verificações de cobertura**
- [x] Cada requisito funcional e não funcional aparece na matriz.
- [x] Cada requisito tem origem identificada: elemento do caso de uso, regra de negócio ou decisão de qualidade.
- [x] Todos os elementos relevantes do caso de uso (passos, fluxos alternativos, exceções, regras de negócio e pós-condições) têm requisito associado.
- [x] Os tópicos parciais na secção 4.1.3 estão justificados e os requisitos eliminados estão registados em 4.1.4.
- [x] O impacto no sistema existente está ligado aos elementos de código afetados e aos requisitos relevantes.
