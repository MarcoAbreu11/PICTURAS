# Exercício 1 — Casos de Uso
## Fase 1: Suporte a Vídeo no PictuRAS

## 0. Identificação

| Campo | Valor |
|---|---|
| Grupo / Equipa | [preencher] |
| Autores | Diogo Linhares Campos - PG63948<br>Marco António Ferreira Abreu - PG64003<br>Cláudio Rafael Oliveira Ferreira - PG63933<br>Nelson Daniel Araújo Sousa - PG64010 |
| Data | 2026-10-17 |
| Versão do documento | v1.1 |
| Unidade Curricular | Requisitos e Arquiteturas de Software — MEI, Universidade do Minho |

---

## 1. Funcionalidade de vídeo escolhida

| Campo | Valor |
|---|---|
| Funcionalidade | Converter o formato de um vídeo e/ou comprimi-lo reduzindo resolução ou qualidade |
| Perfil(s) de utilizador abrangido(s) | Utilizador registado e premium |

### Justificação no contexto do MVP

A conversão e compressão de vídeo resolve problemas comuns de compatibilidade e tamanho de ficheiros, facilitando a partilha. Esta funcionalidade permite validar a recodificação de vídeo e a diferenciação de funcionalidades entre perfis de utilizador, reforçando o modelo de negócio existente.

---

# 2. Caso de Uso

## 2.1 Cabeçalho

| Secção | Detalhes |
|---|---|
| ID do Caso de Uso | UC-VID-005 |
| Nome | Converter ou comprimir vídeo |
| Versão | v1.1 |
| Autor | Diogo Linhares Campos<br>Marco António Ferreira Abreu<br>Cláudio Rafael Oliveira Ferreira<br>Nelson Daniel Araújo Sousa |
| Data | 2026-10-17 |
| Objetivo | Permitir ao utilizador obter uma nova versão do vídeo noutro formato e/ou com menor tamanho. |
| Âmbito | Módulo de vídeo do PictuRAS |
| Ator Principal | Utilizador registado ou premium |
| Stakeholders e Interesses | Utilizador: pretende reproduzir ou partilhar o vídeo em qualquer plataforma e reduzir o tamanho do ficheiro.<br>Proprietário do sistema: pretende diferenciar os perfis através da qualidade máxima de saída.<br>Equipa de desenvolvimento: pretende validar a recodificação de vídeo. |
| Pré-condições | O utilizador tem sessão iniciada; possui um vídeo submetido; o vídeo está num formato suportado; o utilizador tem quota disponível. |
| Trigger | O utilizador seleciona um vídeo e escolhe "Converter / Comprimir". |

## 2.2 Fluxo Principal

| Passo | Ação do Ator | Resposta do Sistema |
|---|---|---|
| 1 | O utilizador abre a biblioteca de vídeos. | O sistema apresenta os vídeos disponíveis. |
| 2 | O utilizador seleciona um vídeo e escolhe converter ou comprimir. | O sistema apresenta as opções de formato de saída, resolução e qualidade disponíveis para o seu perfil. |
| 3 | O utilizador escolhe as opções pretendidas. | O sistema mostra uma estimativa do tamanho do ficheiro final. |
| 4 | O utilizador confirma a operação. | O sistema valida os dados e inicia o processamento. |
| 5 | — | O sistema recodifica o vídeo com as opções escolhidas. |
| 6 | — | O sistema guarda o novo vídeo na biblioteca do utilizador. |
| 7 | O utilizador consulta o resultado. | O sistema disponibiliza o novo vídeo e indica o tamanho original e o tamanho final. |

## 2.3 Fluxos Alternativos

| Fluxo | Descrição |
|---|---|
| FA1 — Apenas conversão | O utilizador altera só o formato (ex.: MOV para MP4), mantendo resolução e qualidade. |
| FA2 — Apenas compressão | O utilizador mantém o formato e reduz apenas a resolução ou a qualidade. |
| FA3 — Perfis predefinidos | O utilizador escolhe um perfil pronto (ex.: "Partilha web", "Mensagens"). |
| FA4 — Processamento em segundo plano | O utilizador abandona a página e o processamento continua. |

## 2.4 Exceções

| Condição | Comportamento do Sistema |
|---|---|
| Resolução superior à permitida pelo perfil | O sistema não permite a opção e sugere o upgrade para premium. |
| Formato ou codec não suportado | O sistema rejeita o vídeo. |
| O vídeo está corrompido | O sistema termina a operação e apresenta erro. |
| O ficheiro final seria maior que o original | O sistema avisa o utilizador e pede confirmação. |
| Quota do utilizador registado esgotada | A operação não é iniciada. |
| O processamento falha | O sistema remove resultados parciais e mantém o vídeo original inalterado. |

## 2.5 Pós-condições

| Tipo | Resultado |
|---|---|
| Garantia de Sucesso | Existe um novo vídeo na biblioteca no formato e qualidade escolhidos e o vídeo original permanece inalterado. |
| Garantia Mínima | Em caso de falha, não fica nenhum vídeo incompleto na biblioteca e o utilizador é informado. |

## 2.6 Regras de Negócio e Restrições

