# FSA top-level Makefile
# Author: Kareem Khazem <karkhaz@karkhaz.com>
#   Date: 2015

FSA_FILES=$(wildcard examples/*.fsa)
FSA_DIAGRAMS=$(patsubst examples/%.fsa,out/%.png,$(FSA_FILES))

BIN=src/uidrive.native
COPY=uidrive

SRC=$(wildcard src/*.ml) $(wildcard src/*.mll) \
		$(wildcard src/*.mly)

TARGETS=$(COPY)

default: $(TARGETS)

$(COPY): $(BIN)
	cp $< $@

$(BIN): $(SRC)
	@echo Compiling
	@cd src && ocamlbuild -lib unix -lib str uidrive.native

out/%.png: out/%.dot
	@circo -Tpng $< > $@

out/%.dot: examples/%.fsa  $(BIN)
	@echo Generating $(patsubst out/%dot,%png,$@) 1>&2
	@$(BIN) -d $< > $@

.PHONY: script

script: examples/cmus.fsa $(BIN)
	$(BIN) -r $<

clean:
	@rm $(TARGETS)
