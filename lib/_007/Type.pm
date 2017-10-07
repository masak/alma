sub unique-id is export { ++$ }

constant TYPE = hash();

class _007::Type { ... }

role Typable {
    has $.type = TYPE<Type>;

    method install-type($type) {
        $!type = $type;
    }

    multi method is-a(Str $typename) {
        die "Asked to typecheck against $typename but no such type is declared"
            unless TYPE{$typename} :exists;

        return self.is-a(TYPE{$typename});
    }

    multi method is-a(_007::Type $type) {
        # We return `self` as an "interesting truthy value" so as to enable
        # renaming as part of finding out an object's true type:
        #
        #   if $ast.is-a("Q::StatementList") -> $statementlist {
        #       # ...
        #   }

        return $type (elem) $.type.type-chain && self;
    }
}

class _007::Type does Typable {
    has Str $.name;
    has $.base = TYPE<Object>;
    has @.fields;
    has Bool $.is-abstract = False;
    # XXX: $.id

    method install-base($none) {
        $!base = $none;
    }

    method type-chain() {
        my @chain;
        my $t = self;
        while $t ~~ _007::Type {
            @chain.push($t);
            $t.=base;
        }
        return @chain;
    }
}

BEGIN {
    ### ### Object
    ###
    ### The topmost type in the type system. Every value in 007 is a subtype of
    ### `Object`.
    ###
    ### XXX: mention `id` and maybe some other things
    ###
    TYPE<Object> = _007::Type.new(:name<Object>);

    ### ### Type
    ###
    ### A type in 007's type system. All values have a type, which determines
    ### the value's "shape": what properties it can have, and which of these
    ### are required.
    ###
    ###     say(type(007));         # --> `<type Int>`
    ###     say(type("Bond"));      # --> `<type Str>`
    ###     say(type({}));          # --> `<type Dict>`
    ###     say(type(type({})));    # --> `<type Type>`
    ###
    ### 007 comes with a number of built-in types: `NoneType`, `Bool`, `Int`,
    ### `Str`, `Array`, `Object`, `Regex`, `Type`, `Block`, `Sub`, `Macro`,
    ### and `Exception`.
    ###
    ### There's also a whole hierarchy of Q types, which describe parts of
    ### program structure.
    ###
    ### Besides these built-in types, the programmer can also introduce new
    ### types by using the `class` statement:
    ###
    ###     class C {       # TODO: improve this example
    ###     }
    ###     say(type(new C {}));    # --> `<type C>`
    ###     say(type(C));           # --> `<type Type>`
    ###
    ### If you want to check whether a certain object is of a certain type,
    ### you can use the `infix:<~~>` operator:
    ###
    ###     say(42 ~~ Int);         # --> `True`
    ###     say(42 ~~ Str);         # --> `False`
    ###
    ### The `infix:<~~>` operator respects subtyping, so checking against a
    ### wider type also gives a `True` result:
    ###
    ###     my q = new Q::Literal::Int { value: 42 };
    ###     say(q ~~ Q::Literal::Int);  # --> `True`
    ###     say(q ~~ Q::Literal);       # --> `True`
    ###     say(q ~~ Q);                # --> `True`
    ###     say(q ~~ Int);              # --> `False`
    ###
    ### If you want *exact* type matching (which isn't a very OO thing to want),
    ### consider using infix:<==> on the respective type objects instead:
    ###
    ###     my q = new Q::Literal::Str { value: "Bond" };
    ###     say(type(q) == Q::Literal::Str);    # --> `True`
    ###     say(type(q) == Q::Literal);         # --> `False`
    ###
    TYPE<Type> = _007::Type.new(
        :name<Type>,
        :fields[
            { :name<name>, :type<Str> },
        ],
    );
    TYPE<Type>.install-type(TYPE<Type>);

    ### ### NoneType
    ###
    ### A type with only one value, indicating the lack of a value where one was
    ### expected.
    ###
    ### It is the value variables have that haven't been assigned to:
    ###
    ###     my empty;
    ###     say(empty);         # --> `None`
    ###
    ### It is also the value returned from a subroutine that didn't explicitly
    ### return a value:
    ###
    ###     sub noreturn() {
    ###     }
    ###     say(noreturn());    # --> `None`
    ###
    ### Finally, it's found in various places in the Q hierarchy to indicate that
    ### a certain child element is not present. For example, a `my` declaration
    ### can have an assignment attached to it, in which case its `expr` property
    ### is a `Q::Expr` &mdash; but if no assignment is present, the `expr`
    ### property is the value `None`.
    ###
    ###     say(type((quasi @ Q::Statement { my x = 2 }).expr)); # --> `<type Q::Literal::Int>`
    ###     say(type((quasi @ Q::Statement { my x; }).expr));    # --> `<type NoneType>`
    ###
    ### The value `None` is falsy, stringifies to `None`, and doesn't numify.
    ###
    ###     say(!!None);        # --> `False`
    ###     say(~None);         # --> `None`
    ###     say(+None);         # <ERROR X::Type>
    ###
    ### Since `None` is often used as a default, there's an operator `infix:<//>`
    ### that evaluates its right-hand side if it finds `None` on the left:
    ###
    ###     say(None // "default");     # --> `default`
    ###     say("value" // "default");  # --> `value`
    ###
    TYPE<NoneType> = _007::Type.new(
        :name<NoneType>,
        :fields[
            { :name<name>, :type<Str> },
        ],
    );

    ### ### Bool
    ###
    ### A type with two values, `True` and `False`. These are often the result
    ### of comparisons or match operations, such as `infix:<==>` or `infix:<~~>`.
    ###
    ###     say(2 + 2 == 5);        # --> `False`
    ###     say(7 ~~ Int);          # --> `True`
    ###
    ### In 007 as in many other dynamic languages, it's not necessary to use
    ### `True` or `False` values directly in conditions such as `if` statements
    ### or `while` loops. *Any* value can be used, and there's always a way
    ### for each type to convert any of its values to a boolean value:
    ###
    ###     sub check(value) {
    ###         if value {
    ###             say("truthy");
    ###         }
    ###         else {
    ###             say("falsy");
    ###         }
    ###     }
    ###     check(None);            # --> `falsy`
    ###     check(False);           # --> `falsy`
    ###     check(0);               # --> `falsy`
    ###     check("");              # --> `falsy`
    ###     check([]);              # --> `falsy`
    ###     check({});              # --> `falsy`
    ###     # all other values are truthy
    ###     check(True);            # --> `truthy`
    ###     check(42);              # --> `truthy`
    ###     check("James");         # --> `truthy`
    ###     check([0, 0, 7]);       # --> `truthy`
    ###     check({ name: "Jim" }); # --> `truthy`
    ###
    ### Similarly, when applying the `infix:<||>` and `infix:<&&>` macros to
    ### some expressions, the result isn't coerced to a boolean value, but
    ### instead the last value that needed to be evaluated is returned as-is:
    ###
    ###     say(1 || 2);            # --> `1`
    ###     say(1 && 2);            # --> `2`
    ###     say(None && "!");       # --> `None`
    ###     say(None || "!");       # --> `!`
    ###
    TYPE<Bool> = _007::Type.new(
        :name<NoneType>,
        :fields[
            { :name<name>, :type<Str> },
        ],
    );
}

