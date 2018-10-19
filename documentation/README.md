This documentation has four parts:

* The [language guide](#language-guide) describes how to author 007 programs.

> #### 🔮 Future documentation:
>
> * The *macrology section* talks about how to extend and expand the language
>   itself: its syntax, Q hierarchy, and semantics.
>
> * The *API reference* section documents each built-in types, functions and
>   operators in detail.
>
> * Finally, there's a short section about how to contribute to 007.

*This document is still being written. Paragraphs marked 🔮 represent future
features of 007 that are planned but not yet implemented.*

# Language guide

## Getting started

### Installation

Make sure you have [Rakudo Perl 6](https://perl6.org/downloads/) installed and
in your path.

Then, clone the 007 repository. (This step requires Git. There's also [a zip
file](https://github.com/masak/007/archive/master.zip).)

```sh
$ git clone https://github.com/masak/007.git
[...]
```

### Setting an environment variable

We're one step away from running our first 007 program. Before that, we need to
set an environment variable `PERL6LIB`:

```sh
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

```sh
$ bin/007 -e='say("OH HAI")'
OH HAI

$ bin/007 examples/format.007
abracadabra
foo{1}bar
```

## Variables and values

Variables are declared with `my`. You can read out their values in an ordinary
expression, and you can assign to them.

```_007
my name = "James";
say("My name is ", name);      # "My name is James"
name = "Mr. Smith";
say("Now my name is ", name);  # "Now my name is Mr. Smith"
```

> ### 💡 Lexical scope
>
> Variables are *lexically scoped*. You can only use/see the variable in the
> scope it was declared, after it's been declared.
>
> ```_007
> # can't use x
> {
>     # can't use x
>     my x = "yay!";
>     say(x);
>     # can use x \o/
> }
> # can't use x
> ```
>
> You don't even need to run the program to find out if the use of a variable
> is out-of-scope or not. You can just find out from the program text (and so
> can the compiler). We say that variable binding is _static_.

That's all there is to variables; they are meant to be predictable and
straightforward. Later, when writing macros has richer demands on variables,
007's [location protocol](#evaluating-expressions) will allow us to manipulate
variables more finely, controlling exactly when to read and/or assign to them.

In 007, these "scalar value" types are built in:

    None          NoneType
    False         Bool
    42            Int
    "Bond"        Str

And these "container" types:

    [1, 2]        Array
    ("x", "y")    Tuple
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

```_007
func f1() {
}                               # OK
func f2() {};   say("hi!")      # OK
func f3() {}    say("oh noes")  # not ok
```

### Block statements

007 has `if` statements, `while` loops and `for` loops by default. This example
probably won't look too surprising to anyone who has seen C-like syntax before:

```_007
my array = [5, func() { say("OH HAI") }, None];
for array -> e {
    if e ~~ Int {
        while e > 0 {
            say("Counting down: ", e);
            e = e - 1;
        }
    }
    else if e ~~ Func {
        e();
    }
    else {
        say("Unknown value: ", e);
    }
}
```

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

```_007
func add(n1, n2) {
    return n1 + n2;
}

say("3 + 4 = ", add(3, 4));
```

The `return` statement immediately returns out of a function, optionally with a
value. If no value is supplied (as in `return;`), the value `None` is returned.
Implicit returns are OK too; the statement in the `add` function above could
have been written as just `n1 + n2;` because it's last in the function.

When defined using a function statement, it's also allowed to call the function
_before_ its definition. (This is not true for any other type of defined thing
in 007.)

```_007
whoa();     # Amazingly, this works!

func whoa() {
    say("Amazingly, this works!");
}
```

All references to undeclared variables are postponed until CHECK time (after
parsing the program), and an error message about the identifier not being found
is issued _only_ if it hasn't since been declared as a function.

There's also a way to declare functions as terms, and they work just the same:

```_007
my id = func(x) { x };
say(id("OH HAI"));      # OH HAI
```

Note that this form does not have the above advantage of being able to be used
before its definition &mdash; the declaration in this case is a normal lexical
variable.

Unlike in Perl 6 (but like Python), a function call must have the parentheses.
You can write `say(42);` in 007, but not `say 42;` &mdash; the latter is a
parse error and counts as Two Terms In A Row.

### Arguments and parameters

When declaring a function, we talk about function *parameters*. A parameter is
a kind of variable scoped to the function.

```_007
func goodnight(name) {
    say("Goodnight ", name);
}
```

When calling a function, we instead talk about *arguments*. Arguments are
expressions that we pass in with the function call.

    goodnight("moon");

As the function call happens, all the arguments are evaluated, and their
resulting values are *bound* to the parameters. It's a (runtime) error for
the number of arguments to differ from the number of parameters.

> ### 🔮 Future feature: static checking
>
> In the cases where the function definition is known/visible from the
> callsite, we could even give this error at compile time (like Perl 6 but
> unlike Python or Perl 5). Flagging up the error during compilation makes
> sense, since the call would definitely fail at runtime anyway.

> ### 🔮 Future feature: optional parameter and parameter defaults
>
> 007 will at some point incorporate optional parameters and parameter default
> values into the language. It's undecided whether these will require a pragma
> to use or not. The number of arguments can of course go as low as the number
> of non-optional parameters. Non-optional parameters can only occur before
> optional ones.

> ### 🔮 Future feature: rest parameters and spread arguments
>
> The syntax `...` will at some point work to denote a *rest parameter* (which
> accepts any remaining arguments into an array), and a *spread argument*
> (which turns an array of N arguments into N actual arguments). In the
> presence of a rest parameter, the number of arguments accepted is of course
> unbounded.

> ### 🔮 Future feature: named arguments
>
> Borrowing from Python, it will at some point be possible to specify arguments
> *by name*; the above call would for example be written as
> `goodnight(name="moon")`. Whereas normal ("positional") arguments have to be
> written in an order matching the parameters, named arguments can be written
> in any desired order, and will still match their corresponding parameters
> based on the name.
>
> It's as yet unclear whether there will be a rest parameter syntax for named
> arguments (allowing named arguments without a corresponding parameter to be
> slurped up into a dict.)

### Closures

At any point in a running program, the runtime is in a given _environment_,
which is all the declared names and their values that can be looked up from
that point.

If you return a function from a certain environment, the function will
physically leave that environment but still be able to find all its names.

```_007
func goodnight(name) {
    my fn = func() { say("Goodnight ", name) };
    return fn;
}

my names = ["room", "moon", "cow jumping over the moon"];
my fns = names.map(goodnight);      # an array of 3 functions
for fns -> fn {
    fn();       # Goodnight room, Goodnight moon, Goodnight cow jumping over the moon
}
```

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

```_007
say();                          # empty line
say("OH HAI");
say("The answer is: ", answer);
```

For reading input, there's `prompt`:

```_007
my answer = prompt("Rock, paper, or scissors? ");
```

The third important builtin allows you to get the type of a value:

```_007
type(42);           # <type Int>
type("hi");         # <type Str>
type(prompt);       # <type Func>
type(Bool);         # <type Type>
```

The biggest use for the `type` builtin is for printing the type of something
during debugging. If you want to test for the type of a value in a program, you
probably shouldn't test `type(value) == Array` but instead use the
smartmatching operator: `value ~~ Array`.

Technically, all the operators and types available by default in 007 are also
builtins.

## Classes and objects

> ### 🔮 Future feature: classes
>
> The implementation of classes has started behind a feature flag, but mostly,
> classes are not implemented yet in 007.

You can declare classes in 007.

```_007
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
```

As you can see, classes in 007 look like in most other languages. They can have
fields, a constructor, and methods. Fields can optionally have _initializers_,
expressions that evaluate before the constructor runs.

```_007
has red = 0;
```

The special name `self` is automatically available in initializers, the
constructor, and methods.

The annotations `@get` and `@set` can optionally be used to adorn field
declarations. `@get` makes a field accessible from _outside_ an object as a
property, and not just on `self`. `@set` makes a field writable in situations
outside initializers and the constructor. The combination `@get @set` makes the
field writable from the outside.

Classes can inherit, using the `extends` keyword:

```_007
class AlphaColor extends Color {
    has alpha;
}
```

All the public fields and methods from the base class are also available on the
extending class. If a field or method has the same name as in a base class,
then it will _override_ and effectively hide the field or method in the base
class. 007 stops short of having a `super` mechanism to call overridden methods
or constructors.

Class declarations are _slangs_ in 007, so the above desugars to something very
much like this:

```_007
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
```

(Note how `self` has been made an explicit parameter along the way.)

`NoneType`, `Int`, `Str`, `Bool`, `Array`, `Tuple`, `Dict`, `Regex`, `Symbol`,
and `Type` are all built-in types in 007. Besides that, there are all the types
in [the `Q` hierarchy](#the-q-hierarchy), used to reasoning about program
structure. There are also a number of exception types, under the `X` hierarchy.

Here's an example involving a custom `Range` class, which we'll use later to
also declare custom range operators:

```_007
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
```

Note that the name of the inner class is `Range.Iterator`, not `Iterator`. The
same class can also be declared on the outside of the class `Range`: `class
Range.Iterator`. Only if we declare it nested inside `Range` do we skip the
full name.

> ### 🔮 Future feature: generator functions
>
> Using generator functions, we could skip writing the `Range.Iterator` class,
> and write the `iterator` method like this:
>
> ```_007
> method iterator() {
>     return func*() {
>         my currentValue = self.min;
>         while currentValue <= self.max {
>             yield currentValue;
>             currentValue = currentValue + 1;
>         }
>     }
> }
> ```

## Custom operators

007 is built to give the programmer the power to add to and modify the
language, to the point where everything in the language _could_
have been added by the programmer. Macros are the prime example, but custom
operators qualify too. This chapter is the longest in the guide so far; the
reason is that whenever you get into the game of extending the language itself,
you're technically a language designer, and potentially you have to worry about
some things a language designer has to worry about.

Besides the [built-in operators](#operators-and-expressions), you can supply
your own operators. Here, for example, is an implementation of a factorial
operator:

```_007
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
```

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
> ```_007
> func postfix:<!>(N) { [*](2..N) }
> ```

### Built-in operators are built-in functions

Now that the truth is out about user-defined operators being fairly normal
functions, it's time for another bombshell: built-in operators are normal
functions too! These are two equivalent ways to add two numbers in 007:

```_007
3 + 4;              # 7
infix:<+>(3, 4);    # 7
```

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

```_007
func postfix:<!>(N) {
    if N < 2 {
        return 1;
    }
    else {
        return N * (N-1)!;
    }
}
```

> ### 🔮 Future feature: ternary operator
>
> With the ternary operator macro imported, the solution becomes downright cute:
>
> ```_007
> func postfix:<!>(N) { N < 2 ?? 1 !! N * (N-1)! }
> ```

### Infix precedence and associativity

When you define an operator, you can also provide information about its
precedence and associativity. (For an introduction to those concepts, see
[built-in operators](#operators-and-expressions).) Here is an implementation of
a right-associative [cons](https://en.wikipedia.org/wiki/Cons) operator:

```_007
func infix:<::>(lhs, rhs) is tighter(infix:<==>) is assoc("right") {
    return (lhs, rhs);
}
```

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

```_007
func infix:<^_^>(lhs, rhs) is assoc("non") {
}

2 ^_^ 3 ^_^ 4;          # parse error: "operator is nonassociative"
```

### Prefix/postfix precedence and associativity

A postfix and a prefix can share a precedence level, and if it comes down to
one being evaluated first or the other, associativity comes into play. This
pair of operators associates to the left:

```_007
func prefix:<?>(term) is assoc("left") {
    return "prefix:<?>(" ~ term ~ ")";
}

func postfix:<!>(term) is equal(prefix:<?>) is assoc("left") {
    return "postfix:<!>(" ~ term ~ ")";
}

say(?"term"!);       # postfix:<!>(prefix:<?>(term)) (left associativity) (default)
```

While this pair associates to the right:

```_007
func prefix:<¿>(term) is assoc("right") {
    return term ~ " prefix:<?>";
}

func postfix:<¡>(term) is equal(prefix:<?>) is assoc("right") {
    return term ~ " postfix:<¡>";
}

say(¿"term"¡);       # prefix:<¿>(postfix:<¡>(term)) (right associativity)
```

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

```_007
func infix:<..>(lhs, rhs) is looser(infix:<==>) {
    return Range(lhs, rhs);
}

func infix:<..^>(lhs, rhs) is equiv(infix:<..>) {
    return Range(lhs, rhs - 1);
}

func prefix:<^>(expr) {     # overrides the builtin
    return 0 ..^ expr;
}
```

> #### 🔮 Future feature: using custom iterable types in `for` loops
>
> Now we can use ranges in `for` loops:
>
> ```_007
> for 1..10 -> i { say(i) }
> for ^100 { say("I shall never waste chalk again") }
> ```

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
> Modules have not been implemented yet in 007. This whole chapter is a
> best-guess at how they will work.

007 files can be run directly as _scripts_, or they can be imported from other
007 programs as _modules_.

The purpose of modules is to break up a big program into multiple independent
compilation units.

* Each module can completely express a relatively small piece of functionality,
  and is easier to understand and reason about in isolation. (Often referred
  to as _separation of concerns_.)

* Since each module decides exactly what to export to the outside world, a
  module boundary also confers a means of _encapsulation_ and _information
  hiding_. Some aspects of a module can be "public", others private and
  internal.

* The same module can be used in multiple places in a code base, or in several
  different programs. This _re-use_ is often preferable to manually copying
  the same solution into several programs.

### Example: `Range` as a module

Let's say we want to package up our `Range` class, and the custom operators
that help construct ranges, as a module. That way, a user of our module will
just be able to write this in their program:

```_007
import * from range;
```

From that point on for the rest of the block, all the things related to ranges
will be lexically available.

```_007
for 2 .. 7 -> n {   # works because infix:<..> was imported
    say(n);
}
```

If we only wanted the `infix:<..>` operator, we could import only that:

```_007
import { infix:<..> } from range;
```

The `range` module is in fact a `range.007` file in 007's lib path. We'd write
it with the same definition as before, except we also export them:

```_007
export class Range { ... }

export func infix:<..>(lhs, rhs) # ...
export func infix:<..^>(lhs, rhs) # ...
export func prefix:<^>(expr) # ...
```

### Forms of import

There are three forms of the `import` statement.

The *named import* form lists all the names we want to declare in the current
scope:

```_007
import { nameA, nameB, nameC } from some.module;
```

Each name imported counts as a declaration; it's a compile-time error import
and otherwise declare the same name in the same scope.

In the imported module, every export declaration exports a *name*, and together
all the exported names make up the *export list*.

The *star import* form imports the entire export list into the current scope:

```_007
import * from some.module;
```

While this is convenient, it's also the only built-in construct in the language
where *you can't see* from the syntactic form itself what names you're
introducing into the scope.

Finally, the *module object import* creates a module object with all the
names from the export list as properties:

```_007
import m from some.module;
# m now has m.nameA, m.nameB, m.nameC, etc.
```

Imports are *not* hoisted in 007.

```_007
foo();  # won't work
import { foo } from some.module;
```

### Forms of export

You're only allowed to `export` statements on the top level of a module file.

There are two forms of export statement:

The *exported declaration* form is an export plus one of the declaration
statements:

```_007
export my someVar ...;
export func foo(...) ...;
export macro moo(...) ...;
export class SomeClass ...;
```

The declared name is made available in the lexical scope, and put on the export
list.

The *export list* form lists existing names to export:

```_007
export { nameA, nameB, nameC };
```

There can be several of these export statements in a module, but it's
recommended to put one at the end.

### The lib path

If your program contains an import, you need to have an environment variable
`007LIB` set:

```sh
$ export 007LIB=$(pwd)/lib
```

If you want, you can specify several paths, separated by colons. The module
importer will search through all these paths, in order, when a module is
imported. It will import the first one it finds, from left to right.

If no module is found, a compile-time error is reported.

# Macrology

007 is an extensible language. In a trivial sense, this is true of almost any
language; defining a new variable or function introduces a new name into some
environment, thus "extending" the language with the new name.

Custom operators represent a more ambitious form of extension. Not only do they
introduce the operator name into the local scope, they also lexically extend
the _grammar_ in such a way that a new operator is recognized.

007 is a _very_ extensible language. It lets you define the syntax and
semantics not just for operators, but for terms and statements as well.

The overriding goal is for things in the core language, as well as language
extensions, to be _user-definable_.

This extreme in-language definability happens largely through macros. In order
to talk about those, we first need to talk about program elements.

## The Q hierarchy

Every part of your program, from large to small, is represented by an object of
a subtype of the type `Q`. Your entire program is a `Q.CompUnit`; an integer
term (for example) is a `Q.Term.Int`. Together, all these objects form a tree;
an "abstract syntax tree" describing your code.

You can read more about all the Q types in the API section, but what's most
important is that each Q node contains enough property data to describe the
corresponding part of the program text.

## Quasiquotes

Describing a piece of code as nested `Q` objects will always be more cumbersome
and lengthy than just writing the code as code. That's the problem quasi blocks
solve: they allow you to express some code as code.

As an example, here's a statement:

```007
say("Hello, world!");
```

The syntax tree that corresponds to that statement:

```007
my statement = new Q.Statement.Expr {
    expr: new Q.Postfix.Call {
        identifier: new Q.Identifier { name: "postfix:()" },
        operand: new Q.Identifier { name: "say" },
        argumentlist: new Q.ArgumentList {
            arguments: [
                new Q.Literal.Str { value: "Hello, world!" }
            ]
        }
    }
};
```

As you can see, writing out the syntax tree in 007 code is a fair amount of
work, just to describe a single `say` statement.

Maybe this conclusion can be summarized as "it's far shorter to _be_ code than
to _describe_ code".

That's why quasiquotes exist: they help you express code as _code_, not as
syntax trees. But you still get the syntax tree.

```007
my statement = quasi {
    say("Hello, world!");
};
```

The reason they're called "quasiquotes" and not just "quotes" are that besides
expressing fixed code, they also allow injecting interpolated bits of syntax
trees ("unquotes"):

```007
quasi {
    say( {{{expr}}} );
};
```

This is analogous to how template strings allow interpolated expressions.

## Macros

Macros, the central feature of 007, work a lot like functions do. You can call
a macro just like you can call a function.

The main way they differ is that _functions are invoked at runtime_, whereas
_macro calls are expanded at compile time_.

Of course, the main consequence of this is that functions accept and return
normal runtime values, whereas macros accept and return syntax tree fragments.

Because macros return syntax tree fragments, quasiquotes are a really good fit.
Typically, a macro ends with `return quasi { ... };`.

XXX give two examples: prefix:<exists> and swap, perhaps?

## Stateful macros

XXX hidden variables using Symbols

## Closures in macros

XXX go through how name lookup works in general

XXX Dylan quote about "the meaning of names"

XXX macro hygiene

## Macros that parse

XXX introduce the `@parsed` annotation

XXX there must be dozens of good examples here... `?? !!`, `[*]` --
just need to find a decent explanation order that will introduce
things bit by bit

## Statement macros

XXX these are macros in the statement category. important because we often want
to introduce new statement types

XXX examples: `loop {}`, `repeat while` loop, `for` loop

## Grammatical categories

XXX go through them all, with examples

## Contextual macros

XXX examples: `each()`, junctions, class declarations

## Evaluating expressions

XXX example: `+=`, `.=`

XXX important here to state the single evaluation rule

XXX location protocol

## Interacting with control flow

XXX example: `if` and `while`

XXX example: `next` and `last`

XXX example: `<-` (`amb`)

## Parsers and slangs

# API reference

## Built-in types

## Built-in functions

## Built-in operators

# How to contribute to 007
