# Chapter 1: Lexical grammar

## 1.1 File format

An Alma _compilation unit_ is a UTF-8 encoded text string, parsed into a list
of declarations and statements.

A compilation unit is either a single entry-point file ("script"), a module
file, or an input at the interactive prompt. Unless otherwise specified, the
assumption is that the compilation unit is an entry-point file; the exceptions
are described in [Chapter 8: Modules](08-modules.md) and [Chapter 9:
Interactivity](09-interactivity.md).

As part of parsing a compilation unit, the text is subdivided into tokens,
whitespace, and comments. The rest of this chapter describes this subdivision.

## 1.2 Whitespace

A maximal contiguous sequence of the following characters is one unit of
_whitespace_:

* `\u0009` horizontal tab
* `\u000a` line feed
* `\u000d` carriage return
* `\u0020` space

The rule for recognizing whitespace is valid only between tokens, not within
them; when the above characters occur within a string literal or a comment,
they are not considered to be whitespace.

The tab character is allowed but its use is discouraged. It's recommended to
use four spaces for indentation.

The UTF-8 byte-order mark ("BOM") at the beginning of a compilation unit is
recognized and ignored as whitespace.

The following Unicode characters are disallowed both as part of whitespace,
and in any other part of the file (including string literals and comments),
except the BOM remark above:

* `\u00a0` no-break space
* `\u2000` en quad
* `\u2001` em quad
* `\u2002` en space
* `\u2003` em space
* `\u2004` three-per-em space
* `\u2005` four-per-em space
* `\u2006` six-per-em space
* `\u2007` figure space
* `\u2008` punctuation space
* `\u2009` thin space
* `\u200a` hair space
* `\u200b` zero width space
* `\u200c` zero width non-joiner
* `\u200d` zero width joiner
* `\u202f` narrow no-break space
* `\u205f` medium mathematical space
* `\u2060` word joiner
* `\u3000` ideographic space
* `\ufeff` zero width no-break space

## 1.3 Comments

A _comment_ starts with an octothorpe (`#`) and extends until the end of the
line, namely until (but not including) one of the following, whichever comes
first:

* `\u000a` line feed
* `\u000d` carriage return
* end of the compilation unit

The rule for recognizing comments is valid only between tokens, not within
them; when the `#` character occurs within a string literal or a comment,
it does not begin a comment.

The remaining sections describe token types which are significant, and which
are consumed by the context-free parser during syntactic analysis.

## 1.4 Literals

_Literals_ denote simple values such as integers, strings, and booleans.

The `none` literal denotes the unique value of type `None`.

The `true` and `false` literals denote the two values of type `Bool`.

An integer literal is a maximal contiguous sequence of ASCII digits (`0`..`9`).

A string literal begins with a double quote (`"`), zero or more characters of
string content, and ends with a double quote (`"`). The string content is
parsed as either

* any non-control ASCII character except for `"` or `\\`, or
* a backspace (`\\`), followed by any non-control ASCII character.

Due to these rules, a double quote can occur within a string literal only by
being preceded by a backslash. More generally, non-alphanumeric characters
preceded by a backslash are treated literally as meaning themselves. For a
small set of letters, there are pre-set meanings:

* `\t` means horizontal tab (`\u0009`)
* `\n` means line feed (`\u000a`)
* `\r` means carriage return (`\u000d`)
* `\uXXXX` (four hex digits) means the character with codepoint `XXXX`

Although the allowed literals in a language normally form a closed set, in Alma
this set can be extended. For more, see [Chapter 17: Extending the
lexer](17-extending-the-lexer.md).

## 1.5 Keywords

The following words are _keywords_ in Alma:

* `class`
* `else`
* `enum`
* `export`
* `func`
* `for`
* `if`
* `import`
* `interface`
* `last`
* `macro`
* `method`
* `my`
* `next`
* `quasi`
* `return`
* `throw`
* `try`
* `unquote`
* `while`

Along with the alphabetic literals `none`, `true`, and `false`, the keywords
are _reserved words_: they can not be used as new names in declarations.
However, they can still be used for unscoped literals such as dictionary
keys and object properties.

Although the keywords in a language normally form a closed set, in Alma this
set can be extended. For more, see [Chapter 17: Extending the
lexer](17-extending-the-lexer.md).

## 1.6 Identifiers

An _identifier_ begins with an alphabetic ASCII character or underscore (`_`),
and consists of one or more alphanumeric characters or underscore. Asterisks
may appear in an identifier _only_ if one appears first and one appears last,
but no asterisks appear anywhere else.

The following are examples of valid identifiers by the above rules:

* `apple`
* `_banana42`
* `_`
* `_007`
* `*earmuffs*`

But these are not valid identifiers:

* `42`
* `*front`
* `back*`
* `mid*dle`
* `*foo*'`

In a limited set of circumstances, an _extended identifier_ is recognized
by the parser. An extended identifier is a maximal sequence of Unicode
characters, but excluding Unicode whitespace characters and delimiters and
punctuators.

When it's important to make the distinction, the kind of identifier that is
not an extended identifier is called a _regular identifier_.

An extended identifier is considered to be valid if the following three
conditions hold:

* its first character is an underscore (`_`), or its last character is an
  underscore, or both,
* there's at least one more character, and
* none of the remaining characters is an underscore.

These validity rules allow extended identifiers to denote the three categories
of operators: `_xyz` (prefix), `_xyz_` (infix), and `xyz_` (postfix), and
nothing else. Specifically, the following are disallowed: `xy` (terms), and
`if_then_else_` (mixfix).

