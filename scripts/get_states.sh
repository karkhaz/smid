#!/bin/sh
#
# Prints the names of the current-state images for each .sm file in
# the state-machines directory.
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

for f in state-machines/*.sm; do
  prog=`echo $f | awk -F/ '{print $2}' | awk -F. '{print $1}'`


  if [ -f images/states/$prog/.states ]; then

    for line in `cat images/states/$prog/.states`; do
      echo images/states/$prog/$line.png
    done

  fi
done
