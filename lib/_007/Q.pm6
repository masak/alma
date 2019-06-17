use _007::Val;

class X::Control::Return is Exception {
    has $.frame;
    has $.value;
}

class X::Subscript::TooLarge is Exception {
    has $.value;
    has $.length;

    method message() { "Subscript ($.value) too large (array length $.length)" }
}

class X::Subscript::NonInteger is Exception {
}

class X::Subscript::NonString is Exception {
}

class X::ParameterMismatch is Exception {
    has $.type;
    has $.paramcount;
    has $.argcount;

    method message {
        "$.type with $.paramcount parameters called with $.argcount arguments"
    }
}

class X::Property::NotFound is Exception {
    has $.propname;
    has $.type;

    method message {
        "Property '$.propname' not found on object of type $.type"
    }
}

class X::Associativity::Conflict is Exception {
    method message { "The operator already has a defined associativity" }
}

class X::Regex::InvalidMatchType is Exception {
    method message { "A regex can only match strings" }
}

class X::TypeCheck::HeterogeneousArray is Exception {
    has $.operation;
    has $.types;

    method message {
        "Can't do '$.operation' on heterogeneous array, types found: {$.types.sort}"
    }
}

class X::_007::RuntimeException is Exception {
    has $.msg;

    method message {
        $.msg.Str;
    }
}

sub aname($attr) { $attr.name.substr(2) }
sub avalue($attr, $obj) { $attr.get_value($obj) }

### ### Q
###
### An program element; anything that forms a node in the syntax tree
### representing a program.
###
role Q {
    method Str {
        my %*stringification-seen;
        Helper::Str(self);
    }

    method quoted-Str {
        self.Str
    }

    method truthy {
        True
    }

    method attributes {
        sub find($aname) { self.^attributes.first({ $aname eq aname($_) }) }

        self.can("attribute-order")
            ?? self.attribute-order.map({ find($_) })
            !! self.^attributes;
    }
}

### ### Q::Identifier
###
### An identifier; a name in code.
###
class Q::Identifier does Q {
    has Val::Str $.name;

    method attribute-order { <name> }
}

### ### Q::Expr
###
### An expression; something that can be evaluated to a value.
###
role Q::Expr does Q {
    method eval($runtime) { ... }
}

### ### Q::Term
###
### A term; a unit of parsing describing a value or an identifier. Along with
### operators, what makes up expressions.
###
role Q::Term does Q::Expr {
}

### ### Q::Literal
###
### A literal; a constant value written out explicitly in the program, such as
### `none`, `true`, `5`, or `"James Bond"`.
###
### Compound values such as arrays and objects are considered terms but not
### literals.
###
role Q::Literal does Q::Term {
}

### ### Q::Literal::None
###
### The `none` literal.
###
class Q::Literal::None does Q::Literal {
    method eval($) { NONE }
}

### ### Q::Literal::Bool
###
### A boolean literal; either `true` or `false`.
###
class Q::Literal::Bool does Q::Literal {
    has Val::Bool $.value;

    method eval($) { $.value }
}

### ### Q::Literal::Int
###
### An integer literal; a non-negative number.
###
### Negative numbers are not themselves considered integer literals: something
### like `-5` is parsed as a `prefix:<->` containing a literal `5`.
###
class Q::Literal::Int does Q::Literal {
    has Val::Int $.value;

    method eval($) { $.value }
}

### ### Q::Literal::Str
###
### A string literal.
###
class Q::Literal::Str does Q::Literal {
    has Val::Str $.value;

    method eval($) { $.value }
}

### ### Q::Term::Identifier
###
### An identifier; a name which identifies a storage location in the program.
###
### Identifiers in expressions are subject to *scoping*: the same name can
### point to different storage locations because they belong to different scopes.
### The same name in the same scope might even point to different storage
### locations at different times when accessed from different call frames.
###
class Q::Term::Identifier is Q::Identifier does Q::Term {
    method eval($runtime) {
        return $runtime.get-var($.name.value);
    }

