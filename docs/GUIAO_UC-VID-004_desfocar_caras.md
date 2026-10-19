# Guião — UC-VID-004 Desfocar caras (atualizado após o pull de 18/10)

> Guião interno para quem implementa o UC-VID-004. Está alinhado com o que o grupo já fez no
> **UC-VID-002 (cortar, `Tools/trim/`)** e no **UC-VID-003 (extrair frames, `Tools/extract_frames/`)**.
> A regra é simples: **fazer igual ao `trim`**, que é a tool de vídeo mais parecida com esta
> (recebe um vídeo e devolve um vídeo).

---

## 0. O que já existe e reutilizas (veio no pull)

| Já existe | Onde | Para que te serve |
|---|---|---|
| Mensagem de progresso | `ToolMSG.send_progress()` em `Tools/utils/tool_msg.py` | REQ-026 e REQ-037 (percentagem): já chega ao frontend via `wsGateway` (`process-progress`) |
| Manter a ligação ao RabbitMQ viva | `ToolMSG.keep_alive()` | Vídeos longos não perdem a ligação (chamar a cada frame/segundo) |
| Erros com keyword args | `send_msg(..., err_code=, err_msg=, og_img_uri=)` | REQ-029 (mensagem com a causa) |
| Tipo de output `"video"` | `process_msg` em `projects/routes/projects.js` | O resultado é guardado como vídeo e o ficheiro temporário é apagado (REQ-033 em parte) |
| Falha isolada por vídeo + devolução da operação | `handleItemFailure()` em `projects.js` | REQ-030 (quota só com sucesso) e REQ-020: só tens de pôr a tool em `EXCLUSIVE_TOOLS` |
| Tools exclusivas (não se combinam) | `EXCLUSIVE_TOOLS` em `projects/utils/toolCapabilities.js` | Cumpre o 4.1.3 do teu UC ("encadeamento fora do âmbito") |
| Itens incompatíveis ignorados | `processableImgs()` e `pipelineAccepts()` | Imagens no projeto são ignoradas e não gastam operações |
| Duração/resolução guardadas no upload | `imgs[].duration`, `width`, `height` | Validar sem reler o vídeo; frontend sabe a duração (`currentImage.duration`) |
| Copiar resultados para um novo projeto | `POST /:user/:project/results/project` | REQ-007 ("guardar na biblioteca"): o resultado vira um item normal |
| 5 réplicas por tool | `deploy: replicas: 5` no `docker-compose.yaml` | REQ-034 (5 trabalhos em simultâneo) |
| Toolbar de vídeo | ramo `currentIsVideo` em `frontend/components/toolbar/toolbar.tsx` | Onde pões o teu botão |
| `invalid` / `noPreview` no `ToolbarButton` | `frontend/components/toolbar/toolbar-button.tsx` | Bloquear Save com parâmetros inválidos |
| Testes | `node:test` (`projects/test/*.test.js`), `unittest` (`Tools/trim/test_trim_rules.py`), ponta a ponta (`projects/test/e2e/*.sh`) | Seguir a mesma estrutura e os IDs `TST-BLUR-xx` |

---

## 1. Ajustes ao documento do UC (para ficar coerente com o UC-VID-002/003)

Guardar o documento como **`docs/UC-VID-004-desfocar-caras.md`** (o mesmo padrão de nomes).

