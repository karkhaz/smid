# Reference

This manual describes the syntax of `.sm` files. Having a little
experience with using the `smid` tool before reading this manual is
probably helpful, so follow the [tutorial](/smid/tutorial.html) first!

## Overview

There are 6 kinds of statement in `smid`:

<div id="contents">
<p>
<a href="#comments">Comments</a>
<br />
<br />
<a href="#initial-declarations">Initial declarations</a>
<br />
<a href="#final-declarations">Final declarations</a>
<br />
<br />
<a href="#transitions">Transitions</a>
<br />
<br />
(transitions contain <a href="#actions">Actions</a>)
<br />
<br />
<br />
<br />
<a href="#state-hook-declarations">State hook declarations</a>
</p>
</div>
<div class="block" id="top-demo"><code>
@import examples/top-demo.sm
</code></div>

<p style="clear: both; margin-bottom: 20px;"></p>

Identifiers (names that you create) are composed of alphanumerics and
underscores, and must start with a letter [a-z]. Identifiers are used
to name states. In the example code of this manual, any word that
is not brightly coloured is an identifier.

Whitespace is never significant, and you can break the line wherever
whitespace is allowed. There are no statement terminators (like the
semicolons `;` used in C).

States don't need to be 'declared' before using them.  This means that
if you misspell the name of a state, `smid` will interpret that as two
different states. This error is easy to check for by looking at the
picture of the state machine, generated with `smid -d`.



<h2 id="transitions">Transitions</h2>

**Syntax:** Transitions generally have the following shape:

    start state(s) -- list of actions --> end-state

* The `start-state(s)` is a space-delimited list of states. The list
  of states may be preceeded with the keyword [`all`](#all) or
  [`all-except`](#all-except).
* The `end-state` is the name of a state, or the keyword
  [`stay`](#stay).
* A space-delimited list of at least one [`action`](#actions) goes in
  between the `--` and `-->`.

**Meaning:** At each step of a program run, `smid` finds all
transitions whose list of `start-states` includes the current state.
It then picks one of those transitions at random.  It then performs
all the actions specified in the [`action`](#actions) list of that
transition, and finally changes the current state to the `end-state`
of that transition.

**Example:** consider this `smid` file:

<p class="block"><code>
@import examples/3-trans.sm
</code></p>
![3-trans](examples/3-trans.png)

If the current state is `bar`, then `smid` can either:

* Send the key-press `Ctrl+M` to the application and set the current
  state to `foo`;
* Send the key-press `Ctrl+U` to the application and set the current
  state to `baz`.


<h3 id="multiple">Multiple start states</h3>

If we can do the same action from several states in the state machine,
you can specify all the states on the same line. The first line in the
following example is equivalent to the next three lines:

<p class="block"><code>
@import examples/same-line.sm
</code></p>
![same-line](examples/same-line.png)


<h3 id="all">all</h3>

If we can do the same action from *all* states in the state machine,
 the `all` keyword can be used to specify this more concisely. If
 `foo`, `bar`, `baz` and `quit` are the only states in the state
 machine, then the last two lines are equivalent:

<p class="block"><code>
@import examples/all.sm
</code></p>
![all](examples/all.png)

Note that there is no action from the `quit` state to itself, since
`quit` was declared as a [final state](#final-declarations) and final
states do not have outgoing edges.

<h3 id="all-except">all-except</h3>

If we can do the same action from all states *except for a few*, the
`all-except` keyword can be used to specify this more concisely.

<p class="block"><code>
@import examples/all-except.sm
</code></p>
![all-except](examples/all-except.png)


<h3 id="stay">stay</h3>

If we have several states where the same action causes a transition
*back to the same state,* the `stay` keyword can be used to specify
this more concisely. In the following example, the first line is
equivalent to the next three:

<p class="block"><code>
@import examples/stay.sm
</code></p>
![stay](examples/stay.png)

In that previous example, if `foo`, `bar` and `baz` were the only
states on the state machine, we could also have written

<p class="block"><code>
@import examples/all-stay.sm
</code></p>


<h3 id="actions">Actions</h3>

Actions describe the ways in which `smid` can interact with your
application. If `smid` walks over a transition, it will perform all of
the actions specified in the transition. In the following example,
there are two actions in the transition:

<p class="block"><code>
@import examples/multi-action.sm
</code></p>

Actions consist of a keyword (like `keys`) and a body (like
`[Escape`]).  Multiple actions are separated by whitespace. When
writing a transition with multiple actions, it is recommended to
format it as above: each action on its own indented line. To help with
alignment, all actions have a four-character alias; we could have
written `scrl` above instead of `scroll`, to keep the bodies of the
actions lined up.


<h4 id="keys">keys</h4>

**Syntax:** The keyword `keys`, followed by a space-delimited list of
keysyms. The list is surrounded with square braces `[ ]`. 'Keysyms'
are names for keys; a list of valid keysyms can be found
[here](http://wiki.linuxquestions.org/wiki/List_of_KeySyms), along
with [additional
keysyms](http://wiki.linuxquestions.org/wiki/XF86_keyboard_symbols)
sometimes found on laptops. Key combinations are separated using the
plus sign `+`.

**Meaning:** The `keys` action causes `smid` to send keypresses to your
application, as if the user had made those entered keypresses on the
keyboard.

**Example:**

    keys [ Ctrl+M  5  space  Return ]




<h4 id="text">text</h4>

    text "quoted text"



<h4 id="line">line</h4>

    line "filename"


<h4 id="move">move</h4>

    move [ x y ]
    move [ start_x start_y end_x end_y ]
    move region_name



<h4 id="move-rel">move_rel / movr</h4>

    move_rel [ x y ]
    movr     [ x y ]




<h4 id="click">click / clik</h4>

    click ( frequency left  )
    click ( frequency right )
    clik  ( frequency left  )
    clik  ( frequency right )





<h4 id="scroll">scroll / scrl</h4>

    scroll ( distance up   )
    scroll ( distance down )
    scrl   ( distance up   )
    scrl   ( distance down )




<h4 id="shell">shell / shel</h4>

    shell { arbitrary shell commands}
    shel  { arbitrary shell commands}




<h2 id="initial-declarations">Initial states</h2>

**Syntax:** The state machine's *initial state* is declared with the
keyword `initial`, followed by the name of the state.

**Meaning:** `smid` 'starts' on the initial state. It then begins to
interact with your application by taking one of the
[transitions](#transitions) that start on the initial state.



<h2 id="final-declarations">Final states</h2>



<h2 id="state-hook-declarations">State hooks</h2>



<h2 id="comments">Comments</h2>

**Syntax:** Comments start with the hash character (`#`) and continue
to the end of the line.

**Meaning:** `smid` ignores comments completely.


