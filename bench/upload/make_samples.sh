#!/usr/bin/env bash
# Generates the synthetic media used by the upload benchmark and the
# regression checks into bench/upload/samples/ (not versioned).
#
# Videos are H.264/AAC MP4 at a constant bit rate chosen to reach the target
# size, with a noisy test pattern so the encoder cannot compress them away.
# Usage: bench/upload/make_samples.sh [size_mb ...]   (default: 100 500 950)
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)/samples"
mkdir -p "$DIR"
SIZES=("$@")
[ ${#SIZES[@]} -eq 0 ] && SIZES=(100 500 950)

# H.264 encoder: libx264 when available (most builds), otherwise OpenH264
# (e.g. Fedora's ffmpeg-free). Sizes are approximate; the benchmark records
# the real size of every file.
# capture first: with pipefail, grep -q closing the pipe early makes ffmpeg fail
ENCODERS="$(ffmpeg -hide_banner -encoders 2>/dev/null)"
if grep -q ' libx264 ' <<<"$ENCODERS"; then
  ENC=(-c:v libx264 -preset ultrafast -x264-params nal-hrd=cbr)
else
  ENC=(-c:v libopenh264 -rc_mode bitrate -allow_skip_frames 0)
fi

# make_video <file> <size_mb> <duration_s> [extra ffmpeg output args...]
make_video() {
  local out="$1" size_mb="$2" dur="$3"
  shift 3
  if [ -f "$out" ]; then echo "exists: $out"; return; fi
  # total bit rate in kbit/s, minus 128 kbit/s of audio
  local kbps=$(( size_mb * 8 * 1024 * 1024 / 1000 / dur - 128 ))
  echo "generating $out (~${size_mb} MB, ${dur} s, ${kbps} kbit/s video)"
  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i "testsrc2=size=1280x720:rate=30,noise=alls=60:allf=t+u" \
    -f lavfi -i "sine=frequency=440:sample_rate=48000" \
    -t "$dur" "${ENC[@]}" -pix_fmt yuv420p \
    -b:v "${kbps}k" -minrate "${kbps}k" -maxrate "${kbps}k" -bufsize "$(( kbps * 2 ))k" \
    -c:a aac -b:a 128k "$@" "$out"
}

for s in "${SIZES[@]}"; do
  # long enough to keep the bit rate realistic, short enough for the
  # premium duration limit (600 s)
  dur=$(( s < 200 ? 60 : 300 ))
  make_video "$DIR/video_${s}mb.mp4" "$s" "$dur"
done

# Regression fixtures
make_video "$DIR/small.mp4" 2 5
make_video "$DIR/over_free_limit.mp4" 110 50     # free profile limit is 100 MB
[ -f "$DIR/wrong_codec.mp4" ] || ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i testsrc2=size=320x240:rate=25 -t 2 -c:v mpeg2video "$DIR/wrong_codec.mp4"
[ -f "$DIR/image.png" ] || ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i testsrc2=size=640x480 -frames:v 1 "$DIR/image.png"
[ -f "$DIR/corrupted.mp4" ] || head -c 300000 /dev/urandom > "$DIR/corrupted.mp4"

ls -l "$DIR"
