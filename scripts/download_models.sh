#!/usr/bin/env bash
# One-shot model downloader for the cf-models network volume.
# Usage: download_models.sh <volume_root> [manifest_url]
# Serves progress at http://<pod>:8000/log.txt (+ listing.txt, DONE / FAILED markers).
set -uo pipefail
ROOT="${1:-/workspace}"
MANIFEST_URL="${2:-https://raw.githubusercontent.com/ycdizion-commits/creative-factory-worker/main/models/manifest.txt}"
STATUS="$ROOT/_status"; MODELS="$ROOT/models"
mkdir -p "$STATUS" "$MODELS"; LOG="$STATUS/log.txt"; : > "$LOG"; rm -f "$STATUS/DONE" "$STATUS/FAILED"
log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOG"; }
( cd "$STATUS" && python3 -m http.server 8000 --bind 0.0.0.0 >/dev/null 2>&1 ) &
log "start root=$ROOT"; df -h "$ROOT" | tee -a "$LOG"
if ! command -v aria2c >/dev/null; then apt-get update -qq && apt-get install -y -qq aria2 >/dev/null 2>&1 || log "aria2 install failed"; fi
curl -fsSL "$MANIFEST_URL" -o "$STATUS/manifest.txt" || { log "manifest download failed"; touch "$STATUS/FAILED"; sleep infinity; }
: > "$STATUS/aria2.txt"; total=0; skipped=0
while IFS='|' read -r url rel size; do
  url="$(echo "$url" | xargs)"; rel="$(echo "$rel" | xargs)"; size="$(echo "$size" | xargs)"
  [[ -z "$url" || "$url" == \#* ]] && continue
  dest="$MODELS/$rel"; mkdir -p "$(dirname "$dest")"
  if [[ -f "$dest" && ! -f "$dest.aria2" ]]; then log "skip existing $rel ($(stat -c %s "$dest") bytes)"; skipped=$((skipped+1)); continue; fi
  printf '%s\n  dir=%s\n  out=%s\n' "$url" "$(dirname "$dest")" "$(basename "$dest")" >> "$STATUS/aria2.txt"; total=$((total+1))
done < "$STATUS/manifest.txt"
log "queued=$total skipped=$skipped"
rc=0
if [[ $total -gt 0 ]]; then
  aria2c -i "$STATUS/aria2.txt" -x 8 -s 8 -j 3 -k 1M --continue=true --auto-file-renaming=false \
    --file-allocation=none --summary-interval=30 --console-log-level=warn --show-console-readout=false \
    --log="$STATUS/aria2.log" --log-level=notice 2>&1 | tee -a "$LOG"
  rc=${PIPESTATUS[0]}
fi
find "$MODELS" -type f -printf "%s %P\n" | sort -k2 > "$STATUS/listing.txt"
du -sh "$MODELS" | tee -a "$LOG"; df -h "$ROOT" | tee -a "$LOG"
if [[ $rc -eq 0 ]]; then touch "$STATUS/DONE"; log "DONE"; else touch "$STATUS/FAILED"; log "FAILED rc=$rc"; fi
sleep infinity