| # | O quê | Como o grupo fez no trim/frames | Ação no teu UC |
|---|---|---|---|
| 1 | Formatos, duração e tamanho | Validados **no carregamento, por perfil** (`media.js`: anónimo 15 s/20 MB, free 60 s/100 MB, premium 10 min/500 MB). O TRIM eliminou os requisitos duplicados (4.1.4) | Criar **4.1.4 Requisitos eliminados**: BLUR-017, BLUR-025 (substituídos pelos requisitos de carregamento) e BLUR-015/038 (substituídos por um requisito "formatos que a desfocagem processa": MP4, MOV, WebM). Atualizar A6 e DQ-001/DQ-002 |
| 2 | Codecs de saída | `trim_rules.CODECS`: o contentor mantém-se; MP4/MOV → H.264/AAC, WebM → VP9/Opus | Reescrever BLUR-043: "mesmo contentor; H.264/AAC para MP4/MOV, VP9/Opus para WebM" |
| 3 | "Biblioteca de vídeos" | O resultado aparece em **Resultados**; "Criar projeto com os resultados" faz dele um item normal | Passo 1, Passo 7, BLUR-001/007 e §4.2: trocar "biblioteca" por "resultados do projeto" (+ cópia para novo projeto) |
| 4 | Quota só com sucesso (BLUR-030) | Cobrança no início e devolução automática em falha (`handleItemFailure`) e em cancelamento | Manter o requisito, mas descrever como "cobrada no início e devolvida em caso de falha ou cancelamento" |
| 5 | Acesso (BLUR-035/036) | Partilha de projetos existente; ligações presigned válidas 1 h | BLUR-035: "…ou utilizadores com quem o projeto foi partilhado"; BLUR-036 (MVP): "ligação assinada, ≥128 bits, expira em ≤ 1 h" |
| 6 | Q6 e Q7 em aberto | — | Q6: "Proposta v1.1: sem expiração (DQ-005)". Q7: responder (ex.: "a operação é cobrada no pedido e devolvida se falhar; não há pedidos pendentes a contar") |
| 7 | §0 e §3 | — | Preencher "Grupo / Equipa" e a validação da 2.ª linha da tabela de IA; confirmar os autores |
| 8 | §4.1.2, frase inicial | — | Retirar "resolução e número de imagens" |
| 9 | Realização | O UC-VID-002 tem **§4.4 Realização e verificação** (componentes, testes, estado por requisito) | Acrescentar a §4.4 no fim (passo 14) |

---

## 2. Como vai funcionar

```
Frontend  BlurFacesTool (só num vídeo)  ── POST /tool {procedure:"blur_faces", params}
   ▼
projects  /tool     valida params (utils/blurFaces.js), perfil (advanced_tools → anónimo bloqueado),
                    exclusividade (EXCLUSIVE_TOOLS)
projects  /process  processableImgs → só vídeos; cobra 1 operação por vídeo (free)
   ▼
RabbitMQ  blur_faces_queue   (5 réplicas do worker)
   ▼
Tools/blur_faces/blur_faces.py
   1. ffprobe (codec, duração)                    → erro 2501 se ilegível
   2. frame a frame: YuNet a cada 3 frames, blur/pixelate, send_progress + keep_alive
   3. ffmpeg: junta o áudio original, codecs do contentor
   4. verifica a duração (±1 s)                   → erro 2502 se falhar
   5. send_msg(success, type="video", faces_detected=N)
   em erro: apaga o output parcial + send_msg(error)
   ▼
projects  process_msg  guarda Result(type "video", faces_detected) ; em erro → handleItemFailure (devolve a operação)
   ▼
wsGateway → frontend: progresso, fim, aviso "nenhuma cara" + botão Descartar
```

**Nome da tool:** `blur_faces` (sem prefixo `video_`, como `trim` e `extract_frames`).
**Códigos de erro:** `2500` procedimento errado · `2501` vídeo ilegível · `2502` falha a processar · `2503` parâmetros inválidos.
Já estão ocupados 1100–2200 e 2400; a gama 2300 fica para as legendas. Confirma no grupo.

---

## 3. Passo a passo

### Passo 1 — Branch
```bash
git checkout main && git pull
```
```bash
git checkout -b feat/blur-faces
```

### Passo 2 — Protótipo fora do Docker (meio dia)
Num ambiente Python local (`opencv-python`, `numpy`):
- `cv2.FaceDetectorYN.create("face_detection_yunet_2023mar.onnx", "", (w, h))`;
- ler um vídeo teu com `cv2.VideoCapture`, detetar a cada 3 frames, desfocar com `cv2.GaussianBlur` e
  pixelizar (reduzir a região para 10×10 e voltar a ampliar com `INTER_NEAREST`);
- medir o tempo: **≤ 3× a duração do vídeo** (REQ-041). Se for mais lento, detetar a cada 5 frames ou reduzir o frame para a deteção.

### Passo 3 — Conjunto de teste para os 90 % (REQ-023)
`Tools/blur_faces/eval/`:
- 20–30 imagens com caras frontais ≥ 64×64 px (**licença livre ou consentimento**, RGPD);
- `annotations.json` com as caixas de cada cara;
- `eval_detection.py`: corre o YuNet e conta uma cara como detetada se a caixa tiver IoU ≥ 0,5 com a anotada; imprime a taxa.

