use _007::Val;
use _007::Q;

sub builtins(:$input!, :$output!, :$opscope!) is export {
    sub wrap($_) {
        when _007::Object { $_ }
        when Val | Q { $_ }
        when Nil  { NONE }
        when Bool { Val::Bool.new(:value($_)) }
        when Str  { die "A Str was sent to &wrap" }
        default { die "Got some unknown value of type ", .^name }
    }

    # These multis are used below by infix:<==> and infix:<!=>
    multi equal-value($, $) { False }
    multi equal-value(Val::Bool $l, Val::Bool $r) { $l.value == $r.value }
    multi equal-value(_007::Object $l, _007::Object $r) {
        return False
            unless $l.type === $r.type;
        my $type = $l.type;
        if $type === TYPE<Int> {
            return $l.value == $r.value;
        }
        elsif $type === TYPE<Str> {
            return $l.value eq $r.value;
        }
        elsif $type === TYPE<Array> {
            if %*equality-seen{$l.WHICH} && %*equality-seen{$r.WHICH} {
                return $l === $r;
            }
            %*equality-seen{$l.WHICH}++;
            %*equality-seen{$r.WHICH}++;

            sub equal-at-index($i) {
                equal-value($l.value[$i], $r.value[$i]);
            }

            return [&&] $l.value == $r.value, |(^$l.value).map(&equal-at-index);
        }
        elsif $type === TYPE<NoneType> {
            return True;
        }
        else {
            die "Unknown type ", $type.Str;
        }
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
    multi equal-value(_007::Type $l, _007::Type $r) { $l === $r }
    multi equal-value(Val::Type $l, Val::Type $r) {
        $l.type === $r.type
    }
    multi equal-value(Val::Sub $l, Val::Sub $r) {
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
            :expected(_007::Object));
    }
    multi less-value(_007::Object $l, _007::Object $r) {
        die X::TypeCheck.new(:operation<less>, :got($_), :expected(_007::Object))
            unless $l.type === $r.type;
        my $type = $l.type;
        return $type === TYPE<Int>
            ?? $l.value < $r.value
            !! $type === TYPE<Str>
                ?? $l.value lt $r.value
                !! die "Unknown type ", $type.Str;
    }
    multi more-value($, $) {
        die X::TypeCheck.new(
            :operation<more>,
            :got($_),
            :expected(_007::Object));
    }
    multi more-value(_007::Object $l, _007::Object $r) {
        die X::TypeCheck.new(:operation<less>, :got($_), :expected(_007::Object))
            unless $l.type === $r.type;
        my $type = $l.type;
        return $type === TYPE<Int>
            ?? $l.value > $r.value
            !! $type === TYPE<Str>
                ?? $l.value gt $r.value
                !! die "Unknown type ", $type.Str;
    }

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
            $output.print($arg ~ "\n");
            Nil;
        },
        prompt => sub ($arg) {
            $output.print($arg);
            $output.flush();
            return sevenize($input.get());
        },
        type => sub ($arg) {
            $arg ~~ _007::Type
                ?? TYPE<Type>
                !! $arg ~~ _007::Object
                    ?? $arg.type
                    !! Val::Type.of($arg.WHAT);
        },

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
            :precedence{ equal => "infix:||" },
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
            :precedence{ equal => "infix:==" },
        ),
        'infix:<' => op(
            sub ($lhs, $rhs) {
                return wrap(less-value($lhs, $rhs))
            },
            :qtype(Q::Infix::Lt),
            :precedence{ equal => "infix:==" },
        ),
        'infix:<=' => op(
            sub ($lhs, $rhs) {
                my %*equality-seen;
                return wrap(less-value($lhs, $rhs) || equal-value($lhs, $rhs))
            },
            :qtype(Q::Infix::Le),
            :precedence{ equal => "infix:==" },
        ),
        'infix:>' => op(
            sub ($lhs, $rhs) {
                return wrap(more-value($lhs, $rhs) )
            },
            :qtype(Q::Infix::Gt),
            :precedence{ equal => "infix:==" },
        ),
        'infix:>=' => op(
            sub ($lhs, $rhs) {
                my %*equality-seen;
                return wrap(more-value($lhs, $rhs) || equal-value($lhs, $rhs))
            },
            :qtype(Q::Infix::Ge),
            :precedence{ equal => "infix:==" },
        ),
        'infix:~~' => op(
            sub ($lhs, $rhs) {
                if $rhs ~~ _007::Type {
                    return wrap($lhs ~~ _007::Object && $lhs.type === $rhs);
                }

                die X::TypeCheck.new(:operation<~~>, :got($rhs), :expected(Val::Type))
                    unless $rhs ~~ Val::Type;

                return wrap($lhs ~~ $rhs.type);
            },
            :qtype(Q::Infix::TypeMatch),
            :precedence{ equal => "infix:==" },
        ),
        'infix:!~~' => op(
            sub ($lhs, $rhs) {
                if $rhs ~~ _007::Type {
                    return wrap($lhs !~~ _007::Object || $lhs.type !=== $rhs);
                }

                die X::TypeCheck.new(:operation<~~>, :got($rhs), :expected(Val::Type))
                    unless $rhs ~~ Val::Type | _007::Type;

                return wrap($lhs !~~ $rhs.type);
            },
            :qtype(Q::Infix::TypeNonMatch),
            :precedence{ equal => "infix:==" },
        ),

        # cons precedence
        'infix:::' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<::>, :got($rhs), :expected(_007::Object))
                    unless $rhs ~~ _007::Object && $rhs.type === TYPE<Array>;
                return sevenize([$lhs, |$rhs.value]);
            },
            :qtype(Q::Infix::Cons),
            :assoc<right>,
        ),

        # additive precedence
        'infix:+' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<+>, :got($lhs), :expected(_007::Object))
                    unless $lhs ~~ _007::Object && $lhs.type === TYPE<Int>;
                die X::TypeCheck.new(:operation<+>, :got($rhs), :expected(_007::Object))
                    unless $rhs ~~ _007::Object && $rhs.type === TYPE<Int>;
                return sevenize($lhs.value + $rhs.value);
            },
            :qtype(Q::Infix::Addition),
        ),
        'infix:~' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<~>, :got($lhs), :expected(_007::Object))
                    unless $lhs ~~ _007::Object && $lhs.type === TYPE<Str>;
                die X::TypeCheck.new(:operation<~>, :got($rhs), :expected(_007::Object))
                    unless $rhs ~~ _007::Object && $rhs.type === TYPE<Str>;
                return sevenize($lhs.value ~ $rhs.value);
            },
            :qtype(Q::Infix::Concat),
            :precedence{ equal => "infix:+" },
        ),
        'infix:-' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<->, :got($lhs), :expected(_007::Object))
                    unless $lhs ~~ _007::Object && $lhs.type === TYPE<Int>;
                die X::TypeCheck.new(:operation<->, :got($rhs), :expected(_007::Object))
                    unless $rhs ~~ _007::Object && $rhs.type === TYPE<Int>;
                return sevenize($lhs.value - $rhs.value);
            },
            :qtype(Q::Infix::Subtraction),
        ),

        # multiplicative precedence
        'infix:*' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<*>, :got($lhs), :expected(_007::Object))
                    unless $lhs ~~ _007::Object && $lhs.type === TYPE<Int>;
                die X::TypeCheck.new(:operation<*>, :got($rhs), :expected(_007::Object))
                    unless $rhs ~~ _007::Object && $rhs.type === TYPE<Int>;
                return sevenize($lhs.value * $rhs.value);
            },
            :qtype(Q::Infix::Multiplication),
        ),
        'infix:%' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<%>, :got($lhs), :expected(_007::Object))
                    unless $lhs ~~ _007::Object && $lhs.type === TYPE<Int>;
                die X::TypeCheck.new(:operation<%>, :got($rhs), :expected(_007::Object))
                    unless $rhs ~~ _007::Object && $rhs.type === TYPE<Int>;
                die X::Numeric::DivideByZero.new(:using<%>, :numerator($lhs.value))
                    if $rhs.value == 0;
                return sevenize($lhs.value % $rhs.value);
            },
            :qtype(Q::Infix::Modulo),
        ),
        'infix:%%' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<%%>, :got($lhs), :expected(_007::Object))
                    unless $lhs ~~ _007::Object && $lhs.type === TYPE<Int>;
                die X::TypeCheck.new(:operation<%%>, :got($rhs), :expected(_007::Object))
                    unless $rhs ~~ _007::Object && $rhs.type === TYPE<Int>;
                die X::Numeric::DivideByZero.new(:using<%%>, :numerator($lhs.value))
                    if $rhs.value == 0;
                return wrap($lhs.value %% $rhs.value);
            },
            :qtype(Q::Infix::Divisibility),
        ),
        'infix:x' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<x>, :got($lhs), :expected(_007::Object))
                    unless $lhs ~~ _007::Object && $lhs.type === TYPE<Str>;
                die X::TypeCheck.new(:operation<x>, :got($rhs), :expected(_007::Object))
                    unless $rhs ~~ _007::Object && $rhs.type === TYPE<Int>;
                return sevenize($lhs.value x $rhs.value);
            },
            :qtype(Q::Infix::Replicate),
            :precedence{ equal => "infix:*" },
        ),
        'infix:xx' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<xx>, :got($lhs), :expected(_007::Object))
                    unless $lhs ~~ _007::Object && $lhs.type === TYPE<Array>;
                die X::TypeCheck.new(:operation<xx>, :got($rhs), :expected(_007::Object))
                    unless $rhs ~~ _007::Object && $rhs.type === TYPE<Int>;
                return sevenize(| $lhs.value xx $rhs.value);
            },
            :qtype(Q::Infix::ArrayReplicate),
            :precedence{ equal => "infix:*" },
        ),

        # prefixes
        'prefix:~' => op(
            sub prefix-str($expr) { sevenize($expr.Str) },
            :qtype(Q::Prefix::Str),
        ),
        'prefix:+' => op(
            sub prefix-plus($expr) {
                if $expr ~~ _007::Object {
                    if $expr.type === TYPE<Str> {
                        return sevenize($expr.value.Int)
                            if $expr.value ~~ /^ '-'? \d+ $/;
                    }
                    elsif $expr.type === TYPE<Int> {
                        return $expr;
                    }
                }
                die X::TypeCheck.new(
                    :operation("prefix:<+>"),
                    :got($expr),
                    :expected(_007::Object));
            },
            :qtype(Q::Prefix::Plus),
        ),
        'prefix:-' => op(
            sub prefix-minus($expr) {
                if $expr ~~ _007::Object {
                    if $expr.type === TYPE<Str> {
                        return sevenize(-$expr.value.Int)
                            if $expr.value ~~ /^ '-'? \d+ $/;
                    }
                    elsif $expr.type === TYPE<Int> {
                        return sevenize(-$expr.value);
                    }
                }
                die X::TypeCheck.new(
                    :operation("prefix:<->"),
                    :got($expr),
                    :expected(_007::Object));
            },
            :qtype(Q::Prefix::Minus),
        ),
        'prefix:?' => op(
            sub ($a) {
                return wrap(?$a.truthy)
            },
            :qtype(Q::Prefix::So),
        ),
        'prefix:!' => op(
            sub ($a) {
                return wrap(!$a.truthy)
            },
            :qtype(Q::Prefix::Not),
        ),
        'prefix:^' => op(
            sub ($n) {
                die X::TypeCheck.new(:operation<^>, :got($n), :expected(_007::Object))
                    unless $n ~~ _007::Object && $n.type === TYPE<Int>;
                return sevenize([(^$n.value).map(&sevenize)]);
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
    push @builtins, "Q" => Val::Type.of(Q);
    for TYPE.keys -> $type {
        next if $type eq "Type";
        push @builtins, ($type => TYPE{$type});
    }

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
    my &parameter = { Q::Parameter.new(:identifier(Q::Identifier.new(:name(sevenize($^value))))) };

    return @builtins.map: {
        when .value ~~ _007::Type | Val::Type {
            .key => .value;
        }
        when .value ~~ Block {
            my @elements = .value.signature.params».name».&ditch-sigil».&parameter;
            my $parameters = sevenize(@elements);
            my $parameterlist = Q::ParameterList.new(:$parameters);
            my $statementlist = Q::StatementList.new();
            .key => Val::Sub.new-builtin(.value, .key, $parameterlist, $statementlist);
        }
        when .value ~~ Placeholder::MacroOp {
            my $name = .key;
            install-op($name, .value);
            my @elements = .value.qtype.attributes».name».substr(2).grep({ $_ ne "identifier" })».&parameter;
            my $parameters = sevenize(@elements);
            my $parameterlist = Q::ParameterList.new(:$parameters);
            my $statementlist = Q::StatementList.new();
            .key => Val::Sub.new-builtin(sub () {}, $name, $parameterlist, $statementlist);
        }
        when .value ~~ Placeholder::Op {
            my $name = .key;
            install-op($name, .value);
            my &fn = .value.fn;
            my @elements = &fn.signature.params».name».&ditch-sigil».&parameter;
            my $parameters = sevenize(@elements);
            my $parameterlist = Q::ParameterList.new(:$parameters);
            my $statementlist = Q::StatementList.new();
            .key => Val::Sub.new-builtin(&fn, $name, $parameterlist, $statementlist);
        }
        default { die "Unknown type {.value.^name}" }
    };
}
