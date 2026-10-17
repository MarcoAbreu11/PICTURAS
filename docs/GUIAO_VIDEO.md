# Guião interno — Suporte a vídeo (Fase 1, base sem tools)

> Documento para a equipa. Cobre **apenas a base**: carregar, guardar, listar, ver, descarregar e apagar
> vídeos, e preparar o sistema para receber ferramentas de vídeo.
> **As tools (adaptar as existentes e criar as de vídeo) ficam para uma etapa seguinte** — ver §6.

---

## 0. Visão geral

### 0.1 Ideia central

1. **"Imagem" passa a "media".** Cada item de um projeto ganha `media_type: "image" | "video"`.
   Projetos antigos continuam válidos (default `"image"`).
2. **O caminho do ficheiro aceita vídeos de ponta a ponta**: nginx → apiGateway → projects → imageStorageService → SeaweedFS.
   Hoje há três limites que partem com vídeo (nginx 1 MB, axios 10 MB, extensão errada na key S3).
3. **O frontend mostra vídeos** com `<video controls>` em vez de `<Image>`, aceita-os no upload e dentro de `.zip`.
4. **Processamento**: como ainda não há tools que aceitem vídeo, o `projects` passa a ter uma
   **tabela de capacidades** (que tool aceita que tipo). Nesta etapa todas as tools aceitam só `image`, por isso:
   - ao processar, os vídeos são **ignorados** (não são enviados para nenhuma fila) e o frontend avisa;
   - quando as tools de vídeo forem feitas, basta acrescentá-las à tabela — a orquestração já está pronta.

### 0.2 Fluxo (★ = ponto novo/alterado)

```
Upload
Browser ★aceita mp4/webm/mov ──► nginx ★body 500M ──► apiGateway ★multer/axios limits
        ──► projects POST /img ★deteta media_type, valida tamanho/duração por perfil
        ──► imageStorageService ★extensão correta na key ──► SeaweedFS  user-<id>/<project>/src/<uuid>.mp4

Ver / listar
Browser ──► projects GET /imgs ★devolve media_type ──► presigned URL ──► ★<video controls>

Processar
Browser ──► projects POST /process
        ★ para cada item: tools compatíveis com media_type?  não → item ignorado (contado na resposta)
        sim → fluxo atual inalterado (RabbitMQ → tool → project_queue → out/)
```

### 0.3 Pastas e ficheiros tocados

```
picturas-27/
├── nginx/nginx.conf                              ✏️ limite de body e timeouts
├── apiGateway/routes/projects.js                 ✏️ multer limits + axios maxBodyLength
├── imageStorageService/
│   ├── route/upload.js                           ✏️ multer limits
│   └── services/uploadImage.js                   ✏️ extensão a partir do nome original
├── projects/
│   ├── Dockerfile                                ✏️ instalar ffmpeg (ffprobe)
│   ├── package.json                              ✏️ jest + supertest
│   ├── models/project.js                         ✏️ media_type
│   ├── routes/projects.js                        ✏️ upload, imgs, process, preview, assistente
│   ├── utils/imageStorage.js                     ✏️ axios maxBodyLength
│   ├── utils/media.js                            🆕 tipo, ffprobe, limites por perfil
│   ├── utils/toolCapabilities.js                 🆕 que tool aceita que tipo
│   └── test/                                     🆕 testes jest
└── frontend/
    ├── lib/projects.ts                           ✏️ media_type nas interfaces
    ├── lib/utils.ts                              ✏️ zip com vídeos, isVideo()
    ├── lib/media-limits.ts                       🆕 limites por perfil (espelho do backend)
    ├── components/app-dropzone.tsx               ✏️ accept vídeo
    ├── components/image-submission-area.tsx      ✏️ tipos + validação de duração/tamanho
    ├── components/image-preview.tsx              ✏️ <video> no preview do upload
    ├── components/media-view.tsx                 🆕 <Image> ou <video>
    ├── components/project-page/project-image.tsx       ✏️ usa MediaView
    ├── components/project-page/project-image-list.tsx  ✏️ usa MediaView
    ├── components/project-page/add-images-dialog.tsx   ✏️ textos/tipos
    └── components/toolbar/toolbar.tsx            ✏️ aviso/desativar tools num vídeo
```

`Tools/`, `rabbitMQ/definitions.json` e `docker-compose.yaml` **não mudam** nesta etapa.

