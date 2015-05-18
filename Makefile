# FSA top-level Makefile
# Author: Kareem Khazem <karkhaz@karkhaz.com>
#   Date: 2015

FSA_FILES=$(wildcard examples/*.fsa)
FSA_DIAGRAMS=$(patsubst examples/%.fsa,out/%.png,$(FSA_FILES))

BIN=uidrive.native

LIBS=unix,str
FLAGS=-warn-error,+A,-safe-string,-g

SRC=$(wildcard src/*.ml) $(wildcard src/*.mll) \
		$(wildcard src/*.mly)

TARGETS=src/$(BIN)

default: $(TARGETS)

src/$(BIN): $(SRC)
	@echo Compiling
	@cd src && ocamlbuild -cflags $(FLAGS) -r -libs $(LIBS) -I lib $(BIN)

clean:
	@-rm -rf  src/$(BIN)  src/_build
