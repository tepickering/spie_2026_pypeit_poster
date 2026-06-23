#!/usr/bin/env bash
# Render a downscaled PNG of the poster for visual QC.
# A0 at 96dpi ~= 3179x4494 px; screenshot full then downscale.
set -euo pipefail
cd "$(dirname "$0")/.."
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless=new --disable-gpu --hide-scrollbars \
  --force-device-scale-factor=1 --window-size=3179,4494 \
  --screenshot="$(pwd)/preview_full.png" "file://$(pwd)/index.html" 2>/dev/null
sips -Z "${1:-1600}" "$(pwd)/preview_full.png" --out "$(pwd)/preview.png" >/dev/null
echo "wrote $(pwd)/preview.png"
