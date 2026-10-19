#!/usr/bin/env bash
# Testes ponta a ponta das ferramentas de vídeo (UC-VID-002, UC-VID-003, UC-VID-004 e UC-VID-005).
# Requer a stack a correr (docker compose up -d). Uso, na raiz do repositório:
#   bash projects/test/e2e/run.sh
# Opcional (UC-VID-004): BLUR_FACE_VIDEO=/caminho/video_com_caras.mp4 bash projects/test/e2e/run.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap '[ -n "${KEEP_WORK:-}" ] || rm -rf "$WORK"' EXIT
chmod 777 "$WORK"
cp "$HERE"/frames.sh "$HERE"/trim.sh "$HERE"/convert.sh "$HERE"/blur.sh "$WORK"/
# vídeo com caras para a desfocagem (opcional; não se guarda nenhum no repositório)
if [ -n "${BLUR_FACE_VIDEO:-}" ]; then cp "$BLUR_FACE_VIDEO" "$WORK/cara.mp4"; fi

NET=picturas_elk
CURL=(docker run --rm --network "$NET" -v "$WORK":/media curlimages/curl:8.10.1)

echo "== A gerar vídeos de teste =="
docker run --rm -v "$WORK":/out --entrypoint sh picturas-trim_tool -c '
  cd /out &&
  ffmpeg -v error -y -f lavfi -i testsrc=duration=10:size=320x240:rate=10 -f lavfi -i sine=duration=10 \
         -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest aula.mp4 &&
  ffmpeg -v error -y -f lavfi -i testsrc2=duration=3:size=640x360:rate=25 -pix_fmt yuv420p curto.mp4 &&
  ffmpeg -v error -y -f lavfi -i testsrc=size=200x200 -frames:v 1 foto.png &&
  for i in 1 2 3 4 5 6; do cp curto.mp4 q$i.mp4; done &&
  chmod 666 *'

echo "== A criar utilizadores de teste =="
STAMP=$(date +%s)
new_user() {
  "${CURL[@]}" -sk -X POST https://users:10001/ -H 'Content-Type: application/json' -d "$1" \
    | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p' | head -1
}
FREE=$(new_user "{\"name\":\"E2E\",\"email\":\"e2e.$STAMP@example.com\",\"password\":\"Teste1234!\",\"type\":\"free\"}")
ANON=$(new_user '{"type":"anonymous"}')
# a desfocagem gasta operações: utilizador próprio, para não depender do teste de frames
BLUR_USER=$(new_user "{\"name\":\"E2E Blur\",\"email\":\"e2e.blur.$STAMP@example.com\",\"password\":\"Teste1234!\",\"type\":\"free\"}")
echo "free=$FREE anon=$ANON blur=$BLUR_USER"

echo; echo "######## UC-VID-003 — Extrair frames ########"
docker run -d --name e2e-frames --network "$NET" -v "$WORK":/media curlimages/curl:8.10.1 \
  sh /media/frames.sh "$FREE" "$ANON" >/dev/null
until docker logs e2e-frames 2>&1 | grep -q "READY_FOR_UNSET\|^RESULT"; do sleep 1; done
PID_B=$(docker logs e2e-frames 2>&1 | sed -n 's/^READY_FOR_UNSET \(.*\)/\1/p')
if [ -n "$PID_B" ]; then
  # simula um vídeo antigo sem duração guardada: o worker é que deteta o instante inválido
  docker exec picturas-projects_mongoDB-1 mongo --quiet --port 27018 project --eval \
    "db.projects.updateOne({_id:ObjectId('$PID_B'),'imgs.og_uri':/curto\\.mp4\$/},{\$unset:{'imgs.\$.duration':''}})" >/dev/null
  touch "$WORK/go"
fi
until docker logs e2e-frames 2>&1 | grep -q "^RESULT"; do sleep 1; done
docker logs e2e-frames 2>&1 | grep -v READY_FOR_UNSET
FRAMES_RESULT=$(docker logs e2e-frames 2>&1 | grep "^RESULT")
docker rm -f e2e-frames >/dev/null

echo; echo "######## UC-VID-002 — Cortar vídeo ########"
"${CURL[@]}" sh /media/trim.sh "$FREE" "$ANON" | tee "$WORK/trim.log"
TRIM_RESULT=$(grep "^RESULT" "$WORK/trim.log")

echo; echo "== TST-TRIM-14: duração e codecs do vídeo cortado (TRIM-022, TRIM-044) =="
URL=$(sed 's/\\u0026/\&/g' "$WORK/trim_url.txt")
# a ligação é pública (nginx em localhost:8080): descarrega-se a partir do anfitrião
curl -sk -o "$WORK/cortado.mp4" "$URL"
docker run --rm -v "$WORK":/w --entrypoint ffprobe picturas-trim_tool \
  -v error -show_entries format=duration:stream=codec_name -of compact=p=0 /w/cortado.mp4

echo; echo "######## UC-VID-005 — Converter ou comprimir vídeo ########"
"${CURL[@]}" sh /media/convert.sh "$FREE" "$ANON" | tee "$WORK/convert.log"
CONVERT_RESULT=$(grep "^RESULT" "$WORK/convert.log")

echo; echo "== TST-CONV-21: duração (±1 s), áudio e codecs do vídeo convertido (CONV-023, CONV-046) =="
URL=$(sed 's/\\u0026/\&/g' "$WORK/convert_url.txt")
curl -sk -o "$WORK/convertido.webm" "$URL"
docker run --rm -v "$WORK":/w --entrypoint ffprobe picturas-video_convert_tool \
  -v error -show_entries format=duration:stream=codec_name,height -of compact=p=0 /w/convertido.webm

echo; echo "######## UC-VID-004 — Desfocar caras ########"
"${CURL[@]}" sh /media/blur.sh "$BLUR_USER" "$ANON" | tee "$WORK/blur.log"
BLUR_RESULT=$(grep "^RESULT" "$WORK/blur.log")

echo; echo "== TST-BLUR-06: duração, contentor, codecs e áudio do vídeo anonimizado (BLUR-006, 022, 043) =="
curl -sk -o "$WORK/anonimizado.mp4" "$(cat "$WORK/blur_url.txt")"
docker run --rm -v "$WORK":/w --entrypoint ffprobe picturas-blur_faces_tool \
  -v error -show_entries format=format_name,duration:stream=codec_type,codec_name -of compact=p=0 /w/anonimizado.mp4

if [ -f "$WORK/blur_src_url.txt" ]; then
  echo; echo "== TST-BLUR-07: o original fica inalterado (BLUR-021) =="
  curl -sk -o "$WORK/original.mp4" "$(cat "$WORK/blur_src_url.txt")"
  if [ "$(sha256sum < "$WORK/original.mp4")" = "$(sha256sum < "$WORK/cara.mp4")" ]; then
    echo "PASS TST-BLUR-07 hash do original igual antes e depois"
  else
    echo "FAIL TST-BLUR-07 hash do original mudou"
  fi
fi

echo; echo "UC-VID-003: $FRAMES_RESULT"
echo "UC-VID-002: $TRIM_RESULT"
echo "UC-VID-004: $BLUR_RESULT"
echo "UC-VID-005: $CONVERT_RESULT"
