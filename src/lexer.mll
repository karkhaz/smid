(* smid-format lexer
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
let integer = ['0'-'9']+

(* Top-level lexing rules *)
rule lex = parse
  | nl            as l { dbc "top" l lexbuf; incr_ln lexbuf; lex lexbuf }
  | '#' line nl   as l { dbs "top" l lexbuf; incr_ln lexbuf; lex lexbuf }
  | ','           as l { dbc "top" l lexbuf;                 lex lexbuf }
  | ws                 {                                     lex lexbuf }

(* The lexemes for actions are different than the lexemes for the top
 * level of an FSA file. Therefore we call into some different lexer
 * functions to return the lexemes associated with each action.*)
  | "keys"        as l { dbs "top" l lexbuf; read_keys     () lexbuf  }
  | "text"        as l { dbs "top" l lexbuf; read_verbatim () lexbuf  }
  | "line"        as l { dbs "top" l lexbuf; read_line () lexbuf      }
  | "move"        as l { dbs "top" l lexbuf; read_move () lexbuf      }
  | "movr"        as l { dbs "top" l lexbuf; read_move_rel () lexbuf  }
  | "move-rel"    as l { dbs "top" l lexbuf; read_move_rel () lexbuf  }
  | "click"       as l { dbs "top" l lexbuf; read_click () lexbuf     }
  | "clik"        as l { dbs "top" l lexbuf; read_click () lexbuf     }
  | "scroll"      as l { dbs "top" l lexbuf; read_scroll () lexbuf    }
  | "scrl"        as l { dbs "top" l lexbuf; read_scroll () lexbuf    }
  | "{"           as l { dbc "top" l lexbuf; read_bash "" lexbuf      }

  | "prob"        as l { dbs "top" l lexbuf; PROB }
  | "high"        as l { dbs "top" l lexbuf; HIGH }
  | "med"         as l { dbs "top" l lexbuf; MED  }
  | "low"         as l { dbs "top" l lexbuf; LOW  }

  | "stay"        as l { dbs "top" l lexbuf; STAY         }
  | "pre"         as l { dbs "top" l lexbuf; PRE          }
  | "post"        as l { dbs "top" l lexbuf; POST         }
  | "all"         as l { dbs "top" l lexbuf; ALL          }
  | "all-except"  as l { dbs "top" l lexbuf; ALL          }
  | "initial"     as l { dbs "top" l lexbuf; INITIAL      }
  | "final"       as l { dbs "top" l lexbuf; FINAL        }
  | "-->"         as l { dbs "top" l lexbuf; ARROW_END    }
  | "->"          as l { dbs "top" l lexbuf; ARROW_END    }
  | "--"          as l { dbs "top" l lexbuf; ARROW_BEGIN  }
  | "["           as l { dbc "top" l lexbuf; L_BRACK      }
  | "]"           as l { dbc "top" l lexbuf; R_BRACK      }

  | "region"      as l { dbs "top" l lexbuf; REGION       }
  | "="           as l { dbc "top" l lexbuf; EQUALS       }
  | ","           as l { dbc "top" l lexbuf; COMMA        }
  | "("           as l { dbc "top" l lexbuf; L_PAREN      }
  | ")"           as l { dbc "top" l lexbuf; R_PAREN      }
  | integer       as l { dbs "top" l lexbuf; INT (int_of_string l) }

  | eof           as l { dbs "top" l lexbuf; EOF          }

  | id            as l { dbs "top" l lexbuf; IDENT l }
  | _                { raise SyntaxError }


(* Rules for lexing keypresses, invoked when we see the keys keyword
 * at the top-level *)
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
 * at the top-level *)
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
 * at the toplevel *)
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

(* Rules for lexing movement coordinates, invoked when we see the move
 * keyword at the top-level. *)
