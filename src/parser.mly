/* FSA file parser
 * Author: Kareem Khazem <karkhaz@karkhaz.com>
 *   Date: 2015
 */

%{
  module L = List
%}

%token <string> IDENT

%token <string> VERBATIM_STRING
%token <string list> KEYPRESSES
%token <string> LINE
%token <string> BLOCK

%token <int * int > MOVE
%token <int * int>  MOVE_REL

%token <FileRep.click_side * int> CLICK
%token <FileRep.scroll_direction * int> SCROLL

%token <string> BASH_SCRIPT

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

%token L_CURLY
%token R_CURLY
%token L_BRACK
%token R_BRACK

%start input

%type <FileRep.fsa> input

%type <FileRep.fsa_entry> line
%type <FileRep.initial_state list> initial_states_line
%type <FileRep.final_state   list> final_states_line

%%

input: lines EOF { $1 }


lines: line                { [$1]     }
     | lines line { $2 :: $1 }


line: initial_states_line   { FileRep.InitialStates  $1 }
    | final_states_line     { FileRep.FinalStates    $1 }
    | pre_state_hooks_line  { FileRep.PreStateHooks  $1 }
    | post_state_hooks_line { FileRep.PostStateHooks $1 }
    | transition_line       { FileRep.Transition     $1 }


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
  { (FileRep.Additive $1, $3, $5) }

subtractive_transition:
  ALL maybe_state_list ARROW_BEGIN action_list ARROW_END dest_state
  { (FileRep.Subtractive $2, $4, $6) }

dest_state: IDENT { FileRep.DestState $1 }
          | STAY  { FileRep.Stay         }

action_list: action             {   [$1]   }
           | action_list action { $2 :: $1 }

action: key_act       { FileRep.KeysAction $1     }
      | type_act      { FileRep.TypeAction $1     }
      | line_act      { FileRep.LineAction $1     }
      | move_act      { FileRep.MoveAction $1     }
      | move_rel_act  { FileRep.MoveRelAction $1  }
      | click_act     { FileRep.ClickAction $1    }
      | scroll_act    { FileRep.ScrollAction $1   }


key_act:      KEYPRESSES      { $1 }
type_act:     VERBATIM_STRING { $1 }
line_act:     LINE            { $1 }
move_act:     MOVE            { $1 }
move_rel_act: MOVE_REL        { $1 }
click_act:    CLICK           { $1 }
scroll_act:   SCROLL          { $1 }


state_string: IDENT { $1 }
