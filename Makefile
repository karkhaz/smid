# FSA top-level Makefile
# Author: Kareem Khazem <karkhaz@karkhaz.com>
#   Date: 2015

FSA_FILES=$(wildcard examples/*.fsa)
FSA_DIAGRAMS=$(patsubst examples/%.fsa,out/%.png,$(FSA_FILES))

BIN=uidrive.native

SRC=$(wildcard src/*.ml) $(wildcard src/*.mll) \
		$(wildcard src/*.mly)

TARGETS=src/$(BIN)

default: $(TARGETS)

src/$(BIN): $(SRC)
	@echo Compiling
	@cd src && ocamlbuild -lib unix -lib str $(BIN)

clean:
	@-rm -rf  src/$(BIN)  src/_build
