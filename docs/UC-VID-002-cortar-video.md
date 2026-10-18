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
| Funcionalidade | Ferramenta de vídeo "Cortar vídeo": mantém apenas o excerto entre dois instantes, como mais uma ferramenta da pipeline de edição |
| Perfil(s) de utilizador abrangido(s) | Anónimo, registado e premium. É uma ferramenta básica, equivalente ao recorte de imagem já existente: não consome operações da quota diária e está disponível para todos os perfis, dentro dos limites de vídeo de cada perfil definidos no carregamento. |

### Justificação no contexto do MVP

O corte é a operação base de qualquer editor de vídeo, equivalente ao recorte já existente para imagens. Valida a parte do suporte a vídeo que a extração de frames não cobre: uma ferramenta que recebe um vídeo e produz um novo vídeo, com parametrização temporal (linha temporal e instantes), recodificação e reprodução do resultado. Sem ela, a aplicação consegue obter imagens a partir de vídeos, mas não editar os próprios vídeos.

---

# 2. Caso de Uso

## 2.1 Cabeçalho

| Secção | Detalhes |
|---|---|
| ID do Caso de Uso | UC-VID-002 |
| Nome | Cortar vídeo |
| Versão | v1.3 |
| Autor | Diogo Linhares Campos<br>Marco António Ferreira Abreu<br>Cláudio Rafael Oliveira Ferreira<br>Nelson Daniel Araújo Sousa |
| Data | 2026-10-18 |
| Objetivo | Permitir ao utilizador obter novos vídeos contendo apenas o excerto entre um instante inicial e um instante final escolhidos, a partir dos vídeos de um projeto. |
| Âmbito | Serviço `projects` (pipeline de ferramentas e processamento), novo worker de vídeo em `Tools/` e frontend (barra de ferramentas, linha temporal e resultados) |
| Ator Principal | Utilizador (anónimo, registado ou premium), dono do projeto ou com permissão de edição |
| Stakeholders e Interesses | - **Utilizador**: pretende remover partes indesejadas de um vídeo sem recorrer a software externo.<br>- **Proprietário do sistema**: pretende disponibilizar uma operação de vídeo essencial a todos os perfis, como acontece com o recorte de imagem.<br>- **Equipa de desenvolvimento**: pretende validar uma ferramenta de vídeo que produz um novo vídeo na pipeline existente. |
| Pré-condições | - O utilizador é dono do projeto ou tem permissão de edição sobre ele.<br>- O projeto contém pelo menos um vídeo, carregado e validado no carregamento (formato, tamanho e duração por perfil). |
| Trigger | O utilizador pretende obter um excerto dos vídeos de um projeto. |

## 2.2 Fluxo Principal

| Passo | Ação do Ator | Resposta do Sistema |
|---|---|---|
| 1 | O utilizador abre um projeto que contém vídeos e abre um dos vídeos. | O sistema reproduz o vídeo e apresenta a barra de ferramentas com as ferramentas de vídeo disponíveis. |
| 2 | O utilizador escolhe a ferramenta "Cortar vídeo". | O sistema apresenta a linha temporal do vídeo aberto, com a duração total e os marcadores de início e de fim. |
| 3 | O utilizador define o instante inicial e o instante final e guarda a ferramenta. | O sistema mostra a duração do excerto, indica os vídeos do projeto em que o excerto não cabe e adiciona a ferramenta à pipeline do projeto. |
| 4 | O utilizador carrega em "Aplicar". | O sistema valida a pipeline e os instantes face à duração de cada vídeo, cria um trabalho de processamento por vídeo e confirma a receção do pedido. |
| 5 | — | O sistema gera, para cada vídeo, um novo vídeo apenas com o excerto selecionado e atualiza a percentagem de progresso. As imagens do projeto não são processadas por esta ferramenta. |
| 6 | — | O sistema guarda os novos vídeos como resultados do projeto, identificando cada um com o nome do vídeo de origem e o intervalo cortado. |
| 7 | — | O sistema notifica o utilizador de que o processamento terminou. |
| 8 | O utilizador consulta os resultados. | O sistema apresenta os vídeos cortados nos resultados do projeto, prontos a reproduzir e a descarregar. |

## 2.3 Fluxos Alternativos

| Fluxo | Descrição |
|---|---|
| FA1 — Pré-visualização do excerto | No passo 3, antes de guardar, o utilizador pede a pré-visualização. O sistema reproduz, num leitor do vídeo aberto dentro da própria ferramenta, apenas o intervalo entre o instante inicial e o final, sem criar ficheiros. Continua no passo 3. |
| FA2 — Introdução manual de tempos | No passo 3, o utilizador introduz os instantes no formato hh:mm:ss em vez de usar a linha temporal. O sistema atualiza os marcadores. Continua no passo 3. |
| FA3 — Continuar a editar os vídeos cortados | No passo 8, o utilizador escolhe "Copiar para novo projeto". O sistema cria um projeto com os vídeos cortados como vídeos normais, aos quais o utilizador pode aplicar outras ferramentas de vídeo (por exemplo, a extração de frames). |
| FA4 — Processamento em segundo plano | Após o passo 4, o utilizador abandona a página. O processamento continua e, ao regressar, o utilizador vê o estado (em fila, em curso, concluído, falhado ou cancelado) e a percentagem de progresso. |
| FA5 — Desistir antes de aplicar | Nos passos 2–3, o utilizador fecha a ferramenta sem a guardar ou repõe os valores por omissão. O sistema não altera a pipeline e não cria qualquer ficheiro. |
| FA6 — Cancelar processamento | Após o passo 4, enquanto o processamento está em fila ou em curso, o utilizador cancela-o. O sistema termina o processamento e remove os resultados dessa execução. |
| FA7 — Projeto com imagens e vídeos | No passo 4, o projeto contém também imagens. O sistema processa apenas os vídeos e informa o utilizador do número de itens ignorados. |

## 2.4 Exceções

| Condição | Comportamento do Sistema |
|---|---|
| **Exceção 1** — O instante inicial é maior ou igual ao final (passo 3) | O sistema impede guardar a ferramenta e informa o utilizador. |
| **Exceção 2** — O excerto tem menos de 1 s (passo 3) | O sistema impede guardar a ferramenta e indica a duração mínima. |
| **Exceção 3** — O instante final ultrapassa a duração de algum vídeo do projeto (passos 3–4) | O sistema não inicia o processamento e indica os vídeos afetados e a respetiva duração. |
| **Exceção 4** — A ferramenta de corte é combinada com outras ferramentas na mesma pipeline (passo 3) | O sistema recusa adicionar a ferramenta e explica que, nesta versão, o corte tem de ser a única ferramenta do projeto. |
| **Exceção 5** — O projeto não contém vídeos (passo 4) | O sistema não inicia o processamento e informa que nenhum item é compatível com a ferramenta. |
| **Exceção 6** — Um vídeo está corrompido ou não pode ser descodificado (passo 5) | O sistema marca esse vídeo como falhado, remove o resultado parcial desse vídeo e continua com os restantes vídeos. |
| **Exceção 7** — O processamento de um vídeo falha (passos 5–6) | O sistema remove o resultado parcial desse vídeo, informa a causa e mantém os resultados dos vídeos concluídos. O vídeo original permanece inalterado. |

## 2.5 Pós-condições

| Tipo | Resultado |
|---|---|
| Garantia de Sucesso | Os vídeos cortados estão nos resultados do projeto, com a duração do excerto selecionado, e os vídeos originais permanecem inalterados. |
| Garantia Mínima | Em caso de falha ou cancelamento, não fica nenhum vídeo incompleto nos resultados, os vídeos originais permanecem inalterados e o utilizador é informado. |

## 2.6 Regras de Negócio e Restrições