### ### Int
###
### An whole number value, such as -8, 0, or 16384.
###
### Implementations are required to represent `Int` values either as 32-bit
### or as arbitrary-precision bigints.
###
### The standard arithmetic operations are defined in the language, with the
### notable exception of division.
###
###     say(-7);                # --> `-7`
###     say(3 + 2);             # --> `5`
###     say(3 * 2);             # --> `6`
###     say(3 % 2);             # --> `1`
###
### Division is not defined, because there's no sensible thing to return for
### something like `3 / 2`. Returning `1.5` is not an option, because the
### language does not have a built-in rational or floating-point type.
### Returning `1` (truncating to an integer) would be possible but
### unsatisfactory and a source of confusion.
###
### There are also a few methods defined on `Int`:
###
###     say((-7).abs());        # --> `7`
###     say(97.chr());          # --> `a`
###
TYPE<Int> = _007::Type.new(:name<Int>);

### ### Str
###
### A piece of text. Strings are frequent whenever a program does text-based
### input/output. Since this language cares a lot about parsing, strings occur
### a lot.
###
### A number of useful operators are defined to work with strings:
###
###     say("James" ~ " Bond"); # --> `James Bond`
###     say("tap" x 3);         # --> `taptaptap`
###
### Besides which, the `Str` type also carries many useful methods:
###
###     say("x".ord());                         # --> `120`
###     say("James".chars());                   # --> `5`
###     say("Bond".uc());                       # --> `BOND`
###     say("Bond".lc());                       # --> `bond`
###     say("  hi   ".trim());                  # --> `hi`
###     say("1,2,3".split(","));                # --> `["1", "2", "3"]`
###     say([4, 5].join(":"));                  # --> `4:5`
###     say("a fool's errand".index("foo"));    # --> `2`
###     say("abcd".substr(1, 2));               # --> `bc`
###     say("abcd".prefix(3));                  # --> `abc`
###     say("abcd".suffix(2));                  # --> `cd`
###     say("James Bond".contains("s B"));      # --> `True`
###     say("James".charat(2));                 # --> `m`
###
TYPE<Str> = _007::Type.new(:name<Str>);

