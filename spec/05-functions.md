# Chapter 5: Functions

_Functions_ are independent chunks of program code. _Calling_ or _invoking_ a
function causes its code to run. A function has zero or more _parameters_,
variables which become bound to _arguments_ passed from a call expression. A
function's body may finish _normally_ or _abruptly_. If it finishes normally, a
value is returned from the function; this is then the value of the call
expression that invoked the function.

## 5.1 Function calls

Call expressions are described in section 2.8 "Call expressions";
syntactically, a call expression consists of a _callable expression_ followed
by a (parentheses-enclosed) list of _operands_, which are also expressions. At
the time of evaluating the call expression, these steps happen:

* The callable expression is fully evaluated into a value.
* This value is confirmed to be a function, or more precisely a value which
  implements the invocation protocol; if not, an exception is signaled at
  runtime, and evaluation stops.
* All of the operands are evaluated, left-to-right, into values called
  _arguments_.
* The `call` method of the invocation protocol is invoked, with an array of
  the arguments.
    * Parameter binding happens, explained in section 5.8. If successful,
      this results in an extended environment.
    * The function's body is run in the extended environment. This is explained
      in section 5.9 "Function body".
    * Eventually, control might return normally, in which case a value is also
      returned. This value is then the value of entire call expression. This is
      explained in section 5.10 "Returning from a function".

This describes a "call-by-value" convention, in which only values are passed
from call sites to functions. The operand expressions are entirely evaluated at
the call site, and then the resulting values are passed.

Operator expressions, although syntactically different, can be viewed as
syntactic sugar for the above call expressions.

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

During function invocation, when arguments have been passed to a function for
invocation, and before the function body can run, an environment is constructed in which to run the function body.

This happens in two steps: first, making sure that there is an argument for
each required parameter and a parameter for each passed argument, and second,
binding the parameters in the new environment.

The first step breaks down into the following smaller steps:

* Assert that at least as many positional arguments have been passed as there
  are required positional parameters. If not, signal an exception.
* Assert that the number of positional arguments does not exceed the number of
  (required and optional) positional parameters, or that there's a positional
  rest parameter declared in the parameter list. If not, signal an exception.
* Assert that, for each required named parameter, there is a named argument of
  that name. If not, signal an exception.
* Assert that all named arguments that were passed have a corresponding named
  parameter, or that a named rest parameter is declared in the parameter list.
  If not, signal an exception.

At this point, we know that parameter binding won't fail because not enough
arguments were passed for the required parameters, or too many arguments were
passed that rest parameters weren't present to absorb.

* For each required positional parameter, bind it to the corresponding
  positional argument (of which we just checked there are enough).
* For each optional positional parameter, bind it left-to-right to the
  corresponding positional argument, the value of the parameter default
  expression if present, or `none` if not.
* If there is a positional rest parameter, make an array of the remaining
  positional arguments, and bind the positional rest parameter to this array.
* For each required named parameter, bind it to the corresponding named
  argument (which we just asserted exists).
* For each optional named parameter, bind it left-to-right (in the parameter
  list) to the corresponding named argument, the value of the parameter default
  expression if present, or `none` if not.
* If there is a named rest parameter, make a dictionary of the remaining named
  arguments (name and argument), and bind the named rest parameter to this
  dictionary.

The resulting environment is the one that will be used when running the
function body.

## 5.9 Function body

## 5.10 Returning from a function

