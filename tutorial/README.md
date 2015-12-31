## Overview

> **Q**: Good to see you Mr Bond, things have been awfully dull around
> here...Now you're on this, I hope we're going to have some gratuitous
> sex and violence!  
> **James Bond**: I certainly hope so too.

007 is a small language. It has been designed with the purpose of
exploring ASTs, macros, the compiler-runtime barrier, and program
structure introspection.

In terms of language features, it's perhaps easiest to think of 007 as
the secret love child of Perl 6 and Python.

| feature                  | Perl 6   | 007   | Python   |
| ------------------------ | -------- | ----- | -------- |
| braces                   | yes      | yes   | no       |
| user-defined operators   | yes      | yes   | no       |
| variable declarations    | yes      | yes   | no       |
| macros                   | yes      | yes   | no       |
| implicit typecasts       | yes      | no    | no       |
| sigils                   | yes      | no    | no       |
| multis                   | yes      | no    | no       |
| implicit returns         | yes      | no    | no       |

## Values

A small number of values in 007 can be expressed using literal syntax.

    123                 Q::Literal::Int
    "Bond."             Q::Literal::Str
    None                Q::Literal::None
    [0, 0, 7]           Q::Term::Array
    { name: "Bond" }    Q::Term::Object

Only double quotes are allowed. Strings don't have any form of
interpolation.

The `None` value is a singleton. It's the value of unassigned variables
and subroutines that don't `return` anything.

## Expressions

> **James Bond**: A gun and a radio. It's not exactly Christmas, is it?  
> **Q**: Were you expecting an exploding pen? We don't really go in for
> that anymore.

You can add integers together, and negate them.

    40 + 2              Q::Infix::Addition
    -42                 Q::Prefix::Minus

Strings can be concatenated.

    "Bo" ~ "nd."        Q::Infix::Concat

Arrays can be indexed. (Strings can't, but there's a builtin for that.)

    ar[3]               Q::Postfix::Index

There's an assignment operator, and a comparison operator. These work on
all types.

    name = "Bond"       Q::Infix::Assignment
    42 == 40 + 2        Q::Infix::Eq

There is no boolean type; comparison yields `1` and `0`. Comparison is
strict, in the sense that `7` and `"7"` are not considered equal under
`==`, and an array is never equal to an int, not even the length of the
array.

The only thing that can be assigned to is variables. Arrays are
immutable values, and you can't assign to `ar[3]`, for example.

    ar[3] = "hammer";   # error; can't touch this

Operands don't need to be simple values. Arbitrarily large expressions
can be built. Parentheses can be used to explicitly show evaluation
order.

    10 + -(2 + int("3" ~ "4"))

## Variables

In order to be able to read and write a variable, you must first declare
it.

    my name;            Q::Statement::My

As part of the declaration, you can also do an assignment.

    my name = "Bond";

Variables are only visible for the rest of the scope they are declared
in. All scopes are delimited by braces, except for the scope delimiting
the whole program.

    {
        my drink = "Dry Martini";
        say(drink);     # works
    }
    say(drink);         # fails, no longer visible

It's fine for a variable in an inner scope to have the same name as one
in an outer scope. The inner variable will then "shadow" the outer until
it's no longer visible.

    my x = 1;
    {
        my x = 2;
        say(x);         # 2
    }
    say(x);             # 1

## Statements

> **Q**: It is to be handled with special care!  
> **Bond**: Everything you give me...  
> **Q**: ...is treated with equal contempt. Yes, I know.

We've seen two types of statement already: variable declarations, and
expression statements.

    my name = "Bond";   Q::Statement::My
    say(2 + 2);         Q::Statement::Expr

Expression statements are generally used for their side effects, so they
tend to either call some routine or assign to some variable. However,
this is not a requirement, and an expression statement can contain any
valid expression.

Besides these simple statements, there are also a few compound
statements for conditionals and loops.

    if 2 + 2 == 4 {}    Q::Statement::If
    for xs -> x {}      Q::Statement::For
    while agent {}      Q::Statement::While

There is also an immediate block statement. Immediate blocks run
unconditionally, as if they were an `if 1 {}` statement.

    { say("hi") }       Q::Statement::Block

