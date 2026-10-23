#!/bin/sh
# Teste ponta a ponta das legendas na pipeline (UC-VID-001) contra o serviço projects.
# Corre num container curl na rede da stack (ver run.sh): sh subtitles.sh <anon_user_id>
# Se existir /media/cara.mp4 (vídeo com fala, opcional), testa também uma geração bem-sucedida.
set -u
ANON="$1"
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
vid() { curl -sk "$P/$U/$PID/imgs" -H "X-Caller-Id: $U" | tr '{' '\n' | grep "$1" | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p'; }
# estado das legendas de um vídeo (rota com JWT validado pelo users)
subs() { curl -sk "$P/$U/$PID/img/$1/subtitles" -H "Authorization: Bearer $JWT"; }
# espera até haver faixa "original" ou erro (o 1.º pedido descarrega o modelo Whisper)
wait_subs() {
  i=0
  while [ $i -lt 180 ]; do
    subs "$1" > /tmp/subs
    grep -q '"tracks":{"original"' /tmp/subs && { echo track; return; }
    grep -q '"error":{' /tmp/subs && { sed -n 's/.*"error":{"code":\([0-9]*\).*/\1/p' /tmp/subs; return; }
    i=$((i+1)); sleep 5
  done
  echo timeout
}

STAMP=$(date +%s)
NEW=$(curl -sk -X POST "$USERS/" -H 'Content-Type: application/json' \
  -d "{\"name\":\"E2E Subs\",\"email\":\"e2e.subs.$STAMP@example.com\",\"password\":\"Teste1234!\",\"type\":\"free\"}")
U=$(echo "$NEW" | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p' | head -1)
JWT=$(echo "$NEW" | sed -n 's/.*"jwt":"\([^"]*\)".*/\1/p')
HAS_SPEECH=0; [ -f /media/cara.mp4 ] && HAS_SPEECH=1

echo "== Configurar as legendas na pipeline (registado) =="
CALLER=$U; PID=$(newproj subs-e2e)
upload aula.mp4 >/dev/null; upload foto.png >/dev/null
[ "$HAS_SPEECH" = 1 ] && upload cara.mp4 >/dev/null
check TST-SUB-01 "idioma inválido recusado" 400 "$(req POST "$P/$U/$PID/tool" -d '{"procedure":"video_subtitles","params":{"language":"pt"}}')"
check TST-SUB-02 "adicionar legendas à pipeline" 204 "$(req POST "$P/$U/$PID/tool" -d '{"procedure":"video_subtitles","params":{"language":"original"}}')"
check TST-SUB-03 "combinar com o corte recusado" 400 "$(req POST "$P/$U/$PID/tool" -d '{"procedure":"trim","params":{"start":0,"end":2}}')"
VA=$(vid aula.mp4)
check TST-SUB-04 "sem pré-visualização no servidor" 400 "$(req POST "$P/$U/$PID/preview/$VA" -d '{}')"
check TST-SUB-05 "nada é gerado antes do Apply" 0 "$(subs "$VA" | grep -c '"job":{')"

echo "== Apply =="
OPS0=$(ops)
check TST-SUB-06 "aplicar" 201 "$(req POST "$P/$U/$PID/process" -d '{}')"
check TST-SUB-06 "1 imagem ignorada" 1 "$(jget skipped)"
check TST-SUB-07 "vídeo sem fala termina com erro 2304 (sem fala)" 2304 "$(wait_subs "$VA")"
if [ "$HAS_SPEECH" = 1 ]; then
  VC=$(vid cara.mp4)
  check TST-SUB-08 "vídeo com fala fica com a faixa original" track "$(wait_subs "$VC")"
  check TST-SUB-09 "gasta 1 operação (a do vídeo sem fala é devolvida)" "$((OPS0 - 1))" "$(ops)"
  URL=$(sed -n 's/.*"original":{[^}]*"url":"\([^"]*\)".*/\1/p' /tmp/subs | sed 's/\\u0026/\&/g')
  echo "$URL" > /media/subs_url.txt
  echo "== Apply outra vez: faixa já existe =="
  OPS1=$(ops)
  check TST-SUB-10 "aplicar de novo" 201 "$(req POST "$P/$U/$PID/process" -d '{}')"
  sleep 5
  check TST-SUB-10 "faixa existente não volta a gastar quota" "$OPS1" "$(ops)"
else
  echo "SKIP TST-SUB-08 a 10: defina BLUR_FACE_VIDEO no run.sh com um vídeo com fala"
  sleep 3
  check TST-SUB-09 "operação devolvida quando não há fala" "$OPS0" "$(ops)"
fi

echo "== Exceção 2: quota insuficiente para o lote =="
PID=$(newproj subs-e2e-quota)
for f in q1.mp4 q2.mp4 q3.mp4 q4.mp4 q5.mp4 q6.mp4; do upload "$f" >/dev/null; done
req POST "$P/$U/$PID/tool" -d '{"procedure":"video_subtitles","params":{"language":"original"}}' >/dev/null
OPS2=$(ops)
check TST-SUB-13 "6 vídeos sem faixa com quota < 6: recusado antes de começar (QUOTA-003)" 429 "$(req POST "$P/$U/$PID/process" -d '{}')"
check TST-SUB-13 "mensagem indica que acabaram as operações" 1 "$(grep -c 'daily_operations' /tmp/body)"
sleep 3
check TST-SUB-13 "quota inalterada (QUOTA-003)" "$OPS2" "$(ops)"
check TST-SUB-13 "nenhum vídeo enviado para geração" 0 "$(subs "$(vid q1.mp4)" | grep -c '"job":{')"

echo "== Perfil anónimo =="
CALLER=$ANON; PID=$(newproj subs-anon)
upload curto.mp4 >/dev/null
check TST-SUB-11 "anónimo não pode adicionar legendas" 403 "$(req POST "$P/$ANON/$PID/tool" -d '{"procedure":"video_subtitles","params":{"language":"original"}}')"

echo "RESULT pass=$pass fail=$fail"