| ID | Regra |
|---|---|
| RN1 | O corte não altera o vídeo original; é sempre gerado um novo ficheiro. |
| RN2 | "Cortar vídeo" é uma ferramenta básica: não consome operações da quota diária e está disponível para os perfis anónimo, registado e premium. |
| RN3 | Os vídeos a cortar respeitam os limites de duração e tamanho do perfil, validados no carregamento. |
| RN4 | A ferramenta aplica-se apenas a vídeos; as imagens do projeto são ignoradas. |
| RN5 | O instante inicial tem de ser inferior ao final, o excerto tem pelo menos 1 s e o instante final não pode ultrapassar a duração de nenhum vídeo do projeto. |
| RN6 | Resultados incompletos não devem ser disponibilizados como válidos. |
| RN7 | No MVP, cada operação corta um único excerto e a ferramenta de corte não pode ser combinada com outras ferramentas na mesma pipeline. |
| RN8 | Só o dono do projeto e os utilizadores com permissão de edição podem adicionar e aplicar a ferramenta; com permissão de leitura, apenas se consultam os resultados. |
| RN9 | O mesmo intervalo de corte aplica-se a todos os vídeos do projeto. |

## 2.7 Assunções

| ID | Assunção |
|---|---|
| A1 | O carregamento e a validação dos vídeos (formatos MP4, WebM e MOV; tamanho e duração por perfil) estão fora do âmbito deste caso de uso e já estão implementados. |
| A2 | A duração de cada vídeo fica guardada no carregamento e permite validar os instantes antes do processamento. |
| A3 | O corte pode demorar em vídeos longos e necessita de estados intermédios. |
| A4 | Para o MVP, apenas é suportado um excerto por operação. |
| A5 | Os resultados seguem a regra existente do PictuRAS: são substituídos na execução seguinte da pipeline e eliminados com o projeto; para os manter e continuar a editá-los, copiam-se para um novo projeto (FA3). |
| A6 | Os limites de vídeo por perfil já estão definidos no carregamento: anónimo 20 MB / 15 s, registado 100 MB / 60 s, premium 500 MB / 10 min. |
| A7 | O corte é executado por um worker em `Tools/` com `ffmpeg`, alimentado por uma fila RabbitMQ própria; o número de trabalhos simultâneos corresponde ao número de réplicas desse worker. |
| A8 | No MVP uma falha não é retomada automaticamente: o utilizador volta a aplicar a pipeline. |
| A9 | Uma precisão de corte de ±1 s é aceitável no MVP. |
| A10 | O perfil "registado" corresponde ao tipo `free` no serviço `users`. |

## 2.8 Questões em Aberto

| ID | Questão |
|---|---|
| Q1 | Deve ser possível cortar vários excertos e juntá-los numa só operação? — **Resolução:** fora do âmbito do MVP; um só excerto por operação (TRIM-023, A4). |
| Q2 | Qual a precisão mínima do corte (segundo ou frame)? — **Resolução:** ±1 s no MVP e 1 frame em produção (†) (TRIM-022). |
| Q3 | O novo vídeo deve manter a qualidade original ou ser recodificado? — **Resolução:** mantém o contentor do original e é recodificado com o codec habitual desse contentor (MP4/MOV: H.264 e AAC; WebM: VP9 e Opus), o que garante a precisão do corte (TRIM-044, DQ-113). |
| Q4 | Deve existir uma duração mínima para o excerto? — **Resolução:** 1 s (†) (TRIM-034). |
| Q5 | Qual a duração máxima de vídeo suportada? — **Resolução:** a definida por perfil no carregamento (A6); esta ferramenta não acrescenta limites. |
| Q6 | Os resultados devem expirar ao fim de algum tempo? — **Resolução:** seguem a regra existente (A5); os vídeos copiados para um projeto mantêm-se até serem eliminados (TRIM-032). |
| Q7 | Os pedidos em fila ou em curso devem contar para a quota? — **Resolução:** não se aplica: o corte é uma ferramenta básica e não consome operações (RN2). |
| Q8 | O corte deve poder ser seguido de outras ferramentas na mesma pipeline (ex.: cortar e extrair frames)? — **Resolução:** não no MVP (RN7); o caminho é copiar os vídeos cortados para um novo projeto (FA3). |
| Q9 | Deve ser possível escolher um intervalo diferente para cada vídeo do projeto? — **Resolução:** não no MVP; o mesmo intervalo aplica-se a todos os vídeos (RN9), como as restantes ferramentas aplicam os mesmos parâmetros a todos os itens. Avaliar na Fase 2. |

---

# 3. Utilização de agentes de IA

| Ferramenta / skill | Tarefa apoiada | Validação realizada pela equipa |
|---|---|---|
| Claude | Apoio na definição do caso de uso, fluxos, exceções, regras de negócio, assunções e questões em aberto. | Revisão manual pela equipa comparando com o enunciado, template e exemplos fornecidos pelos docentes. |
| Claude | Elaboração da ERS do Exercício 2 (secção 4): classificação segundo a ISO/IEC 25010, proposta de valores (†) e decisões de qualidade, catálogo de requisitos, impacto e matriz de rastreabilidade. | [preencher: revisão da equipa] |
| Claude Code | Revisão v1.2: alinhamento com o sistema implementado (upload de vídeo, limites por perfil, pipeline de ferramentas, partilha) e com o UC-VID-003; corte como ferramenta básica e isolada na pipeline; renumeração das decisões de qualidade. | [preencher: revisão da equipa] |
| Claude Code | Implementação (v1.3): worker `Tools/trim`, alterações ao `projects` e frontend (linha temporal, tempos hh:mm:ss, pré-visualização do excerto); testes unitários (`node:test`, `unittest`) e ponta a ponta (`projects/test/e2e/`); tabela de realização e verificação (4.4). | [preencher: revisão da equipa — p. ex. teste manual no navegador do corte e da pré-visualização] |

---

# 4. Especificação de Requisitos do Sistema (ERS)

**Caso de Uso:** UC-VID-002 — Cortar vídeo  
**Versão do dossiê:** v1.3  
**Baseline do Exercício 1:** v1.0 — REQ-VID-TRIM-001 a REQ-VID-TRIM-024

> O catálogo 4.1 é a fonte única dos requisitos desta ERS. A matriz 4.3 rastreia esses IDs até ao caso de uso ou às decisões de qualidade (DQ). A tabela 4.2 descreve o impacto no sistema existente. Nas tabelas 4.2 e 4.3 os IDs aparecem abreviados (por exemplo, TRIM-007 = REQ-VID-TRIM-007). Os elementos locais do caso de uso são qualificados (por exemplo, UC-VID-002/RN2). Valores marcados com (†) são propostas da equipa, a confirmar. Os IDs eliminados não são reutilizados (ver 4.1.4). As decisões de qualidade deste caso de uso usam a gama DQ-101 a DQ-199, para não colidirem com as do UC-VID-003 (ver 4.3).

## 4.1 Requisitos da ERS

### 4.1.1 Requisitos Funcionais

