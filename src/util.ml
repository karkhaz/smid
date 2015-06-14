(* Miscellaneous utilities
 * Copyright (C) 2015 Kareem Khazem
 *
 * This file is part of smid.
 *
 * smid is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)

open Printf
module L = List

let lines_of_file fname =
  try
    let in_chan = open_in fname
    in let rec lines_of_file fname acc =
      try
        lines_of_file fname (input_line in_chan :: acc)
      with End_of_file -> acc
    in L.rev (lines_of_file fname [])
  with
    | Sys_error e ->
        eprintf "Error: could not read lines from %s:\n  %s\n"
          fname e
        ; exit 1

let random_from_list lst =
  let rec get_element lst idx =
    match lst with
      | h :: t -> (
        match idx with
          | 0 -> h
          | n -> get_element t (n - 1)
      )
      | [] -> assert false
  in let length = L.length lst
  in let index = Random.int length
  in get_element lst index
