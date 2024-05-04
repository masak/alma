# Chapter 1: Lexical grammar

## 1.1 File format

An Alma _compilation unit_ is a UTF-8 encoded text string, parsed into a list
of declarations and statements.

A compilation unit is either a single entry-point file ("script"), a module
file, or an input at the interactive prompt. Unless otherwise specified, the
assumption is that the compilation unit is an entry-point file; the exceptions
are described in [Chapter 7: Modules](07-modules.md) and [Chapter 8:
Interactivity](08-interactivity.md).

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

* any of the allowed whitespace characters,
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
this set can be extended. For more, see [Chapter 14: Extending the
lexer](14-extending-the-lexer.md).

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
* `my`
* `next`
* `return`
* `throw`
* `try`
* `while`

Along with the alphabetic literals `none`, `true`, and `false`, the keywords
are _reserved words_: they can not be used as new names in declarations.
However, they can still be used for unscoped literals such as dictionary
keys and object properties.

Although the keywords in a language normally form a closed set, in Alma this
set can be extended. For more, see [Chapter 14: Extending the
lexer](14-extending-the-lexer.md).

## 1.6 Identifiers

An _identifier_ begins with an alphabetic ASCII character or underscore (`_`),
and consists of one or more alphanumeric characters or underscore. Also:

* An identifier is allowed to contain one or more hyphens (`-`), as long as
  each hyphen is neither first nor last in the identifier, and each hyphen
  is followed by an ASCII letter.
* An identifier is allowed to contain one or more apostrophes (`'`), as long
  as each apostrophe is not first in the identifier, and each hyphen either is
  followed by an ASCII letter, or is part of a sequence of one or more
  apostrophes last in the identifier as long as there is still at least one
  other character before.
* Asterisks may appear in an identifier _only_ if one appears first and one
  appears last, but no asterisks appear anywhere else.

The following are examples of valid identifiers by the above rules:

* `apple`
* `_banana42`
* `_`
* `_007`
* `singular-decomposition-matrix`
* `x'`
* `y''`
* `z'''`
* `_'`
* `*earmuffs*`

But these are not valid identifiers:

* `42`
* `'`
* `'''`
* `-`
* `re-'`
* `-ily`
* `*front`
* `back*`
* `mid*dle`

## 1.7 Operators

## 1.8 Delimiters

## 1.9 Separators

## 1.10 Longest token matching

