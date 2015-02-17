use _007::Val;

class X::Control::Return is Exception {
    has $.frame;
    has $.value;
}

class X::Subscript::TooLarge is Exception {
}

role Q {
}

sub children(*@c) {
    "\n" ~ @c.join("\n").indent(2)
}

multi truthy(Val::None) is export { False }
multi truthy(Val::Int $i) { ?$i.value }
multi truthy(Val::Str $s) { ?$s.value }
multi truthy(Val::Array $a) { ?$a.elements }

role Q::Literal::Int does Q {
    has $.value;
    method new(Int $value) { self.bless(:$value) }
    method Str { "Int[$.value]" }

    method eval($) { Val::Int.new(:$.value) }
}

role Q::Literal::Str does Q {
    has $.value;
    method new(Str $value) { self.bless(:$value) }
    method Str { qq[Str["$.value"]] }

    method eval($) { Val::Str.new(:$.value) }
}

role Q::Literal::Array does Q {
    has @.elements;
    method new(*@elements) {
        self.bless(:@elements)
    }
    method Str { "Array" ~ children(@.elements) }

    method eval($runtime) {
        Val::Array.new(:elements(@.elements>>.eval($runtime)));
    }
}

role Q::Literal::Block does Q {
    has $.parameters;
    has $.statements;
    method new($parameters, $statements) { self.bless(:$parameters, :$statements) }
    method Str { "Block" ~ children($.parameters, $.statements) }

    method eval($runtime) {
        my $outer-frame = $runtime.current-frame;
        Val::Block.new(:$.parameters, :$.statements, :$outer-frame);
    }
}

role Q::Identifier does Q {
    has $.name;
    method new(Str $name) { self.bless(:$name) }
    method Str { "Identifier[$.name]" }

    method eval($runtime) {
        return $runtime.get-var($.name);
    }
}

role Q::Prefix does Q {
    has $.expr;
    has $.type = "";
    method new($expr) { self.bless(:$expr) }
    method Str { "Prefix" ~ self.type ~ children($.expr) }

    method eval($runtime) { ... }
}

role Q::Prefix::Minus does Q::Prefix {
    method type { "[-]" }
    method eval($runtime) {
        my $expr = $.expr.eval($runtime);
        die X::TypeCheck.new(:operation<->, :got($expr), :expected(Val::Int))
            unless $expr ~~ Val::Int;
        return Val::Int.new(:value(-$expr.value));
    }
}

role Q::Infix does Q {
    has $.lhs;
    has $.rhs;
    has $.type = "";
    method new($lhs, $rhs) { self.bless(:$lhs, :$rhs) }
    method Str { "Infix" ~ self.type ~ children($.lhs, $.rhs) }

    method eval($runtime) { ... }
}

role Q::Infix::Addition does Q::Infix {
    method type { "[+]" }
    method eval($runtime) {
        my $lhs = $.lhs.eval($runtime);
        die X::TypeCheck.new(:operation<+>, :got($lhs), :expected(Val::Int))
            unless $lhs ~~ Val::Int;
        my $rhs = $.rhs.eval($runtime);
        die X::TypeCheck.new(:operation<+>, :got($rhs), :expected(Val::Int))
            unless $rhs ~~ Val::Int;
        return Val::Int.new(:value(
            $lhs.value + $rhs.value
        ));
    }
}

role Q::Infix::Concat does Q::Infix {
    method type { "[~]" }
    method eval($runtime) {
        my $lhs = $.lhs.eval($runtime);
        die X::TypeCheck.new(:operation<~>, :got($lhs), :expected(Val::Str))
            unless $lhs ~~ Val::Str;
        my $rhs = $.rhs.eval($runtime);
        die X::TypeCheck.new(:operation<~>, :got($rhs), :expected(Val::Str))
            unless $rhs ~~ Val::Str;
        return Val::Str.new(:value(
            $lhs.value ~ $rhs.value
        ));
    }
}

role Q::Infix::Assignment does Q::Infix {
    method type { "[=]" }
    method eval($runtime) {
        die "Needs to be an identifier on the left"     # XXX: Turn this into an X::
            unless $.lhs ~~ Q::Identifier;
        my $value = $.rhs.eval($runtime);
        $runtime.put-var($.lhs.name, $value);
        return $value;
    }
}

