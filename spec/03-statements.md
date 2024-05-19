# Chapter 3: Statements

A _statement_ is an imperative representation of a computation; _executing_
a statement might raise one or more side effects, but does not yield a result
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
             |  <try-statement>
             |  <block-statement>
             |  <labeled-statement>
```

## 3.1 Empty statement

An _empty statement_ does nothing, and finishes normally.

```
<empty-statement> ::= <semicolon>
```

## 3.2 Expression statement

An _expression statement_ evaluates an expression, and finishes normally.

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
array, the block is executed once for each element in the array, possibly
passing in the element as an argument.

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

A _`return` statement_ abruptly finishes and returns a value out of the
innermost surrounding function. Evaluation continues after the expression that
called the function. This statement can only occur inside a routine. An
expression, if provided, is used to determine the return value; if no
expression is provided, the value `none` is returned.

```
<return-statement> ::= "return" <expression>? <semicolon>
```

## 3.9 `throw` statement

A _`throw` statement_ evaluates an expression to a value (expected to be of
type `Exception`), and abruptly finishes and proceeds up the dynamic call
stack, looking for the first `catch` clause that matches the value. Execution
continues at the `catch` clause's block. In case there is no such `catch`
clause, program execution finishes abruptly with an error based on the value.

```
<throw-statement> ::= "throw" <expression> <semicolon>
```

## 3.10 `try` statement

A _`try` statement_ runs a block, but intercepts any exceptions bubbling up
from within the execution of the block; the block either finishes normally
without any such exception occurring, or it finishes abruptly, in which case
the `catch` clauses each get a chance, in order, to match against the
exception. If one matches, its corresponding block runs and the `try`
statement finishes normally. If no `catch` clause matches, the `try`
statement finishes abruptly, and the exception keeps bubbling up the dynamic
call stack. No matter what happens with the `try` block and the `catch`
clauses, if a `finally` block is supplied, it will always run after the
(normal or abrupt) execution of the preceding `try` statement.

```
<try-statement> ::= "try"
                    <block>
                    ("catch" <type> <xblock>)*
                    ("finally" <block>)?
                    <semicolon>
```

## 3.11 Block statement

A _block statement_ runs a block, and finishes normally.

In case of a grammatical conflict between a `{` starting a block statement and
a `{` starting an expression statement starting an object literal, it's
resolved in favor of the block statement.

```
<block-statement> ::= <block>
                      <semicolon>

<block> ::= "{" (<statement> | <declaration>)* "}"
```

Blocks occur regularly inside other statement forms. There are also _pointy
blocks_, which accept a parameter:

```
<pblock> ::= "->" <parameter> <block>
```

But pointy blocks are not usually used directly; instead, the option is usually
given between plain blocks and pointy blocks:

```
<xblock> ::= <block> | <pblock>
```

## 3.12 Labeled statements

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