    method put-value($value, $runtime) {
        $runtime.put-var(self, $value);
    }
}

### ### Q::Term::Identifier::Direct
###
### A direct identifier; a name which directly identifies a storage location
### in the program.
###
class Q::Term::Identifier::Direct is Q::Term::Identifier {
    has Val::Dict $.frame;

    method eval($runtime) {
        return $runtime.get-direct($.frame, $.name.value);
    }

    method put-value($value, $runtime) {
        $runtime.put-direct($.frame, $.name.value, $value);
    }
}

### ### Q::Regex::Fragment
###
### The parent role to all regex fragment types.
###
role Q::Regex::Fragment {
}

### ### Q::Regex::Str
###
### A regex fragment for a simple string.
### Corresponds to the `"..."` regex syntax.
###
class Q::Regex::Str does Q::Regex::Fragment {
    has Val::Str $.contents;
}

### ### Q::Regex::Identifier
###
### A regex fragment using a variable from the program.
### Corresponds to an identifier in a regex.
###
class Q::Regex::Identifier does Q::Regex::Fragment {
    has Q::Identifier $.identifier;

    method eval($runtime) {
        # XXX check that the value is a string
        return $.identifier.eval($runtime);
    }
}

### ### Q::Regex::Call
###
### A regex fragment calling to another regex.
### Corresponds to the `<...>` regex syntax.
###
class Q::Regex::Call does Q::Regex::Fragment {
    has Q::Identifier $.identifier;
}

### ### Q::Regex::Alternation
###
### An alternation between fragments.
###
class Q::Regex::Alternation does Q::Regex::Fragment {
    has Q::Regex::Fragment @.alternatives;
}

### ### Q::Regex::Group
###
### A regex fragment containing several other fragments.
### Corresponds to the "[" ... "]" regex syntax.
###
class Q::Regex::Group does Q::Regex::Fragment {
    has Q::Regex::Fragment @.fragments;
}

### ### Q::Regex::OneOrMore
###
### A regex fragment representing the "+" quantifier.
###
class Q::Regex::OneOrMore does Q::Regex::Fragment {
    has Q::Regex::Fragment $.fragment;
}

### ### Q::Regex::ZeroOrMore
###
### A regex fragment representing the "*" quantifier.
###
class Q::Regex::ZeroOrMore does Q::Regex::Fragment {
    has Q::Regex::Fragment $.fragment;
}

### ### Q::Regex::ZeroOrOne
###
### A regex fragment representing the "?" quantifier.
###
class Q::Regex::ZeroOrOne does Q::Regex::Fragment {
    has Q::Regex::Fragment $.fragment;
}

### ### Q::Term::Regex
###
### A regular expression (*regex*).
###
class Q::Term::Regex does Q::Term {
    has Q::Regex::Fragment $.contents;

    method eval($runtime) {
        Val::Regex.new(:$.contents);
    }
}

### ### Q::Term::Array
###
### An array. Array terms consist of zero or more *elements*, each of which
### can be an arbitrary expression.
###
class Q::Term::Array does Q::Term {
    has Val::Array $.elements;

    method eval($runtime) {
        Val::Array.new(:elements($.elements.elements.map(*.eval($runtime))));
    }
}

### ### Q::Term::Object
###
### An object.
###
class Q::Term::Object does Q::Term {
    has Val::Type $.type;
    has $.propertylist;

    method eval($runtime) {
        return $.type.create(
            $.propertylist.properties.elements.map({.key.value => .value.eval($runtime)})
        );
    }
}

### ### Q::Term::Dict
###
### A dict. Dict terms consist of an entry list with zero or more key/value pairs.
###
class Q::Term::Dict does Q::Term {
    has $.propertylist;

