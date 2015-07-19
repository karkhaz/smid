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
<a href="#regions">Region declarations</a>
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

**Example:** consider this `smid` file:

<p class="block"><code>
@import examples/3-trans.sm
</code></p>
![3-trans](examples/3-trans.png)

If the current state is `bar`, then `smid` can either:

* Send the key-press `Ctrl+M` to the application and set the current
  state to `foo`;
* Send the key-press `Ctrl+U` followed by `Ctrl+L` to the application
  and set the current state to `baz`.

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
application. If `smid` walks over a [transition](#transitions),
it will perform all of the actions specified in that transition. In
the following example, there are two actions in the transition:

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

    keys [ Ctrl+M  5  space  Return ]

**Meaning:** The `keys` action causes `smid` to send keypresses to your
application, as if the user had entered those keypresses on the
keyboard.

**Syntax:** The keyword `keys`, followed by a space-delimited list of
keysyms. The list is surrounded with square braces `[ ]`. 'Keysyms'
are names for keys; a list of valid keysyms can be found
[here](http://wiki.linuxquestions.org/wiki/List_of_KeySyms), along
with [additional
keysyms](http://wiki.linuxquestions.org/wiki/XF86_keyboard_symbols)
sometimes found on laptops. Key combinations are separated using the
plus sign `+`.




<h4 id="text">text</h4>

    text "quoted text"

**Meaning:** The `text` action causes `smid` to type the quoted
string, as if the user had typed it on the keyboard.

**Syntax:** The keyword `text`, followed by a string surrounded by
double-quotes. If you wish to include a double-quote inside the
string, escape it with a backslash: `\"`.



<h4 id="line">line</h4>

    line "filename"

**Meaning:** The `line` action causes `smid` to read a random line
from the file named in the quotes, and type that line as if the user
had typed it on the keyboard.

The `line` action is an alternative to writing out several transitions
with `text` actions in the `smid` file. Instead of the following
`smid` file:

<p class="block"><code>
@import examples/several-line.sm
...
</code></p>

we could instead create a file `urls.lines`:

    www.startpage.com
    www.lwn.net
    ...

and then specify this single transition in `smid`:

<p class="block"><code>
@import examples/one-line.sm
</code></p>

**Syntax:** the keyword `line`, followed by a relative file path in
double-quotes.

**Usage note:** If the file does not reside in the current directory
when you run `smid`, you can specify the directory that it is located
in using the `--include-dir` option to `smid`.


<h4 id="move">move</h4>

    move ( x  y )
    move ( start_x  start_y  end_x  end_y )
    move region_name

**Meaning:** The `move` action moves the cursor to some point on the
current window.

* If given two numbers, `smid` moves the cursor to that exact
  coordinate, where (0, 0) is the top-left of the window.
* If given four numbers, `smid` moves the cursor to a random point in
  the rectangle specified by the four numbers.
* If given the name of a [`region`](#regions), `smid` moves the cursor
  to some point in that region.

**Syntax:** The keyword `move`, followed by two or four positive
integers in parentheses, or an identifier that names a
[`region`](#regions). If four integers are given, the third must be
larger than the first, and the fourth must be larger than the second.



<h4 id="move-rel">move_rel / movr</h4>

    move_rel ( x  y )
    movr     ( x  y )

**Meaning:** The `movr` action moves the cursor relative to its
current location.

**Syntax:** The keyword `move_rel` or its alias `movr`, followed by
two integers in parentheses. Positive integers move the cursor
rightward or downward, while negative integers move the cursor
leftward or upward.



<h4 id="click">click / clik</h4>

    click ( frequency left  )
    click ( frequency right )
    clik  ( frequency left  )
    clik  ( frequency right )

**Meaning:** The `click` action simulates a mouse click.

**Syntax:** The keyword `click` or its alias `clik`, followed by an
integer and the word `left` or `right` in parentheses. The integer
indicates how many clicks are sent (single-click, double-click, etc)
and the `left` or `right` indicates the mouse button. The integer and
mouse button can be in either order.



<h4 id="scroll">scroll / scrl</h4>

    scroll ( distance up   )
    scroll ( distance down )
    scrl   ( distance up   )
    scrl   ( distance down )

**Meaning:** The `scroll` action simulates scrolling with a mouse
wheel or trackpad.

**Syntax:** The keyword `scroll` or its alias `scrl`, followed by an
integer and the word `up` or `down` in parentheses. The integer
indicates how far to scroll, and the `up` or `down` indicates the
direction to scroll in. The distance and direction can be in either
order.


<h4 id="shell">shell / shel</h4>

    shell { arbitrary shell commands }
    shel  { arbitrary shell commands }

**Meaning:** The `shell` action causes `smid` to execute the commands
in a shell.

**Syntax:** The keyword `shell` or its alias `shel`, followed by
arbitrary shell code surrounded by curly brackets `{}`. You may write
a closing curly bracket inside the shell code by escaping it with a
backslash `\}`.


<h4 id="winc">win-change / winc</h4>

    win-change  "window name"
    winc        "window name"

**Meaning:** The `winc` action causes `smid` to direct all future
interactions towards windows whose title matches the specified window
name.

`smid` always needs a target window for its user interactions.
Sometimes the target window changes (for example, when opening a save
dialog, you will want to direct new actions to the dialog window).

You must add a `winc` action as a [pre-state hook](#hooks) to the
[initial state](#initial-declarations) to tell `smid` what the
initially-opened window of the target program is.

**Example**
<p class="block"><code>
@import examples/winc.sm
</code></p>

**Syntax:** The keyword `win-change` or its alias `winc`, followed by
a string in double-quotes.


<h4 id="prob">prob</h4>

    prob high
    prob med
    prob low

**Meaning:** The `prob` action changes the probability that the
transition it resides in will be taken, compared to other transitions
out of the same state.

In the following example, if `smid` is on state `foo`:

*  `smid` is more likely to do the `Ctrl+t` action than the `Ctrl+u`
    action
*   `smid` is more likely to do the `Ctrl+u` action than the `Ctrl+m`
    action

<p class="block"><code>
@import examples/prob.sm
</code></p>
![prob](examples/prob.png)

<h3 id="hooks">State hooks</h3>


<h2 id="initial-declarations">Initial states</h2>

**Syntax:** The state machine's *initial state* is declared with the
keyword `initial`, followed by the name of the state.

**Meaning:** `smid` 'starts' on the initial state. It then begins to
interact with your application by taking one of the
[transitions](#transitions) that start on the initial state.



<h2 id="final-declarations">Final states</h2>


<h2 id="comments">Comments</h2>

**Syntax:** Comments start with the hash character (`#`) and continue
to the end of the line.

**Meaning:** `smid` ignores comments completely.


<h2 id="regions">Regions</h2>

    region id = ( x  y )
    region id = ( start_x  start_y  end_x  end_y )

A region is an alias for a location on the window. Often, you will
want to direct several actions to the same coordinates or rectangle of
the screen:

<p class="block"><code>
@import examples/coords.sm
...
</code></p>

We can make this more readable by naming the coordinates with a
region:

<p class="block"><code>
@import examples/region.sm
</code></p>

**Syntax:** The keyword `region`, followed by an identifier, then an
equals sign `=`, and two or four positive integers in parentheses.

**Meaning:** When a `move` action specifies a region as its
target, `smid` will move to the coordinates of the region in the same
way described in the section on [`move`](#move).
