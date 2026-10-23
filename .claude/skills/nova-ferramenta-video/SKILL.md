---
name: nova-ferramenta-video
description: Acrescentar uma nova ferramenta de vídeo ao PictuRAS (worker, fila, regras no projects, frontend, testes e relatório). Usar quando se pede uma nova operação sobre vídeos.
---

# Acrescentar uma ferramenta de vídeo

Segue o padrão das ferramentas existentes (`trim` é o exemplo mais simples) e não altera os _workers_
existentes (REQ-VID-MAINT-001).

## 1. Worker (`Tools/<ferramenta>/`)

- `Dockerfile` a partir de `python:3.11.10-slim-bookworm` (versão fixada, DA-11) e FFmpeg do Debian.
- `<ferramenta>.py`: lê da fila com `Tools/utils/tool_msg.py`; usa `Tools/utils/video.py` para o
  `ffprobe`, o FFmpeg com progresso e a limitação do progresso (0 % ao sair da fila, depois ≤ 1/s).
- `<ferramenta>_rules.py`: validação dos parâmetros, nomes e argumentos do FFmpeg, sem I/O (testável).
- Em falha: remover o ficheiro parcial e enviar o erro com código e causa (nunca deixar resultado parcial).
- `test_<ferramenta>_rules.py` com `unittest`.

## 2. Infraestrutura

- Fila `<ferramenta>_queue` em `rabbitMQ/definitions.json`.
- Serviço em `docker-compose.yaml`: `depends_on: rabbitmq (service_healthy)`, volume `image_data`,
  `deploy.replicas` (5 por omissão; 1 se o modelo ocupar muita memória).

## 3. Serviço `projects`

- `projects/utils/toolCapabilities.js`: `CAPABILITIES.<ferramenta> = ["video"]` e, se não se combina com
  outras, acrescentar a `EXCLUSIVE_TOOLS`.
- `projects/utils/project_msg.js`: entrada em `queues`.
- `projects/utils/<ferramenta>.js`: validação dos parâmetros; ligar em `validateToolParams`
  (`projects/routes/projects.js`).
- Se for avançada, acrescentar a `advanced_tools` (quota por vídeo, devolvida em falha).
- Testes em `projects/test/<ferramenta>.test.js` (`node --test`).

## 4. Frontend

- Componente em `frontend/components/toolbar/<ferramenta>-tool.tsx` e registo em `toolbar.tsx`.
- Em `frontend/app/dashboard/[pid]/page.tsx`, incluir a ferramenta na lista das ferramentas de vídeo
  (estado "Em fila"/"Em curso" e progresso).

## 5. Testes e relatório

- Bateria e2e `projects/test/e2e/<ferramenta>.sh` e chamada em `run.sh`.
- Relatório: caso de uso `UC-VID-nnn`, requisitos `REQ-VID-<ÁREA>-nnn` (sem reutilizar IDs), linhas nas
  tabelas 7.1, 7.3 e 10.2, componente na tabela 8.1 e, se for o caso, uma DA.
