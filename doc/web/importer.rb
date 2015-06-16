#!/usr/bin/env ruby
# Places HTML versions of .sm documents wherever they are imported
# into a markdown file using @import "filename"
# Copyright (C) 2015 Kareem Khazem

# Takes a file on stdin.
file = ARGF.read
new_file = ""

counter = 0
file.each_line do |line|
  counter += 1
  if(m = line.match(/^@import\s+(?<filename>.+)$/))
     sm_file = m[:filename]
     unless File.exists?(sm_file)
       puts "#{file}:#{counter}:0: #{sm_file} not found."
     end
     html = `./web/syntaxizer.rb #{sm_file}`
     new_file += html
  else
    new_file += line
  end
end

puts new_file
