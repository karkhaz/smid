/* FSA file parser
 * Author: Kareem Khazem <karkhaz@karkhaz.com>
 *   Date: 2015
 */

%{
  open FileRep
  module L = List
%}

%token <string> IDENT

%token <string> VERBATIM_STRING
%token <string list> KEYPRESSES
%token <string> LINE
%token <string> BLOCK
%token <string> BASH_SCRIPT

%token ARROW_BEGIN
%token ARROW_END

%token ALL
%token STAY
%token PRE
%token POST
%token GETS

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


line: initial_states_line   { InitialStates  $1 }
    | final_states_line     { FinalStates    $1 }
    | pre_state_hooks_line  { PreStateHooks  $1 }
    | post_state_hooks_line { PostStateHooks $1 }
    | transition_line       { Transition     $1 }


initial_states_line: state_plus ARROW_END  { $1 }
final_states_line:   ARROW_END  state_plus { $2 }

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
action: key_act  { KeysAction $1 }
      | type_act { TypeAction $1 }
      | line_act { LineAction $1 }


key_act:  KEYPRESSES      { $1 }
type_act: VERBATIM_STRING { $1 }
line_act: LINE            { $1 }

state_string: IDENT { $1 }
