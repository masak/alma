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

# XXX: rename to X::Property::NotFound once [RT #126827] has been fixed
class X::PropertyNotFound is Exception {
    has $.propname;

    method message {
        "Property '$.propname' not found"
    }
}

class X::Associativity::Conflict is Exception {
    method message { "The operator already has a defined associativity" }
}

role Q {
    method Str {
        sub aname($attr) { $attr.name.substr(2) }
        sub avalue($attr) { $attr.get_value(self).quoted-Str }

        my @attrs = self.attributes;
        if @attrs == 1 {
            return "{self.^name} { avalue(@attrs[0]) }";
        }
        sub keyvalue($attr) { aname($attr) ~ ": " ~ avalue($attr) }
        my $contents = @attrs.map(&keyvalue).join(",\n").indent(4);
        return "{self.^name} \{\n$contents\n\}";
    }

    method quoted-Str {
        self.Str
    }

    method attributes {
        sub aname($attr) { $attr.name.substr(2) }
        sub find($aname) { self.^attributes.first({ $aname eq aname($_) }) }

        self.can("attribute-order")
            ?? self.attribute-order.map({ find($_) })
            !! self.^attributes;
    }
}

role Q::Expr does Q {
}

role Q::Literal does Q::Expr {
}

class Q::Literal::None does Q::Literal {
    method eval($) { Val::None.new }
    method interpolate($) { self }
}

class Q::Literal::Int does Q::Literal {
    has Val::Int $.value;

    method eval($) { $.value }
    method interpolate($) { self }
}

class Q::Literal::Str does Q::Literal {
    has Val::Str $.value;

    method eval($) { $.value }
    method interpolate($) { self }
}

class Q::Identifier does Q::Expr {
    has Val::Str $.name;
    has $.frame = Val::None.new;

    method attribute-order { <name> }

    method eval($runtime) {
        return $runtime.get-var(
            $.name.value,
            $.frame ~~ Val::None ?? $runtime.current-frame !! $.frame
        );
    }

    method interpolate($runtime) {
        return self.new(:$.name, :frame($runtime.current-frame));
    }
}

role Q::Term does Q::Expr {
}

class Q::Term::Array does Q::Term {
    has Val::Array $.elements;

    method eval($runtime) {
        Val::Array.new(:elements($.elements.elements».eval($runtime)));
    }
    method interpolate($runtime) {
        self.new(:elements(@.elements».interpolate($runtime)));
    }
}

class Q::Term::Quasi does Q::Term {
    has $.contents;

    method eval($runtime) {
        return $.contents.interpolate($runtime);
    }
    method interpolate($runtime) {
        self.new(:contents($.contents.interpolate($runtime)));
        # XXX: the fact that we keep interpolating inside of the quasi means
        # that unquotes encountered inside of this inner quasi will be
        # interpolated in the context of the outer quasi. is this correct?
        # can we come up with a case where it matters?
    }
}

class Q::Term::Object does Q::Term {
    has Q::Identifier $.type;
    has $.propertylist;

    method eval($runtime) {
        return $runtime.get-var($.type.name.value).create(
            $.propertylist.properties.elements.map({.key.value => .value.eval($runtime)})
        );
    }
}

class Q::Property does Q {
    has Val::Str $.key;
    has $.value;
}

class Q::PropertyList does Q {
    has Val::Array $.properties = Val::Array.new;
    method interpolate($runtime) {
        self.new(:properties(@.properties».interpolate($runtime)));
    }
}

class Q::Block does Q {
    has $.parameterlist;
    has $.statementlist;
    has %.static-lexpad;

    method attribute-order { <parameterlist statementlist> }

    method eval($runtime) {
        my $outer-frame = $runtime.current-frame;
        Val::Block.new(
            :$.parameterlist,
            :$.statementlist,
            :%.static-lexpad,
            :$outer-frame
        );
    }
    method interpolate($runtime) {
        Q::Block.new(
            :parameterlist($.parameterlist.interpolate($runtime)),
            :statementlist($.statementlist.interpolate($runtime)));
        # XXX: but what about the static lexpad? we kind of lose it here, don't we?
        # what does that *mean* in practice? can we come up with an example where
        # it matters? if the static lexpad happens to contain a value which is a
        # Q node, do we continue into *it*, interpolating it, too?
    }
}

