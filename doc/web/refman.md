# Reference.

This manual describes the syntax of `.sm` files. Having a little
experience with using the `smid` tool is probably helpful before
reading this manual.

## Overview.

There are 5 kinds of statement in `smid`:

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
whitespace is allowed. There are no line terminators (like colons
`;`).

<h2 id="comments">Comments</h2>
<h2 id="initial-declarations">Initial states</h2>
<h2 id="final-declarations">Final states</h2>
<h2 id="transitions">Transitions</h2>
<h2 id="state-hook-declarations">State hooks</h2>
