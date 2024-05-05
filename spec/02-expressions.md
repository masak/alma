# Chapter 2: Expressions

An _expression_ is an algebraic representation of a computation; _evaluating_
an expression might yield a result value (unless the computation diverges), and
might raise one or more side effects.

```
<expression> ::= <literal-expression>
              |  <variable-lookup>
              |  <array-constructor>
              |  <dictionary-constructor>
              |  <function-constructor>
              |  <quasiquote>
              |  <call-expression>
              |  <index-lookup>
              |  <property-lookup>
              |  <range-constructor>
              |  <custom-constructor>
              |  <additive-expression>
              |  <multiplicative-expression>
              |  <string-expression>
              |  <equality-expression>
              |  <comparison-expression>
              |  <logical-expression>
              |  <conversion-expression>
              |  <assignment-expression>
```

Expressions adhere to the _expression protocol_, which requires an expression
to be combined with an environment for evaluation:

```
interface Expression {
    method evaluate(env: Environment): Any;
}
```

Functionally, the environment is a dictionary from names to values.

```
interface Environment {
    method lookup(name: Str): Any;
}
```

## 2.1 Literal expressions

A _literal expression_ consists of exactly one literal token, and evaluates
directly to its denoted value without any additional computation.

```
<literal-expression> ::= <literal>
```

Usage example:

```
false;          # value `false`
42;             # value `42`
"foo";          # value `"foo"`
```

## 2.2 Variable lookups

A _variable lookup_ finds up a bound value in the current environment by doing
a keyed lookup using the variable's name.

```
<variable-lookup> ::= <identifier>
```

Usage example:

```
x;              # looks up `x` in current environment
```

## 2.3 Array constructors

An _array constructor_ creates a new `Array`.

```
<array-constructor> ::= "[" (<expression>* %% ",") "]"
```

Usage example:

```
[1, 2, 3];      # new Array with elements 1, 2, 3
```

The unadorned square bracket syntax is syntactic sugar for the longer form
`Array::[...]`, where the type is given explicitly. Other types may also
be specified, as long as they support the array constructor syntax:

```
Array::[1, 2, 1];   # array with elements 1, 2, 1
Set::[1, 2, 1];     # set with elements 1, 2
Bag::[1, 2, 1];     # bag with elements 1, 1, 2
```

## 2.4 Dictionary constructors

A _dictionary constructor_ creates a new `Dict`.

```
<dictionary-constructor> ::= "{" (<key-value-pair>* %% ",") "}"

<key-value-pair> ::= <key> ":" <expression>

<key> ::= <identifier> | <keyword> | <alpha-literal>
```

Usage examples:

```
{ foo: 42 };    # new Dict with one entry
{
    x: 1,
    y: 2,
};              # new Dict with two entries
```

The unadorned curly brace syntax is syntactic sugar for the longer form
`Dict::{ ... }`, where the type is given explicitly. Other types may also
be specified, as long as they support the dictionary constructor syntax:

```
Dict::{ foo: 42 };  # dictionary with one key and one value
Bag::{ foo: 42 };   # bag with 42 copies of "foo"
Graph::{
    n1: ["n2"],
    n2: ["n1"],
};                  # graph with two nodes, pointing to each other
```

## 2.5 Function constructors

A _function constructor_ creates a new function value.

```
<function-constructor> ::= "func"
                           <identifier>?
                           "(" <parameter-list> ")"
                           <block>
```

It's important to note that the `func` keyword is also used for function
declarations (see [Chapter 4: Declarations](04-declarations.md)); in situations
where the `func` keyword could either be the start of a function declaration or
a function constructor, it's always a function declaration.

