(* UIDrive front-end
 *
 * Author: Kareem Khazem <karkhaz@karkhaz.com>
 * Date:   2015
 *)

open Arg
open Lexing
open Printf
module C = Config
module FR = FileRep
open FSA

type mode = CompileOnly
          | DOT
          | Stats
          | Script

let fsa_file = ref None
let mode = ref None

let max_depth = ref 5

let usage_msg =
"Usage: uidrive -c [OPTION...] FSA_FILE
       uidrive -d [OPTION...] FSA_FILE
       uidrive -r [OPTION...] FSA_FILE
       uidrive -s [OPTION...] FSA_FILE
"

let rec _speclist = [
  ("-c", Unit (function () -> set_mode CompileOnly),
   " Check syntax of FSA file only")
  ;
  ("-d", Unit (function () -> set_mode DOT),
   " Print out a DOT representation of FSA file")
  ;
  ("-r", Unit (function () -> set_mode Script),
   " Generate run script")
  ;
  ("-s", Unit (function () -> set_mode Stats),
   " Print out FSA statistics")
  ;
  ("--loops", Unit (function () -> C.loops := false),
   " With -d, make transitions to the same state loop back on themselves")
  ;
  ("--include-dir", Set_string C.include_dir,
   " Specify where additional data files are located")
  ;
  ("--run-length", Set_int C.run_length,
   (sprintf " With -r, generate runs of at least length <n>. \
   Default: %d" !C.run_length))
  ;
  ("--debug", Unit (function () -> C.debug := true),
   " Switch on debug output")
  ;
]
and speclist () = align _speclist
and set_mode new_mode = match !mode with
  | None -> mode := Some new_mode
  | _    -> usage (speclist ()) usage_msg; exit 1

let anon_fun str = match !fsa_file with
  | None -> fsa_file := Some str; ()
  | _    -> usage (speclist ()) usage_msg; exit 1

let check_args () = match !fsa_file, !mode with
  | None, _
  | _, None -> usage (speclist ()) usage_msg; exit 1
  | _, _    -> ()

let get_fsa fsa_file =
  try
    let in_chan = open_in fsa_file
    in let lexbuf = Lexing.from_channel in_chan
    in try
      Parser.input Lexer.lex lexbuf
    with
      | Parsing.Parse_error
      | Lexer.SyntaxError ->
          let lexeme = Lexing.lexeme lexbuf
          in let msg =
            format_of_string "Error at %s:%d:%d: Unexpected token <%s>"
          in let line = lexbuf.Lexing.lex_curr_p.pos_lnum
          in let c2bol = lexbuf.Lexing.lex_curr_p.pos_bol
          in let c2cur = lexbuf.Lexing.lex_curr_p.pos_cnum
          in let chr = c2cur - c2bol
          in let msg = sprintf msg fsa_file line chr lexeme
          in eprintf "%s\n" msg
           ; exit 1
      | Failure fail ->
          let msg =
            format_of_string "Error at %s:%d:0: <%s>"
          in let line = lexbuf.Lexing.lex_curr_p.pos_lnum
          in let msg = sprintf msg fsa_file line fail
          in eprintf "%s\n" msg
           ; exit 1
  with
  | Sys_error e ->
      eprintf "Error: %s\n" e;
      exit 1

let () =
  parse (speclist ()) anon_fun usage_msg;
  Random.self_init ();
  match !fsa_file, !mode with
    | None, _
    | _, None -> usage (speclist ()) usage_msg; exit 1
    | Some file, Some mode    ->
        let fsa_file = file
        in let mode = mode
        in let fsa = get_fsa fsa_file
                  |> normalise
        in match mode with
          | CompileOnly ->
              exit 0
          | DOT ->
              printf "%s" (dot_of fsa)
            ; exit 0
          | Stats ->
              printf "%s" (stats_of fsa)
            ; exit 0
          | Script ->
              printf "%s" (script_of fsa !C.run_length)
            ; exit 0