### ### Array
###
### A mutable sequence of values. An array contains zero or more elements,
### indexed from `0` up to `size - 1`, where `size` is the number of
### elements.
###
### Besides creating an array using an array term, one can also use the
### "upto" prefix operator, which creates an array where the elemens equal the
### indices:
###
###     say(["a", "b", "c"]);   # --> `["a", "b", "c"]`
###     say(^3);                # --> `[0, 1, 2]`
###
### Other array constructors which create entirely new arrays out of old ones
### (and leave the old ones unchanged) are concatenation and consing:
###
###     say([1, 2].concat([3, 4])); # --> `[1, 2, 3, 4]`
###     say(0 :: [0, 7]);           # --> `[0, 0, 7]`
###
### Sorting, shuffling, and reversing an array also leave the original
### array unchanged:
###
###     my a = [6, 4, 5];
###     say(a.reverse());           # --> `[5, 4, 6]`
###     say(a);                     # --> `[6, 4, 5]`
###     say(a.sort());              # --> `[4, 5, 6]`
###     say(a);                     # --> `[6, 4, 5]`
###     say(a.shuffle().sort());    # --> `[4, 5, 6]`
###     say(a);                     # --> `[6, 4, 5]`
###
### The `.size` method gives you the length (number of elements) of the
### array:
###
###     say([].size());         # --> `0`
###     say([1, 2, 3].size());  # --> `3`
###
### Some common methods use the fact that the array is mutable:
###
###     my a = [1, 2, 3];
###     a.push(4);
###     say(a);                 # --> `[1, 2, 3, 4]`
###     my x = a.pop();
###     say(x);                 # --> `4`
###     say(a);                 # --> `[1, 2, 3]`
###
###     my a = ["a", "b", "c"];
###     my y = a.shift();
###     say(y);                 # --> `a`
###     say(a);                 # --> `["b", "c"]`
###     a.unshift(y);
###     say(a);                 # --> `["a", "b", "c"]`
###
### You can also *transform* an entire array, either by mapping
### each element through a function, or by filtering each element
### through a predicate function:
###
###     my numbers = [1, 2, 3, 4, 5];
###     say(numbers.map(sub (e) { return e * 2 }));     # --> `[2, 4, 6, 8, 10]`
###     say(numbers.filter(sub (e) { return e %% 2 })); # --> `[2, 4]`
###
TYPE<Array> = _007::Type.new(:name<Array>);

### ### Dict
###
### An unordered collection of key/value pairs.
###
### The way to create a dict from scratch is to write a dict term:
###
###     my d1 = { foo: 42 };        # autoquoted key
###     my d2 = { "foo": 42 };      # string key
###     say(d1 == d2);              # --> `True`
###     my foo = 42;
###     my d3 = { foo };            # property shorthand
###     say(d1 == d3);              # --> `True`
###
### All of the above will create objects of type `Dict`.
###
###     say(type({}));              # --> `<type Dict>`
###
### Dicts have various methods on them:
###
###     my d = { foo: 1, bar: 2 };
###     say(d.size());              # --> `2`
###     say(d.keys().sort());       # --> `["bar", "foo"]`
###
TYPE<Dict> = _007::Type.new(:name<Dict>);

### ### Exception
###
### An exception. Represents an error condition, or some other way control
### flow couldn't continue normally.
###
TYPE<Exception> = _007::Type.new(
    :name<Exception>,
    :fields[
        { :name<message>, :type<Str> },
    ],
);

### ### Sub
###
### A subroutine. When you define a subroutine in 007, the value of the
### name bound is a `Sub` object.
###
###     sub agent() {
###         return "Bond";
###     }
###     say(agent);             # --> `<sub agent()>`
###
### Subroutines are mostly distinguished by being *callable*, that is, they
### can be called at runtime by passing some values into them.
###
###     sub add(x, y) {
###         return x + y;
###     }
###     say(add(2, 5));         # --> `7`
###
TYPE<Sub> = _007::Type.new(
    :name<Sub>,
    :fields[
        { :name<name>, :type<Str> },
        { :name<parameterlist>, :type<Q::ParameterList> },
        { :name<statementlist>, :type<Q::StatementList> },
        { :name<static-lexpad>, :type<Dict> },              # XXX: add an initializer
        { :name<outer-frame>, :type<Dict> },                # XXX: make optional
    ],
);

### ### Macro
###
### A macro. When you define a macro in 007, the value of the name bound
### is a macro object.
###
###     macro agent() {
###         return quasi { "Bond" };
###     }
###     say(agent);             # --> `<macro agent()>`
###
TYPE<Macro> = _007::Type.new(:name<Macro>, :base(TYPE<Sub>));

### ### Regex
###
### A regex. As a runtime value, a regex is like a black box that can be put
### to work matching strings or parts of strings. Its main purpose is
### to let us know whether the string matches the pattern described in the
### regex. In other words, it returns `True` or `False`.
###
### (Regexes are currently under development, and are hidden behind a feature
### flag for the time being: `FLAG_007_REGEX`.)
###
### A few methods are defined on regexes:
###
###     say(/"Bond"/.fullmatch("J. Bond"));     # --> `False`
###     say(/"Bond"/.search("J. Bond"));        # --> `True`
###
TYPE<Regex> = _007::Type.new(
    :name<Regex>,
    :fields[
        { :name<contents>, :type<Str> },
    ],
);

### ### Q
###
### An program element; anything that forms a node in the syntax tree
### representing a program.
###
TYPE<Q> = _007::Type.new(:name<Q>, :is-abstract);

