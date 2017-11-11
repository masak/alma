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
### `None`, `True`, `5`, or `"James Bond"`.
###
### Compound values such as arrays and objects are considered terms but not
### literals.
###
role Q::Literal does Q::Term {
}

### ### Q::Literal::None
###
### The `None` literal.
###
class Q::Literal::None does Q::Literal {
    method eval($) { NONE }
}

### ### Q::Literal::Bool
###
### A boolean literal; either `True` or `False`.
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

### ### Q::Identifier
###
### An identifier; a name which identifies a storage location in the program.
###
### Identifiers are subject to *scoping*: the same name can point to different
### storage locations because they belong to different scopes.
###
class Q::Identifier does Q::Term {
    has Val::Str $.name;
    has $.frame = NONE;

    method attribute-order { <name> }

    method eval($runtime) {
        return $runtime.get-var($.name.value, $.frame);
    }

    method put-value($value, $runtime) {
        $runtime.put-var(self, $value);
    }
}

### ### Q::Term::Regex
###
### A regular expression (*regex*).
###
class Q::Term::Regex does Q::Term {
    has Val::Str $.contents;

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
### An object. Object terms consist of an optional *type*, and a property list
### with zero or more key/value pairs.
###
class Q::Term::Object does Q::Term {
    has Q::Identifier $.type;
    has $.propertylist;

