# PictuRAS: instruções para agentes de IA

Aplicação web de edição de imagem e vídeo (RAS 2026/2027, grupo 5), em microserviços com Docker Compose.
Fase 1: suporte a vídeo num MVP. O relatório da fase está em `relatorio/` (Typst).

## Arquitetura (não reestruturar: restrição R7)

- `nginx` → `frontend` (Next.js), `api_gateway` (REST) e `ws_gateway` (Socket.IO).
- `projects` (Node + MongoDB `projects_mongoDB`) orquestra a pipeline; `users` gere perfis e quota;
  `img_storage` guarda os ficheiros no SeaweedFS (S3) e serve ligações assinadas (1 h).
- Ferramentas = _workers_ Python em `Tools/<ferramenta>/`, um por ferramenta, ligados ao `projects`
  pelo RabbitMQ (`<ferramenta>_queue`); trabalham sobre o volume partilhado `image_data`.
- Ferramentas de vídeo: `trim`, `extract_frames`, `blur_faces`, `video_convert`, `video_subtitles`.

## Regras que o código tem de respeitar

- O processamento de média corre só nos _workers_; o `projects` não corre FFmpeg dentro de um pedido
  HTTP (DA-07). O `/process` responde em ≤ 2 s e só depois copia os vídeos (DA-06).
- Cada ferramenta declara o tipo de média que aceita (`projects/utils/toolCapabilities.js`); as de vídeo
  são exclusivas na pipeline (`EXCLUSIVE_TOOLS`).
- Quota: o registado gasta 1 operação por vídeo numa ferramenta avançada, debitada no pedido e devolvida
  em falha ou cancelamento; o corte é básico e não gasta; o premium não tem limite; o anónimo não usa
  ferramentas avançadas.
- Um vídeo original nunca é alterado; as falhas são isoladas por vídeo (sem resultado parcial).
- Partilhas: dono e partilhas de edição aplicam ferramentas; vídeos convertidos e resultados de uma
  conversão só são visíveis ao dono (`visibleItems` / `visibleResults` em `projects/routes/projects.js`).
- Nos comentários, referir o requisito: `REQ-VID-<ÁREA>-nnn`, `UC-VID-nnn`, `DQ-nnn`, `DA-nn`.

## Comandos

```bash
docker compose up -d --build                      # stack completa (https://localhost:8080)
docker compose restart nginx users subscriptions   # depois de reconstruir; users arranca antes da BD (T-23)
docker compose up -d --build projects             # reconstruir um serviço
```

Testes: ver a skill `testes`. Resumo: unitários do `projects` com `node --test` e a MongoDB do
`projects_mongoDB`; unitários dos _workers_ dentro das imagens; ponta a ponta (e2e) com
`bash projects/test/e2e/run.sh` e a stack a correr.

## Git

- Nunca acrescentar linhas `Co-Authored-By` nem outra atribuição a agentes nos _commits_ ou PR.
- Não fazer _commit_ de ficheiros auxiliares locais (scripts de diagramas em `relatorio/images/src/*.py`,
  notas de revisão).
- Depois de mudar o relatório ou o código entregue, regenerar `docs/entrega-fase1`.

## Skills do projeto

- `nova-ferramenta-video`: passos para acrescentar uma ferramenta de vídeo.
- `testes`: como correr os testes e registar resultados.
