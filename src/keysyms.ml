(* Functions to determine valid keystrokes
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


module S = String
module L = List
include KeysymList

let lower_cased = L.map (fun str ->
  (S.lowercase str), str
) keysyms

let title_cased = L.map (fun (lc, original) ->
  let first = S.get lc 0 |> S.make 1 |> S.uppercase
  in let rest = S.sub lc 1 ((S.length lc) - 1)
  in (S.concat "" [first;rest]), original
) lower_cased

type validity = Valid
              | Corrected of string
              | Invalid

let valid keystroke =
  let split = Str.split (Str.regexp "\\+")
  in let keys = split keystroke
  in L.fold_left (fun acc key ->
    if L.mem key keysyms then acc
    else if L.mem_assoc key lower_cased
    then Corrected (L.assoc key lower_cased)
    else if L.mem_assoc key title_cased
    then Corrected (L.assoc key title_cased)
    else Invalid
  ) Valid keys

