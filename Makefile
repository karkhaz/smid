# smid top-level Makefile
#
# Copyright (C) 2015 Kareem Khazem
#
# This file is part of smid.
#
# smid is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

DOT=circo
XDOTOOL=xdotool
AWK=awk
OCB=ocamlbuild
OCF=ocamlfind
OCO=ocamlopt
OPAM=opam

SMID_FILES=$(wildcard state-machines/*.sm)
SMID_DIAGRAMS=$(patsubst state-machines/%.sm,images/%.png,$(SMID_FILES))

TMP_DIR=/tmp/smid

BIN=smid.native

LIBS=unix,str
CFLAGS=-safe-string,-g,-warn-error,+A
FLAGS= -quiet -r -j 0 -I src -use-ocamlfind \
			 -cflags $(CFLAGS) -libs $(LIBS)

SRC=$(wildcard src/*.ml) $(wildcard src/*.mll) $(wildcard src/*.mly)

TARGETS=smid $(SMID_DIAGRAMS) documentation

default: $(TARGETS)

smid: src/$(BIN)

documentation:
	@cd doc && make


src/$(BIN): $(SRC)
	@echo Building smid
	@$(OCB) $(FLAGS) src/$(BIN)


$(TMP_DIR)/%.dot: state-machines/%.sm $(wildcard support-files/%/*) $(BIN)
	@echo Generating $(notdir $@)
	@mkdir -p $(TMP_DIR)
	@./$(BIN) -d --include-dir support-files/$(notdir $(basename $@)) $< > $@

images/%.png: $(TMP_DIR)/%.dot
	@echo Generating $@
	@mkdir -p $(dir $@)
	@$(DOT) -Tpng $<  >  $@


# Non-default targets ================================================

.PHONY: clean
clean:
	@-rm -rf  src/$(BIN)  src/_build  images/*

.PHONY: vimfiles
vimfiles: $(wildcard vim/*/*)
	@mkdir -p ~/.vim/ftdetect
	@mkdir -p ~/.vim/syntax
	@cp vim/syntax/sm.vim ~/.vim/syntax
	@cp vim/ftdetect/sm.vim ~/.vim/ftdetect

.PHONY: check
check:
	@which $(AWK)
	@which $(DOT)
	@which $(XDOTOOL)
	@which $(OCB)
	@which $(OCO)
	@which $(OPAM)
	@which $(OCF)
	@echo -n "OCaml version " && $(OCO) -version
	@test `$(OCO) -version | $(AWK) -F . '{print $$1 $$2}'` -ge 402
	@echo -n "yojson version: "
	@$(OPAM) list | $(AWK) '{print $$1}' | grep yojson > /dev/null \
		&& $(OPAM) info yojson | grep installed-version | $(AWK) '{print $$2}' \
		|| (echo NOT INSTALLED && exit 1)


# Tests ==============================================================

SHOULD_FAIL=$(wildcard tests/should_fail/*.sm)
SHOULD_PASS=$(wildcard tests/should_pass/*.sm)

test: $(SHOULD_PASS) $(SHOULD_FAIL)

tests/should_fail/%.sm: $(BIN)
	@! ./$(BIN) -c $@ 2>/dev/null || echo "Unexpected pass:" $(notdir $@)

tests/should_pass/%.sm: $(BIN)
	@./$(BIN) -c $@ || echo "Unexpected fail: " $(notdir $@)
