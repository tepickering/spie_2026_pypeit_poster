"""Assert the rendered poster PDF has an A0 page box (841 x 1189 mm)."""
import sys
import subprocess

try:
    from pypdf import PdfReader
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "-q", "pypdf"])
    from pypdf import PdfReader

reader = PdfReader("pypeit_poster.pdf")

n_pages = len(reader.pages)
print(f"pages: {n_pages}")
assert n_pages == 1, f"poster overflowed onto {n_pages} pages (content is too tall for A0)"

box = reader.pages[0].mediabox
w_mm = float(box.width) / 72 * 25.4
h_mm = float(box.height) / 72 * 25.4
print(f"page box: {w_mm:.1f} x {h_mm:.1f} mm")
assert abs(w_mm - 841) < 3 and abs(h_mm - 1189) < 3, "PDF is not A0!"
print("OK: single A0 page")