    method eval($runtime) {
        return $runtime.get-var($.type.name.value, $.type.frame).create(
            $.propertylist.properties.elements.map({.key.value => .value.eval($runtime)})
        );
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

### ### Q::Trait
###
### A trait; a piece of metadata for a routine. A trait consists of an
### identifier and an expression.
###
class Q::Trait does Q {
    has $.identifier;
    has $.expr;

    method attribute-order { <identifier expr> }
}

### ### Q::TraitList
###
### A list of zero or more traits. Each routine has a traitlist.
###
class Q::TraitList does Q {
    has Val::Array $.traits .= new;

    method attribute-order { <traits> }
}

### ### Q::Term::Sub
###
### A subroutine.
###
class Q::Term::Sub does Q::Term does Q::Declaration {
    has $.identifier;
    has $.traitlist = Q::TraitList.new;
    has $.block;

    method attribute-order { <identifier traitlist block> }

    method eval($runtime) {
        my $name = $.identifier ~~ Val::NoneType
            ?? Val::Str.new(:value(""))
            !! $.identifier.name;
        return Val::Sub.new(
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
    has Val::Object $.static-lexpad is rw = Val::Object.new;

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

### ### Q::Prefix::Str
###
### A stringification operator.
###
class Q::Prefix::Str is Q::Prefix {}

### ### Q::Prefix::Plus
###
### A numification operator.
###
class Q::Prefix::Plus is Q::Prefix {}

### ### Q::Prefix::Minus
###
### A numeric negation operator.
###
class Q::Prefix::Minus is Q::Prefix {}

### ### Q::Prefix::So
###
### A boolification operator.
###
class Q::Prefix::So is Q::Prefix {}

### ### Q::Prefix::Not
###
### A boolean negation operator.
###
class Q::Prefix::Not is Q::Prefix {}

### ### Q::Prefix::Upto
###
### An "upto" operator; applied to a number `n` it produces an array
### of values `[0, 1, ..., n-1]`.
###
class Q::Prefix::Upto is Q::Prefix {}

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

### ### Q::Infix::Addition
###
### A numeric addition operator.
###
class Q::Infix::Addition is Q::Infix {}

### ### Q::Infix::Addition
###
### A numeric subtraction operator.
###
class Q::Infix::Subtraction is Q::Infix {}

### ### Q::Infix::Multiplication
###
### A numeric multiplication operator.
###
class Q::Infix::Multiplication is Q::Infix {}

### ### Q::Infix::Modulo
###
### A numeric modulo operator; produces the *remainder* left from an integer
### division between two numbers. For example, `456 % 100` is `56` because the
### remainder from dividing `456` by `100` is `56`.
###
class Q::Infix::Modulo is Q::Infix {}

### ### Q::Infix::Divisibility
###
### A divisibility test operator. Returns `True` exactly when the remainder
### operator would return `0`.
###
class Q::Infix::Divisibility is Q::Infix {}

### ### Q::Infix::Concat
###
### A string concatenation operator. Returns a single string that is the
### result of sequentially putting two strings together.
###
class Q::Infix::Concat is Q::Infix {}

### ### Q::Infix::Replicate
###
### A string replication operator. Returns a string which consists of `n`
### copies of a string.
###
class Q::Infix::Replicate is Q::Infix {}

### ### Q::Infix::ArrayReplicate
###
### An array replication operator. Returns an array which consists of
### the original array's elements, repeated `n` times.
###
class Q::Infix::ArrayReplicate is Q::Infix {}

### ### Q::Infix::Cons
###
### A "cons" operator. Given a value and an array, returns a new
### array with the value added as the first element.
###
class Q::Infix::Cons is Q::Infix {}

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

### ### Q::Infix::Eq
###
### An equality test operator.
###
class Q::Infix::Eq is Q::Infix {}

### ### Q::Infix::Ne
###
### An inequality test operator.
###
class Q::Infix::Ne is Q::Infix {}

### ### Q::Infix::Gt
###
### A greater-than test operator.
###
class Q::Infix::Gt is Q::Infix {}

### ### Q::Infix::Lt
###
### A less-than test operator.
###
class Q::Infix::Lt is Q::Infix {}

### ### Q::Infix::Ge
###
### A greater-than-or-equal test operator.
###
class Q::Infix::Ge is Q::Infix {}

### ### Q::Infix::Le
###
### A less-than-or-equal test operator.
###
class Q::Infix::Le is Q::Infix {}

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
### right-hand side only if the left-hand side is `None`.
###
class Q::Infix::DefinedOr is Q::Infix {
    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        return $l !~~ Val::NoneType
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

### ### Q::Infix::TypeMatch
###
### A type match operator. Checks if a value on the left-hand side has
### the type on the right-hand side, including subtypes.
###
class Q::Infix::TypeMatch is Q::Infix {}

### ### Q::Infix::TypeNonMatch
###
### A negative type match operator. Returns `True` exactly in the cases
### a type match would return `False`.
###
class Q::Infix::TypeNonMatch is Q::Infix {}

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
            when Val::Object | Val::Sub | Q {
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
            when Val::Object | Q {
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
            unless $c ~~ Val::Sub;
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
            when Val::Object | Q {
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
        sub interpolate($thing) {
            return $thing.new(:elements($thing.elements.map(&interpolate)))
                if $thing ~~ Val::Array;

            return $thing.new(:properties(%($thing.properties.map({ .key => interpolate(.value) }))))
                if $thing ~~ Val::Object;

            return $thing
                if $thing ~~ Val;

            return $thing.new(:name($thing.name), :frame($runtime.current-frame))
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

            my %attributes = $thing.attributes.map: -> $attr {
                aname($attr) => interpolate(avalue($attr, $thing))
            };

            $thing.new(|%attributes);
        }

        if $.qtype.value eq "Q::Unquote" && $.contents ~~ Q::Unquote {
            return $.contents;
        }
        return interpolate($.contents);
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

### ### Q::Statement
###
### A statement.
###
role Q::Statement does Q {
}

### ### Q::Statement::My
###
### A `my` variable declaration statement.
###
class Q::Statement::My does Q::Statement does Q::Declaration {
    has $.identifier;
    has $.expr = NONE;

    method attribute-order { <identifier expr> }

    method is-assignable { True }

    method run($runtime) {
        return
            unless $.expr !~~ Val::NoneType;
        my $value = $.expr.eval($runtime);
        $.identifier.put-value($value, $runtime);
    }
}

### ### Q::Statement::Constant
###
### A `constant` declaration statement.
###
class Q::Statement::Constant does Q::Statement does Q::Declaration {
    has $.identifier;
    has $.expr;

    method attribute-order { <identifier expr> }

    method run($runtime) {
        # value has already been assigned
    }
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
            $runtime.enter($runtime.current-frame, $.block.static-lexpad, $.block.statementlist);
            for @($.block.parameterlist.parameters.elements) Z $expr -> ($param, $arg) {
                $runtime.declare-var($param.identifier, $arg);
            }
            $.block.statementlist.run($runtime);
            $runtime.leave;
        }
        else {
            given $.else {
                when Q::Statement::If {
                    $.else.run($runtime)
                }
                when Q::Block {
                    $runtime.enter($runtime.current-frame, $.else.static-lexpad, $.else.statementlist);
                    $.else.statementlist.run($runtime);
                    $runtime.leave;
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
        $runtime.enter($runtime.current-frame, $.block.static-lexpad, $.block.statementlist);
        $.block.statementlist.run($runtime);
        $runtime.leave;
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
            $runtime.enter($runtime.current-frame, $.block.static-lexpad, $.block.statementlist);
            if $count == 1 {
                $runtime.declare-var($.block.parameterlist.parameters.elements[0].identifier, $arg.list[0]);
            }
            $.block.statementlist.run($runtime);
            $runtime.leave;
        }
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
            $runtime.enter($runtime.current-frame, $.block.static-lexpad, $.block.statementlist);
            for @($.block.parameterlist.parameters.elements) Z $expr -> ($param, $arg) {
                $runtime.declare-var($param.identifier, $arg);
            }
            $.block.statementlist.run($runtime);
            $runtime.leave;
        }
    }
}

### ### Q::Statement::Return
###
### A `return` statement.
###
class Q::Statement::Return does Q::Statement {
    has $.expr = NONE;

    method run($runtime) {
        my $value = $.expr ~~ Val::NoneType ?? $.expr !! $.expr.eval($runtime);
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
        my $value = $.expr ~~ Val::NoneType
            ?? Val::Exception.new(:message(Val::Str.new(:value("Died"))))
            !! $.expr.eval($runtime);
        die X::TypeCheck.new(:got($value), :excpected(Val::Exception))
            if $value !~~ Val::Exception;

        die X::_007::RuntimeException.new(:msg($value.message.value));
    }
}

### ### Q::Statement::Sub
###
### A subroutine declaration statement.
###
class Q::Statement::Sub does Q::Statement does Q::Declaration {
    has $.identifier;
    has $.traitlist = Q::TraitList.new;
    has Q::Block $.block;

    method attribute-order { <identifier traitlist block> }

    method run($runtime) {
    }
}

### ### Q::Statement::Macro
###
### A macro declaration statement.
###
class Q::Statement::Macro does Q::Statement does Q::Declaration {
    has $.identifier;
    has $.traitlist = Q::TraitList.new;
    has $.block;

    method attribute-order { <identifier traitlist block> }

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
            LAST if $statement ~~ Q::Statement::Expr {
                return $value;
            }
        }
    }
}

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
class Q::Expr::StatementListAdapter does Q::Expr {
    has $.statementlist;

    method eval($runtime) {
        return $.statementlist.run($runtime);
    }
}
