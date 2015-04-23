# FSA top-level Makefile
# Author: Kareem Khazem <karkhaz@karkhaz.com>
#   Date: 2015

FSA_FILES=$(wildcard examples/*.fsa)
FSA_DIAGRAMS=$(patsubst examples/%.fsa,out/%.png,$(FSA_FILES))

BIN=src/uidrive.native

SRC=$(wildcard src/*.ml) $(wildcard src/*.mll) \
		$(wildcard src/*.mly)

TARGETS=$(BIN)

default: $(TARGETS)

$(BIN): $(SRC)
	@echo Compiling
	@cd src && ocamlbuild -lib unix -lib str uidrive.native

clean:
	@rm $(TARGETS)