    method eval($runtime) {
        return Val::Dict.new(:properties(
            $.propertylist.properties.elements.map({.key.value => .value.eval($runtime)})
        ));
    }
}

### ### Q::Property
###
### An object property. Properties have a key and a value.
###
class Q::Property does Q {
    has Val::Str $.key;
    has $.value;
}

### ### Q::PropertyList
###
### A property list in an object. Property lists have zero or more key/value
### pairs. Keys in objects are considered unordered, but a property list has
### a specified order: the order the properties occur in the program text.
###
class Q::PropertyList does Q {
    has Val::Array $.properties .= new;
}

### ### Q::Declaration
###
### A declaration; something that introduces a name.
###
role Q::Declaration {
    method is-assignable { False }
}

### ### Q::Term::Func
###
### A subroutine.
###
class Q::Term::Func does Q::Term does Q::Declaration {
    has $.identifier;
    has $.block;

    method attribute-order { <identifier block> }

    method eval($runtime) {
        my $name = $.identifier ~~ Val::None
            ?? Val::Str.new(:value(""))
            !! $.identifier.name;
        return Val::Func.new(
            :$name,
            :parameterlist($.block.parameterlist),
            :statementlist($.block.statementlist),
            :static-lexpad($.block.static-lexpad),
            :outer-frame($runtime.current-frame),
        );
    }
}

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
class Q::Block does Q {
    has $.parameterlist;
    has $.statementlist;
    has Val::Dict $.static-lexpad is rw = Val::Dict.new;

    method attribute-order { <parameterlist statementlist> }
}

### ### Q::Prefix
###
### A prefix operator; an operator that occurs before a term, like the
### `-` in `-5`.
###
class Q::Prefix does Q::Expr {
    has $.identifier;
    has $.operand;

    method attribute-order { <identifier operand> }

    method eval($runtime) {
        my $e = $.operand.eval($runtime);
        my $c = $.identifier.eval($runtime);
        return $runtime.call($c, [$e]);
    }
}

### ### Q::Infix
###
### An infix operator; something like the `+` in `2 + 2` that occurs between
### two terms.
###
class Q::Infix does Q::Expr {
    has $.identifier;
    has $.lhs;
    has $.rhs;

    method attribute-order { <identifier lhs rhs> }

    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        my $r = $.rhs.eval($runtime);
        my $c = $.identifier.eval($runtime);
        return $runtime.call($c, [$l, $r]);
    }
}

### ### Q::Infix::Assignment
###
### An assignment operator. Puts a value in a storage location.
###
class Q::Infix::Assignment is Q::Infix {
    method eval($runtime) {
        my $value = $.rhs.eval($runtime);
        $.lhs.put-value($value, $runtime);
        return $value;
    }
}

### ### Q::Infix::Or
###
### A short-circuiting disjunction operator; evaluates its right-hand
### side only if the left-hand side is falsy.
###
class Q::Infix::Or is Q::Infix {
    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        return $l.truthy
            ?? $l
            !! $.rhs.eval($runtime);
    }
}

### ### Q::Infix::DefinedOr
###
### A short-circuiting "defined-or" operator. Evaluates its
### right-hand side only if the left-hand side is `none`.
###
class Q::Infix::DefinedOr is Q::Infix {
    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        return $l !~~ Val::None
            ?? $l
            !! $.rhs.eval($runtime);
    }
}

### ### Q::Infix::And
###
### A short-circuiting "and" operator. Evaluates its
### right-hand side only if the left-hand side is truthy.
###
class Q::Infix::And is Q::Infix {
    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        return !$l.truthy
            ?? $l
            !! $.rhs.eval($runtime);
    }
}

### ### Q::Postfix
###
### A postfix operator; something like the `[0]` in `agents[0]` that occurs
### after a term.
###
class Q::Postfix does Q::Expr {
    has $.identifier;
    has $.operand;

    method attribute-order { <identifier operand> }

