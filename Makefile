# Makefile for LaTeX projects
#
# Copyright (c) 2007-2013 Fabian Fagerholm
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# The principle in this Makefile is to render all graphical content into
# PDF, and then compile the LaTeX and BibTeX files using rubber. The
# rendered PDFs are included into the resulting PDF document. No modifications
# to this file are needed as long as the following conventions are followed:
#
#  * All LaTeX files have a .tex extension.
#  * All BibTeX files have a .bib extension.
#  * All graphics files have a native extension or are saved into PDF.
#  * All files are in the same directory as this Makefile.
#
# PDFs can be placed directly into the main directory, and will not be cleaned
# away by this Makefile. This Makefile only cleans PDFs that it produces itself.
#
# To include a PDF figure in the resulting PDF, use the following LaTeX:
#   \begin{figure}
#    \begin{center}
#     \includegraphics[scale=0.5]{myfigurefile}
#    \end{center}
#    \caption{A nice Figure.}
#    \label{fig:myfigure}
#   \end{figure}
# where "myfigurefile" is the name of the PDF file without its .pdf extension.

TEXFILES := $(wildcard *.tex)
BIBFILES := $(wildcard *.bib)
SVGFILES := $(wildcard *.svg)
DIAFILES := $(wildcard *.dia)

STAMPFILES=$(SVGFILES:.svg=.svg.stamp) $(DIAFILES:.dia=.dia.stamp) $(TEXFILES:.tex=.tex.stamp)
CLEANFILES=$(STAMPFILES) $(SVGFILES:.svg=.pdf) $(DIAFILES:.dia=.pdf) $(TEXFILES:.tex=.pdf) $(TEXFILES:.tex=.synctex.gz) $(TEXFILES:.tex=.out) $(shell basename $(CURDIR)).zip $(shell basename $(CURDIR)).tar.xz

all: $(STAMPFILES)

zip: PROJDIR=$(shell basename $(CURDIR))
zip:
	git diff-index --exit-code --quiet HEAD; \
	if [ $$? -eq 0 ]; then TREEISH="HEAD"; else TREEISH=`git stash create`; fi ; \
	TIMESTAMP=`date +%M%m%d%H%M%S`; \
	git archive --prefix=$(PROJDIR)/ --output=$(PROJDIR)-$$TIMESTAMP.zip -9 $$TREEISH

txz: PROJDIR=$(shell basename $(CURDIR))
txz:
	@git diff-index --exit-code --quiet HEAD; \
	if [ $$? -eq 0 ]; then TREEISH="HEAD"; else TREEISH=`git stash create`; fi; \
	TIMESTAMP=`date +%M%m%d%H%M%S`; \
	git archive --prefix=$(PROJDIR)/ --output=$(PROJDIR)-$$TIMESTAMP.tar $$TREEISH; \
	xz $(PROJDIR)-$$TIMESTAMP.tar

clean:
	$(foreach tex,$(TEXFILES),rubber --pdf --clean $(tex);)
	@rm -fv $(CLEANFILES)
	@rm -fv *~ *~[0-9+] \#*\# *.stamp *.hst *.ver *.4ct *.4tc *.css \
	        *.dvi *.html *.idv *.lg *.tmp *.xref texput.log

.PHONY: all clean

# Target to make Word-compatible HTML
html: $(TEXFILES)
	$(foreach tex,$(TEXFILES),htlatex $(tex) 'html,word' 'symbol/!' '-cvalidate';)

# Target to compile LaTeX and BibTeX files into PDF
%.tex.stamp: %.tex $(BIBFILES)
	rubber --pdf $<
	@touch $@

# Target to compile SVG into PDF
%.svg.stamp: %.svg
	inkscape --without-gui --export-pdf=$(subst .svg.stamp,.pdf,$@) $<
	@touch $@

# Target to compile Dia into PDF
%.dia.stamp: %.dia
	dia --nosplash --filter=eps --export=$(subst .dia.stamp,.eps,$@) $<
	epstopdf -.stampfile=$(EPS) $<
	@touch $@

