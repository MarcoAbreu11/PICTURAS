# Guião interno — Tools de vídeo (o que cada elemento faz)

> Documento para a equipa. Parte do que já está feito ([`RELATORIO_ALTERACOES_VIDEO.md`](RELATORIO_ALTERACOES_VIDEO.md)):
> upload, armazenamento e reprodução de vídeos. Aqui dividimos as **5 tools de vídeo** pelos 5 elementos.

| Elemento | Tool | Pasta | Parte partilhada que também lhe cabe |
|---|---|---|---|
| **E1** | Cortar excerto | `Tools/video_trim/` | Base comum: `video_handler.py`, correções no `tool_msg.py`/`rabbit_mq.py`, esqueletos das 5 tools, testes pytest |
| **E2** | Converter / comprimir | `Tools/video_convert/` | `toolCapabilities.js` + validação no `/process` e `/preview`; base do frontend (toolbar de vídeo, tipos, hook de duração) |
| **E3** | Extrair frames | `Tools/video_frames/` | Suporte a **vários outputs** por mensagem no `process_msg` e adicionar imagens à biblioteca |
| **E4** | Legendas automáticas | `Tools/video_subtitles/` | Tools de vídeo pagas (`advanced_tools`) e mensagens de limite no frontend |
| **E5** | Desfocar caras | `Tools/video_blur_faces/` | Documento de testes manuais de todas as tools de vídeo |

---

## 0. Regras comuns (todos lêem isto primeiro)

### 0.1 Como uma tool funciona (já é assim nas tools de imagem)

```
projects ──► RabbitMQ  <tool>_queue
             {
               "messageId": "request-…",  "timestamp": "…",  "procedure": "video_trim",
               "parameters": {
                 "inputImageURI":  "./images/users/U/projects/P/src/clip.mp4",
                 "outputImageURI": "./images/users/U/projects/P/out/clip.mp4",
                 …parâmetros da tool…
               }
             }
                  ▼
Tools/video_trim/video_trim.py   lê o ficheiro de input no volume partilhado (/app/images)
                                 corre o ffmpeg / modelo
                                 escreve o ficheiro de output no volume
                  ▼
RabbitMQ  project_queue
             { "correlationId": <messageId>, "status": "success",
               "output": { "type": "video" | "image" | "text", "imageURI": "<caminho do output>" } }
                  ▼
projects.process_msg   passa o output à tool seguinte ou guarda-o como resultado (out/)
```

Pontos importantes:
- **Os nomes dos campos dizem "Image" por razões históricas**, mas contêm caminhos de vídeo. Não os renomeiem: partia as tools de imagem.
- **Se o output mudar de extensão** (ex.: `.mp4` → `.webm`, `.png`, `.srt`), a tool escreve com a extensão nova e devolve esse caminho em `imageURI`. O `process_msg` já usa o caminho devolvido.
- `output.type`:
  - `"video"` — a tool devolveu um vídeo (trim, convert, blur, legendas queimadas);
  - `"text"` — devolveu um ficheiro de texto (legendas `.srt`); a pipeline continua com o vídeo anterior, tal como acontece hoje com o OCR (`text_ai`);
  - `"images"` — **novo**, vários ficheiros de imagem (extrair frames); ver E3.

### 0.2 Estrutura de cada tool

```
Tools/video_<nome>/
├── Dockerfile
├── requirements.txt
└── video_<nome>.py
```

`Dockerfile` (base para todas; E4 e E5 acrescentam as suas dependências):
```dockerfile
FROM python:3.11-slim
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg && rm -rf /var/lib/apt/lists/*
COPY ./utils/requirements.txt utils/requirements.txt
RUN pip install --no-cache-dir -r utils/requirements.txt
COPY video_<nome>/requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY ./video_<nome> .
COPY ./utils utils
CMD ["python", "-u", "video_<nome>.py"]
```

### 0.3 Onde cada tool tem de ser registada

