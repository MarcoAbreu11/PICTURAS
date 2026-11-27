#import "../template.typ": *

#set heading(numbering: "A.1.")
#counter(heading).update(0)

= Instruções de execução

#orientacao[
  Indiquem os passos mínimos para lançar a solução a partir do repositório (pré-requisitos, comandos, projeto de teste) e
  para repetir as medições (antes e depois do _refactoring_) (_scripts_, dados, ambiente). Quem avalia, ou a equipa na fase seguinte, deve
  conseguir repetir o que descrevem sem ajuda. No glossário, definam os termos específicos do projeto ou da disciplina
  usados no relatório.
]

== Lançar a solução

Pré-requisitos: Docker Engine e Docker Compose (ou Podman com `podman compose`), cerca de 15 GB de disco e 8 GB de RAM
para a _stack_ completa; Python 3 para os _scripts_ de medição.

```bash
git clone https://github.com/MarcoAbreu11/PICTURAS.git && cd PICTURAS
docker compose down -v --remove-orphans   # só ao substituir uma checkout antiga (mesmo projeto Compose)
docker compose up -d --build
```

A aplicação fica em `https://localhost:8080` (aceitar o certificado autoassinado). Em máquinas com SELinux, juntar
`bench/upload/compose.selinux.yaml` ao `COMPOSE_FILE` (_bind mounts_ com `:z`).

== Testes unitários

Com a _stack_ a correr (as dependências já estão nas imagens dos serviços):

```bash
docker compose exec -T projects npm test        # 27 testes
docker compose exec -T api_gateway npm test     # 3 testes
docker compose exec -T img_storage npm test     # 5 testes
```

== Medições do CAND-1 (carregamento de ficheiros)

Detalhe em `bench/upload/README.md` e `bench/upload/RESULTS.md`. As amostras geram-se com
`bench/upload/make_samples.sh` (100, 500 e 950 MB). Nunca medir a base sem limites de memória.

```bash
export COMPOSE_FILE=docker-compose.yaml:bench/upload/compose.memlimit.yaml
docker compose up -d --build nginx frontend api_gateway ws_gateway seaweedfs img_storage rabbitmq \
  projects projects_mongoDB users users_mongoDB subscriptions subscriptions_mongoDB brightness_tool video_tool
python3 bench/upload/regression.py
python3 bench/upload/measure_upload.py --label final --sizes 100,500,950 --reps 5
python3 bench/upload/measure_upload.py --label final --sizes 100 --reps 3 --concurrency 4
python3 bench/upload/compare.py bench/upload/results/*.csv
```

Para a base, extrair `git archive 0523102` para uma pasta, copiar para lá `bench/upload/`, e correr os mesmos comandos
com `--label baseline` sob outro nome de projeto Compose (`-p picturasbench-base`).

== Medições do CAND-2 (validação de pipelines)

Detalhe em `bench/pipeline/README.md` e `bench/pipeline/RESULTS.md`. Além dos serviços acima, levantar
`contrast_tool` e `border_tool`.

```bash
python3 bench/pipeline/measure_pipeline.py --label final   # API, cerca de 3 min
python3 bench/pipeline/ui_check.py --label final           # editor, cerca de 2 min (Playwright em Docker)
```

== Compilar este relatório

```bash
cd relatorio && typst compile --font-path fonts main.typ
```

= Glossário

#tabela(
  colunas: (4cm, 1fr),
  [Termo], [Definição],
  [_Streaming_], [Processamento de um ficheiro à medida que os _bytes_ chegam, com _buffers_ de tamanho limitado, sem o guardar inteiro em memória.],
  [Contrapressão (_backpressure_)], [Mecanismo dos _streams_ que abranda quem envia quando quem recebe ainda não consumiu os dados.],
  [_Buffering_ do pedido (nginx)], [O nginx recebe o corpo inteiro (em memória ou em disco) antes de o enviar ao serviço seguinte.],
  [VmRSS], [Memória residente de um processo, lida de `/proc/<pid>/status`; a escala do CAND-1 é o seu crescimento durante o upload.],
  [OOM], [_Out of memory_: o _kernel_ termina um processo que excede o limite de memória do contentor.],
  [_Multipart upload_ (S3)], [Envio de um objeto ao S3 em partes independentes (aqui de 5 MB), juntas no fim.],
  [Pipeline], [Sequência ordenada de ferramentas que pertence ao projeto e se aplica a todos os _media_ desse projeto.],
  [Aviso útil antecipado], [Mensagem mostrada antes de qualquer pré-visualização ou execução, que nomeia a ferramenta e diz o que fazer (critério do CAND-2).],
  [Cenário de qualidade (`QS`)], [Descrição verificável de um atributo de qualidade: estímulo, ambiente, artefacto, resposta e medida da resposta.],
  [Tática (`TAT`)], [Decisão de desenho que influencia a resposta de um atributo de qualidade a um estímulo.],
)
