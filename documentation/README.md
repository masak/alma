This documentation has four parts:

* The [language guide](#language-guide) describes how to author Alma programs.

> #### 🔮 Future documentation:
>
> * The *macrology section* talks about how to extend and expand the language
>   itself: its syntax, Q hierarchy, and semantics.
>
> * The *API reference* section documents each built-in types, functions and
>   operators in detail.
>
> * Finally, there's a short section about how to contribute to Alma.

*This document is still being written. Paragraphs marked 🔮 represent future
features of Alma that are planned but not yet implemented.*

# Language guide

## Getting started

### Installation (with zef)

If you're just planning to be an Alma end user, `zef` is the recommended way to
install Alma:

```sh
zef install alma
```

In order to get the `zef` installer, you first need [Rakudo](https://raku.org/downloads). Instructions for how to install `zef` itself
can be found in the [`zef` README](https://github.com/ugexe/zef#installation).

> #### 💡 Using `zef`
>
> At any later point, you can use `zef upgrade` to get an up-to-date Alma, or
> `zef uninstall` to remove Alma from your system.

### Installation (from source)

Make sure you have [Rakudo](https://raku.org/downloads) installed and
in your path.

Then, clone the Alma repository. (This step requires Git. There's also [a zip
file](https://github.com/masak/alma/archive/master.zip).)

```sh
$ git clone https://github.com/masak/alma.git
[...]
```

Finally, we need to set an environment variable `PERL6LIB`:

```sh
$ cd alma
$ export PERL6LIB=$(pwd)/lib
```

> #### 💡 `PERL6LIB`
>
> `PERL6LIB` is used to tell Rakudo Raku which paths to look in whenever it
> sees a `use` module import in a program. Since `bin/alma` imports some
> Alma-specific modules, which in turn import other modules, we need to set this
> environment variable.

### Running Alma

Now this should work:

```sh
$ bin/alma -e='say("OH HAI")'
OH HAI

$ bin/alma examples/format.alma
abracadabra
foo{1}bar
```

## Variables and values

Variables are declared with `my`. You can read out their values in an ordinary
expression, and you can assign to them.

```alma
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
> ```alma
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
Alma's [location protocol](#evaluating-expressions) will allow us to manipulate
variables more finely, controlling exactly when to read and/or assign to them.

In Alma, these "scalar value" types are built in:

    none          None
    false         Bool
    42            Int
    "Bond"        Str

And these "container" types:

    [1, 2]        Array
    { "n": 42 }   Dict

## Operators and expressions

Gramatically, an Alma expression always looks like this:

    expr := <termish> +% <infix>
    termish := <prefix>* <term> <postfix>*

Unpacking what this means, a term may be preceded by prefix operators, and
succeeded by postfix operators. (The combination of prefixes-term-postfixes is
referred to as a _termish_.) Several termishes can occur in a row, separated by
infix operators.

You can have whitespace before or after terms and operators, and it largely
doesn't change the meaning of the program. The recommended style is to use
whitespace around infixes, but not after prefixes or before postfixes.

Alma has 28 built-in operators. Here we describe them by group. (These are just
short descriptions. For more detail, see each individual operator in the API
docs.)

**Assignment**. The `x = 42` expression assigns the value `42` to the variable
`x`.

**Arithmetic**. The infix operators `+ - * div %` work as you'd expect. (The
`div` operator does integer division, truncating the result so that `5 div 2 ==
2`. This is the reason it isn't spelled `/`.) `%%` tests for divisibility, so
it returns `true` whenever `%` returns `0`. `divmod` does an integer division
resulting in a 2-element array `[q, r]` where `q` is the quotient and `r` is
the reminder.

**String building**. You can concatenate strings with `~`. (To concatenate
arrays, use the Array method `.concat`.)

**Equality, comparison and matching**. The operators `==` and `!=` checks
whether values are equal or unequal. `< <= > >=` compare ordered types like
integers or strings. `~~ !~~` match a value against a type.

**Logical connectives**. The infixes `||` and `&&` allow you to combine boolean
(or really, any) values. Furthermore, `//` allows you to replace `none` values
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
| Additive             | left  | infix    | `+ -` |
| Concatenation        | left  | infix    | `~` |
| Comparison           | left  | infix    | `== != < <= > >= ~~ !~~` |
| Conjuctive           | left  | infix    | `&&` |
| Disjunctive          | left  | infix    | `\|\| //` |
| Assignment (loosest) | right | infix    | `=` |

Alma's precedence rules are a bit simpler than Raku's. In Alma, the prefixes
and postfixes _have_ to bind tighter than the infixes.

The table also shows the associativity of the different precedence levels.
(Also unlike Raku, associativity belongs to the precedence _level_, not to
individual operators.) Associativity makes sure to (conceptually) insert
parentheses in a certain way for operators on the same level:

    1 + 2 - 3 + 4          becomes        ((1 + 2) - 3) + 4    (associating to the left)
    x || y // z            becomes        (x || y) // z        (associating to the left)
    a = b = c = 0          becomes        a = (b = (c = 0))    (associating to the right)

Besides the built-in operators, you can also extend the Alma grammar by writing
your own [custom operators](#custom-operators).

## Control flow

### Sequencing

_Sequencing_ happens just by writing statements after each other.

A statement can be terminated by a semicolon (`;`). The semicolon is mandatory
when you have other statements coming after it, regardless of the statements
being on the same line or separated by a newline character. When a statement
ends in a closing curly brace (`}`), you can omit the semicolon as long as you
have a newline character instead.

```alma
func f1() {
}                               # OK
func f2() {};   say("hi!")      # OK
func f3() {}    say("oh noes")  # not ok
```

### Block statements

Alma has `if` statements, `while` loops and `for` loops by default. This example
probably won't look too surprising to anyone who has seen C-like syntax before:

```alma
my array = [5, func() { say("OH HAI") }, none];
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
if the resulting value is `true`, possibly after coercing to `Bool`. (We
sometimes refer to a value that is `true` when coerced to `Bool` as _truthy_,
and the other values as _falsy_.) Several other mechanisms in Alma, such as `&&`
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

Alma allows you to add new statement forms for control flow if you want to
&mdash; the three statements above are very common but don't form a closed set.
For more information on how to do this, see the section [interacting with
control flow](#control-flow).

## Functions

Functions take parameters, can be called, and return a value. Definitions and
calls look like this:

```alma
func add(n1, n2) {
    return n1 + n2;
}

say("3 + 4 = ", add(3, 4));
```

The `return` statement immediately returns out of a function, optionally with a
value. If no value is supplied (as in `return;`), the value `none` is returned.
Implicit returns are OK too; the statement in the `add` function above could
have been written as just `n1 + n2;` because it's last in the function.

When defined using a function statement, it's also allowed to call the function
_before_ its definition. (This is not true for any other type of defined thing
in Alma.)

```alma
whoa();     # Amazingly, this works!

func whoa() {
    say("Amazingly, this works!");
}
```

All references to undeclared variables are postponed until CHECK time (after
parsing the program), and an error message about the identifier not being found
is issued _only_ if it hasn't since been declared as a function.

There's also a way to declare functions as terms, and they work just the same:

```alma
my id = func(x) { x };
say(id("OH HAI"));      # OH HAI
```

Note that this form does not have the above advantage of being able to be used
before its definition &mdash; the declaration in this case is a normal lexical
variable.

Unlike in Raku (but like Python), a function call must have the parentheses.
You can write `say(42);` in Alma, but not `say 42;` &mdash; the latter is a
parse error and counts as Two Terms In A Row.

### Arguments and parameters

When declaring a function, we talk about function *parameters*. A parameter is
a kind of variable scoped to the function.

```alma
func goodnight(name) {
    say("Goodnight ", name);
}
```

When calling a function, we instead talk about *arguments*. Arguments are
expressions that we pass in with the function call.

```alma
goodnight("moon");
```

As the function call happens, all the arguments are evaluated, and their
resulting values are *bound* to the parameters. It's a (runtime) error for
the number of arguments to differ from the number of parameters.

> #### 🔮 Future feature: static checking
>
> In the cases where the function definition is known/visible from the
> callsite, we could even give this error at compile time (like Raku but
> unlike Python or Perl 5). Flagging up the error during compilation makes
> sense, since the call would definitely fail at runtime anyway.

> #### 🔮 Future feature: optional parameter and parameter defaults
>
> Alma will at some point incorporate optional parameters and parameter default
> values into the language. (These are already supported in some of the
> built-ins, albeit still inaccessible to the user.) The number of arguments
> can of course go as low as the number
> of non-optional parameters. Non-optional parameters can only occur before
> optional ones.

> #### 🔮 Future feature: rest parameters and spread arguments
>
> The syntax `...` will at some point work to denote a *rest parameter* (which
> accepts any remaining arguments into an array), and a *spread argument*
> (which turns an array of N arguments into N actual arguments). In the
> presence of a rest parameter, the number of arguments accepted is of course
> unbounded.

> #### 🔮 Future feature: named arguments
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

```alma
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

```alma
say();                          # empty line
say("OH HAI");
say("The answer is: ", answer);
```

For reading input, there's `prompt`:

```alma
my answer = prompt("Rock, paper, or scissors? ");
```

The third important builtin allows you to get the type of a value:

```alma
type(42);           # <type Int>
type("hi");         # <type Str>
type(prompt);       # <type Func>
type(Bool);         # <type Type>
```

The biggest use for the `type` builtin is for printing the type of something
during debugging. If you want to test for the type of a value in a program, you
probably shouldn't test `type(value) == Array` but instead use the
smartmatching operator: `value ~~ Array`.

Technically, all the operators and types available by default in Alma are also
builtins.

## Classes and objects

> #### 🔮 Future feature: classes
>
> The implementation of classes has started behind a feature flag, but mostly,
> classes are not implemented yet in Alma.

You can declare classes in Alma.

```alma
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

As you can see, classes in Alma look like in most other languages. They can have
fields, a constructor, and methods. Fields can optionally have _initializers_,
expressions that evaluate before the constructor runs.

```alma
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

```alma
class AlphaColor extends Color {
    has alpha;
}
```

All the public fields and methods from the base class are also available on the
extending class. If a field or method has the same name as in a base class,
then it will _override_ and effectively hide the field or method in the base
class. Alma stops short of having a `super` mechanism to call overridden methods
or constructors.

Class declarations are _slangs_ in Alma, so the above desugars to something very
much like this:

```alma
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

`None`, `Int`, `Str`, `Bool`, `Array`, `Dict`, `Regex`, `Symbol`,
and `Type` are all built-in types in Alma. Besides that, there are all the types
in [the `Q` hierarchy](#the-q-hierarchy), used to reasoning about program
structure. There are also a number of exception types, under the `X` hierarchy.

Here's an example involving a custom `Range` class, which we'll use later to
also declare custom range operators:

```alma
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

> #### 🔮 Future feature: generator functions
>
> Using generator functions, we could skip writing the `Range.Iterator` class,
> and write the `iterator` method like this:
>
> ```alma
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

Alma is built to give the programmer the power to add to and modify the
language, to the point where everything in the language _could_
have been added by the programmer. Macros are the prime example, but custom
operators qualify too. This chapter is the longest in the guide so far; the
reason is that whenever you get into the game of extending the language itself,
you're technically a language designer, and potentially you have to worry about
some things a language designer has to worry about.

Besides the [built-in operators](#operators-and-expressions), you can supply
your own operators. Here, for example, is an implementation of a factorial
operator:

```alma
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
functions, but also as _syntax_ &mdash; writing `5!` in an Alma program doesn't
work normally, but it does after you've defined `postfix:<!>`.

Just like with ordinary identifiers, they go out of scope at the end of the
block where they were defined. Like with other functions, you can call them
before their definition, but you can _not_ use the operator syntax before the
definition (because the parser only does one pass, and adds the operator when
it's defined).

> #### 🔮 Future feature: reduction metaoperator
>
> Using the reduction metaoperator, argument spread, and a range operator, we
> can implement `postfix:<!>` much more succinctly:
>
> ```alma
> func postfix:<!>(N) { [*](...(2..N)) }
> ```

### Built-in operators are built-in functions

Now that the truth is out about user-defined operators being fairly normal
functions, it's time for another bombshell: built-in operators are normal
functions too! These are two equivalent ways to add two numbers in Alma:

```alma
3 + 4;              # 7
infix:<+>(3, 4);    # 7
```

The function `infix:<+>` is defined among the built-ins, together with `say`
and some other functions.

### Operator categories

The thing before the colon is called a _category_. For Alma operators, there are
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

```alma
func postfix:<!>(N) {
    if N < 2 {
        return 1;
    }
    else {
        return N * (N-1)!;
    }
}
```

> #### 🔮 Future feature: ternary operator
>
> With the ternary operator macro imported, the solution becomes downright cute:
>
> ```alma
> func postfix:<!>(N) { N < 2 ?? 1 !! N * (N-1)! }
> ```

### Infix precedence and associativity

When you define an operator, you can also provide information about its
precedence and associativity. (For an introduction to those concepts, see
[built-in operators](#operators-and-expressions).) Here is an implementation of
a right-associative [cons](https://en.wikipedia.org/wiki/Cons) operator:

```alma
func infix:<::>(lhs, rhs) is tighter(infix:<==>) is assoc("right") {
    return [lhs, rhs];
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

```alma
func infix:<^_^>(lhs, rhs) is assoc("non") {
}

2 ^_^ 3 ^_^ 4;          # parse error: "operator is nonassociative"
```

### Prefix/postfix precedence and associativity

A postfix and a prefix can share a precedence level, and if it comes down to
one being evaluated first or the other, associativity comes into play. This
pair of operators associates to the left:

```alma
func prefix:<?>(term) is assoc("left") {
    return "prefix:<?>(" ~ term ~ ")";
}

func postfix:<!>(term) is equal(prefix:<?>) is assoc("left") {
    return "postfix:<!>(" ~ term ~ ")";
}

say(?"term"!);       # postfix:<!>(prefix:<?>(term)) (left associativity) (default)
```

While this pair associates to the right:

```alma
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
top, then prefix, then infix.) Alma tries to respect this convention by default;
instead of making a new custom prefix maximally tight by default, it only makes
it tighter than all other prefixes, but looser than all other postfixes.

Infixes form precedence levels of their own, apart from the prefixes and
postfixes. Trying to relate the precedence of a prefix or postfix to that of an
infix, or vice versa, leads to a compile-time error.

### An example: `Range`

We can define operators that construct `Range` objects, using the class we
defined earlier:

```alma
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
> ```alma
> for 1..10 -> i { say(i) }
> for ^100 { say("I shall never waste chalk again") }
> ```

### Parsing concerns

In `infix:<+>`, the angle bracket symbols are a quoting construct to delimit
the symbol of interest; the actual _internal_ name is `infix:+`, but during
parsing and stringification, it will always show up as `infix:<+>`.

If your operator symbol contains `>`, then you can use a backslash to escape
the symbol: `infix:<\>>`. Another way to avoid ambiguity is to use different
angle brackets: `infix:«>»`. (This is Alma's default when it stringifies.)

If two or more operators could all match a given piece of text, then the rule
is that the _longest_ operator wins. This is regardless of the order in which
they were defined, and regardless of their category.

    3 +++ 4     # is there an infix:<+++>? then it wins
                # or maybe an postfix:<++> and an infix:<+>; then they win
                  # ...EVEN if there were an infix:<+> and a prefix:<++>, since infix:<++> is longer
                # or maybe an infix:<+>, a prefix:<+>, and another prefix:<+>
                  # (these are all built-in operators, so that's what happens by default)

Whitespace does not enter into consideration when the parser tries to determine
whether something is an infix, prefix, or postfix. At least in this regard, Alma
is whitespace-agnostic.

Given the above, if an infix and a postfix are defined with the exact same
symbol, they _would_ clash as soon as they were parsed. For this reason, if you
try to install a postfix with the same symbol as an already installed infix, or
vice versa, the compiler will give you an error. You'll get an error regardless
of whether the already installed operator is a built-in or user-defined.

## Modules

> #### 🔮 Future feature: modules
>
> Modules have not been implemented yet in Alma. This whole chapter is a
> best-guess at how they will work.

Alma files can be run directly as _scripts_, or they can be imported from other
Alma files as _modules_.

The purpose of modules is to break up a big program into multiple independent
compilation units.

* Each module can completely express a relatively small piece of functionality,
  and is easier to understand and reason about in isolation. (Often referred
  to as _separation of concerns_.)

* Since each module decides exactly what to export to the outside world, a
  module boundary also confers a means of _encapsulation_ and _information
  hiding_. Some aspects of a module can be exported to the outside;, the ones
  that aren't are completely private and internal.

* The same module can be used in multiple places in a code base, or in several
  different programs. This _re-use_ is often preferable to manually copying
  the same solution into several programs.

### Example: `Range` as a module

Let's say we want to package up our `Range` class, and the custom operators
that help construct ranges, as a module. That way, a user of our module will
just be able to write this in their program:

```alma
import * from range;
```

From that point on for the rest of the block, all the things related to ranges
will be lexically available.

```alma
for 2 .. 7 -> n {   # works because infix:<..> was imported
    say(n);
}
```

If we only wanted the `infix:<..>` operator, we could import only that:

```alma
import { infix:<..> } from range;
```

The `range` module is in fact a `range.alma` file in Alma's lib path. We'd write
it with the same definition as before, except we also export them:

```alma
export class Range { ... }

export func infix:<..>(lhs, rhs) # ...
export func infix:<..^>(lhs, rhs) # ...
export func prefix:<^>(expr) # ...
```

### Forms of import

There are three forms of the `import` statement.

The *named import* form lists all the names we want to declare in the current
scope:

```alma
import { nameA, nameB, nameC } from some.module;
```

Each name imported counts as a declaration; importing and otherwise declaring
the same name in the same scope is a compile-time error.

In the imported module, every export declaration exports an identifier, and
together all the exported names make up the *export list*.

The *star import* form imports the entire export list into the current scope:

```alma
import * from some.module;
```

While this is convenient, it's also the only built-in construct in the language
where *you can't see* from the syntactic form itself what names you're
introducing into the scope.

Finally, the *module object import* creates a module object with all the
names from the export list as properties:

```alma
import m from some.module;
# m now has m.nameA, m.nameB, m.nameC, etc.
```

Imports are *not* hoisted in Alma.

```alma
foo();  # won't work
import { foo } from some.module;
```

### Forms of export

You're only allowed to `export` statements outside of any block in a module
file.

There are two forms of export statement:

The *exported declaration* form is an export plus one of the declaration
statements:

```alma
export my someVar ...;
export func foo(...) ...;
export macro moo(...) ...;
export class SomeClass ...;
```

Exactly as you'd think, this not only declares a new identifier in the local
scope, but also exports it.

The *export list* form lists existing names to export:

```alma
export { nameA, nameB, nameC };
```

There can be several of these export statements in a module, but it's
recommended to put one at the end.

# Macrology

Alma has extensible syntax and semantics, to an extent not found in many other
languages.  It lets you define the syntax and semantics not just for operators,
but for terms and statements as well. This part of the documentation is about
that.

The overriding goal is for elements of the core language, as well as language
extensions, to be _user-definable_. This largely happens thanks to macros.

This section is intricate because being a language extender is more challenging
than being a language consumer. In extending in the language's reach, you will
need to relate to aspects of the parser, the code generation, and the execution
model at a higher fidelity than the average "end user" of the language.

Moreover, in the crowded space of lanuage extension, you're being held at a
higher-than-usual standard of care and empathy. Your particular extension might
need to interoperate not just with the core language but with other people's
(past, present, and future) extensions. This requires tact and taste.

## Macros

Function calls run at runtime:

```alma
func foo() {
    say("OH HAI");
}

say("before");
foo();
say("after");
```

This will output `before`, `OH HAI`, and `after`.

Compare this to a macro call:

```alma
macro moo() {
    say("OH HAI");
}

say("before");
moo();
say("after");
```

This will output `OH HAI`, `before`, and `after`. In fact, the `moo` macro runs
so early, it runs during the compilation process itself. (Macros run at `BEGIN`
time.)

Macros can return code, which will then be injected at the point of the macro
call. Code that we return has to be *quoted*, so that it doesn't run
immediately:

```alma
macro moo() {
    return quasi {
        say("OH HAI");
    };
}

say("before");
moo();
say("after");
```

This code, again, outputs `before`, `OH HAI`, and `after` &mdash; the code in
the `quasi` block was injected at the point of the `moo()` call.

The above macros were not real examples, so let's do two macros that are
actually potentially useful in your code:

Let's say you want an operator for repeating an array. Let's call the new
operator `infix:<xx>`:

```alma
[1] xx 5;                   # [1, 1, 1, 1, 1]
[1, 2] xx 3;                # [1, 2, 1, 2, 1, 2]
```

The above is perfectly definable as an operator _function_, but... we could get
a little bit of extra use out of the thing if the left-hand side was
re-evaluated each time:

```alma
my i = 0;
[i = i + 10] xx 4;          # [10, 20, 30, 40]
```

(For more on re-evaluation, see "thunky semantics" in the [Evaluating
expressions](#evaluating-expressions) chapter.)

Here's how an implementation of `infix:<xx>` might look:

```alma
macro infix:<xx>(left, right) is equiv(infix:<*>) {
    return quasi {
        (^{{{right}}}).flatMap(func(_) { {{{left}}} })
    }
}
```

The second example comes from C#, which has a [`nameof`
operator](https://docs.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/nameof).
This is a little helper that takes a variable, and returns its _name_. The
benefit of using such an operator (over just writing the names as strings in
the code directly) comes when renaming things using automatic refactor actions
&mdash; the variable in the `nameof` expression will be renamed with everything
else, but a name in a string won't be.

Here's an Alma implementation of this operator:

```alma
macro prefix:<nameof>(expr) {
    assertType(expr, Q.Identifier);
    return quasi { expr.name };
}
```

And here's how to use it:

```alma
my agents = ["Bond", "Nexus"];

say(nameof agents);         # "agents"
```

### Quasis

A _`quasi`_ (or _`quasi` block_ or _quasiquote_) is a way to create a Qtree
program fragment by simply typing out the code as you'd usually do.

```alma
macro moo() {
    return quasi {
        say("OH HAI");
    };
}
```

Whereas regular code runs directly, and code in a function runs only when the
function is called, the code in a quasi isn't even in the program yet. It's
waiting to be inserted somewhere.

The typical way to insert code from a quasi into the regular code is via a
macro. A macro contains one or more quasis, and the resulting bit of code is
returned at the end. The compiler takes the resulting code and re-injects it in
the place of the macro call.

Sometimes the code where the macro is inserted is called the _mainline_ code,
just to distinguish it from what happens within the macro. (The distinction is
a bit bogus. Macros can call other macros.)

By the way, the act of replacing a macro call by its returned code is
traditionally called _macro expansion_.

Together with the ability to represent code literally, quasis also allow you to
_interpolate code_ into the `quasi` code:

```alma
macro doubleDo(stmt) {
    return quasi {
        {{{stmt}}};
        {{{stmt}}};
    };
}

doubleDo(
    say("OH HAI")
);                  # prints "OH HAI" twice
```

The interpolation capability is what makes quasiquotes interesting. (And also
why they are called _quasi_quotes, and not just quotes.) It's a really neat way
to switch between literal code that's the same between macro calls, and
parameterized code that can vary from call to call.

### The Q hierarchy

What's the value of a `quasi` block? When a macro returns, what does it
actually return?

In Alma, your entire program is a _document_, much like the HTML DOM treats an
HTML page as a document. This document is made up of _nodes_, all subclasses of
the `Q` class. (Usually referred to as _Qnodes_.)

In other words, they are regular Alma values, instances of some subclass of `Q`.

* Any statement is a `Q.Statement`.
* Any expression or expression fragment is a `Q.Expr`.
* Operators belong to `Q.Prefix`, `Q.Infix`, or `Q.Postfix`.

And so on. The entire Q hierarchy is detailed in the API documentation.

Philosophically, this is where Alma departs from Lisp. In Lisp, everything is
nested lists, even the entire program structure. Alma instead exposes an
object-oriented API to the program structure. It will never be as simple and
uniform as the list interface, but it can have other strengths, such as the
ability to strongly type the program structure, or access values in Qnodes
through named properties.

In the end, the essential point of Qnodes is that the compiler toolchain and
the runtime are able to act on the same values without any fuss.

## Stateful macros

Consider this macro:

```alma
macro onlyOnce(expr) {
    my alreadyRan = false;
    return quasi {
        if !alreadyRan {
            {{{expr}}};
            alreadyRan = true;
        }
    };
}

for [1, 2, 3] {
    onlyOnce(say("OH HAI"));        # "OH HAI" once, not three times
}
for [1, 2] {
    onlyOnce(say("OH HAI"));        # "OH HAI" once, not twice
}
```

The above demonstrates two things:

* Code in a quasi can read/modify variables defined in the macro. The values in
  such variables will persist between runs of the quasi code.

* Each macro _expansion_ (that is, each call to the macro in the code) gets its
  own fresh copies of these variables, since the macro runs anew each time.

We describe this by saying that the `alreadyRan` variable belongs to the
macro's local _state_. Macros with local state are called _stateful_.

As a prototypical example of a stateful macro, consider the `infix:<ff>`
operator from Raku (spelled `infix:<..>` in Perl 5):

```alma
my values = ["A", "B", "A", "B", "A"];
for values -> v {
    if v == "B" ff v == "B" {
        say(v);
    }
    else {
        say("x");
    }
}
# Output: xBxBx
```

Here's how we can simply implement this macro:

```alma
macro infix:<ff>(lhs, rhs) {
    my active = false;
    return quasi {
        if {{{lhs}}} {
            active = true;
        }
        my result = active;
        if {{{rhs}}} {
            active = false;
        }
        result;
    };
}
```

We can eliminate the `if` statements by using assignment operators instead:

```alma
import * from syntax.op.assign;

macro infix:<ff>(lhs, rhs) {
    my active = false;
    return quasi {
        active ||= {{{lhs}}};
        my result = active;
        active &&= {{{rhs}}};
        result;
    };
}
```

This declaration works, but has one downside: the macro state is program-wide,
but what we tend to expect/want is for the macro state to "reset" every time
its surrounding block is re-entered.

Here's an implementation that stores the state such that it's per block entry,
not per program run:

```alma
import * from syntax.op.assign;
import * from syntax.term.state;

macro infix:<ff>(lhs, rhs) {
    return quasi {
        state active = false;
        my result = active;
        active &&= {{{rhs}}};
        result;
    };
}
```

Pleasingly, stateful macros can often be expressed using the `state`
declarator.

## Closures in macros

Lexical lookup means a "search" is carried out from where a variable occurs,
outwards to where it was defined. Eventually, the definition is found &mdash;
it can't not be found, since such cases have already been eliminated at
runtime.

When macros are thrown into the mix, the situation is different: code can be
"copy-pasted" so that variables get separated from their definitions. Here's
a simple example:

```alma
import * from syntax.op.incdec;

macro nth() {
    my count = 0;
    quasi {
        say(++count);
    };
}

nth();  # 1
nth();  # 2
nth();  # 3
```

The `nth();` invocations get expanded into code that looks like `say(++count);`
&mdash; but a lexical look-up of `count` from that place in the code would
_fail_.

What's worse, if the code looked a little bit different:

```alma
# macro nth as before

my count = "haha, busted!";
nth();
nth();
nth();
```

Then a lexical lookup would find the _wrong_ `count` variable; the one from the
mainline, not the one from the `nth` macro.

An expectation would be broken here: that mainline variables never get mistaken
for macro/quasi variables, or vice versa. As a consumer of a macro, you
shouldn't ever have to be concerned about the names of your (mainline)
variables colliding with names from inside the macro. This expectation is
referred to as "macro hygiene".

For this to work, variables inside of a quasi tied to outside definitions use a
different kind of lookup: _direct_ lookup. No "search" is involved in this
lookup; instead, the exact location of the variable is used. This is how the
macro-expanded `count` in the examples above finds its way to the definition
inside of the macro.

Among the languages of the Lisp family, Scheme guarantees hygiene by default.
In contrast, Common Lisp allows variables from macros and the mainline to
intermix; proponents of this unhygienic approach point to greater macro
expressivity as the main advantage.

Alma goes with Scheme's hygienic behavior by default, as this seems to adhere to
Least Surprise for unwary users. But it also allows the macro author to opt
into Common Lisp's unhygienic behavior, through the special namespace
`COMPILING`, which denotes the block from which the macro was _invoked_:

```alma
macro moo(expr) {
    return quasi {
        say(COMPILING.x);       # prints "OH"
        my COMPILING.y = "HAI";
        {{{expr}}};
    };
}

my x = "OH";
moo(say(y));                    # prints "HAI"
```

Needless to say, unhygienic variables are weird and should be used sparingly.
The good news is that they are safe, in the sense that attempting to expand the
`moo` macro above in an environment where `x` is not defined will trigger an
error. That is, the variables bind quite late, but still at compile time.

Sometimes we want to have the cake and eat it: we want to punch a hole
(unhygienically) into the mainline scope and place a variable there, but we
also want its name (hygienically) to not collide with any other names, whether
from the mainline or from other macro invocations. That's when we need
_symbols_; see [a later section](#symbols) for more on these.

## Macros that parse

A macro invocation usually looks like a function call, or possibly like an
operator. If we want it to look like something else, we have to indicate to the
language how it should be parsed. We do this using the `@parsed` annotation.

As the `@parsed` annotation uses regexes, it's recommended you read [the
section on regexes](#regexes) before reading this one.

Here's how we would implement the `loop` statement:

```alma
@parsed(/ "loop"» :: <.ws> <block> /)
macro statement:loop(match) {
    my block = match["block"].ast;
    return quasi {
        while True {{{Q.Block @ block}}}
    };
}
```

The `loop` statement starts with the keyword `loop`. It's a good idea to
require a word boundary (`»`) right after the keyword, otherwise other things
starting with `loop` (for example a variable called `loopy`) would match as
false positives.

The `::` backtrack controller is also good form, to mark the end of the
"declarative prefix" inside of the parse rule. See [the section on
regexes](#regexes) for more on declarative prefixes.

After the keyword, we accept some whitespace (which we don't care to capture)
and a block. The block is made available inside of the macro through a `match`
parameter. All `@parsed` macros need to declare an extra parameter where the
matched result of the parse goes &mdash; even in cases where nothing was
captured. This parameter can be called anything, but it's a strong convention
to name it `match`. We index into `match["block"]` and fish out its `.ast`
payload, which is guaranteed to be a `Q.Block`.

Finally, inside the `quasi`, instead of writing the customary `{ ... }` block
as literal code, we pass in `{{{Q.Block @ block}}}` &mdash; the `Q.Block` is
both a guarantee to the `quasi` parser that the thing is syntactically
`Q.Block`-shaped, and a runtime check (when the quasi gets interpolated) that
the expression `block` is a subtype of `Q.Block`.

Here's another example, one which involves macro hygiene. This macro defines a
_reduction metaoperator_, allowing code such as `[+](1, 2, 3)` (getting a sum
of 6) or `[~]("OH", " ", "HAI")` (concatenating to `"OH HAI"`):

```alma
import * from syntax.param.rest;

@parsed(/ "[" :: <infix> "]" /)
macro term:reduce(match) {
    my infix = match["infix"].ast;
    my fn = func(...values) {
        values.reduce(infix.code);
    };
    return quasi { fn };
}
```

Here we rely on the fact that every `Q.Infix` node has a `.code` attribute with
the code behind that particular operator. From this, we can construct just the
right anonymous function and return it inside the quasi block.

(The reduce operator provided through `syntax.op.reduce`, is a little bit more
intricate in that it also respects the associativity of the infix operator
used.)

As a final example in this section, let's define the `?? !!` operator:

```alma
@parsed(/ "??" :: <.ws> <expr> "!!" <rhs=expr> /)
macro infix:cond(lhs, match) {
    my expr = match["expr"].ast;
    my rhs = match["rhs"].ast;
    return quasi {
        my result;
        if {{{lhs}}} {
            result = {{{expr}}};
        }
        else {
            result = {{{rhs}}};
        }
        result;
    }
}
```

An infix operator macro has two paramters (the lhs and the rhs); for a
`@parsed` infix macro, the `lhs` parameter is kept, but the `rhs` parameter is
_replaced_ by the `match` parameter. Generally for operators, the operands
coming before the operator are kept as regular parameters, whereas the ones
occurring after are incorporated into the `match` parameter (and thus parsing
them (or not) is completely up to the `@parsed` regex).

Also, in this example, we make good use of renaming of captures (`<rhs=expr>`).
If we hadn't renamed the second `<expr>` subrule call, we would have ended up
with an array of submatches in `match["expr"]` rather than a single submatch.

For brevity, the above example omits some error handling involving `=` (or even
looser user-defined operators) occuring inside `<expr>`. See the source code of
`syntax.op.conditional` for the gory details.

## Statement macros

We already saw an example of a statement macro in [the previous
section](#macros-that-parse), but it's so common to want to define these that
we might as well do a few more examples.

First, let's implement the `until` statement. XXX

As a slightly more elaborate example, let's define the `repeat while` loop,
whose main selling-point is that it evaluates its condition _after_ the first
iteration through the loop (unlike `while` which does it before). Futhermore,
the programmer gets to choose whether to write the condition before or after
the loop (but the condition will always run after regardless).

```alma
@parsed(/"repeat" <.ws> [
    | "while"» :: <.ws> <expr> <.ws> <block>
    | :: <block> <.ws> "while"» <.ws> <expr>
]/)
macro statement:repeatWhile(match) {
    my expr = match["expr"].ast;
    my pblock = match["block"].ast;

    return quasi {
        while True {
            {{{Q.Block @ block}}}
            if {{{expr}}} {
                last;
            }
        }
    };
}
```

No special handling is needed to distinguish between condition coming before or
after the block.

Just from the above, the consumer of the `repeat while` macro gets to declare a
variable in the condition, and then use it in the loop block (or later in the
surrounding block):

```alma
repeat while my line = prompt("> ") {
    # do something with `line` here
    # (first iteration `line` will have the value `none`)
}

# `line` is visible here too, until end of block
```

This falls out automatically from how `my` works. By the same token, if you
declare a variable when the condition comes _after_ the block, that variable is
_not_ visible inside the block:

```alma
repeat {
    # now `line` isn't visible here
} while my line = prompt("> ");

# `line` is still visible here, though
```

(The real `repeat while` statement uses a pointy block instead of a regular
block. The gory details have been omitted here.)

As a last example, let's look at how the `for` loop can be defined:

```alma
import * from syntax.my.destructure;

@parsed(/ "for"» <xblock> /)
macro statement:for(match) {
    my expr = match["expr"].ast;
    my pblock = match["pblock"].ast;
    my pfn = pblock.fn();

    return quasi {
        my iterator = {{{expr}}}.iterator();
        while my [hasNext, value] = iterator.next() && hasNext {
            pfn(value);
        }
    };
}
```

Two things are going on here. First, under the hood what a `for` loop does is
grab an iterator from its expression which it then iterates in a `while` loop.

Second, the pointy block coming after the expression needs to be passed the
current `value`. There's not really a way to syntactically call a pointy block
(since it's not an expression), but we can ask a `Q.Block` to wrap itself into
a function, and then we can call it from inside the `while` loop.

To read more about `xblock`, check out the next section on [grammatical
categories](#grammatical-categories).

(We've omitted from this simple example some checking that the pointy block
doesn't have more than one parameter, plus also the logic required to handle
the zero-parameter case. See the `syntax.stmt.for` module for those details
details.)

## Grammatical categories

In a macro definition such as

```alma
@parsed(/ ... /)
macro statement:loop(match) { ... }
```

The (grammatical) category is what comes before the colon in the name; in this
case it's `statement`.

While the `@parsed` annotation determines _how_ a macro should parse, a macro's
grammatical category indicates _when_ it can parse. Statements, for example,
can parse at the beginning of a block, or after another statement. They can not
parse (say) right in the middle of an expression.

The grammar rules in Alma form an open set &mdash; you can add new ones if you
want &mdash; but the grammatical _categories_ form a closed set. They are as
follows:

* `prefix` and `term` (in term position)
* `infix` and `postfix` (in operator position)
* `statement` (at the start of a block or after another statement)
* `property` (at the start or after a comma in a property list)
* `argument` (at the start or after a comma in an argument list)
* `parameter` (at the start or after a comma in a parameter list)

The last four categories in the list are similar; they are so-called _list
environments_; the last three are comma-separated, whereas statements are
separated by semicolons (except when the semicolon can be skipped). The top
four categories belong to the _expression environment_.

A convenient way to "inject" operator-like grammar rules into the list
environments is to extend these just like you would extend the expression
environment. For example, the commas between parameters could be defined like
this:

```alma
@trailing
@assoc("list")
macro parameter:infix:<,>(...parameters) {
    return Q.ParameterList(parameters);
}
```

The `@trailing` annotation allows a trailing comma in a parameter list, like
so: `fn(1, 2, 3,)`. It's a bit more ergonomic when writing parameters each on
one line.

Similarly, the rest parameter syntax can be defined like this:

```alma
macro parameter:prefix:<...>(parameter) {
    return Q.Parameter.Rest(parameter);
}
```

## Contextual macros

By default, macros only have influence over what code to expand in place of the
macro call (or `@parsed` code). Also by default, expansion (that is, wholesale
replacement of the old code with the new) is the only action possible.

When that's not sufficient &mdash; when a macro needs to affect things in its
surroundings and/or move, copy, and validate Qnodes rather than just replace
them, a _contextual_ macro is used.

A contextual macro is a macro which consumes a _context_, an object provided by
a _host_ attached to some syntactically surrounding thing in the code. For
example, there's an `each()` macro, which can turn a statement into several
repeated statements with different data:

```alma
say(each(1, 2, 3), "testing");
# 1 testing
# 2 testing
# 3 testing
```

The `each()` macro can be implemented like this:

```alma
import * from syntax.param.rest;

@usesContext(Q.Statement.Expr)
macro each(context, ...values) {
    my stmts = values.map(func (value) {
        return context.root.cloneAndReplace(context.target, value);
    });
    context.root.replace(stmts);
}
```

The `each()` macro locates the whole statement (the AST of the surrounding
context), and for each value in `values`, it clones a new statement while also
replacing _itself_ (the `each()` invocation) with just one particular value.
The whole array of new statements is returned, and Alma's macro expansion does
the right thing expanding the entire old statement (containing the `each()`
call) into those new statements (containing individual values).

As demonstrated above, there are two important Qtrees available through the
`context` parameter: `context.root`, the Qtree of the macro's host (the one
providing the context), and `context.target`, the macro itself.

The inquisitive reader might wonder what the above macro definition does if a
statement has _two_ (or more) `each()` invocations. For example, this code:

```alma
say(my p = each(1, 2, 3), " * ", my q = each(4, 5, 6), " = ", p * q);
```

will print the following:

```
1 * 4 = 4
1 * 5 = 5
1 * 6 = 6
2 * 4 = 8
2 * 5 = 10
2 * 6 = 12
3 * 4 = 12
3 * 5 = 15
3 * 6 = 18
```

Intuitively, the second `each()` call can be seen as an "inner loop" and the
first one an "outer loop".

Concretely, the two `each()` calls fire in reverse order, so that `each(4, 5,
6)` gets to transform the statement first, and `each(1, 2, 3)` second. Regular
macros don't fire in reverse, they fire ASAP either as they are parsed, or as
they are expanded into code. With contextual macros, the firing order is
delayed until the whole contextual host has been parsed, and then it happens
according to specific rules of precedence, explained below.

XXX examples: junctions, amb, class declarations

## Evaluating expressions

A common rule-of-thumb for macros is that they typically only want to unquote
their arguments _once_. An example will serve to show why. Let's start with
this (insufficient) implementation of `prefix:<++>`:

```alma
macro prefix:<++>(term) {
    return quasi {
        {{{term}}} = {{{term}}} + 1;
    };
}
```

Why is this insufficient? Well, consider this contrived bit of code to tease
out a behavior which breaks Least Surprise:

```alma
my a = [0, 0, 0];

func sideEffecty() {
    say("double agent detected in passenger seat -- ejecting");
    return a;
}

++sideEffecty()[1];
```

The user correctly expects this code to increase the middle element of the
array in `a`, yielding `[0, 1, 0]`. However, the function has a side effect,
and the user likely also expects `sideEffecty` to only run once.

Unfortunately, since `{{{term}}}` was spelled out twice in the `quasi`, there
are two `sideEffecty()` calls in the resulting expanded code:

```alma
sideEffecty()[1] = sideEffecty()[1] + 1;
```

Contrary to expectations, therefore, two double agents get ejected from the
passenger seat.

This is a really common mistake to make, and so we formulate this rule to
combat it:

> **The single evaluation rule**
>
> Typically, a variable should be unquoted at most once in a quasi.

To this end, Alma also serves up a compile-time error if you break this rule.

Since it's just a rule-of-thumb, though, you might want to suppress this error
message. You do that by annotating the parameter or variable with `@many`.

Also, the compiler is relatively clever in what it means by "more than one
evaluation". For example, this macro doesn't get you in trouble:

```alma
macro fine(expr) {
    return quasi {
        if Bool.roll() {
            {{{expr}}};
        }
        else {
            {{{expr}}};
        }
    }
}
```

Because even though `{{{expr}}}` occurs twice in there, it only gets evaluated
at most _once_ on each path through the quasi code.

Moreover, this macro is also fine:

```alma
macro alsoFine(expr) {
    return quasi {
        for ^10 {
            {{{expr}}};
        }
    };
}
```

Because if you put the interpolation of your variable in a loop, you probably
_meant_ to evaluate it more than once anyway. We designate as a _thunk_ a
seemingly normal expression which (through a macro) we make run either more
than once, or (sometimes) not at all. In other words, both of these things are
thunks:

1. The left-hand side of `... xx N`, which evaluates (possibly differently)
once for each of the `N` elements we requested.

2. The right-hand side of a `&&` or `||` or `//`, which doesn't evaluate at all
if the left-hand side was already falsy, truthy, or defined, respectively.

You'll notice that the reason we naively wanted to unquote `{{{term}}}` twice
above was that we wanted to first _get_ the value (the so-called rvalue), do
some computation, and then _set_ the value (the lvalue). This comes up in many
other cases, such as the `infix:<+=>` family of operators, or the
`postfix:<.=>` mutating method calls, or the `swap` macro.

Here's how we do that correctly, again using `prefix:<++>` as an example:

```alma
macro prefix:<++>(term) {
    return quasi {
        my L = location({{{term}}});
        my value = L.get();
        L.set(value + 1);
    };
}
```

The built-in `location` macro takes an _access path_ (anything that resolves to
a modifiable bit of storage in memory) and gives back an opaque `Location`
object, with a `.get` and a `.set` method.

`Location` objects are an abstraction, to allow the macro author to talk about
the same access path multiple times without evaluating it more than once. The
compiler does its best to optimize away the location in the expanded code,
replacing it with simpler code. For example, with this better definition of
`prefix:<++>`, the expression `++sideEffecty()[1]` would result in something
like this:

```alma
my _uniqueSymbol873643 = sideEffecty();
_uniqueSymbol873643[1] = _uniqueSymbol873643[1] + 1;
```

(Where no amount of luck would allow you to guess the actual name of
`_uniqueSymbol873643`.)

`Location` objects are a bit of a two-edged sword &mdash; since they allow you
to essentially act on a storage location at a distance, letting them escape
from the quasi can cause the optimizer to become _very_ conservative in what it
can assume when optimizing your program. In other words, try to use locations
as locally as possible, on pain of getting a really slow program.

## Interacting with control flow

XXX example: `if` and `while`

XXX example: `next` and `last`

XXX example: `<-` (`amb`)

## Parsers and slangs

XXX

# API reference

## Types

## Functions

## Operators

## Exceptions

# How to contribute to Alma
