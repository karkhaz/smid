(* Misc utilities
 * Author: Kareem Khazem <karkhaz@karkhaz.com>
 *   Date: 2015
 *)

open Printf
module L = List

let lines_of_file fname =
  try
    let in_chan = open_in fname
    in let rec lines_of_file fname acc =
      try
        lines_of_file fname (input_line in_chan :: acc)
      with End_of_file -> acc
    in L.rev (lines_of_file fname [])
  with
    | Sys_error e ->
        eprintf "Error: could not read lines from %s:\n  %s\n"
          fname e
        ; exit 1

let random_from_list lst =
  let rec get_element lst idx =
    match lst with
      | h :: t -> (
        match idx with
          | 0 -> h
          | n -> get_element t (n - 1)
      )
      | [] -> assert false
  in let length = L.length lst
  in let index = Random.self_init (); Random.int length
  in get_element lst index