| Ficheiro | Entrada |
|---|---|
| `rabbitMQ/definitions.json` | fila `video_<nome>_queue` em `queues` **e** em `bindings` (copiar `rotate_queue`) |
| `docker-compose.yaml` | serviço `video_<nome>_tool` (copiar `rotate_tool`) |
| `projects/utils/project_msg.js` | `'video_<nome>': 'video_<nome>_queue'` |
| `Tools/utils/tool_msg.py` | `'video_<nome>': 'video_<nome>_queue'` |
| `projects/utils/toolCapabilities.js` | que tipo de ficheiro aceita |
| `frontend/lib/tool-types.ts` | nome em `ToolNames` + interface dos parâmetros |
| `frontend/components/toolbar/toolbar.tsx` | o componente da tool no ramo `currentIsVideo` |

> **Para evitar conflitos de merge, E1 e E2 registam as 5 tools de uma vez no dia 1** (ver §6).
> Depois disso, cada elemento **só mexe na sua pasta e no seu componente do frontend**.

### 0.4 Códigos de erro

| Tool | Códigos |
|---|---|
| `video_trim` | 2000 procedimento errado · 2001 erro a processar · 2002 parâmetros inválidos |
| `video_convert` | 2100 · 2101 · 2102 |
| `video_frames` | 2200 · 2201 · 2202 |
| `video_subtitles` | 2300 · 2301 · 2302 · 2303 sem áudio |
| `video_blur_faces` | 2400 · 2401 · 2402 |

### 0.5 Git

- Um branch por elemento: `feat/video-trim`, `feat/video-convert`, `feat/video-frames`, `feat/video-subtitles`, `feat/video-blur-faces`.
- Pull request para `main` no PICTURAS com pelo menos **um revisor** do grupo.
- Registar no PR que agente de IA foi usado e para quê (o enunciado exige; ver §7).

### 0.6 Testar uma tool sozinha (sem frontend)

Gerar um vídeo de teste com áudio:
```bash
ffmpeg -f lavfi -i testsrc=duration=5:size=640x360:rate=25 -f lavfi -i sine=duration=5 -shortest clip.mp4
```
Correr os testes da tool dentro do container:
```bash
docker compose run --rm video_trim_tool python -m pytest tests
```

---

## E1 — Cortar excerto (`video_trim`) + base comum

### E1.1 Base comum (fazer **primeiro**, os outros dependem disto)

**`Tools/utils/video_handler.py` 🆕**
```python
def probe(path) -> dict            # ffprobe → {duration, width, height, fps, has_audio, vcodec}
def run_ffmpeg(args: list[str])    # subprocess.run(["ffmpeg", "-y", "-loglevel", "error", *args], check=True)
                                   # em erro lança VideoHandlerError com o stderr
def replace_ext(path, ext) -> str  # "./a/b/clip.mp4", "png" → "./a/b/clip.png"
def even(n) -> int                 # H.264 exige largura/altura pares
H264_ARGS = ["-c:v", "libx264", "-pix_fmt", "yuv420p", "-preset", "fast", "-c:a", "aac", "-movflags", "+faststart"]
```

**`Tools/utils/tool_msg.py` ✏️**
- Acrescentar as 5 filas ao dict `queues`.
- **Corrigir o bug do erro:** nas tools atuais, `send_msg(..., 'error', t, None, code, "msg", path)` passa o
  código para o parâmetro `type`, e o envio de erro rebenta. Nas tools de vídeo usar sempre:
  `send_msg(msg_id, resp_id, ts, "error", t, None, err_code=..., err_msg=..., og_img_uri=...)`.
- Aceitar `imageURIs` (lista) para o tipo `"images"` de E3: `send_msg(..., type="images", new_img_uri=None, new_img_uris=[...])`.

**`projects/routes/projects.js` ✏️ (uma linha)** — o projects lê `msg_content.error.msg` mas as tools enviam
`error.message`. Ler `msg_content.error.message ?? msg_content.error.msg`.