    method eval($runtime) {
        my $e = $.operand.eval($runtime);
        my $c = $.identifier.eval($runtime);
        return $runtime.call($c, [$e]);
    }
}

### ### Q::Postfix::Index
###
### An indexing operator; returns an array element or object property.
### Arrays expect integer indices and objects expect string property names.
###
class Q::Postfix::Index is Q::Postfix {
    has $.index;

    method attribute-order { <identifier operand index> }

    method eval($runtime) {
        given $.operand.eval($runtime) {
            when Val::Array {
                my $index = $.index.eval($runtime);
                die X::Subscript::NonInteger.new
                    if $index !~~ Val::Int;
                die X::Subscript::TooLarge.new(:value($index.value), :length(+.elements))
                    if $index.value >= .elements;
                die X::Subscript::Negative.new(:$index, :type([]))
                    if $index.value < 0;
                return .elements[$index.value];
            }
            when Val::Dict {
                my $property = $.index.eval($runtime);
                die X::Subscript::NonString.new
                    if $property !~~ Val::Str;
                my $propname = $property.value;
                die X::Property::NotFound.new(:$propname, :type(Val::Dict))
                    if .properties{$propname} :!exists;
                return .properties{$propname};
            }
            when Val::Func | Q {
                my $property = $.index.eval($runtime);
                die X::Subscript::NonString.new
                    if $property !~~ Val::Str;
                my $propname = $property.value;
                return $runtime.property($_, $propname);
            }
            die X::TypeCheck.new(:operation<indexing>, :got($_), :expected(Val::Array));
        }
    }

    method put-value($value, $runtime) {
        given $.operand.eval($runtime) {
            when Val::Array {
                my $index = $.index.eval($runtime);
                die X::Subscript::NonInteger.new
                    if $index !~~ Val::Int;
                die X::Subscript::TooLarge.new(:value($index.value), :length(+.elements))
                    if $index.value >= .elements;
                die X::Subscript::Negative.new(:$index, :type([]))
                    if $index.value < 0;
                .elements[$index.value] = $value;
            }
            when Val::Dict | Q {
                my $property = $.index.eval($runtime);
                die X::Subscript::NonString.new
                    if $property !~~ Val::Str;
                my $propname = $property.value;
                $runtime.put-property($_, $propname, $value);
            }
            die X::TypeCheck.new(:operation<indexing>, :got($_), :expected(Val::Array));
        }
    }
}

### ### Q::Postfix::Call
###
### An invocation operator; calls a routine.
###
class Q::Postfix::Call is Q::Postfix {
    has $.argumentlist;

    method attribute-order { <identifier operand argumentlist> }

    method eval($runtime) {
        my $c = $.operand.eval($runtime);
        die "macro is called at runtime"
            if $c ~~ Val::Macro;
        die "Trying to invoke a {$c.^name.subst(/^'Val::'/, '')}" # XXX: make this into an X::
            unless $c ~~ Val::Func;
        my @arguments = $.argumentlist.arguments.elements.map(*.eval($runtime));
        return $runtime.call($c, @arguments);
    }
}

### ### Q::Postfix::Property
###
### An object property operator; fetches a property out of an object.
###
class Q::Postfix::Property is Q::Postfix {
    has $.property;

    method attribute-order { <identifier operand property> }

    method eval($runtime) {
        my $obj = $.operand.eval($runtime);
        my $propname = $.property.name.value;
        $runtime.property($obj, $propname);
    }

    method put-value($value, $runtime) {
        given $.operand.eval($runtime) {
            when Val::Dict | Q {
                my $propname = $.property.name.value;
                $runtime.put-property($_, $propname, $value);
            }
            die "We don't handle this case yet"; # XXX: think more about this case
        }
    }
}

### ### Q::Unquote
###
### An unquote; allows Qtree fragments to be inserted into places in a quasi.
###
class Q::Unquote does Q {
    has $.qtype;
    has $.expr;

