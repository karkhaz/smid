(* FSA representation as parsed from file
 * Author: Kareem Khazem <karkhaz@karkhaz.com>
 *   Date: 2015
 *)

module L = List

type initial_state = string
type final_state = string


type hook = string

type state_hooks = (final_state * hook)


type action = KeysAction of string list
            | TypeAction of string
            | LineAction of string

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
  in L.fold_left (fun acc line ->
    let str = match line with
      | InitialStates l    -> (pp_is l) ^ "\n"
      | FinalStates l      -> (pp_fs l) ^ "\n"
      | PreStateHooks l    -> (pp_sh l) ^ "\n"
      | PostStateHooks l   -> (pp_sh l) ^ "\n"
      | Transition l       -> (pp_tr l) ^ "\n"
    in str ^ acc
    ) "" fsa


