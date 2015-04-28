(* FSA data structure, normalised from file representation
 * Author: Kareem Khazem <karkhaz@karkhaz.com>
 *   Date: 2015
 *)

module FR = FileRep
module S = String
module L = List
module C = Config
module U = Util
module TR = TRList
open Printf
open Std

type state = string
type hook = string
type _state_hook = (state * hook)
type state_hook = Pre  of _state_hook
                | Post of _state_hook

type type_action = {
  fname: string option;
  text:  string;
}

type action = KeysAction of string list
            | TypeAction of type_action

type trans = (state * action list * state)

type fsa = {
  states: state list;
  inits:  state list;
  finals: state list;
  transs: trans list;
  hooks:  state_hook list;
}


(* Turn a FileRep.fsa into an fsa *)
let normalise frep =
  let states_from_frep get_states_fun =
    let all_states = L.fold_left (fun acc entry ->
      acc @ (get_states_fun entry)
    ) [] frep
    in TR.sort_uniq compare all_states
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
      in TR.sort_uniq compare all_states
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
            in L.map (fun acts ->
              let dst = match dst with
                | FR.DestState s -> s
                | FR.Stay -> state
              in (state, acts, dst)
            ) conv_acts
          ) states
          in L.flatten lst
      | _ -> []
    in let transs_from_frep =
      let all_transs = L.fold_left (fun acc entry ->
        acc @ (transs_of_entry entry)
      ) [] frep
      in TR.sort_uniq compare all_transs
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
  in let dot_of_is inits =
    let dot_of_i init =
      init ^ " [style=filled, color=green];"
    in L.map dot_of_i inits
  in let dot_of_fs finals =
    let dot_of_f final =
      final ^ " [style=filled, color=red];"
    in L.map dot_of_f finals
  in let dot_of_ts transs =
    let dot_of_t (src, acts, dst) =
      let dot_of_act = function
        | KeysAction a ->
          let keys = L.fold_left (fun acc key ->
              (dot_escape key) ^ " " ^ acc
            ) "" a
          in "[" ^ (trim keys) ^ "]"
        | TypeAction {fname; text} ->
            let str = match fname with
              | Some fname -> ">" ^ fname
              | None -> dot_escape text
            in "\\\"" ^ str ^ "\\\""
      in let dot_of_acts acts =
        let str = L.fold_left (fun acc act ->
          (dot_of_act act) ^ "; " ^ acc
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
  in let lines = TR.sort_uniq compare lines
  in let body = L.fold_left (fun acc line ->
    "  " ^ line ^ "\n" ^ acc
      ) "" lines
  in "digraph G {\n  node [shape=box];\n  " ^ (trim body) ^ "\n}\n"



let script_of fsa run_length =
  let get_nexts source =
    L.filter (fun (src, _, _) -> src = source) fsa.transs
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
           (trim hook) ^ "\n" ^ acc
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
           (trim hook) ^ "\n" ^ acc
         ) "" hooks
         in b ^ hooks ^ e
    else ""
  in let acts_to_s acts =
    let script_of_keys keys =
      let script = L.map (fun key ->
        let key = S.escaped key
        in let cmd = "xdotool search --name $WINDOW_NAME key " ^ key
        in cmd ^ "\necho " ^ cmd ^ "\n" ^ random_delay ^ "\n"
      ) keys
      in L.fold_left (fun acc line ->
        line ^ "\n" ^ acc
      ) "" script
    in let script_of_type {fname; text} =
      let comment = match fname with
        | None -> ""
        | Some f-> "# Typing string from file <" ^ f ^ ">:\n"
      in let cmd = "xdotool search --name $WINDOW_NAME type --window \
                    %1 \"" ^ text ^ "\""
      in comment ^ cmd ^ "\necho " ^ cmd ^ "\n" ^ random_delay ^ "\n"
    in let act_to_s  = function
      | KeysAction keys -> script_of_keys keys
      | TypeAction str  -> script_of_type str
    in L.fold_left (fun acc act ->
      (act_to_s act) ^ "\n" ^ acc
    ) "" acts
  in let add_trans trans acc =
    let trans_to_s (src, acts, dst) =
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
  in let is_final (_, _, dest) = L.mem dest fsa.finals
  in let rec script_of fsa run_length curr acc =
    match run_length with
      | 0 ->
          let nexts = get_nexts curr
          in if  L.exists is_final nexts
             then let (_, _, final) = L.find is_final nexts
                   in (final, (add_trans (L.find is_final nexts) acc))
             else let (s, _, _) as next = U.random_from_list nexts
                  in script_of fsa 0 s (add_trans next acc)
      | n ->
          let nexts = get_nexts curr
          in let nexts = L.filter (fun s -> not (is_final s)) nexts
          in let (_, _, d) as next = U.random_from_list nexts
          in script_of fsa (n - 1) d (add_trans next acc)
  in let start_state = U.random_from_list fsa.inits
  in let final_state, script = script_of fsa run_length start_state []
  in let script = L.fold_left (fun acc line ->
    line ^ acc
  ) "" script
  in "#!/bin/bash\n" ^
     (pre_hooks_of start_state) ^ script ^ (post_hooks_of final_state)