role Q::Infix::Eq does Q::Infix {
    method type { "[==]" }
    method eval($runtime) {
        multi equal-value(Val $, Val $) { False }
        multi equal-value(Val::None, Val::None) { True }
        multi equal-value(Val::Int $r, Val::Int $l) { $r.value == $l.value }
        multi equal-value(Val::Str $r, Val::Str $l) { $r.value eq $l.value }
        multi equal-value(Val::Array $r, Val::Array $l) {
            return False unless $r.elements == $l.elements;
            for $r.elements.list Z $l.elements.list -> ($re, $le) {
                return False unless equal-value($re, $le);
            }
            return True;
        }

        my $r = $.rhs.eval($runtime);
        my $l = $.lhs.eval($runtime);
        # converting Bool->Int because the implemented language doesn't have Bool
        my $equal = +equal-value($r, $l);
        return Val::Int.new(:value($equal));
    }
}

role Q::Infix::Custom[$type] does Q::Infix {
    method type { $type }

    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        my $r = $.rhs.eval($runtime);
        my $c = $runtime.get-var("infix:<$type>");
        return $runtime.call($c, [$l, $r]);
    }
}

role Q::Postfix::Index does Q {
    has $.array;
    has $.index;
    method new($array, $index) { self.bless(:$array, :$index) }
    method Str { "Index" ~ children($.array, $.index) }

    method eval($runtime) {
        my $array = $runtime.get-var($.array.name);
        die X::TypeCheck.new(:operation<indexing>, :got($array), :expected(Val::Array))
            unless $array ~~ Val::Array;
        my $index = $.index.eval($runtime);
        # XXX: also check index is integer
        die X::Subscript::TooLarge.new
            if $index.value >= $array.elements;
        die X::Subscript::Negative.new(:$index, :type([]))
            if $index.value < 0;
        return $array.elements[$index.value];
    }
}

role Q::Postfix::Call does Q {
    has $.expr;
    has $.arguments;
    method new($expr, $arguments) { self.bless(:$expr, :$arguments) }
    method Str { "Call" ~ children($.expr, $.arguments) }

    method eval($runtime) {
        my $c = $.expr.eval($runtime);
        die "macro is called at runtime"
            if $c ~~ Val::Macro;
        die "Trying to invoke a {$c.^name.subst(/^'Val::'/, '')}" # XXX: make this into an X::
            unless $c ~~ Val::Block;
        my @args = $.arguments.arguments».eval($runtime);
        return $runtime.call($c, @args);
    }
}

role Q::Statement::My does Q {
    has $.ident;
    has $.assignment;
    method new($ident, $assignment = Nil) { self.bless(:$ident, :$assignment) }
    method Str { "My" ~ children($.ident, |$.assignment) }

    method declare($runtime) {
        $runtime.declare-var($.ident.name);
    }

    method run($runtime) {
        return
            unless $.assignment;
        $.assignment.eval($runtime);
    }
}

role Q::Statement::Constant does Q {
    has $.ident;
    has $.assignment;
    method new($ident, $assignment = Nil) { self.bless(:$ident, :$assignment) }
    method Str { "Constant" ~ children($.ident, |$.assignment) }    # XXX: remove | once we guarantee it

    method declare($runtime) {
        $runtime.declare-var($.ident.name);
    }

    method run($runtime) {
        # value has already been assigned
    }
}

role Q::Statement::Expr does Q {
    has $.expr;
    method new($expr) { self.bless(:$expr) }
    method Str { "Expr" ~ children($.expr) }

    method declare($runtime) {
        # an expression statement makes no declarations
    }

    method run($runtime) {
        $.expr.eval($runtime);
    }
}

role Q::Statement::If does Q {
    has $.expr;
    has $.block;
    method new($expr, Q::Literal::Block $block) { self.bless(:$expr, :$block) }
    method Str { "If" ~ children($.expr, $.block) }

    method declare($runtime) {
        # an if statement makes no declarations
    }

    method run($runtime) {
        my $expr = $.expr.eval($runtime);
        if truthy($expr) {
            my $c = $.block.eval($runtime);
            $runtime.enter($c);
            die "Too many parameters in if statements"  # XXX: needs a test and a real exception
                if $c.parameters.parameters > 1;
            for $c.parameters.parameters Z $expr -> ($param, $arg) {
                $runtime.declare-var($param.name);
                $runtime.put-var($param.name, $arg);
            }
            $.block.statements.run($runtime);
            $runtime.leave;
        }
    }
}

role Q::Statement::Block does Q {
    has $.block;
    method new(Q::Literal::Block $block) { self.bless(:$block) }
    method Str { "Statement block" ~ children($.block) }

    method declare($runtime) {
        # an immediate block statement makes no declarations
    }

    method run($runtime) {
        my $c = $.block.eval($runtime);
        $runtime.enter($c);
        $.block.statements.run($runtime);
        $runtime.leave;
    }
}

