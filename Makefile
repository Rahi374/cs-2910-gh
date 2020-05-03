DOT_FILES=$(wildcard img/*.dot)
DOTPNG=$(DOT_FILES:.dot=.png)
REPORT_SRC=report.org

%.png: %.dot
	dot -Tpng $< -o $@

cs-2910-paul-elder-report.pdf: $(DOTPNG) $(REPORT_SRC)
	pandoc $(REPORT_SRC) --pdf-engine=pdflatex -o $@