| **ID** | **Requisito** | **Prioridade** | **Evolução** | **Novo/Alt** | **Origem (UC / RN / decisão)** | **Justificação** | **Critério de aceitação / verificação** |
|---|---|---|---|---|---|---|---|
| REQ-VID-TRIM-001 | O sistema deve disponibilizar a ferramenta "Cortar vídeo" na barra de ferramentas quando o item aberto é um vídeo, permitindo adicioná-la à pipeline do projeto. | Deve ter | Refinado | ALT | UC-VID-002/Trigger, UC-VID-002/Passos 1–2, DQ-101 | Ponto de entrada da funcionalidade, ao lado das restantes ferramentas de vídeo. | Dado um projeto com um vídeo aberto no carrossel, quando o utilizador abre a barra de ferramentas, então "Cortar vídeo" está disponível. |
| REQ-VID-TRIM-002 | O sistema deve apresentar a linha temporal do vídeo aberto com a sua duração total. | Deve ter | Mantido | NOVO | UC-VID-002/Passo 2, UC-VID-002/A2 | O utilizador precisa de ver a duração total para escolher os instantes. | Dado um vídeo de 30 s aberto, quando escolhe a ferramenta, então vê a linha temporal e a duração 00:30. |
| REQ-VID-TRIM-003 | O sistema deve permitir ao utilizador definir o instante inicial e o instante final do excerto na linha temporal. | Deve ter | Mantido | NOVO | UC-VID-002/Passo 3 | Define o excerto a manter. | Dado a linha temporal, quando o utilizador arrasta os marcadores, então os instantes são atualizados. |
| REQ-VID-TRIM-004 | O sistema deve mostrar a duração do excerto selecionado. | Deve ter | Mantido | NOVO | UC-VID-002/Passo 3 | Dá feedback da duração do excerto antes de guardar. | Dado início 00:10 e fim 00:40, então é apresentada a duração 00:30. |
| REQ-VID-TRIM-005 | O sistema deve iniciar o processamento apenas quando o utilizador carrega em "Aplicar" e a validação é bem-sucedida. | Deve ter | Refinado | NOVO | UC-VID-002/Passo 4 | Evita processamentos por engano. | Dado instantes válidos, quando carrega em "Aplicar", então o processamento inicia; sem "Aplicar", nada é processado. |
| REQ-VID-TRIM-006 | O sistema deve gerar, para cada vídeo, um novo vídeo que contém apenas o excerto selecionado. | Deve ter | Refinado | NOVO | UC-VID-002/Passo 5 | Núcleo funcional do caso de uso. | Dado o excerto 00:10–00:40 e um vídeo de 60 s, então o novo vídeo corresponde a esse intervalo. |
| REQ-VID-TRIM-007 | O sistema deve guardar os vídeos cortados como resultados do projeto. | Deve ter | Refinado | ALT | UC-VID-002/Passo 6, UC-VID-002/Pós-condição de sucesso, DQ-101 | O PictuRAS guarda o resultado das ferramentas nos resultados do projeto. | Dado o processamento concluído, então cada vídeo do projeto tem um vídeo cortado nos resultados. |
| REQ-VID-TRIM-008 | O sistema deve permitir reproduzir e descarregar os vídeos cortados a partir dos resultados do projeto. | Deve ter | Refinado | ALT | UC-VID-002/Passo 8 | O utilizador tem de poder ver e levar o resultado. | Dado um vídeo cortado nos resultados, quando o utilizador o abre, então pode reproduzi-lo; quando descarrega os resultados, então o vídeo está incluído. |
| REQ-VID-TRIM-009 | O sistema deve permitir reproduzir, num leitor do vídeo aberto dentro da ferramenta, apenas o excerto selecionado, sem criar ficheiros. | Deveria ter | Refinado | NOVO | UC-VID-002/FA1 | Permite verificar o excerto antes de aplicar. | Dado o excerto 00:10–00:20, quando pede a pré-visualização, então a reprodução começa em 00:10 e para em 00:20. |
| REQ-VID-TRIM-010 | O sistema deve permitir ao utilizador introduzir os instantes no formato hh:mm:ss. | Deveria ter | Mantido | NOVO | UC-VID-002/FA2 | Dá uma precisão que o arrastar na linha temporal não garante. | Dado a introdução manual "00:01:30", então o instante inicial passa a 90 s. |
| REQ-VID-TRIM-011 | O sistema deve continuar o processamento quando o utilizador abandona a página. | Deve ter | Mantido | ALT | UC-VID-002/FA4 | Operação potencialmente demorada; reutiliza o processamento assíncrono existente. | Dado um corte em curso, quando fecha e volta a abrir o projeto, então os vídeos cortados surgem nos resultados no fim. |
| REQ-VID-TRIM-012 | O sistema deve apresentar o estado do processamento (em fila, em curso, concluído, falhado ou cancelado). | Deve ter | Refinado | ALT | UC-VID-002/A3, UC-VID-002/FA4, DQ-108 | Permite acompanhar uma operação que não é instantânea. | Dado um corte em curso, quando o utilizador volta ao projeto, então o estado é visível. |
| REQ-VID-TRIM-013 | O sistema deve permitir ao utilizador desistir antes de aplicar, sem alterar a pipeline nem criar ficheiros. | Deveria ter | Refinado | NOVO | UC-VID-002/FA5 | Permite desistir sem efeitos. | Dado a ferramenta aberta, quando o utilizador a fecha sem guardar, então a pipeline e os resultados ficam iguais. |
| REQ-VID-TRIM-014 | O sistema deve impedir guardar a ferramenta e informar o utilizador quando o instante inicial for maior ou igual ao final. | Deve ter | Mantido | NOVO | UC-VID-002/Exceção 1, UC-VID-002/RN5 | Instantes incoerentes não definem um excerto. | Dado início 00:40 e fim 00:10, então guardar está bloqueado com mensagem. |
| REQ-VID-TRIM-015 | O sistema deve recusar iniciar o processamento quando o instante final ultrapassar a duração de algum vídeo do projeto, indicando os vídeos afetados. | Deve ter | Refinado | NOVO | UC-VID-002/Exceção 3, UC-VID-002/RN5, DQ-114 | Evita cortes sobre instantes inexistentes. | Dado vídeos de 10 s e 60 s e o fim em 00:30, quando aplica, então é recusado com indicação do vídeo de 10 s. |
| REQ-VID-TRIM-017 | O sistema deve marcar como falhado o vídeo que não pode ser descodificado e continuar com os restantes vídeos. | Deve ter | Refinado | NOVO | UC-VID-002/Exceção 6 | Um vídeo problemático não deve impedir os restantes. | Dado um projeto com um vídeo corrompido e um válido, quando aplica, então o corrompido fica "falhado" com mensagem e o válido gera resultado. |
| REQ-VID-TRIM-023 | O sistema deve processar um único excerto por operação. | Deve ter | Mantido | NOVO | UC-VID-002/A4, UC-VID-002/RN7, UC-VID-002/Q1 | Mantém o MVP simples. | Dado a ferramenta, então só é possível definir um par início/fim. |
| REQ-VID-TRIM-026 | O sistema deve apresentar a percentagem de progresso do corte de cada vídeo. | Deveria ter | Mantido | ALT | UC-VID-002/Passo 5, UC-VID-002/FA4, DQ-108 | Um corte pode demorar; o estado por si só não permite estimar o tempo restante. | Dado um processamento em curso, quando o utilizador consulta o estado, então vê uma percentagem entre 0 % e 100 % que não diminui. |
| REQ-VID-TRIM-027 | O sistema deve permitir cancelar o processamento em fila ou em curso, reutilizando o cancelamento existente. | Deve ter | Refinado | ALT | UC-VID-002/FA6, DQ-108 | Evita ocupar capacidade com pedidos desnecessários. | Dado um processamento em curso, quando o utilizador cancela, então o estado passa a "cancelado" e não fica nenhum resultado dessa execução. |
| REQ-VID-TRIM-028 | O sistema deve notificar o utilizador quando o processamento termina, com sucesso ou com falha. | Deveria ter | Mantido | ALT | UC-VID-002/Passo 7, UC-VID-002/FA4, DQ-108 | Com processamento em segundo plano, o utilizador precisa de saber quando voltar. | Dado um processamento em segundo plano, quando termina, então surge uma notificação com o resultado. |
| REQ-VID-TRIM-029 | O sistema deve apresentar, para cada vídeo cujo processamento falha, uma mensagem com a causa em linguagem corrente. | Deve ter | Refinado | ALT | UC-VID-002/Exceção 7, UC-VID-002/Pós-condição mínima, DQ-104 | O utilizador precisa de perceber se pode repetir ou se o vídeo tem um problema. | Dado uma falha injetada no corte de um vídeo, quando o utilizador consulta o estado, então vê "falhado" e a causa. |
| REQ-VID-TRIM-032 | O sistema deve manter os vídeos cortados copiados para um projeto até o utilizador os eliminar. | Deve ter | Refinado | NOVO | UC-VID-002/FA3, UC-VID-002/Q6, DQ-105 | Os vídeos copiados deixam de depender dos resultados, que são substituídos na execução seguinte. | Dado vídeos copiados há 30 dias, quando o utilizador abre o projeto, então continuam disponíveis. |
| REQ-VID-TRIM-033 | O sistema deve eliminar os ficheiros temporários do corte até 1 h (†) após o termo do processamento, com sucesso, falha ou cancelamento. | Deve ter | Mantido | NOVO | UC-VID-002/Pós-condição mínima, DQ-105 | Evita acumular dados fora do armazenamento de objetos. | Dado um processamento terminado, quando passa 1 h, então o worker não tem ficheiros temporários desse trabalho. |
| REQ-VID-TRIM-034 | O sistema deve impedir guardar a ferramenta quando o excerto tiver menos de 1 s (†). | Deveria ter | Refinado | NOVO | UC-VID-002/Exceção 2, UC-VID-002/RN5, DQ-112 | Evita ficheiros sem utilidade e dá um limite verificável (Q4). | Dado um excerto de 0,5 s, então guardar está bloqueado com mensagem; com 1 s é aceite. |
| REQ-VID-TRIM-045 | O sistema deve processar apenas os vídeos do projeto com esta ferramenta e informar o número de itens ignorados. | Deve ter | Novo | ALT | UC-VID-002/Passo 5, UC-VID-002/FA7, UC-VID-002/RN4, DQ-101 | A tabela de capacidades indica que a ferramenta aceita apenas vídeo. | Dado um projeto com 2 vídeos e 3 imagens, quando aplica, então são processados 2 itens e o utilizador é informado de 3 ignorados. |
| REQ-VID-TRIM-046 | O sistema deve recusar combinar a ferramenta "Cortar vídeo" com outras ferramentas na mesma pipeline. | Deve ter | Novo | ALT | UC-VID-002/Exceção 4, UC-VID-002/RN7, DQ-109 | A pipeline do MVP mantém cada ferramenta de vídeo isolada; o encadeamento fica para a Fase 2. | Dado um projeto com a ferramenta de brilho, quando tenta adicionar "Cortar vídeo", então é recusado com explicação; e vice-versa. |
| REQ-VID-TRIM-047 | O sistema deve recusar iniciar o processamento quando o projeto não contém vídeos, informando que nenhum item é compatível. | Deve ter | Novo | ALT | UC-VID-002/Exceção 5, DQ-101 | Evita trabalhos vazios. | Dado um projeto só com imagens e a ferramenta adicionada, quando aplica, então é recusado com mensagem. |
| REQ-VID-TRIM-048 | O sistema deve permitir copiar os vídeos cortados para um novo projeto, como vídeos normais. | Deve ter | Novo | ALT | UC-VID-002/Passo 8, UC-VID-002/FA3, DQ-115 | Caminho para continuar a editar os vídeos cortados com outras ferramentas e mantê-los independentemente dos resultados. | Dado 2 vídeos cortados, quando escolhe "Copiar para novo projeto", então é criado um projeto com 2 vídeos que se reproduzem e aceitam ferramentas de vídeo. |
| REQ-VID-TRIM-049 | O sistema deve disponibilizar a ferramenta aos perfis anónimo, registado e premium sem consumir operações da quota diária. | Deve ter | Novo | ALT | UC-VID-002/RN2, UC-VID-002/Q7, DQ-102 | É uma ferramenta básica, como o recorte de imagem. | Dado um registado com 0 operações disponíveis, quando aplica o corte, então o processamento inicia e as operações disponíveis continuam a 0; dado um anónimo, então consegue adicionar e aplicar a ferramenta. |
| REQ-VID-TRIM-050 | O sistema deve permitir adicionar e aplicar a ferramenta apenas ao dono do projeto e a utilizadores com permissão de edição. | Deve ter | Novo | ALT | UC-VID-002/RN8, UC-VID-002/Pré-condições, DQ-106 | Aplica as permissões de partilha existentes à nova ferramenta. | Dado um utilizador com partilha só de leitura, quando tenta adicionar a ferramenta, então recebe erro de permissão; consegue ver os resultados. |
| REQ-VID-TRIM-051 | O sistema deve identificar cada vídeo cortado com o nome do vídeo de origem e o intervalo cortado. | Deveria ter | Novo | NOVO | UC-VID-002/Passo 6 | Permite reconhecer a origem e o excerto de cada resultado. | Dado o corte 10–40 s de "aula.mp4", então o nome do resultado contém "aula" e "10-40s". |

