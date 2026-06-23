"""Regenerate a polished Binospec IFU narrowband image at 6784 A.

Co-adds N channels centered on 6784 A from the JADES IFU datacube and renders
a publication-quality figure (asinh stretch, perceptual colormap, colorbar,
arcsec offset axes). Native spatial resolution is intrinsically coarse
(0.27"/spaxel) -- the goal is a clean render, not added detail.

Run with the pypeit conda env:
  /Users/tim/conda/envs/pypeit/bin/python scripts/make_ifu_slice.py
"""
import os
import warnings
warnings.simplefilter("ignore")
import numpy as np
from astropy.io import fits
from astropy.wcs import WCS
from astropy.wcs.utils import proj_plane_pixel_scales
from astropy.visualization import AsinhStretch, ImageNormalize, PercentileInterval
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

CUBE = os.path.expanduser(
    "~/MMT/bino_ifu/JADES_1031022/Science/"
    "cube_sci_img_2025.0524.034253-IFU_BINOSPEC_20250524T032729.376.fits")
OUT = ("/Users/tim/Library/Mobile Documents/com~apple~CloudDocs/MMTO/"
       "spie/2026/pypeit/poster/assets/figures/ifu_6784.png")
TARGET_A = 6784.0
NCHAN = 5                 # co-add width (odd)
CONTINUUM_SUBTRACT = True  # subtract median of off-line windows

hl = fits.open(CUBE)
flux = hl["FLUX"].data.astype(float)          # (nwave, ny, nx)
hdr = hl["FLUX"].header
w = WCS(hdr)
nz, ny, nx = flux.shape
chan = np.arange(nz)
wave_A = np.array(w.pixel_to_world_values(
    np.full(nz, nx // 2), np.full(nz, ny // 2), chan)[2]) * 1e10
i0 = int(np.argmin(np.abs(wave_A - TARGET_A)))
half = NCHAN // 2

line = np.nansum(flux[i0 - half:i0 + half + 1], axis=0)
if CONTINUUM_SUBTRACT:
    off = np.concatenate([flux[i0 - 40:i0 - 20], flux[i0 + 20:i0 + 40]])
    cont = np.nanmedian(off, axis=0) * NCHAN
    img = line - cont
else:
    img = line

scl = proj_plane_pixel_scales(w.celestial) * 3600.0   # arcsec/spaxel
dx, dy = scl[0], scl[1]
extent = [-(nx / 2) * dx, (nx / 2) * dx, -(ny / 2) * dy, (ny / 2) * dy]

norm = ImageNormalize(img, interval=PercentileInterval(99.3),
                      stretch=AsinhStretch(0.1))
fig, ax = plt.subplots(figsize=(5.2, 4.2), dpi=300)
im = ax.imshow(img, origin="lower", extent=extent, cmap="inferno",
               norm=norm, interpolation="gaussian", aspect="equal")
ax.set_xlabel(r"$\Delta\alpha$ (arcsec)")
ax.set_ylabel(r"$\Delta\delta$ (arcsec)")
ax.set_title(f"Binospec IFU — {wave_A[i0]:.0f} Å "
             f"({NCHAN}-channel co-add)")
cb = fig.colorbar(im, ax=ax, fraction=0.046, pad=0.03)
cb.set_label("Continuum-subtracted flux" if CONTINUUM_SUBTRACT
             else "Co-added flux")
fig.tight_layout()
fig.savefig(OUT, dpi=300, bbox_inches="tight", facecolor="white")
print(f"wrote {OUT}")
print(f"center chan {i0} = {wave_A[i0]:.2f} A; img shape {img.shape}; "
      f"finite frac {np.isfinite(img).mean():.2f}; "
      f"range [{np.nanmin(img):.3g}, {np.nanmax(img):.3g}]")
