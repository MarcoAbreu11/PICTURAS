# Relatório de alterações — Suporte base a vídeo (Fase 1, primeiro marco)

> Documento interno da equipa. Descreve **o que foi alterado, onde, porquê e como foi verificado**.
> O plano completo está em [`GUIAO_VIDEO.md`](GUIAO_VIDEO.md); este relatório cobre o que já está implementado.

**Data:** 17/10/2026
**Commit base:** `781a63e` (antes das alterações)
**Commits:** `537e8bf` (suporte base a vídeo + guião). A alteração da toolbar (§5.9) ainda **não está em commit**.
**Repositório:** <https://github.com/MarcoAbreu11/PICTURAS>

---

## 1. Resumo

A aplicação passou a aceitar, guardar e reproduzir **vídeos** (`.mp4`, `.webm`, `.mov`) ao lado das imagens.

| Funcionalidade | Estado |
|---|---|
| Upload de vídeo (arrastar, botão ou dentro de `.zip`) | ✅ |
| Limites de tamanho e duração por perfil (anónimo / free / premium) | ✅ |
| Guardar o tipo de cada ficheiro (`media_type`) na base de dados | ✅ |
| Devolver `media_type` em todas as rotas que listam ficheiros | ✅ |
| Reproduzir vídeo na grelha, no carrossel e no preview de upload | ✅ |
| Esconder as tools de imagem quando o item aberto é um vídeo | ✅ (por fazer commit) |
| Processar vídeos (tools de vídeo) | ❌ Etapa seguinte |
| Bloquear no backend o processamento de vídeos com tools de imagem | ❌ Etapa seguinte (`toolCapabilities.js`) |

**Números:** 15 ficheiros existentes alterados, 2 ficheiros de código novos (`projects/utils/media.js`, `frontend/components/media-view.tsx`) e 2 documentos em `docs/`.

---

## 2. Arquitetura — o que mudou e o que não mudou

### 2.1 Ideia

Em vez de criar um modelo separado para vídeos, cada item de um projeto passou a ter um campo
`media_type: "image" | "video"`. Tudo o resto (armazenamento S3, presigned URLs, apagar, download do projeto)
já funcionava com qualquer ficheiro binário e **não precisou de alterações**.

### 2.2 Caminho de um upload de vídeo

```
Browser
  │  ① aceita .mp4/.webm/.mov (também dentro de .zip)
  ▼
nginx  ② client_max_body_size 500M (antes: 1 MB por defeito → erro 413)
  ▼
apiGateway  ③ multer até 500 MB + 413 legível; axios sem o limite de 10 MB
  ▼
projects  POST /:user/:project/img
  │  ④ media_type pela extensão (desconhecida → 400)
  │  ⑤ se vídeo: perfil do utilizador (users-ms) + ffprobe → limites → 413 se exceder
  │  ⑥ grava o item com media_type
  ▼
imageStorageService  ⑦ key S3 com a extensão do nome original (antes: .quicktime para .mov)
  ▼
SeaweedFS  user-<id>/<projeto>/src/<uuid>.mp4
```

### 2.3 Caminho da visualização

```
projects GET /imgs (e /img/:id, /:project, /share/...)  ── devolve media_type
        ▼
frontend ProjectImage ──► MediaView ──► <video> se vídeo, <Image> se imagem
Toolbar ──► se o item aberto for vídeo, esconde as tools de imagem
```

---

## 3. Infraestrutura

### 3.1 `nginx/nginx.conf`
**Problema:** não havia `client_max_body_size`, por isso o nginx usava o limite padrão de **1 MB** e rejeitava
quase todos os vídeos com `413 Request Entity Too Large`.

**Alteração** (bloco `server` HTTPS):
```nginx
client_max_body_size 500M;
proxy_request_buffering off;   # envia o upload para o gateway à medida que chega
proxy_read_timeout 600s;       # uploads e respostas grandes não dão timeout
proxy_send_timeout 600s;
```

### 3.2 `projects/Dockerfile`
Acrescentada a instalação do **ffmpeg** (inclui o `ffprobe`, usado para ler a duração dos vídeos no upload):
```dockerfile
run apt-get update && apt-get install -y --no-install-recommends ffmpeg && rm -rf /var/lib/apt/lists/*
```
O ficheiro original usa terminações de linha **CRLF**; foram mantidas.