### ### Q::Expr
###
### An expression; something that can be evaluated to a value.
###
TYPE<Q::Expr> = _007::Type.new(:name<Q::Expr>, :base(TYPE<Q>), :is-abstract);

### ### Q::Term
###
### A term; a unit of parsing describing a value or an identifier. Along with
### operators, what makes up expressions.
###
TYPE<Q::Term> = _007::Type.new(:name<Q::Term>, :base(TYPE<Q::Expr>), :is-abstract);

### ### Q::Literal
###
### A literal; a constant value written out explicitly in the program, such as
### `None`, `True`, `5`, or `"James Bond"`.
###
### Compound values such as arrays and objects are considered terms but not
### literals.
###
TYPE<Q::Literal> = _007::Type.new(:name<Q::Literal>, :base(TYPE<Q::Term>), :is-abstract);

### ### Q::Literal::None
###
### The `None` literal.
###
TYPE<Q::Literal::None> = _007::Type.new(:name<Q::Literal::None>, :base(TYPE<Q::Literal>));

### ### Q::Literal::Bool
###
### A boolean literal; either `True` or `False`.
###
TYPE<Q::Literal::Bool> = _007::Type.new(
    :name<Q::Literal::Bool>,
    :base(TYPE<Q::Literal>),
    :fields[
        { :name<value>, :type<Bool> },
    ],
);

### ### Q::Literal::Int
###
### An integer literal; a non-negative number.
###
### Negative numbers are not themselves considered integer literals: something
### like `-5` is parsed as a `prefix:<->` containing a literal `5`.
###
TYPE<Q::Literal::Int> = _007::Type.new(
    :name<Q::Literal::Int>,
    :base(TYPE<Q::Literal>),
    :fields[
        { :name<value>, :type<Int> },
    ],
);

### ### Q::Literal::Str
###
### A string literal.
###
TYPE<Q::Literal::Str> = _007::Type.new(
    :name<Q::Literal::Str>,
    :base(TYPE<Q::Literal>),
    :fields[
        { :name<value>, :type<Str> },
    ],
);

### ### Q::Identifier
###
### An identifier; a name which identifies a storage location in the program.
###
### Identifiers are subject to *scoping*: the same name can point to different
### storage locations because they belong to different scopes.
###
TYPE<Q::Identifier> = _007::Type.new(
    :name<Q::Identifier>,
    :base(TYPE<Q::Term>),
    :fields[
        { :name<name>, :type<Str> },
        { :name<frame>, :type("Dict"), :optional },
    ],
);

### ### Q::Term::Regex
###
### A regular expression (*regex*).
###
TYPE<Q::Term::Regex> = _007::Type.new(
    :name<Q::Term::Regex>,
    :base(TYPE<Q::Term>),
    :fields[
        { :name<contents>, :type<Str> },
    ],
);

### ### Q::Term::Array
###
### An array. Array terms consist of zero or more *elements*, each of which
### can be an arbitrary expression.
###
TYPE<Q::Term::Array> = _007::Type.new(
    :name<Q::Term::Array>,
    :base(TYPE<Q::Term>),
    :fields[
        { :name<elements>, :type<Array> },
    ],
);

### ### Q::Term::Dict
###
### A dictionary. Dict terms consist of zero or more *properties*, each of which
### consists of a key and a value.
###
TYPE<Q::Term::Dict> = _007::Type.new(
    :name<Q::Term::Dict>,
    :base(TYPE<Q::Term>),
    :fields[
        { :name<propertylist>, :type<Q::PropertyList> },
    ],
);

### ### Q::Term::Object
###
### An object. Object terms consist of an optional *type*, and a property list
### with zero or more key/value pairs.
###
TYPE<Q::Term::Object> = _007::Type.new(
    :name<Q::Term::Object>,
    :base(TYPE<Q::Term>),
    :fields[
        { :name<type>, :type<Q::Identifier> },
        { :name<propertylist>, :type<Q::PropertyList> },
    ],
);

### ### Q::Property
###
### An object property. Properties have a key and a value.
###
TYPE<Q::Property> = _007::Type.new(
    :name<Q::Property>,
    :base(TYPE<Q>),
    :fields[
        { :name<key>, :type<Str> },
        { :name<value>, :type<Q::Expr> },
    ],
);

### ### Q::PropertyList
###
### A property list in an object. Property lists have zero or more key/value
### pairs. Keys in objects are considered unordered, but a property list has
### a specified order: the order the properties occur in the program text.
###
TYPE<Q::PropertyList> = _007::Type.new(
    :name<Q::PropertyList>,
    :base(TYPE<Q>),
    :fields[
        { :name<properties>, :type<Array> },
    ],
);

### ### Q::Trait
###
### A trait; a piece of metadata for a routine. A trait consists of an
### identifier and an expression.
###
TYPE<Q::Trait> = _007::Type.new(
    :name<Q::Trait>,
    :base(TYPE<Q>),
    :fields[
        { :name<identifier>, :type<Q::Identifier> },
        { :name<expr>, :type<Q::Expr> },
    ],
);

