#!/usr/bin/env bash
# Render the poster to a print-ready A0 PDF via headless Chrome.
set -euo pipefail
cd "$(dirname "$0")/.."
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless=new --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$(pwd)/poster.pdf" "file://$(pwd)/index.html" 2>/dev/null
echo "wrote $(pwd)/poster.pdf"