| ID | Regra |
|---|---|
| RN1 | A conversão não altera o vídeo original; é sempre gerado um novo ficheiro. |
| RN2 | Utilizadores registados estão sujeitos às quotas existentes. |
| RN3 | Utilizadores premium não possuem limite diário de operações. |
| RN4 | Apenas formatos suportados podem ser processados. |
| RN5 | Utilizadores registados estão limitados a uma resolução máxima de saída (ex.: 720p). |
| RN6 | O vídeo gerado mantém a duração e o áudio do vídeo original. |

## 2.7 Assunções

| ID | Assunção |
|---|---|
| A1 | O vídeo já está armazenado na biblioteca do utilizador. |
| A2 | O sistema consegue recodificar vídeos suportados (ex.: através de FFmpeg). |
| A3 | A recodificação pode demorar e necessita de estados intermédios. |
| A4 | Para o MVP, a estimativa de tamanho final é aproximada. |
| A5 | A biblioteca do utilizador já permite eliminar ficheiros; a eliminação dos resultados segue esse mecanismo (DQ-005). |
| A6 | Os limites de duração (10 min) e de tamanho (500 MB) e os formatos de entrada (MP4 e MOV) são valores propostos para o MVP, a confirmar (DQ-001, DQ-002). |
| A7 | O mecanismo de autenticação existente identifica o proprietário de cada ficheiro e pode ser reutilizado para controlar o acesso a vídeos e resultados (DQ-006). |
| A8 | A infraestrutura do MVP suporta 5 trabalhos de vídeo em simultâneo; os restantes aguardam em fila (DQ-007). |
| A9 | No MVP uma falha não é retomada automaticamente: o utilizador repete o pedido; a retoma automática é alvo de produção (DQ-004). |
| A10 | MP4 e WebM cobrem a compatibilidade necessária no MVP e o PictuRAS preserva sempre o vídeo original (DQ-013, DQ-015). |

## 2.8 Questões em Aberto

| ID | Questão |
|---|---|
| Q1 | Que formatos de saída devem ser suportados no MVP? — **Proposta v1.1:** MP4 e WebM (†) (CONV-046); a confirmar. |
| Q2 | Qual a resolução máxima para utilizadores registados? — **Proposta v1.1:** 720p para registados e 1080p para premium (†) (CONV-022, CONV-035); a confirmar. |
| Q3 | Deve ser possível substituir o vídeo original pelo convertido? — **Proposta v1.1:** não; o original é sempre preservado (CONV-036). |
| Q4 | Devem existir perfis predefinidos de compressão? — **Proposta v1.1:** sim, como funcionalidade “Poderia ter” (CONV-011). |
| Q5 | Qual a duração máxima de vídeo suportada? — **Proposta v1.1:** 10 min (†) (CONV-037); a confirmar. |
| Q6 | Os resultados na biblioteca devem expirar ao fim de algum tempo, em vez de se manterem até serem eliminados? (DQ-005) |
| Q7 | Os pedidos em fila ou em curso devem contar para a verificação da quota antes de concluírem? (DQ-003) |

---

# 3. Utilização de agentes de IA

| Ferramenta / skill | Tarefa apoiada | Validação realizada pela equipa |
|---|---|---|
| Claude | Apoio na definição do caso de uso, fluxos, exceções, regras de negócio, assunções e questões em aberto. | Revisão manual pela equipa comparando com o enunciado, template e exemplos fornecidos pelos docentes. |
| Claude | Elaboração da ERS do Exercício 2 (secção 4): classificação segundo a ISO/IEC 25010, proposta de valores (†) e decisões de qualidade, catálogo de requisitos, impacto e matriz de rastreabilidade. | [preencher: revisão da equipa] |

---

# 4. Especificação de Requisitos do Sistema (ERS)

**Caso de Uso:** UC-VID-005 — Converter ou comprimir vídeo  
**Versão do dossiê:** v1.1  
**Baseline do Exercício 1:** v1.0 — REQ-VID-CONV-001 a REQ-VID-CONV-025

> O catálogo 4.1 é a fonte única dos requisitos desta ERS. A matriz 4.3 rastreia esses IDs até ao caso de uso ou às decisões de qualidade (DQ). A tabela 4.2 descreve o impacto no sistema existente. Nas tabelas 4.2 e 4.3 os IDs aparecem abreviados (por exemplo, CONV-007 = REQ-VID-CONV-007). Valores marcados com (†) são propostas da equipa, a confirmar; quando um valor for confirmado, passa a assunção ou regra de negócio do caso de uso.

## 4.1 Requisitos da ERS

### 4.1.1 Requisitos Funcionais

