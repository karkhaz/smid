#!/usr/bin/env ruby
# Adds nice colours (solarized) to dot files

bg    = "#fdf6e3"
bghl  = "#eee8d5"
fg    = "#657b83"
fghl  = "#586e75"
cyan  = "#2aa198"
red   = "#dc322f"

dot_file = ARGF.read.split(/\n/)

formatting = "  node [style='filled', color='#{bghl}'];
  node [fontcolor='#{fghl}', fontsize=11, fontname='Verdana']
  graph [bgcolor='#{bg}'];
  edge [color='#{red}', fontcolor='#{cyan}', fontsize=11];
  edge [fontname='Verdana'];
"

formatting.gsub!(/'/, '"')

dot_file = [dot_file[0]].concat([formatting]).concat(dot_file[1..-1])

dot_file.each {|l| puts l}