## Subroutines

Subroutines are similar to blocks, but they are declared with a name and
a (non-optional) parameter list.

    sub f(x) {}         Q::Statement::Sub

When calling a subroutine, the number of arguments must equal the number
of parameters.

The parentheses in the call are mandatory. There is no `g "Mr. Bond";`
listop form.

Subroutines can return values.

    return 42;          Q::Statement::Return

A return statement finds the lexically surrounding subroutine, and
returns from it. Blocks are transparent to this process; a `return`
simply doesn't see blocks.

    sub outer() {
        my inner = {
            return 42;
        }
        inner();
        say("not printed");
    }
    say(outer());

## `BEGIN` and constants

`BEGIN` blocks are blocks of code that run as soon as the parser has
parsed the ending brace (`}`) of the block.

    BEGIN {}            Q::Statement::BEGIN

There is no statement form of `BEGIN`: you must put in the braces.

There's also a `constant` declaration statement:

    constant pi = 3;    Q::Statement::Constant

The right-hand side of the `constant` declaration is evaluated at parse
time, making it functionally similar to using a BEGIN block to do the
assignment:

    my pi;
    BEGIN {
        pi = 3;
    }

Constants cannot be assigned to after their declaration. Because of
this, the assignment in the `constant` declaration is mandatory.

## Setting

There's a scope outside the program scope, containing a utility
subroutines. These should be fairly self-explanatory.

    say(any)
    type(any)
    str(any)
    int(any)

    abs(int)
    min(a, b)
    max(a, b)
    chr(int)

    ord(char)
    chars(str)
    uc(str)
    lc(str)
    trim(str)
    split(str, sep)
    index(str, substr)
    charat(str, pos)
    substr(str, pos, chars?)

    elems(array)
    reversed(array)
    sorted(array)
    join(array, sep)
    filter(fn, array)
    map(fn, array)

## Objects

Object terms are delimited by braces, and contain property declarations
separated by commas:

    { name: "Bond", agency: "MI6" }

Property keys can be quoted, for example when they aren't simple identifiers:

    { "no, Mr Bond": "I expect you to die" }

There's also syntactic sugar for defining properties with function values,
making these two forms more or less equivalent:

    { quip() { say("I'd say one of their aircraft is missing") } }

    sub quip() { say("I'd say one of their aircraft is missing") }
    { quip: quip }

## Q objects

All the different Q types can be created by specifying the type before an
object term:

    my q = Q::Statement::My {
        identifier: Q::Identifier { name: "name" },
        expr: Q::Literal::Str { value: "Bond" }
    };

## Macros

> **Q**: Now, look...  
> **Bond**: So where is this cutting edge stuff?  
> **Q**: I'm trying to get to it!

Macros are a form of routine, just like subs.

    macro m(q) {}       Q::Statement::Macro

When a call to a macro is seen in the source code, the compiler will
call the macro, and then install whatever code the macro said to return.

    macro greet() {
        return Q::Postfix::Call {
            expr: Q::Identifier { name: "say" },
            argumentlist: Q::ArgumentList {
                [Q::Literal::Str { value: "Mr Bond!" }]
            }
        };
    }

    greet();    # prints "Mr Bond!" when run

## Quasis

> **Q**: Right. Now pay attention, 007. I want you to take great care of
> this equipment. There are one or two rather special accessories...  
> **James Bond**: Q, have I ever let you down?  
> **Q**: Frequently.

It's sometimes convenient to express code as Qtree constructors, like
above, and sometimes convenient to express it as code. Quasis are for
the latter case.

    macro greet() {
        return quasi {
            say("Mr Bond!");
        }
    }

    greet();

Quasis can contain *unquotes*, where we momentarily jump back from
code to Qtrees. Mixing code and Qtrees like that is the main point of
quasis. For instance, instead of specifying the string directly as
above, we can construct the Q node for it, and inject it:

    constant greeting_ast = Q::Literal::Str { value: "Mr Bond!" };

    macro greet() {
        return quasi {
            say({{{greeting_ast}}});
        }
    }

    greet();

Note the need for `constant` in the mainline, because the macro
`greet` runs very early. If we moved `greeting_ast` into the macro
body, we could use `my`.
