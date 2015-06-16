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

type location = (string option * int * int * int * int)

type action = KeysAction of string list
            | TypeAction of type_action
            | MoveAction of location
            | MoveRelAction of location
            | ClickAction of (click_side * int)
            | ScrollAction of (scroll_direction * int)

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


(* Turn a FileRep.fsa into an fsa *)
let normalise frep =
  let coords_from_alias alias =
    let result = L.fold_left (fun acc e ->
      match e with
        | FR.LocationAlias (a, coords) ->
            if a = alias
            then Some coords
            else acc
        | _ -> acc
    ) None frep
    in match result with
      | Some coords -> coords
      | None -> failwith ("Unknown region '" ^ alias ^ "'")
  in let states_from_frep get_states_fun =
    let all_states = L.fold_left (fun acc entry ->
      acc @ (get_states_fun entry)
    ) [] frep
    in L.sort_uniq compare all_states
  in let get_all_states frep fsa =
    let get_states = function
      | FR.InitialStates e
      | FR.FinalStates   e -> e
      | FR.Transition (ss, _, d) -> (
          let d = match d with
            | FR.DestState s -> [s]
            | FR.Stay        -> []
          in match ss with
            | FR.Additive    lst
            | FR.Subtractive lst -> d @ lst
      )
      | FR.PreStateHooks (s, _) -> [s]
      | FR.PostStateHooks (s, _) -> [s]
      | FR.LocationAlias _ -> []
    in {fsa with states = states_from_frep get_states}
  in let get_inits frep fsa =
    let get_states = function
      | FR.InitialStates e -> e
      | _ -> []
    in {fsa with inits = states_from_frep get_states}
  in let get_finals frep fsa =
    let get_states = function
      | FR.FinalStates e -> e
      | _ -> []
    in {fsa with finals = states_from_frep get_states}

  in let get_hooks frep fsa =
    let hooks_of_entry = function
      | FR.PreStateHooks  (state, hooks) -> [Pre (state, hooks)]
      | FR.PostStateHooks (state, hooks) -> [Post (state, hooks)]
      | _ -> []
    in let hooks_from_frep =
      let all_states = L.fold_left (fun acc entry ->
        acc @ (hooks_of_entry entry)
      ) [] frep
      in L.sort_uniq compare all_states
    in {fsa with hooks = hooks_from_frep}

  in let get_transs frep fsa =
    let all_states = fsa.states
    (* FR.action list -> action list list *)
    in let conv_actions acts =
      let rec conv_actions acts acc =
        match acts with
        | [] -> acc
        | act :: t -> (
          match act with
            | FR.Probability _ -> conv_actions t acc
            | FR.MoveAction loc ->
                let coords = match loc with
                  | FR.Coordinates (sx, sy, ex, ey) ->
                      (None, sx, sy, ex, ey)
                  | FR.Alias s ->
                      let sx, sy, ex, ey = coords_from_alias s
                      in (Some s, sx, sy, ex, ey)
                in let new_acc = L.map (fun l ->
                  MoveAction coords :: l) acc
                in conv_actions t new_acc
            | FR.MoveRelAction loc ->
                let coords = match loc with
                  | FR.Coordinates (sx, sy, ex, ey) ->
                      (None, sx, sy, ex, ey)
                  | FR.Alias s ->
                      let sx, sy, ex, ey = coords_from_alias s
                      in (Some s, sx, sy, ex, ey)
                in let new_acc = L.map (fun l ->
                  MoveRelAction coords :: l) acc
                in conv_actions t new_acc
            | FR.ClickAction (s, n) ->
                let new_side = (
                  match s with
                    | FR.Left -> Left
                    | FR.Right -> Right
                ) in let new_acc = L.map (fun l ->
                  ClickAction (new_side, n) :: l) acc
                in conv_actions t new_acc
            | FR.ScrollAction (d, n) ->
                let new_direction = (
                  match d with
                    | FR.Up -> Up
                    | FR.Down -> Down
                ) in let new_acc = L.map (fun l ->
                  ScrollAction (new_direction, n) :: l) acc
                in conv_actions t new_acc
            | FR.KeysAction a ->
                let new_acc = L.map (fun l ->
                  KeysAction a :: l) acc
                in conv_actions t new_acc
            | FR.TypeAction a ->
                let new_acc = L.map (fun l ->
                  TypeAction {fname = None; text = a} :: l) acc
                in conv_actions t new_acc
            | FR.LineAction a ->
                let fname = !C.include_dir ^ "/" ^ a
                in let lines = Util.lines_of_file fname
                in let actions = L.map (fun l ->
                  TypeAction {fname = Some fname; text = l}
                ) lines
                in let new_acc = L.map (fun l ->
                  L.map (fun act ->
                    act :: l
                  ) actions
                ) acc
                |> L.flatten
                in conv_actions t new_acc
        )
      in let act_lists = conv_actions acts [[]]
      in L.map (L.rev) act_lists
    in let probability_of actions =
      L.fold_left (fun acc e ->
        match e with
          | FR.Probability p -> (
              match p with
                | FR.High -> High
                | FR.Med  -> Med
                | FR.Low  -> Low
          )
          | _ -> acc
      ) Med actions
    in let transs_of_entry = function
      | FR.Transition (srcs, acts, dst) ->
          let states = match srcs with
            | FR.Additive states -> states
            | FR.Subtractive states -> L.filter (fun e ->
                  not (
                      (List.mem e states)
                   || (List.mem e fsa.finals)
                  )
                ) all_states
          in let lst = L.map (fun state ->
            let conv_acts = conv_actions acts
            in let prob = probability_of acts
            in L.map (fun acts ->
              let dst = match dst with
                | FR.DestState s -> s
                | FR.Stay -> state
              in {src=state; acts; dst; prob}
            ) conv_acts
          ) states
          in L.flatten lst
      | _ -> []
    in let transs_from_frep =
      let all_transs = L.fold_left (fun acc entry ->
        acc @ (transs_of_entry entry)
      ) [] frep
      in L.sort_uniq compare all_transs
    in {fsa with transs = transs_from_frep}

  in let empty = {
    states = [];
    inits  = [];
    finals = [];
    transs = [];
    hooks  = [];
  }
  in empty
  |> get_all_states frep
  |> get_inits  frep
  |> get_finals frep
  |> get_hooks  frep
  |> get_transs frep



