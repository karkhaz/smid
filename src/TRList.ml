(* Tail-recursive versions of stdlib List functions
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

module L = List



let map ?(rev=false) f lst =
  let rec map f lst acc =
    match lst with
      | [] -> acc
      | h :: t -> map f t (f h :: acc)
  in if rev
     then L.rev (map f lst [])
     else map f lst []



let concat ?(rev=false) lst =
  let rec concat lst acc =
    match lst with
      | [] -> acc
      | [h] :: t ->
          concat t (h :: acc)
      | (h::t) :: t2 ->
          concat (t :: t2) (h :: acc)
      | [] :: t2 ->
          concat t2 acc
  in if rev
     then L.rev (concat lst [])
     else concat lst []