| **ID** | **Requisito** | **Prioridade** | **Evolução** | **Novo/Alt** | **Origem (UC / RN / decisão)** | **Justificação** | **Critério de aceitação / verificação** |
|---|---|---|---|---|---|---|---|
| REQ-VID-CONV-001 | O sistema deve permitir ao utilizador registado ou premium selecionar um vídeo da sua biblioteca e pedir a sua conversão ou compressão. | Deve ter | Mantido | NOVO | Trigger, Passos 1–2 | Ponto de entrada da funcionalidade. | Dado um vídeo na biblioteca, quando escolhe "Converter / Comprimir", então abre o ecrã de opções. |
| REQ-VID-CONV-002 | O sistema deve apresentar apenas as opções de formato de saída, resolução e qualidade disponíveis para o perfil do utilizador. | Deve ter | Mantido | ALT | Passo 2, RN5 | Aplica a diferenciação de perfis (RN5). | Dado um registado, então não surgem resoluções acima do seu limite; dado um premium, surgem todas. |
| REQ-VID-CONV-003 | O sistema deve mostrar uma estimativa do tamanho do ficheiro final após o utilizador escolher as opções. | Deve ter | Mantido | NOVO | Passo 3, A4 | Permite decidir com base no tamanho final. | Dado opções escolhidas, então é apresentada uma estimativa em MB. |
| REQ-VID-CONV-004 | O sistema deve iniciar o processamento apenas após confirmação do utilizador e validação dos dados. | Deve ter | Mantido | NOVO | Passo 4 | Evita processamentos demorados e consumo de quota por engano. | Dado dados válidos, quando confirma, então inicia. |
| REQ-VID-CONV-005 | O sistema deve recodificar o vídeo com o formato, resolução e qualidade escolhidos. | Deve ter | Mantido | NOVO | Passo 5 | Núcleo funcional do caso de uso. | Dado a escolha MP4 a 720p, então o ficheiro gerado é MP4 a 720p. |
| REQ-VID-CONV-006 | O sistema deve guardar o novo vídeo na biblioteca do utilizador. | Deve ter | Mantido | NOVO | Passo 6, Pós-condição de sucesso | Torna o novo vídeo acessível como qualquer outro da biblioteca. | Dado o processamento concluído, então o novo vídeo surge na biblioteca. |
| REQ-VID-CONV-007 | O sistema deve disponibilizar o novo vídeo para visualização e descarga. | Deve ter | Mantido | NOVO | Passo 7 | O utilizador tem de poder ver e levar o resultado. | Dado o novo vídeo, então pode ser reproduzido e descarregado. |
| REQ-VID-CONV-008 | O sistema deve indicar o tamanho original e o tamanho final do vídeo. | Deve ter | Mantido | NOVO | Passo 7 | Permite verificar o ganho de espaço. | Dado o resultado, então são apresentados os dois tamanhos. |
| REQ-VID-CONV-009 | O sistema deve permitir ao utilizador alterar apenas o formato, mantendo a resolução e a qualidade. | Deve ter | Mantido | NOVO | FA1 | Cobre a necessidade só de compatibilidade. | Dado MOV→MP4 sem outras alterações, então resolução e qualidade ficam iguais às do original. |
| REQ-VID-CONV-010 | O sistema deve permitir ao utilizador reduzir apenas a resolução ou a qualidade, mantendo o formato. | Deve ter | Mantido | NOVO | FA2 | Cobre a necessidade só de tamanho. | Dado a redução de resolução, então o formato do ficheiro gerado é o do original. |
| REQ-VID-CONV-011 | O sistema deve permitir ao utilizador escolher um perfil predefinido de conversão. | Poderia ter | Mantido | NOVO | FA3, Q4 | Facilita casos comuns de partilha (Q4). | Dado o perfil "Partilha web", então as opções são preenchidas com os valores do perfil. |
| REQ-VID-CONV-012 | O sistema deve continuar o processamento quando o utilizador abandona a página. | Deve ter | Mantido | NOVO | FA4 | Operação demorada; o utilizador não deve ter de manter a página aberta. | Dado uma conversão em curso, quando fecha a página, então o novo vídeo surge no fim. |
| REQ-VID-CONV-013 | O sistema deve apresentar o estado do processamento (em fila, em curso, concluído, falhado ou cancelado). | Deve ter | Refinado | NOVO | A3, FA4, DQ-008 | Permite acompanhar uma operação que não é instantânea. | Dado um processamento, então o estado é visível. |
| REQ-VID-CONV-014 | O sistema deve bloquear resoluções superiores à permitida pelo perfil e sugerir o upgrade para premium. | Deve ter | Mantido | ALT | Exceção 1, RN5 | Aplica o limite do perfil e incentiva o upgrade. | Dado um registado, quando tenta resolução acima do limite, então é bloqueado e surge sugestão de upgrade. |
| REQ-VID-CONV-015 | O sistema deve rejeitar vídeos cujo formato ou codec não seja suportado (entrada: MP4 e MOV, com vídeo H.264 e áudio AAC) (†). | Deve ter | Refinado | NOVO | Exceção 2, RN4, DQ-001 | Protege o sistema de ficheiros que não consegue processar (RN4). | Dado codec não suportado, então rejeita com mensagem. |
| REQ-VID-CONV-016 | O sistema deve terminar a operação e apresentar erro quando o vídeo estiver corrompido. | Deve ter | Mantido | NOVO | Exceção 3 | Evita resultados inválidos e informa o utilizador. | Dado um vídeo corrompido, então termina com erro. |
| REQ-VID-CONV-017 | O sistema deve avisar o utilizador e pedir confirmação quando o ficheiro final for estimado como maior do que o original. | Deveria ter | Mantido | NOVO | Exceção 4 | Evita que a compressão aumente o ficheiro sem o utilizador saber. | Dado uma estimativa superior ao original, então surge aviso e, sem confirmação, não inicia. |
| REQ-VID-CONV-018 | O sistema deve impedir o início da operação quando o utilizador registado tiver a quota diária esgotada. | Deve ter | Mantido | ALT | Exceção 5, RN2, Pré-condição (quota disponível) | Aplica a regra de quotas existente (RN2) à nova operação. | Dado quota esgotada, então não inicia e é informado. |
| REQ-VID-CONV-019 | O sistema não deve aplicar limite diário de operações de conversão a utilizadores premium. | Deve ter | Mantido | ALT | RN3 | Mantém a vantagem do perfil premium (RN3). | Dado um premium com muitas operações, então nova conversão é aceite. |
| REQ-VID-CONV-022 | O sistema deve limitar a 720p (†) a resolução máxima de saída para utilizadores registados. | Deve ter | Refinado | ALT | RN5, Q2, DQ-014 | Restrição funcional do perfil (RN5), reclassificada de NF (Capacidade); valor (†) a confirmar (Q2). | Dado um registado, então nenhum vídeo gerado excede 720p. |
| REQ-VID-CONV-026 | O sistema deve rejeitar, antes de iniciar o processamento, vídeos com tamanho de ficheiro superior a 500 MB (†). | Deve ter | Novo | NOVO | RN4, DQ-002 | Completa a validação do ficheiro, que tem de cobrir também a dimensão, para proteger a capacidade de processamento e o armazenamento. Extensão de âmbito (ver 4.1.3). | Dado um vídeo de 501 MB, quando o utilizador confirma, então é rejeitado com indicação do limite; com 500 MB é aceite. |
| REQ-VID-CONV-027 | O sistema deve apresentar a percentagem de progresso de um processamento em curso. | Deveria ter | Novo | NOVO | A3, FA4, DQ-008 | Operação que dura minutos; um estado discreto não basta para o utilizador estimar o tempo restante. Extensão de âmbito (ver 4.1.3). | Dado um processamento em curso, quando o utilizador consulta o estado, então vê uma percentagem entre 0 % e 100 % que não diminui. |
| REQ-VID-CONV-028 | O sistema deve permitir ao utilizador cancelar um processamento em fila ou em curso. | Deveria ter | Novo | NOVO | FA4, DQ-008 | Evita ocupar capacidade e quota com pedidos feitos por engano ou já desnecessários. Extensão de âmbito (ver 4.1.3). | Dado um processamento em curso, quando o utilizador cancela, então o estado passa a “cancelado” e não fica nenhum resultado associado. |
| REQ-VID-CONV-029 | O sistema deve notificar o utilizador na aplicação quando um processamento termina, com sucesso ou com falha. | Deveria ter | Novo | NOVO | FA4, DQ-008 | Com processamento em segundo plano, o utilizador precisa de saber quando voltar ao resultado. Extensão de âmbito (ver 4.1.3). | Dado um processamento em segundo plano, quando termina, então surge uma notificação que indica o resultado. |
| REQ-VID-CONV-030 | O sistema deve apresentar, quando o processamento falha, uma mensagem que indique a causa da falha em linguagem corrente. | Deve ter | Novo | NOVO | Exceção 6, Pós-condição mínima, DQ-004 | O utilizador precisa de perceber se pode repetir o pedido ou se o vídeo tem um problema. | Dado uma falha injetada a meio do processamento, quando o utilizador consulta o estado, então vê “falhado” e uma mensagem com a causa. |
| REQ-VID-CONV-031 | O sistema deve contabilizar a operação na quota diária do utilizador registado apenas quando concluída com sucesso. | Deve ter | Novo | ALT | RN2, Pré-condição (quota disponível), DQ-003 | Falhas e cancelamentos não devem penalizar o utilizador; define a regra de contagem pedida no Exercício 2. | Dado um registado com quota disponível e uma falha injetada, quando consulta a quota, então o valor usado não aumentou. |
| REQ-VID-CONV-032 | O sistema deve impedir utilizadores anónimos de pedir a conversão ou compressão de vídeos. | Deve ter | Novo | ALT | Pré-condição (sessão iniciada), DQ-010 | O caso de uso abrange apenas utilizadores registados e premium; o perfil anónimo tem de ficar explicitamente excluído. Extensão de âmbito (ver 4.1.3). | Dado uma sessão anónima, quando tenta aceder à operação, então é-lhe pedido que inicie sessão e nada é criado. |
| REQ-VID-CONV-033 | O sistema deve manter o vídeo convertido ou comprimido na biblioteca do utilizador até este o eliminar. | Deve ter | Novo | NOVO | Pós-condição de sucesso, DQ-005 | Define a persistência do resultado: sem expiração no MVP, para não perder trabalho do utilizador. Extensão de âmbito (ver 4.1.3). | Dado um resultado criado há 30 dias, quando o utilizador abre a biblioteca, então continua disponível. |
| REQ-VID-CONV-034 | O sistema deve eliminar os ficheiros temporários do processamento até 1 h (†) após o seu termo, quer este tenha sucesso, falha ou seja cancelado. | Deve ter | Novo | NOVO | Pós-condição mínima, DQ-005 | Evita acumular dados do utilizador fora da biblioteca e reduz o custo de armazenamento. Extensão de âmbito (ver 4.1.3). | Dado um processamento terminado, quando passa 1 h, então não existem ficheiros temporários associados a esse trabalho. |
| REQ-VID-CONV-035 | O sistema deve permitir aos utilizadores premium resoluções de saída até 1080p (†). | Deve ter | Novo | ALT | Passo 2, RN5, DQ-014 | Concretiza a diferenciação de perfis (RN5) com um valor verificável (Q2). | Dado um utilizador premium, quando escolhe 1080p, então a opção é aceite; para um registado, 1080p não está disponível. |
| REQ-VID-CONV-036 | O sistema deve manter o vídeo original na biblioteca após a conversão, sem o substituir pelo vídeo convertido. | Deve ter | Novo | NOVO | RN1, DQ-015 | Evita perda irreversível do original (Q3). | Dado uma conversão concluída, quando o utilizador abre a biblioteca, então existem o vídeo original e o novo vídeo. |
| REQ-VID-CONV-037 | O sistema deve rejeitar vídeos com duração superior a 10 min (†) antes de iniciar o processamento. | Deve ter | Novo | NOVO | RN4, DQ-002 | Completa a validação do ficheiro (duração) e protege a capacidade de processamento (Q5). | Dado um vídeo de 11 min, quando o utilizador confirma, então é rejeitado com indicação do limite; com 10 min é aceite. |