### ### Q::TraitList
###
### A list of zero or more traits. Each routine has a traitlist.
###
TYPE<Q::TraitList> = _007::Type.new(
    :name<Q::TraitList>,
    :base(TYPE<Q>),
    :fields[
        { :name<traits>, :type<Array> },
    ],
);

### ### Q::Term::Sub
###
### A subroutine.
###
TYPE<Q::Term::Sub> = _007::Type.new(
    :name<Q::Term::Sub>,
    :base(TYPE<Q::Term>),
    :fields[
        { :name<identifier>, :type("Q::Identifier | NoneType") },           # XXX: make optional
        { :name<traitlist>, :type<Q::TraitList> },                          # XXX: give initializer
        { :name<block>, :type<Q::Block> },
    ],
);

### ### Q::Block
###
### A block. Blocks are used in a number of places: by routines, by
### block statements, by other compound statements (such as `if` statements)
### and by `quasi` terms and sub terms. Blocks are not, however, terms
### in their own regard.
###
### A block has a parameter list and a statement list, each of which can
### be empty.
###
TYPE<Q::Block> = _007::Type.new(
    :name<Q::Block>,
    :base(TYPE<Q>),
    :fields[
        { :name<parameterlist>, :type<Q::ParameterList> },
        { :name<statementlist>, :type<Q::StatementList> },
        { :name<static-lexpad>, :type("Dict | NoneType") },                         # XXX: make optional
    ],
);

### ### Q::Prefix
###
### A prefix operator; an operator that occurs before a term, like the
### `-` in `-5`.
###
TYPE<Q::Prefix> = _007::Type.new(
    :name<Q::Prefix>,
    :base(TYPE<Q::Expr>),
    :fields[
        { :name<identifier>, :type("Q::Identifier | NoneType") },
        { :name<operand>, :type("Q::Expr | NoneType") },
    ],
);

### ### Q::Prefix::Str
###
### A stringification operator.
###
TYPE<Q::Prefix::Str> = _007::Type.new(:name<Q::Prefix::Str>, :base(TYPE<Q::Prefix>));

### ### Q::Prefix::Plus
###
### A numification operator.
###
TYPE<Q::Prefix::Plus> = _007::Type.new(:name<Q::Prefix::Plus>, :base(TYPE<Q::Prefix>));

### ### Q::Prefix::Minus
###
### A numeric negation operator.
###
TYPE<Q::Prefix::Minus> = _007::Type.new(:name<Q::Prefix::Minus>, :base(TYPE<Q::Prefix>));

### ### Q::Prefix::So
###
### A boolification operator.
###
TYPE<Q::Prefix::So> = _007::Type.new(:name<Q::Prefix::So>, :base(TYPE<Q::Prefix>));

### ### Q::Prefix::Not
###
### A boolean negation operator.
###
TYPE<Q::Prefix::Not> = _007::Type.new(:name<Q::Prefix::Not>, :base(TYPE<Q::Prefix>));

### ### Q::Prefix::Upto
###
### An "upto" operator; applied to a number `n` it produces an array
### of values `[0, 1, ..., n-1]`.
###
TYPE<Q::Prefix::Upto> = _007::Type.new(:name<Q::Prefix::Upto>, :base(TYPE<Q::Prefix>));

### ### Q::Infix
###
### An infix operator; something like the `+` in `2 + 2` that occurs between
### two terms.
###
TYPE<Q::Infix> = _007::Type.new(
    :name<Q::Infix>,
    :base(TYPE<Q::Expr>),
    :fields[
        { :name<identifier>, :type("Q::Identifier | NoneType") },
        { :name<lhs>, :type("Q::Expr | NoneType") },
        { :name<rhs>, :type("Q::Expr | NoneType") },
    ],
);

### ### Q::Infix::Addition
###
### A numeric addition operator.
###
TYPE<Q::Infix::Addition> = _007::Type.new(:name<Q::Infix::Addition>, :base(TYPE<Q::Infix>));

### ### Q::Infix::Subtraction
###
### A numeric subtraction operator.
###
TYPE<Q::Infix::Subtraction> = _007::Type.new(:name<Q::Infix::Subtraction>, :base(TYPE<Q::Infix>));

### ### Q::Infix::Multiplication
###
### A numeric multiplication operator.
###
TYPE<Q::Infix::Multiplication> = _007::Type.new(:name<Q::Infix::Multiplication>, :base(TYPE<Q::Infix>));

### ### Q::Infix::Modulo
###
### A numeric modulo operator; produces the *remainder* left from an integer
### division between two numbers. For example, `456 % 100` is `56` because the
### remainder from dividing `456` by `100` is `56`.
###
TYPE<Q::Infix::Modulo> = _007::Type.new(:name<Q::Infix::Modulo>, :base(TYPE<Q::Infix>));