class Q::Unquote does Q {
    has $.expr;

    method eval($runtime) {
        die "Should never hit an unquote at runtime"; # XXX: turn into X::
    }
    method interpolate($runtime) {
        my $q = $.expr.eval($runtime);
        die "Expression inside unquote did not evaluate to a Q" # XXX: turn into X::
            unless $q ~~ Q;
        return $q;
    }
}

class Q::Prefix does Q::Expr {
    has $.ident;
    has $.expr;

    method attribute-order { <expr> }

    method eval($runtime) {
        my $e = $.expr.eval($runtime);
        my $c = $.ident.eval($runtime);
        return $runtime.call($c, [$e]);
    }

    method interpolate($runtime) {
        self.new(:expr($.expr ~~ Val::None ?? $.expr !! $.expr.interpolate($runtime)));
    }
}

class Q::Prefix::Minus is Q::Prefix {}

class Q::Infix does Q::Expr {
    has $.ident;
    has $.lhs;
    has $.rhs;

    method attribute-order { <lhs rhs> }

    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        my $r = $.rhs.eval($runtime);
        my $c = $.ident.eval($runtime);
        return $runtime.call($c, [$l, $r]);
    }

    method interpolate($runtime) {
        self.new(
            :lhs($.lhs ~~ Val::None ?? $.lhs !! $.lhs.interpolate($runtime)),
            :rhs($.rhs ~~ Val::None ?? $.rhs !! $.rhs.interpolate($runtime)),
            :ident($.ident.interpolate($runtime)));
    }
}

class Q::Infix::Addition is Q::Infix {}

class Q::Infix::Subtraction is Q::Infix {}

class Q::Infix::Multiplication is Q::Infix {}

class Q::Infix::Concat is Q::Infix {}

class Q::Infix::Assignment is Q::Infix {
    method eval($runtime) {
        die "Needs to be an identifier on the left"     # XXX: Turn this into an X::
            unless $.lhs ~~ Q::Identifier;
        my $value = $.rhs.eval($runtime);
        $runtime.put-var($.lhs.name.value, $value);
        return $value;
    }
}

class Q::Infix::Eq is Q::Infix {}

class Q::Postfix does Q::Expr {
    has $.ident;
    has $.expr;

    method attribute-order { <expr> }

    method eval($runtime) {
        my $e = $.expr.eval($runtime);
        my $c = $.ident.eval($runtime);
        return $runtime.call($c, [$e]);
    }
}

class Q::Postfix::Index is Q::Postfix {
    has $.index;

    method attribute-order { <expr index> }

    method eval($runtime) {
        given $.expr.eval($runtime) {
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
            when Val::Object | Q {
                my $property = $.index.eval($runtime);
                die X::Subscript::NonString.new
                    if $property !~~ Val::Str;
                my $propname = $property.value;
                return $runtime.property($_, $propname);
            }
            die X::TypeCheck.new(:operation<indexing>, :got($_), :expected(Val::Array));
        }
    }
    method interpolate($runtime) {
        self.new(:expr($.expr.interpolate($runtime)), :index($.index.interpolate($runtime)));
    }
}

class Q::Postfix::Call is Q::Postfix {
    has $.argumentlist;

    method attribute-order { <expr argumentlist> }

    method eval($runtime) {
        my $c = $.expr.eval($runtime);
        die "macro is called at runtime"
            if $c ~~ Val::Macro;
        die "Trying to invoke a {$c.^name.subst(/^'Val::'/, '')}" # XXX: make this into an X::
            unless $c ~~ Val::Block;
        my @args = $.argumentlist.arguments.elements».eval($runtime);
        return $runtime.call($c, @args);
    }
    method interpolate($runtime) {
        self.new(:expr($.expr.interpolate($runtime)), :argumentlist($.argumentlist.interpolate($runtime)));
    }
}

