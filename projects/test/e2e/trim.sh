#!/bin/sh
# Teste ponta a ponta do corte de vídeo (UC-VID-002) contra o serviço projects.
# Corre num container curl na rede da stack (ver run.sh): sh trim.sh <free_user_id> <anon_user_id>
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
  while [ $i -lt 90 ]; do
    n=$(curl -sk "$P/$CALLER/$PID/process/url" -H "X-Caller-Id: $CALLER" | grep -o '"og_img_id"' | wc -l)
    [ "$n" -ge "$1" ] && break
    i=$((i+1)); sleep 1
  done
  curl -sk "$P/$CALLER/$PID/process/url" -H "X-Caller-Id: $CALLER" > /tmp/results
  grep -o '"og_img_id"' /tmp/results | wc -l | tr -d ' '
}

echo "== Fluxo principal: corte 1–2.5 s em 2 vídeos + 1 imagem =="
CALLER=$U; PID=$(newproj trim-e2e)
upload aula.mp4 >/dev/null; upload curto.mp4 >/dev/null; upload foto.png >/dev/null
check TST-TRIM-07 "início ≥ fim recusado (TRIM-014)" 400 "$(req POST "$P/$U/$PID/tool" -d '{"procedure":"trim","params":{"start":5,"end":2}}')"
check TST-TRIM-07 "excerto < 1 s recusado (TRIM-034)" 400 "$(req POST "$P/$U/$PID/tool" -d '{"procedure":"trim","params":{"start":1,"end":1.5}}')"
check TST-TRIM-09 "adicionar trim 1–2.5 s (TRIM-001)" 204 "$(req POST "$P/$U/$PID/tool" -d '{"procedure":"trim","params":{"start":1,"end":2.5}}')"
check TST-TRIM-08 "combinar com brightness recusado (TRIM-046)" 400 "$(req POST "$P/$U/$PID/tool" -d '{"procedure":"brightness","params":{"brightness":1.2}}')"
check TST-TRIM-09 "não conta como operação avançada (TRIM-049)" 0 "$(curl -sk "$P/$U/$PID/advanced_tools" -H "X-Caller-Id: $U")"
OPS0=$(ops)
check TST-TRIM-09 "aplicar (TRIM-005)" 201 "$(req POST "$P/$U/$PID/process" -d '{}')"
check TST-TRIM-09 "1 imagem ignorada (TRIM-045)" 1 "$(jget skipped)"
check TST-TRIM-09 "2 vídeos cortados nos resultados (TRIM-006, 007)" 2 "$(wait_results 2)"
check TST-TRIM-09 "resultados marcados como vídeo (TRIM-008)" 2 "$(grep -o '"media_type":"video"' /tmp/results | wc -l | tr -d ' ')"
check TST-TRIM-09 "nome com vídeo e intervalo (TRIM-051)" 1 "$(grep -c 'aula_1-2.5s.mp4' /tmp/results)"
check TST-TRIM-09 "quota inalterada (TRIM-049)" "$OPS0" "$(ops)"
# ligação do vídeo cortado, para o run.sh verificar duração e codecs (TST-TRIM-14)
grep -o '"name":"aula_1-2.5s.mp4","url":"[^"]*"' /tmp/results | sed 's/.*"url":"//;s/"$//' > /media/trim_url.txt

echo "== Validações antes de processar =="
TOOL=$(curl -sk "$P/$U/$PID" -H "X-Caller-Id: $U" | sed -n 's/.*"tools":\[{[^]]*"_id":"\([^"]*\)".*/\1/p')
req PUT "$P/$U/$PID/tool/$TOOL" -d '{"params":{"start":1,"end":5}}' >/dev/null
check TST-TRIM-10 "fim além da duração recusado (TRIM-015)" 400 "$(req POST "$P/$U/$PID/process" -d '{}')"
check TST-TRIM-10 "mensagem indica o vídeo curto (TRIM-015)" 1 "$(grep -c 'curto.mp4' /tmp/body)"
VID=$(curl -sk "$P/$U/$PID/imgs" -H "X-Caller-Id: $U" | tr '{' '\n' | grep aula.mp4 | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p')
check TST-TRIM-11 "pré-visualização no servidor recusada: o excerto vê-se no leitor (TRIM-009)" 400 "$(req POST "$P/$U/$PID/preview/$VID" -d '{}')"

echo "== FA3: copiar vídeos cortados para um novo projeto =="
req PUT "$P/$U/$PID/tool/$TOOL" -d '{"params":{"start":1,"end":2.5}}' >/dev/null
check TST-TRIM-12 "copiar resultados (TRIM-048)" 201 "$(req POST "$P/$U/$PID/results/project" -d '{}')"
NEW=$(jget _id); PID=$NEW
IMGS=$(curl -sk "$P/$U/$NEW/imgs" -H "X-Caller-Id: $U")
check TST-TRIM-12 "novo projeto com 2 vídeos (TRIM-048, 032)" 2 "$(echo "$IMGS" | grep -o '"media_type":"video"' | wc -l | tr -d ' ')"
check TST-TRIM-12 "duração guardada nos vídeos copiados (TRIM-048)" 2 "$(echo "$IMGS" | grep -o '"duration":1\.[0-9]*' | wc -l | tr -d ' ')"
check TST-TRIM-12 "outra tool de vídeo aplica-se aos vídeos copiados (TRIM-048)" 204 "$(req POST "$P/$U/$NEW/tool" -d '{"procedure":"extract_frames","params":{"mode":"single","interval":2,"instant":0.5,"format":"png"}}')"

echo "== Projeto sem vídeos =="
PID=$(newproj trim-e2e-sem-videos); upload foto.png >/dev/null
req POST "$P/$U/$PID/tool" -d '{"procedure":"trim","params":{"start":0,"end":2}}' >/dev/null
check TST-TRIM-15 "aplicar sem vídeos recusado (TRIM-047)" 400 "$(req POST "$P/$U/$PID/process" -d '{}')"

echo "== Perfil anónimo =="
CALLER=$ANON; PID=$(newproj trim-anon)
check TST-TRIM-13 "upload aula.mp4 (10 s, limite anónimo 15 s)" 204 "$(upload aula.mp4)"
check TST-TRIM-13 "anónimo pode adicionar trim (TRIM-049)" 204 "$(req POST "$P/$ANON/$PID/tool" -d '{"procedure":"trim","params":{"start":0,"end":3}}')"
check TST-TRIM-13 "anónimo aplica o corte (TRIM-049)" 201 "$(req POST "$P/$ANON/$PID/process" -d '{}')"
check TST-TRIM-13 "anónimo obtém 1 vídeo cortado (TRIM-049)" 1 "$(wait_results 1)"

echo "RESULT pass=$pass fail=$fail"
