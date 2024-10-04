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
    * Parameter binding happens, explained in section 5.8 "Parameter binding".
      If successful, this results in an extended environment.
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
see [Chapter 13: Macros](13-macros.md).

## 5.2 Optional parameters

A parameter is _required_ by default, but there are two different ways to
declare it _optional_, so that a call to the function will still succeed even
if the parameter is not passed.

A parameter can be declared optional using the `@optional` annotation:

```
func fnWithOptParam(@optional param) {
    say param;
}

fnWithOptParam(42);         // 42
fnWithOptParam();           // none

func fnWithReqParam(param) {
    say param;
}

fnWithReqParam(42);         // 42
fnWithReqParam();           // <error: too few arguments>
```

Or it can be declared optional using the `?` suffix on parameters:

```
func fnWithOptParam(param?) {
    say param;
}

fnWithOptParam(42);         // 42
fnWithOptParam();           // none
```

Using both forms at once is valid but redundant, and might be flagged by a code
linter:

```
func fnWithOptParam(@optional param?) {
    say param;
}

fnWithOptParam(42);         // 42
fnWithOptParam();           // none
```

In a function declaration with both required and optional parameters, all the
optional parameters must be declared after all the required ones.

## 5.3 Parameter defaults

_Parameter defaults_ are expressions that are evaluated if (and only if) an
argument was not passed. There are two different ways to declare a parameter
default.

The first way uses an annotation:

```
func fnWithParamDefault(@default(5) param) {
    say param;
}

fnWithParamDefault(42);     // 42
fmWithParamDefault();       // 5
```

The second way uses an infix `=` syntax:

```
func fnWithParamDefault(param = 5) {
    say param;
}

fnWithParamDefault(42);     // 42
fmWithParamDefault();       // 5
```

Using both syntaxes for the same parameter results in a declaration-time error:

```
func fnWithParamDefault(@default(1) param = 2) {    // <error: two defaults>
    say param;
}
```

Giving a parameter a default implies that the parameter is optional. Declaring
a parameter both optional and having a default is allowed, but the default is
enough.

```
func fnWithOptionalParamWithDefault(@optional @default(1) param) {  // fine
}

func fnWithOptionalParamWithDefault(@default(2) param?) {           // fine
}

func fnWithOptionalParamWithDefault(@optional param = 3) {          // fine
}

func fnWithOptionalParamWithDefault(param? = 4) {                   // fine
}
```

Because the parameter name itself indicates the point at which the parameter
is declared and thus visible, one difference between the annotation form and
the `=` form is that the parameter itself is bound and visible in the `=` form
but not in the annotation form:

```
func fnUsingParamInDefault(x = x) {             // fine
}

func fnUsingParamInDefault(@default(x) x) {     // <error: no such variable x>
}
```

## 5.4 Rest parameter

A function can handle an excess of arguments being passed by declaring a _rest
parameter_, which will bind to an array containing the excess arguments. There
are two syntaxes for declaring a rest parameter.

The first syntax uses a `@rest` annotation:

```
func fnWithRestParam(x, y, z, @rest r) {
    say r;
}

fnWithRestParam(1, 2, 3);           // []
fnWithRestParam(1, 2, 3, 4, 5);     // [4, 5]
```

The second syntax uses a prefix `...` on the parameter:

```
func fnWithRestParam(x, y, z, ...r) {
    say r;
}

fnWithRestParam(1, 2, 3);           // []
fnWithRestParam(1, 2, 3, 4, 5);     // [4, 5]
```

Using both forms at once is valid but redundant, and might be flagged by a code
linter:

```
func fnWithRestParam(x, y, z, @rest ...r) {
    say r;
}

fnWithRestParam(1, 2, 3);           // []
fnWithRestParam(1, 2, 3, 4, 5);     // [4, 5]
```

A parameter which is not a rest parameter is called an _individual_ parameter.

## 5.5 Named parameter

A _named_ parameter indicates that the corresponding operand should be written
as a key/value pair, using the same syntax as for dictionary key/value pairs:

```
func fnWithNamedParameter(@named param) {
    say param;
}

fnWithNamedParameter(param => "hi");    // hi
fnWithNamedParameter("hi");             // <error: missing named param "param">
```

There is only one syntax for declaring named parameters: the above `@named`
annotation syntax.

A parameter which is not named is called _positional_, as it is identified by
its position in the list of parameters.

In a function declaration with both positional and named parameters, all the
named parameters must be declared after all the positional ones.

By default, a named parameter is required, but it can be used together with the
`@optional` annotation (or the `?` syntax) to make it an optional named
parameter.