### ### Q::Infix::Divisibility
###
### A divisibility test operator. Returns `True` exactly when the remainder
### operator would return `0`.
###
TYPE<Q::Infix::Divisibility> = _007::Type.new(:name<Q::Infix::Divisibility>, :base(TYPE<Q::Infix>));

### ### Q::Infix::Concat
###
### A string concatenation operator. Returns a single string that is the
### result of sequentially putting two strings together.
###
TYPE<Q::Infix::Concat> = _007::Type.new(:name<Q::Infix::Concat>, :base(TYPE<Q::Infix>));

### ### Q::Infix::Replicate
###
### A string replication operator. Returns a string which consists of `n`
### copies of a string.
###
TYPE<Q::Infix::Replicate> = _007::Type.new(:name<Q::Infix::Replicate>, :base(TYPE<Q::Infix>));

### ### Q::Infix::ArrayReplicate
###
### An array replication operator. Returns an array which consists of
### the original array's elements, repeated `n` times.
###
TYPE<Q::Infix::ArrayReplicate> = _007::Type.new(:name<Q::Infix::ArrayReplicate>, :base(TYPE<Q::Infix>));

### ### Q::Infix::Cons
###
### A "cons" operator. Given a value and an array, returns a new
### array with the value added as the first element.
###
TYPE<Q::Infix::Cons> = _007::Type.new(:name<Q::Infix::Cons>, :base(TYPE<Q::Infix>));

### ### Q::Infix::Assignment
###
### An assignment operator. Puts a value in a storage location.
###
TYPE<Q::Infix::Assignment> = _007::Type.new(:name<Q::Infix::Assignment>, :base(TYPE<Q::Infix>));

### ### Q::Infix::Eq
###
### An equality test operator.
###
TYPE<Q::Infix::Eq> = _007::Type.new(:name<Q::Infix::Eq>, :base(TYPE<Q::Infix>));

### ### Q::Infix::Ne
###
### An inequality test operator.
###
TYPE<Q::Infix::Ne> = _007::Type.new(:name<Q::Infix::Ne>, :base(TYPE<Q::Infix>));

### ### Q::Infix::Gt
###
### A greater-than test operator.
###
TYPE<Q::Infix::Gt> = _007::Type.new(:name<Q::Infix::Gt>, :base(TYPE<Q::Infix>));

### ### Q::Infix::Lt
###
### A less-than test operator.
###
TYPE<Q::Infix::Lt> = _007::Type.new(:name<Q::Infix::Lt>, :base(TYPE<Q::Infix>));

### ### Q::Infix::Ge
###
### A greater-than-or-equal test operator.
###
TYPE<Q::Infix::Ge> = _007::Type.new(:name<Q::Infix::Ge>, :base(TYPE<Q::Infix>));

### ### Q::Infix::Le
###
### A less-than-or-equal test operator.
###
TYPE<Q::Infix::Le> = _007::Type.new(:name<Q::Infix::Le>, :base(TYPE<Q::Infix>));

### ### Q::Infix::Or
###
### A short-circuiting disjunction operator; evaluates its right-hand
### side only if the left-hand side is falsy.
###
TYPE<Q::Infix::Or> = _007::Type.new(:name<Q::Infix::Or>, :base(TYPE<Q::Infix>));

### ### Q::Infix::DefinedOr
###
### A short-circuiting "defined-or" operator. Evaluates its
### right-hand side only if the left-hand side is `None`.
###
TYPE<Q::Infix::DefinedOr> = _007::Type.new(:name<Q::Infix::DefinedOr>, :base(TYPE<Q::Infix>));

### ### Q::Infix::And
###
### A short-circuiting "and" operator. Evaluates its
### right-hand side only if the left-hand side is truthy.
###
TYPE<Q::Infix::And> = _007::Type.new(:name<Q::Infix::And>, :base(TYPE<Q::Infix>));

### ### Q::Infix::TypeMatch
###
### A type match operator. Checks if a value on the left-hand side has
### the type on the right-hand side, including subtypes.
###
TYPE<Q::Infix::TypeMatch> = _007::Type.new(:name<Q::Infix::TypeMatch>, :base(TYPE<Q::Infix>));

### ### Q::Infix::TypeNonMatch
###
### A negative type match operator. Returns `True` exactly in the cases
### a type match would return `False`.
###
TYPE<Q::Infix::TypeNonMatch> = _007::Type.new(:name<Q::Infix::TypeNonMatch>, :base(TYPE<Q::Infix>));

### ### Q::Postfix
###
### A postfix operator; something like the `[0]` in `agents[0]` that occurs
### after a term.
###
TYPE<Q::Postfix> = _007::Type.new(
    :name<Q::Postfix>,
    :base(TYPE<Q::Expr>),
    :fields[
        { :name<identifier>, :type("Q::Identifier | NoneType") },
        { :name<operand>, :type("Q::Expr | Q::Unquote | NoneType") },      # XXX: Q::Unquote needs mulling over
    ],
);