### 4.1.2 Requisitos Não Funcionais e de Qualidade

As regras de negócio e restrições funcionais (instantes, excerto mínimo, combinação de ferramentas) estão na tabela 4.1.1. Aqui ficam apenas os requisitos de qualidade, classificados segundo a ISO/IEC 25010.

| **ID** | **Requisito** | **Característica ISO/IEC 25010** | **Alvo MVP** | **Alvo produção** | **Evolução** | **Origem (UC / DQ)** | **Critério de aceitação / verificação** |
|---|---|---|---|---|---|---|---|
| REQ-VID-TRIM-020 | O sistema deve remover o resultado parcial do vídeo cujo processamento falha, e de todos os vídeos quando é cancelado, mantendo os resultados dos vídeos concluídos. | Fiabilidade (Recuperabilidade) | Remoção dos parciais por vídeo, sem retoma | Uma repetição automática por vídeo e retoma a partir do último ponto de controlo | Refinado | UC-VID-002/Exceção 6, UC-VID-002/Exceção 7, UC-VID-002/FA6, UC-VID-002/RN6, DQ-104 | Dado 2 vídeos e uma falha forçada a meio do segundo, então o resultado do primeiro mantém-se e não há resultado do segundo. |
| REQ-VID-TRIM-021 | O sistema deve manter o vídeo original inalterado, gerando sempre um novo ficheiro. | Segurança (Integridade) | Obrigatório | Obrigatório | Mantido | UC-VID-002/RN1, UC-VID-002/Pós-condição de sucesso | Dado o hash do original antes e depois, então são idênticos. |
| REQ-VID-TRIM-022 | O sistema deve gerar um vídeo cuja duração difere da duração selecionada em no máximo 1 s (†). | Adequação Funcional (Correção funcional) | ≤ 1 s | ≤ 1 frame | Refinado | UC-VID-002/Pós-condição de sucesso, UC-VID-002/Q2, DQ-112 | Dado um excerto de 30 s, então o novo vídeo tem entre 29 s e 31 s. |
| REQ-VID-TRIM-024 | O sistema deve confirmar a receção do pedido em ≤ 2 s após "Aplicar", independentemente da duração dos vídeos. | Eficiência de Desempenho (Comportamento temporal) | ≤ 2 s | ≤ 1 s (†) | Refinado | UC-VID-002/Passo 4, UC-VID-002/FA4, DQ-110 | Dado vídeos de 15 s e 10 min, quando aplica, então a confirmação surge em ≤ 2 s. |
| REQ-VID-TRIM-036 | O sistema deve processar em simultâneo até 5 (†) cortes de vídeo, mantendo os restantes em fila. | Eficiência de Desempenho (Capacidade) | 5 réplicas do worker (†) | Réplicas ajustadas à carga, até 50 (†) | Refinado | UC-VID-002/A3, UC-VID-002/A7, DQ-107 | Dado 8 vídeos a cortar em simultâneo, então 5 ficam em curso, 3 em fila e os 8 terminam com sucesso. |
| REQ-VID-TRIM-037 | O sistema deve restringir o acesso aos vídeos e aos resultados às permissões do projeto (dono e partilhas). | Segurança (Confidencialidade) | Obrigatório | Obrigatório | Refinado | UC-VID-002/RN8, UC-VID-002/Pré-condições, DQ-106 | Dado um utilizador sem acesso ao projeto, quando pede um vídeo ou resultado, então recebe erro de autorização. |
| REQ-VID-TRIM-038 | O sistema deve disponibilizar vídeos e resultados para descarga apenas através de ligações assinadas, não adivinháveis e com expiração. | Segurança (Confidencialidade) | Ligações assinadas com expiração de 1 h (mecanismo existente) | Expiração ≤ 15 min (†) | Refinado | UC-VID-002/Passo 8, DQ-106 | Dado uma ligação de descarga, quando um carácter da assinatura é alterado ou a ligação expirou, então o armazenamento devolve erro. |
| REQ-VID-TRIM-039 | O sistema deve atualizar o estado e a percentagem de progresso apresentados com um intervalo máximo de 10 s (†). | Usabilidade (Operabilidade) | ≤ 10 s | ≤ 2 s | Mantido | UC-VID-002/Passo 5, UC-VID-002/FA4, DQ-108 | Dado um processamento de 5 min, quando se observa o ecrã durante 1 min, então o valor é atualizado pelo menos a cada 10 s. |
| REQ-VID-TRIM-041 | O sistema deve poder ser instalado e executado, incluindo o novo worker com `ffmpeg`, a partir de `docker compose up` num ambiente limpo. | Portabilidade (Instalabilidade) | Worker no `docker-compose.yaml`, com a versão do `ffmpeg` fixada | Instalação automatizada com uma só ação, com verificação de saúde do worker | Refinado | UC-VID-002/A7, DQ-111 | Dado uma máquina limpa, quando se executa `docker compose up`, então o teste de aceitação do corte passa. |
| REQ-VID-TRIM-042 | O sistema deve permitir acrescentar uma nova ferramenta de vídeo registando-a na tabela de capacidades e num novo worker, sem alterar o código das ferramentas de vídeo existentes. | Manutenibilidade (Modularidade) | Obrigatório (o corte é acrescentado sem alterar a extração de frames) | Obrigatório | Refinado | DQ-101, DQ-109 | Dado o corte acrescentado, então nenhum ficheiro do worker de extração de frames foi alterado. |
| REQ-VID-TRIM-043 | O sistema deve concluir o corte em tempo não superior a 0,5× a duração do excerto (†). | Eficiência de Desempenho (Comportamento temporal) | ≤ 0,5× a duração do excerto | ≤ 0,2× a duração do excerto | Mantido | UC-VID-002/A3, DQ-110 | Dado um excerto de 5 min, quando o processamento arranca sem outros trabalhos, então termina em ≤ 2,5 min. |
| REQ-VID-TRIM-044 | O sistema deve produzir o vídeo cortado no mesmo contentor do original, recodificado com o codec habitual desse contentor (MP4/MOV: H.264 e AAC; WebM: VP9 e Opus). | Compatibilidade (Interoperabilidade) | Mesmo contentor, codecs indicados | Mesmo contentor e mesmos codecs do original | Refinado | UC-VID-002/Passo 5, UC-VID-002/Q3, DQ-113 | Dado um MP4 e um WebM, quando cortados, então os ficheiros gerados são MP4 com H.264/AAC e WebM com VP9/Opus (verificado com `ffprobe`). |
| REQ-VID-TRIM-052 | O sistema deve cortar vídeos de todos os formatos aceites no carregamento (MP4, WebM e MOV), incluindo os codecs H.264, H.265 e VP9. | Compatibilidade (Interoperabilidade) | MP4, WebM, MOV (H.264, H.265, VP9) | Mais formatos aceites no carregamento (†) | Novo | UC-VID-002/A1, DQ-103 | Dado um vídeo de cada formato e codec, quando aplica, então todos geram resultado. |