Similarly, a named parameter can be given a default, using either the
`@default` annotation, or the `=` syntax.

## 5.6 Named rest parameter

A named parameter which is also declared as a rest parameter is a _named rest
parameter_: it collects up any named arguments that were passed but don't have
a corresponding argument into a dictionary of excess named arguments.

```
func fnWithNamedRestArgument(
    @named x,
    @named @rest rest,      // @rest @named also works
) {
    say rest;
}

fnWithNamedRestArgument(x => 1, y => 2);    // { y => 2 }
fnWithNamedRestArgument(x => 1);            // {}
```

Any syntax for declaring the parameter a rest parameter works:

```
func fnWithNamedRestArgument(
    @named x,
    @named ...rest,
) {
    say rest;
}

fnWithNamedRestArgument(x => 1, y => 2);    // { y => 2 }
fnWithNamedRestArgument(x => 1);            // {}
```

## 5.7 Parameter type

A parameter can be associated with a type, in which case the argument is type
checked against the provided type during parameter binding. That is, the
expression `arg is T` must evaluate to a truthy value, or the parameter binding
will fail with (at the latest) a runtime error.

There are two ways to declare a type with a parameter. The first uses a `@type`
annotation:

```
func fnWithTypedParameter(@type(Int) x) {
    say x;
}

fnWithTypedParameter(42);       // 42
fnWithTypedParameter("hi");     // <error: type mismatch>
```

The second way uses an infix `:` syntax:

```
func fnWithTypedParameter(x: Int) {
    say x;
}

fnWithTypedParameter(42);       // 42
fnWithTypedParameter("hi");     // <error: type mismatch>
```

## 5.8 Parameter binding

During function invocation, when arguments have been passed to a function for
invocation, and before the function body can run, an environment is constructed in which the function body later runs.

This happens in two steps: first, making sure that there is an argument for
each required parameter and a parameter for each passed argument, and second,
binding the parameters in the new environment.

The first step breaks down into the following smaller steps:

* Assert that at least as many positional arguments have been passed as there
  are required positional parameters. If not, signal an exception.
* Assert that the number of positional arguments does not exceed the number of
  (required and optional) positional parameters, or that there's a positional
  rest parameter declared in the parameter list. If not, signal an exception.
    * If the positional rest parameter has a type, assert that the type is
      `Array<T>` for some `T`.
* Assert that, for each required named parameter, there is a named argument of
  that name. If not, signal an exception.
* Assert that all named arguments that were passed have a corresponding named
  parameter, or that a named rest parameter is declared in the parameter list.
  If not, signal an exception.
    * If the named rest parameter has a type, assert that the type is
      `Dict<string, V>` for some `V`.

At this point, we know that parameter binding won't fail because not enough
arguments were passed for the required parameters, or too many arguments were
passed that rest parameters weren't present to absorb.

* For each required positional parameter, bind it to the corresponding
  positional argument (of which we just checked there are enough). If the
  parameter has a type, check the argument against the type.
* For each optional positional parameter, bind it left-to-right to the
  corresponding positional argument, the value of the parameter default
  expression if present, or `none` if not. If the parameter has a type, check
  the bound value against the type.
* If there is a positional rest parameter, make an array of the remaining
  positional arguments, and bind the positional rest parameter to this array.
  If the positional rest parameter has a type `Array<T>`, check each remaining
  positional argument against `T`.
* For each required named parameter, bind it to the corresponding named
  argument (which we just asserted exists). If the parameter has a type, check
  the argument against the type.
* For each optional named parameter, bind it left-to-right (in the parameter
  list) to the corresponding named argument, the value of the parameter default
  expression if present, or `none` if not. If the parameter has a type, check
  the bound value against the type.
* If there is a named rest parameter, make a dictionary of the remaining named
  arguments (name and argument), and bind the named rest parameter to this
  dictionary. If the named rest parameter has a type `Dict<string, V>`, check
  each remaining named argument against `V`.

The resulting environment is the one that will be used when running the
function body.

## 5.9 Function body

The function body runs normally, except that the environment it runs in is
extended with the parameters bound to either arguments or parameter defaults.

Inside a function body, it is also valid to use the statement `return <expr>;`
which has the effect of evaluating `<expr>` and immediately terminating the
running of the function body, returning the value that results to the caller.

## 5.10 Returning from a function

A value is returned from the function, either by explicitly executing a
`return` statement in the function body, or by statement execution falling off
the end of the function body. In the latter case, the value returned from the
function is `none`.

## 5.11 Function return type

