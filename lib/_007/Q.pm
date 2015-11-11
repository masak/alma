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

role Q {
    method worthy-attributes {
        sub aname($attr) { $attr.name.substr(2) }
        sub avalue($attr) { $attr.get_value(self) }
        sub worthy($attr) {
            avalue($attr) !~~ Hash  # avoids showing static-lexpad
                && aname($attr) ne "outer-frame"
                && (aname($attr) ne "type" || avalue($attr) ne "")
        }

        return self.^attributes.grep(&worthy);
    }

    method Str {
        sub pretty($_) {
            when Array {
                return .elems == 0
                    ?? "[]"
                    !! .elems == 1 && .[0].Str.lines == 1
                        ?? "[{.[0].Str}]"
                        !! "[\n{.map({.Str}).join(",\n").indent(4)}\n]"
            }
            when Str { return .perl }
            default { return .Str }
        }
        sub aname($attr) { $attr.name.substr(2) }
        sub avalue($attr) { $attr.get_value(self) }

        my @attrs = @.worthy-attributes;
        if @attrs == 1 {
            return "{self.^name} {pretty(avalue(@attrs[0]))}";
        }
        sub keyvalue($attr) { aname($attr) ~ ": " ~ pretty(avalue($attr)) }
        if @attrs == 2 && aname(@attrs[1]) eq "expr" {  # prefix or postfix
            @attrs .= reverse;  # because it looks nicer to have expr first
        }
        my $contents = @attrs.map(&keyvalue).join(",\n").indent(4);
        return "{self.^name} \{\n$contents\n\}";
    }
}

role Q::Expr does Q {
}

role Q::Literal does Q::Expr {
}

role Q::Literal::None does Q::Literal {
    method new() { self.bless }

    method eval($) { Val::None.new }
    method interpolate($) { self }
}

role Q::Literal::Int does Q::Literal {
    has $.value;
    method new(Int $value) { self.bless(:$value) }

    method eval($) { Val::Int.new(:$.value) }
    method interpolate($) { self }
}

role Q::Literal::Str does Q::Literal {
    has $.value;
    method new(Str $value) { self.bless(:$value) }

    method eval($) {
        my $value = $.value.subst(q[\"], q["], :g).subst(q[\\\\], q[\\], :g);
        Val::Str.new(:$value);
    }
    method interpolate($) { self }
}

role Q::Term does Q::Expr {
}

role Q::Term::Array does Q::Term {
    has @.elements;
    method new(*@elements) {
        self.bless(:@elements)
    }

    method eval($runtime) {
        Val::Array.new(:elements(@.elements>>.eval($runtime)));
    }
    method interpolate($runtime) {
        self.new(@.elements».interpolate($runtime));
    }
}

role Q::Expr::Block { ... }

role Q::Literal::Object does Q::Literal {
  has @.elements;
  method new(*@elements) {
    self.bless(elements => @elements)
  }
  method Str { "Object" ~ children(@.elements) }

  method eval($runtime) {
    ... 'Val::Object NYI'
  }
}

role Q::Property does Q::Literal {
  has $.key;
  has $.value;
  method new($key, $value) {
    self.bless(:$key, :$value);
  }

  method Str { "Property" ~ children($!key, $!value) }

  method eval($runtime) {
    ... 'Property NYI'
  }
}

role Q::Block does Q {
    has $.parameterlist;
    has $.statementlist;
    has %.static-lexpad;

    method new($parameterlist, $statementlist) {
        self.bless(:$parameterlist, :$statementlist)
    }

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
        my $block = Q::Expr::Block.new(
            $.parameterlist.interpolate($runtime),
            $.statementlist.interpolate($runtime),
            $runtime.current-frame);
        # XXX: but what about the static lexpad? we kind of lose it here, don't we?
        # what does that *mean* in practice? can we come up with an example where
        # it matters? if the static lexpad happens to contain a value which is a
        # Q node, do we continue into *it*, interpolating it, too?
    }
}

role Q::Expr::Block does Q::Block {
    has $.outer-frame;

    method new($parameterlist, $statementlist, $outer-frame) {
        self.bless(:$parameterlist, :$statementlist, :$outer-frame)
    }

    method eval($runtime) {
        Val::Block.new(
            :$.parameterlist,
            :$.statementlist,
            :%.static-lexpad,
            :$.outer-frame
        );
    }
}

role Q::Identifier does Q::Expr {
    has $.name;
    method new(Str $name) { self.bless(:$name) }

    method eval($runtime) {
        return $runtime.get-var($.name);
    }
    method interpolate($) { self }
}