### ### Q::Postfix::Index
###
### An indexing operator; returns an array element or object property.
### Arrays expect integer indices and objects expect string property names.
###
TYPE<Q::Postfix::Index> = _007::Type.new(
    :name<Q::Postfix::Index>,
    :base(TYPE<Q::Postfix>),
    :fields[
        { :name<index>, :type("Q::Expr | NoneType") },
    ],
);

### ### Q::Postfix::Call
###
### An invocation operator; calls a routine.
###
TYPE<Q::Postfix::Call> = _007::Type.new(
    :name<Q::Postfix::Call>,
    :base(TYPE<Q::Postfix>),
    :fields[
        { :name<argumentlist>, :type("Q::ArgumentList | Q::Unquote | NoneType") },  # XXX: Q::Unquote needs mulling over
    ],
);

### ### Q::Postfix::Property
###
### An object property operator; fetches a property out of an object.
###
TYPE<Q::Postfix::Property> = _007::Type.new(
    :name<Q::Postfix::Property>,
    :base(TYPE<Q::Postfix>),
    :fields[
        { :name<property>, :type("Q::Expr | NoneType") },
    ],
);

### ### Q::Unquote
###
### An unquote; allows Qtree fragments to be inserted into places in a quasi.
###
TYPE<Q::Unquote> = _007::Type.new(
    :name<Q::Unquote>,
    :base(TYPE<Q>),
    :fields[
        { :name<qtype>, :type<Type> },
        { :name<expr>, :type<Q::Expr> },
    ],
);

### ### Q::Unquote::Prefix
###
### An unquote which is a prefix operator.
###
TYPE<Q::Unquote::Prefix> = _007::Type.new(
    :name<Q::Unquote::Prefix>,
    :base(TYPE<Q::Unquote>),
    :fields[
        { :name<operand>, :type<Q::Expr> },
    ],
);

### ### Q::Unquote::Infix
###
### An unquote which is an infix operator.
###
TYPE<Q::Unquote::Infix> = _007::Type.new(
    :name<Q::Unquote::Infix>,
    :base(TYPE<Q::Unquote>),
    :fields[
        { :name<lhs>, :type<Q::Expr> },
        { :name<rhs>, :type<Q::Expr> },
    ],
);

### ### Q::Term::Quasi
###
### A quasi; a piece of 007 code which evaluates to that code's Qtree
### representation. A way to "quote" code in a program instead of running
### it directly in place. Used together with macros.
###
### The term "quasi" comes from the fact that inside the quoted code there
### can be parametric holes ("unquotes") where Qtree fragments can be
### inserted. Quasiquotation is the practice of combining literal code
### fragments with such parametric holes.
###
TYPE<Q::Term::Quasi> = _007::Type.new(
    :name<Q::Term::Quasi>,
    :base(TYPE<Q::Term>),
    :fields[
        { :name<qtype>, :type<Str> },
        { :name<contents>, :type<Q> },
    ],
);

### ### Q::Parameter
###
### A parameter. Any identifier that's declared as the input to a block
### is a parameter, including subs, macros, and `if` statements.
###
TYPE<Q::Parameter> = _007::Type.new(
    :name<Q::Parameter>,
    :base(TYPE<Q>),
    :fields[
        { :name<identifier>, :type<Q::Identifier> },
    ],
);

### ### Q::ParameterList
###
### A list of zero or more parameters.
###
TYPE<Q::ParameterList> = _007::Type.new(
    :name<Q::ParameterList>,
    :base(TYPE<Q>),
    :fields[
        { :name<parameters>, :type<Array> },
    ],
);

### ### Q::ArgumentList
###
### A list of zero or more arguments.
###
TYPE<Q::ArgumentList> = _007::Type.new(
    :name<Q::ArgumentList>,
    :base(TYPE<Q>),
    :fields[
        { :name<arguments>, :type<Array> },
    ],
);

### ### Q::Statement
###
### A statement.
###
TYPE<Q::Statement> = _007::Type.new(:name<Q::Statement>, :base(TYPE<Q>), :is-abstract);

### ### Q::Statement::My
###
### A `my` variable declaration statement.
###
TYPE<Q::Statement::My> = _007::Type.new(
    :name<Q::Statement::My>,
    :base(TYPE<Q::Statement>),
    :fields[
        { :name<identifier>, :type<Q::Identifier> },
        { :name<expr>, :type("Q::Expr | NoneType") },                     # XXX: make optional
    ],
);

### ### Q::Statement::Constant
###
### A `constant` declaration statement.
###
TYPE<Q::Statement::Constant> = _007::Type.new(
    :name<Q::Statement::Constant>,
    :base(TYPE<Q::Statement>),
    :fields[
        { :name<identifier>, :type<Q::Identifier> },
        { :name<expr>, :type<Q::Expr> },
    ],
);

### ### Q::Statement::Expr
###
### A statement consisting of an expression.
###
TYPE<Q::Statement::Expr> = _007::Type.new(
    :name<Q::Statement::Expr>,
    :base(TYPE<Q::Statement>),
    :fields[
        { :name<expr>, :type<Q::Expr> },
    ],
);