---

## 4. Backend

### 4.1 `apiGateway/routes/projects.js`

| Alteração | Porquê |
|---|---|
| `multer({ storage, limits: { fileSize: 500 MB } })` | Sem limite, o gateway aceitava qualquer tamanho em memória |
| Nova função `uploadSingle(field)` que envolve `upload.single` | Quando o ficheiro excede o limite, o multer lança `LIMIT_FILE_SIZE`; agora responde **413 "File too large"** em vez de um erro 500 genérico |
| Rota `POST /:user/:project/img`: `uploadSingle("image")` e verificação `if (!req.file) → 400` | Antes, um pedido sem ficheiro rebentava em `req.file.buffer` |
| `axios.post` para o projects com `maxBodyLength: Infinity, maxContentLength: Infinity` | **O axios em Node corta pedidos acima de 10 MB por defeito**: vídeos maiores falhavam entre o gateway e o projects |

### 4.2 `imageStorageService/route/upload.js`
`multer({ storage: multer.memoryStorage(), limits: { fileSize: 500 MB } })` — limite coerente com o resto da cadeia.

### 4.3 `imageStorageService/services/uploadImage.js`
**Problema:** a key do ficheiro no S3 era gerada com `file.mimetype.split("/")[1]`. Para um `.mov` o MIME é
`video/quicktime`, por isso o ficheiro ficava guardado como `<uuid>.quicktime`.

**Alteração:** a extensão passa a vir do nome original, com o MIME como alternativa:
```js
const ext =
  path.extname(file.originalname || "").slice(1).toLowerCase() ||
  file.mimetype.split("/")[1];
const imageKey = `${projectId}/${stage}/${uuidv4()}.${ext}`;
```

### 4.4 `projects/utils/imageStorage.js`
`post_image` passa `{ maxBodyLength: Infinity, maxContentLength: Infinity }` ao axios, pelo mesmo motivo de §4.1:
os ficheiros que o projects envia para o storage (originais e resultados) podem passar os 10 MB.

### 4.5 🆕 `projects/utils/media.js`
Módulo novo com toda a lógica específica de vídeo do serviço `projects`:

| Função / constante | O que faz |
|---|---|
| `mediaTypeOf(filename)` | Devolve `"image"` (`.png`, `.jpg`, `.jpeg`), `"video"` (`.mp4`, `.webm`, `.mov`) ou `null`. Não distingue maiúsculas de minúsculas |
| `probeVideo(buffer, filename)` | Escreve o vídeo num ficheiro temporário, corre `ffprobe` e devolve `{ duration, width, height }`. Falha se o ficheiro não tiver stream de vídeo (ficheiro corrompido ou falso). Apaga sempre o temporário |
| `VIDEO_LIMITS` | Limites por perfil (ver tabela abaixo) |
| `checkVideoLimits(userType, size, duration)` | Devolve `null` se estiver dentro dos limites ou uma mensagem com o motivo. Um perfil desconhecido é tratado como anónimo |

| Perfil | Tamanho máximo | Duração máxima |
|---|---|---|
| `anonymous` | 20 MB | 15 s |
| `free` | 100 MB | 60 s |
| `premium` | 500 MB | 10 min |

### 4.6 `projects/models/project.js`
No `imgSchema`:
```js
media_type: { type: String, enum: ["image", "video"], default: "image" },
```
O `default: "image"` garante que **os projetos que já existem continuam válidos** sem migração.

### 4.7 `projects/routes/projects.js`

