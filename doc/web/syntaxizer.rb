#!/usr/bin/env ruby
# Reads a .sm file, splits out a HTML version ready to be formatted
# with CSS.
# Copyright (C) 2015 Kareem Khazem

unless(ARGV.length == 1)
  printf($stderr, "Usage: #{$PROGRAM_NAME} SM_FILE\n")
  exit 1
end

unless(File.exists?(ARGV[0]))
  printf($stderr, "File <#{ARGV[0]}> not found\n")
  exit 1
end

file = File.read(ARGV[0])

transforms = [
[
  /^\s+\s/, "&nbsp;&nbsp;"
],
[
  /"(?<string>.+?)"/,
  '<span class="sm-literal">"\k<string>"</span>'
],
[
  /\((?<coords>.+?)\)/,
  '<span class="sm-literal">(\k<coords>)</span>'
],
[
  /\[(?<keys>.+?)\]/,
  '<span class="sm-literal">[\k<keys>]</span>'
],
[
  /\{(?<script>.+?)\}/m,
  '<span class="sm-script">{\k<script>}</span>'
],
[
  /^(?<comment>#.+)$/,
  '<span class="sm-comment">\k<comment></span>'
],
[
  /(?<kw>(
    all-except|all|stay|pre|post|initial|final|region
    ))/x,
  '<span class="sm-keyword">\k<kw></span>'
],
[
  /(?<kw>(
    keys|text|line|click|clik|scroll|scrl|move|move-rel|movr|prob
    ))/x,
  '<span class="sm-action">\k<kw></span>'
],
[
  /\n/, "<br />\n"
],
[
  /-->\s+(?<state>[-"><\/\w]+)/,
  '<span class="sm-transition">--&gt;</span> \k<state>'
],
[
  /(?<state>[-">\w]+)\s+--/,
  '\k<state> <span class="sm-transition">--</span>'
],

]

transforms.each do |pair|
  regex, replacement = pair
  file.gsub!(regex, replacement)
end

printf file