The function name is optional in a function constructor. If supplied, that
name is visible in the parameter list and body of the function, but not outside
the function constructor (since it's not a declaration).

Names that were bound in the environment where the function was constructed
are also visible inside the function. We say that the function _closes over_
those names; in practice, the function value gets a copy of the environment
where it was constructed. This environment is implicitly passed around
together with the function, if the function value is passed around as a
first-class value.

## 2.6 Quasiquotes

Quotation can mean many things, but for the purposes of this section, it means
representing a bit of fixed Alma code as its abstract syntax tree.

_Quasiquotation_ is like quotation, with some parts fixed and other parts
computed dynamically.

```
<quasiquote> ::= "quasi"
                 "{" (<statement-unq> | <declaration-unq>)* "}"
```

Uniquely for the code inside a quasiquote, the syntax `unquote(...)` is allowed
and allows for dynamic evaluation of an expression.

```
my fragment = quasi { "OH HAI" };
my ast = quasi { say( unquote(fragment) ) };    # quoted `say("OH HAI")`
```

Both the fixed parts and the dynamic/unquoted parts of the quasiquote follow
the normal scope rules of blocks in Alma, and have full access to their
outer environment. However, the dynamic code evaluates immediately on
quasiquote construction, whereas the fixed code closes over its surrounding
environment, much like a function does.

## 2.7 Call expressions

A _call expression_ can represent a runtime invocation (to something that
satisfies the invocation protocol), or alternatively a macro invocation
(which will be handled at compile time).

```
<call-expression> ::= <expression> "(" <argument>* %% "," ")"

<argument> ::= expression
```

If the call is a runtime invocation, the following steps happen:

* Evaluate the function expression
* Confirm that the result is indeed callable, and has a matching signature
  (or signal a runtime error)
* Evaluate each of the arguments, from left to right
* Bind the evaluated argument values to the corresponding parameters
* Run the function block, expecting a return value back representing the
  result of the call

If the call is a macro invocation, the steps happen during compile time
instead of at runtime; for details, see [Chapter 11: Macros](ch11-macros.md).

## 2.8 Indexed and keyed lookups

## 2.9 Property lookup

* `.` (postfix) property lookup

## 2.10 Range constructor

* `..` (infix) range constructor

## 2.11 Custom constructor

* `::` (infix) custom constructor

## 2.12 Arithmetic operators

* `+` (infix) addition
* `-` (infix) subtraction
* `*` (infix) multiplication
* `//` (infix) flooring division
* `%` (infix) modulo

## 2.13 String operators

* `~` (infix) concatenation

## 2.14 Equality operators

* `==` (infix) equality test
* `!=` (infix) inequality test

## 2.15 Comparison operators

* `<`/`<=` (infix) less-than/less-than-or-equal comparison
* `>`/`>=` (infix) greater-than/greater-than-or-equal comparison

## 2.16 Logical operators

* `&&` (infix) logical and
* `||` (infix) logical or

## 2.17 Conversion operators

* `+` (prefix) numification
* `-` (prefix) negated numification
* `~` (prefix) stringification
* `?` (prefix) boolification
* `!` (prefix) negated boolification

## 2.18 Assignment operators

* `=` (right-associating infix) assignment
* `+=`, `-=`, `*=`, `//=`, `%=`, `~=`, `&&=`, `||=`, `.=` (right-associating
  infix) derived assignment

## 2.19 Precedence table

* `.` (postfix) property lookup
* `::` (infix) custom constructor
* `..` (infix) range constructor
* `+` (infix) addition
* `-` (infix) subtraction
* `*` (infix) multiplication
* `//` (infix) flooring division
* `%` (infix) modulo
* `~` (infix) concatenation
* `==` (infix) equality test
* `!=` (infix) inequality test
* `<`/`<=` (infix) less-than/less-than-or-equal comparison
* `>`/`>=` (infix) greater-than/greater-than-or-equal comparison
* `&&` (infix) logical and
* `||` (infix) logical or
* `+` (prefix) numification
* `-` (prefix) negated numification
* `~` (prefix) stringification
* `?` (prefix) boolification
* `!` (prefix) negated boolification
* `=` (right-associating infix) assignment
* `+=`, `-=`, `*=`, `//=`, `%=`, `~=`, `&&=`, `||=`, `.=` (right-associating
  infix) derived assignment

