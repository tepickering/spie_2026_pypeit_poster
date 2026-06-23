#!/usr/bin/env bash
# Bundle Inter (body) + Space Grotesk (display) woff2 from @fontsource via jsDelivr.
set -euo pipefail
F="$(cd "$(dirname "$0")/.." && pwd)/assets/fonts"
base="https://cdn.jsdelivr.net/npm/@fontsource"
for w in 400 500 600 700; do
  curl -fsSL "$base/inter/files/inter-latin-$w-normal.woff2" -o "$F/inter-$w.woff2"
done
for w in 500 700; do
  curl -fsSL "$base/space-grotesk/files/space-grotesk-latin-$w-normal.woff2" -o "$F/spacegrotesk-$w.woff2"
done
echo "fonts bundled in $F"
