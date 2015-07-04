#!/usr/bin/ruby
# Executing a run output by smid in JSON format.
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



require 'json'



#=====================================================================
def main #============================================================
  smid_output = ARGF.read

  begin
    json = JSON.parse(smid_output)

  rescue JSON::ParserError => e
    printf($stderr, "Bad JSON from smid:\n")
    printf($stderr, "%s\n", smid_output.gsub(/^/, ('  ')))
    exit 1
  end

  json['actions'].each do |action|
    puts message_of(action)
    execute(action)
  end
end



#=====================================================================
def message_of action # ==============================================
  case action['type']
  when "key"
    "Sending <#{action['body']}> to window <#{$window}>"

  when "window-change"
    "Changing target window to <#{action['body']}>"

  when "type"
    text = action['body']['text']
    text = text[0..66] + "..." if text.length > 70
    file = action['body']['file']
    if(file)
      "Typing to window <#{$window}> from file <#{file}>:\n  <#{text}>"
    else
      "Typing to window <#{$window}>:\n<#{text.gsub(/^/,' ')}>"
    end

  when "move"
    x = action['body']['x']
    y = action['body']['y']
    region = action['body']['region']
    if(region)
      "Moving cursor to coords(#{x}, #{y})\n\
in region <#{region}> of window <#{$window}>"
    else
      "Moving cursor to coords(#{x}, #{y})\n\
in window <#{$window}>"
    end

  when "move_rel"
    x = action['body']['x']
    y = action['body']['y']
    x = if(x < 0) then "#{x} left" else "#{x} right" end
    y = if(y < 0) then "#{y} down" else "#{y} up" end
    region = action['body']['region']
    if(region)
      "Moving cursor by #{x} and #{y} in region <#{region}>"
    else
      "Moving cursor by #{x} and #{y}"
    end

  when "click"
    side = action['body']['side']
    freq = action['body']['freq']
    freq = case freq
           when 1 then "single";
           when 2 then "double";
           when 3 then "triple";
           else freq
           end
    "Sending a #{freq}-#{side} click to window <#{$window}>"

  when "scroll"
    dir  = action['body']['dir']
    dist = action['body']['dist']
    "Scrolling by #{dist} measures #{dir} in window <#{$window}>"

  when "shell"
    "Executing shell command\n<#{action['body'].gsub(/^/,'  ')}>"

  when "hook"
    position = action['body']['position']
    state = action['body']['state']
    "Running #{position}-hooks for state <#{state}>"

  when "state"
    from = action['body']['from']
    to = action['body']['to']
    "Changing state from <#{from}> to <#{to}>"

  when "delay"
    sprintf("Waiting for about %2.3fs", action['body'])

  else
    raise "Unknown action type #{action['type']}"

  end
end



#=====================================================================
def execute action #==================================================
  xsearch = "xdotool search --name \"#{$window}\" "

  case action['type']
  when "window-change"
    $window = action['body']

  when "key"
    system "#{xsearch}key --window %1 \"#{action['body']}\""

  when "type"
    text = action['body']['text']
    system "#{xsearch}type --window %1 \"#{text}\""

  when "move"
    x = action['body']['x']
    y = action['body']['y']
    cmd = "#{xsearch}mousemove --window %1 --clearmodifiers --sync"
    cmd += "#{x} #{y}"
    system cmd

  when "move_rel"
    x = action['body']['x']
    y = action['body']['y']
    cmd = "#{xsearch}mousemove_relative --window %1"
    cmd += "--clearmodifiers --sync #{x} #{y}"
    system cmd


  when "click"
    side = action['body']['side']
    side = if side == "left" then 1 elsif side == "right" then 3 end
    freq = action['body']['freq']
    cmd = "#{xsearch}click --clearmodifiers --repeat #{freq} #{side}"
    system cmd

  when "scroll"
    dir = action['body']['dir']
    dir = if dir == "up" then 4 elsif dir == "down" then 5 end
    dist = action['body']['dist']
    cmd = "#{xsearch}click --clearmodifiers --repeat #{dist} #{dir}"
    system cmd

  when "shell"
    system action['body']

  when "delay"
    sleep action['body']

  when "hook"
  when "state"

  else
    raise "Unknown action type #{action['type']}"

  end
end



# ====================================================================
# ====================================================================

main
