---
name: testes
description: Correr os testes do PictuRAS (unitários do projects, unitários dos workers Python e ponta a ponta) e registar os resultados no relatório. Usar antes de um commit que mexe em código ou para atualizar o capítulo 10.
---

# Testes do PictuRAS

## Unitários do `projects` (59 testes)

O teste do ciclo de vida das legendas usa a MongoDB do próprio `projects`, numa base temporária que
apaga no fim. Sem `SUBTITLES_TEST_MONGO` esse teste é ignorado e o total desce para 37.

```bash
docker compose up -d projects_mongoDB
cd projects && SUBTITLES_TEST_MONGO=mongodb://127.0.0.1:27018 node --test test/*.test.js
```

Sem Node no anfitrião, correr dentro da imagem, na rede da stack:

```bash
docker run --rm --network picturas_elk --entrypoint sh -v "$PWD/projects":/src:ro \
  -e SUBTITLES_TEST_MONGO=mongodb://projects_mongoDB:27018 picturas-projects:latest -c \
  'cp -r /src /tmp/p && rm -rf /tmp/p/node_modules && ln -s /app/node_modules /tmp/p/node_modules && cd /tmp/p && node --test test/*.test.js'
```

## Unitários dos _workers_ (64 testes)

Dentro das imagens, que já têm FFmpeg e OpenCV:

```bash
docker run --rm --entrypoint sh picturas-video_convert_tool -c "python -m unittest test_convert_rules utils.test_video"
```

Os restantes: `test_trim_rules`, `test_frames`, `test_blur_faces_rules` e `test_subtitles`, nas imagens
respetivas.

## Ponta a ponta (e2e)

Com a stack toda a correr:

```bash
docker compose up -d --build
docker compose restart nginx users subscriptions
BLUR_FACE_VIDEO=/caminho/video_com_pessoas_a_falar.mp4 bash projects/test/e2e/run.sh
```

- Sem `BLUR_FACE_VIDEO`, os testes de deteção de caras e de fala ficam SKIP.
- Se o SeaweedFS falhar com "port 9090 already in use", usar um ficheiro de sobreposição local com
  `ports: !override ["9000:9000", "19090:8888"]` em vez de alterar o `docker-compose.yaml`.
- No fim, `docker compose stop` se a stack não estava a correr antes.

## Registar no relatório

Atualizar `relatorio/capitulos/10-testes-validacao.typ` (linha de cada bateria com a contagem e a data,
totais no fim de 10.2) e a coluna de testes de `relatorio/capitulos/07-rastreabilidade.typ` (7.3). Manter
os totais iguais na Introdução (1.3) e na Conclusão.
