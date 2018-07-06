##############################################################################
#  GetArg command-line option parser                                         #
#  Copyright (C) 2012-2018 Quentin Heath                                     #
#                                                                            #
#  This program is free software: you can redistribute it and/or modify      #
#  it under the terms of the GNU General Public License as published by      #
#  the Free Software Foundation, either version 3 of the License, or         #
#  (at your option) any later version.                                       #
#                                                                            #
#  This program is distributed in the hope that it will be useful,           #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of            #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             #
#  GNU General Public License for more details.                              #
#                                                                            #
#  You should have received a copy of the GNU General Public License         #
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.     #
##############################################################################

LIB_NAME = getarg

#
# PROGRAMS
#
##############################################################################

SHELL		= bash
OCAMLBUILD	= ocamlbuild \
		  -use-ocamlfind \
		  -use-menhir \
		  -yaccflag -v \
		  -cflags -warn-error,A \
		  -docflags -stars,-m,A \
		  -quiet


#
# FILES
#
##############################################################################

OCAML_FILES	= src/test.ml \
		  src/META \
		  src/$(LIB_NAME).mllib \
		  src/getArg.ml \
		  src/getArg.mli \
		  src.odocl

BUILD_FILES	= _build/src/getArg.cmi \
		  _build/src/$(LIB_NAME).cma \
		  _build/src/$(LIB_NAME).cmxa \
		  _build/src/$(LIB_NAME).a


#
# BUILDING
#
##############################################################################

.PHONY: build

build: $(BUILD_FILES)

_build/src/getArg.cmi: $(OCAML_FILES)
	@$(OCAMLBUILD) $(patsubst _build/%,%,$@)

_build/src/$(LIB_NAME).cma: $(OCAML_FILES)
	@$(OCAMLBUILD) $(patsubst _build/%,%,$@)

_build/src/$(LIB_NAME).cmxa _build/src/$(LIB_NAME).a: $(OCAML_FILES)
	@$(OCAMLBUILD) $(patsubst _build/%,%,$@)


#
# TESTING
#
##############################################################################

.PHONY: test

test: _build/src/test.byte
	$< --help
	$< -abfoo -ac42 --alpha bar --gamma 44 --delta 45 --gamma=46 --delta=47

_build/src/test.byte: $(OCAML_FILES)
	@$(OCAMLBUILD) $(patsubst _build/%,%,$@)


#
# DOC
#
##############################################################################

.PHONY: doc

_build/src.docdir/index.html: $(OCAML_FILES)
	@$(OCAMLBUILD) src.docdir/index.html

doc: _build/src.docdir/index.html


#
# (UN)INSTALL
#
##############################################################################

.PHONY: install_lib

install_lib: src/META $(BUILD_FILES) _build/src/getArg.mli
	@ocamlfind install $(LIB_NAME) $^

uninstall_lib:
	@ocamlfind remove $(LIB_NAME)


#
# OTHER TARGETS
#
##############################################################################

.PHONY: clean distclean

clean:
	@[[ -x _build/sanitize.sh ]] && _build/sanitize.sh || true
	@$(OCAMLBUILD) -clean

distclean: clean
	@find . -name '*~' -exec rm -vf \{\} \;
