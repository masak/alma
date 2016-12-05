##Table of Contents

- [NoneType](#nonetype)
- [Bool](#bool)
- [Int](#int)
- [Str](#str)
- [Regex](#regex)
- [Array](#array)
- [Object](#object)
- [Type](#type)
- [Block](#block)
- [Sub](#sub)
- [Macro](#macro)
- [Exception](#exception)
- [Q::Expr](#qexpr)
- [Q::Term](#qterm)
- [Q::Literal](#qliteral)
- [Q::Identifier](#qidentifier)
- [Q::Property](#qproperty)
- [Q::PropertyList](#qpropertylist)
- [Q::Declaration](#qdeclaration)
- [Q::Trait](#qtrait)
- [Q::TraitList](#qtraitlist)
- [Q::Block](#qblock)
- [Q::Prefix](#qprefix)
- [Q::Infix](#qinfix)
- [Q::Postfix](#qpostfix)
- [Q::Unquote](#qunquote)
- [Q::Parameter](#qparameter)
- [Q::ParameterList](#qparameterlist)
- [Q::ArgumentList](#qargumentlist)
- [Q::Statement](#qstatement)
- [Q::CompUnit](#qcompunit)
- [Q::StatementList](#qstatementlist)





### NoneType

A type with only one value, indicating the lack of a value where one was
expected.

It is the value variables have that haven't been assigned to:

    my empty;
    say(empty);
        &#8658; None

It is also the value returned from a subroutine that didn't explicitly
return a value:

    sub noreturn() {
    }
    say(noreturn());
        &#8658; None

Finally, it's found in various places in the Q hierarchy to indicate that
a certain child element is not present. For example, a `my` declaration
can have an assignment attached to it, in which case its `expr` property
is a `Q::Expr` &mdash; but if no assignment is present, the `expr`
property is the value `None`.

    say(type((quasi @ Q::Statement { my x = 2 }).expr));
        &#8658; <type Q::Literal::Int>
    say(type((quasi @ Q::Statement { my x; }).expr));
        &#8658; <type NoneType>

The value `None` is falsy, stringifies to `None`, and doesn't numify.

    say(!!None);
        &#8658; False
    say(str(None));
        &#8658; None
    say(int(None));
        &#9760; X::TypeCheck

Since `None` is often used as a default, there's an operator `infix:<//>`
that evaluates its right-hand side if it finds `None` on the left:

    say(None // "default");
        &#8658; default
    say("value" // "default");
        &#8658; value


### Bool

A type with two values, `True` and `False`. These are often the result
of comparisons or match operations, such as `infix:<==>` or `infix:<~~>`.

    say(2 + 2 == 5);
        &#8658; False
    say(7 ~~ Int);
        &#8658; True

In 007 as in many other dynamic languages, it's not necessary to use
`True` or `False` values directly in conditions such as `if` statements
or `while` loops. *Any* value can be used, and there's always a way
for each type to convert any of its values to a boolean value:

    sub check(value) {
        if value {
            say("truthy");
        }
        else {
            say("falsy");
        }
    }
    check(None);
        &#8658; falsy
    check(False);
        &#8658; falsy
    check(0);
        &#8658; falsy
    check("");
        &#8658; falsy
    check([]);
        &#8658; falsy
    check({});
        &#8658; falsy

    check(True);
        &#8658; truthy
    check(42);
        &#8658; truthy
    check("James");
        &#8658; truthy
    check([0, 0, 7]);
        &#8658; truthy
    check({ name: "Jim" });
        &#8658; truthy

Similarly, when applying the `infix:<||>` and `infix:<&&>` macros to
some expressions, the result isn't coerced to a boolean value, but
instead the last value that needed to be evaluated is returned as-is:

    say(1 || 2);
        &#8658; 1
    say(1 && 2);
        &#8658; 2
    say(None && "!");
        &#8658; None
    say(None || "!");
        &#8658; !


### Int

An whole number value, such as -8, 0, or 16384.

Implementations are required to represent `Int` values either as 32-bit
or as arbitrary-precision bigints.

The standard arithmetic operations are defined in the language, with the
notable exception of division.

    say(-7);
        &#8658; -7
    say(3 + 2);
        &#8658; 5
    say(3 * 2);
        &#8658; 6
    say(3 % 2);
        &#8658; 1

Division is not defined, because there's no sensible thing to return for
something like `3 / 2`. Returning `1.5` is not an option, because the
language does not have a built-in rational or floating-point type.
Returning `1` (truncating to an integer) would be possible but
unsatisfactory and a source of confusion.

There are also a few methods defined on `Int`:

    say((-7).abs());
        &#8658; 7
    say(97.chr());
        &#8658; a


### Str

A piece of text. Strings are frequent whenever a program does text-based
input/output. Since this language cares a lot about parsing, strings occur
a lot.

A number of useful operators are defined to work with strings:

    say("James" ~ " Bond");
        &#8658; James Bond
    say("tap" x 3);
        &#8658; taptaptap

Besides which, the `Str` type also carries many useful methods:

    say("x".ord());
        &#8658; 120
    say("James".chars());
        &#8658; 5
    say("Bond".uc());
        &#8658; BOND
    say("Bond".lc());
        &#8658; bond
    say("  hi   ".trim());
        &#8658; hi
    say("1,2,3".split(","));
        &#8658; ["1", "2", "3"]
    say([4, 5].join(":"));
        &#8658; 4:5
    say("a fool's errand".index("foo"));
        &#8658; 2
    say("abcd".substr(1, 2));
        &#8658; bc
    say("abcd".prefix(3));
        &#8658; abc
    say("abcd".suffix(2));
        &#8658; cd
    say("James Bond".contains("s B"));
        &#8658; True
    say("James".charat(2));
        &#8658; m


### Regex

A regex. As a runtime value, a regex is like a black box that can be put
to work matching strings or parts of strings. Its main purpose is
to let us know whether the string matches the pattern described in the
regex. In other words, it returns `True` or `False`.

(Regexes are currently under development, and are hidden behind a feature
flag for the time being: `FLAG_007_REGEX`.)

A few methods are defined on regexes:

    say(/"Bond"/.fullmatch("J. Bond"));
        &#8658; False
    say(/"Bond"/.search("J. Bond"));
        &#8658; True


### Array

A mutable sequence of values. An array contains zero or more elements,
indexed from `0` up to `elems - 1`, where `elems` is the number of
elements.

Besides creating an array using an array term, one can also use the
"upto" prefix operator, which creates an array where the elemens equal the
indices:

    say(["a", "b", "c"]);
        &#8658; ["a", "b", "c"]
    say(^3);
        &#8658; [0, 1, 2]

Other array constructors which create entirely new arrays out of old ones
(and leave the old ones unchanged) are concatenation and consing:

    say([1, 2].concat([3, 4]));
        &#8658; [1, 2, 3, 4]
    say(0 :: [0, 7]);
        &#8658; [0, 0, 7]

Sorting, shuffling, and reversing an array also leave the original
array unchanged:

    my a = [6, 4, 5];
    say(a.reverse());
        &#8658; [5, 4, 6]
    say(a);
        &#8658; [6, 4, 5]
    say(a.sort());
        &#8658; [4, 5, 6]
    say(a);
        &#8658; [6, 4, 5]
    say(a.shuffle().sort());
        &#8658; [4, 5, 6]
    say(a);
        &#8658; [6, 4, 5]

The `.elems` method gives you the length (number of elements) of the
array:

    say([].elems());
        &#8658; 0

Some common methods use the fact that the array is mutable:

    my a = [1, 2, 3];
    a.push(4);
    say(a);
        &#8658; [1, 2, 3, 4]
    my x = a.pop();
    say(x);
        &#8658; 4
    say(a);
        &#8658; [1, 2, 3]

    my a = ["a", "b", "c"];
    my y = a.shift();
    say(y);
        &#8658; a
    say(a);
        &#8658; ["b", "c"]
    a.unshift(y);
    say(a);
        &#8658; ["a", "b", "c"]

You can also *transform* an entire array, either by mapping
each element through a function, or by filtering each element
through a predicate function:

    my numbers = [1, 2, 3, 4, 5];
    say(numbers.map(sub (e) { return e * 2 }));
        &#8658; [2, 4, 6, 8, 10]
    say(numbers.filter(sub (e) { return e %% 2 }));
        &#8658; [2, 4]


### Object

A mutable unordered collection of key/value properties. An object
contains zero or more such properties, each with a unique string
name.

The way to create an object from scratch is to use the object term
syntax:

    my o1 = { foo: 42 };
    my o2 = { "foo": 42 };
    say(o1 == o2);
        &#8658; True
    my foo = 42;
    my o3 = { foo };
    say(o1 == o3);
        &#8658; True

    my o4 = {
        greet: sub () {
            return "hi!";
        }
    };
    my o5 = {
        greet() {
            return "hi!";
        }
    };
    say(o4.greet() == o5.greet());
        &#8658; True

All of the above will create objects of type `Object`, which is
the topmost type in the type system. `Object` also has the special
property that it can accept any set of keys.

    say(type({}));
        &#8658; <type Object>

There are also two ways to create a new, similar object from an old one.

    my o6 = {
        name: "James",
        job: "librarian"
    };
    my o7 = o6.update({
        job: "secret agent"
    });
    say(o7);
        &#8658; {job: "secret agent", name: "James"}

    my o8 = {
        name: "Blofeld"
    };
    my o9 = o8.extend({
        job: "supervillain"
    });
    say(o9);
        &#8658; {job: "supervillain", name: "Blofeld"}

There's a way to extract an array of an object's keys. The order of the keys in
this list is not defined and may even change from call to call.

    my o10 = {
        one: 1,
        two: 2,
        three: 3
    };
    say(o10.keys().sort());
        &#8658; ["one", "three", "two"]

You can also ask whether a key exists on an object.

    my o11 = {
        foo: 42,
        bar: None
    };
    say(o11.has("foo"));
        &#8658; True
    say(o11.has("bar"));
        &#8658; True
    say(o11.has("bazinga"));
        &#8658; False

Note that the criterion is whether the *key* exists, not whether the
corresponding value is defined.

Each object has a unique ID, corresponding to references in other
languages. Comparison of objects happens by comparing keys and values,
not by reference. If you want to do a reference comparison, you need
to use the `.id` property:

    my o12 = { foo: 5 };
    my o13 = { foo: 5 };
    say(o12 == o13);
        &#8658; True
    say(o12.id == o13.id);
        &#8658; False


### Type

A type in 007's type system. All values have a type, which determines
the value's "shape": what properties it can have, and which of these
are required.

    say(type(007));
        &#8658; <type Int>
    say(type("Bond"));
        &#8658; <type Str>
    say(type({}));
        &#8658; <type Object>
    say(type(type({})));
        &#8658; <type Type>

007 comes with a number of built-in types: `NoneType`, `Bool`, `Int`,
`Str`, `Array`, `Object`, `Regex`, `Type`, `Block`, `Sub`, `Macro`,
and `Exception`.

There's also a whole hierarchy of Q types, which describe parts of
program structure.

Besides these built-in types, the programmer can also introduce new
types by using the `class` statement:

    class C {
    }
    say(type(new C {}));
        &#8658; <type C>
    say(type(C));
        &#8658; <type Type>

If you want to check whether a certain object is of a certain type,
you can use the `infix:<~~>` operator:

    say(42 ~~ Int);
        &#8658; True
    say(42 ~~ Str);
        &#8658; False

The `infix:<~~>` operator respects subtyping, so checking against a
wider type also gives a `True` result:

    my q = new Q::Literal::Int { value: 42 };
    say(q ~~ Q::Literal::Int);
        &#8658; True
    say(q ~~ Q::Literal);
        &#8658; True

    say(q ~~ Int);
        &#8658; False

If you want *exact* type matching (which isn't a very OO thing to want),
consider using infix:<==> on the respective type objects instead:

    my q = new Q::Literal::Str { value: "Bond" };
    say(type(q) == Q::Literal::Str);
        &#8658; True
    say(type(q) == Q::Literal);
        &#8658; False


### Block

A code block. This type is probably not needed, because all it's
used for is entering blocks at runtime. So, the less said about
that, the better.


### Sub

A subroutine. When you define a subroutine in 007, the value of the
name bound is a `Sub` object.

    sub agent() {
        return "Bond";
    }
    say(agent);
        &#8658; <sub agent()>

Subroutines are mostly distinguished by being *callable*, that is, they
can be called at runtime by passing some values into them.

    sub add(x, y) {
        return x + y;
    }
    say(add(2, 5));
        &#8658; 7


### Macro

A macro. When you define a macro in 007, the value of the name bound
is a macro object.

    macro agent() {
        return quasi { "Bond" };
    }
    say(agent);
        &#8658; <macro agent()>


### Exception

An exception. Represents an error condition, or some other way control
flow couldn't continue normally.




### Q::Expr

An expression; something that can be evaluated to a value.


### Q::Term

A term; a unit of parsing describing a value or an identifier. Along with
operators, what makes up expressions.


### Q::Literal

A literal; a constant value written out explicitly in the program, such as
`None`, `True`, `5`, or `"James Bond"`.

Compound values such as arrays and objects are considered terms but not
literals.

### Q::Literal::None

The `None` literal.

### Q::Literal::Bool

A boolean literal; either `True` or `False`.

### Q::Literal::Int

An integer literal; a non-negative number.

Negative numbers are not themselves considered integer literals: something
like `-5` is parsed as a `prefix:<->` containing a literal `5`.

### Q::Literal::Str

A string literal.


### Q::Identifier

An identifier; a name which identifies a storage location in the program.

Identifiers are subject to *scoping*: the same name can point to different
storage locations because they belong to different scopes.

### Q::Term::Regex

A regular expression (*regex*).

### Q::Term::Array

An array. Array terms consist of zero or more *elements*, each of which
can be an arbitrary expression.

### Q::Term::Object

An object. Object terms consist of an optional *type*, and a property list
with zero or more key/value pairs.


### Q::Property

An object property. Properties have a key and a value.


### Q::PropertyList

A property list in an object. Property lists have zero or more key/value
pairs. Keys in objects are considered unordered, but a property list has
a specified order: the order the properties occur in the program text.


### Q::Declaration

A declaration; something that introduces a name.


### Q::Trait

A trait; a piece of metadata for a routine. A trait consists of an
identifier and an expression.


### Q::TraitList

A list of zero or more traits. Each routine has a traitlist.

### Q::Term::Sub

A subroutine.


### Q::Block

A block. Blocks are used in a number of places: by routines, by
block statements, by other compound statements (such as `if` statements)
and by `quasi` terms and sub terms. Blocks are not, however, terms
in their own regard.

A block has a parameter list and a statement list, each of which can
be empty.


### Q::Prefix

A prefix operator; an operator that occurs before a term, like the
`-` in `-5`.

### Q::Prefix::Minus

A numeric negation operator.

### Q::Prefix::Not

A boolean negation operator.

### Q::Prefix::Upto

An "upto" operator; applied to a number `n` it produces an array
of values `[0, 1, ... , n-1]`.


### Q::Infix

An infix operator; something like the `+` in `2 + 2` that occurs between
two terms.

### Q::Infix::Addition

A numeric addition operator.

### Q::Infix::Addition

A numeric subtraction operator.

### Q::Infix::Multiplication

A numeric multiplication operator.

### Q::Infix::Modulo

A numeric modulo operator; produces the *remainder* left from an integer
division between two numbers. For example, `456 % 100` is `56` because the
remainder from dividing `456` by `100` is `56`.

### Q::Infix::Divisibility

A divisibility test operator. Returns `True` exactly when the remainder
operator would return `0`.

### Q::Infix::Concat

A string concatenation operator. Returns a single string that is the
result of sequentially putting two strings together.

### Q::Infix::Replicate

A string replication operator. Returns a string which consists of `n`
copies of a string.

### Q::Infix::ArrayReplicate

An array replication operator. Returns an array which consists of
the original array's elements, repeated `n` times.

### Q::Infix::Cons

A "cons" operator. Given a value and an array, returns a new
array with the value added as the first element.

### Q::Infix::Assignment

An assignment operator. Puts a value in a storage location.

### Q::Infix::Eq

A string equality test operator.

### Q::Infix::Ne

A string inequality test operator.

### Q::Infix::Gt

A string greater-than test operator.

### Q::Infix::Lt

A string less-than test operator.

### Q::Infix::Ge

A string greater-than-or-equal test operator.

### Q::Infix::Le

A string less-than-or-equal test operator.

### Q::Infix::Or

A short-circuiting disjunction operator; evaluates its right-hand
side only if the left-hand side is falsy.

### Q::Infix::DefinedOr

A short-circuiting "defined-or" operator. Evaluates its
right-hand side only if the left-hand side is `None`.

### Q::Infix::And

A short-circuiting "and" operator. Evaluates its
right-hand side only if the left-hand side is truthy.

### Q::Infix::TypeMatch

A type match operator. Checks if a value on the left-hand side has
the type on the right-hand side, including subtypes.

### Q::Infix::TypeNonMatch

A negative type match operator. Returns `True` exactly in the cases
a type match would return `False`.


### Q::Postfix

A postfix operator; something like the `[0]` in `agents[0]` that occurs
after a term.

### Q::Postfix::Index

An indexing operator; returns an array element or object property.
Arrays expect integer indices and objects expect string property names.

### Q::Postfix::Call

An invocation operator; calls a routine.

### Q::Postfix::Property

An object property operator; fetches a property out of an object.


### Q::Unquote

An unquote; allows Qtree fragments to be inserted into places in a quasi.

### Q::Unquote::Prefix

An unquote which is a prefix operator.

### Q::Unquote::Infix

An unquote which is an infix operator.

### Q::Term::Quasi

A quasi; a piece of 007 code which evaluates to that code's Qtree
representation. A way to "quote" code in a program instead of running
it directly in place. Used together with macros.

The term "quasi" comes from the fact that inside the quoted code there
can be parametric holes ("unquotes") where Qtree fragments can be
inserted. Quasiquotation is the practice of combining literal code
fragments with such parametric holes.


### Q::Parameter

A parameter. Any identifier that's declared as the input to a block
is a parameter, including subs, macros, and `if` statements.


### Q::ParameterList

A list of zero or more parameters.


### Q::ArgumentList

A list of zero or more arguments.


### Q::Statement

A statement.

### Q::Statement::My

A `my` variable declaration statement.

### Q::Statement::Constant

A `constant` declaration statement.

### Q::Statement::Expr

A statement consisting of an expression.

### Q::Statement::If

An `if` statement.

### Q::Statement::Block

A block statement.


### Q::CompUnit

A block-level statement representing a whole compilation unit.
We can read "compilation unit" here as meaning "file".

### Q::Statement::For

A `for` loop statement.

### Q::Statement::While

A `while` loop statement.

### Q::Statement::Return

A `return` statement.

### Q::Statement::Throw

A `throw` statement.

### Q::Statement::Sub

A subroutine declaration statement.

### Q::Statement::Macro

A macro declaration statement.

### Q::Statement::BEGIN

A `BEGIN` block statement.

### Q::Statement::Class

A class declaration statement.


### Q::StatementList

A list of zero or more statements. Statement lists commonly occur
directly inside blocks (or at the top level of the program, on the
compunit level). However, it's also possible for a `quasi` to
denote a statement list without any surrounding block.

### Q::Expr::StatementListAdapter

An expression which holds a statement list. Surprisingly, this never
happens in the source code text itself; because of 007's grammar, an
expression can never consist of a list of statements.

However, it can happen as a macro call (an expression) expands into
a statement list; that's when this Qtype is used.

Semantically, the contained statement list is executed normally, and
if execution evaluates the last statement and the statement turns out
to have a value (because it's an expression statement), then this
value is the value of the whole containing expression. (Note: this is
not actually true yet in the implementation. Currently a
`Q::Expr::StatementListAdapter` always returns `None` no matter what.)


