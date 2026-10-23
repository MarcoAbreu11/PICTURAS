# Prompts relevantes (Fase 1)

Prompts dados ao Claude Code nas sessões do Marco Abreu (aplicação de _desktop_, sessão de 2026-10-17 a
2026-10-23), copiados da transcrição da sessão, com a data, o objetivo e o que a equipa validou. Os prompts
de confirmação curtos ("faz push", "continua") e os pedidos sem relação com o trabalho entregue ficam de fora.
Os prompts do UC-VID-001 (ChatGPT Work) estão descritos na nota de implementação
`docs/UC-VID-001_legendas.md`; os das restantes sessões de colegas não ficaram registados no repositório.

## Planeamento

| Data | Prompt | Resultado e validação |
|---|---|---|
| 2026-10-17 | "Quero que fazas um guiao detalhado das alterações de cada ficheiro, e localizes as pastas e a maneira geral de como vai funcionar" | Guião `docs/GUIAO_VIDEO.md`, lido e corrigido pela equipa. |
| 2026-10-17 | "Refaz o plano sem as tools e as tools são para ser feitas mais para a frente. Docs que criares é para nós lermos não para use-cases" | Plano refeito só com a infraestrutura de vídeo. |
| 2026-10-17 | "Sim, implementa o primeiro marco do guião: infraestrutura de upload, media_type no upload e no /imgs, e o MediaView no frontend." | Carregamento de vídeos e leitor; testado à mão com um vídeo próprio. |
| 2026-10-17 | "Temos os seguintes use cases: [...] Cria um guião especifico de que cada elemento deve fazer" | Guião `docs/GUIAO_TOOLS_VIDEO.md` com a divisão por elemento. |

## UC-VID-004 (Desfocar caras)

| Data | Prompt | Resultado e validação |
|---|---|---|
| 2026-10-18 | "Esta é o meu use case quero que verifiques se está tudo bem e quero que digas passo a passo o que tenho de fazer" (com `UC-VID-004_desfocar_caras_v1.1.md`) | Revisão do caso de uso e guião `docs/GUIAO_UC-VID-004_desfocar_caras.md`. |
| 2026-10-18 | "o ficheiro com os requisitos está na pasta docs aplica as alterações necessarias para ficar totalmente direito" | Caso de uso corrigido em `docs/UC-VID-004-desfocar-caras.md`, revisto pelo Marco. |
| 2026-10-19 | "implementa no picturas esta funcionalidade tendo em conta o use case e mantem o flow do trabalho" | _Worker_ `blur_faces`, regras no `projects`, painel e descarte no _frontend_, testes; validado com um vídeo próprio com pessoas (TST-BLUR-03) e revisão de código pelo Marco. |
| 2026-10-19 | "Sim, corrige a barra de progresso da blur_faces na página do projeto, testa e faz push pelo meu terminal, sem coautoria." | Progresso por vídeo corrigido e verificado no navegador. |
| 2026-10-21 | "Sim, acrescenta a deteção a cada 3 frames como decisão de qualidade no UC-VID-004 (docs e relatório), com a justificação e a limitação, e faz push pelo meu terminal sem coautoria." | DQ-021 no caso de uso e no relatório. |

## Pipeline e legendas

| Data | Prompt | Resultado e validação |
|---|---|---|
| 2026-10-20 | "Neste momento a tool de legendas não está a ser adicionada à pipeline podes fazer isso e só ser aplicada depois de fazer apply" | Legendas como ferramenta da _pipeline_, geradas só no Apply; testes ponta a ponta das legendas. |
| 2026-10-21 | "as tools do video não deveriam dar para usar todas na mesma pipeline?" | Análise que manteve as ferramentas de vídeo exclusivas (DA-03, PIPE-004). |

## Relatório e verificação

| Data | Prompt | Resultado e validação |
|---|---|---|
| 2026-10-21 | "Na pasta "relatorio" tens lá o necessário para fazer o relatório" | Relatório em Typst a partir do _template_ e dos documentos da equipa; revisto pela equipa. |
| 2026-10-21 | "Na página 5 diz lá que o desfocar desfoca a cara frame a frame mas isso e mentira porque só faz isso a cada 3 frames, verifica ainda se tem alguma coisa fora do que temos realmente no trabalho e corrige. No final diz o que falta fazer ainda" | Verificação do relatório contra o código (limites, réplicas, constantes) e correção das afirmações falsas. |
| 2026-10-23 | "quero que faz ao repositório e vejas as alterações que foram feitas e verifica se está tudo pronto para a entrega" | Execução de todas as baterias de testes e comparação dos pacotes de entrega com o repositório; encontrou os zips com fins de linha CRLF e regenerou-os com LF. |
| 2026-10-23 | "Isto é verdade?" (sobre a auditoria final) e "Se for do código original não é para mejer" | Cada defeito da auditoria verificado no código e na origem (`git blame`); D-07 e D-08 corrigidos com o teste TST-SUB-13, D-09 a D-11 registados. |
