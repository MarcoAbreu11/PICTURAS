#!/bin/sh
# Teste ponta a ponta da extração de frames (UC-VID-003) contra o serviço projects.
# Corre num container curl na rede da stack (ver run.sh): sh frames.sh <free_user_id> <anon_user_id>
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

echo "== Fluxo principal: intervalo de 2 s em 2 vídeos + 1 imagem =="
CALLER=$U; PID=$(newproj frames-e2e)
check TST-FRAME-11 "upload aula.mp4 (10 s)" 204 "$(upload aula.mp4)"
upload curto.mp4 >/dev/null; upload foto.png >/dev/null
check TST-FRAME-11 "duração guardada no upload (FRAME-053)" 10 "$(curl -sk "$P/$U/$PID/imgs" -H "X-Caller-Id: $U" | tr '{' '\n' | grep aula.mp4 | sed -n 's/.*"duration":\([0-9]*\).*/\1/p')"
check TST-FRAME-12 "parâmetros inválidos recusados (FRAME-002)" 400 "$(req POST "$P/$U/$PID/tool" -d '{"procedure":"extract_frames","params":{"mode":"interval","interval":0,"format":"png"}}')"
check TST-FRAME-13 "adicionar extract_frames (FRAME-001)" 204 "$(req POST "$P/$U/$PID/tool" -d '{"procedure":"extract_frames","params":{"mode":"interval","interval":2,"instant":0,"format":"png"}}')"
check TST-FRAME-12 "combinar com brightness recusado (FRAME-051)" 400 "$(req POST "$P/$U/$PID/tool" -d '{"procedure":"brightness","params":{"brightness":1.2}}')"
check TST-FRAME-13 "operações previstas = nº de vídeos (FRAME-049)" 2 "$(curl -sk "$P/$U/$PID/advanced_tools" -H "X-Caller-Id: $U")"
OPS0=$(ops)
check TST-FRAME-13 "aplicar (FRAME-005)" 201 "$(req POST "$P/$U/$PID/process" -d '{}')"
check TST-FRAME-13 "1 imagem ignorada (FRAME-050)" 1 "$(jget skipped)"
check TST-FRAME-13 "5 + 2 frames nos resultados (FRAME-006, 007, 009)" 7 "$(wait_results 7)"
check TST-FRAME-13 "nome com vídeo e instante (FRAME-036)" 1 "$(grep -c 'aula_4s.png' /tmp/results)"
check TST-FRAME-13 "debitadas 2 operações (FRAME-024)" $((OPS0-2)) "$(ops)"

echo "== Validações antes de processar =="
TOOL=$(curl -sk "$P/$U/$PID" -H "X-Caller-Id: $U" | sed -n 's/.*"tools":\[{[^]]*"_id":"\([^"]*\)".*/\1/p')
req PUT "$P/$U/$PID/tool/$TOOL" -d '{"params":{"mode":"interval","interval":0.05,"instant":0,"format":"png"}}' >/dev/null
check TST-FRAME-14 "mais de 100 imagens recusado (FRAME-014, 015)" 400 "$(req POST "$P/$U/$PID/process" -d '{}')"
req PUT "$P/$U/$PID/tool/$TOOL" -d '{"params":{"mode":"single","interval":2,"instant":5,"format":"jpeg"}}' >/dev/null
check TST-FRAME-14 "instante além do fim recusado (FRAME-013)" 400 "$(req POST "$P/$U/$PID/process" -d '{}')"
check TST-FRAME-14 "mensagem indica o vídeo curto (FRAME-013)" 1 "$(grep -c 'curto.mp4' /tmp/body)"

echo "== FA3: copiar resultados para um novo projeto =="
check TST-FRAME-15 "copiar resultados (FRAME-011)" 201 "$(req POST "$P/$U/$PID/results/project" -d '{}')"
NEW=$(jget _id); PID=$NEW
check TST-FRAME-15 "novo projeto com 7 imagens (FRAME-022, 033)" 7 "$(curl -sk "$P/$U/$NEW/imgs" -H "X-Caller-Id: $U" | grep -o '"media_type":"image"' | wc -l | tr -d ' ')"
req POST "$P/$U/$NEW/tool" -d '{"procedure":"brightness","params":{"brightness":1.3}}' >/dev/null
check TST-FRAME-15 "brightness aplica-se às imagens copiadas (FRAME-008, 047)" 201 "$(req POST "$P/$U/$NEW/process" -d '{}')"
check TST-FRAME-15 "7 imagens processadas (FRAME-008)" 7 "$(wait_results 7)"

echo "== Projeto sem vídeos =="
PID=$(newproj frames-e2e-sem-videos); upload foto.png >/dev/null
req POST "$P/$U/$PID/tool" -d '{"procedure":"extract_frames","params":{"mode":"interval","interval":2,"instant":0,"format":"png"}}' >/dev/null
check TST-FRAME-16 "aplicar sem vídeos recusado (FRAME-052)" 400 "$(req POST "$P/$U/$PID/process" -d '{}')"

echo "== Falha isolada de um vídeo e devolução da operação =="
PID=$(newproj frames-e2e-falha); upload aula.mp4 >/dev/null; upload curto.mp4 >/dev/null
req POST "$P/$U/$PID/tool" -d '{"procedure":"extract_frames","params":{"mode":"single","interval":2,"instant":5,"format":"png"}}' >/dev/null
echo "READY_FOR_UNSET $PID"
# o run.sh remove a duração de curto.mp4 na BD (simula um vídeo antigo) e cria /media/go
while [ ! -f /media/go ]; do sleep 1; done
OPS0=$(ops)
check TST-FRAME-17 "aplicar (o worker vai falhar em curto.mp4)" 201 "$(req POST "$P/$U/$PID/process" -d '{}')"
check TST-FRAME-17 "só o vídeo válido gera resultado (FRAME-017, 020)" 1 "$(wait_results 1)"
sleep 3
check TST-FRAME-17 "1 operação devolvida (FRAME-031)" $((OPS0-1)) "$(ops)"

echo "== Perfil anónimo =="
CALLER=$ANON; PID=$(newproj frames-anon)
check TST-FRAME-18 "anónimo não pode adicionar extract_frames (FRAME-032)" 403 "$(req POST "$P/$ANON/$PID/tool" -d '{"procedure":"extract_frames","params":{"mode":"interval","interval":2,"instant":0,"format":"png"}}')"

echo "RESULT pass=$pass fail=$fail"