### 0.4 Decisões a fechar em equipa (proposta por defeito)

| Decisão | Proposta |
|---|---|
| Formatos aceites | `.mp4`, `.webm`, `.mov` |
| Limites por perfil | anónimo: 20 MB / 15 s · free: 100 MB / 60 s · premium: 500 MB / 10 min |
| Vídeos no processamento (sem tools) | ignorados, com contagem na resposta e aviso no frontend |
| Assistente IA em vídeo | indisponível (400) |

---

## 1. Infraestrutura

### 1.1 `nginx/nginx.conf`
Não há `client_max_body_size` → limite padrão **1 MB** → upload de vídeo dá `413`.
No bloco `server`:
```nginx
client_max_body_size 500M;
proxy_request_buffering off;
proxy_read_timeout 600s;
proxy_send_timeout 600s;
```

### 1.2 `apiGateway/routes/projects.js`
- Linha 24: `multer({ storage, limits: { fileSize: 500 * 1024 * 1024 } })`.
- Rota `POST /:user/:project/img` (~409), no `axios.post` para o projects:
  `maxBodyLength: Infinity, maxContentLength: Infinity`.
  **O axios em Node corta pedidos acima de 10 MB por defeito.**
- Tratar o erro do multer `LIMIT_FILE_SIZE` → `413` com mensagem legível.

### 1.3 `imageStorageService/route/upload.js`
`multer({ storage: multer.memoryStorage(), limits: { fileSize: 500 * 1024 * 1024 } })`.

### 1.4 `imageStorageService/services/uploadImage.js`
A key usa `file.mimetype.split("/")[1]` → `video/quicktime` dá `.quicktime`. Trocar por:
```js
const path = require("path");
const ext = path.extname(file.originalname).slice(1).toLowerCase() || file.mimetype.split("/")[1];
const imageKey = `${projectId}/${stage}/${uuidv4()}.${ext}`;
```
Presigned URLs (`getPresignedUrl.js`) já servem vídeo; o browser faz *range requests* sozinho.

### 1.5 `projects/utils/imageStorage.js`
Em `post_image`: terceiro argumento `{ maxBodyLength: Infinity, maxContentLength: Infinity }`.

### 1.6 `projects/Dockerfile`
```dockerfile
FROM node
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg && rm -rf /var/lib/apt/lists/*
```
(precisamos do `ffprobe` para ler duração/resolução no upload).

---

## 2. Serviço `projects`

### 2.1 `projects/models/project.js`
No `imgSchema`:
```js
media_type: { type: String, enum: ["image", "video"], default: "image" },
```

### 2.2 🆕 `projects/utils/media.js`
```js
const IMAGE_EXT = [".png", ".jpg", ".jpeg"];
const VIDEO_EXT = [".mp4", ".webm", ".mov"];

function mediaTypeOf(filename) { /* "image" | "video" | null pela extensão */ }

async function probeVideo(buffer) {
  // escreve para os.tmpdir(), corre
  // ffprobe -v error -show_entries format=duration:stream=width,height -of json <tmp>
  // apaga o tmp e devolve { duration, width, height }
}

const VIDEO_LIMITS = {
  anonymous: { maxBytes: 20e6,  maxSeconds: 15 },
  free:      { maxBytes: 100e6, maxSeconds: 60 },
  premium:   { maxBytes: 500e6, maxSeconds: 600 },
};

function checkVideoLimits(userType, sizeBytes, durationSec) {
  // devolve null se ok, ou string com o motivo
}

module.exports = { mediaTypeOf, probeVideo, VIDEO_LIMITS, checkVideoLimits };
```

### 2.3 🆕 `projects/utils/toolCapabilities.js`
```js
// Todas as tools atuais só aceitam imagem. As tools de vídeo entram aqui mais tarde.
const CAPABILITIES = {
  border: ["image"], brightness: ["image"], contrast: ["image"], cut: ["image"],
  scale: ["image"], saturation: ["image"], binarization: ["image"], rotate: ["image"],
  resize: ["image"], watermark: ["image"], cut_ai: ["image"], upgrade_ai: ["image"],
  bg_remove_ai: ["image"], text_ai: ["image"], obj_ai: ["image"], people_ai: ["image"],
  expand_ai: ["image"],
};

function pipelineAccepts(tools, mediaType) {
  // true se TODAS as tools aceitam mediaType (procedure desconhecida → false)
}

module.exports = { CAPABILITIES, pipelineAccepts };
```
> Quando houver tools que mudam o tipo (ex.: extrair frame de um vídeo → imagem), isto evolui para
> `{ accepts, produces }` e `pipelineAccepts` passa a percorrer as tools por `position`.

