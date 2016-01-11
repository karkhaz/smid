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

type initial_state = string
type final_state = string


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
            | ShellAction of string
            | MoveRelAction of location
            | ClickAction of (click_side * int)
            | ScrollAction of (scroll_direction * int)
            | Probability of probability
            | WindowChange of string

type dest_state = DestState of string
                | Stay

type src_states = Additive    of string list
                | Subtractive of string list

type trans = (src_states * action list * dest_state)

type pre_post = Pre | Post
type hook = (pre_post * string list * action list)

type fsa_entry  = InitialStates  of initial_state list
                | FinalStates    of final_state list
                | Hook           of hook
                | Transition     of trans
                | LocationAlias  of (string * coordinates)

type fsa = fsa_entry list

let number_of_transitions fsa = List.length fsa