    method eval($runtime) {
        die "Should never hit an unquote at runtime"; # XXX: turn into X::
    }
}

### ### Q::Unquote::Prefix
###
### An unquote which is a prefix operator.
###
class Q::Unquote::Prefix is Q::Unquote {
    has $.operand;
}

### ### Q::Unquote::Infix
###
### An unquote which is an infix operator.
###
class Q::Unquote::Infix is Q::Unquote {
    has $.lhs;
    has $.rhs;
}

### ### Q::Term::My
###
### A `my` variable declaration.
###
class Q::Term::My does Q::Term does Q::Declaration {
    has $.identifier;

    method is-assignable { True }

    method eval($runtime) {
        return $.identifier.eval($runtime);
    }

    method put-value($value, $runtime) {
        $.identifier.put-value($value, $runtime);
    }
}

class Q::StatementList { ... }

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
class Q::Term::Quasi does Q::Term {
    has $.qtype;
    has $.contents;

    method attribute-order { <qtype contents> }

    method eval($runtime) {
        my $quasi-frame;

        sub interpolate($thing) {
            return $thing.new(:elements($thing.elements.map(&interpolate)))
                if $thing ~~ Val::Array;

            return $thing.new(:properties(%($thing.properties.map({ .key => interpolate(.value) }))))
                if $thing ~~ Val::Dict;

            return $thing
                if $thing ~~ Val;

            if $thing ~~ Q::Term::Identifier {
                if $runtime.lookup-frame-outside($thing, $quasi-frame) -> $frame {
                    return Q::Term::Identifier::Direct.new(:name($thing.name), :$frame);
                }
                else {
                    return $thing;
                }
            }

            return $thing.new(:name($thing.name))
                if $thing ~~ Q::Identifier;

            if $thing ~~ Q::Unquote::Prefix {
                my $prefix = $thing.expr.eval($runtime);
                die X::TypeCheck.new(:operation("interpolating an unquote"), :got($prefix), :expected(Q::Prefix))
                    unless $prefix ~~ Q::Prefix;
                return $prefix.new(:identifier($prefix.identifier), :operand($thing.operand));
            }
            elsif $thing ~~ Q::Unquote::Infix {
                my $infix = $thing.expr.eval($runtime);
                die X::TypeCheck.new(:operation("interpolating an unquote"), :got($infix), :expected(Q::Infix))
                    unless $infix ~~ Q::Infix;
                return $infix.new(:identifier($infix.identifier), :lhs($thing.lhs), :rhs($thing.rhs));
            }

            if $thing ~~ Q::Unquote {
                my $ast = $thing.expr.eval($runtime);
                die "Expression inside unquote did not evaluate to a Q" # XXX: turn into X::
                    unless $ast ~~ Q;
                return $ast;
            }

            if $thing ~~ Q::Term::My {
                $runtime.declare-var($thing.identifier);
            }

            if $thing ~~ Q::Term::Func {
                $runtime.enter($runtime.current-frame, Val::Dict.new, Q::StatementList.new);
                for $thing.block.parameterlist.parameters.elements.map(*.identifier) -> $identifier {
                    $runtime.declare-var($identifier);
                }
            }

            if $thing ~~ Q::Block {
                $runtime.enter($runtime.current-frame, Val::Dict.new, $thing.statementlist);
            }

            my %attributes = $thing.attributes.map: -> $attr {
                aname($attr) => interpolate(avalue($attr, $thing))
            };

            if $thing ~~ Q::Term::Func || $thing ~~ Q::Block {
                $runtime.leave();
            }

            $thing.new(|%attributes);
        }

        if $.qtype.value eq "Q.Unquote" && $.contents ~~ Q::Unquote {
            return $.contents;
        }
        $runtime.enter($runtime.current-frame, Val::Dict.new, Q::StatementList.new);
        $quasi-frame = $runtime.current-frame;
        my $r = interpolate($.contents);
        $runtime.leave();
        return $r;
    }
}