**`Tools/utils/rabbit_mq.py` ✏️** — o `BlockingConnection` não envia *heartbeats* enquanto a tool está a processar.
Num vídeo longo (legendas, caras) o RabbitMQ fecha a ligação e a resposta perde-se. No MVP: passar `heartbeat=0`
nos `ConnectionParameters`.

**Esqueletos das 5 tools (dia 1):** criar as 5 pastas com o Dockerfile de §0.2 e um `.py` que responde sempre
erro "not implemented". Assim o `docker compose up` funciona desde o início e cada elemento só substitui o `.py`.

**`Tools/tests/conftest.py` 🆕** — fixture `sample_video(tmp_path, seconds=3, audio=True)` que gera o vídeo com
ffmpeg lavfi (nada de binários no repositório). Os outros elementos reutilizam-na.

### E1.2 A tool

| | |
|---|---|
| **Use case** | Cortar um vídeo, mantendo apenas o excerto entre dois instantes |
| **Aceita / produz** | vídeo → vídeo |
| **Parâmetros** | `start` (s, ≥ 0), `end` (s, > `start`, ≤ duração) |
| **Paga?** | Não (tool básica) |

Implementação (`Tools/video_trim/video_trim.py`):
1. `probe(input)`; validar `0 ≤ start < end ≤ duration` → senão erro 2002 com a mensagem do motivo.
2. `run_ffmpeg(["-ss", start, "-to", end, "-i", input, *H264_ARGS, output])`.
   Recodificar (em vez de `-c copy`) para o corte ser exato ao frame e não ao keyframe.
3. `send_msg(..., "success", t, output, type="video")`.

Frontend — `frontend/components/toolbar/video-trim-tool.tsx` 🆕:
- Copiar `rotate-tool.tsx`.
- `Slider` com **dois pontos** (`value={[start, end]}`), `max` = duração do vídeo (hook `useCurrentVideoDuration` de E2).
- Mostrar os tempos em `mm:ss.s`.

Testes: corte normal (duração ≈ `end - start`), `start ≥ end` → erro, `end` > duração → erro, vídeo sem áudio.

**Feito quando:** num vídeo de 14 s, cortar de 2 s a 6 s dá um resultado de 4 s que toca nos resultados.

---

## E2 — Converter / comprimir (`video_convert`) + orquestração + base do frontend

### E2.1 Backend partilhado

**`projects/utils/toolCapabilities.js` 🆕**
```js
const CAPABILITIES = {
  // tools de imagem atuais: só imagem
  brightness: { accepts: ["image"], produces: "image" }, /* … todas as atuais … */
  video_trim:       { accepts: ["video"], produces: "video" },
  video_convert:    { accepts: ["video"], produces: "video" },
  video_frames:     { accepts: ["video"], produces: "images", terminal: true },
  video_subtitles:  { accepts: ["video"], produces: "video" },   // modo srt devolve texto mas a pipeline segue com o vídeo
  video_blur_faces: { accepts: ["video"], produces: "video" },
};
function validatePipeline(tools, mediaType) // percorre por position; devolve { ok, tool, reason }
// reason ex.: "video_frames must be the last tool", "rotate does not accept video"
```

**`projects/routes/projects.js` ✏️**
- `POST /:user/:project/tool` — se a tool não aceitar nenhum dos tipos presentes no projeto → `400` com o motivo.
- `POST /:user/:project/process` — antes de arrancar, `validatePipeline` por item; itens incompatíveis são
  **ignorados** e contados (`skipped`), e não contam para as operações pagas (`advanced_tool_num`).
- `POST /:user/:project/preview/:img` — num vídeo, enviar `previewSeconds: 3` nos parâmetros; cada tool de vídeo
  processa só os primeiros 3 s quando recebe esse parâmetro (`-t 3` antes do output). Avisar os outros elementos.

### E2.2 Frontend partilhado

