# Examples

These scripts showcase various parts of the language.

## [euclid-gcd.alma](/examples/euclid-gcd.alma)

Implements [Euclid's
algorithm](https://en.wikipedia.org/wiki/Euclidean_algorithm).

Showcases recursion and the `swap` macro.

## [factorial.alma](/examples/factorial.alma)

Declares a `postfix:<!>` operator for the
[factorial](https://en.wikipedia.org/wiki/Factorial).

Showcases custom operators.

## [ff.alma](/examples/ff.alma)

Implements the `infix:<ff>` macro and family.

Showcases stateful macros, and operator macros with their own `tighter`
precedence level. Also showcases thunky macro arguments.

## [format.alma](/examples/format.alma)

Implements a `format` macro for formatting text.

This macro does some checking at compile-time, catching possible logical errors
early.

## [in.alma](/examples/in.alma)

Implements an `infix:<in>` operator for checking membership/elementhood.

Showcases custom (non-macro) operators with `equiv` precedence.

## [incdec.alma](/examples/incdec.alma)

Implements the various prefix/postfix `--` and `++` operators.

Showcases mutating operators. Currently not-quite-correctly, due to known
problems with the Single Evaluation Rule.

## [name.alma](/examples/name.alma)

Implements a `name` macro which extracts the name of a variable or property.

Showcases a thing that macros can do that regular functions can't. The names of
variables are a property of the source text/AST, but usually not a part of the
running code. By virtue of running at compile time, a macro can extract the
name and re-insert it as a string literal in the code.

## [nicomachus.alma](/examples/nicomachus.alma)

Implements a number guessing game.

## [nim-addition.alma](/examples/nim-addition.alma)

Implements a `infix:<⊕>` operator for "bitwise xor".

Showcases custom operators with `equiv` precedence. Also inadvertently
showcases how Alma is somewhat suffering from the lack of support for low-level
bitwise operators; see [#461](/masak/007/issues/461).

## [power.alma](/examples/power.alma)

Implements an `infix:<**>` power/exponentiation operator.

Showcases a custom right-associative operator.

## [quicksort.alma](/examples/quicksort.alma)

Implements [QuickSort](https://en.wikipedia.org/wiki/Quicksort) (though not the
in-place version).

## [quine.alma](/examples/quine.alma)

A [quine](https://en.wikipedia.org/wiki/Quine_(computing)), that is, a program
that outputs its own source code.

## [swap.alma](/examples/swap.alma)

An implementation of the `swap` macro.

Also currently suffers from effects from the Single Evaluation Rule.

## [x-and-xx.alma](/examples/x-and-xx.alma)

Implements `infix:<x>` and `infix:<xx>`, for duplicating strings and arrays, respectively.

Showcases a macro with a thunky argument.