### 2.4 `projects/routes/projects.js` — alterações por zona

| Zona (linha aprox.) | Alteração |
|---|---|
| linha 56 `upload` | `multer({ storage, limits: { fileSize: 500 * 1024 * 1024 } })` |
| `POST /:user/:project/img` (~1171) | 1) `media_type = mediaTypeOf(req.file.originalname)`; `null` → `400 "Unsupported file type"`. 2) Se `video`: obter `type` do caller em `users_ms + ${callerId}/type` (como já faz a rota `/tool`), `probeVideo(req.file.buffer)`, `checkVideoLimits` → `413` com o motivo. 3) No `project.imgs.push` acrescentar `media_type`. 4) Mensagem "image with that name" → "file with that name". |
| `GET /:user/:project/img/:img` (~848) | acrescentar `media_type: img.media_type ?? "image"` à resposta |
| `GET /:user/:project/imgs` (~872) | idem em cada item |
| `GET /share/:shareId/project` (~626) e `GET /:user/:project` (~776) | se devolverem `imgs`, garantir que `media_type` vai incluído |
| `function advanced_tool_num` (~107) | `adv_ops` deve multiplicar só pelos itens que vão de facto ser processados (`processable.length`, ver linha abaixo), senão um vídeo ignorado gasta operações |
| `POST /:user/:project/process` (~1378) | no início: `const processable = project.imgs.filter(i => pipelineAccepts(project.tools, i.media_type ?? "image"))`; se `processable.length === 0` → `400 { message: "No file is compatible with the selected tools", skipped }`. Dentro de `startProcessing` iterar `processable` em vez de `project.imgs`. Responder `201` com header/JSON `skipped: n`. |
| `process_msg` (~152) — fim de execução | `Process.countByProjectAndToken` já só conta os processos criados, por isso ignorar vídeos não bloqueia o commit. Nada a mudar. |
| `POST /:user/:project/preview/:img` (~1017) | se `img.media_type === "video"` e `!pipelineAccepts(...)` → `400 "Preview not available for this file"` antes de descarregar o ficheiro |
| assistente: rotas que usam `extractImageFeatures` / `applyLocalToolsWithSharp` (~2317–2440) | se o item for vídeo → `400 "Assistant not available for video"` (o `sharp` rebenta com vídeo) |
| `DELETE /:user/:project/img/:img` (~1783), download zip (~907) | já funcionam com qualquer ficheiro — só testar |

### 2.5 `projects/package.json`
`devDependencies`: `jest`, `supertest`; script `"test": "jest"`.

---

## 3. Frontend (Next.js)

| Ficheiro | Alteração |
|---|---|
| `lib/projects.ts` | `ProjectImage` → `media_type?: "image" \| "video"`; no `useProcessProject` (ou equivalente) ler `skipped` da resposta para o toast |
| `lib/utils.ts` | `extractZipImages`: regex `/\.(png\|jpe?g\|mp4\|webm\|mov)$/i`; o blob do JSZip vem sem MIME → criar o `File` com `type` deduzido da extensão. Novo `isVideo(nameOrType: string)` |
| 🆕 `lib/media-limits.ts` | mesmos `VIDEO_LIMITS` do backend, para feedback imediato (o backend valida sempre) |
| `components/app-dropzone.tsx` | `accept` + `"video/mp4": [".mp4"], "video/webm": [".webm"], "video/quicktime": [".mov"]`; texto do toast |
| `components/image-submission-area.tsx` | `compatibleFileTypes` + vídeos; validar tamanho e duração (criar `<video>` com `URL.createObjectURL`, esperar `loadedmetadata`, ler `duration`) contra `media-limits` do perfil da sessão; ícone `FileVideo` para vídeos; textos "images or videos" |
| `components/image-preview.tsx` | se `isVideo(file.type)` → `<video src={blobUrl} muted controls className=…/>` |
| 🆕 `components/media-view.tsx` | props `{ url, name, mediaType, className, onLoaded }` → `<Image unoptimized …/>` ou `<video src={url} controls preload="metadata" onLoadedData={onLoaded} …/>` |
| `components/project-page/project-image.tsx` | trocar os dois `<Image>` por `MediaView`; para vídeo não usar a camada *blur* (é um 2.º download do vídeo); `setLoaded` via `onLoaded`; badge "Video" no canto |
| `components/project-page/project-image-list.tsx` | diálogo de preview (~294) e grelhas → `MediaView`; nos resultados usar o tipo do item original |
| `components/project-page/add-images-dialog.tsx` | textos e tipos aceites |
| `components/toolbar/toolbar.tsx` | se o item selecionado (vista individual) for vídeo → `disabled = true` e mostrar nota "Video tools coming soon"; toast após processar quando `skipped > 0` |