- `frontend/lib/tool-types.ts`: os 5 nomes em `ToolNames` e as 5 interfaces de parâmetros (dia 1).
- `frontend/components/toolbar/toolbar.tsx`: no ramo `currentIsVideo`, trocar "Video tools coming soon" pelos 5
  componentes (dia 1, com componentes provisórios que cada elemento substitui).
- 🆕 `frontend/hooks/use-current-video-duration.ts`: cria um `<video>` invisível com a URL do item atual, espera
  `loadedmetadata` e devolve `duration` (para os sliders de E1 e E3).
- `frontend/lib/projects.ts` / página do projeto: mostrar toast "N ficheiros ignorados" quando o `/process` devolver `skipped`.

### E2.3 A tool

| | |
|---|---|
| **Use case** | Converter o formato e/ou comprimir (reduzir resolução ou qualidade) |
| **Aceita / produz** | vídeo → vídeo (pode mudar de extensão) |
| **Parâmetros** | `format`: `"mp4"` \| `"webm"` \| `"mov"` · `resolution`: `"original"` \| `1080` \| `720` \| `480` \| `360` · `quality`: `"high"` \| `"medium"` \| `"low"` |
| **Paga?** | Não |

Implementação:
1. `out = replace_ext(outputImageURI, format)`.
2. Escala só se a resolução pedida for **menor** que a original: `-vf scale=-2:<altura>` (nunca aumentar).
3. Codecs e qualidade:

| format | vídeo | áudio | CRF high / medium / low |
|---|---|---|---|
| mp4, mov | `libx264 -pix_fmt yuv420p` | `aac` | 20 / 26 / 32 |
| webm | `libvpx-vp9 -b:v 0` | `libopus` | 30 / 36 / 42 |

4. Devolver `type="video"` com `imageURI = out`.

Frontend — `video-convert-tool.tsx`: três `Select` (formato, resolução, qualidade). Mostrar a resolução atual do vídeo.

Testes: mp4→webm muda codec e extensão; 720 num vídeo de 360 não aumenta; `low` gera ficheiro menor que `high`.

**Feito quando:** um `.mov` de 1080p convertido para `mp4 / 480 / low` fica bastante mais pequeno e toca no Chrome.

---

## E3 — Extrair frames (`video_frames`) + vários outputs

### E3.1 A tool

| | |
|---|---|
| **Use case** | Extrair frames de um vídeo como imagens para a biblioteca do utilizador |
| **Aceita / produz** | vídeo → **várias imagens**; tem de ser a **última tool** da pipeline |
| **Parâmetros** | `mode`: `"interval"` (uma imagem a cada `every` s) \| `"count"` (`count` imagens igualmente espaçadas) \| `"times"` (lista `times` de instantes) · `format`: `"png"` \| `"jpg"` · `addToProject`: bool |
| **Limite** | no máximo 50 frames por vídeo (erro 2202 acima disso) |
| **Paga?** | Não |

Implementação:
1. Calcular os instantes a partir do `mode` e da duração (`probe`).
2. Para cada instante: `run_ffmpeg(["-ss", t, "-i", input, "-frames:v", "1", f"{base}_frame_{i:03d}.{format}"])`,
   com `base = outputImageURI` sem extensão.
3. `send_msg(..., type="images", new_img_uris=[...])` com a lista de caminhos.

### E3.2 Vários outputs no `projects` (`process_msg`)

Hoje o `process_msg` assume **um** ficheiro de output por mensagem. Acrescentar o ramo `type === "images"`:
1. Para cada caminho em `msg_content.output.imageURIs`: `post_image(..., "out", …)` e `Result.create({ type: "image", … })`.
2. Se `addToProject` estiver ativo: fazer também upload para `src` e acrescentar a `project.imgs` com
   `media_type: "image"` (reaproveitar o código da rota `POST /img`; extrair para uma função `addFileToProject`).