### Passo 4 — Regras puras: `Tools/blur_faces/blur_faces_rules.py`
O mesmo papel que `trim_rules.py`: funções sem RabbitMQ nem ficheiros, fáceis de testar.
```python
MODES = ("blur", "pixelate")
DETECT_EVERY = 3
CODECS = { 'webm': [...VP9/Opus...], 'default': [...H.264/AAC...] }   # copiar de trim_rules.py

def validate(params) -> str | None      # mode ∈ MODES, strength 1–10, padding 0–100
def expand_box(x, y, w, h, padding, frame_w, frame_h)   # alarga e corta aos limites do frame
def blur_kernel(strength, box_w) -> int  # ímpar, proporcional à cara
def output_name(video_name) -> str       # "aula.mp4" -> "aula_blurred.mp4"
def mux_args(tmp_video, original, out_path) -> list  # junta o áudio original, codecs pelo contentor
def duration_ok(original, result) -> bool            # |dif| ≤ 1 s (REQ-022)
```

### Passo 5 — Worker: `Tools/blur_faces/blur_faces.py`
Copiar a estrutura de `Tools/trim/trim.py` (classe, `callback`, `send_error`, `now`, `exec`) e mudar o meio:
1. `procedure != 'blur_faces'` → erro 2500.
2. `ffprobe` → duração, fps, codec. Falha → erro **2501** "The video could not be read…" (REQ-016).
3. `validate(params)` → erro **2503** (o projects já valida, isto é a 2.ª linha de defesa).
4. Dentro de `tempfile.TemporaryDirectory()` (REQ-033):
   - `cv2.VideoCapture` → `cv2.VideoWriter(tmp/video.mp4, "mp4v", fps, (w, h))`;
   - por frame: detetar a cada `DETECT_EVERY`, aplicar blur/pixelate às caixas, somar `faces_detected` (máximo de caras num frame ou total de deteções; escolhe e documenta);
   - a cada frame `keep_alive()`; no máximo 1×/s `send_progress(... , pct)` (copiar o `on_progress` do trim, até 90 %);
   - no fim, `ffmpeg` com `mux_args` → `out_path` (o áudio entra com `-map 1:a:0?`, REQ-006) e progresso a 100 %.
5. `duration_ok` falso → erro **2502** (REQ-022).
6. Sucesso: `send_msg(msg_id, resp_id, ts, 'success', elapsed, out_path, type='video')` com o nº de caras.
   O `send_msg` atual não tem campo para isto: **acrescenta um argumento opcional `extra=None`** em `tool_msg.py`
   que, se existir, vai para `msg["output"]` (ex.: `{"facesDetected": 3}`). Avisa o grupo; não parte nada.
7. `except`: apagar `out_path` se existir (REQ-020) e enviar erro com a causa (REQ-029), como no trim.
8. **Pré-visualização de um frame (REQ-010):** se `params.get('previewFrame')`, processar só o frame do meio,
   gravar `out_path` com extensão `.png` e responder `type='image'`.

### Passo 6 — Docker: `Tools/blur_faces/Dockerfile` e `requirements.txt`
Copiar `Tools/trim/Dockerfile` (`python:3.11-slim-bookworm` + ffmpeg) e acrescentar:
```dockerfile
COPY ./blur_faces/requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
# modelo YuNet com versão fixa (REQ-039, REQ-042: corre localmente, sem serviços externos)
ADD https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx models/
COPY ./blur_faces .
COPY ./utils ./utils
CMD ["python", "-u", "blur_faces.py"]
```
`requirements.txt`: `opencv-python-headless==4.10.0.84` e `numpy<2` (versões fixas).
Melhor ainda: guardar o `.onnx` no repositório (≈230 KB) em vez do `ADD`, para o build não depender da rede.
O `opencv_zoo` guarda os modelos com Git LFS: confirma que o ficheiro descarregado tem ≈230 KB e não é um
ficheiro de texto pequeno (ponteiro LFS); se for, descarrega-o pelo botão "Download" da página do GitHub.

### Passo 7 — Registar a tool (5 sítios)