> O alvo de produção é uma referência para a evolução futura (Fase 2), não um critério de aprovação do MVP.

### 4.1.3 Verificação da completude e dos limites do âmbito

| **Tópico a verificar** | **Aplicável?** | **Decisão / justificação** | **Requisito(s) relacionado(s)** |
|---|---|---|---|
| Formato, codec, duração e dimensão do vídeo | Parcial | A validação de formato, tamanho e duração por perfil é feita no carregamento (fora do âmbito, A1). Este caso de uso garante o corte dos formatos aceites, valida os instantes com a duração guardada no carregamento e trata vídeos corrompidos. | TRIM-014, TRIM-015, TRIM-017, TRIM-034, TRIM-052 |
| Estado, progresso, cancelamento e resultado | Sim | Reutiliza o processamento assíncrono, o cancelamento e as notificações existentes; acrescenta a percentagem de progresso e um resultado em vídeo, reproduzível nos resultados. | TRIM-007, TRIM-008, TRIM-011, TRIM-012, TRIM-013, TRIM-026, TRIM-027, TRIM-028, TRIM-039 |
| Falhas durante o processamento | Sim | Falha isolada por vídeo: remoção do resultado parcial desse vídeo e mensagem com a causa, sem retoma automática no MVP. | TRIM-017, TRIM-020, TRIM-029, TRIM-033 |
| Persistência e expiração dos ficheiros | Sim | Resultados seguem a regra existente (substituídos na execução seguinte); vídeos copiados mantêm-se até eliminação; temporários eliminados até 1 h; descarga por ligações assinadas. | TRIM-032, TRIM-033, TRIM-037, TRIM-038 |
| Perfis e contagem de operações | Sim | Ferramenta básica: disponível para anónimo, registado e premium, sem consumir operações. Os limites por perfil aplicam-se no carregamento. | TRIM-049 |
| Itens de tipos diferentes no mesmo projeto | Sim | A tabela de capacidades restringe a ferramenta a vídeos; as imagens são ignoradas e o utilizador é informado. | TRIM-045, TRIM-047 |
| Encadeamento de ferramentas e processamento em lote | Parcial | A ferramenta aplica-se a todos os vídeos do projeto com o mesmo intervalo (lote dentro do projeto). O encadeamento com outras ferramentas fica fora do MVP (RN7); os vídeos cortados podem ser editados com outras ferramentas depois de copiados para um novo projeto. | TRIM-023, TRIM-042, TRIM-046, TRIM-048 |
| Partilha do projeto | Sim | As permissões existentes (leitura/edição) aplicam-se à nova ferramenta e aos resultados. | TRIM-037, TRIM-050 |

**Evolução:** *Mantido* = requisito preservado; *Refinado* = clarificado, tornado verificável ou alinhado com o sistema existente, sem mudar a intenção; *Novo* = acrescentado nesta versão. **NOVO/ALT** indica o impacto face ao PictuRAS existente, não a novidade face ao Exercício 1.

### 4.1.4 Requisitos eliminados

| **ID** | **Motivo** | **Substituído por** |
|---|---|---|
| REQ-VID-TRIM-016 | A validação de formato e codec é feita no carregamento do vídeo, fora deste caso de uso. | Requisitos de carregamento de vídeo; TRIM-052 (formatos que o corte processa) |
| REQ-VID-TRIM-018 | O corte é uma ferramenta básica e não consome quota: não há quota esgotada a tratar. | TRIM-049 |
| REQ-VID-TRIM-019 | O corte não tem limite diário para nenhum perfil; a distinção para o premium deixa de se aplicar. | TRIM-049 |
| REQ-VID-TRIM-025 | O limite de tamanho é validado no carregamento, por perfil. | Requisitos de carregamento de vídeo (A6) |
| REQ-VID-TRIM-030 | O corte não consome quota. | TRIM-049 |
| REQ-VID-TRIM-031 | O perfil anónimo passa a ter acesso, como nas restantes ferramentas básicas. | TRIM-049 |
| REQ-VID-TRIM-035 | O limite de duração é validado no carregamento, por perfil. | Requisitos de carregamento de vídeo (A6) |
| REQ-VID-TRIM-040 | Os formatos de entrada são os aceites no carregamento. | TRIM-052 |

## 4.2 Impacto no sistema existente