### ### Q::Statement::If
###
### An `if` statement.
###
TYPE<Q::Statement::If> = _007::Type.new(
    :name<Q::Statement::If>,
    :base(TYPE<Q::Statement>),
    :fields[
        { :name<expr>, :type<Q::Expr> },
        { :name<block>, :type<Q::Block> },
        { :name<else>, :type("Q::Block | Q::Statement::If | NoneType") },
    ],
);

### ### Q::Statement::Block
###
### A block statement.
###
TYPE<Q::Statement::Block> = _007::Type.new(
    :name<Q::Statement::Block>,
    :base(TYPE<Q::Statement>),
    :fields[
        { :name<block>, :type<Q::Block> },
    ],
);

### ### Q::CompUnit
###
### A block-level statement representing a whole compilation unit.
### We can read "compilation unit" here as meaning "file".
###
TYPE<Q::CompUnit> = _007::Type.new(:name<Q::CompUnit>, :base(TYPE<Q::Statement::Block>));

### ### Q::Statement::For
###
### A `for` loop statement.
###
TYPE<Q::Statement::For> = _007::Type.new(
    :name<Q::Statement::For>,
    :base(TYPE<Q::Statement>),
    :fields[
        { :name<expr>, :type<Q::Expr> },
        { :name<block>, :type<Q::Block> },
    ],
);

### ### Q::Statement::While
###
### A `while` loop statement.
###
TYPE<Q::Statement::While> = _007::Type.new(
    :name<Q::Statement::While>,
    :base(TYPE<Q::Statement>),
    :fields[
        { :name<expr>, :type<Q::Expr> },
        { :name<block>, :type<Q::Block> },
    ],
);

### ### Q::Statement::Return
###
### A `return` statement.
###
TYPE<Q::Statement::Return> = _007::Type.new(
    :name<Q::Statement::Return>,
    :base(TYPE<Q::Statement>),
    :fields[
        { :name<expr>, :type("Q::Expr | NoneType") },                                # XXX: make optional
    ],
);

### ### Q::Statement::Throw
###
### A `throw` statement.
###
TYPE<Q::Statement::Throw> = _007::Type.new(
    :name<Q::Statement::Throw>,
    :base(TYPE<Q::Statement>),
    :fields[
        { :name<expr>, :type<Q::Expr> },
    ],
);

### ### Q::Statement::Sub
###
### A subroutine declaration statement.
###
TYPE<Q::Statement::Sub> = _007::Type.new(
    :name<Q::Statement::Sub>,
    :base(TYPE<Q::Statement>),
    :fields[
        { :name<identifier>, :type<Q::Identifier> },
        { :name<traitlist>, :type<Q::TraitList> },
        { :name<block>, :type<Q::Block> },
    ],
);

### ### Q::Statement::Macro
###
### A macro declaration statement.
###
TYPE<Q::Statement::Macro> = _007::Type.new(
    :name<Q::Statement::Macro>,
    :base(TYPE<Q::Statement>),
    :fields[
        { :name<identifier>, :type<Q::Identifier> },
        { :name<traitlist>, :type<Q::TraitList> },
        { :name<block>, :type<Q::Block> },
    ],
);

### ### Q::Statement::BEGIN
###
### A `BEGIN` block statement.
###
TYPE<Q::Statement::BEGIN> = _007::Type.new(
    :name<Q::Statement::BEGIN>,
    :base(TYPE<Q::Statement>),
    :fields[
        { :name<block>, :type<Q::Block> },
    ],
);

### ### Q::Statement::Class
###
### A class declaration statement.
###
TYPE<Q::Statement::Class> = _007::Type.new(
    :name<Q::Statement::Class>,
    :base(TYPE<Q::Statement>),
    :fields[
        { :name<block>, :type<Q::Block> },
    ],
);

### ### Q::StatementList
###
### A list of zero or more statements. Statement lists commonly occur
### directly inside blocks (or at the top level of the program, on the
### compunit level). However, it's also possible for a `quasi` to
### denote a statement list without any surrounding block.
###
TYPE<Q::StatementList> = _007::Type.new(
    :name<Q::StatementList>,
    :base(TYPE<Q>),
    :fields[
        { :name<statements>, :type<Array> },
    ],
);

### ### Q::Expr::StatementListAdapter
###
### An expression which holds a statement list. Surprisingly, this never
### happens in the source code text itself; because of 007's grammar, an
### expression can never consist of a list of statements.
###
### However, it can happen as a macro call (an expression) expands into
### a statement list; that's when this Qtype is used.
###
### Semantically, the contained statement list is executed normally, and
### if execution evaluates the last statement and the statement turns out
### to have a value (because it's an expression statement), then this
### value is the value of the whole containing expression.
###
TYPE<Q::Expr::StatementListAdapter> = _007::Type.new(
    :name<Q::Expr::StatementListAdapter>,
    :base(TYPE<Q::Expr>),
    :fields[
        { :name<statementlist>, :type<Q::StatementList> },
    ],
);