### ### Q::Parameter
###
### A parameter. Any identifier that's declared as the input to a block
### is a parameter, including subs, macros, and `if` statements.
###
class Q::Parameter does Q does Q::Declaration {
    has $.identifier;

    method is-assignable { True }
}

### ### Q::ParameterList
###
### A list of zero or more parameters.
###
class Q::ParameterList does Q {
    has Val::Array $.parameters .= new;
}

### ### Q::ArgumentList
###
### A list of zero or more arguments.
###
class Q::ArgumentList does Q {
    has Val::Array $.arguments .= new;
}

### ### Q::Decorator
###
### A decorator.
###
class Q::Decorator is Q {
    has Q::Identifier $.identifier;
    has $.argumentlist;
}

### ### Q::Statement
###
### A statement.
###
role Q::Statement does Q {
}

### ### Q::Statement::Expr
###
### A statement consisting of an expression.
###
class Q::Statement::Expr does Q::Statement {
    has $.expr;

    method run($runtime) {
        $.expr.eval($runtime);
    }
}

### ### Q::Statement::If
###
### An `if` statement.
###
class Q::Statement::If does Q::Statement {
    has $.expr;
    has $.block;
    has $.else = NONE;

    method attribute-order { <expr block else> }

    method run($runtime) {
        my $expr = $.expr.eval($runtime);
        if $expr.truthy {
            my $paramcount = $.block.parameterlist.parameters.elements.elems;
            die X::ParameterMismatch.new(
                :type("If statement"), :$paramcount, :argcount("0 or 1"))
                if $paramcount > 1;
            $runtime.run-block($.block, [$expr]);
        }
        else {
            given $.else {
                when Q::Statement::If {
                    $.else.run($runtime)
                }
                when Q::Block {
                    my $paramcount = $.else.parameterlist.parameters.elements.elems;
                    die X::ParameterMismatch.new(
                        :type("Else block"), :$paramcount, :argcount("0 or 1"))
                        if $paramcount > 1;
                    $runtime.run-block($.else, [$expr]);
                }
            }
        }
    }
}

### ### Q::Statement::Block
###
### A block statement.
###
class Q::Statement::Block does Q::Statement {
    has $.block;

    method run($runtime) {
        $runtime.run-block($.block, []);
    }
}

### ### Q::CompUnit
###
### A block-level statement representing a whole compilation unit.
### We can read "compilation unit" here as meaning "file".
###
class Q::CompUnit is Q::Statement::Block {
}

### ### Q::Statement::For
###
### A `for` loop statement.
###
class Q::Statement::For does Q::Statement {
    has $.expr;
    has $.block;

    method attribute-order { <expr block> }

    method run($runtime) {
        my $count = $.block.parameterlist.parameters.elements.elems;
        die X::ParameterMismatch.new(
            :type("For loop"), :paramcount($count), :argcount("0 or 1"))
            if $count > 1;

        my $array = $.expr.eval($runtime);
        die X::TypeCheck.new(:operation("for loop"), :got($array), :expected(Val::Array))
            unless $array ~~ Val::Array;

        for $array.elements -> $arg {
            $runtime.run-block($.block, [$arg]);
            last if $runtime.last-triggered;
            $runtime.reset-triggers();
        }
        $runtime.reset-triggers();
    }
}

### ### Q::Statement::While
###
### A `while` loop statement.
###
class Q::Statement::While does Q::Statement {
    has $.expr;
    has $.block;

    method attribute-order { <expr block> }

    method run($runtime) {
        while (my $expr = $.expr.eval($runtime)).truthy {
            my $paramcount = $.block.parameterlist.parameters.elements.elems;
            die X::ParameterMismatch.new(
                :type("While loop"), :$paramcount, :argcount("0 or 1"))
                if $paramcount > 1;
            $runtime.run-block($.block, [$expr]);
            last if $runtime.last-triggered;
            $runtime.reset-triggers();
        }
        $runtime.reset-triggers();
    }
}

