(* FSA data structure, normalised from FileRep
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


module FR = FileRep
module S = String
module L = List
module C = Config
module U = Util
module TR = TRList
open Printf

type state = string
type hook = string
type _state_hook = (state * hook)
type state_hook = Pre  of _state_hook
                | Post of _state_hook

type type_action = {
  fname: string option;
  text:  string;
}

type click_side = Left | Right
type scroll_direction = Up | Down

type location = {
  region: string option;
  sx: int;
  sy: int;
  ex: int;
  ey: int;
}

type action = KeysAction of string list
            | TypeAction of type_action
            | MoveAction of location
            | MoveRelAction of location
            | ClickAction of (click_side * int)
            | ScrollAction of (scroll_direction * int)
            | ShellAction of string

type run = action list


type probability = High | Med | Low

type trans = {
  src:   state;
  acts:  action list;
  dst:   state;
  prob:  probability;
}

type fsa = {
  states: state list;
  inits:  state list;
  finals: state list;
  transs: trans list;
  hooks:  state_hook list;
}


(**  Checks for the following conditions:
 * - There exists at least one initial and one final state
 * - We never get to a state that is stuck
 * - No state is unreachable
 * - All states are reachable from some initial state
 * - All states can reach some final state
 *)
val is_sane : fsa -> bool

(** Turn a FileRep.fsa into an fsa *)
val normalise : FileRep.fsa -> fsa

(** Return some statistics about the fsa *)
val stats_of : fsa -> string

(** Return a Graphviz DOT-formatted representation of the fsa *)
val dot_of : fsa -> string

(** Return a Bash script-formatted run along the fsa *)
val script_of : fsa -> int -> string
