# Reference.

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



<h2 id="comments">Comments</h2>

**Syntax:** Comments start with the hash character (`#`) and continue
to the end of the line.

**Meaning:** `smid` ignores comments completely.



<h2 id="transitions">Transitions</h2>

**Syntax:** Transitions generally have the following shape:

    start state(s) -- list of actions --> end-state

* The `start-state(s)` is a space-delimited list of states. The list
  of states may be preceeded with the keyword [`all`](#all) or
  [`all-except`](#all).
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


<h3 id="transition-variations">Variations</h3>

If there are several actions in a transition, the preferred way to
write them is across multiple lines:
<p class="block"><code>
@import examples/multi-action.sm
</code></p>



<h2 id="initial-declarations">Initial states</h2>

**Syntax:** The state machine's *initial state* is declared with the
keyword `initial`, followed by the name of the state.

**Meaning:** `smid` 'starts' on the initial state. It then begins to
interact with your application by taking one of the
[transitions](#transitions) that start on the initial state.



<h2 id="final-declarations">Final states</h2>



<h2 id="state-hook-declarations">State hooks</h2>
