# RNF de carregamento de ficheiros: resumo para o relatório (Fase 2)

> Ficheiro de trabalho local, **não é para commit**. A evidência versionável está em
> `bench/upload/RESULTS.md` e `bench/upload/results/*.csv`.

## 1. Requisito

**Eficiência de desempenho → utilização de recursos** (ISO/IEC 25010:2011), no carregamento
de ficheiros de média grandes (vídeos até 1 GiB, o limite do perfil premium).

## 2. Diagnóstico (base `0523102`)

Os três serviços Node no caminho do upload guardam o ficheiro inteiro em memória, e o gateway
faz isso antes de verificar o token.

**`api_gateway`**: corpo em memória e token verificado só depois do upload.

```js
// apiGateway/routes/projects.js:23-24
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

// apiGateway/routes/projects.js:458-462
router.post(
  "/:user/:project/video",
  upload.single("video"),   // 1.º recebe o ficheiro todo para memória
  auth.checkToken,          // só depois valida o JWT
```

O gateway constrói depois um `FormData` novo com `req.file.buffer` e envia-o com axios sem
`maxRedirects: 0` (`apiGateway/routes/projects.js:466-488`). Com os redirecionamentos ativos, o
axios passa pelo `follow-redirects`, que guarda uma cópia de todo o corpo para o poder reenviar.

**`projects`**: corpo em memória, uma segunda cópia em disco para o `ffprobe` e o hash calculado
sobre o buffer.

```js
// projects/routes/projects.js:72-73
const storage = multer.memoryStorage();
var upload = multer({ storage: storage });

// projects/routes/projects.js:1309, 1322, 1343
videoMeta = await probeVideoBuffer(req.file.buffer, req.file.originalname);
data.append("file", req.file.buffer, { ... });
const sha = crypto.createHash("sha256").update(req.file.buffer).digest("hex");

// projects/utils/video.js:84-86
async function probeVideoBuffer(buffer, originalname) {
  const tmp = path.join(os.tmpdir(), `${uuidv4()}${path.extname(originalname || ".mp4")}`);
  fs.writeFileSync(tmp, buffer);
```

**`img_storage`**: corpo em memória, enviado ao S3 de uma só vez.

```js
// imageStorageService/route/upload.js:6
const upload = multer({ storage: multer.memoryStorage() });
// imageStorageService/services/uploadImage.js:15
Body: file.buffer,
```

**nginx**: grava o corpo num ficheiro temporário antes de o enviar (`proxy_request_buffering`
está ligado por omissão) e usa o *timeout* padrão de 60 s em `/api-gateway/`.

Consequência medida: um ficheiro de 100 MB custa cerca de 330 MB no gateway e cerca de 210 MB em
cada um dos outros dois serviços, perto de 750 MB no total. Com 1 GB por serviço, a base não aceita
nenhum ficheiro de 500 MB ou mais, nem 4 envios simultâneos de 100 MB: o kernel mata o processo do
gateway por falta de memória.

## 3. Alternativas consideradas

| Alternativa | A favor | Contra |
| --- | --- | --- |
| **A. URL pré-assinado: o browser envia diretamente para o S3 (SeaweedFS)** | Nenhum serviço Node vê os bytes; memória mínima. | A validação (`ffprobe`, codec, duração, limites do perfil) passa para depois do upload: é preciso quarentena e limpeza de objetos inválidos e confirmação assíncrona. Muda o contrato da API e o fluxo do frontend. Expõe o S3 ao browser (CORS, ciclo de vida das ligações). É uma mudança de arquitetura grande. |
| **B. Disco em todos os saltos (`multer.diskStorage` no gateway, no projects e no img_storage)** | Simples; memória constante. | Cada salto só reenvia depois de receber tudo (*store-and-forward*): triplica a escrita em disco e soma a latência de cada salto. Obriga a limpar temporários em três serviços. O gateway continuaria a ler o corpo inteiro antes de decidir. |
| **C. Streaming de ponta a ponta, com um único ficheiro temporário no `projects` (escolhida)** | Memória limitada em todos os saltos. Os saltos correm em paralelo, em *pipeline*. A validação continua antes de guardar. A API e o frontend mantêm o contrato. | Disco temporário no `projects` (até cerca de 1 GB por upload). Código de streams mais delicado: erros, abortos e limpeza. |

## 4. Decisão

Opção **C**, com uma mudança por salto (commit `7590c4a`):

- **nginx**: `proxy_request_buffering off` e *timeouts* de 300 s em `/api-gateway/`.
- **`api_gateway`**: `auth.checkToken` antes de ler o corpo. O pedido é encaminhado em stream
  sem alterações (`apiGateway/utils/forwardUpload.js`), com `maxRedirects: 0` e o upstream
  abortado se o cliente desligar.
- **`projects`**: um *storage engine* do multer (`projects/utils/uploadStorage.js`) escreve o
  ficheiro temporário e calcula o SHA-256 na mesma passagem. O limite do perfil é verificado pelo
  `Content-Length` antes de ler o corpo. O `ffprobe` e o `validateVideo` correm sobre esse
  ficheiro, que segue depois em stream para o `img_storage`. O temporário é sempre apagado.
- **`img_storage`**: o ficheiro vai direto para um `s3.upload` *multipart* (partes de 5 MB, no
  máximo 2 em memória), em `imageStorageService/services/s3StreamStorage.js`.
- **frontend**: barra de progresso nos diálogos de importação e de criar projeto.

