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


module F = FSA
module S = String
module L = List
module C = Config
module U = Util
module TR = TRList
module J = Yojson
open Printf

type _state_hook = { state: string; hook: string; }
type state_hook = Pre  of _state_hook
                | Post of _state_hook

type type_action  = { fname: string option; text:  string; }
type state_change = { src: string; dst: string; }

type click_side = Left | Right
type scroll_direction = Up | Down

type location = (string option * int * int * int * int)

type action = KeysAction of string list
            | TypeAction of type_action
            | MoveAction of location
            | MoveRelAction of location
            | ClickAction of (click_side * int)
            | ScrollAction of (scroll_direction * int)
            | ShellAction of string
            | HookAction of state_hook
            | StateChangeAction of state_change
            | DelayAction of float
            | DebugAction of string
            | PrintAction of string

type run = action list

let run_of fsa run_length =
  let get_nexts source =
    L.filter (fun {F.src; _} -> src = source) fsa.F.transs
  in let filter_by_probability outs =
    let highs =   L.filter (fun {F.prob; _} -> prob = F.High) outs
    in let meds = L.filter (fun {F.prob; _} -> prob = F.Med) outs
    in let lows = L.filter (fun {F.prob; _} -> prob = F.Low) outs
    in let lst = [lows;meds;highs]
    in let lst = L.filter (fun l -> (L.length l) > 0) lst
    in let (h, t) = match lst with
      | h :: t -> (h, t)
      | [] -> (* impossible, this implies that there were no
               * transitions away from the current state. This should
               * have been taken care of by the is_sane function.
               *) failwith ("Stuck")
    in L.fold_left (fun acc e ->
      let rand = Random.int 20
      in if rand = 0 then acc else e
    ) h t
  in let hooks_of state pre_or_post =
    let {F.hooks; _} = fsa in
    let hooks = L.filter (fun hook -> match (hook, pre_or_post) with
      | (F.Post (s, _), `Post) -> s = state
      | (F.Pre  (s, _), `Pre ) -> s = state
      | (_          , _    ) -> false
    ) hooks
    in L.map (function
      | F.Post (state, hook) -> Post {state; hook}
      | F.Pre (state, hook)  -> Pre  {state; hook}
    ) hooks
  in let goes_to_final {F.dst; _} =
    let {F.finals; _} = fsa in L.mem dst finals
  (* builds a run backwards. This is later reversed by add_hooks *)
  in let rec build_run cur_state length acc =
    let nexts = get_nexts cur_state
    in match length with
      | 0 ->
          let final_transs = L.filter goes_to_final nexts
          in (
          match final_transs with
            | [] -> build_run cur_state 1 acc
            | lst -> let trans = lst
                  |> filter_by_probability
                  |> U.random_from_list
                  in trans :: acc
          )
      | n ->
          let trans = nexts
          |> L.filter (fun trans -> not (goes_to_final trans))
          |> filter_by_probability
          |> U.random_from_list
          in let new_acc = trans :: acc
          in let {F.dst = new_state; _} = trans
          in build_run new_state (n - 1) new_acc
  in let to_actions transs =
    let final_trans = match transs with
      | [] -> (* runs can't be empty *) failwith "Empty run"
      | h :: _ -> h
    in let fake_trans = {
      F.src = final_trans.F.dst; F.acts = [];
      F.dst = "__fake_state"; F.prob = F.Med; }
    in let transs = fake_trans :: transs
    in let rec to_actions transs acc =
      let mk_delay () =
        (Random.float 10.0) +. 2.0
      in let add_hooks state pre_or_post actions =
        let hooks = hooks_of state pre_or_post
        in if L.length hooks = 0
        then actions
        else HookAction (L.hd hooks) :: actions
      in let add_actions fsa_acts run_acts =
        L.fold_right (fun fsa_act run_acts ->
          let fsa_act = match fsa_act with
            | F.KeysAction keys -> KeysAction keys
            | F.TypeAction {F.fname;F.text} ->
                TypeAction {fname;    text}
            | F.MoveAction (r,sx,sy,ex,ey) ->
                MoveAction (r,sx,sy,ex,ey)
            | F.MoveRelAction (r,sx,sy,ex,ey) ->
                MoveRelAction (r,sx,sy,ex,ey)
            | F.ClickAction (F.Left,  i) -> ClickAction (Left,  i)
            | F.ClickAction (F.Right, i) -> ClickAction (Right, i)
            | F.ScrollAction (F.Up,   i) -> ScrollAction (Up,   i)
            | F.ScrollAction (F.Down, i) -> ScrollAction (Down, i)
            | F.ShellAction s -> ShellAction s
          in fsa_act :: run_acts
        ) fsa_acts run_acts
      in match transs with
        | [] -> acc
        | {F.src;F.acts;F.dst;_} :: t -> let actions = []
          in let actions = DelayAction (mk_delay ()) :: actions
          in let actions = add_hooks dst `Pre  actions
          in let actions = add_actions acts actions
          in let actions = add_hooks src `Post actions
          in let actions = StateChangeAction {src;dst} :: actions
          in let new_acc = L.append actions acc
          in to_actions t new_acc
    in to_actions transs []
  in let {F.inits; _} = fsa
  in let initial = U.random_from_list inits
  in let transitions = build_run initial run_length []
  in let actions = to_actions transitions
  in let drop_3 lst =
    let rec drop_3 lst acc =
      match lst with
        | [_;_;_] -> acc
        | h :: t  -> drop_3 t (h :: acc)
        | [] -> (* impossible *) failwith "Empty run"
    in L.rev (drop_3 lst [])
  in drop_3 actions





let to_json run =
  let to_json = function
    | KeysAction keys ->
        let head = ("type", `String "keys")
        in let keys = `List (L.map (fun key -> `String key) keys)
        in let body = ("body", keys)
        in `Assoc [head; body]
    | TypeAction {fname; text} ->
        let head = ("type", `String "type")
        in let fname = match fname with
          | Some f -> `String f
          | None   -> `Null
        in let body = `Assoc [
          ("text", `String text);
          ("file", fname)
        ]
        in let body = ("body", body)
        in `Assoc [head; body]
    | MoveAction (r, sx, sy, ex, ey) ->
        let head = ("type", `String "move")
        in let region = match r with
          | Some r -> `String r
          | None -> `Null
        in let body = `Assoc [
          ("region",   region);
          ("start-x", `Int sx);
          ("end-x",   `Int ex);
          ("start-y", `Int sy);
          ("end-y",   `Int ey)
        ]
        in let body = ("body", body)
        in `Assoc [head; body]
    | MoveRelAction (r, sx, sy, ex, ey) ->
        let head = ("type", `String "move_rel")
        in let region = match r with
          | Some r -> `String r
          | None -> `Null
        in let body = `Assoc [
          ("region",   region);
          ("start-x", `Int sx);
          ("end-x",   `Int ex);
          ("start-y", `Int sy);
          ("end-y",   `Int ey)
        ]
        in let body = ("body", body)
        in `Assoc [head; body]
    | ClickAction (side, freq) ->
        let head = ("type", `String "click")
        in let side = match side with
          | Left  -> `String "left"
          | Right -> `String "right"
        in let body = `Assoc [
          ("side", side);
          ("frequency", `Int freq)
        ]
        in let body = ("body", body)
        in `Assoc [head; body]
    | ScrollAction (dir, dist) ->
        let head = ("type", `String "scroll")
        in let dir = match dir with
          | Up   -> `String "up"
          | Down -> `String "down"
        in let body = `Assoc [
          ("dir", dir);
          ("distance", `Int dist)
        ]
        in let body = ("body", body)
        in `Assoc [head; body]
    | ShellAction cmd ->
        let head = ("type", `String "shell")
        in let body = `String cmd
        in let body = ("body", body)
        in `Assoc [head; body]
    | HookAction h ->
        let head = ("type", `String "hook")
        in let position, state, hook = match h with
          | Pre  {state; hook} -> "pre",  state, hook
          | Post {state; hook} -> "post", state, hook
        in let body = `Assoc [
          ("position", `String position);
          ("state",    `String state);
          ("hook",     `String hook)
        ]
        in let body = ("body", body)
        in `Assoc [head; body]
    | StateChangeAction {src; dst} ->
        let head = ("type", `String "state")
        in let body = `Assoc [
          ("from", `String src);
          ("to",   `String dst)
        ]
        in let body = ("body", body)
        in `Assoc [head; body]
    | DelayAction d ->
        let head = ("type", `String "delay")
        in let body = `Float d
        in let body = ("body", body)
        in `Assoc [head; body]
    | _ -> `Null
  in let lst = `List (L.map (fun act -> to_json act) run)
  in let json = `Assoc [("actions", lst)]
  in J.pretty_to_string json
