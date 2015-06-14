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

FSA_FILES=$(wildcard examples/*.fsa)
FSA_DIAGRAMS=$(patsubst examples/%.fsa,out/%.png,$(FSA_FILES))

BIN=smid.native

LIBS=unix,str
FLAGS=-warn-error,+A,-safe-string,-g

SRC=$(wildcard src/*.ml) $(wildcard src/*.mll) \
		$(wildcard src/*.mly)

TARGETS=src/$(BIN) smid

default: $(TARGETS)

smid: src/$(BIN)

src/$(BIN): $(SRC)
	@echo Compiling
	@cd src && ocamlbuild -cflags $(FLAGS) -r -libs $(LIBS) -I lib $(BIN)

clean:
	@-rm -rf  src/$(BIN)  src/_build