and read_move u = parse
  | ws       {                      read_move ()  lexbuf }
  | '(' as l { dbc "pmov" l lexbuf; read_move' [] lexbuf }
  | nl  as l { dbc "pmov" l lexbuf; incr_ln lexbuf; read_move () lexbuf }
  | id  as l { dbs "pmov" l lexbuf; MOVE_REGION l        }
and read_move' acc = parse
  | ws               {                      read_move' acc lexbuf          }
  | ','              {                      read_move' acc lexbuf          }
  | nl          as l { dbc "move" l lexbuf; incr_ln lexbuf; read_move' acc lexbuf }
  | '#' line nl as l { dbs "move" l lexbuf; incr_ln lexbuf; read_move' acc lexbuf }
  | integer     as l { dbs "move" l lexbuf; read_move' (l :: acc) lexbuf   }
  | '-' integer as l { dbs "movr" l lexbuf; read_move' (l :: acc) lexbuf   }
  | ")"         as l { dbc "move" l lexbuf;
                       match acc with
                        (* Note---these lists will be backwards *)
                         | [ey;ex;sy;sx] ->
                             MOVE ( int_of_string sx,
                                    int_of_string sy,
                                    int_of_string ex,
                                    int_of_string ey
                                  )
                         | [y;x] ->
                             MOVE ( int_of_string x,
                                    int_of_string y,
                                    int_of_string x,
                                    int_of_string y
                                  )
                         | _ -> raise SyntaxError
                     }
  | _        { raise SyntaxError }



(* Rules for lexing relative movement coordinates, invoked when we see
 * the movr keyword at the top-level.  *)
and read_move_rel u = parse
  | ws       {                      read_move_rel ()  lexbuf }
  | '(' as l { dbc "pmvr" l lexbuf; read_move_rel' [] lexbuf }
  | nl  as l { dbc "pmvr" l lexbuf; incr_ln lexbuf; read_move_rel () lexbuf }
  | _        { raise SyntaxError }
and read_move_rel' acc = parse
  | ws                { read_move_rel' acc lexbuf }
  | ','               { read_move_rel' acc lexbuf }
  | nl          as l  { dbc "movr" l lexbuf;
                        incr_ln lexbuf;
                        read_move_rel' acc lexbuf
                      }
  | '#' line nl as l  { dbs "movr" l lexbuf;
                        incr_ln lexbuf;
                        read_move_rel' acc lexbuf
                      }
  | integer     as l  { dbs "movr" l lexbuf;
                        read_keys' (l :: acc) lexbuf
                      }
  | '-' integer as l  { dbs "movr" l lexbuf;
                        read_keys' (l :: acc) lexbuf
                      }
  | ")"         as l  { dbc "movr" l lexbuf;
                        match acc with
                        (* Note---these lists will be backwards *)
                         | [ey;ex;sy;sx] ->
                             MOVE_REL ( int_of_string sx,
                                        int_of_string sy,
                                        int_of_string ex,
                                        int_of_string ey
                                      )
                         | [y;x] ->
                             MOVE_REL ( int_of_string x,
                                        int_of_string y,
                                        int_of_string x,
                                        int_of_string y
                                      )
                         | _ -> raise SyntaxError
                      }
  | _        { raise SyntaxError }


(* Rules for lexing click instructions, invoked when we see the click
 * keyword at the top-level *)
and read_click u = parse
  | ws       {                      read_click ()  lexbuf }
  | '(' as l { dbc "pclk" l lexbuf; read_click' None None lexbuf }
  | nl  as l { dbc "pclk" l lexbuf; incr_ln lexbuf; read_click () lexbuf }
  | _        { raise SyntaxError }
and read_click' side freq = parse
  | ws                { read_click' side freq lexbuf }
  | ','               { read_click' side freq lexbuf }
  | nl          as l  { dbc "clik" l lexbuf;
                        incr_ln lexbuf;
                        read_click' side freq lexbuf
                      }
  | '#' line nl as l  { dbs "clik" l lexbuf;
                        incr_ln lexbuf;
                        read_click' side freq lexbuf
                      }
  | integer     as l  { dbs "clik" l lexbuf;
                        match freq with
                          | None ->
                              read_click' side (Some l) lexbuf
                          | Some _ ->
                              raise SyntaxError
                      }
  | "left"      as l  { dbs "clik" l lexbuf;
                        match side with
                          | None ->
                              read_click' (Some FileRep.Left) freq lexbuf
                          | Some _ ->
                              raise SyntaxError
                      }
  | "L"         as l  { dbc "clik" l lexbuf;
                        match side with
                          | None ->
                              read_click' (Some FileRep.Left) freq lexbuf
                          | Some _ ->
                              raise SyntaxError
                      }
  | "right"     as l  { dbs "clik" l lexbuf;
                        match side with
                          | None ->
                              read_click' (Some FileRep.Right) freq lexbuf
                          | Some _ ->
                              raise SyntaxError
                      }
  | "R"         as l  { dbc "clik" l lexbuf;
                        match side with
                          | None ->
                              read_click' (Some FileRep.Right) freq lexbuf
                          | Some _ ->
                              raise SyntaxError
                      }
  | ")"         as l  { dbc "clik" l lexbuf;
                        match side, freq with
                          | None, _   | _, None ->
                              raise SyntaxError
                          | Some side, Some freq ->
                              CLICK (side, int_of_string freq)
                      }
  | _        { raise SyntaxError }


(* Rules for lexing scroll instructions, invoked when we see the
 * scroll keyword at the top-level *)
and read_scroll u = parse
  | ws       {                      read_scroll ()  lexbuf }
  | '(' as l { dbc "pclk" l lexbuf; read_scroll' None None lexbuf }
  | nl  as l { dbc "pclk" l lexbuf; incr_ln lexbuf; read_scroll () lexbuf }
  | _        { raise SyntaxError }
and read_scroll' dir freq = parse
  | ws                { read_scroll' dir freq lexbuf }
  | ','               { read_scroll' dir freq lexbuf }
  | nl          as l  { dbc "clik" l lexbuf;
                        incr_ln lexbuf;
                        read_scroll' dir freq lexbuf
                      }
  | '#' line nl as l  { dbs "clik" l lexbuf;
                        incr_ln lexbuf;
                        read_scroll' dir freq lexbuf
                      }
  | integer     as l  { dbs "clik" l lexbuf;
                        match freq with
                          | None ->
                              read_scroll' dir (Some l) lexbuf
                          | Some _ ->
                              raise SyntaxError
                      }
  | "up"        as l  { dbs "clik" l lexbuf;
                        match dir with
                          | None ->
                              read_scroll' (Some FileRep.Up) freq lexbuf
                          | Some _ ->
                              raise SyntaxError
                      }
  | "U"         as l  { dbc "clik" l lexbuf;
                        match dir with
                          | None ->
                              read_scroll' (Some FileRep.Up) freq lexbuf
                          | Some _ ->
                              raise SyntaxError
                      }
  | "down"      as l  { dbs "clik" l lexbuf;
                        match dir with
                          | None ->
                              read_scroll' (Some FileRep.Down) freq lexbuf
                          | Some _ ->
                              raise SyntaxError
                      }
  | "D"         as l  { dbc "clik" l lexbuf;
                        match dir with
                          | None ->
                              read_scroll' (Some FileRep.Down) freq lexbuf
                          | Some _ ->
                              raise SyntaxError
                      }
  | ")"         as l  { dbc "clik" l lexbuf;
                        match dir, freq with
                          | None, _   | _, None ->
                              raise SyntaxError
                          | Some dir, Some freq ->
                              SCROLL (dir, int_of_string freq)
                      }
  | _        { raise SyntaxError }