| Ficheiro | O que acrescentar |
|---|---|
| `Tools/utils/tool_msg.py` | `'blur_faces': 'blur_faces_queue'` em `queues` (+ o argumento `extra` do passo 5) |
| `projects/utils/project_msg.js` | `'blur_faces': 'blur_faces_queue'` |
| `rabbitMQ/definitions.json` | fila `blur_faces_queue` em `queues` **e** binding (copiar as entradas de `trim_queue`) |
| `docker-compose.yaml` | serviço `blur_faces_tool` (copiar `trim_tool`, com `deploy: replicas: 5`) |
| `projects/utils/toolCapabilities.js` | `blur_faces: ["video"]` em `CAPABILITIES` e `"blur_faces"` em `EXCLUSIVE_TOOLS` |

### Passo 8 — Regras no `projects`
1. 🆕 `projects/utils/blurFaces.js` — espelho de `validate` do passo 4 (`validateBlurParams(params)`), como `utils/trim.js`.
2. `projects/routes/projects.js`:
   - `advanced_tools`: acrescentar `"blur_faces"` → anónimo bloqueado (REQ-031), quota do free (REQ-018), premium sem limite (REQ-019);
   - `validateToolParams`: `if (procedure === "blur_faces") return validateBlurParams(params);`
   - `process_msg`, no `Result.create` do tipo vídeo: guardar `faces_detected: msg_content.output.facesDetected`;
   - `GET /:user/:project/process/url`: devolver `faces_detected` em cada resultado;
   - rota **`POST /:user/:project/preview/:img`**: se a tool for `blur_faces`, enviar `params: { ...params, previewFrame: true }` (o resultado é uma imagem e a janela de preview já mostra imagens).
3. `projects/models/result.js`: `faces_detected: { type: Number, required: false }`.
4. 🆕 rota **`DELETE /:user/:project/results/:result`** (REQ-014, "Descartar"): apaga o objeto de `out` (`delete_image`) e o `Result`. Hoje não existe nenhuma rota para apagar um resultado.

### Passo 9 — Frontend
| Ficheiro | O que fazer |
|---|---|
| `frontend/lib/tool-types.ts` | `BlurFacesToolParams { mode: "blur" \| "pixelate"; strength: number; padding: number }`, juntar a `ToolParams`, `"blur_faces"` em `ToolNames` |
| 🆕 `frontend/lib/blur-faces.ts` | Espelho das regras (limites dos sliders), como `lib/trim.ts` |
| 🆕 `frontend/components/toolbar/blur-faces-tool.tsx` | Copiar `people-ai-tool.tsx` (ícone com estrela de tool de IA). `Select` blur/pixelate, `Slider` intensidade 1–10, `Slider` margem. `invalid` quando os valores forem inválidos; **Preview** ativo (mostra 1 frame) |
| `frontend/components/toolbar/toolbar.tsx` | `<BlurFacesTool disabled={disabled} />` no ramo `currentIsVideo`, a seguir a `ExtractFramesTool` |
| `frontend/lib/projects.ts` + resultados em `app/dashboard/[pid]/page.tsx` | Se `faces_detected === 0`: aviso "Não foram detetadas caras" (REQ-013) com botões **Manter** e **Descartar** (chama o DELETE do passo 8.4) |
| `frontend/lib/mutations/projects.ts` | Mutation `useDeleteProjectResult` |

### Passo 10 — Testes unitários
- `Tools/blur_faces/test_blur_faces_rules.py` (`unittest`, como `test_trim_rules.py`): `validate`, `expand_box` (cortes nos limites), `blur_kernel` ímpar, `output_name`, `mux_args` por contentor, `duration_ok`.
- `projects/test/blurFaces.test.js` (`node:test`): `validateBlurParams`; `pipelineAccepts([blur], "video")` e não `"image"`; `checkExclusiveTools(["blur_faces","trim"])` recusa.
- Correr:
  ```bash
  cd Tools/blur_faces && python3 -m unittest
  ```
  ```bash
  cd projects && npm test
  ```

### Passo 11 — Teste ponta a ponta: `projects/test/e2e/blur.sh`
Copiar `trim.sh` e acrescentar a chamada em `run.sh`. Cenários (IDs `TST-BLUR-xx`):

