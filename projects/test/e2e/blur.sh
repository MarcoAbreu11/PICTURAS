#!/bin/sh
# Teste ponta a ponta da desfocagem de caras (UC-VID-004) contra o serviço projects.
# Corre num container curl na rede da stack (ver run.sh): sh blur.sh <free_user_id> <anon_user_id>
# Se existir /media/cara.mp4 (vídeo com uma cara, opcional), testa também a deteção.
set -u
U="$1"; ANON="$2"
P=https://projects:9001
USERS=https://users:10001
pass=0; fail=0

check() { # id, nome, esperado, obtido
  if [ "$3" = "$4" ]; then echo "PASS $1 $2"; pass=$((pass+1)); else echo "FAIL $1 $2 (esperado=$3 obtido=$4)"; fail=$((fail+1)); fi
}
ver() { curl -sk "$P/$CALLER/$PID" -H "X-Caller-Id: $CALLER" | sed -n 's/.*"version":\([0-9]*\).*/\1/p'; }
req() { m=$1; url=$2; shift 2; curl -sk -o /tmp/body -w '%{http_code}' -X "$m" "$url" -H "X-Caller-Id: $CALLER" -H "X-Project-Version: $(ver)" -H 'Content-Type: application/json' "$@"; }
upload() { curl -sk -o /tmp/body -w '%{http_code}' -X POST "$P/$CALLER/$PID/img" -H "X-Caller-Id: $CALLER" -H "X-Project-Version: $(ver)" -F "image=@/media/$1"; }
newproj() { curl -sk -X POST "$P/$CALLER" -H "X-Caller-Id: $CALLER" -H 'Content-Type: application/json' -d "{\"name\":\"$1\"}" | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p' | head -1; }
ops() { curl -sk "$USERS/$U" | sed -n 's/.*"remaining_operations":\([0-9]*\).*/\1/p'; }
jget() { sed -n "s/.*\"$1\":\"\{0,1\}\([^\",}]*\).*/\1/p" /tmp/body | head -1; }
wait_results() {
  i=0
  while [ $i -lt 180 ]; do
    n=$(curl -sk "$P/$CALLER/$PID/process/url" -H "X-Caller-Id: $CALLER" | grep -o '"og_img_id"' | wc -l)
    [ "$n" -ge "$1" ] && break
    i=$((i+1)); sleep 1
  done
  curl -sk "$P/$CALLER/$PID/process/url" -H "X-Caller-Id: $CALLER" > /tmp/results
  grep -o '"og_img_id"' /tmp/results | wc -l | tr -d ' '
}
# campo de um resultado identificado pelo nome do ficheiro
rget() { tr '{' '\n' < /tmp/results | grep "\"name\":\"$1\"" | sed -n "s/.*\"$2\":\"\{0,1\}\([^\",}]*\).*/\1/p" | head -1; }

HAS_FACE=0; [ -f /media/cara.mp4 ] && HAS_FACE=1
NVIDEOS=$((1 + HAS_FACE))

echo "== Fluxo principal: desfocagem em $NVIDEOS vídeo(s) + 1 imagem (registado) =="
CALLER=$U; PID=$(newproj blur-e2e)
upload aula.mp4 >/dev/null; upload foto.png >/dev/null
[ "$HAS_FACE" = 1 ] && upload cara.mp4 >/dev/null
check TST-BLUR-11 "intensidade fora de 1–10 recusada (BLUR-050)" 400 "$(req POST "$P/$U/$PID/tool" -d '{"procedure":"blur_faces","params":{"mode":"blur","strength":15,"padding":20}}')"
check TST-BLUR-11 "tipo desconhecido recusado (BLUR-050)" 400 "$(req POST "$P/$U/$PID/tool" -d '{"procedure":"blur_faces","params":{"mode":"emoji","strength":5,"padding":20}}')"
check TST-BLUR-03 "adicionar blur_faces (BLUR-001, BLUR-002)" 204 "$(req POST "$P/$U/$PID/tool" -d '{"procedure":"blur_faces","params":{"mode":"blur","strength":5,"padding":20}}')"
check TST-BLUR-02 "combinar com trim recusado (BLUR-046)" 400 "$(req POST "$P/$U/$PID/tool" -d '{"procedure":"trim","params":{"start":0,"end":2}}')"
check TST-BLUR-03 "operações previstas = nº de vídeos (BLUR-018, BLUR-045)" "$NVIDEOS" "$(curl -sk "$P/$U/$PID/advanced_tools" -H "X-Caller-Id: $U")"

VID=$(curl -sk "$P/$U/$PID/imgs" -H "X-Caller-Id: $U" | tr '{' '\n' | grep aula.mp4 | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p')
OPS_PREVIEW=$(ops)
check TST-BLUR-10 "pré-visualização de um frame aceite (BLUR-010)" 201 "$(req POST "$P/$U/$PID/preview/$VID" -d '{}')"
check TST-BLUR-10 "pré-visualização não consome operações (BLUR-010)" "$OPS_PREVIEW" "$(ops)"

OPS0=$(ops)
check TST-BLUR-03 "aplicar (BLUR-003)" 201 "$(req POST "$P/$U/$PID/process" -d '{}')"
check TST-BLUR-03 "1 imagem ignorada (BLUR-045)" 1 "$(jget skipped)"
check TST-BLUR-03 "$NVIDEOS vídeo(s) anonimizado(s) nos resultados (BLUR-006, BLUR-007)" "$NVIDEOS" "$(wait_results "$NVIDEOS")"
check TST-BLUR-03 "resultados marcados como vídeo (BLUR-008)" "$NVIDEOS" "$(grep -o '"media_type":"video"' /tmp/results | wc -l | tr -d ' ')"
check TST-BLUR-03 "nome com o vídeo de origem (BLUR-007)" 1 "$(grep -c 'aula_blurred.mp4' /tmp/results)"
check TST-BLUR-03 "debita uma operação por vídeo (BLUR-018, BLUR-030)" "$((OPS0 - NVIDEOS))" "$(ops)"
check TST-BLUR-04 "vídeo sem caras assinalado (BLUR-013)" 0 "$(rget aula_blurred.mp4 faces_detected)"
if [ "$HAS_FACE" = 1 ]; then
  FACES=$(rget cara_blurred.mp4 faces_detected)
  check TST-BLUR-03 "caras detetadas no vídeo com pessoas (BLUR-004)" 1 "$([ "${FACES:-0}" -ge 1 ] && echo 1 || echo 0)"
  rget cara_blurred.mp4 url | sed 's/\\u0026/\&/g' > /media/blur_url.txt
  curl -sk "$P/$U/$PID/imgs" -H "X-Caller-Id: $U" | tr '{' '\n' | grep cara.mp4 \
    | sed -n 's/.*"url":"\([^"]*\)".*/\1/p' | sed 's/\\u0026/\&/g' > /media/blur_src_url.txt
else
  echo "SKIP TST-BLUR-03 deteção (BLUR-004): defina BLUR_FACE_VIDEO no run.sh para testar com um vídeo com caras"
  rget aula_blurred.mp4 url | sed 's/\\u0026/\&/g' > /media/blur_url.txt
fi

echo "== FA4: descartar o resultado sem caras =="
RID=$(rget aula_blurred.mp4 _id)
check TST-BLUR-04 "descartar o resultado (BLUR-014)" 204 "$(req DELETE "$P/$U/$PID/results/$RID")"
check TST-BLUR-04 "restam os outros resultados (BLUR-014)" "$((NVIDEOS - 1))" "$(wait_results 0)"

echo "== FA5: copiar para um novo projeto =="
if [ "$HAS_FACE" = 1 ]; then
  check TST-BLUR-12 "copiar resultados (BLUR-048)" 201 "$(req POST "$P/$U/$PID/results/project" -d '{}')"
  NEW=$(jget _id)
  check TST-BLUR-12 "novo projeto com o vídeo anonimizado (BLUR-032, BLUR-048)" 1 "$(curl -sk "$P/$U/$NEW/imgs" -H "X-Caller-Id: $U" | grep -o '"media_type":"video"' | wc -l | tr -d ' ')"
else
  echo "SKIP TST-BLUR-12 (sem resultados depois de descartar o vídeo sem caras)"
fi

echo "== Exceção 2: quota insuficiente =="
PID=$(newproj blur-e2e-quota)
for f in q1.mp4 q2.mp4 q3.mp4 q4.mp4 q5.mp4 q6.mp4; do upload "$f" >/dev/null; done
req POST "$P/$U/$PID/tool" -d '{"procedure":"blur_faces","params":{"mode":"pixelate","strength":5,"padding":20}}' >/dev/null
OPS1=$(ops)
# o users-ms responde 701 "No more daily_operations available" e o projects reencaminha-o
check TST-BLUR-13 "6 vídeos com quota < 6 recusado (BLUR-018)" 701 "$(req POST "$P/$U/$PID/process" -d '{}')"
check TST-BLUR-13 "mensagem indica que acabaram as operações (BLUR-018)" 1 "$(grep -c 'daily_operations' /tmp/body)"
check TST-BLUR-13 "quota inalterada (BLUR-018)" "$OPS1" "$(ops)"

echo "== Exceção 4: projeto sem vídeos =="
PID=$(newproj blur-e2e-sem-videos); upload foto.png >/dev/null
req POST "$P/$U/$PID/tool" -d '{"procedure":"blur_faces","params":{"mode":"blur","strength":5,"padding":20}}' >/dev/null
check TST-BLUR-14 "aplicar sem vídeos recusado (BLUR-047)" 400 "$(req POST "$P/$U/$PID/process" -d '{}')"

echo "== Exceção 1: perfil anónimo =="
CALLER=$ANON; PID=$(newproj blur-anon)
upload curto.mp4 >/dev/null
check TST-BLUR-01 "anónimo não pode adicionar blur_faces (BLUR-031)" 403 "$(req POST "$P/$ANON/$PID/tool" -d '{"procedure":"blur_faces","params":{"mode":"blur","strength":5,"padding":20}}')"

echo "RESULT pass=$pass fail=$fail"
