# Chapter 5: Functions

_Functions_ are independent chunks of program code. _Calling_ or _invoking_ a
function causes its code to run. A function has zero or more _parameters_,
which are bound to _arguments_ from a call expression. If the function body
finishes normally, a value may be returned from the function; this value then
becomes the value of the call expression that invoked the function.

## 5.1 Function calls

Call expressions were described in section 2.8 "Call expressions";
syntactically, a call expression consists of a _callable expression_ followed
by a (parentheses-enclosed) list of _operands_, which are also expressions.
At the time of evaluating the call expression, the following steps happen:

* The callable expression is fully evaluated into a value.
* This value is confirmed to be a function, or more precisely a value which
  implements the invocation protocol; if not, then an exception is signaled
  at runtime and evaluation stops.
* All of the operands are evaluated, left-to-right, into values called
  _arguments_.
* The `call` method of the invocation protocol is invoked, with an array of
  the arguments.
    * Parameter binding happens, explained in the next section. If successful,
      this results in an extended environment.
    * The function's body is run. This is explained in section 5.3 "Function
      body".
    * Eventually, control might return normally, in which case a value is
      returned. This value is then the value of entire call expression. This is
      explained in section 5.4 "Returning from a function".

This describes a "call-by-value" convention, in which only values are passed
from call sites to functions; that is, the operand expressions are entirely
evaluated at the call site, and then the resulting values are passed.

Operator expressions, although syntactically different, can be seen as
syntactic sugar for the above call expressions. This is true both for built-in
operators and user-defined ones.

Both in the case of call expressions and in the case of operator expressions,
if the callable expression (statically) resolves to a macro, then macro
expansion instead takes place at compile time. For more on macro expansion,
see [Chapter 12: Macros](12-macros.md).

## 5.2 Optional parameters

xxx `@optional` syntax

xxx `?` syntax

## 5.3 Parameter defaults

xxx `@default(expr)` syntax

xxx `=` syntax

## 5.4 Rest parameter

xxx `@rest` syntax

xxx `...` syntax

## 5.5 Named parameter

xxx `@named` syntax

## 5.6 Named rest parameter

xxx it's a combination of `@named` and `@rest` (in any order)

xxx or `@named` and `...`

## 5.8 Parameter binding

After the arguments are passed to a function for invocation, and before we can
run the function body, an environment for running the function body needs to
be prepared. This happens in two steps: making sure that there is an argument
for each required parameter and a parameter for each passed argument, and
binding the parameters in the new environment.

* Assert that at least as many positional arguments have been passed as there
  are required positional parameters. If not, signal an exception.
* Assert that if more positional arguments were passed than positional
  arguments (required and optional both), there's a positional rest parameter
  present. If not, signal an exception.
* Assert that the set of names of named arguments is non-strictly contained by
  the set of names of required named parameters. If not, signal an exception.
* Assert that if the set of names of named arguments contains a name not
  contained in the set of names of named arguments (required and optional
  both), there's a named rest parameter present. If not, signal an exception.

At this point, we know that parameter binding won't fail because not enough
arguments were passed for the required parameters, or too many arguments were
passed that rest parameters weren't present to absorb.

* For each required positional parameter, bind it to the corresponding
  positional argument (of which we just checked there are enough).
* For each optional positional parameter, bind it (in decreasing order of
  preference) to the corresponding positional argument, the value resulting
  from evaluating the corresponding parameter default expression, or `none`.
* Make an array of any remaining positional arguments, and bind the positional
  rest parameter (which at this point must exist) to it.
* For each required named parameter, bind it to the corresponding named
  argument (which we just asserted exists).
* For each optional named parameter, bind it (in decreasing order of
  preference) to the corresponding named argument, the value resulting from
  evaluating the corresponding parameter default expression, or `none`.
* Make a dictionary of any remaining named arguments, keys being the names and
  values being the named arguments, and bind the named rest parameter (which at
  this point must exist) to it.

The resulting environment is the one that will be used when running the
function body.

## 5.9 Function body

## 5.10 Returning from a function