let stats_of {states; inits; finals; transs; hooks} =
  sprintf "%3d states\n%3d initial\n%3d final\n%3d hooks\n%3d \
     normalised transitions\n"
  (L.length states) (L.length inits) (L.length finals)
  (L.length hooks) (L.length transs)



(* Return a dot graph of an FSA *)
let dot_of fsa =
  let dot_escape str =
    str |> S.escaped
  in let string_of_coords sx sy ex ey =
    if ((ex = sx + 1) && (ey = sy + 1))
    then "(" ^ string_of_int sx ^ ", " ^ string_of_int sy ^ ")"
    else "(" ^ string_of_int sx ^ ", " ^ string_of_int sy ^ " - "
             ^ string_of_int ex ^ ", " ^ string_of_int ey ^ ")"
  in let dot_of_is inits =
    let dot_of_i init =
      init ^ " [style=filled, color=green];"
    in L.map dot_of_i inits
  in let dot_of_fs finals =
    let dot_of_f final =
      final ^ " [style=filled, color=red];"
    in L.map dot_of_f finals
  in let dot_of_ts transs =
    let dot_of_t {src; acts; dst} =
      let dot_of_act = function
        | ScrollAction (d, n) ->
            let dir = match d with
              | Up -> "ScrUp "
              | Down -> "ScrDown "
            in dir ^ "x" ^ (string_of_int n)
        | MoveAction (r, sx, sy, ex, ey) -> (
            match r with
              | None -> "move " ^ string_of_coords sx sy ex ey
              | Some region -> "move to '" ^ region ^ "'"
        )
        | MoveRelAction (_, sx, sy, ex, ey) ->
            "rel-move " ^ string_of_coords sx sy ex ey
        | ClickAction (side, freq) ->
            let side =
              match side with
                | Left -> "left"
                | Right -> "right"
            in let freq =
              match freq with
                | 1 -> "single"
                | 2 -> "double"
                | 3 -> "triple"
                | n -> (string_of_int n) ^ "x"
            in side ^ " " ^ freq ^ " click"
        | KeysAction a ->
          let keys = L.fold_left (fun acc key ->
              (dot_escape key) ^ " " ^ acc
            ) "" a
          in "[" ^ (S.trim keys) ^ "]"
        | TypeAction {fname; text} ->
            let str = match fname with
              | Some fname -> ">" ^ fname
              | None -> dot_escape text
            in "\\\"" ^ str ^ "\\\""
      in let dot_of_acts acts =
        let str = L.fold_left (fun acc act ->
          (dot_of_act act) ^ ";\n" ^ acc
          ) "" acts
        in S.sub str 0 (S.length str - 2)
      in let acts = dot_of_acts acts
      in let dst =
        if dst = src && !C.loops
        then "loop_to_" ^ dst
        else dst
      in src ^ " -> " ^ dst
       ^ " [label=\"" ^ acts ^ "\"];"
    in L.map dot_of_t transs
  in let lines =
    dot_of_is fsa.inits
    @ dot_of_fs fsa.finals
    @ dot_of_ts fsa.transs
  in let lines = L.sort_uniq compare lines
  in let body = L.fold_left (fun acc line ->
    "  " ^ line ^ "\n" ^ acc
      ) "" lines
  in "digraph G {\n  node [shape=box];\nrankdir=LR;\n  "
    ^ (S.trim body) ^ "\n}\n"