role Q::Quasi does Q {
    has $.statements;
    method new($statements) { self.bless(:$statements) }
    method Str { "Quasi" ~ children($.statements) }

    method eval($runtime) {
        my $parameters = Q::Parameters.new();
        my $block = Q::Literal::Block.new($parameters, $.statements);
        return Q::Statement::Block.new($block);
    }
}

role Q::Statement::For does Q {
    has $.expr;
    has $.block;
    method new($expr, Q::Literal::Block $block) { self.bless(:$expr, :$block) }
    method Str { "For" ~  children($.expr, $.block)}

    method declare($runtime) {
        # nothing is here so far
    }
    method run($runtime) {
        multi elements(Q::Literal::Array $array) {
            return $array.elements>>.value;
        }

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
        my $count = $c.parameters.parameters.elems;

        if $count == 0 {
            for ^elements($.expr).elems {
                $runtime.enter($c);
                $.block.statements.run($runtime);
                $runtime.leave;
            }
        }
        else {
            for split_elements(elements($.expr), $count) -> $arg {
                $runtime.enter($c);
                for $c.parameters.parameters Z $arg.list -> ($param, $real_arg) {
                    $runtime.declare-var($param.name);
                    $runtime.put-var($param.name, $real_arg);
                }
                $.block.statements.run($runtime);
                $runtime.leave;
            }
        }
    }
}

role Q::Statement::While does Q {
    has $.expr;
    has $.block;
    method new($expr, Q::Literal::Block $block) { self.bless(:$expr, :$block) }
    method Str { "While" ~ children($.expr, $.block) }

    method declare($runtime) {
        # a while loop makes no declarations
    }

    method run($runtime) {
        while truthy($.expr.eval($runtime)) {
            my $c = $.block.eval($runtime);
            $runtime.enter($c);
            $.block.statements.run($runtime);
            $runtime.leave;
        }
    }
}

role Q::Statement::Return does Q {
    has $.expr;
    sub NONE { role { method eval($) { Val::None.new }; method Str { "(no return value)" } } }
    method new($expr = NONE) { self.bless(:$expr) }
    method Str { "Return" ~ children($.expr) }

    method declare($runtime) {
        # a return statement makes no declarations
    }

    method run($runtime) {
        my $frame = $runtime.get-var("--RETURN-TO--");
        die X::Control::Return.new(:value($.expr.eval($runtime)), :$frame);
    }
}

role Q::Statement::Sub does Q {
    has $.ident;
    has $.parameters;
    has $.statements;

    method new($ident, $parameters, $statements) {
        self.bless(:$ident, :$parameters, :$statements);
    }
    method Str { "Sub[{$.ident.name}]" ~ children($.parameters, $.statements) }

    method declare($runtime) {
        my $name = $.ident.name;
        my $outer-frame = $runtime.current-frame;
        my $sub = Val::Sub.new(:$name, :$.parameters, :$.statements, :$outer-frame);
        $runtime.declare-var($name);
        $runtime.put-var($name, $sub);
    }

    method run($runtime) {
    }
}

role Q::Statement::Macro does Q {
    has $.ident;
    has $.parameters;
    has $.statements;

    method new($ident, $parameters, $statements) {
        self.bless(:$ident, :$parameters, :$statements);
    }
    method Str { "Macro[{$.ident.name}]" ~ children($.parameters, $.statements) }

    method declare($runtime) {
        my $name = $.ident.name;
        my $outer-frame = $runtime.current-frame;
        my $macro = Val::Macro.new(:$name, :$.parameters, :$.statements, :$outer-frame);
        $runtime.declare-var($name);
        $runtime.put-var($name, $macro);
    }

    method run($runtime) {
    }
}

role Q::Statement::BEGIN does Q {
    has $.block;
    method new(Q::Literal::Block $block) { self.bless(:$block) }
    method Str { "BEGIN block" ~ children($.block) }

    method declare($runtime) {
        # a BEGIN block makes no declarations
    }

    method run($runtime) {
        # a BEGIN block does not run at runtime
    }
}

role Q::Statements does Q {
    has @.statements;
    has %.static-lexpad is rw;
    method new(*@statements) { self.bless(:@statements) }
    method Str { "Statements" ~ children(@.statements) }

    method run($runtime) {
        for @.statements -> $statement {
            $statement.run($runtime);
        }
    }
}

role Q::Parameters does Q {
    has @.parameters;
    method new(*@parameters) { self.bless(:@parameters) }
    method Str { "Parameters" ~ children(@.parameters) }
}

role Q::Arguments does Q {
    has @.arguments;
    method new(*@arguments) { self.bless(:@arguments) }
    method Str { "Arguments" ~ children(@.arguments) }
}