### 4.1.2 Requisitos Não Funcionais e de Qualidade

As regras de negócio e restrições funcionais (limites de duração, tamanho, resolução e número de imagens) estão na tabela 4.1.1. Aqui ficam apenas os requisitos de qualidade, classificados segundo a ISO/IEC 25010.

| **ID** | **Requisito** | **Característica ISO/IEC 25010** | **Alvo MVP** | **Alvo produção** | **Evolução** | **Origem (UC / DQ)** | **Critério de aceitação / verificação** |
|---|---|---|---|---|---|---|---|
| REQ-VID-CONV-020 | O sistema deve remover os resultados parciais quando o processamento falha ou é cancelado. | Fiabilidade (Recuperabilidade) | Estado “falhado”, remoção dos parciais, sem retoma | Uma repetição automática e retoma a partir do último ponto de controlo | Refinado | Exceção 6, Pós-condição mínima, DQ-004 | Dado uma falha forçada, então não existe vídeo incompleto na biblioteca. |
| REQ-VID-CONV-021 | O sistema deve manter o vídeo original inalterado, gerando sempre um novo ficheiro. | Segurança (Integridade) | Obrigatório | Obrigatório | Mantido | RN1, Pós-condição de sucesso | Dado o hash do original antes e depois, então são idênticos. |
| REQ-VID-CONV-023 | O sistema deve gerar um vídeo com a mesma duração e o mesmo áudio do original, com diferença de duração máxima de 1 s (†). | Adequação Funcional (Correção funcional) | ≤ 1 s de diferença e áudio presente | ≤ 1 frame de diferença e áudio presente | Mantido | RN6 | Dado um original de 120 s, então o gerado tem entre 119 s e 121 s e áudio presente. |
| REQ-VID-CONV-024 | O sistema deve apresentar uma estimativa de tamanho com erro máximo de 20 % (†) face ao tamanho final. | Adequação Funcional (Correção funcional) | ≤ 20 % (†) | ≤ 10 % (†) | Mantido | A4, Passo 3, DQ-016 | Dado 20 conversões de teste, então a estimativa difere ≤ 20 % do tamanho final real. |
| REQ-VID-CONV-025 | O sistema deve confirmar a receção do pedido em ≤ 2 s, independentemente da duração do vídeo. | Eficiência de Desempenho (Comportamento temporal) | ≤ 2 s | ≤ 1 s (†) | Refinado | A3, FA4, DQ-011 | Dado vídeos de 1 min e 60 min, então a confirmação surge em ≤ 2 s. |
| REQ-VID-CONV-038 | O sistema deve processar em simultâneo até 5 (†) trabalhos de vídeo, mantendo os restantes em fila. | Eficiência de Desempenho (Capacidade) | 5 trabalhos simultâneos (†) | 50 trabalhos simultâneos (†) | Novo | A3, DQ-007 | Dado 8 pedidos de utilizadores diferentes em simultâneo, então 5 ficam em curso, 3 ficam “em fila” e os 8 terminam com sucesso. |
| REQ-VID-CONV-039 | O sistema deve restringir o acesso ao vídeo original e ao resultado ao utilizador que o submeteu. | Segurança (Confidencialidade) | Obrigatório | Obrigatório | Novo | Pré-condição (sessão iniciada), DQ-006 | Dado uma sessão de outro utilizador, quando tenta aceder ao vídeo ou ao resultado, então recebe erro de autorização. |
| REQ-VID-CONV-040 | O sistema deve disponibilizar o vídeo e o resultado para descarga apenas através de ligações não adivinháveis, com pelo menos 128 bits de aleatoriedade (†). | Segurança (Confidencialidade) | Obrigatório; ligação válida só com a sessão do proprietário | Obrigatório e com expiração ≤ 15 min (†) | Novo | Passo 7, DQ-006 | Dado uma ligação de descarga, quando um carácter é alterado ou é usada sem a sessão do proprietário, então devolve erro e não entrega o ficheiro. |
| REQ-VID-CONV-041 | O sistema deve atualizar o estado e a percentagem de progresso apresentados ao utilizador com um intervalo máximo de 10 s (†). | Usabilidade (Operabilidade) | ≤ 10 s | ≤ 2 s | Novo | A3, FA4, DQ-008 | Dado um processamento em curso de 5 min, quando se observa o ecrã durante 1 min, então o valor é atualizado pelo menos a cada 10 s. |
| REQ-VID-CONV-042 | O sistema deve aceitar como entrada vídeos MP4 e MOV, com vídeo H.264 e áudio AAC. | Compatibilidade (Interoperabilidade) | MP4 e MOV (H.264/AAC) | MP4 e MOV, mais WebM e MKV (†) | Novo | RN4, DQ-001 | Dado um MP4 e um MOV com H.264/AAC, então ambos são aceites; dado um AVI, então é rejeitado com mensagem. |
| REQ-VID-CONV-043 | O sistema deve poder ser instalado e executado, incluindo as dependências externas de processamento de vídeo, num ambiente limpo a partir de instruções documentadas. | Portabilidade (Instalabilidade) | Instalação documentada, com versões das dependências fixadas | Instalação automatizada com uma só ação, em ambiente isolado | Novo | DQ-012 | Dado uma máquina limpa, quando se seguem as instruções documentadas, então o teste de aceitação desta funcionalidade passa. |
| REQ-VID-CONV-044 | O sistema deve permitir acrescentar uma nova ferramenta de vídeo sem alterar o código das ferramentas de vídeo existentes. | Manutenibilidade (Modularidade) | Objetivo (demonstrado quando existir uma segunda ferramenta) | Obrigatório | Novo | DQ-009 | Dado uma segunda ferramenta de vídeo acrescentada, então nenhum ficheiro de código das ferramentas existentes foi alterado. |
| REQ-VID-CONV-045 | O sistema deve concluir a conversão ou compressão em tempo não superior a 2× a duração do vídeo (†). | Eficiência de Desempenho (Comportamento temporal) | ≤ 2× a duração do vídeo | ≤ 0,5× a duração do vídeo | Novo | A3, DQ-011 | Dado um vídeo de 10 min, quando o processamento arranca sem outros trabalhos, então termina em ≤ 20 min. |
| REQ-VID-CONV-046 | O sistema deve produzir vídeos em MP4 (H.264/AAC) e WebM (VP9/Opus) reproduzíveis nos navegadores atuais (†). | Compatibilidade (Interoperabilidade) | MP4 e WebM | MP4 e WebM, mais outros formatos conforme procura (†) | Novo | Passo 2, FA1, DQ-013 | Dado uma conversão para cada formato, quando o resultado é aberto num navegador atual, então é reproduzido com vídeo e áudio. |