let script_of fsa run_length =
  (* get_nexts gets the transitions that could be taken away from
   * source. It doesn't get all of the transitions, since some
   * transitions might be labelled with probabilities (High, Med or
   * Low). This function returns a list of transitions from a single
   * probability category; a list of transitions is more likely to be
   * returned if its probability category is High than Med, etc.
   *)
  let get_nexts source =
    L.filter (fun {src; _} -> src = source) fsa.transs
  in let filter_by_probability outs =
    let highs = L.filter (fun {prob; _} -> prob = High) outs
    in let meds = L.filter  (fun {prob; _} -> prob = Med)  outs
    in let lows = L.filter  (fun {prob; _} -> prob = Low)  outs
    in let lst = [lows;meds;highs]
    in let lst = L.filter (fun l -> L.length l > 0) lst
    in let (h, t) = match lst with
      | h :: t -> (h, t)
      | [] -> failwith ("Stuck.")
    in L.fold_left (fun acc e ->
      let rand = Random.int 20
      in if rand = 0
      then acc
      else e
    ) h t
  in let random_delay =
    "r=$RANDOM; let \"r %=10\"; let \"r += 2\"; "
    ^ "sleep `bc -l <<< \"1 / $r\"`"
  in let pre_hooks_of state =
    let tmp = (fun sh -> match sh with
                          | Post (s, _) -> false
                          | Pre  (s, _) -> s = state)
    in if L.exists tmp fsa.hooks
    then let hooks = L.filter tmp fsa.hooks
         in let hooks = L.map (fun h -> match h with
                                | Pre (s, h) -> (s, h)
                                | Post _ -> (* filtered above *)
                                    assert false
                              ) hooks
         in let b = "\n# Pre-hooks for <" ^ state ^ ">:\n"
         in let e = "# End of pre-hooks for <" ^ state ^ ">\n"
         in let hooks = L.fold_left (fun acc (_, hook) ->
           (S.trim hook) ^ "\n" ^ acc
         ) "" hooks
         in b ^ hooks ^ e
    else ""
  in let post_hooks_of state =
    let tmp = (fun sh -> match sh with
                          | Pre  (s, _) -> false
                          | Post (s, _) -> s = state)
    in if L.exists tmp fsa.hooks
    then let hooks = L.filter tmp fsa.hooks
         in let hooks = L.map (fun h -> match h with
                                | Post (s, h) -> (s, h)
                                | Pre  _ -> (* filtered above *)
                                    assert false
                              ) hooks
         in let b = "\n# Post-hooks for <" ^ state ^ ">:\n"
         in let e = "# End of post-hooks for <" ^ state ^ ">\n"
         in let hooks = L.fold_left (fun acc (_, hook) ->
           (S.trim hook) ^ "\n" ^ acc
         ) "" hooks
         in b ^ hooks ^ e
    else ""
  in let acts_to_s acts =
    let script_of_keys keys =
      let script = L.map (fun key ->
        let key = S.escaped key
        in let cmd = "xdotool search --name \"$WINDOW_NAME\" key " ^ key
        in cmd ^ "\necho " ^ cmd ^ "\n" ^ random_delay ^ "\n"
      ) keys
      in L.fold_left (fun acc line ->
        line ^ "\n" ^ acc
      ) "" script
    in let script_of_type {fname; text} =
      let comment = match fname with
        | None -> ""
        | Some f-> "# Typing string from file <" ^ f ^ ">:\n"
      in let cmd = "xdotool search --name \"$WINDOW_NAME\" type --window \
                    %1 \"" ^ text ^ "\""
      in comment ^ cmd ^ "\necho " ^ cmd ^ "\n" ^ random_delay ^ "\n"
    in let coords_of_region sx sy ex ey =
      let x_range = ex - sx
      in let x_range = if x_range >= 0
      then x_range
      else failwith ("Bad range: " ^ (string_of_int sx)
                  ^  "-" ^ (string_of_int ex))
      in let rand = if x_range = 0
      then 0
      else Random.int x_range
      in let x = sx + rand
      in let y_range = ey - sy
      in let y_range = if y_range >= 0
      then y_range
      else failwith ("Bad range: " ^ (string_of_int sy)
                  ^  "-" ^ (string_of_int ey))
      in let rand = if y_range = 0
      then 0
      else Random.int y_range
      in let y = sy + rand
      in (x, y)
    in let script_of_move sx sy ex ey =
      let (x, y) = coords_of_region sx sy ex ey
      in let cmd = "xdotool search --name \"$WINDOW_NAME\" "
        ^ "mousemove --window %1 --clearmodifiers --sync "
        ^ (string_of_int x) ^ " " ^ (string_of_int y)
        in cmd ^ "\necho " ^ cmd ^ "\n" ^ random_delay ^ "\n"
    in let script_of_move_rel sx sy ex ey =
      let (x, y) = coords_of_region sx sy ex ey
      in let cmd = "xdotool "
        ^ "mousemove_relative --clearmodifiers --sync "
        ^ (string_of_int x) ^ " " ^ (string_of_int y)
        in cmd ^ "\necho " ^ cmd ^ "\n" ^ random_delay ^ "\n"
    in let script_of_click side freq=
      let button = match side with
        | Left ->  "1"
        | Right -> "3"
      in let cmd = "xdotool search --name \"$WINDOW_NAME\" "
                 ^ "click --clearmodifiers "
                 ^ " --repeat " ^ (string_of_int freq)
                 ^ " " ^ button
        in cmd ^ "\necho " ^ cmd ^ "\n" ^ random_delay ^ "\n"
    in let script_of_scroll dir freq=
      let button = match dir with
        | Up ->  "4"
        | Down -> "5"
      in let cmd = "xdotool search --name \"$WINDOW_NAME\" "
                 ^ "click --clearmodifiers "
                 ^ " --repeat " ^ (string_of_int freq)
                 ^ " " ^ button
        in cmd ^ "\necho " ^ cmd ^ "\n" ^ random_delay ^ "\n"
    in let act_to_s  = function
      | KeysAction keys -> script_of_keys keys
      | TypeAction str  -> script_of_type str
      | MoveAction (_, sx, sy, ex, ey) ->
          script_of_move sx sy ex ey
      | MoveRelAction (_, sx, sy, ex, ey) ->
          script_of_move_rel sx sy ex ey
      | ClickAction (side, freq)  -> script_of_click side freq
      | ScrollAction (dir, freq)  -> script_of_scroll dir freq
    in L.fold_left (fun acc act ->
      (act_to_s act) ^ "\n" ^ acc
    ) "" acts
  in let add_trans trans acc =
    let trans_to_s {src; acts; dst} =
      let comment =
        if src = dst
        then ""
        else
          let post_hooks = post_hooks_of src in
          let banner = "Changing from state <" ^ src ^
                        "> to <" ^ dst ^ ">"
          in let length = S.length banner
          in let eq = (70 - length) / 2
          in let eq = S.make eq '='
          in let pre_hooks = pre_hooks_of dst
          in "\n" ^ pre_hooks ^ "\n# " ^ eq ^
             " " ^ banner ^ " " ^ eq ^ "\n\n" ^
             post_hooks ^ "\n"
      in comment ^ (acts_to_s acts)
    in (trans_to_s trans) :: acc
  in let is_final {src; acts; dst} = L.mem dst fsa.finals
  in let rec script_of fsa run_length curr acc =
    match run_length with
      | 0 ->
          let nexts = get_nexts curr
          in  if  L.exists is_final nexts
              then let {src; acts; dst} = L.find is_final nexts
                   in (dst, (add_trans (L.find is_final nexts) acc))
              else let nexts = filter_by_probability nexts
                   in let {src; _} as next = U.random_from_list nexts
                   in script_of fsa 0 src (add_trans next acc)
      | n ->
          let nexts = get_nexts curr
          in let nexts = L.filter (fun s -> not (is_final s)) nexts
          in let nexts = filter_by_probability nexts
          in let {src; acts; dst} as next = U.random_from_list nexts
          in script_of fsa (n - 1) dst (add_trans next acc)
  in let start_state = U.random_from_list fsa.inits
  in let final_state, script = script_of fsa run_length start_state []
  in let script = L.fold_left (fun acc line ->
    line ^ acc
  ) "" script
  in "#!/bin/bash\n" ^
     (pre_hooks_of start_state) ^ script ^ (post_hooks_of final_state)