| **Elemento existente afetado** | **Impacto (Manter / Estender / Alterar)** | **Descrição do impacto** | **Requisito(s) relacionado(s)** |
|---|---|---|---|
| Barra de ferramentas (`frontend/components/toolbar/toolbar.tsx`) | Alterar | Num vídeo aberto, passa a mostrar também a ferramenta "Cortar vídeo", com linha temporal, introdução manual de tempos e pré-visualização do excerto. | TRIM-001, TRIM-002, TRIM-003, TRIM-004, TRIM-009, TRIM-010 |
| Pipeline de ferramentas do projeto (`POST /:user/:project/tool`) | Alterar | Aceita a nova ferramenta, valida os instantes e recusa combiná-la com outras. | TRIM-001, TRIM-014, TRIM-034, TRIM-046, TRIM-050 |
| Tabela de capacidades (`projects/utils/toolCapabilities.js`) | Estender | Regista `trim` como ferramenta que aceita vídeo e como ferramenta exclusiva no MVP. | TRIM-042, TRIM-045, TRIM-046, TRIM-047 |
| Processamento (`POST /:user/:project/process`) | Alterar | Processa só os vídeos, valida o instante final face à duração de cada vídeo e informa os itens ignorados. | TRIM-005, TRIM-015, TRIM-045, TRIM-047 |
| Quota diária e ferramentas avançadas (`advanced_tools`, `users`) | Manter | O corte não entra nas ferramentas avançadas: não debita nem devolve operações. | TRIM-049 |
| Perfis de utilização (anónimo / registado / premium) | Manter | A regra atual para ferramentas básicas (todos os perfis) aplica-se ao corte. | TRIM-049 |
| Contrato de mensagens das ferramentas (`project_msg.js` ↔ `Tools/utils/tool_msg.py`) | Estender | Reutiliza o contrato já estendido no UC-VID-003 (progresso intermédio, erros com causa); regista a fila `trim_queue` e o tipo de saída `video` (um único ficheiro). | TRIM-026, TRIM-029 |
| Tratamento das respostas das ferramentas (`process_msg`) | Alterar | A saída de vídeo do corte termina a pipeline e cria um resultado do tipo vídeo; a falha de um vídeo não afeta os restantes. | TRIM-007, TRIM-017, TRIM-020 |
| Resultados do projeto (`models/result.js`, `GET /process/url`) e grelha de resultados | Estender | Resultados do tipo vídeo, reproduzidos com o leitor de vídeo nos resultados. | TRIM-007, TRIM-008, TRIM-051 |
| Workers de ferramentas (`Tools/`) | Estender | Novo worker `trim` com `ffmpeg` e fila RabbitMQ própria. | TRIM-006, TRIM-036, TRIM-043, TRIM-044, TRIM-052 |
| Cópia de resultados para novo projeto (`POST /:user/:project/results/project`) | Alterar | Hoje copia só imagens; passa a copiar vídeos, marcando-os como vídeos e guardando a respetiva duração. | TRIM-032, TRIM-048 |
| Cancelamento (`DELETE /:user/:project/process`) | Manter | Reutilizado sem alterações: token e remoção dos resultados da execução. | TRIM-020, TRIM-027 |
| Notificações (`wsGateway`) | Manter | Reutiliza os eventos de progresso e de falha por item introduzidos no UC-VID-003. | TRIM-012, TRIM-026, TRIM-028, TRIM-039 |
| Partilha e permissões (`checkSharePermission`, `requireEditPermission`) | Manter | Aplicadas à nova ferramenta e aos resultados. | TRIM-037, TRIM-050 |
| Ligações de descarga (`getPresignedUrl.js`) | Manter | Já assinadas e com expiração de 1 h. | TRIM-038 |
| Instalação (`docker-compose.yaml`, `rabbitMQ/definitions.json`) | Estender | Novo serviço para o worker de corte e nova fila. | TRIM-041 |
| Slider do frontend (`components/ui/slider.tsx`) | Estender | Passa a desenhar um marcador por valor, para a linha temporal com início e fim; os sliders existentes (um valor) não mudam. | TRIM-002, TRIM-003 |
| Botão de ferramenta do frontend (`toolbar-button.tsx`) | Estender | Opções `invalid` (bloqueia "Save" com instantes inválidos) e `noPreview` (o corte pré-visualiza-se no leitor da ferramenta, não no servidor). | TRIM-009, TRIM-014, TRIM-034, TRIM-046 |

## 4.3 Matriz de Rastreabilidade Atualizada

| **Elemento de origem** | **Descrição abreviada** | **Requisito(s) relacionado(s)** |
|---|---|---|
| UC-VID-002/Passo 1 | Abrir projeto e vídeo | TRIM-001 |
| UC-VID-002/Passo 2 | Escolher ferramenta, linha temporal | TRIM-001, TRIM-002 |
| UC-VID-002/Passo 3 | Definir instantes, duração do excerto | TRIM-003, TRIM-004 |
| UC-VID-002/Passo 4 | Aplicar e validar | TRIM-005, TRIM-024 |
| UC-VID-002/Passo 5 | Gerar vídeos cortados com progresso | TRIM-006, TRIM-026, TRIM-039, TRIM-043, TRIM-044, TRIM-045 |
| UC-VID-002/Passo 6 | Guardar como resultados | TRIM-007, TRIM-051 |
| UC-VID-002/Passo 7 | Notificar fim | TRIM-028 |
| UC-VID-002/Passo 8 | Reproduzir e descarregar | TRIM-008, TRIM-038, TRIM-048 |
| UC-VID-002/FA1 | Pré-visualização do excerto | TRIM-009 |
| UC-VID-002/FA2 | Tempos manuais | TRIM-010 |
| UC-VID-002/FA3 | Copiar para novo projeto | TRIM-032, TRIM-048 |
| UC-VID-002/FA4 | Segundo plano | TRIM-011, TRIM-012, TRIM-024, TRIM-026, TRIM-028, TRIM-039 |
| UC-VID-002/FA5 | Desistir antes de aplicar | TRIM-013 |
| UC-VID-002/FA6 | Cancelar processamento | TRIM-020, TRIM-027 |
| UC-VID-002/FA7 | Projeto com imagens e vídeos | TRIM-045 |
| UC-VID-002/Exceção 1 | Início ≥ fim | TRIM-014 |
| UC-VID-002/Exceção 2 | Excerto < 1 s | TRIM-034 |
| UC-VID-002/Exceção 3 | Fim além da duração | TRIM-015 |
| UC-VID-002/Exceção 4 | Combinação com outras ferramentas | TRIM-046 |
| UC-VID-002/Exceção 5 | Projeto sem vídeos | TRIM-047 |
| UC-VID-002/Exceção 6 | Vídeo corrompido | TRIM-017, TRIM-020 |
| UC-VID-002/Exceção 7 | Falha no processamento | TRIM-020, TRIM-021, TRIM-029 |
| UC-VID-002/Pós-condição de sucesso | Vídeos cortados, originais intactos | TRIM-007, TRIM-021, TRIM-022 |
| UC-VID-002/Pós-condição mínima | Sem vídeo incompleto | TRIM-020, TRIM-029, TRIM-033 |
| UC-VID-002/Pré-condições | Permissão e vídeo validado | TRIM-037, TRIM-050 |
| UC-VID-002/RN1 | Novo ficheiro | TRIM-021 |
| UC-VID-002/RN2 | Ferramenta básica, todos os perfis | TRIM-049 |
| UC-VID-002/RN3 | Limites do carregamento por perfil | TRIM-052 |
| UC-VID-002/RN4 | Só vídeos | TRIM-045 |
| UC-VID-002/RN5 | Instantes válidos, excerto ≥ 1 s | TRIM-014, TRIM-015, TRIM-034 |
| UC-VID-002/RN6 | Sem resultados incompletos | TRIM-020 |
| UC-VID-002/RN7 | Um excerto, sem combinação | TRIM-023, TRIM-046 |
| UC-VID-002/RN8 | Permissões do projeto | TRIM-037, TRIM-050 |
| UC-VID-002/RN9 | Mesmo intervalo para todos | TRIM-015 |
| UC-VID-002/A1 | Carregamento validado fora do UC | TRIM-052 |
| UC-VID-002/A2 | Duração guardada no carregamento | TRIM-002 |
| UC-VID-002/A3 | Estados intermédios | TRIM-012, TRIM-036, TRIM-043 |
| UC-VID-002/A4 | Um excerto por operação | TRIM-023 |
| UC-VID-002/A7 | Worker com ffmpeg | TRIM-036, TRIM-041 |
| UC-VID-002/Q1 | Vários excertos | TRIM-023 |
| UC-VID-002/Q2 | Precisão | TRIM-022 |
| UC-VID-002/Q3 | Contentor e codecs | TRIM-044 |
| UC-VID-002/Q6 | Persistência | TRIM-032 |
| UC-VID-002/Q7 | Quota | TRIM-049 |
| DQ-101 | Corte como ferramenta de vídeo da pipeline | TRIM-001, TRIM-007, TRIM-042, TRIM-045, TRIM-047 |
| DQ-102 | Ferramenta básica, sem quota | TRIM-049 |
| DQ-103 | Validação no carregamento | TRIM-052 |
| DQ-104 | Falha isolada por vídeo, sem retoma | TRIM-020, TRIM-029 |
| DQ-105 | Persistência e temporários | TRIM-032, TRIM-033 |
| DQ-106 | Permissões do projeto e ligações assinadas | TRIM-037, TRIM-038, TRIM-050 |
| DQ-107 | Réplicas do worker e fila | TRIM-036 |
| DQ-108 | Estado, progresso, cancelamento e notificação | TRIM-012, TRIM-026, TRIM-027, TRIM-028, TRIM-039 |
| DQ-109 | Sem combinação; modularidade | TRIM-042, TRIM-046 |
| DQ-110 | Alvos de desempenho | TRIM-024, TRIM-043 |
| DQ-111 | Instalação com docker compose | TRIM-041 |
| DQ-112 | Excerto mínimo e precisão | TRIM-022, TRIM-034 |
| DQ-113 | Contentor mantido, recodificação | TRIM-044 |
| DQ-114 | Mesmo intervalo para todos os vídeos | TRIM-015 |
| DQ-115 | Cópia para novo projeto | TRIM-048 |

