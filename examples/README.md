# Examples

These scripts showcase various parts of the language.

## [euclid-gcd.007](/masak/007/blob/master/examples/euclid-gcd.007)

Implements [Euclid's
algorithm](https://en.wikipedia.org/wiki/Euclidean_algorithm).

Showcases recursion and the `swap` macro.

## [factorial.007](/masak/007/blob/master/examples/factorial.007)

Declares a `postfix:<!>` operator for the
[factorial](https://en.wikipedia.org/wiki/Factorial).

Showcases custom operators.

## [ff.007](/masak/007/blob/master/examples/ff.007)

Implements the `infix:<ff>` macro and family.

Showcases stateful macros, and operator macros with their own `tighter`
precedence level. Also showcases thunky macro arguments.

## [format.007](/masak/007/blob/master/examples/format.007)

Implements a `format` macro for formatting text.

This macro does some checking at compile-time, catching possible logical errors
early.

## [in.007](/masak/007/blob/master/examples/in.007)

Implements an `infix:<in>` operator for checking membership/elementhood.

Showcases custom (non-macro) operators with `equiv` precedence.

## [incdec.007](/masak/007/blob/master/examples/incdec.007)

Implements the various prefix/postfix `--` and `++` operators.

Showcases mutating operators. Currently not-quite-correctly, due to known
problems with the Single Evaluation Rule.

## [name.007](/masak/007/blob/master/examples/name.007)

Implements a `name` macro which extracts the name of a variable or property.

Showcases a thing that macros can do that regular functions can't. The names of
variables are a property of the source text/AST, but usually not a part of the
running code. By virtue of running at compile time, a macro can extract the
name and re-insert it as a string literal in the code.

## [nicomachus.007](/masak/007/blob/master/examples/nicomachus.007)

Implements a number guessing game.

## [nim-addition.007](/masak/007/blob/master/examples/nim-addition.007)

Implements a `infix:<⊕>` operator for "bitwise xor".

Showcases custom operators with `equiv` precedence. Also inadvertently
showcases how 007 is somewhat suffering from the lack of support for low-level
bitwise operators; see [#461](/masak/007/issues/461).

## [power.007](/masak/007/blob/master/examples/power.007)

Implements an `infix:<**>` power/exponentiation operator.

Showcases a custom right-associative operator.

## [quicksort.007](/masak/007/blob/master/examples/quicksort.007)

Implements [QuickSort](https://en.wikipedia.org/wiki/Quicksort) (though not the
in-place version).

## [quine.007](/masak/007/blob/master/examples/quine.007)

A [quine](https://en.wikipedia.org/wiki/Quine_(computing)), that is, a program
that outputs its own source code.

## [swap.007](/masak/007/blob/master/examples/swap.007)

An implementation of the `swap` macro.

Also currently suffers from effects from the Single Evaluation Rule.

## [x-and-xx.007](/masak/007/blob/master/examples/x-and-xx.007)

Implements `infix:<x>` and `infix:<xx>`, for duplicating strings and arrays, respectively.

Showcases a macro with a thunky argument.