class Q::Postfix::Property is Q::Postfix {
    has $.property;

    method attribute-order { <expr property> }

    method eval($runtime) {
        my $obj = $.expr.eval($runtime);
        my $propname = $.property.name.value;
        $runtime.property($obj, $propname);
    }

    method interpolate($runtime) {
        self.new(:expr($.expr.interpolate($runtime)), :property($.property.interpolate($runtime)));
    }
}

role Q::Declaration {
    method is-assignable { False }
}

class Q::ParameterList does Q {
    has Val::Array $.parameters = Val::Array.new;
    method interpolate($runtime) {
        self.new(:parameters(Val::Array.new(:elements($.parameters.elements».interpolate($runtime)))));
    }
}

class Q::Parameter does Q does Q::Declaration {
    has $.ident;

    method is-assignable { True }

    method interpolate($runtime) {
        self.new(:ident($.ident.interpolate));
    }
}

class Q::ArgumentList does Q {
    has Val::Array $.arguments = Val::Array.new;
    method interpolate($runtime) {
        self.new(:arguments(Val::Array.new(:elements($.arguments.elements».interpolate($runtime)))));
    }
}

role Q::Statement does Q {
}

class Q::Statement::My does Q::Statement does Q::Declaration {
    has $.ident;
    has $.expr;

    method attribute-order { <expr ident> }

    method is-assignable { True }

    method run($runtime) {
        return
            unless $.expr !~~ Val::None;
        my $value = $.expr.eval($runtime);
        $runtime.put-var($.ident.name.value, $value);
    }
    method interpolate($runtime) {
        self.new(
            :ident($.ident.interpolate($runtime)),
            :expr($.expr ~~ Val::None ?? $.expr !! $.expr.interpolate($runtime)));
    }
}

class Q::Statement::Constant does Q::Statement does Q::Declaration {
    has $.ident;
    has $.expr;

    method attribute-order { <expr ident> }

    method run($runtime) {
        # value has already been assigned
    }
    method interpolate($runtime) {
        self.new(
            :ident($.ident.interpolate($runtime)),
            :expr($.expr.interpolate($runtime)));
    }
}

class Q::Statement::Expr does Q::Statement {
    has $.expr;

    method run($runtime) {
        $.expr.eval($runtime);
    }
    method interpolate($runtime) {
        self.new(:expr($.expr.interpolate($runtime)));
    }
}

class Q::Statement::If does Q::Statement {
    has $.expr;
    has $.block;

    method attribute-order { <expr block> }

    method run($runtime) {
        my $expr = $.expr.eval($runtime);
        if $expr.truthy {
            my $c = $.block.eval($runtime);
            $runtime.enter($c);
            my $paramcount = $c.parameterlist.elems;
            die X::ParameterMismatch.new(
                :type("If statement"), :$paramcount, :argcount("0 or 1"))
                if $paramcount > 1;
            for @($c.parameterlist.parameters.elements) Z $expr -> ($param, $arg) {
                $runtime.declare-var($param.ident.name.value, $arg);
            }
            $.block.statementlist.run($runtime);
            $runtime.leave;
        }
    }
    method interpolate($runtime) {
        self.new(:expr($.expr.interpolate($runtime)), :block($.block.interpolate($runtime)));
    }
}

class Q::Statement::Block does Q::Statement {
    has $.block;

    method run($runtime) {
        $runtime.enter($.block.eval($runtime));
        $.block.statementlist.run($runtime);
        $runtime.leave;
    }
    method interpolate($runtime) {
        self.new(:block($.block.interpolate($runtime)));
    }
}

class Q::CompUnit is Q::Statement::Block {
}

class Q::Statement::For does Q::Statement {
    has $.expr;
    has $.block;

    method attribute-order { <expr block> }