**Decisões de qualidade (v1.2)**

| **ID** | **Decisão de qualidade** | **Justificação** | **Requisito(s) relacionado(s)** |
|---|---|---|---|
| DQ-101 | O corte é uma ferramenta de vídeo da pipeline (`trim`, aceita vídeo e produz vídeo), executada por um worker em `Tools/` via RabbitMQ, como as restantes ferramentas. | Reutiliza fila, estados, cancelamento, partilha e descarga, e segue a mesma arquitetura da extração de frames (UC-VID-003). | TRIM-001, TRIM-007, TRIM-042, TRIM-045, TRIM-047 |
| DQ-102 | "Cortar vídeo" é uma ferramenta básica: não consome operações e está disponível para anónimo, registado e premium. | É o equivalente em vídeo do recorte de imagem, que já é básico; os limites por perfil já se aplicam no carregamento. | TRIM-049 |
| DQ-103 | Os formatos, o tamanho e a duração dos vídeos são validados no carregamento, por perfil; o corte processa todos os formatos aí aceites. | Evita validar duas vezes e mantém uma só lista de formatos e limites. | TRIM-052 |
| DQ-104 | A falha é isolada por vídeo: o resultado parcial desse vídeo é removido e os restantes continuam; no MVP não há retoma automática. | Um vídeo problemático não deve anular o trabalho dos restantes. | TRIM-020, TRIM-029 |
| DQ-105 | Os resultados seguem a regra existente; os vídeos copiados para um projeto mantêm-se até eliminação; os temporários são eliminados até 1 h após o termo (†). | Evita perda de trabalho e retenção desnecessária de dados. | TRIM-032, TRIM-033 |
| DQ-106 | O acesso segue as permissões do projeto (dono e partilhas) e a descarga usa as ligações assinadas existentes. | Reutiliza o modelo de segurança atual sem exceções para vídeo. | TRIM-037, TRIM-038, TRIM-050 |
| DQ-107 | O MVP corre 5 réplicas (†) do worker de corte; os restantes vídeos ficam em fila no RabbitMQ. | Limita o consumo de CPU e mantém a aplicação responsiva. | TRIM-036 |
| DQ-108 | Estado, cancelamento e notificação reutilizam os mecanismos existentes; a percentagem de progresso é atualizada no máximo a cada 10 s no MVP (†). | Operações que duram minutos exigem feedback ao utilizador. | TRIM-012, TRIM-026, TRIM-027, TRIM-028, TRIM-039 |
| DQ-109 | No MVP o corte não se combina com outras ferramentas; novas ferramentas de vídeo acrescentam-se pela tabela de capacidades sem alterar as existentes. | Cada ferramenta de vídeo fica isolada na pipeline; o encadeamento fica para a Fase 2. | TRIM-042, TRIM-046 |
| DQ-110 | Alvos de desempenho: confirmação do pedido em ≤ 2 s e corte em ≤ 0,5× a duração do excerto (†). | Distingue o tempo de resposta do pedido do tempo de processamento. | TRIM-024, TRIM-043 |
| DQ-111 | O worker de corte é um serviço do `docker-compose.yaml`, com o `ffmpeg` instalado na imagem e versão fixada. | Mantém a instalação reprodutível com binários externos. | TRIM-041 |
| DQ-112 | Excerto mínimo de 1 s e precisão de corte de ±1 s no MVP (†). | Responde a Q2 e Q4 com valores verificáveis. | TRIM-022, TRIM-034 |
| DQ-113 | O vídeo cortado mantém o contentor do original e é recodificado (MP4/MOV: H.264 e AAC; WebM: VP9 e Opus). | A cópia direta dos fluxos só corta em keyframes, que podem distar vários segundos, e não cumpriria a precisão de ±1 s. | TRIM-044 |
| DQ-114 | O mesmo intervalo de corte aplica-se a todos os vídeos do projeto; se não couber em algum, o processamento não inicia. | As ferramentas da pipeline aplicam os mesmos parâmetros a todos os itens. | TRIM-015 |
| DQ-115 | Os vídeos cortados ficam nos resultados do projeto; para os editar com outras ferramentas, copiam-se para um novo projeto como vídeos. | Permite continuar a editar sem encadeamento na pipeline. | TRIM-048 |

**Correspondência com a numeração da v1.1** (as DQ foram renumeradas para não colidirem com as do UC-VID-003): DQ-001 e DQ-002 → DQ-103; DQ-003 e DQ-010 → DQ-102; DQ-004 → DQ-104; DQ-005 → DQ-105; DQ-006 → DQ-106; DQ-007 → DQ-107; DQ-008 → DQ-108; DQ-009 → DQ-109; DQ-011 → DQ-110; DQ-012 → DQ-111; DQ-013 → DQ-112; DQ-014 → DQ-113.

**Verificações de cobertura**
- [x] Cada requisito funcional e não funcional aparece na matriz.
- [x] Cada requisito tem origem identificada: elemento do caso de uso, regra de negócio ou decisão de qualidade.
- [x] Todos os elementos relevantes do caso de uso (passos, fluxos alternativos, exceções, regras de negócio e pós-condições) têm requisito associado.
- [x] Os tópicos parciais na secção 4.1.3 estão justificados e os requisitos eliminados estão registados em 4.1.4.
- [x] O impacto no sistema existente está ligado aos elementos de código afetados e aos requisitos relevantes.

## 4.4 Realização e verificação

> Corresponde ao Cap. 7.3 do relatório: para cada requisito, componente(s) que o realizam, estado de implementação, teste(s) e resultado. Estado à data de 2026-10-18 (branch `feat/trim`).

**Componentes**

| **ID** | **Componente** | **Ficheiro(s)** |
|---|---|---|
| W-TRIM | Worker de corte | `Tools/trim/` (`trim.py`, `trim_rules.py`, `Dockerfile`) |
| P-ROUTES | Rotas e orquestração do `projects` | `projects/routes/projects.js` (`/tool`, `/process`, `/preview`, `/process/url`, `/results/project`, `process_msg`) |
| P-RULES | Regras de vídeo do `projects` | `projects/utils/toolCapabilities.js`, `projects/utils/trim.js` |
| MSG | Contrato de mensagens | `Tools/utils/tool_msg.py`, `projects/utils/project_msg.js` |
| WS | Notificações | `wsGateway/index.js` (eventos do UC-VID-003) |
| FE-TOOL | Ferramenta no frontend | `frontend/components/toolbar/trim-tool.tsx`, `toolbar.tsx`, `toolbar-button.tsx`, `components/ui/slider.tsx`, `lib/trim.ts` |
| FE-PAGE | Página do projeto e resultados | `frontend/app/dashboard/[pid]/page.tsx`, `lib/projects.ts` |
| INFRA | Instalação | `docker-compose.yaml`, `rabbitMQ/definitions.json` |

**Testes**