### ### Q::Statement::Return
###
### A `return` statement.
###
class Q::Statement::Return does Q::Statement {
    has $.expr = NONE;

    method run($runtime) {
        my $value = $.expr ~~ Val::None ?? $.expr !! $.expr.eval($runtime);
        my $frame = $runtime.get-var("--RETURN-TO--");
        die X::Control::Return.new(:$value, :$frame);
    }
}

### ### Q::Statement::Throw
###
### A `throw` statement.
###
class Q::Statement::Throw does Q::Statement {
    has $.expr = NONE;

    method run($runtime) {
        my $value = $.expr ~~ Val::None
            ?? Val::Exception.new(:message(Val::Str.new(:value("Died"))))
            !! $.expr.eval($runtime);
        die X::TypeCheck.new(:got($value), :excpected(Val::Exception))
            if $value !~~ Val::Exception;

        die X::_007::RuntimeException.new(:msg($value.message.value));
    }
}

### ### Q::Statement::Next
###
### A `next` statement.
###
class Q::Statement::Next does Q::Statement {
    method run($runtime) {
        $runtime.trigger-next();
    }
}

### ### Q::Statement::Last
###
### A `last` statement.
###
class Q::Statement::Last does Q::Statement {
    method run($runtime) {
        $runtime.trigger-last();
    }
}

### ### Q::Statement::Func
###
### A subroutine declaration statement.
###
class Q::Statement::Func does Q::Statement does Q::Declaration {
    has $.identifier;
    has Q::Block $.block;

    method attribute-order { <identifier block> }

    method run($runtime) {
    }
}

### ### Q::Statement::Macro
###
### A macro declaration statement.
###
class Q::Statement::Macro does Q::Statement does Q::Declaration {
    has $.identifier;
    has $.block;

    method attribute-order { <identifier block> }

    method run($runtime) {
    }
}

### ### Q::Statement::BEGIN
###
### A `BEGIN` block statement.
###
class Q::Statement::BEGIN does Q::Statement {
    has $.block;

    method run($runtime) {
        # a BEGIN block does not run at runtime
    }
}

### ### Q::Statement::Class
###
### A class declaration statement.
###
class Q::Statement::Class does Q::Statement does Q::Declaration {
    has $.block;

    method run($runtime) {
        # a class block does not run at runtime
    }
}

### ### Q::StatementList
###
### A list of zero or more statements. Statement lists commonly occur
### directly inside blocks (or at the top level of the program, on the
### compunit level). However, it's also possible for a `quasi` to
### denote a statement list without any surrounding block.
###
class Q::StatementList does Q {
    has Val::Array $.statements .= new;

    method run($runtime) {
        for $.statements.elements -> $statement {
            my $value = $statement.run($runtime);
            last if $runtime.next-triggered || $runtime.last-triggered;
            LAST if $statement ~~ Q::Statement::Expr {
                return $value;
            }
        }
        return NONE;
    }
}

### ### Q::Expr::BlockAdapter
###
### An expression which holds a block. Surprisingly, this never
### happens in the source code text itself; because of 007's grammar, an
### expression can never consist of a block.
###
### However, it can happen as a macro call (an expression) expands into
### a block of one or more statements; that's when this Qtype is used.
###
### Semantically, the block is executed normally, and
### if execution evaluates the last statement and the statement turns out
### to have a value (because it's an expression statement), then this
### value is the value of the whole containing expression.
###
class Q::Expr::BlockAdapter does Q::Expr {
    has $.block;

    method eval($runtime) {
        $runtime.enter($runtime.current-frame, $.block.static-lexpad, $.block.statementlist);
        my $result = $.block.statementlist.run($runtime);
        $runtime.leave;
        return $result;
    }
}
