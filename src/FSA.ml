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
            | WindowChange of string

type pre_post = Pre | Post
type hook = (pre_post * state * action list)

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
  hooks:  hook list;
}


let error str =
  match !Config.fsa_file with
    | None -> (* impossible *) failwith "Empty fsa file"
    | Some file -> eprintf "%s:0:0: %s\n%!" file str

(* Checks for the following conditions:
 * - There exists at least one initial and one final state
 * - We never get to a state that is stuck
 * - No state is unreachable
 * - All states are reachable from some initial state
 * - All states can reach some final state
 * - All states have no more than one pre-hook and no more than one
 *   post-hook
 * - All initial states have a pre-hook that specifies a window change
 *)
let is_sane fsa =
  let check_hooks fsa =
    let {hooks; states; _} = fsa
    in L.fold_left (fun acc state ->
      let pre_hooks = L.filter (fun (pp, s, _) ->
        match pp with Pre -> s = state | Post -> false
      ) hooks
      in let post_hooks = L.filter (fun (pp, s, _) ->
        match pp with Post -> s = state | Pre -> false
      ) hooks
      in if (L.length pre_hooks) <= 1  &&  (L.length post_hooks) <= 1
      then acc
      else if (L.length pre_hooks) <= 1
      then (error
      (sprintf "State <%s> has more than one post hook" state); false)
      else (* L.length post_hooks) <= 1 *)
      (error
      (sprintf "State <%s> has more than one pre hook" state); false)
    ) true states
  in let initials_have_windows fsa =
    let {hooks; inits; _} = fsa
    in L.fold_left (fun acc state ->
      let has_window = L.fold_left (fun acc hook ->
        let (_, _, actions) = hook
        in L.fold_left (fun acc action ->
          match action with
            | WindowChange _ -> true
            | _ -> acc
        ) false actions
      ) false hooks
      in if has_window
      then acc
      else (error (sprintf
      "Initial state <%s> does not set a window target" state) ; false)
    ) true inits
  in let inits_and_finals {inits=inits; finals=finals; _} =
    let _inits inits =
      if L.length inits > 0
      then true
      else (error (sprintf "No initial states"); false)
    in let _finals finals =
      if L.length finals > 0
      then true
      else (error (sprintf "No final states"); false)
    in (_inits inits) && (_finals finals)
  in let never_stuck {states = states; transs = transs; finals=finals} =
    let stucks = L.filter (fun state ->
      not (L.exists (fun {src = src; _} ->
        state = src
      ) transs)
    ) states
    in let stucks = L.filter (fun state ->
          not (L.mem state finals)
       ) stucks
    in L.fold_left (fun acc stuck_state ->
      error
      (sprintf "No outgoing transitions from state <%s>" stuck_state)
      ; false
    ) true stucks
  in let no_unreachable {states = states; transs = transs; inits=inits} =
    let unreachs = L.filter (fun state ->
      not (L.exists (fun {dst = dst; _} ->
        state = dst
      ) transs)
    ) states
    in let unreachs = L.filter (fun state ->
          not (L.mem state inits)
       ) unreachs
    in L.fold_left (fun acc unreach_state ->
      error
      (sprintf "No incoming transitions to state <%s>" unreach_state)
      ; false
    ) true unreachs
  in let all_reachable_from_init {inits=is; states=ss; transs=ts; _} =
    let report_error all reached =
      let unreached = L.filter (fun state ->
        not (L.mem state reached)
      ) all
      in L.fold_left (fun acc state ->
        error (sprintf
        "State <%s> cannot be reached from initial state" state)
        ; false
      ) false unreached
    in let rec all_reachable all wl transs last_size =
      if last_size = L.length wl
      then report_error all wl
      else if all = wl
      then true
      else let nexts =
        L.map (fun {dst=dst;_} -> dst) (
          L.filter (fun {src=src;_} ->
            L.mem src wl
          ) transs
        )
      in let new_wl = (L.sort_uniq compare (nexts @ wl))
      in all_reachable all new_wl transs (L.length wl)
    in let wl = (L.sort_uniq compare is)
    in all_reachable ss wl ts 0
  in let finals_reachable_from_all {finals=fs; states=ss; transs=ts; _} =
    let report_error all reached =
      let unreached = L.filter (fun state ->
        not (L.mem state reached)
      ) all
      in L.fold_left (fun acc state ->
        error (sprintf
        "State <%s> cannot reach any final state" state)
        ; false
      ) false unreached
    in let rec all_reachable all wl transs last_size =
      if last_size = L.length wl
      then report_error all wl
      else if all = wl
      then true
      else let priors =
        L.map (fun {src=src;_} -> src) (
          L.filter (fun {dst=dst;_} ->
            L.mem dst wl
          ) transs
        )
      in let new_wl = (L.sort_uniq compare (priors @ wl))
      in all_reachable all new_wl transs (L.length wl)
    in let wl = (L.sort_uniq compare fs)
    in all_reachable ss wl ts 0
  in (inits_and_finals fsa)
  && (never_stuck fsa)
  && (no_unreachable fsa)
  && (all_reachable_from_init fsa)
  && (finals_reachable_from_all fsa)
  && (check_hooks fsa)
  && (initials_have_windows fsa)



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
      | None -> (error ("Unknown region '" ^ alias ^ "'"); exit 1)
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
      | FR.Hook (_, states, _) -> states
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

  (* FR.action list -> action list list *)
  in let conv_actions acts =
    let rec conv_actions acts acc =
      match acts with
      | [] -> acc
      | act :: t -> (
        match act with
          | FR.WindowChange win -> let new_acc = L.map (
              fun lst -> WindowChange win :: lst
            ) acc
            in conv_actions t new_acc
          | FR.Probability _ -> conv_actions t acc
          | FR.MoveAction loc ->
              let coords = match loc with
                | FR.Coordinates (sx, sy, ex, ey) ->
                    {region=None; sx; sy; ex; ey}
                | FR.Alias s ->
                    let sx, sy, ex, ey = coords_from_alias s
                    in {region = Some s; sx; sy; ex; ey}
              in let new_acc = L.map (fun l ->
                MoveAction coords :: l) acc
              in conv_actions t new_acc
          | FR.ShellAction str -> let new_acc = L.map (
              fun l -> (ShellAction str) :: l
              ) acc
            in conv_actions t new_acc
          | FR.MoveRelAction loc ->
              let coords = match loc with
                | FR.Coordinates (sx, sy, ex, ey) ->
                    {region=None; sx; sy; ex; ey}
                | FR.Alias s ->
                    let sx, sy, ex, ey = coords_from_alias s
                    in {region = Some s; sx; sy; ex; ey}
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

  in let get_hooks frep fsa =
    let hooks_of_entry = function
      | FR.Hook (pre_post, states, actions) ->
          let lst = L.map (fun state ->
            let conv_acts = conv_actions actions
            in L.map (fun action_list ->
              let pre_post = match pre_post with
                | FR.Pre  -> Pre
                | FR.Post -> Post
              in (pre_post, state, action_list)
            ) conv_acts
          ) states
          in L.flatten lst
      | _ -> []
    in let hooks_from_frep =
      let all_states = L.fold_left (fun acc entry ->
        acc @ (hooks_of_entry entry)
      ) [] frep
      in L.sort_uniq compare all_states
    in {fsa with hooks = hooks_from_frep}

  in let get_transs frep fsa =
    let all_states = fsa.states
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
  |> get_transs frep
  |> get_hooks frep



let stats_of {states; inits; finals; transs; hooks} =
  sprintf "%3d states\n%3d initial\n%3d final\n%3d hooks\n%3d \
     normalised transitions\n"
  (L.length states) (L.length inits) (L.length finals)
  (L.length hooks) (L.length transs)



let real_dot_of fsa from_to =
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
        | WindowChange _ -> ""
        | ShellAction str ->
            ":> " ^ str
        | ScrollAction (d, n) ->
            let dir = match d with
              | Up -> "ScrUp "
              | Down -> "ScrDown "
            in dir ^ "x" ^ (string_of_int n)
        | MoveAction {region; sx; sy; ex; ey} -> (
            match region with
              | None -> "move " ^ string_of_coords sx sy ex ey
              | Some region -> "move to '" ^ region ^ "'"
        )
        | MoveRelAction {sx; sy; ex; ey; _} ->
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
      in let edge_attributes = match from_to with
        | None -> ""
        | Some (from, too) -> (
          (*
          if from = src   &&   too = dst
          then "penwidth=7; color=\"blue\"; fontcolor=\"blue\";"
          else
            *)
            ""
        )
      in src ^ " -> " ^ dst
       ^ " [label=\"" ^ acts ^ "\"; " ^ edge_attributes ^ "];"
    in L.map dot_of_t transs
  in let dot_of_ss states =
    match from_to with
      | None -> []
      | Some (from, too) ->
          let highlight color state =
            state ^ "[style=\"filled\"; color=\"" ^ color ^ "\";]"
          in let states = L.filter
          (fun state -> state = from || state = too) states
          in L.map (fun state ->
            if state = from
            then highlight "purple" state
            else if state = too
            then highlight "blue" state
            else (* impossible, we only selected from and to states *)
              failwith "Bad logic"
          ) states
  in let lines =
    dot_of_is fsa.inits
    @ dot_of_fs fsa.finals
    @ dot_of_ts fsa.transs
    @ dot_of_ss fsa.states
  in let lines = L.sort_uniq compare lines
  in let body = L.fold_left (fun acc line ->
    "  " ^ line ^ "\n" ^ acc
      ) "" lines
  in "digraph G {\n  node [shape=box];\nrankdir=LR;\n  "
    ^ (S.trim body) ^ "\n}\n"



let dot_of fsa =
  real_dot_of fsa None



let transition_graphs fsa cont =
  L.iter (fun from_state ->
    L.iter (fun to_state ->
      let graph = real_dot_of fsa (Some (from_state, to_state))
      in cont graph (from_state, to_state)
    ) fsa.states
  ) fsa.states