| **ID** | **Tipo** | **Descrição (Dado … Quando … Então …)** | **Requisitos** | **Resultado** |
|---|---|---|---|---|
| TST-TRIM-01 a 06 | Unitário (`node:test`) | Intervalo válido, início ≥ fim, excerto < 1 s, parâmetros em falta, fim além da duração, capacidades e exclusividade (`projects/test/trim.test.js`) | TRIM-003, 014, 015, 034, 045, 046 | ✅ 6/6 |
| TST-TRIM-PY | Unitário (`unittest`) | Validação, nome do resultado, codecs por contentor e argumentos do `ffmpeg` (`Tools/trim/test_trim_rules.py`) | TRIM-015, 034, 044, 051 | ✅ 8/8 |
| TST-TRIM-07 | Ponta a ponta | Dado início ≥ fim ou excerto de 0,5 s, quando se adiciona a ferramenta, então é recusado | TRIM-014, 034 | ✅ |
| TST-TRIM-08 | Ponta a ponta | Dado o corte na pipeline, quando se adiciona brilho, então é recusado | TRIM-046 | ✅ |
| TST-TRIM-09 | Ponta a ponta | Dado 2 vídeos e 1 imagem, quando se aplica o corte 1–2,5 s, então há 2 vídeos cortados do tipo vídeo, 1 item ignorado, nomes com o intervalo e a quota não muda | TRIM-001, 005, 006, 007, 008, 023, 045, 049, 051 | ✅ |
| TST-TRIM-10 | Ponta a ponta | Dado o fim em 5 s e um vídeo de 3 s, quando se aplica, então é recusado e o vídeo afetado é indicado | TRIM-015 | ✅ |
| TST-TRIM-11 | Ponta a ponta | Dado o corte na pipeline, quando se pede a pré-visualização ao servidor, então é recusada (o excerto vê-se no leitor) | TRIM-009 | ✅ |
| TST-TRIM-12 | Ponta a ponta | Dado 2 vídeos cortados, quando se copiam para um novo projeto, então há 2 vídeos com duração guardada que aceitam outra ferramenta de vídeo | TRIM-032, 048 | ✅ |
| TST-TRIM-13 | Ponta a ponta | Dado um utilizador anónimo, quando corta um vídeo, então obtém o resultado | TRIM-049 | ✅ |
| TST-TRIM-14 | Inspeção (`ffprobe`) | Dado o corte 1–2,5 s de um MP4 e 2–5 s de um WebM, então duram 1,500 s e 3,000 s, com H.264/AAC e VP9 | TRIM-022, 044 | ✅ |
| TST-TRIM-15 | Ponta a ponta | Dado um projeto só com imagens, quando se aplica o corte, então é recusado | TRIM-047 | ✅ |
| TST-TRIM-16 | Inspeção | Dado um corte em curso, quando se observam os logs do `ws_gateway`, então chega o progresso (3 % → 100 %, ~1 s) | TRIM-026, 039 | ✅ |
| TST-TRIM-M1 | Manual (equipa, navegador) | Corte de um vídeo com a ferramenta "Trim video" (linha temporal) e processamento concluído | TRIM-001, 002, 003 | ✅ |

Os testes ponta a ponta correm com `bash projects/test/e2e/run.sh` (stack a correr); os unitários com `npm test` em `projects/` e `python3 -m unittest` em `Tools/trim/`.

**Realização por requisito**

| **Requisito** | **Componente(s)** | **Estado** | **Teste(s)** | **Resultado / observação** |
|---|---|---|---|---|
| TRIM-001 | FE-TOOL, P-ROUTES | Implementado | TST-TRIM-09, M1 | ✅ |
| TRIM-002 | FE-TOOL | Implementado | M1 | ✅ |
| TRIM-003 | FE-TOOL, P-RULES | Implementado | TST-TRIM-01, M1 | ✅ |
| TRIM-004 | FE-TOOL | Implementado | — | Por testar no navegador |
| TRIM-005 | P-ROUTES, FE-PAGE | Implementado | TST-TRIM-09 | ✅ |
| TRIM-006 | W-TRIM | Implementado | TST-TRIM-09, 14 | ✅ |
| TRIM-007 | P-ROUTES, MSG | Implementado | TST-TRIM-09 | ✅ |
| TRIM-008 | P-ROUTES (`/process/url`), FE-PAGE | Implementado | TST-TRIM-09, 14 | ✅ Resultado do tipo vídeo e descarregável; reprodução no navegador por confirmar |
| TRIM-009 | FE-TOOL | Implementado | TST-TRIM-11 | Recusa no servidor verificada; leitor da ferramenta por testar no navegador |
| TRIM-010 | FE-TOOL (`lib/trim.ts`) | Implementado | — | Por testar (sem teste unitário de `parseTime`) |
| TRIM-011 | P-ROUTES | Implementado (mecanismo existente) | TST-TRIM-09 | ✅ O processamento não depende da página (os testes ponta a ponta correm sem navegador) |
| TRIM-012 | P-ROUTES, FE-PAGE | Parcial | — | O estado só é visível enquanto a página está aberta |
| TRIM-013 | FE-TOOL | Implementado | — | Por testar no navegador |
| TRIM-014 | P-RULES, FE-TOOL | Implementado | TST-TRIM-02, 07 | ✅ |
| TRIM-015 | P-RULES, W-TRIM | Implementado | TST-TRIM-05, 10 | ✅ |
| TRIM-017 | W-TRIM, P-ROUTES | Implementado | — | Mecanismo de falha por vídeo partilhado com a extração (TST-FRAME-17); sem teste próprio do corte |
| TRIM-023 | FE-TOOL, P-RULES | Implementado | TST-TRIM-09 | ✅ |
| TRIM-026 | W-TRIM, WS, FE-PAGE | Implementado | TST-TRIM-16 | ✅ |
| TRIM-027 | P-ROUTES (cancelamento existente) | Implementado | — | Por testar automaticamente |
| TRIM-028 | FE-PAGE | Parcial | — | Só há aviso de fim com a página aberta |
| TRIM-029 | W-TRIM, MSG, FE-PAGE | Implementado | — | Por testar com falha injetada |
| TRIM-032 | P-ROUTES (`/results/project`) | Implementado | TST-TRIM-12 | ✅ Persistência ao longo do tempo não testada |
| TRIM-033 | W-TRIM, P-ROUTES | Parcial | — | Vídeo cortado e parciais apagados de imediato; a cópia local do vídeo de origem só é apagada no "Aplicar" seguinte |
| TRIM-034 | P-RULES, FE-TOOL | Implementado | TST-TRIM-03, 07 | ✅ |
| TRIM-045 | P-RULES, P-ROUTES | Implementado | TST-TRIM-06, 09 | ✅ |
| TRIM-046 | P-RULES, P-ROUTES, FE-TOOL | Implementado | TST-TRIM-06, 08 | ✅ |
| TRIM-047 | P-RULES, P-ROUTES | Implementado | TST-TRIM-15 | ✅ |
| TRIM-048 | P-ROUTES (`/results/project`) | Implementado | TST-TRIM-12 | ✅ |
| TRIM-049 | P-RULES, P-ROUTES | Implementado | TST-TRIM-09, 13 | ✅ |
| TRIM-050 | P-ROUTES (permissões existentes) | Implementado (mecanismo existente) | — | Por testar com partilha só de leitura |
| TRIM-051 | W-TRIM | Implementado | TST-TRIM-09, PY | ✅ |
| TRIM-020 | W-TRIM, P-ROUTES | Implementado | — | Por testar com falha injetada no corte |
| TRIM-021 | W-TRIM | Implementado | Inspeção de código | O worker só lê o vídeo original |
| TRIM-022 | W-TRIM | Implementado | TST-TRIM-14 | ✅ Duração exata (1,500 s) |
| TRIM-024 | P-ROUTES | Parcial | — | O `projects` descarrega os vídeos antes de responder: com vídeos grandes a confirmação passa de 2 s |
| TRIM-036 | INFRA | Implementado | Inspeção | ✅ 5 consumidores na `trim_queue`; sem teste de carga |
| TRIM-037 | P-ROUTES (permissões existentes) | Implementado (mecanismo existente) | — | Por testar |
| TRIM-038 | Armazenamento (ligações assinadas existentes) | Implementado (mecanismo existente) | Inspeção | Expiração de 1 h |
| TRIM-039 | W-TRIM, WS | Implementado | TST-TRIM-16 | ✅ |
| TRIM-041 | INFRA | Implementado | Inspeção | ✅ Construído e executado com `docker compose up --build` |
| TRIM-042 | P-RULES, INFRA | Implementado | Inspeção | ✅ Acrescentado sem alterar `Tools/extract_frames/` |
| TRIM-043 | W-TRIM | Implementado | — | Tempo não medido |
| TRIM-044 | W-TRIM | Implementado | TST-TRIM-14, PY | ✅ |
| TRIM-052 | W-TRIM | Implementado | TST-TRIM-09, 14 | ✅ MP4 e WebM; MOV e H.265 por testar |

**Limitações conhecidas:** os requisitos parciais (TRIM-012, 024, 028, 033), os tempos não medidos (TRIM-043) e os testes por fazer ficam como trabalho para a Fase 2. O `ws_gateway` não volta a ligar-se ao RabbitMQ se este reiniciar (comportamento herdado do código base); nesse caso o ecrã fica em "Processing" até se reiniciar o serviço.
