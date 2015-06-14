(* Internal representation of parsed file.
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

type initial_state = string
type final_state = string


type hook = string

type state_hooks = (final_state * hook)

type click_side = Left | Right
type scroll_direction = Up | Down

type probability = High | Med | Low

type coordinates = (int * int * int * int)
type location = Coordinates of coordinates
              | Alias of string

type action = KeysAction of string list
            | TypeAction of string
            | LineAction of string
            | MoveAction of location
            | MoveRelAction of location
            | ClickAction of (click_side * int)
            | ScrollAction of (scroll_direction * int)
            | Probability of probability

type dest_state = DestState of string
                | Stay

type src_states = Additive    of string list
                | Subtractive of string list

type trans = (src_states * action list * dest_state)



type fsa_entry  = InitialStates  of initial_state list
                | FinalStates    of final_state list
                | PreStateHooks  of state_hooks
                | PostStateHooks of state_hooks
                | Transition     of trans
                | LocationAlias  of (string * coordinates)

type fsa = fsa_entry list

let pp_fsa fsa =
  let pp_tr line = ""
  in let pp_str_list lst =
    let tmp = L.fold_left (fun acc str ->
      match acc with
        | "]" -> str ^ " "  ^ acc
        | _   -> str ^ ", " ^ acc
    ) "]" lst
    in "[ " ^ tmp
  in let pp_hooks hooks =
    hooks ^ "\n"
  in let pp_is line = "initial: " ^ pp_str_list line
  in let pp_fs line = "final:   " ^ pp_str_list line
  in let pp_sh (state, hooks) =
    "Hooks for " ^ state ^ ": " ^ pp_hooks hooks
  in let pp_la la = "region"
  in L.fold_left (fun acc line ->
    let str = match line with
      | InitialStates l    -> (pp_is l) ^ "\n"
      | FinalStates l      -> (pp_fs l) ^ "\n"
      | PreStateHooks l    -> (pp_sh l) ^ "\n"
      | PostStateHooks l   -> (pp_sh l) ^ "\n"
      | Transition l       -> (pp_tr l) ^ "\n"
      | LocationAlias l    -> (pp_la l) ^ "\n"
    in str ^ acc
    ) "" fsa


