# PypeIt SPIE 2026 poster build
#
#   make            render the PDF, check it is A0, and build the preview
#   make poster     render pypeit_poster.pdf and verify the page box is A0
#   make preview    build preview.png (override size: make preview SIZE=2400)
#   make check      assert pypeit_poster.pdf has an A0 page box
#   make open       open the rendered PDF
#   make clean      remove generated artifacts
#
# PYTHON selects the interpreter for the A0 check (needs pypdf; auto-installed
# if missing). Override if python3 is not the one you want:
#   make check PYTHON=/Users/tim/conda/envs/pypeit/bin/python

PYTHON ?= python3
SIZE   ?= 1600

SOURCES := index.html styles.css palette.css

.PHONY: all poster render check preview open clean

all: poster preview

poster: render check

render: pypeit_poster.pdf

pypeit_poster.pdf: $(SOURCES)
	bash scripts/render.sh

check: pypeit_poster.pdf
	$(PYTHON) scripts/check_pdf.py

preview: preview.png

preview.png: $(SOURCES)
	bash scripts/preview.sh $(SIZE)

open: pypeit_poster.pdf
	open pypeit_poster.pdf

clean:
	rm -f pypeit_poster.pdf preview.png preview_full.png