| ID | Dado / Quando / Então | Requisitos |
|---|---|---|
| TST-BLUR-01 | Anónimo adiciona `blur_faces` → recusado | BLUR-031 |
| TST-BLUR-02 | `blur_faces` + `trim` na mesma pipeline → recusado | BLUR-040 (4.1.3) |
| TST-BLUR-03 | Free com vídeo com cara → resultado do tipo vídeo, `faces_detected ≥ 1`, quota −1 | BLUR-004–008, 018 |
| TST-BLUR-04 | Vídeo sem caras (`testsrc`) → `faces_detected = 0`; DELETE do resultado → desaparece | BLUR-013, 014 |
| TST-BLUR-05 | Vídeo corrompido (ficheiro truncado) → falha do item, quota devolvida, sem resultado | BLUR-016, 020, 029, 030 |
| TST-BLUR-06 | `ffprobe` ao resultado: mesma duração (±1 s), mesmo contentor e codecs, tem áudio | BLUR-006, 022, 043 |
| TST-BLUR-07 | `sha256` do original antes e depois → igual | BLUR-021 |
| TST-BLUR-08 | Logs do `ws_gateway` → progresso a subir até 100 % com intervalo ≤ 10 s | BLUR-026, 037 |
| TST-BLUR-09 | 8 pedidos em simultâneo → os 8 terminam | BLUR-034 |
| TST-BLUR-10 | Preview → devolve uma imagem | BLUR-010 |

Para o vídeo com cara: `ffmpeg -loop 1 -i cara.jpg -f lavfi -i sine=duration=4 -t 4 -pix_fmt yuv420p -shortest cara.mp4`, com uma imagem de licença livre em `projects/test/e2e/assets/`.

### Passo 12 — Medições (para a §4.4)
- Taxa de deteção: `python3 Tools/blur_faces/eval/eval_detection.py` → ≥ 90 % (REQ-023).
- Tempo de processamento de um vídeo de 1 min e de 10 min (premium) → ≤ 3× (REQ-041).
- Tempo de resposta do `POST /process` com um vídeo grande → ≤ 2 s (REQ-024). Se falhar, fica registado como limitação: o `/process` descarrega os vídeos antes de responder.

### Passo 13 — Teste manual no browser
Perfis anónimo, free e premium; blur e pixelate; preview; vídeo sem caras (manter/descartar); cancelar a meio; copiar o resultado para um novo projeto; descarregar.

### Passo 14 — Documento e PR
1. Completar `docs/UC-VID-004-desfocar-caras.md` com a **§4.4 Realização e verificação** (componentes `W-BLUR`, `P-ROUTES`, `P-RULES`, `MSG`, `FE-TOOL`, `FE-PAGE`, `INFRA`; tabela de testes; estado por requisito), igual à do UC-VID-002.
2. Preencher a §3 (uso de IA) com o que o agente fez e como validaste.
3. Reconstruir e testar tudo:
   ```bash
   docker compose up -d --build blur_faces_tool projects frontend
   ```
   ```bash
   bash projects/test/e2e/run.sh
   ```
4. PR `feat/blur-faces` → `main` no PICTURAS, com um revisor do grupo.

---

## 4. Requisitos que ficam parciais ou como limitação (dizer na defesa)

| Requisito | Situação |
|---|---|
| BLUR-012 (estados) | Como no TRIM-012: o estado só é visível com a página aberta |
| BLUR-024 (≤ 2 s) | Depende do tamanho do vídeo (o `/process` descarrega-o antes de responder) |
| BLUR-033 (temporários) | O resultado e os temporários do worker são apagados; a cópia local do original (`src/`) só é limpa no processamento seguinte |
| BLUR-034 (fila visível) | As 5 réplicas processam em paralelo, mas o estado "em fila" não é mostrado |

## 5. Estimativa

| Passos | Horas |
|---|---|
| 1–3 (branch, protótipo, conjunto de teste) | 3–4 |
| 4–6 (regras, worker, Docker) | 5–6 |
| 7–8 (registos e `projects`) | 2–3 |
| 9 (frontend) | 3–4 |
| 10–13 (testes e medições) | 4–5 |
| 14 (documento e PR) | 2 |
| **Total** | **19–24 h** |
