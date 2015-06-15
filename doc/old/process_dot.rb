#!/usr/bin/ruby

file = ARGF.read

fg="\"#073642\""
red="\"#dc322f\""
green="\"#859900\""

file.gsub! /\=red/,   "=#{red}; fontcolor=#{fg};"
file.gsub! /\=green/, "=#{green}; fontcolor=#{fg};"

file.gsub! /digraph G {/,
  "digraph G {\n\
  rankdir=LR;\n\
  bgcolor=\"#fdf6e3\";\n\
  edge [color=#{fg};fontcolor=#{fg};]\n\
  node [color=#{fg};fontcolor=#{fg};]\n\
  "


#}}

puts file