3. Tratar como fim da pipeline (`terminal`), incluindo o *commit* do run (`committedToken`), como já acontece no último passo.
4. Preview: mostrar só o primeiro frame (`urls.imageUrl`).

### E3.3 Frontend

- `video-frames-tool.tsx`: `Select` do modo; conforme o modo, um `Input` (segundos ou nº de frames) ou uma lista de
  instantes; `Checkbox` "Add frames to project".
- Os resultados já aparecem como imagens na vista de resultados.

Testes: `count=5` gera 5 ficheiros; `interval=1` num vídeo de 3 s gera 3; mais de 50 → erro; `addToProject` acrescenta
os itens ao projeto (teste no `projects`).

**Feito quando:** extrair 5 frames de um vídeo e vê-los como imagens no projeto, prontos para usar as tools de imagem.

---

## E4 — Legendas automáticas (`video_subtitles`)

| | |
|---|---|
| **Use case** | Gerar legendas a partir do áudio, mantendo o idioma original ou traduzindo para inglês |
| **Aceita / produz** | vídeo → vídeo com legendas (`mode: "burn"`) **ou** ficheiro `.srt` (`mode: "srt"`, `type: "text"`) |
| **Parâmetros** | `language`: `"original"` \| `"en"` · `mode`: `"burn"` \| `"srt"` |
| **Paga?** | **Sim** — acrescentar a `advanced_tools` em `projects/routes/projects.js` (anónimos não podem usar) |

Dependências:
- `faster-whisper` (Whisper otimizado para CPU) no `requirements.txt`; modelo `small` com `compute_type="int8"`.
- O modelo (~500 MB) é descarregado na primeira utilização: montar um volume `whisper_models:/root/.cache` no
  serviço do compose para não o descarregar a cada arranque.

Implementação:
1. `probe(input)`; sem áudio → erro 2303 "Video has no audio track".
2. `model.transcribe(input, task="translate" if language == "en" else "transcribe", vad_filter=True)`.
   O Whisper só traduz **para inglês**, o que coincide com o use case.
3. Escrever os segmentos num `.srt` (`00:00:01,000 --> 00:00:03,500`).
4. `mode == "srt"`: devolver `replace_ext(output, "srt")` com `type="text"`.
   `mode == "burn"`: `run_ffmpeg(["-i", input, "-vf", f"subtitles={srt}", *H264_ARGS, output])` e `type="video"`.
5. Carregar o modelo **uma vez** no `__init__`, não por mensagem.

Frontend — `video-subtitles-tool.tsx`: dois `Select` (idioma, modo), ícone com a estrela das tools de IA
(como `text-ai-tool.tsx`) e aviso de que pode demorar.

Parte partilhada de E4: nas mensagens de erro do frontend (`lib/error-messages.ts`), mensagem clara quando um anónimo
tenta usar uma tool paga de vídeo ou quando acabam as operações diárias.

Testes: vídeo de teste com fala (gerar com `espeak-ng` + ffmpeg, ou um clip curto com licença livre em `Tools/tests/assets/`);
`srt` bem formado; `burn` mantém duração; vídeo sem áudio → 2303.

**Feito quando:** um vídeo em português gera um `.srt` em português e, com `language="en"`, um vídeo com legendas em inglês.

---

## E5 — Desfocar caras (`video_blur_faces`)

| | |
|---|---|
| **Use case** | Desfocar automaticamente as caras presentes num vídeo |
| **Aceita / produz** | vídeo → vídeo |
| **Parâmetros** | `strength`: 1–10 (intensidade do desfoque) · `padding`: % de margem à volta da cara (default 20) |
| **Paga?** | **Sim** (`advanced_tools`) |

Dependências: `opencv-python-headless`. Detetor **YuNet** (`cv2.FaceDetectorYN`): descarregar o modelo
`face_detection_yunet_2023mar.onnx` (≈ 230 KB) no Dockerfile para `Tools/video_blur_faces/models/`.