O ficheiro temporário fica só no `projects` porque o `ffprobe` precisa de um ficheiro com acesso
aleatório. Num MP4 o índice (`moov`) pode estar no fim do ficheiro.

## 5. Quantificação proposta ao grupo

Medido nesta máquina (ver `bench/upload/RESULTS.md`). Os valores finais estão nas colunas da
direita.

| Campo | Proposta |
| --- | --- |
| **Escala** | Crescimento do pico de memória residente (VmRSS, MB) dos processos Node de **cada** serviço no caminho do upload (`api_gateway`, `projects`, `img_storage`) durante **um** upload. Indicadores complementares: taxa de sucesso com 1 GB por serviço e tempo mediano do upload. |
| **Método** | `bench/upload/measure_upload.py`, com ficheiros de 100, 500 e 950 MB e 5 repetições por tamanho, mais 4 envios simultâneos de 100 MB (3 repetições). Os serviços são reiniciados entre repetições. Limite de 1 GB por serviço sem swap; mesma máquina e mesmos serviços nas duas versões. Conta o **máximo** das repetições. |
| **Valor da base** | 100 MB: até 405 MB num serviço (gateway) e cerca de 750 MB no caminho todo. 500 MB, 950 MB e 4 × 100 MB: 0% de sucesso, porque o gateway é morto pelo kernel ao chegar a 1 GB. |
| **Valor-alvo** | ≤ **150 MB** por serviço para qualquer ficheiro até 1 GiB, e **100%** de sucesso em 950 MB e 4 × 100 MB. |
| **Mínimo aceitável** | ≤ **256 MB** por serviço, ou seja, 25% do **tamanho máximo permitido** (1 GiB), para qualquer ficheiro até esse limite. |
| **Tempo** | No máximo **+10%** face à base onde a base funciona (100 MB: ≤ 2,2 s). Acima disso, débito ≥ 90% do débito da base a 100 MB (≥ cerca de 47 MB/s). |

Resultado da versão final face à proposta:

| Indicador | Final | Alvo | Mínimo |
| --- | --- | --- | --- |
| Pico máximo por serviço, em série (100–950 MB) | 105 MB (`img_storage`, 950 MB) | cumpre | cumpre |
| Pico máximo por serviço, 4 × 100 MB | 146 MB (`img_storage`) | cumpre, com pouca margem | cumpre |
| Sucesso 950 MB / 4 × 100 MB | 5/5 e 12/12 | cumpre | cumpre |
| Tempo a 100 MB | 1,5 s (base: 2,0 s; −25%) | cumpre | cumpre |
| Débito a 500 e 950 MB | 81 e 85 MB/s | cumpre | cumpre |

**Porque não "≤ 25% do tamanho do ficheiro"?** Tomado por ficheiro, esse mínimo seria mais exigente
do que o alvo nos ficheiros pequenos. A 100 MB, o `img_storage` cresce 61 MB, ou seja, 58% do
ficheiro. Falharia o "mínimo", apesar de cumprir os 150 MB, porque esse custo é fixo e não depende
do ficheiro. Usar 25% do tamanho **máximo** permitido mantém a ideia e dá um valor absoluto
verificável.

**"Independente do tamanho do ficheiro"**: se o grupo quiser escrevê-lo, sugiro esta forma
mensurável: a mediana a 950 MB menos a mediana a 100 MB é ≤ 50 MB em cada serviço. Valores
finais: gateway 27, `projects` 47, `img_storage` 41. Cumpre, mas o `projects` fica perto do limite.
O `img_storage` ainda cresce com o tamanho (59 → 77 → 100 MB). A memória é libertada no fim e a
medição não distingue atraso do *garbage collector* de dados vivos.

## 6. Notas para a análise

- Na base, os valores de memória dos casos que falham são um **limite inferior**: o processo morre
  ao chegar a 1 GB, e o tempo é o que demora até ao `502`, não um tempo de upload.
- O *timeout* do nginx (60 s na base, 300 s no final) **não decidiu nenhum resultado nesta
  máquina**. A base falha por falta de memória em menos de 6 s e o upload final mais lento demorou
  14,1 s. Noutra máquina, mais lenta e sem limites de memória, a base falhou com `504` aos cerca de
  64 s.
- O valor *cgroup* do `docker stats` inclui a *page cache*. O `projects` chega aos 578 MB com
  950 MB por causa do ficheiro temporário, mas essa memória é recuperável e não é do processo.
- Regressão: 19/19 verificações passam nas duas versões.
- Efeitos noutros RNF: disco temporário no `projects` (até cerca de 1 GB por upload em simultâneo).
  A validação continua antes de guardar. Há rejeição antecipada pelo `Content-Length` e o token é
  verificado antes do corpo.

## 7. Uso de IA

> Completar com o que o grupo fez nas outras sessões. Abaixo está só o que se passou nesta.

- **Ferramenta**: Claude Code (modelo Claude Opus 5.5), no terminal, com acesso ao repositório e
  ao Docker local.
- **Tarefas apoiadas nesta sessão**:
  - adaptar o procedimento de medição a esta máquina (WSL2/Docker): portos em conflito, limites de
    memória sem swap e projetos Compose separados;
  - correr a regressão e as medições;
  - detetar e contornar um erro no `make_samples.sh` (`pipefail` com `grep -q`);
  - redigir `RESULTS.md` e este resumo.
- **Validação feita por nós**: _[a preencher pelo grupo; por exemplo: revisão do diff de
  `7590c4a`, conferência dos números da tabela com os CSV, repetição de uma medição noutra
  máquina, leitura dos excertos de código citados]_.
