(* FSA file lexer
 *
 * Author: Kareem Khazem <karkhaz@karkhaz.com>
 *   Date: 2015
 *)

{
  module L = Lexing
  module C = Config
  open Parser
  open Printf

  let incr_ln lexbuf =
    let pos = lexbuf.L.lex_curr_p
    in lexbuf.L.lex_curr_p <- {pos with
      L.pos_lnum = pos.L.pos_lnum + 1;
      L.pos_bol  = pos.L.pos_cnum;
    }

  let last_mode = ref "top"

  let dbs mode lexeme lexbuf =
    let sep =
      if   !last_mode = mode
      then ""
      else "     ----\nlex: "
    in last_mode := mode;
    let str = String.trim lexeme
    in if !C.debug
    then  eprintf "lex: %s%3d [%4s] %s\n%!"
            sep lexbuf.L.lex_curr_p.L.pos_lnum mode str
    else  ()

  let dbc mode lexeme lexbuf =
    let str = match lexeme with
      | '\n' -> "newline"
      | c -> String.make 1 c
    in dbs mode str lexbuf

  exception SyntaxError
}

let ws       = [  ' '  '\t' ]*
let nonblank = [^ ' '  '\t' ]+
let keypress = ([^ ' '  '\t' ']'] | '\\' ']')+
let line = [^ '\n']*
let nl = '\n'
let id = ['a'-'z' '_' 'A'-'Z'] ['a'-'z' '_' 'A'-'Z' '0'-'9']+

(* Top-level lexing rules *)
rule lex = parse
  | nl            as l { dbc "top" l lexbuf; incr_ln lexbuf; lex lexbuf }
  | '#' line nl   as l { dbs "top" l lexbuf; incr_ln lexbuf; lex lexbuf }
  | ws                 {                                     lex lexbuf }
  | ','           as l { dbc "top" l lexbuf;                 lex lexbuf }

  | "keys"        as l { dbs "top" l lexbuf; read_keys     () lexbuf }
  | "text"        as l { dbs "top" l lexbuf; read_verbatim () lexbuf }
  | "line"        as l { dbs "top" l lexbuf; read_line () lexbuf }
  | "{"           as l { dbc "top" l lexbuf; read_bash "" lexbuf }

  | "stay"        as l { dbs "top" l lexbuf; STAY }
  | "pre"         as l { dbs "top" l lexbuf; PRE  }
  | "post"        as l { dbs "top" l lexbuf; POST }
  | ":="          as l { dbs "top" l lexbuf; GETS }
  | "all"         as l { dbs "top" l lexbuf; ALL  }
  | "all-except"  as l { dbs "top" l lexbuf; ALL  }
  | "initial"     as l { dbs "top" l lexbuf; INITIAL     }
  | "final"       as l { dbs "top" l lexbuf; FINAL       }
  | "-->"         as l { dbs "top" l lexbuf; ARROW_END   }
  | "->"          as l { dbs "top" l lexbuf; ARROW_END   }
  | "--"          as l { dbs "top" l lexbuf; ARROW_BEGIN }
  | "["           as l { dbc "top" l lexbuf; L_BRACK }
  | "]"           as l { dbc "top" l lexbuf; R_BRACK }
  | eof           as l { dbs "top" l lexbuf; EOF  }

  | id            as l { dbs "top" l lexbuf; IDENT l }
  | _                { raise SyntaxError }


(* Rules for lexing keypresses, invoked when we see the keys keyword
 * at the top-level
 *)
and read_keys u = parse
  | ws       {                      read_keys () lexbuf }
  | '[' as l { dbc "pkey" l lexbuf; read_keys' [] lexbuf }
  | nl  as l { dbc "pkey" l lexbuf; incr_ln lexbuf; read_keys () lexbuf }
  | _        { raise SyntaxError }
and read_keys' acc = parse
  | ws               {                      read_keys' acc lexbuf          }
  | "\\]"       as l { dbs "keyp" l lexbuf; read_keys' ("]" :: acc) lexbuf }
  | nl          as l { dbc "keyp" l lexbuf; incr_ln lexbuf; read_keys' acc lexbuf }
  | '#' line nl as l { dbs "keyp" l lexbuf; incr_ln lexbuf; read_keys' acc lexbuf }
  | "]"         as l { dbc "keyp" l lexbuf; KEYPRESSES (acc)           }
  | keypress    as l { dbs "keyp" l lexbuf; read_keys' (l :: acc) lexbuf   }


(* Rules for lexing verbatin text, invoked when we see the text keyword
 * at the top-level
 *)
and read_verbatim u = parse
  | ws       {                         read_verbatim () lexbuf }
  | '"' as l { dbc "pvrb" l lexbuf; read_verbatim' "" lexbuf }
  | nl  as l { dbc "pvrb" l lexbuf; incr_ln lexbuf; read_verbatim () lexbuf }
  | _        { raise SyntaxError }
and read_verbatim' acc = parse
  | '"'    as l { dbc "verb" l lexbuf; VERBATIM_STRING acc }
  | "\\\"" as l { dbs "verb" l lexbuf; read_verbatim' (acc ^ "\"") lexbuf }
  | "\\n"  as l { dbs "verb" l lexbuf; read_verbatim' (acc ^ "\n") lexbuf }
  | "\\t"  as l { dbs "verb" l lexbuf; read_verbatim' (acc ^ "\t") lexbuf }
  | "\\\\" as l { dbs "verb" l lexbuf; read_verbatim' (acc ^ "\\") lexbuf }
  | _ as c as l { dbc "verb" l lexbuf;
                  read_verbatim' (acc ^ (String.make 1 c)) lexbuf
                }

(* Rules for lexing bash, invoked when we see a } at toplevel *)
and read_bash acc = parse
  | '}'    as l { dbc "bash" l lexbuf; BASH_SCRIPT acc }
  | "\\\"" as l { dbs "bash" l lexbuf; read_bash (acc ^ "\"") lexbuf }
  | "\\n"  as l { dbs "bash" l lexbuf; read_bash (acc ^ "\n") lexbuf }
  | "\\t"  as l { dbs "bash" l lexbuf; read_bash (acc ^ "\t") lexbuf }
  | "\\\\" as l { dbs "bash" l lexbuf; read_bash (acc ^ "\\") lexbuf }
  | _ as c as l { dbc "bash" l lexbuf;
                  read_bash (acc ^ (String.make 1 c)) lexbuf
                }

(* Rules for lexing file paths, invoked when we see the line keyword
 * at the toplevel
 *)
and read_line u = parse
  | ws       {                         read_line () lexbuf }
  | '"' as l { dbc "plin" l lexbuf; read_line' "" lexbuf }
  | _        { raise SyntaxError }
and read_line' acc = parse
  | '"'    as l { dbc "line" l lexbuf; LINE acc }
  | "\\\"" as l { dbs "line" l lexbuf; read_line' (acc ^ "\"") lexbuf }
  | "\\n"  as l { dbs "line" l lexbuf; read_line' (acc ^ "\n") lexbuf }
  | "\\t"  as l { dbs "line" l lexbuf; read_line' (acc ^ "\t") lexbuf }
  | "\\\\" as l { dbs "line" l lexbuf; read_line' (acc ^ "\\") lexbuf }
  | _ as c as l { dbc "line" l lexbuf;
                  read_line' (acc ^ (String.make 1 c)) lexbuf
                }
