#!/bin/sh
# Teste ponta a ponta da conversão/compressão de vídeo (UC-VID-005) contra o serviço projects.
# Corre num container curl na rede da stack (ver run.sh): sh convert.sh <free_user_id> <anon_user_id>
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
imgid() { curl -sk "$P/$CALLER/$PID/imgs" -H "X-Caller-Id: $CALLER" | tr '{' '\n' | grep "\"name\":\"$1\"" | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p'; }
wait_results() {
  i=0
  while [ $i -lt 120 ]; do
    n=$(curl -sk "$P/$CALLER/$PID/process/url" -H "X-Caller-Id: $CALLER" | grep -o '"og_img_id"' | wc -l)
    [ "$n" -ge "$1" ] && break
    i=$((i+1)); sleep 1
  done
  curl -sk "$P/$CALLER/$PID/process/url" -H "X-Caller-Id: $CALLER" > /tmp/results
  grep -o '"og_img_id"' /tmp/results | wc -l | tr -d ' '
}

echo "== Fluxo principal: comprimir aula.mp4 para WebM 360p =="
CALLER=$U; PID=$(newproj convert-e2e)
upload aula.mp4 >/dev/null; upload curto.mp4 >/dev/null; upload foto.png >/dev/null
VID=$(imgid aula.mp4); CURTO=$(imgid curto.mp4)
# o vídeo sintético comprime mal: confirma-se um resultado maior (Exceção 4, CONV-017)
PARAMS="{\"format\":\"webm\",\"resolution\":360,\"quality\":\"low\",\"allow_larger\":true,\"video_id\":\"$VID\"}"

check TST-CONV-11 "registado não pode pedir 1080p (CONV-014, 022)" 403 "$(req POST "$P/$U/$PID/tool" -d "{\"procedure\":\"video_convert\",\"params\":{\"format\":\"mp4\",\"resolution\":1080,\"quality\":\"high\",\"video_id\":\"$VID\"}}")"
check TST-CONV-11 "mensagem sugere o upgrade (CONV-014)" 1 "$(grep -c 'Upgrade to Premium' /tmp/body)"
check TST-CONV-12 "estimativa de tamanho (CONV-003)" 200 "$(req POST "$P/$U/$PID/video-convert/estimate/$VID" -d "$PARAMS")"
EST=$(sed -n 's/.*"estimatedSizeBytes":\([0-9]*\).*/\1/p' /tmp/body)
check TST-CONV-13 "adicionar conversão do vídeo escolhido (CONV-001)" 204 "$(req POST "$P/$U/$PID/tool" -d "{\"procedure\":\"video_convert\",\"params\":$PARAMS}")"
OPS0=$(ops)
T0=$(date +%s)
check TST-CONV-13 "aplicar (CONV-004)" 201 "$(req POST "$P/$U/$PID/process" -d '{}')"
check TST-CONV-14 "confirmação em ≤ 2 s (CONV-025)" 1 "$([ $(( $(date +%s) - T0 )) -le 2 ] && echo 1 || echo 0)"
check TST-CONV-13 "só o vídeo escolhido é convertido (passo 2)" 1 "$(wait_results 1)"
check TST-CONV-15 "tamanho original e final no resultado (CONV-008)" 1 "$(grep -c '"output_size_bytes":[0-9]' /tmp/results)"
OUT=$(sed -n 's/.*"output_size_bytes":\([0-9]*\).*/\1/p' /tmp/results)
check TST-CONV-16 "estimativa com erro ≤ 20 % (CONV-024)" 1 "$(awk -v e="$EST" -v o="$OUT" 'BEGIN { d = (e > o ? e - o : o - e) / o; print (d <= 0.20 ? 1 : 0) }')"
echo "     estimativa=$EST real=$OUT"
check TST-CONV-17 "vídeo novo na biblioteca (CONV-006)" 1 "$(curl -sk "$P/$U/$PID/imgs" -H "X-Caller-Id: $U" | grep -c 'aula_converted.webm')"
check TST-CONV-17 "original mantido (CONV-036)" 1 "$(curl -sk "$P/$U/$PID/imgs" -H "X-Caller-Id: $U" | grep -o '"name":"aula.mp4"' | wc -l | tr -d ' ')"
check TST-CONV-18 "conta 1 operação após sucesso (CONV-018, 031)" "$((OPS0 - 1))" "$(ops)"

echo "== Persistência: remover a tool não apaga o vídeo convertido =="
TOOL=$(curl -sk "$P/$U/$PID" -H "X-Caller-Id: $U" | sed -n 's/.*"tools":\[{[^]]*"_id":"\([^"]*\)".*/\1/p')
req DELETE "$P/$U/$PID/tool/$TOOL" >/dev/null
check TST-CONV-19 "vídeo convertido continua na biblioteca (CONV-033)" 1 "$(curl -sk "$P/$U/$PID/imgs" -H "X-Caller-Id: $U" | grep -c 'aula_converted.webm')"
check TST-CONV-19 "outro utilizador não lhe acede (CONV-039)" 403 "$(curl -sk -o /dev/null -w '%{http_code}' "$P/$U/$PID/imgs" -H "X-Caller-Id: $ANON")"
# ligação do vídeo convertido na biblioteca, para o run.sh verificar duração, áudio e codecs (TST-CONV-21)
curl -sk "$P/$U/$PID/imgs" -H "X-Caller-Id: $U" | tr '{' '\n' | grep '"name":"aula_converted.webm"' \
  | sed -n 's/.*"url":"\([^"]*\)".*/\1/p' > /media/convert_url.txt

echo "== Exceções =="
req POST "$P/$U/$PID/tool" -d "{\"procedure\":\"video_convert\",\"params\":{\"format\":\"mp4\",\"resolution\":480,\"quality\":\"medium\",\"video_id\":\"$CURTO\"}}" >/dev/null
check TST-CONV-20 "vídeo sem áudio AAC recusado (CONV-015)" 400 "$(req POST "$P/$U/$PID/process" -d '{}')"
check TST-CONV-20 "mensagem indica o vídeo (CONV-015)" 1 "$(grep -c 'curto.mp4' /tmp/body)"
check TST-CONV-20 "quota inalterada sem processamento (CONV-031)" "$((OPS0 - 1))" "$(ops)"

echo "== Perfil anónimo =="
CALLER=$ANON; PID=$(newproj convert-anon)
upload aula.mp4 >/dev/null; AVID=$(imgid aula.mp4)
check TST-CONV-22 "anónimo não pode converter (CONV-032)" 403 "$(req POST "$P/$ANON/$PID/tool" -d "{\"procedure\":\"video_convert\",\"params\":{\"format\":\"mp4\",\"resolution\":360,\"quality\":\"low\",\"video_id\":\"$AVID\"}}")"

echo "RESULT pass=$pass fail=$fail"