> O alvo de produção é uma referência para a evolução futura (Fase 2), não um critério de aprovação do MVP.

### 4.1.3 Verificação da completude e dos limites do âmbito

| **Tópico a verificar** | **Aplicável?** | **Decisão / justificação** | **Requisito(s) relacionado(s)** |
|---|---|---|---|
| Formato, codec, duração e dimensão do vídeo | Sim | Validação antes de processar: formato e codec (MP4 e MOV com H.264/AAC), duração ≤ 10 min e tamanho ≤ 500 MB (†); resolução de saída limitada pelo perfil. O carregamento do vídeo é anterior ao caso de uso (A1). | CONV-014, CONV-015, CONV-026, CONV-037, CONV-042 |
| Estado, progresso, cancelamento e resultado | Sim | Estados em fila/em curso/concluído/falhado/cancelado, percentagem de progresso, cancelamento, notificação de fim e tamanhos original e final no resultado. | CONV-008, CONV-013, CONV-027, CONV-028, CONV-029, CONV-041 |
| Falhas durante o processamento | Sim | Remoção do resultado parcial, mensagem com a causa, sem retoma automática no MVP. | CONV-016, CONV-020, CONV-030, CONV-034 |
| Persistência e expiração dos ficheiros | Sim | Vídeo convertido mantido até eliminação (sem expiração no MVP); original preservado; temporários eliminados até 1 h após o termo. | CONV-033, CONV-034, CONV-036, CONV-039, CONV-040 |
| Perfis e contagem de operações | Sim | Quota para registados, sem limite premium, resolução máxima por perfil (720p/1080p), anónimo excluído; só operações concluídas contam. | CONV-018, CONV-019, CONV-022, CONV-031, CONV-032, CONV-035 |
| Encadeamento de ferramentas e processamento em lote | Não | Fora do âmbito no MVP: converter vários vídeos em lote ou encadear a conversão com outras ferramentas de vídeo não é necessário para validar a recodificação. Mantém-se a modularidade para integração futura. | CONV-044 |