Implementação:
1. `cv2.VideoCapture(input)`, ler `fps`, largura e altura; `cv2.VideoWriter` para um `.mp4` temporário sem áudio.
2. Para cada frame: detetar caras **a cada 3 frames** e reutilizar as caixas nos frames intermédios (3× mais rápido
   e evita "piscar"); alargar cada caixa com o `padding`; aplicar `cv2.GaussianBlur` (kernel proporcional a `strength`
   e ao tamanho da cara) só nessa região.
3. Juntar o áudio original e recodificar para H.264:
   `run_ffmpeg(["-i", tmp, "-i", input, "-map", "0:v", "-map", "1:a?", *H264_ARGS, output])`.
4. Respeitar `previewSeconds` (parar ao fim de `fps × previewSeconds` frames).

Frontend — `video-blur-faces-tool.tsx`: `Slider` de intensidade e de margem, ícone de tool de IA.

Parte partilhada de E5: `docs/testes-manuais-video.md` com a checklist de todas as tools (ver §5),
preenchida no fim com os resultados e screenshots.

Testes: um vídeo gerado a partir de uma imagem com uma cara (ex.: `ffmpeg -loop 1 -i face.jpg -t 2 face.mp4`, imagem com licença livre em
`Tools/tests/assets/`) → a região da cara muda e o resto não; vídeo sem caras → igual ao original (exceto recodificação).

**Feito quando:** num vídeo com pessoas, as caras saem desfocadas ao longo de todo o vídeo e o áudio mantém-se.

---

## 5. Testes manuais (E5 coordena, cada um testa a sua tool)

| Teste | Esperado |
|---|---|
| Cada tool sozinha num vídeo | Resultado correto e reproduzível na vista de resultados |
| `trim → blur_faces → convert(webm)` | Os três passos aplicados, resultado `.webm` |
| `trim → frames(addToProject)` | Frames do excerto aparecem como imagens no projeto |
| `subtitles(srt)` seguido de `convert` | Resultado com o `.srt` e o vídeo convertido |
| `frames` seguido de outra tool | Bloqueado com mensagem "must be the last tool" |
| `rotate` (tool de imagem) num projeto só com vídeos | Bloqueado / ignorado com aviso |
| Anónimo tenta legendas ou caras | Bloqueado (tool paga) |
| Free: legendas consomem operações diárias | Contador desce |
| Preview num vídeo | Só os primeiros 3 s, rápido |
| Cancelar a meio de um vídeo longo | Processamento cancelado sem resultados parciais |

---

## 6. Calendário

| Quando | E1 | E2 | E3 | E4 | E5 |
|---|---|---|---|---|---|
| **Dia 1** | `video_handler.py`, correções em `tool_msg.py`/`rabbit_mq.py`, esqueletos das 5 pastas, filas e serviços no compose | `toolCapabilities.js`, tipos e toolbar com os 5 componentes provisórios | Estudar `process_msg` e desenhar o tipo `"images"` | Protótipo do Whisper fora do Docker | Protótipo do YuNet fora do Docker |
| **Dias 2–4** | `video_trim` + testes + componente | `video_convert` + validação no `/process` | `video_frames` + `process_msg` + `addFileToProject` | `video_subtitles` + `advanced_tools` | `video_blur_faces` |
| **Dia 5** | Revisão de PRs | Revisão de PRs | Revisão de PRs | Revisão de PRs | Testes manuais (§5) com todos |

**Dependências:** toda a gente depende do **dia 1 de E1 e E2**. E3 precisa da extensão do `send_msg` (E1) para o tipo `"images"`.

---

## 7. Registo do uso de IA (exigido pelo enunciado)

Cada elemento acrescenta à descrição do seu PR:
- que agente/ferramenta usou e em que partes (ex.: "gerou o primeiro rascunho do `video_trim.py`");
- o que alterou à mão depois e porquê;
- como validou (testes que correu, teste manual, quem reviu).
