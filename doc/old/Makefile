MAKEFLAGS=-j

FSA_FILES=$(wildcard fsa_files/*)

PNG_IMAGES= $(patsubst fsa_files/%.fsa,images/%.ps.png,$(FSA_FILES))
PS_IMAGES = $(patsubst fsa_files/%.fsa,images/%.ps,$(FSA_FILES))
IMAGES = $(PNG_IMAGES) $(PS_IMAGES)

TARGETS = out/index.html $(IMAGES)

DOT=dot

default: $(TARGETS)

out/index.html: out/ui_driver.html
	@hacha -tocbis -o $@ $<

out/ui_driver.html: ui_driver.tex $(IMAGES) macros.hva macros.tex \
	colours-texified.tex global.css
	@mkdir -p out
	@hevea -fix -o $@ macros.hva $<
	@cp -r *.otf *.ttf global.css images out

images/sour_stay.dot: fsa_files/sour_stay.fsa ../uidrive
	@../uidrive --loops -d $<    \
		| ./process_dot.rb \
		> $@

images/%.dot: fsa_files/%.fsa ../uidrive
	@mkdir -p images
	@../uidrive -d $<    \
		| ./process_dot.rb \
		> $@

images/%.ps: images/%.dot
	@mkdir -p images
	@$(DOT) -Tps   $<  >  $@

images/%.ps.png: images/%.dot
	@mkdir -p images
	@$(DOT) -Tpng  $<  >  $@

colours-texified.tex: colours.tex
	@./texify_colours.sh

.PHONY: clean
clean:
	@rm -rf $(TARGETS)