| Zona | Alteração |
|---|---|
| Imports | `mediaTypeOf`, `probeVideo`, `checkVideoLimits` de `utils/media` |
| `multer` (linha ~57) | `limits: { fileSize: 500 MB }` |
| `POST /:user/:project/img` | 1) Determina `media_type` pela extensão; desconhecida → **400 "Unsupported file type"**. 2) Se for vídeo: pede o perfil ao users-ms (`GET /:id/type`, a mesma chamada que a rota `/tool` já fazia), corre `probeVideo` e `checkVideoLimits` → **413** com o motivo. Se o vídeo não for legível → **400 "Invalid or unreadable video file"**. 3) Grava `media_type` no item. 4) Mensagem de nome repetido: "image" → "file" |
| `GET /:user/:project/imgs` | Cada item inclui `media_type` |
| `GET /:user/:project/img/:img` | Inclui `media_type` |
| `GET /:user/:project` | Cada item de `imgs` inclui `media_type` |
| `GET /share/:shareId/project` | Inclui `media_type` nos originais e nos resultados (nos resultados vem do campo `type` do `Result`) |

Nos itens antigos sem o campo, as respostas usam `img.media_type ?? "image"`.

> ⚠️ **Mudança de comportamento:** antes, o backend aceitava qualquer ficheiro (o filtro estava só no frontend).
> Agora, ficheiros sem extensão reconhecida são rejeitados com 400.

---

## 5. Frontend

### 5.1 `lib/utils.ts`
- 🆕 `MEDIA_MIME_TYPES` — mapa extensão → MIME (`png`, `jpg`, `jpeg`, `mp4`, `webm`, `mov`).
- 🆕 `isVideo(nameOrType)` — aceita um MIME (`"video/mp4"`) ou um nome/URL (`"clip.mp4"`, ignora a query string das presigned URLs).
- `extractZipImages` passa a extrair também vídeos. **Correção:** o blob devolvido pelo JSZip vem sem MIME type,
  e os ficheiros extraídos eram depois descartados pelo filtro de tipos; agora o `File` é criado com o tipo deduzido da extensão.

### 5.2 `lib/projects.ts`
`ProjectImage` ganha `media_type?: "image" | "video"` (opcional, para não partir respostas antigas).

### 5.3 `components/app-dropzone.tsx`
- `accept` com `video/mp4` (`.mp4`), `video/webm` (`.webm`) e `video/quicktime` (`.mov`).
- Mensagem do toast de ficheiro inválido atualizada com os novos formatos.

### 5.4 `components/image-submission-area.tsx`
- `compatibleFileTypes` com os três tipos de vídeo.
- Ícone `FileVideo` para vídeos na lista de ficheiros a carregar (`FileImage` para imagens).
- Texto: "Drag and drop images, videos or a .zip".

### 5.5 `components/image-preview.tsx` (preview no hover, antes de carregar)
Se o ficheiro for vídeo, mostra `<video muted controls>` em vez das duas `<Image>` (nítida + fundo desfocado).

### 5.6 🆕 `components/media-view.tsx`
Componente que decide entre imagem e vídeo:

| Prop | Uso |
|---|---|
| `url`, `name` | Origem e nome (o nome serve para deduzir o tipo se `mediaType` não vier) |
| `mediaType` | `"image"` ou `"video"`, vindo do backend |
| `controls` (default `true`) | `false` nas grelhas: o vídeo fica parado no 1.º frame, sem som e sem capturar cliques (`pointer-events-none`), para o clique continuar a abrir o item |
| `className`, `priority`, `onLoaded` | Passados à `<Image>` / `<video>` |

Detalhe: sem controlos, a URL leva `#t=0.1` para o browser mostrar o primeiro frame em vez de um retângulo preto.
O fragmento `#…` não é enviado ao servidor, por isso não invalida a assinatura da presigned URL.

### 5.7 `components/project-page/project-image.tsx`
- As duas `<Image>` foram substituídas por `<MediaView>`.
- Na grelha (`animation = true`) o vídeo aparece sem controlos e com a etiqueta **"Video"**; no carrossel tem controlos.
- O fundo desfocado só é usado em imagens: num vídeo obrigaria a descarregar o vídeo duas vezes.

### 5.8 `components/project-page/add-images-dialog.tsx`
Textos: "Add Images" → **"Add Media"**, "Add more images or videos to your project.", "Files added successfully."

### 5.9 `components/toolbar/toolbar.tsx` *(ainda não está em commit)*
- Lê o item aberto com `useCurrentImage()` (contexto já existente no `ProjectProvider`).
- Se a vista for o carrossel e o item for vídeo, **as 16 tools de imagem não são mostradas**; aparece
  "Video tools coming soon". A lista de tools aplicadas (`AppliedToolsList`) e o botão de limpar mantêm-se,
  para se poder remover tools já adicionadas.