**Extensões de âmbito (completude do serviço):** CONV-026, CONV-027, CONV-028, CONV-029, CONV-032, CONV-033, CONV-034. Completam o serviço pedido no Exercício 2 (progresso, cancelamento, notificação, persistência, ficheiros temporários, validação da dimensão e exclusão do perfil anónimo) sem alterar o fluxo principal nem as regras de negócio do caso de uso; ficam registadas nas decisões de qualidade da secção 4.3.

**Evolução:** *Mantido* = requisito preservado; *Refinado* = clarificado ou tornado verificável sem mudar a intenção; *Novo* = acrescentado para completar a ERS. **NOVO/ALT** indica o impacto face ao PictuRAS existente, não a novidade face ao Exercício 1.

## 4.2 Impacto no sistema existente

| **Elemento existente afetado** | **Impacto (Manter / Estender / Alterar)** | **Descrição do impacto** | **Requisito(s) relacionado(s)** |
|---|---|---|---|
| Biblioteca de vídeos | Estender | Passa a receber versões convertidas/comprimidas. | CONV-006, CONV-020, CONV-033, CONV-036 |
| Quota diária (perfil registado) | Alterar | A conversão conta como operação. Só é contabilizada quando a operação termina com sucesso (DQ-003). | CONV-018, CONV-031 |
| Perfil premium (sem limite) | Estender | Regra de ausência de limite aplicada à nova operação, com diferenciação por resolução. | CONV-002, CONV-019 |
| Diferenciação de funcionalidades por perfil | Alterar | Resolução máxima de saída passa a depender do perfil; sugestão de upgrade. | CONV-002, CONV-014, CONV-022 |
| Processamento assíncrono e estados | Estender | Operação longa com estados visíveis. | CONV-012, CONV-013, CONV-025 |
| Armazenamento | Estender | Guarda um novo ficheiro por operação, com informação de tamanho. | CONV-006, CONV-008 |
| Descarga de resultados | Manter | Mesmo mecanismo aplicado ao novo vídeo. | CONV-007 |
| Perfis de utilização (anónimo / registado / premium) | Estender | A regra de acesso por perfil passa a cobrir as ferramentas de vídeo: o perfil anónimo fica excluído desta operação. | CONV-018, CONV-019, CONV-032 |
| Ficheiros temporários de processamento | Estender | Passam a existir ficheiros intermédios de processamento, eliminados até 1 h após o termo do trabalho. | CONV-020, CONV-034 |
| Autorização e acesso a ficheiros | Estender | O controlo de acesso por proprietário passa a cobrir os vídeos de entrada, os resultados e as ligações de descarga. | CONV-039, CONV-040 |
| Estado e notificações de trabalhos | Estender | O acompanhamento passa a incluir percentagem de progresso, cancelamento e notificação de fim de trabalhos de vídeo. | CONV-013, CONV-027, CONV-028, CONV-029, CONV-041 |
| Capacidade de processamento | Estender | Passa a existir um limite de trabalhos de vídeo em simultâneo, com fila para os restantes. | CONV-038, CONV-045 |
| Encadeamento de ferramentas e processamento em lote | Manter | Sem integração no MVP: o trabalho é individual e não é encadeável nem processado em lote (DQ-009). | CONV-044 |