role Q::Unquote does Q {
    has $.expr;
    method new($expr) { self.bless(:$expr) }

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

role Q::Prefix[$type] does Q::Expr {
    has $.expr;

    method type { $type }

    method new($expr) { self.bless(:$expr) }

    method eval($runtime) {
        my $e = $.expr.eval($runtime);
        my $c = $runtime.get-var("prefix:$type");
        return $runtime.call($c, [$e]);
    }

    method interpolate($runtime) {
        self.new($.expr.interpolate($runtime));
    }
}

role Q::Prefix::Minus does Q::Prefix["<->"] {}

role Q::Infix[$type] does Q::Expr {
    has $.lhs;
    has $.rhs;

    method type { $type }

    method new($lhs, $rhs) { self.bless(:$lhs, :$rhs) }

    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        my $r = $.rhs.eval($runtime);
        my $c = $runtime.get-var("infix:$type");
        return $runtime.call($c, [$l, $r]);
    }

    method interpolate($runtime) {
        self.new($.lhs.interpolate($runtime), $.rhs.interpolate($runtime));
    }
}

role Q::Infix::Addition does Q::Infix["<+>"] {}

role Q::Infix::Concat does Q::Infix["<~>"] {}

role Q::Infix::Assignment does Q::Infix["<=>"] {
    method eval($runtime) {
        die "Needs to be an identifier on the left"     # XXX: Turn this into an X::
            unless $.lhs ~~ Q::Identifier;
        my $value = $.rhs.eval($runtime);
        $runtime.put-var($.lhs.name, $value);
        return $value;
    }
}

role Q::Infix::Eq does Q::Infix["<==>"] {}

role Q::Postfix[$type] does Q::Expr {
    has $.expr;

    method type { $type }

    method new($expr) { self.bless(:$expr) }

    method eval($runtime) {
        my $e = $.expr.eval($runtime);
        my $c = $runtime.get-var("postfix:$type");
        return $runtime.call($c, [$e]);
    }
}

role Q::Postfix::Index does Q::Postfix["<[>"] {
    has $.index;
    method new($expr, $index) { self.bless(:$expr, :$index) }

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
            when Q {
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
        self.new($.expr.interpolate($runtime), $.index.interpolate($runtime));
    }
}

role Q::Postfix::Call does Q::Postfix["<(>"] {
    has $.argumentlist;
    method new($expr, $argumentlist) { self.bless(:$expr, :$argumentlist) }

    method eval($runtime) {
        my $c = $.expr.eval($runtime);
        die "macro is called at runtime"
            if $c ~~ Val::Macro;
        die "Trying to invoke a {$c.^name.subst(/^'Val::'/, '')}" # XXX: make this into an X::
            unless $c ~~ Val::Block;
        my @args = $.argumentlist».eval($runtime);
        return $runtime.call($c, @args);
    }
    method interpolate($runtime) {
        self.new($.expr.interpolate($runtime), $.argumentlist.interpolate($runtime));
    }
}

role Q::Postfix::Property does Q::Postfix["<.>"] {
    has $.ident;
    method new($expr, $ident) { self.bless(:$expr, :$ident) }

    method eval($runtime) {
        my $obj = $.expr.eval($runtime);
        my $propname = $.ident.name;
        return $runtime.property($obj, $propname);
    }

    method interpolate($runtime) {
        self.new($.expr.interpolate($runtime), $.ident.interpolate($runtime));
    }
}

role Q::ParameterList does Q {
    has @.parameters handles <elems Numeric Real list>;
    method new(*@parameters) { self.bless(:@parameters) }
    method interpolate($runtime) {
        self.new(@.parameters».interpolate($runtime));
    }
}

role Q::ArgumentList does Q {
    has @.arguments handles <elems Numeric Real list>;
    method new(*@arguments) { self.bless(:@arguments) }
    method interpolate($runtime) {
        self.new(@.arguments».interpolate($runtime));
    }
}

role Q::Statement does Q {
}

role Q::Statement::My does Q::Statement {
    has $.ident;
    has $.expr;
    method new($ident, $expr = Empty) { self.bless(:$ident, :$expr) }

    method run($runtime) {
        return
            unless $.expr;
        my $value = $.expr.eval($runtime);
        $runtime.put-var($.ident.name, $value);
    }
    method interpolate($runtime) {
        self.new($.ident.interpolate($runtime),
            $.expr === Empty ?? Empty !! $.expr.interpolate($runtime));
    }
}

role Q::Statement::Constant does Q::Statement {
    has $.ident;
    has $.expr;
    method new($ident, $expr = Empty) { self.bless(:$ident, :$expr) }

    method run($runtime) {
        # value has already been assigned
    }
    method interpolate($runtime) {
        self.new($.ident.interpolate($runtime),
            $.expr === Empty ?? Empty !! $.expr.interpolate($runtime));   # XXX: and here
    }
}

role Q::Statement::Expr does Q::Statement {
    has $.expr;
    method new($expr) { self.bless(:$expr) }

    method run($runtime) {
        $.expr.eval($runtime);
    }
    method interpolate($runtime) {
        self.new($.expr.interpolate($runtime));
    }
}