---

## 4. Testes

Hoje **não existe nenhum teste automático** no repositório.

### 4.1 🆕 `projects/test/` (jest)
- `media.test.js` — `mediaTypeOf` (extensões, maiúsculas, desconhecidas) e `checkVideoLimits` por perfil e fronteiras.
- `toolCapabilities.test.js` — `pipelineAccepts`: imagem + tools atuais → true; vídeo + qualquer tool atual → false; procedure desconhecida → false.
- `probe.test.js` — gera um vídeo de 2 s com
  `ffmpeg -f lavfi -i testsrc=duration=2:size=320x240:rate=10 clip.mp4` em `beforeAll` (sem binários no repo)
  e confirma `duration ≈ 2`, `width 320`. Saltar o teste se não houver ffmpeg.
- `upload.test.js` (supertest, com `jest.mock` de `utils/imageStorage` e do axios para users-ms):
  tipo inválido → 400; vídeo acima do limite do anónimo → 413; vídeo válido → 204 e `media_type: "video"` gravado.
- Correr: `docker compose run --rm projects npm test`.

### 4.2 Testes manuais (checklist para a equipa)
- [ ] Upload `.mp4`, `.webm`, `.mov` (cada perfil) — aparece na grelha e toca.
- [ ] Vídeo acima do limite → mensagem clara (frontend e, forçando, backend).
- [ ] `.zip` com imagens + vídeos.
- [ ] Ver vídeo em vista individual e no diálogo de preview.
- [ ] Projeto misto: processar → imagens processadas, vídeos ignorados, toast com contagem, sem gastar operações pelos vídeos.
- [ ] Projeto só com vídeos: processar → 400 tratado no frontend.
- [ ] Preview e assistente num vídeo → bloqueados com mensagem.
- [ ] Apagar vídeo; descarregar projeto (zip).
- [ ] Projeto partilhado (read/edit) com vídeos.
- [ ] Vídeo de ~400 MB como premium passa nginx + gateway + storage.

---

## 5. Ordem sugerida

| # | Tarefa | Secções | Depende de |
|---|---|---|---|
| 1 | Infra de upload (nginx, gateway, storage, Dockerfile) | §1 | — |
| 2 | `media.js` + `toolCapabilities.js` + testes unitários | §2.2, §2.3, §4.1 | — |
| 3 | Rotas do `projects` + modelo | §2.1, §2.4 | 2 |
| 4 | Frontend: `MediaView`, upload, zip, listas | §3 | contrato de §2.4 (`media_type`) |
| 5 | Frontend: toolbar e toasts de `skipped` | §3 | 3 |
| 6 | Testes manuais | §4.2 | tudo |

**Primeiro marco:** passos 1 + 3 (só upload/imgs) + `MediaView` → carregar um `.mp4` e vê-lo a tocar no projeto.

---

## 6. Para mais tarde — tools de vídeo (fora deste guião)

Pontos de ligação já preparados por esta etapa:
- `toolCapabilities.js` — basta acrescentar `"video"` às tools que o suportarem / novas entradas.
- Contrato RabbitMQ (`projects/utils/project_msg.js` ↔ `Tools/utils/tool_msg.py`) — continuará a usar caminhos no volume `image_data`; nessa altura acrescentar `mediaType` aos `parameters`.
- Bugs a corrigir nessa altura em `Tools/utils/tool_msg.py`: as tools chamam `send_msg` de erro com argumentos
  posicionais que caem em `type` (o envio de erro lança exceção); e o `projects` lê `error.msg` mas as tools enviam `error.message`.