## 1.7 Operators

An expression consists of terms joined together by _operators_, sequences of
characters which are not underscores (`_`), delimiters, or punctuators.

By these rules, operators can overlap with (regular) identifiers. For example,
`is` and `as` parse as operators in some contexts, and as identifiers in other
contexts. For details, see section 1.10, "Scannerless parsing".

The following Alma operators are built in:

* `+` (prefix) numification and (infix) addition
* `-` (prefix) negated numification and (infix) subtraction
* `*` (infix) multiplication
* `//` (infix) flooring division
* `%` (infix) modulo
* `~` (prefix) stringification and (infix) concatenation
* `?` (prefix) boolification
* `!` (prefix) negated boolification
* `&&` (infix) logical and
* `||` (infix) logical or
* `.` (postfix) property lookup
* `::` (infix) custom constructor
* `..` (infix) range constructor
* `==` (infix) equality test
* `!=` (infix) inequality test
* `<`/`<=` (infix) less-than/less-than-or-equal comparison
* `>`/`>=` (infix) greater-than/greater-than-or-equal comparison
* `is`/`as` (infix)
* `=` (right-associating infix) assignment
* `+=`, `-=`, `*=`, `//=`, `%=`, `~=`, `&&=`, `||=`, `.=` (right-associating
  infix) derived assignment

For more on these operators and their semantics, see [Chapter 2:
Expressions](02-expressions.md).

Alma's operators form an open set which can be extended in a given scope by
defining new operators. For more, see [Chapter 4:
Declarations](04-declarations.md).

## 1.8 Delimiters

_Delimiters_ are tokens to mark the beginning or end of something, and come in
pairs. We refer to the two delimiters in a pair as the _opener_ and the
_closer_, respectively.

The `(` and `)` delimiters are used for grouping and enclosure:

* In term position in expressions, they are used for grouping and overriding
  precedence, as in `a * (b + c)`.
* In postfix position in expressions, they are used for function calls and
  method calls, as in `foo(1, 2)` and `o.m()`.
* They are used to enclose the list of parameters in function declarations and
  macro declarations.
* They are used to delimit parameters to an annotation.
* They are used in the `unquote(...)` syntax to delimit an interpolated
  expression.

The `[` and `]` delimiters are related to containers:

* In term position in expressions, they act as an array constructor.
* In postfix position in expressions, they are used both for indexed lookup
  and for keyed lookup.

The `{` and `}` delimiters are used both for blocks and for containers:

* At the start of a statement, they begin a block statement.
* In term position in expressions, they act as a dictionary constructor.
* They serve as syntax for blocks in many statement forms (such as `if`), and
  many declaration forms (such as `func`).
* They are part of the `import` syntax, to name or rename the imported items
  from a module.

Although the delimiters in a language normally form a closed set, in Alma this
set can be extended. For more, see [Chapter 17: Extending the
lexer](17-extending-the-lexer.md).

## 1.9 Punctuators

Whereas operators occur within expressions, _punctuators_ happen between
expressions, or between other things such as statements or declarations.
Although they are similar in their function to (infix) operators, they are
governed not by a surrounding expression, but by a surrounding syntactic
context which is not an expression (such as a parameter list).

The built-in punctuators are as follows:

* comma (`,`), which is used in parameter lists, argument lists, import lists,
  enum declarations, and array and dictionary constructors;

* semicolon (`;`), which is used as an (often optional) terminator for
  statements and declarations.

The following punctuators might be called "pseudo-operators":

* colon (`:`), which is used between a name and its (optional) type in
  declarations, and between the parameter list and the (optional) return type
  in function declarations.

* double arrow (`=>`), used between the key and the value in dictionary
  constructors, and used between a name and the expression of a named
  parameter.

* equality sign (`=`), usually an assignment operator, but used specially as
  a separator between a declared parameter (optionally including type) and its
  (optional) initializer expression.

* question mark (`?`), usually a prefix boolification operator, but used
  specially as a postfix after a declared parameter (before the colon and its
  type declaration, if any) to mark it as optional but without giving it an
  explicit default value.

Although the punctuators in a language normally form a closed set, in Alma this
set can be extended. For more, see [Chapter 17: Extending the
lexer](17-extending-the-lexer.md).

## 1.10 Scannerless parsing

As a matter of language design, the lexer operates independently of the parser
and without receiving any information from it. In practice, this is only true
up to a point.

* The lexer operates on the compilation unit from left to right.

* It emits tokens one after another (in a "lazy" or "streaming" fashion),
  although this detail might not be observable from the outside.

* Whitespace and comments are skipped.

* Given a starting position (assumed to be after any whitespace and comments)
  characters are considered left-to-right, one by one, until a decision can
  be made and the next token is emitted. The lexer works with one character
  of lookahead, meaning that at the time a token is emitted, the lookahead
  character is not part of the emitted token, but it helped in identifying the
  end of the token.

* The lexer will always prefer to emit a longer token to a shorter one. The
  operator `..` trumps the operator `.` if both are an option, because it is
  the longer one. `123abc` is neither a valid integer literal nor a valid
  identifier, but the lexer parse the longest alphanumeric (ish) sequence it
  can find, and only then will it signal an error about a malformed token.

* This longest-token rule is greedy. If the input is `+++` and there are two
  operators `+` and `++` in scope, the lexer will treat this as seeing
  `++` then `+`, not `+` then `++`, or three `+`.