role Q::Statement::If does Q::Statement {
    has $.expr;
    has $.block;
    method new($expr, Q::Block $block) { self.bless(:$expr, :$block) }

    method run($runtime) {
        my $expr = $.expr.eval($runtime);
        if $expr.truthy {
            my $c = $.block.eval($runtime);
            $runtime.enter($c);
            my $paramcount = $c.parameterlist.elems;
            die X::ParameterMismatch.new(
                :type("If statement"), :$paramcount, :argcount("0 or 1"))
                if $paramcount > 1;
            for @($c.parameterlist) Z $expr -> ($param, $arg) {
                $runtime.declare-var($param.name, $arg);
            }
            $.block.statementlist.run($runtime);
            $runtime.leave;
        }
    }
    method interpolate($runtime) {
        self.new($.expr.interpolate($runtime), $.block.interpolate($runtime));
    }
}

role Q::Statement::Block does Q::Statement {
    has $.block;
    method new(Q::Block $block) { self.bless(:$block) }

    method run($runtime) {
        $runtime.enter($.block.eval($runtime));
        $.block.statementlist.run($runtime);
        $runtime.leave;
    }
    method interpolate($runtime) {
        self.new($.block.interpolate($runtime));
    }
}

role Q::CompUnit does Q::Statement::Block {
}

role Q::Statement::For does Q::Statement {
    has $.expr;
    has $.block;
    method new($expr, Q::Block $block) { self.bless(:$expr, :$block) }

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
        my $count = $c.parameterlist.elems;

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
                for @($c.parameterlist) Z $arg.list -> ($param, $real_arg) {
                    $runtime.declare-var($param.name, $real_arg);
                }
                $.block.statementlist.run($runtime);
                $runtime.leave;
            }
        }
    }
    method interpolate($runtime) {
        self.new($.expr.interpolate($runtime), $.block.interpolate($runtime));
    }
}

role Q::Statement::While does Q::Statement {
    has $.expr;
    has $.block;
    method new($expr, Q::Block $block) { self.bless(:$expr, :$block) }

    method run($runtime) {
        while (my $expr = $.expr.eval($runtime)).truthy {
            my $c = $.block.eval($runtime);
            $runtime.enter($c);
            my $paramcount = $c.parameterlist.elems;
            die X::ParameterMismatch.new(
                :type("While loop"), :$paramcount, :argcount("0 or 1"))
                if $paramcount > 1;
            for @($c.parameterlist) Z $expr -> ($param, $arg) {
                $runtime.declare-var($param.name, $arg);
            }
            $.block.statementlist.run($runtime);
            $runtime.leave;
        }
    }
    method interpolate($runtime) {
        self.new($.expr.interpolate($runtime), $.block.interpolate($runtime));
    }
}

role Q::Statement::Return does Q::Statement {
    has $.expr;
    sub NONE { role { method eval($) { Val::None.new }; method Str { "(no return value)" } } }
    method new($expr = NONE) { self.bless(:$expr) }

    method run($runtime) {
        my $frame = $runtime.get-var("--RETURN-TO--");
        die X::Control::Return.new(:value($.expr.eval($runtime)), :$frame);
    }
    method interpolate($runtime) {
        self.new($.expr.interpolate($runtime));
    }
}

role Q::Statement::Sub does Q::Statement {
    has $.ident;
    has $.block;

    method new($ident, $block) {
        self.bless(:$ident, :$block);
    }

    method run($runtime) {
    }
    method interpolate($runtime) {
        self.new($.ident.interpolate($runtime),
            $.block.interpolate($runtime));
    }
}

role Q::Statement::Macro does Q::Statement {
    has $.ident;
    has $.block;

    method new($ident, $block) {
        self.bless(:$ident, :$block);
    }

    method run($runtime) {
    }
    method interpolate($runtime) {
        self.new($.ident.interpolate($runtime),
            $.block.interpolate($runtime));
    }
}

role Q::Statement::BEGIN does Q::Statement {
    has $.block;
    method new(Q::Block $block) { self.bless(:$block) }

    method run($runtime) {
        # a BEGIN block does not run at runtime
    }
    method interpolate($runtime) {
        self.new($.block.interpolate($runtime));
    }
}

role Q::StatementList does Q {
    has @.statements handles <elems Numeric Real list>;
    method new(*@statements) { self.bless(:@statements) }

    method run($runtime) {
        for @.statements -> $statement {
            $statement.run($runtime);
        }
    }
    method interpolate($runtime) {
        self.new(@.statements».interpolate($runtime));
    }
}

role Q::Trait does Q {
    has $.ident;
    has $.expr;

    method new($ident, $expr) {
        self.bless(:$ident, :$expr);
    }

    method interpolate($runtime) {
        self.new($.ident.interpolate($runtime), $.expr.interpolate($runtime));
    }
}

role Q::Term::Quasi does Q::Term {
    has $.block;
    method new($block) { self.bless(:$block) }

    method eval($runtime) {
        return $.block.interpolate($runtime);
    }
    method interpolate($runtime) {
        self.new($.statementlist.interpolate($runtime));
        # XXX: the fact that we keep interpolating inside of the quasi means
        # that unquotes encountered inside of this inner quasi will be
        # interpolated in the context of the outer quasi. is this correct?
        # can we come up with a case where it matters?
    }
}