## 4.3 Matriz de Rastreabilidade Atualizada

| **Elemento de origem** | **Descrição abreviada** | **Requisito(s) relacionado(s)** |
|---|---|---|
| Passo 1 | Abrir biblioteca | CONV-001 |
| Passo 2 | Selecionar vídeo, opções por perfil | CONV-001, CONV-002, CONV-035, CONV-046 |
| Passo 3 | Escolher opções, estimativa | CONV-003, CONV-024 |
| Passo 4 | Confirmar e validar | CONV-004 |
| Passo 5 | Recodificar | CONV-005 |
| Passo 6 | Guardar | CONV-006 |
| Passo 7 | Consultar resultado, tamanhos | CONV-007, CONV-008, CONV-040 |
| FA1 | Apenas conversão | CONV-009, CONV-046 |
| FA2 | Apenas compressão | CONV-010 |
| FA3 | Perfis predefinidos | CONV-011 |
| FA4 | Segundo plano | CONV-012, CONV-013, CONV-025, CONV-027, CONV-028, CONV-029, CONV-041 |
| Exceção 1 | Resolução acima do perfil | CONV-014 |
| Exceção 2 | Formato/codec | CONV-015 |
| Exceção 3 | Vídeo corrompido | CONV-016 |
| Exceção 4 | Ficheiro final maior | CONV-017 |
| Exceção 5 | Quota esgotada | CONV-018 |
| Exceção 6 | Falha no processamento | CONV-020, CONV-021, CONV-030 |
| Pós-condição de sucesso | Novo vídeo, original intacto | CONV-006, CONV-021, CONV-033 |
| Pós-condição mínima | Sem vídeo incompleto | CONV-020, CONV-030, CONV-034 |
| RN1 | Novo ficheiro | CONV-021, CONV-036 |
| RN2 | Quotas registados | CONV-018, CONV-031 |
| RN3 | Premium sem limite | CONV-019 |
| RN4 | Só formatos suportados | CONV-015, CONV-026, CONV-037, CONV-042 |
| RN5 | Resolução máxima registados | CONV-002, CONV-014, CONV-022, CONV-035 |
| RN6 | Mantém duração e áudio | CONV-023 |
| A3 | Estados intermédios | CONV-013, CONV-025, CONV-027, CONV-038, CONV-041, CONV-045 |
| A4 | Estimativa aproximada | CONV-003, CONV-024 |
| Pré-condição (quota disponível) | Verificação de quota | CONV-018, CONV-031 |
| Pré-condição (sessão iniciada) | Utilizador autenticado | CONV-032, CONV-039 |
| DQ-001 | Formatos de entrada MP4 e MOV | CONV-015, CONV-042 |
| DQ-002 | Limites de duração e tamanho | CONV-026, CONV-037 |
| DQ-003 | Quota só com sucesso | CONV-031 |
| DQ-004 | Falha: sem parciais, sem retoma no MVP | CONV-020, CONV-030 |
| DQ-005 | Persistência e ficheiros temporários | CONV-033, CONV-034 |
| DQ-006 | Acesso restrito ao proprietário | CONV-039, CONV-040 |
| DQ-007 | Trabalhos simultâneos e fila | CONV-038 |
| DQ-008 | Progresso, cancelamento e notificação | CONV-013, CONV-027, CONV-028, CONV-029, CONV-041 |
| DQ-009 | Sem lote nem encadeamento; modularidade | CONV-044 |
| DQ-010 | Perfil anónimo excluído | CONV-032 |
| DQ-011 | Alvos de desempenho | CONV-025, CONV-045 |
| DQ-012 | Instalação reprodutível | CONV-043 |
| DQ-013 | Formatos de saída | CONV-046 |
| DQ-014 | Resolução máxima por perfil | CONV-022, CONV-035 |
| DQ-015 | Original preservado | CONV-036 |
| DQ-016 | Precisão da estimativa de tamanho | CONV-024 |