- Na grelha não há alterações: as tools já estavam desativadas nessa vista.

---

## 6. Verificação

| Verificação | Como | Resultado |
|---|---|---|
| Sintaxe dos ficheiros JS do backend | `node --check` num container `node:22-alpine` | ✅ |
| `media.js` com um vídeo real | Vídeo de 2 s gerado com `ffmpeg -f lavfi -i testsrc…`; testados `mediaTypeOf`, `probeVideo` (→ `{duration: 2, width: 320, height: 240}`), `checkVideoLimits` e um ficheiro falso (→ rejeitado) | ✅ |
| Tipos TypeScript do frontend | `npx tsc --noEmit` | ✅ sem erros |
| Lint | `npx eslint` nos ficheiros alterados | ✅ sem avisos |
| Containers com o código novo | `ffprobe` presente no `projects`; `extname` no `img_storage`; `client_max_body_size` no nginx | ✅ |
| Limite do nginx | Upload de 2 MB pelo nginx → chegou ao gateway (401 por falta de sessão, não 413) | ✅ |
| Teste manual no browser | Upload de um vídeo próprio de 14 s numa conta registada: aparece na grelha e toca no carrossel | ✅ (screenshot da equipa) |
| Toolbar escondida em vídeo | Frontend reconstruído; falta confirmar no browser | ⏳ |
| Testes automáticos (jest) | Ainda não existem no repositório | ❌ (ver guião §4.1) |

---

## 7. Problemas encontrados durante o trabalho

| Problema | Causa | Solução |
|---|---|---|
| Vídeos acima de 1 MB davam 413 | nginx sem `client_max_body_size` | §3.1 |
| Vídeos acima de 10 MB falhavam entre serviços | Limite por defeito do axios em Node | §4.1 e §4.4 |
| `.mov` guardado como `.quicktime` | Extensão gerada a partir do MIME | §4.3 |
| Vídeos/imagens dentro de `.zip` eram descartados | Blob do JSZip sem MIME type | §5.1 |
| Depois de mudar o `nginx.conf` o limite continuava | O nginx só lê a configuração no arranque | `docker compose exec nginx nginx -s reload` |
| Erro **502** depois de reconstruir o frontend | O nginx guarda o IP do container antigo | `nginx -s reload` (ou reiniciar o nginx) |
| Alterações no frontend não apareciam | O container corre um build de produção (`bun start`), não `next dev` | `docker compose up -d --build frontend` |
| No teste manual, o Apply com brightness num vídeo terminou em "Processamento cancelado" | As tools atuais só sabem processar imagens | Esperado nesta etapa; ver §8 |

---

## 8. Limitações e próximos passos

1. **Processamento:** o backend ainda envia vídeos para as tools de imagem quando se carrega em Apply.
   O próximo passo é o `projects/utils/toolCapabilities.js` (guião §2.3–2.4): ignorar os vídeos no `/process`
   e não gastar operações diárias com eles.
2. **Validação no frontend:** os limites de duração e tamanho só são verificados no backend (o utilizador só
   vê o erro depois do upload). Falta o `lib/media-limits.ts` (guião §3).
3. **Memória:** os uploads continuam em `memoryStorage` no gateway, no projects e no storage. Um vídeo de
   500 MB ocupa essa memória em cada serviço. É aceitável no MVP; é candidato para a Fase 2 (desempenho).
4. **Codecs:** vídeos HEVC (comuns em iPhone) são aceites, mas podem não tocar no Chrome/Firefox.
5. **Testes automáticos:** jest + supertest para `media.js` e para a rota de upload (guião §4.1).
6. **Tools de vídeo:** etapa seguinte, fora deste relatório.

---

## 9. Como reproduzir

```bash
docker compose up -d --build projects img_storage api_gateway frontend
docker compose exec nginx nginx -s reload
```
Depois, abrir <https://localhost:8080>, criar uma conta, criar um projeto e arrastar um `.mp4`.
Os passos detalhados e a checklist de testes estão no guião (§4.2).
