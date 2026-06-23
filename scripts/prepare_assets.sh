#!/usr/bin/env bash
# Extract/copy all poster figures & logos with semantic names, convert the MMT
# vector logo, crop a clean PypeIt wordmark, label QR codes, and write palette.css.
# Python work uses the pypeit conda env per session convention.
set -euo pipefail
ROOT="/Users/tim/Library/Mobile Documents/com~apple~CloudDocs/MMTO/spie/2026/pypeit"
PY="/Users/tim/conda/envs/pypeit/bin/python"
P="$ROOT/poster"; FIG="$P/assets/figures"; LOGO="$P/assets/logos"
mkdir -p "$FIG" "$LOGO"

SCRATCH="$(mktemp -d)"; cp "$ROOT/PypeIt_MMTO_symposium.pptx" "$SCRATCH/deck.pptx"
( cd "$SCRATCH" && unzip -o -q deck.pptx -d deck )
M="$SCRATCH/deck/ppt/media"

# --- deck figures ---
cp "$M/image12.png" "$FIG/world_map.png"           # supported spectrographs map
cp "$M/image9.png"  "$FIG/growth.png"              # Slack users + citations
cp "$M/image6.png"  "$FIG/fiber_2d.png"            # Binospec IFU 2D fiber spectra
cp "$M/image13.png" "$FIG/spectrograph_montage.png" # bonus: 4-panel data montage
# QR codes: slide-11 layout pairs image1(=docs, left) and image4(=slack, right)
cp "$M/image1.png"  "$FIG/qr_docs.png"
cp "$M/image4.png"  "$FIG/qr_slack.png"

# --- user-supplied figures ---
cp "$ROOT/extraction_gui.png"             "$FIG/extraction_gui.png"
cp "$ROOT/faint_emission_line_source.png" "$FIG/faint_emission.png"
cp "$ROOT/long_cr.png"                     "$FIG/cosmic_ray.png"

# --- logos ---
cp "$ROOT/UA Logo.png"      "$LOGO/ua.png"
cp "$ROOT/Logo_Dec2025.png" "$LOGO/pose.png"
cp "$ROOT/UCO_logo.svg"     "$LOGO/uco.svg"
cp "$ROOT/Logo_mmt_observatory.pdf" "$LOGO/mmt.pdf"
# MMT vector logo -> trimmed high-res PNG (needs ImageMagick+Ghostscript)
magick -density 400 "$LOGO/mmt.pdf" -background white -flatten -trim +repage "$LOGO/mmt.png"

# --- clean PypeIt wordmark (deck image14 holds two stacked variants; keep lower) ---
"$PY" - "$M/image14.png" "$LOGO/pypeit_wordmark.png" <<'PYEOF'
import sys, numpy as np
from PIL import Image
src, out = sys.argv[1], sys.argv[2]
im = Image.open(src).convert('RGBA'); a = np.asarray(im)
ink = (a[:,:,3] > 40) & ~((a[:,:,:3] > 235).all(2))
cov = ink.sum(1); H = len(cov); thr = cov.max() * 0.03
runs=[]; s=None
for i in range(H):
    if cov[i] < thr:
        s = i if s is None else s
    elif s is not None:
        runs.append((s,i)); s=None
if s is not None: runs.append((s,H))
runs=[r for r in runs if r[0] > H*0.2 and r[1] < H*0.8]
runs.sort(key=lambda r:r[1]-r[0], reverse=True)
split=(runs[0][0]+runs[0][1])//2 if runs else H//2
b=im.crop((0,split,im.width,im.height)); ba=np.asarray(b)
bink=(ba[:,:,3]>40)&~((ba[:,:,:3]>235).all(2)); ys,xs=np.where(bink)
b.crop((xs.min(),ys.min(),xs.max()+1,ys.max()+1)).save(out)
print("wordmark saved", out)
PYEOF

# --- palette.css from the wordmark spectrum trace (sampled left->right) ---
"$PY" - "$LOGO/pypeit_wordmark.png" "$P/palette.css" <<'PYEOF'
import sys, numpy as np
from PIL import Image
img=Image.open(sys.argv[1]).convert('RGBA'); a=np.asarray(img)
rgb=a[:,:,:3].astype(int); al=a[:,:,3]; mx,mn=rgb.max(2),rgb.min(2)
sat=(al>180)&((mx-mn)>70)&(mx>90); ys,xs=np.where(sat); cols=rgb[ys,xs]
o=np.argsort(xs); cols=cols[o]
stops=[np.median(c,axis=0).astype(int) for c in np.array_split(np.arange(len(cols)),6)]
names=["violet","blue","green","yellow","orange","red"]
hexes=[f'#{c[0]:02X}{c[1]:02X}{c[2]:02X}' for c in stops]
lines=[":root{"]+[f"  --spec-{n}: {h};" for n,h in zip(names,hexes)]
lines+=["  --ink:#1A1A1A;","  --bg:#FFFFFF;","  --bg-alt:#F7F8FA;",
        "  --muted:#5A5F66;","  --hairline:#E2E5EA;","}"]
open(sys.argv[2],"w").write("\n".join(lines)+"\n"); print("palette.css written")
PYEOF

echo "assets prepared."
