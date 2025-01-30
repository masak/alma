# Chapter 3: Statements

A _statement_ is an imperative representation of a computation; _executing_
a statement might cause one or more side effects, but does not yield a result
value. Whereas expressions are primarily about reaching a result value,
statements are primarily about orchestrating control flow or raising some
other effect.

What happens after a statement executes depends on whether the statement
finishes _normally_ or _abruptly_. In general, the former means that the
next statement in order will execute, and the latter means that it will not,
and something else will happen next. At the extreme end, program execution
itself can finish abruptly. In order to more finely control the execution of
blocks, loops, and loop iterations, labels can be declared and used.

Statements are semicolon-terminated; in general, it is legal for any statement
to end with a semicolon. However, the semicolon can be omitted for any
statement which occurs last in its block or compilation unit. Also, a special
provision is made for statements which end in a closing curly brace (`}`); if
the curly brace is followed by (horizontal whitespace and) a newline, then the
semicolon can be omitted. All these rules are captured in the nonterminal
`<semicolon>`, which usually resolves to a semicolon, but sometimes resolves
to block end, compilation unit end, or closing curly brace and newline.

```
<statement> ::= <empty-statement>
             |  <expression-statement>
             |  <if-statement>
             |  <while-statement>
             |  <for-statement>
             |  <next-statement>
             |  <last-statement>
             |  <return-statement>
             |  <throw-statement>
             |  <catch-phaser>
             |  <leave-phaser>
             |  <sorry-statement>
             |  <block-statement>
             |  <labeled-statement>
```

## 3.1 Empty statement

An _empty statement_ does nothing.

```
<empty-statement> ::= <semicolon>
```

## 3.2 Expression statement

An _expression statement_ evaluates an expression. The value from the
expression is discarded.

```
<expression-statement> ::= <expression> <semicolon>
```

## 3.3 `if` statement

An _`if` statement_ evaluates a condition, and uses the result of the condition
to decide whether to (in the truthy case) evaluate the first block, or (in the
falsy case) evaluate the (optional) rest of the statement (which might be a
single unconditional block, or a nested `if` statement).

```
<if-statement> ::= "if"
                   <expression>
                   <xblock>
                   (<empty> | <xblock> | <if-statement>)
                   <semicolon>
```

## 3.4 `while` statement

A _`while` statement_ evaluates a condition; in case this condition evaluates
to a truthy value, the corresponding block is run, and the `while` statement
is re-executed; in case the condition evaluates to a falsy value, the `while`
statement finishes normally.

```
<while-statement> ::= "while" <expression> <xblock> <semicolon>
```

## 3.5 `for` statement

A _`for` statement_ evaluates an expression, expecting it to be an `Array`;
if it is not, execution terminates abruptly with an error. If it is an
array, the block is executed once for each element in the array. If the block
provided for the body has a parameter, this parameter is bound to the current
element at each iteration.

```
<for-statement> ::= "for" <expression> <xblock> <semicolon>
```

## 3.6 `next` statement

A _`next` statement_ abruptly finishes a surrounding loop iteration, and begins
the next one. This statement can only occur inside a loop block. A label, if
provided, must resolve to the `Label` of a surrounding loop.

```
<next-statement> ::= "next" <label>? <semicolon>
```

## 3.7 `last` statement

A _`last` statement_ abruptly finishes by successfully finishing the
surrounding loop, meaning that execution continues immediately after the loop
itself. This statement can only occur inside a loop block. A label, if
provided, must resolve to the `Label` of a surrounding loop.

```
<last-statement> ::= "last" <label>? <semicolon>
```

## 3.8 `return` statement

A _`return` statement_ abruptly finishes the innermost surrounding routine and
returns a value from it. Evaluation continues after the expression that called
the function. This statement can only occur lexically inside a routine. An
expression, if provided, is used to determine the return value; if no
expression is provided, the value `none` is returned.

```
<return-statement> ::= "return" <expression>? <semicolon>
```

## 3.9 `throw` statement

A _`throw` statement_ evaluates an expression to a value (expected to be of
type `Exception`), and abruptly finishes and proceeds up the dynamic call
stack, looking for the first `CATCH` phaser. Execution continues at the `CATCH`
phaser's block. In case there is no such `CATCH` phaser, program execution
finishes abruptly with an error based on the value.

```
<throw-statement> ::= "throw" <expression> <semicolon>
```

## 3.10 `CATCH` phaser

A _`CATCH` phaser_ does not run as part of the normal control flow. Instead, it
triggers if an exception is thrown and unrolls to the dynamic scope of the
surrounding block. The optional parameter to the `CATCH` block is the
exception.

```
<catch-phaser> ::= "CATCH" <xblock> <semicolon>
```

At most one `CATCH` phaser per block is allowed.

## 3.11 `LEAVE` phaser

A _`LEAVE` phaser_ does not run as part of the normal control flow. Instead, it
triggers unconditionally on the surrounding block's exit, whether that exit is
a normal exit through the bottom of the block, or an abrupt exit such as via
`last` or `return` or `throw`.

```
<leave-phaser> ::= "LEAVE" <block> <semicolon>
```

Teardown logic that needs to run regardless of how the block exits should be
put in a `LEAVE` phaser.

If several `LEAVE` phasers are in the same block, they will run in reverse
textual order.

## 3.12 `sorry` statememt

A _`sorry` statement_ abruptly finishes the program execution. An
implementation is encouraged to not only indicate clearly where execution
halted, but also keep enough of the aborted program state around (local
variable bindings, call stack, etc.) to be able to debug and inspect the
program at that point.

## 3.13 Block statement

A _block statement_ runs a block, and finishes normally.

In case of a grammatical conflict between a `{` starting a block statement and
a `{` starting an object literal starting an expression statement, parsing
resolves this conflict in favor of the block statement.

```
<block-statement> ::= <block>
                      <semicolon>

<block> ::= "{" (<statement> | <declaration>)* "}"
```

Blocks occur regularly inside other statement forms. There are also _pointy
blocks_, which accept a parameter list:

```
<pblock> ::= "->" <parameter-list> <block>
```

But pointy blocks are not usually used directly; instead, the option is usually
given between plain blocks and pointy blocks:

```
<xblock> ::= <block> | <pblock>
```

## 3.14 Labeled statement

A _labeled statement_ is a statement optionally preceded by a label and a
colon. All statements are allowed to be labeled statements, although by
default only loops and block statements make any use of having a label.
A statement can have zero or more labels.

The label is an identifier, with the colon not being considered part of the
label itself. The presence of a label in a labeled statement counts as a
declaration, and the name of the label is bound in the lexical scope to a
value of type `Label`.

```
<labeled-statement> ::= <label> ":" <statement>

<label> ::= <identifier>
```

