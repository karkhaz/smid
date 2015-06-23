(* Program run derived from FSA
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


(** [to_json fsa run_length] returns a JSON-formatted run along [fsa].
 * The JSON document will have a key called "actions" whose value is a
 * a run (i.e. list of user interactions). The run will be along at
 * least [run_length] transitions along the state machine.
 *)
val to_json : FSA.fsa -> int -> string


(** [to_script fsa run_length] returns a Bash script for executing a
 * run along [fsa]. The script will execute a list of actions taken
 * from at least [run_length] transitions along the fsa.
 *)
val to_script : FSA.fsa -> int -> string

type result = Success | Fail

(** [execute fsa run_length] executes a sequence of user interactions
 * derived from walking along [fsa]. The actions will be taken from
 * at least [run_length] transitions over the fsa.
 *)
val execute : FSA.fsa -> int -> result
