/* smid-format parser
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
 */

%{
  open FileRep
%}

%token <string> IDENT

%token <string> VERBATIM_STRING
%token <string list> KEYPRESSES
%token <string> LINE
%token <string> BLOCK

%token <int * int * int * int> MOVE
%token <int * int * int * int> MOVE_REL
%token <string> MOVE_REGION

%token <FileRep.click_side * int> CLICK
%token <FileRep.scroll_direction * int> SCROLL

%token <string> BASH_SCRIPT

%token PROB
%token HIGH
%token MED
%token LOW

%token REGION
%token <int> INT
%token EQUALS
%token COMMA

%token ARROW_BEGIN
%token ARROW_END

%token ALL
%token STAY
%token PRE
%token POST
%token INITIAL
%token FINAL

%token EOF

%token SEMI
%token ESCAPED_SEMI

%token DQUOTE
%token ESCAPED_DQUOTE

%token L_BRACK
%token R_BRACK
%token L_PAREN
%token R_PAREN

%start input
%type <FileRep.fsa> input

%%

input: lines EOF { $1 }


lines: line                { [$1]     }
     | lines line { $2 :: $1 }


line: initial_states_line   { InitialStates  $1 }
    | final_states_line     { FinalStates    $1 }
    | pre_state_hooks_line  { PreStateHooks  $1 }
    | post_state_hooks_line { PostStateHooks $1 }
    | transition_line       { Transition     $1 }
    | region_def_line       { LocationAlias  $1 }


region_def_line: REGION IDENT EQUALS L_PAREN coords R_PAREN
                 { ($2, ($5)) }

coords: INT maybe_comma INT
        { ($1, $3, $1, $3) }
      | INT maybe_comma INT maybe_comma INT maybe_comma INT
         { ($1, $3, $5, $7) }

maybe_comma:       { }
           | COMMA { }


initial_states_line: INITIAL state_plus { $2 }
final_states_line:   FINAL   state_plus { $2 }

state_plus: state_string                { [$1] }
          | L_BRACK state_list R_BRACK  {  $2  }

state_list: state_string            {   [$1]   }
          | state_list state_string { $2 :: $1 }

maybe_state_list:            { [] }
                | state_list { $1 }

pre_state_hooks_line: PRE state_string BASH_SCRIPT
                      { ($2, $3) }

post_state_hooks_line: POST state_string BASH_SCRIPT
                       { ($2, $3) }

transition_line: additive_transition    { $1 }
               | subtractive_transition { $1 }

additive_transition:
  state_list ARROW_BEGIN action_list ARROW_END dest_state
  { (Additive $1, $3, $5) }

subtractive_transition:
  ALL maybe_state_list ARROW_BEGIN action_list ARROW_END dest_state
  { (Subtractive $2, $4, $6) }

dest_state: IDENT { DestState $1 }
          | STAY  { Stay         }

action_list: action             {   [$1]   }
           | action_list action { $2 :: $1 }

action: key_act       { KeysAction $1     }
      | type_act      { TypeAction $1     }
      | line_act      { LineAction $1     }
      | move_act      { MoveAction $1     }
      | move_coord    { MoveAction $1     }
      | move_rel_act  { MoveRelAction $1  }
      | click_act     { ClickAction $1    }
      | scroll_act    { ScrollAction $1   }
      | probability   { Probability  $1   }


key_act:      KEYPRESSES      { $1 }
type_act:     VERBATIM_STRING { $1 }
line_act:     LINE            { $1 }
click_act:    CLICK           { $1 }
scroll_act:   SCROLL          { $1 }
move_act:     MOVE            { Coordinates $1  }
move_rel_act: MOVE_REL        { Coordinates $1  }
move_coord:   MOVE_REGION     { Alias $1        }

probability:  PROB prob { $2  }
        prob: HIGH      { High}
            | MED       { Med }
            | LOW       { Low }


state_string: IDENT { $1 }
