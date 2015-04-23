#!/bin/sh
#
# Converts solarized colour names (like base03) into an alphabetical
# name that LaTeX can use as a command.
#
# Note that there should be no need to use actual colour names
# anywhere in the document, except in colours.tex where the stylesheet
# is defined. Thus, this script substitutes on colours.tex only.

sed                    \
  's/sbase03/sbaseq/g 
  s/sbase02/sbasew/g
  s/sbase01/sbasee/g
  s/sbase00/sbaser/g
  s/sbase0/sbaset/g
  s/sbase1/sbasey/g
  s/sbase2/sbaseu/g
  s/sbase3/sbasei/g'   \
  < colours.tex        \
  > colours-texified.tex
