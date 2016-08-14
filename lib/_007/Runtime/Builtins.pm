use _007::Val;
use _007::Q;

sub builtins(:$input!, :$output!, :$opscope!) is export {
    my &str = sub ($_) {
        when Val { return Val::Str.new(:value(.Str)) }
        die X::TypeCheck.new(
            :operation<str()>,
            :got($_),
            :expected("something that can be converted to a string"));
    };

    sub wrap($_) {
        when Val | Q { $_ }
        when Nil  { NONE }
        when Bool { Val::Bool.new(:value($_)) }
        when Int  { Val::Int.new(:value($_)) }
        when Str  { Val::Str.new(:value($_)) }
        when Array | Seq | List { Val::Array.new(:elements(.map(&wrap))) }
        default { die "Got some unknown value of type ", .^name }
    }

    # These multis are used below by infix:<==> and infix:<!=>
    multi equal-value($, $) { False }
    multi equal-value(Val::None, Val::None) { True }
    multi equal-value(Val::Bool $l, Val::Bool $r) { $l.value == $r.value }
    multi equal-value(Val::Int $l, Val::Int $r) { $l.value == $r.value }
    multi equal-value(Val::Str $l, Val::Str $r) { $l.value eq $r.value }
    multi equal-value(Val::Array $l, Val::Array $r) {
        if %*equality-seen{$l.WHICH} && %*equality-seen{$r.WHICH} {
            return $l === $r;
        }
        %*equality-seen{$l.WHICH}++;
        %*equality-seen{$r.WHICH}++;

        sub equal-at-index($i) {
            equal-value($l.elements[$i], $r.elements[$i]);
        }

        [&&] $l.elements == $r.elements,
            |(^$l.elements).map(&equal-at-index);
    }
    multi equal-value(Val::Object $l, Val::Object $r) {
        if %*equality-seen{$l.WHICH} && %*equality-seen{$r.WHICH} {
            return $l === $r;
        }
        %*equality-seen{$l.WHICH}++;
        %*equality-seen{$r.WHICH}++;

        sub equal-at-key(Str $key) {
            equal-value($l.properties{$key}, $r.properties{$key});
        }

        [&&] $l.properties.keys.sort.perl eq $r.properties.keys.sort.perl,
            |($l.properties.keys).map(&equal-at-key);
    }
    multi equal-value(Val::Type $l, Val::Type $r) {
        $l.type === $r.type
    }
    multi equal-value(Val::Block $l, Val::Block $r) {
        $l.name eq $r.name
            && equal-value($l.parameterlist, $r.parameterlist)
            && equal-value($l.statementlist, $r.statementlist)
    }
    multi equal-value(Q $l, Q $r) {
        sub same-avalue($attr) {
            equal-value($attr.get_value($l), $attr.get_value($r));
        }

        [&&] $l.WHAT === $r.WHAT,
            |$l.attributes.map(&same-avalue);
    }

    multi less-value($, $) {
        die X::TypeCheck.new(
            :operation<less>,
            :got($_),
            :expected("string or integer"));
    }
    multi less-value(Val::Int $l, Val::Int $r) { $l.value < $r.value }
    multi less-value(Val::Str $l, Val::Str $r) { $l.value le $r.value }
    multi more-value($, $) {
        die X::TypeCheck.new(
            :operation<more>,
            :got($_),
            :expected("string or integer"));
    }
    multi more-value(Val::Int $l, Val::Int $r) { $l.value > $r.value }
    multi more-value(Val::Str $l, Val::Str $r) { $l.value ge $r.value }

    my role Placeholder {
        has $.qtype;
        has $.assoc;
        has %.precedence;
    }
    my class Placeholder::MacroOp does Placeholder {
    }
    sub macro-op(:$qtype, :$assoc?, :%precedence?) {
        Placeholder::MacroOp.new(:$qtype, :$assoc, :%precedence);
    }

    my class Placeholder::Op does Placeholder {
        has &.fn;
    }
    sub op(&fn, :$qtype, :$assoc?, :%precedence?) {
        Placeholder::Op.new(:&fn, :$qtype, :$assoc, :%precedence);
    }

    my @builtins =
        say => -> $arg {
            my $string = $arg ~~ Val::Array ?? &str($arg).Str !! ~$arg;
            $output.print($string ~ "\n");
            Nil;
        },
        prompt => sub ($arg) {
            $output.print($arg);
            $output.flush();
            return wrap($input.get());
        },
        type => -> $arg { Val::Type.of($arg.WHAT) },
        str => &str,
        int => sub ($_) {
            when Val::Str {
                return wrap(.value.Int)
                    if .value ~~ /^ '-'? \d+ $/;
                proceed;
            }
            when Val::Int {
                return $_;
            }
            die X::TypeCheck.new(
                :operation<int()>,
                :got($_),
                :expected(Val::Int));
        },
        min => -> $a, $b { wrap(min($a.value, $b.value)) },
        max => -> $a, $b { wrap(max($a.value, $b.value)) },

        # OPERATORS (from loosest to tightest within each category)

        # assignment precedence
        'infix:=' => macro-op(
            :qtype(Q::Infix::Assignment),
            :assoc<right>,
        ),

        # disjunctive precedence
        'infix:||' => macro-op(
            :qtype(Q::Infix::Or),
        ),
        'infix://' => macro-op(
            :qtype(Q::Infix::DefinedOr),
            :precedence{ equal => "||" },
        ),

        # conjunctive precedence
        'infix:&&' => macro-op(
            :qtype(Q::Infix::And),
        ),

        # comparison precedence
        'infix:==' => op(
            sub ($lhs, $rhs) {
                my %*equality-seen;
                return wrap(equal-value($lhs, $rhs));
            },
            :qtype(Q::Infix::Eq),
        ),
        'infix:!=' => op(
            sub ($lhs, $rhs) {
                my %*equality-seen;
                return wrap(!equal-value($lhs, $rhs))
            },
            :qtype(Q::Infix::Ne),
            :precedence{ equal => "==" },
        ),
        'infix:<' => op(
            sub ($lhs, $rhs) {
                return wrap(less-value($lhs, $rhs))
            },
            :qtype(Q::Infix::Lt),
            :precedence{ equal => "==" },
        ),
        'infix:<=' => op(
            sub ($lhs, $rhs) {
                my %*equality-seen;
                return wrap(less-value($lhs, $rhs) || equal-value($lhs, $rhs))
            },
            :qtype(Q::Infix::Le),
            :precedence{ equal => "==" },
        ),
        'infix:>' => op(
            sub ($lhs, $rhs) {
                return wrap(more-value($lhs, $rhs) )
            },
            :qtype(Q::Infix::Gt),
            :precedence{ equal => "==" },
        ),
        'infix:>=' => op(
            sub ($lhs, $rhs) {
                my %*equality-seen;
                return wrap(more-value($lhs, $rhs) || equal-value($lhs, $rhs))
            },
            :qtype(Q::Infix::Ge),
            :precedence{ equal => "==" },
        ),
        'infix:~~' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<~~>, :got($rhs), :expected(Val::Type))
                    unless $rhs ~~ Val::Type;

                return wrap($lhs ~~ $rhs.type);
            },
            :qtype(Q::Infix::TypeMatch),
            :precedence{ equal => "==" },
        ),
        'infix:!~~' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<~~>, :got($rhs), :expected(Val::Type))
                    unless $rhs ~~ Val::Type;

                return wrap($lhs !~~ $rhs.type);
            },
            :qtype(Q::Infix::TypeNonMatch),
            :precedence{ equal => "==" },
        ),

        # cons precedence
        'infix:::' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<::>, :got($rhs), :expected(Val::Array))
                    unless $rhs ~~ Val::Array;
                return wrap([$lhs, |$rhs.elements]);
            },
            :qtype(Q::Infix::Cons),
            :assoc<right>,
        ),

        # additive precedence
        'infix:+' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<+>, :got($lhs), :expected(Val::Int))
                    unless $lhs ~~ Val::Int;
                die X::TypeCheck.new(:operation<+>, :got($rhs), :expected(Val::Int))
                    unless $rhs ~~ Val::Int;
                return wrap($lhs.value + $rhs.value);
            },
            :qtype(Q::Infix::Addition),
        ),
        'infix:~' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<~>, :got($lhs), :expected(Val::Str))
                    unless $lhs ~~ Val::Str;
                die X::TypeCheck.new(:operation<~>, :got($rhs), :expected(Val::Str))
                    unless $rhs ~~ Val::Str;
                return wrap($lhs.value ~ $rhs.value);
            },
            :qtype(Q::Infix::Concat),
            :precedence{ equal => "+" },
        ),
        'infix:-' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<->, :got($lhs), :expected(Val::Int))
                    unless $lhs ~~ Val::Int;
                die X::TypeCheck.new(:operation<->, :got($rhs), :expected(Val::Int))
                    unless $rhs ~~ Val::Int;
                return wrap($lhs.value - $rhs.value);
            },
            :qtype(Q::Infix::Subtraction),
        ),

        # multiplicative precedence
        'infix:*' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<*>, :got($lhs), :expected(Val::Int))
                    unless $lhs ~~ Val::Int;
                die X::TypeCheck.new(:operation<*>, :got($rhs), :expected(Val::Int))
                    unless $rhs ~~ Val::Int;
                return wrap($lhs.value * $rhs.value);
            },
            :qtype(Q::Infix::Multiplication),
        ),
        'infix:%' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<%>, :got($lhs), :expected(Val::Int))
                    unless $lhs ~~ Val::Int;
                die X::TypeCheck.new(:operation<%>, :got($rhs), :expected(Val::Int))
                    unless $rhs ~~ Val::Int;
                die X::Numeric::DivideByZero.new(:using<%>, :numerator($lhs.value))
                    if $rhs.value == 0;
                return wrap($lhs.value % $rhs.value);
            },
            :qtype(Q::Infix::Modulo),
        ),
        'infix:%%' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<%%>, :got($lhs), :expected(Val::Int))
                    unless $lhs ~~ Val::Int;
                die X::TypeCheck.new(:operation<%%>, :got($rhs), :expected(Val::Int))
                    unless $rhs ~~ Val::Int;
                die X::Numeric::DivideByZero.new(:using<%%>, :numerator($lhs.value))
                    if $rhs.value == 0;
                return wrap($lhs.value %% $rhs.value);
            },
            :qtype(Q::Infix::Divisibility),
        ),
        'infix:x' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<x>, :got($lhs), :expected(Val::Str))
                    unless $lhs ~~ Val::Str;
                die X::TypeCheck.new(:operation<x>, :got($rhs), :expected(Val::Int))
                    unless $rhs ~~ Val::Int;
                return wrap($lhs.value x $rhs.value);
            },
            :qtype(Q::Infix::Replicate),
            :precedence{ equal => "*" },
        ),
        'infix:xx' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<xx>, :got($lhs), :expected(Val::Array))
                    unless $lhs ~~ Val::Array;
                die X::TypeCheck.new(:operation<xx>, :got($rhs), :expected(Val::Int))
                    unless $rhs ~~ Val::Int;
                return wrap(| $lhs.elements xx $rhs.value);
            },
            :qtype(Q::Infix::ArrayReplicate),
            :precedence{ equal => "*" },
        ),

        # prefixes
        'prefix:-' => op(
            sub ($expr) {
                die X::TypeCheck.new(:operation<->, :got($expr), :expected(Val::Int))
                    unless $expr ~~ Val::Int;
                return wrap(-$expr.value);
            },
            :qtype(Q::Prefix::Minus),
        ),
        'prefix:!' => op(
            sub ($a) {
                return wrap(!$a.truthy)
            },
            :qtype(Q::Prefix::Not),
        ),
        'prefix:^' => op(
            sub ($n) {
                die X::TypeCheck.new(:operation<^>, :got($n), :expected(Val::Int))
                    unless $n ~~ Val::Int;
                return wrap([^$n.value]);
            },
            :qtype(Q::Prefix::Upto),
        ),

        # postfixes
        'postfix:[]' => macro-op(
            :qtype(Q::Postfix::Index),
        ),
        'postfix:()' => macro-op(
            :qtype(Q::Postfix::Call),
        ),
        'postfix:.' => macro-op(
            :qtype(Q::Postfix::Property),
        ),
    ;

    sub tree-walk(%package) {
        for %package.keys.map({ %package ~ "::$_" }) -> $name {
            my $type = ::($name);
            push @builtins, ($type.^name.subst("Val::", "") => Val::Type.of($type));
            tree-walk($type.WHO);
        }
    }
    tree-walk(Val::);
    tree-walk(Q::);

    sub install-op($name, $placeholder) {
        $name ~~ /^ (prefix | infix | postfix) ':' (.+) $/
            or die "This shouldn't be an op";
        my $type = ~$0;
        my $opname = ~$1;
        my $qtype = $placeholder.qtype;
        my $assoc = $placeholder.assoc;
        my %precedence = $placeholder.precedence;
        $opscope.install($type, $opname, $qtype, :$assoc, :%precedence);
    }

    my &ditch-sigil = { $^str.substr(1) };
    my &parameter = { Q::Parameter.new(:identifier(Q::Identifier.new(:name(Val::Str.new(:$^value))))) };

    return @builtins.map: {
        when .value ~~ Val::Type {
            .key => .value;
        }
        when .value ~~ Block {
            my @elements = .value.signature.params».name».&ditch-sigil».&parameter;
            my $parameterlist = Q::ParameterList.new(:parameters(Val::Array.new(:@elements)));
            my $statementlist = Q::StatementList.new();
            .key => Val::Sub.new-builtin(.value, .key, $parameterlist, $statementlist);
        }
        when .value ~~ Placeholder::MacroOp {
            my $name = .key;
            install-op($name, .value);
            my @elements = .value.qtype.attributes».name».substr(2).grep({ $_ ne "identifier" })».&parameter;
            my $parameterlist = Q::ParameterList.new(:parameters(Val::Array.new(:@elements)));
            my $statementlist = Q::StatementList.new();
            .key => Val::Sub.new-builtin(sub () {}, $name, $parameterlist, $statementlist);
        }
        when .value ~~ Placeholder::Op {
            my $name = .key;
            install-op($name, .value);
            my &fn = .value.fn;
            my @elements = &fn.signature.params».name».&ditch-sigil».&parameter;
            my $parameterlist = Q::ParameterList.new(:parameters(Val::Array.new(:@elements)));
            my $statementlist = Q::StatementList.new();
            .key => Val::Sub.new-builtin(&fn, $name, $parameterlist, $statementlist);
        }
        default { die "Unknown type {.value.^name}" }
    };
}
