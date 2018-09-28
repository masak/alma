This document is still being written. Paragraphs marked 🔮 represent future
features of 007 that are planned but not yet implemented.

# Language guide

## Getting started

### Installation

Make sure you have [Rakudo Perl 6](https://perl6.org/downloads/) installed and
in your path.

Then, clone the 007 repository. (This step requires Git. There's also [a zip
file](https://github.com/masak/007/archive/master.zip).)

```
$ git clone https://github.com/masak/007.git
[...]
```

### Setting an environment variable

We're one step away from running our first 007 program. Before that, we need to
set an environment variable `PERL6LIB`:

```
$ cd 007
$ export PERL6LIB=$(pwd)/lib
```

> #### 💡 `PERL6LIB`
>
> `PERL6LIB` is used to tell Rakudo Perl 6 which paths to look in whenever it
> sees a `use` module import in a program. Since `bin/007` imports some
> 007-specific modules, which in turn import other modules, we need to set this
> environment variable.

### Running 007

Now this should work:

```
$ bin/007 -e='say("OH HAI")'
OH HAI

$ bin/007 examples/format.007
abracadabra
foo{1}bar
```

## Variables and values

Variables are declared with `my`. You can read out their values in an ordinary
expression, and you can assign to them.

    my name = "James";
    say("My name is ", name);      # "My name is James"
    name = "Mr. Smith";
    say("Now my name is ", name);  # "Now my name is Mr. Smith"

> ### 💡 Lexical scope
>
> Variables are *lexically scoped*. You can only use/see the variable in the
> scope it was declared, after it's been declared.
>
>     # can't use x
>     {
>         # can't use x
>         my x = "yay!";
>         say(x);
>         # can use x \o/
>     }
>     # can't use x
>
> You don't even need to run the program to find out if the use of a variable
> is out-of-scope or not. You can just find out from the program text (and so
> can the compiler). We say that variable binding is _static_.

That's all there is to variables; they are meant to be predictable and
straightforward. Later, when writing macros has richer demands on variables,
007's [location protocol](#evaluating-expressions) will allow us to manipulate
variables more finely, controlling exactly when to read and/or assign to them.

In 007, these "scalar value" types are built in:

    None        NoneType
    False       Bool
    42          Int
    "Bond"      Str

And these "container" types:

    [1, 2]      Array
    ("x", "y")  Tuple
    { "n": 42 }   Dict

## Operators and expressions

Gramatically, a 007 expression always looks like this:

    expr := <termish> +% <infix>
    termish := <prefix>* <term> <postfix>*

Unpacking what this means, a term may be preceded by prefix operators, and
succeeded by postfix operators. (The combination of prefixes-term-postfixes is
referred to as a _termish_.) Several termishes can occur in a row, separated by
infix operators.

You can have whitespace before or after terms and operators, and it largely
doesn't change the meaning of the program. The recommended style is to use
whitespace around infixes, but not after prefixes or before postfixes.

007 has 28 built-in operators. Here we describe them by group. (These are just
short descriptions. For more detail, see each individual operator in the API
docs.)

**Assignment**. The `x = 42` expression assigns the value `42` to the variable
`x`.

**Arithmetic**. The infix operators `+ - * %` work as you'd expect. `%%` tests
for divisibility, so it returns `True` whenever `%` returns `0`. `divmod` does
an integer division resulting in a tuple `(q, r)` where `q` is the quotient and
`r` is the reminder.

**String building**. You can concatenate strings with `~`. (To concatenate
arrays, use the Array method `.concat`.)

**Equality, comparison and matching**. The operators `==` and `!=` checks
whether values are equal or unequal. `< <= > >=` compare ordered types like
integers or strings. `~~ !~~` match a value against a type.

**Logical connectives**. The infixes `||` and `&&` allow you to combine boolean
(or really, any) values. Furthermore, `//` allows you to replace `None` values
with a default. (All of these operators are short-circuiting. See the
individual operators for more information.)

**Postfixes**. The postfixes are `[]` for indexing, `()` for calls, and `.` for
property lookup.

**Conversion prefixes**. The prefixes `+ -` convert to integers, `~` converts
to a string, and `? !` convert to booleans. The prefix `^` turns an integer `n`
into an array `[0, 1, 2, .., n - 1]`.

Each operator has a built-in precedence which governs the order in which the
operators are evaluated. This can be more clearly seen by pretending that the
parser groups subexpressions by inserting parentheses around the tighter
operators:

    1 + 2 * 3         becomes         1 + (2 * 3)
    1 * 2 + 3         becomes         (1 * 2) + 3
    x || y && z       becomes         x || (y && z)
    x && y || z       becomes         (x && y) || z

In general, the precedence of an operator is set so as to minimize the use for
explicit parentheses. For example, `*` binds tighter than `+` because in
mathematical expressions terms conventionally consist of one or more factors.

The built-in operators are grouped into precedence levels as follows &mdash;
tightest operators at the top, loosest at the bottom.

| Precedence level     | Assoc | Category | Operators |
|----------------------|-------|----------|-----------|
| (tightest)           | left  | postfix  | `[] () .` |
|                      | left  | prefix   | `+ - ~ ? ! ^` |
| Multiplicative       | left  | infix    | `* % %% divmod` |
| Additive             | left  | infix    | `+ - ~` |
| Comparison           | left  | infix    | `== != < <= > >= ~~ !~~` |
| Conjuctive           | left  | infix    | `&&` |
| Disjunctive          | left  | infix    | `\|\| //` |
| Assignment (loosest) | right | infix    | `=` |

007's precedence rules are a bit simpler than Perl 6's. In 007, the prefixes
and postfixes _have_ to bind tighter than the infixes.

The table also shows the associativity of the different precedence levels.
(Also unlike Perl 6, associativity belongs to the precedence _level_, not to
individual operators.) Associativity makes sure to (conceptually) insert
parentheses in a certain way for operators on the same level:

    1 + 2 - 3 + 4          becomes        ((1 + 2) - 3) + 4    (associating to the left)
    x || y // z            becomes        (x || y) // z        (associating to the left)
    a = b = c = 0          becomes        a = (b = (c = 0))    (associating to the right)

Besides the built-in operators, you can also extend the 007 grammar by writing
your own [custom operators](#custom-operators).

## Control flow

### Sequencing

_Sequencing_ happens just by writing statements after each other.

A statement can be terminated by a semicolon (`;`). The semicolon is mandatory
when you have other statements coming after it, regardless of the statements
being on the same line or separated by a newline character. When a statement
ends in a closing curly brace (`}`), you can omit the semicolon as long as you
have a newline character instead.

    func f1() {
    }                               # OK
    func f2() {};   say("hi!")      # OK
    func f3() {}    say("oh noes")  # not ok

### Block statements

007 has `if` statements, `while` loops and `for` loops by default. This example
probably won't look too surprising to anyone who has seen C-like syntax before:

    my array = [5, func() { say("OH HAI") }, None];
    for array -> e {
        if e ~~ Int {
            while e > 0 {
                say("Counting down: " ~ e);
                e = e - 1;
            }
        }
        else if e ~~ Func {
            e();
        }
        else {
            say("Unknown value: " ~ e);
        }
    }

The normal block statements all require blocks with curly braces (`{}`) &mdash;
there's no blockless form. Unlike C/Java/JavaScript/C# but like Python,
parentheses (`()`) are optional around expressions after `if`, `for` and
`while`.

The `if` and `while` statements evaluate their expression and runs their block
if the resulting value is `True`, possibly after coercing to `Bool`. (We
sometimes refer to a value that is `True` when coerced to `Bool` as _truthy_,
and the other values as _falsy_.) Several other mechanisms in 007, such as `&&`
and the `.filter` method, accept these "generalized `Bool` values".

The optional `-> e` syntax is a _block parameter_, and is a way to pass each
element as a lexical variable into the block. Although the most natural fit is
a `for` loop, it also works consistently for `while` loops and `if` statements
(including the `else if` and `else` blocks). All these blocks accept at most
one parameter.

### Exceptional control flow

> #### 🔮 Future feature: `next` and `last`
>
> Inside a loop of any kind, it's possible to write a `next` statement to
> transfer immediately to the next iteration, or a `last` statement to
> terminate the loop immediately.

In the next section we'll see `return` breaking out of a function or macro.

There's also `throw` statement.

### Custom statement types

007 allows you to add new statement forms for control flow if you want to
&mdash; the three statements above are very common but don't form a closed set.
For more information on how to do this, see the section [interacting with
control flow](#control-flow).

## Functions

Functions take parameters, can be called, and return a value. Definitions and
calls look like this:

    func add(n1, n2) {
        return n1 + n2;
    }

    say("3 + 4 = ", add(3, 4));

The `return` statement immediately returns out of a function, optionally with a
value. If no value is supplied (as in `return;`), the value `None` is returned.
Implicit returns are OK too; the statement in the `add` function above could
have been written as just `n1 + n2;` because it's last in the function.

When defined using a function statement, it's also allowed to call the function
_before_ its definition. (This is not true for any other type of defined thing
in 007.)

    whoa();     # Amazingly, this works!

    func whoa() {
        say("Amazingly, this works!");
    }

All references to undeclared variables are postponed until CHECK time (after
parsing the program), and an error message about the identifier not being found
is issued _only_ if it hasn't since been declared as a function.

There's also a way to declare functions as terms, and they work just the same:

    my id = func(x) { x };
    say(id("OH HAI"));      # OH HAI

Note that this form does not have the above advantage of being able to be used
before its definition &mdash; the declaration in this case is a normal lexical
variable.

Unlike in Perl 6 (but like Python), a function call must have the parentheses.
You can write `say(42);` in 007, but not `say 42;` &mdash; the latter is a
parse error and counts as Two Terms In A Row.

### Arguments and parameters

XXX

### Closures

At any point in a running program, the runtime is in a given _environment_,
which is all the declared names and their values that can be looked up from
that point.

If you return a function from a certain environment, the function will
physically leave that environment but still be able to find all its names.

    func goodnight(name) {
        my fn = func() { say("Goodnight " ~ name) };
        return fn;
    }

    my names = ["room", "moon", "cow jumping over the moon"];
    my fns = names.map(goodnight);      # an array of 3 functions
    for fns -> fn {
        fn();       # Goodnight room, Goodnight moon, Goodnight cow jumping over the moon
    }

This effect is referred to as the functions "closing over" their current
environment. In the case above, the 3 function values in `fns` close over the
`name` parameter. Such functions are often referred to as _closures_. If we
were to look at a snapshot of memory at that point, we would see three
different `fn` function values, each one holding onto a `name` variable with a
different string value in it.

Technically it's extremely easy for a function to be a closure, since both
built-in functions like `say` and (as we will see) built-in operators like `~`
come from the lexical environment. In practice the term is reserved to the
narrower use of closing over a relatively local variable (like `name`).

A function closing over some variable is similar in spirit to an object having
a private property. In fact, from a certain point of view [closures and objects
are equivalent](http://wiki.c2.com/?ClosuresAndObjectsAreEquivalent).

## Builtins

_Builtins_ are functions that are available by default in the language, without
the need to import them.

By far the most common builtin is `say`, a function for printing things.

    say();                          # empty line
    say("OH HAI");
    say("The answer is: ", answer);

For reading input, there's `prompt`:

    my answer = prompt("Rock, paper, or scissors? ");

The third important builtin allows you to get the type of a value:

    type(42);           # <type Int>
    type("hi");         # <type Str>
    type(prompt);       # <type Func>
    type(Bool);         # <type Type>

The biggest use for the `type` builtin is for printing the type of something
during debugging. If you want to test for the type of a value in a program, you
probably shouldn't test `type(value) == Array` but instead use the
smartmatching operator: `value ~~ Array`.

Technically, all the operators and types available by default in 007 are also
builtins.

## Classes and objects

> ### 🔮 Future feature: classes
> This whole chapter is conjectural right now.

You can declare classes in 007.

    class Color {
        has red;
        has green;
        has blue;

        constructor(red, green, blue) {
            self.red = red;
            self.green = green;
            self.blue = blue;
        }

        method show() {
            format("rgb({}, {}, {})", self.red, self.green, self.blue);
        }
    }

As you can see, classes in 007 look like in most other languages. They can have
fields, a constructor, and methods. Fields can optionally have _initializers_,
expressions that evaluate before the constructor runs.

    has red = 0;

The special name `self` is automatically available in initializers, the
constructor, and methods.

The annotations `@get` and `@set` can optionally be used to adorn field
declarations. `@get` makes a field accessible from _outside_ an object as a
property, and not just on `self`. `@set` makes a field writable in situations
outside initializers and the constructor. The combination `@get @set` makes the
field writable from the outside.

Classes can inherit, using the `extends` keyword:

    class AlphaColor extends Color {
        has alpha;
    }

All the public fields and methods from the base class are also available on the
extending class. If a field or method has the same name as in a base class,
then it will _override_ and effectively hide the field or method in the base
class. 007 stops short of having a `super` mechanism to call overridden methods
or constructors.

Class declarations are _slangs_ in 007, so the above desugars to something very
much like this:

    BEGIN my Color = Type(
        name: "Color",
        fields: [{ name: "red" }, { name: "green" }, { name: "blue" }],
        constructor: func(self, red, green, blue) { ... },
        methods: {
            show(self) { ... },
        },
    );

    BEGIN my AlphaColor = Type(
        name: "AlphaColor",
        extends: Color,
        fields: [{ name: "alpha" }],
    );

(Note how `self` has been made an explicit parameter along the way.)

`NoneType`, `Int`, `Str`, `Bool`, `Array`, `Tuple`, `Dict`, `Regex`, `Symbol`,
and `Type` are all built-in types in 007. Besides that, there are all the types
in [the `Q` hierarchy](#the-q-hierarchy), used to reasoning about program
structure. There are also a number of exception types, under the `X` hierarchy.

Here's an example involving a custom `Range` class, which we'll use later to
also declare custom range operators:

    class Range {
        @get has min;
        @get has max;

        constructor(min, max) {
            self.min = min;
            self.max = max;
        }

        method iterator() {
            return Range.Iterator(self);
        }

        class Iterator {
            has range;
            @set has currentValue;

            constructor(range) {
                self.range = range;
                self.currentValue = range.min;
            }

            method next() {
                if self.currentValue > self.range.max {
                    throw StopIteration();
                }
                my value = self.currentValue;
                self.currentValue = self.currentValue + 1;
                return value;
            }
        }
    }

Note that the name of the inner class is `Range.Iterator`, not `Iterator`. The
same class can also be declared on the outside of the class `Range`: `class
Range.Iterator`. Only if we declare it nested inside `Range` do we skip the
full name.

## Custom operators

007 is built to give the programmer the power to add to and modify the
language, to the point where everything that's already _in_ the language could
have been added by the programmer. Macros are the prime example, but custom
operators qualify too. This chapter is the longest in the guide so far; the
reason is that whenever you get into the game of extending the language itself,
you're technically a language designer, and potentially you have to worry about
some things a language designer has to worry about.

Besides the [built-in operators](#operators-and-expressions), you can supply
your own operators. Here, for example, is an implementation of a factorial
operator:

    func postfix:<!>(N) {
        my product = 1;
        my n = 2;
        while n <= N {
            product = product * n;
            n = n + 1;
        }
        return product;
    }

    say(5!);                # 120
    say(postfix:<!>(5));    # 120

Operators are special in that they install themselves both as specially named
functions, but also as _syntax_ &mdash; writing `5!` in a 007 program doesn't
work normally, but it does after you've defined `postfix:<!>`.

Just like with ordinary identifiers, they go out of scope at the end of the
block where they were defined. Like with other functions, you can call them
before their definition, but you can _not_ use the operator syntax before the
definition (because the parser only does one pass, and adds the operator when
it's defined).

> #### 🔮 Future feature: reduction metaoperator
>
> Using the reduction metaoperator and a range operator, we can implement
> `postfix:<!>` much shorter:
>
>     func postfix:<!>(N) { [*](2..N) }

### Built-in operators are built-in functions

Now that the truth is out about user-defined operators being fairly normal
functions, it's time for another bombshell: built-in operators are normal
functions too! These are two equivalent ways to add two numbers in 007:

    3 + 4;              # 7
    infix:<+>(3, 4);    # 7

The function `infix:<+>` is defined among the built-ins, together with `say`
and some other functions.

### Operator categories

The thing before the colon is called a _category_. For 007 operators, there are
three categories:

    prefix:<!>            !x
    infix:<!>           x ! y
    postfix:<!>          x!

(There are also other categories for non-operator things.)

Prefix and postfix operators are defined as _unary_ functions taking one
parameter. Infix operators are defined as _binary_ functions taking two
parameters.

Since we'll be defining a number of operators, it might be good to know that
`lhs` and `rhs` are common parameter neames to infix operators. They stand for
"left-hand side" and "right-hand side", respectively. There's no corresponding
established naming convention for prefix and postfix operators.

### Recursion

It's possible for operator functions to be recursive, so we can actually write
the factorial in a slightly shorter way:

    func postfix:<!>(N) {
        if N < 2 {
            return 1;
        }
        else {
            return N * (N-1)!;
        }
    }

> ### 🔮 Future feature: ternary operator
>
> With the ternary operator macro imported, the solution becomes downright cute:
>
>     func postfix:<!>(N) { N < 2 ?? 1 !! N * (N-1)! }

### Infix precedence and associativity

When you define an operator, you can also provide information about its
precedence and associativity. (For an introduction to those concepts, see
[built-in operators](#operators-and-expressions).) Here is an implementation of
a right-associative cons operator:

    func infix:<::>(lhs, rhs) is tighter(infix:<==>) is assoc("right") {
        return (lhs, rhs);
    }

The traits `is looser(op)` and `is tighter(op)` both create a new precedence
level, just next to the one of the specified operator. The trait `is equal(op)`
adds to the precedence level of an existing operator. If you don't specify
either of these, your newly defined operator will be on its own maximally tight
precedence level. (This is what happened with `postfix:<!>` above.)

The `is assoc` trait has the allowed values `"left"`, `"right"`, and `"non"`.
The `"left"` and `"right"` values determine how the syntax tree will group
things when several operators of the exact same precedence follow one another:

    x ! y ! z               (x ! y) ! z         left associativity
    x ! y ! z               x ! (y ! z)         right associativity

With the `"non"` value, it's illegal for two operators on the same level to
occur next to each other without being parenthesized. Here is an example:

    func infix:<^_^>(lhs, rhs) is assoc("non") {
    }

    2 ^_^ 3 ^_^ 4;          # parse error: "operator is nonassociative"

### Prefix/postfix precedence and associativity

A postfix and a prefix can share a precedence level, and if it comes down to
one being evaluated first or the other, associativity comes into play. This
pair of operators associates to the left:

    func prefix:<?>(term) is assoc("left") {
        return "prefix:<?>(" ~ term ~ ")";
    }

    func postfix:<!>(term) is equal(prefix:<?>) is assoc("left") {
        return "postfix:<!>(" ~ term ~ ")";
    }

    say(?"term"!);       # postfix:<!>(prefix:<?>(term)) (left associativity) (default)

While this pair associates to the right:

    func prefix:<¿>(term) is assoc("right") {
        return term ~ " prefix:<?>";
    }

    func postfix:<¡>(term) is equal(prefix:<?>) is assoc("right") {
        return term ~ " postfix:<¡>";
    }

    say(¿"term"¡);       # prefix:<¿>(postfix:<¡>(term)) (right associativity)

Because `"left"` is the default associativity, both specifiers in the former
example are unnecessary. The associativity for `postfix:<¡>` also doesn't need
to be specified explicitly, since it was already specified for `prefix:<¿>` and
all operators on a precedence level share the same associativity.

### Default precedence

If you don't specify a precedence for your operator, it will get the tightest
precedence for its category. For example, a new infix operator without a
precedence specifier will get its own precedence level tighter than `infix:<+>`
and friends. Further infix operators will get even tighter precedence levels.

A small exception happens for prefixes and postfixes: while you _can_ make
these have any relative precedence, the convention is that postfixes be tigher
and prefixes be looser. (This is true for [the precedence
table](#expressions-and-operators) of the built-in operators: postfix at the
top, then prefix, then infix.) 007 tries to respect this convention by default;
instead of making a new custom prefix maximally tight by default, it only makes
it tighter than all other prefixes, but looser than all other postfixes.

Infixes form precedence levels of their own, apart from the prefixes and
postfixes. Trying to relate the precedence of a prefix or postfix to that of an
infix, or vice versa, leads to a compile-time error.

### An example: `Range`

We can define operators that construct `Range` objects, using the class we
defined earlier:

    func infix:<..>(lhs, rhs) is looser(infix:<==>) {
        return Range(lhs, rhs);
    }

    func infix:<..^>(min, max1) is equiv(infix:<..>) {
    }

    func prefix:<^>(term) {     # overrides the builtin
        return 0 ..^ term;
    }

> #### 🔮 Future feature: using custom iterable types in `for` loops
>
> Now we can use ranges in `for` loops:
>
>     for 1..10 -> i { say(i) }
>     for ^100 { say("I shall never waste chalk again") }

### Parsing concerns

In `infix:<+>`, the angle bracket symbols are a quoting construct to delimit
the symbol of interest; the actual _internal_ name is `infix:+`, but during
parsing and stringification, it will always show up as `infix:<+>`.

If your operator symbol contains `>`, then you can use a backslash to escape
the symbol: `infix:<\>>`. Another way to avoid ambiguity is to use different
angle brackets: `infix:«>»`. (This is 007's default when it stringifies.)

If two or more operators could all match a given piece of text, then the rule
is that the _longest_ operator wins. This is regardless of the order in which
they were defined, and regardless of their category.

    3 +++ 4     # is there an infix:<+++>? then it wins
                # or maybe an postfix:<++> and an infix:<+>; then they win
                  # ...EVEN if there were an infix:<+> and a prefix:<++>, since infix:<++> is longer
                # or maybe an infix:<+>, a prefix:<+>, and another prefix:<+>
                  # (these are all built-in operators, so that's what happens by default)

Whitespace does not enter into consideration when the parser tries to determine
whether something is an infix, prefix, or postfix. At least in this regard, 007
is whitespace-agnostic.

Given the above, if an infix and a postfix are defined with the exact same
symbol, they _would_ clash as soon as they were parsed. For this reason, if you
try to install a postfix with the same symbol as an already installed infix, or
vice versa, the compiler will give you an error. You'll get an error regardless
of whether the already installed operator is a built-in or user-defined.

## Modules

> ### 🔮 Future feature: modules
>
> This whole chapter is conjectural right now.

Programs in 007 can be run directly as _scripts_, or they can be imported from
other 007 programs as _modules_.

### Example: `Range` as a module

Let's say we want to package up our `Range` class, and the custom operators
that help construct ranges, as a module. That way, a user of our module will
just be able to write this in their program:

    import * from range;

From that point on for the rest of the program (or the rest of the scope if the
import was made in a smaller block somewhere), all the things related to ranges
will be lexically available.

XXX

# Macrology

## The Q hierarchy

## Quasi blocks

Describing a piece of code as nested `Q` objects will always be more cumbersome
and lengthy than just writing the code as code. That's the problem quasi blocks
solve: they allow you to express some code as code.

XXX

## Macros

## Stateful macros

XXX hidden variables using Symbols

## Closures in macros

## Macros that parse

## Statement macros

## Contextual macros

## Evaluating expressions

## Interacting with control flow

## Parsers and slangs

# API reference

## Built-in types

## Built-in functions

## Built-in operators

# How to contribute to 007