    method run($runtime) {
        multi split_elements(@array, 1) { return @array }
        multi split_elements(@array, Int $n) {
            my $list = @array.list;
            my @split;

            while True {
                my @new = $list.splice(0, $n);
                last unless @new;
                @split.push: @new.item;
            }

            @split;
        }

        my $c = $.block.eval($runtime);
        my $count = $c.parameterlist.parameters.elements.elems;

        my $array = $.expr.eval($runtime);
        die X::TypeCheck.new(:operation("for loop"), :got($array), :expected(Val::Array))
            unless $array ~~ Val::Array;

        if $count == 0 {
            for $array.elements {
                $runtime.enter($c);
                $.block.statementlist.run($runtime);
                $runtime.leave;
            }
        }
        else {
            for split_elements($array.elements, $count) -> $arg {
                $runtime.enter($c);
                for @($c.parameterlist.parameters.elements) Z $arg.list -> ($param, $real_arg) {
                    $runtime.declare-var($param.ident.name.value, $real_arg);
                }
                $.block.statementlist.run($runtime);
                $runtime.leave;
            }
        }
    }
    method interpolate($runtime) {
        self.new(:expr($.expr.interpolate($runtime)), :block($.block.interpolate($runtime)));
    }
}

class Q::Statement::While does Q::Statement {
    has $.expr;
    has $.block;

    method attribute-order { <expr block> }

    method run($runtime) {
        while (my $expr = $.expr.eval($runtime)).truthy {
            my $c = $.block.eval($runtime);
            $runtime.enter($c);
            my $paramcount = $c.parameterlist.parameters.elements.elems;
            die X::ParameterMismatch.new(
                :type("While loop"), :$paramcount, :argcount("0 or 1"))
                if $paramcount > 1;
            for @($c.parameterlist.parameters.elements) Z $expr -> ($param, $arg) {
                $runtime.declare-var($param.ident.name.value, $arg);
            }
            $.block.statementlist.run($runtime);
            $runtime.leave;
        }
    }
    method interpolate($runtime) {
        self.new(:expr($.expr.interpolate($runtime)), :block($.block.interpolate($runtime)));
    }
}

class Q::Statement::Return does Q::Statement {
    has $.expr;

    method run($runtime) {
        my $value = $.expr ~~ Val::None ?? $.expr !! $.expr.eval($runtime);
        my $frame = $runtime.get-var("--RETURN-TO--");
        die X::Control::Return.new(:$value, :$frame);
    }
    method interpolate($runtime) {
        self.new(:expr($.expr.interpolate($runtime)));
    }
}

class Q::Statement::Sub does Q::Statement does Q::Declaration {
    has $.ident;
    has $.block;

    method attribute-order { <ident block> }

    method run($runtime) {
    }
    method interpolate($runtime) {
        self.new(:ident($.ident.interpolate($runtime)),
            :block($.block.interpolate($runtime)));
    }
}

class Q::Statement::Macro does Q::Statement does Q::Declaration {
    has $.ident;
    has $.block;

    method attribute-order { <ident block> }

    method run($runtime) {
    }
    method interpolate($runtime) {
        self.new(:ident($.ident.interpolate($runtime)),
            :block($.block.interpolate($runtime)));
    }
}

class Q::Statement::BEGIN does Q::Statement {
    has $.block;

    method run($runtime) {
        # a BEGIN block does not run at runtime
    }
    method interpolate($runtime) {
        self.new(:block($.block.interpolate($runtime)));
    }
}

class Q::StatementList does Q {
    has Val::Array $.statements = Val::Array.new;

    method run($runtime) {
        for $.statements.elements -> $statement {
            $statement.run($runtime);
        }
    }
    method interpolate($runtime) {
        self.new(:statements(Val::Array.new(:elements($.statements.elements».interpolate($runtime)))));
    }
}

class Q::Trait does Q {
    has $.ident;
    has $.expr;

    method attribute-order { <ident expr> }

    method interpolate($runtime) {
        self.new(:ident($.ident.interpolate($runtime)), :expr($.expr.interpolate($runtime)));
    }
}