**Decisões de qualidade introduzidas nesta aula**

| **ID** | **Decisão de qualidade** | **Justificação** | **Requisito(s) relacionado(s)** |
|---|---|---|---|
| DQ-001 | Formatos de entrada suportados no MVP: MP4 e MOV, com vídeo H.264 e áudio AAC (†). | Cobre os formatos mais comuns e limita o esforço de teste na Fase 1 (RN4). | CONV-015, CONV-042 |
| DQ-002 | Limites de entrada no MVP: duração ≤ 10 min e tamanho ≤ 500 MB (†). | Protege a capacidade de processamento e o armazenamento; responde a Q5. | CONV-026, CONV-037 |
| DQ-003 | Uma operação só é contabilizada na quota diária quando concluída com sucesso. | Falhas e cancelamentos não devem penalizar o utilizador (RN2). | CONV-031 |
| DQ-004 | Falha ou cancelamento não deixam ficheiros parciais; no MVP não há retoma automática; em produção há uma repetição automática e retoma a partir do último ponto de controlo. | O MVP prioriza a consistência; a retoma é uma melhoria para a Fase 2. | CONV-020, CONV-030 |
| DQ-005 | Os resultados mantêm-se na biblioteca até o utilizador os eliminar; os ficheiros temporários são eliminados até 1 h após o termo do processamento (†). | Evita perda de trabalho do utilizador e retenção desnecessária de dados. | CONV-033, CONV-034 |
| DQ-006 | O vídeo e o resultado só são acessíveis ao utilizador proprietário e a descarga usa ligações não adivinháveis. | Os vídeos são conteúdo pessoal do utilizador. | CONV-039, CONV-040 |
| DQ-007 | O MVP processa até 5 trabalhos de vídeo em simultâneo (†); os restantes ficam em fila. | Limita o consumo de CPU e mantém a aplicação responsiva. | CONV-038 |
| DQ-008 | Acompanhamento do trabalho: percentagem de progresso, cancelamento e notificação de fim, com estado atualizado com intervalo máximo de 10 s no MVP (†). | Operações que duram minutos exigem feedback ao utilizador. | CONV-013, CONV-027, CONV-028, CONV-029, CONV-041 |
| DQ-009 | Encadeamento de ferramentas e processamento em lote ficam fora do MVP; a arquitetura deve permitir acrescentar ferramentas de vídeo sem alterar as existentes. | Mantém o âmbito do caso de uso e prepara a evolução. | CONV-044 |
| DQ-010 | O perfil anónimo não tem acesso a esta operação; os perfis registado e premium têm. | Alinha com as pré-condições do caso de uso (sessão iniciada). | CONV-032 |
| DQ-011 | Alvos de desempenho: confirmação do pedido em ≤ 2 s no MVP e tempo de processamento proporcional à duração do vídeo (valores em 4.1.2) (†). | Distingue o tempo de resposta da submissão do tempo de processamento. | CONV-025, CONV-045 |
| DQ-012 | O processamento deve ser instalável e reprodutível a partir de instruções documentadas, com as dependências externas isoladas do serviço web. | Reduz o risco associado a binários externos (Portabilidade). | CONV-043 |
| DQ-013 | Formatos de saída no MVP: MP4 (H.264/AAC) e WebM (VP9/Opus) (†). | Cobre a reprodução nos navegadores atuais e responde a Q1. | CONV-046 |
| DQ-014 | Resolução máxima de saída: 720p para registados e 1080p para premium (†). | Concretiza a diferenciação de perfis (RN5) e responde a Q2. | CONV-022, CONV-035 |
| DQ-015 | O vídeo original nunca é substituído pelo convertido. | Evita perda irreversível de conteúdo (RN1, Q3). | CONV-036 |
| DQ-016 | A estimativa de tamanho final tem erro máximo de 20 % no MVP e 10 % em produção (†). | Torna verificável a estimativa (A4). | CONV-024 |

**Verificações de cobertura**
- [x] Cada requisito funcional e não funcional aparece na matriz.
- [x] Cada requisito tem origem identificada: elemento do caso de uso, regra de negócio ou decisão de qualidade.
- [x] Todos os elementos relevantes do caso de uso (passos, fluxos alternativos, exceções, regras de negócio e pós-condições) têm requisito associado.
- [x] Os tópicos excluídos na secção 4.1.3 estão justificados.
- [x] O impacto no sistema existente está atualizado e ligado aos requisitos relevantes.
