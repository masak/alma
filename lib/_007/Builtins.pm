use _007::Type;
use _007::Object;

sub builtins(:$input!, :$output!, :$opscope!, :$runtime) is export {
    # These multis are used below by infix:<==> and infix:<!=>
    multi equal-value($, $) { False }
    multi equal-value(_007::Object $l, _007::Object $r) {
        return False
            unless $l.type === $r.type;
        if $l.is-a("Int") {
            return $l.value == $r.value;
        }
        elsif $l.is-a("Str") {
            return $l.value eq $r.value;
        }
        elsif $l.is-a("Array") {
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
        elsif $l.is-a("Dict") {
            if %*equality-seen{$l.WHICH} && %*equality-seen{$r.WHICH} {
                return $l === $r;
            }
            %*equality-seen{$l.WHICH}++;
            %*equality-seen{$r.WHICH}++;

            sub equal-at-key(Str $key) {
                equal-value($l.value{$key}, $r.value{$key});
            }

            return [&&] $l.value.keys.sort.perl eq $r.value.keys.sort.perl, |($l.value.keys).map(&equal-at-key);
        }
        elsif $l.is-a("NoneType") {
            return True;
        }
        elsif $l.is-a("Bool") {
            return $l === $r;
        }
        elsif $l.is-a("Sub") {
            return $l.properties<name>.value eq $r.properties<name>.value
                && equal-value($l.properties<parameterlist>, $r.properties<parameterlist>)
                && equal-value($l.properties<statementlist>, $r.properties<statementlist>);
        }
        elsif $l.is-a("Q") {
            sub same-propvalue($prop) {
                equal-value($l.properties{$prop}, $r.properties{$prop});
            }

            [&&] $l.type === $r.type,
                |$l.type.type-chain.reverse.map({ .fields }).flat.map({ .<name> }).grep({ $_ ne "frame" }).map(&same-propvalue);
        }
        else {
            die "Unknown type ", $l.type.^name;
        }
    }
    multi equal-value(_007::Type $l, _007::Type $r) { $l === $r }

    multi less-value($, $) {
        die X::Type.new(
            :operation<less>,
            :got($_),
            :expected(TYPE<Int>));
    }
    multi less-value(_007::Object $l, _007::Object $r) {
        die X::Type.new(:operation<less>, :got($_), :expected(TYPE<Int>))
            unless $l.type === $r.type;
        return $l.is-a("Int")
            ?? $l.value < $r.value
            !! $l.is-a("Str")
                ?? $l.value lt $r.value
                !! die "Unknown type ", $l.type.Str;
    }
    multi more-value($, $) {
        die X::Type.new(
            :operation<more>,
            :got($_),
            :expected(TYPE<Int>));
    }
    multi more-value(_007::Object $l, _007::Object $r) {
        die X::Type.new(:operation<less>, :got($_), :expected(TYPE<Int>))
            unless $l.type === $r.type;
        return $l.is-a("Int")
            ?? $l.value > $r.value
            !! $l.is-a("Str")
                ?? $l.value gt $r.value
                !! die "Unknown type ", $l.type.Str;
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
            $output.print(stringify($arg, $runtime) ~ "\n");
            Nil;
        },
        prompt => sub ($arg) {
            $output.print($arg);
            $output.flush();
            return wrap($input.get());
        },
        type => sub ($arg) {
            $arg.type;
        },

        # OPERATORS (from loosest to tightest within each category)

        # assignment precedence
        'infix:=' => macro-op(
            :qtype(TYPE<Q::Infix::Assignment>),
            :assoc<right>,
        ),

        # disjunctive precedence
        'infix:||' => macro-op(
            :qtype(TYPE<Q::Infix::Or>),
        ),
        'infix://' => macro-op(
            :qtype(TYPE<Q::Infix::DefinedOr>),
            :precedence{ equal => "infix:||" },
        ),

        # conjunctive precedence
        'infix:&&' => macro-op(
            :qtype(TYPE<Q::Infix::And>),
        ),

        # comparison precedence
        'infix:==' => op(
            sub ($lhs, $rhs) {
                my %*equality-seen;
                return wrap(equal-value($lhs, $rhs));
            },
            :qtype(TYPE<Q::Infix::Eq>),
        ),
        'infix:!=' => op(
            sub ($lhs, $rhs) {
                my %*equality-seen;
                return wrap(!equal-value($lhs, $rhs))
            },
            :qtype(TYPE<Q::Infix::Ne>),
            :precedence{ equal => "infix:==" },
        ),
        'infix:<' => op(
            sub ($lhs, $rhs) {
                return wrap(less-value($lhs, $rhs))
            },
            :qtype(TYPE<Q::Infix::Lt>),
            :precedence{ equal => "infix:==" },
        ),
        'infix:<=' => op(
            sub ($lhs, $rhs) {
                my %*equality-seen;
                return wrap(less-value($lhs, $rhs) || equal-value($lhs, $rhs))
            },
            :qtype(TYPE<Q::Infix::Le>),
            :precedence{ equal => "infix:==" },
        ),
        'infix:>' => op(
            sub ($lhs, $rhs) {
                return wrap(more-value($lhs, $rhs) )
            },
            :qtype(TYPE<Q::Infix::Gt>),
            :precedence{ equal => "infix:==" },
        ),
        'infix:>=' => op(
            sub ($lhs, $rhs) {
                my %*equality-seen;
                return wrap(more-value($lhs, $rhs) || equal-value($lhs, $rhs))
            },
            :qtype(TYPE<Q::Infix::Ge>),
            :precedence{ equal => "infix:==" },
        ),
        'infix:~~' => op(
            sub ($lhs, $rhs) {
                die X::Type.new(:operation<~~>, :got($rhs), :expected(TYPE<Type>))
                    unless $rhs.is-a("Type");

                return wrap(?$lhs.is-a($rhs));
            },
            :qtype(TYPE<Q::Infix::TypeMatch>),
            :precedence{ equal => "infix:==" },
        ),
        'infix:!~~' => op(
            sub ($lhs, $rhs) {
                die X::Type.new(:operation<~~>, :got($rhs), :expected(TYPE<Type>))
                    unless $rhs.is-a("Type");

                return wrap(!$lhs.is-a($rhs));
            },
            :qtype(TYPE<Q::Infix::TypeNonMatch>),
            :precedence{ equal => "infix:==" },
        ),

        # cons precedence
        'infix:::' => op(
            sub ($lhs, $rhs) {
                die X::Type.new(:operation<::>, :got($rhs), :expected(TYPE<Array>))
                    unless $rhs.is-a("Array");
                return wrap([$lhs, |$rhs.value]);
            },
            :qtype(TYPE<Q::Infix::Cons>),
            :assoc<right>,
        ),

        # additive precedence
        'infix:+' => op(
            sub ($lhs, $rhs) {
                die X::Type.new(:operation<+>, :got($lhs), :expected(TYPE<Int>))
                    unless $lhs.is-a("Int");
                die X::Type.new(:operation<+>, :got($rhs), :expected(TYPE<Int>))
                    unless $rhs.is-a("Int");
                return wrap($lhs.value + $rhs.value);
            },
            :qtype(TYPE<Q::Infix::Addition>),
        ),
        'infix:~' => op(
            sub ($lhs, $rhs) {
                die X::Type.new(:operation<~>, :got($lhs), :expected(TYPE<Str>))
                    unless $lhs.is-a("Str");
                die X::Type.new(:operation<~>, :got($rhs), :expected(TYPE<Str>))
                    unless $rhs.is-a("Str");
                return wrap($lhs.value ~ $rhs.value);
            },
            :qtype(TYPE<Q::Infix::Concat>),
            :precedence{ equal => "infix:+" },
        ),
        'infix:-' => op(
            sub ($lhs, $rhs) {
                die X::Type.new(:operation<->, :got($lhs), :expected(TYPE<Int>))
                    unless $lhs.is-a("Int");
                die X::Type.new(:operation<->, :got($rhs), :expected(TYPE<Int>))
                    unless $rhs.is-a("Int");
                return wrap($lhs.value - $rhs.value);
            },
            :qtype(TYPE<Q::Infix::Subtraction>),
        ),

        # multiplicative precedence
        'infix:*' => op(
            sub ($lhs, $rhs) {
                die X::Type.new(:operation<*>, :got($lhs), :expected(TYPE<Int>))
                    unless $lhs.is-a("Int");
                die X::Type.new(:operation<*>, :got($rhs), :expected(TYPE<Int>))
                    unless $rhs.is-a("Int");
                return wrap($lhs.value * $rhs.value);
            },
            :qtype(TYPE<Q::Infix::Multiplication>),
        ),
        'infix:%' => op(
            sub ($lhs, $rhs) {
                die X::Type.new(:operation<%>, :got($lhs), :expected(TYPE<Int>))
                    unless $lhs.is-a("Int");
                die X::Type.new(:operation<%>, :got($rhs), :expected(TYPE<Int>))
                    unless $rhs.is-a("Int");
                die X::Numeric::DivideByZero.new(:using<%>, :numerator($lhs.value))
                    if $rhs.value == 0;
                return wrap($lhs.value % $rhs.value);
            },
            :qtype(TYPE<Q::Infix::Modulo>),
        ),
        'infix:%%' => op(
            sub ($lhs, $rhs) {
                die X::Type.new(:operation<%%>, :got($lhs), :expected(TYPE<Int>))
                    unless $lhs.is-a("Int");
                die X::Type.new(:operation<%%>, :got($rhs), :expected(TYPE<Int>))
                    unless $rhs.is-a("Int");
                die X::Numeric::DivideByZero.new(:using<%%>, :numerator($lhs.value))
                    if $rhs.value == 0;
                return wrap($lhs.value %% $rhs.value);
            },
            :qtype(TYPE<Q::Infix::Divisibility>),
        ),
        'infix:x' => op(
            sub ($lhs, $rhs) {
                die X::Type.new(:operation<x>, :got($lhs), :expected(TYPE<Str>))
                    unless $lhs.is-a("Str");
                die X::Type.new(:operation<x>, :got($rhs), :expected(TYPE<Int>))
                    unless $rhs.is-a("Int");
                return wrap($lhs.value x $rhs.value);
            },
            :qtype(TYPE<Q::Infix::Replicate>),
            :precedence{ equal => "infix:*" },
        ),
        'infix:xx' => op(
            sub ($lhs, $rhs) {
                die X::Type.new(:operation<xx>, :got($lhs), :expected(TYPE<Array>))
                    unless $lhs.is-a("Array");
                die X::Type.new(:operation<xx>, :got($rhs), :expected(TYPE<Int>))
                    unless $rhs.is-a("Int");
                return wrap(| $lhs.value xx $rhs.value);
            },
            :qtype(TYPE<Q::Infix::ArrayReplicate>),
            :precedence{ equal => "infix:*" },
        ),

        # prefixes
        'prefix:~' => op(
            sub prefix-str($expr) {
                return wrap(stringify($expr, $runtime));
            },
            :qtype(TYPE<Q::Prefix::Str>),
        ),
        'prefix:+' => op(
            sub prefix-plus($expr) {
                if $expr.is-a("Str") {
                    return wrap($expr.value.Int)
                        if $expr.value ~~ /^ '-'? \d+ $/;
                }
                elsif $expr.is-a("Int") {
                    return $expr;
                }
                die X::Type.new(
                    :operation("prefix:<+>"),
                    :got($expr),
                    :expected(TYPE<Str>));
            },
            :qtype(TYPE<Q::Prefix::Plus>),
        ),
        'prefix:-' => op(
            sub prefix-minus($expr) {
                if $expr.is-a("Str") {
                    return wrap(-$expr.value.Int)
                        if $expr.value ~~ /^ '-'? \d+ $/;
                }
                elsif $expr.is-a("Int") {
                    return wrap(-$expr.value);
                }
                die X::Type.new(
                    :operation("prefix:<->"),
                    :got($expr),
                    :expected(TYPE<Str>));
            },
            :qtype(TYPE<Q::Prefix::Minus>),
        ),
        'prefix:?' => op(
            sub ($arg) {
                return wrap(boolify($arg, $runtime));
            },
            :qtype(TYPE<Q::Prefix::So>),
        ),
        'prefix:!' => op(
            sub ($arg) {
                return wrap(!boolify($arg, $runtime));
            },
            :qtype(TYPE<Q::Prefix::Not>),
        ),
        'prefix:^' => op(
            sub ($n) {
                die X::Type.new(:operation<^>, :got($n), :expected(TYPE<Int>))
                    unless $n.is-a("Int");
                return wrap([(^$n.value).map(&wrap)]);
            },
            :qtype(TYPE<Q::Prefix::Upto>),
        ),

        # postfixes
        'postfix:[]' => macro-op(
            :qtype(TYPE<Q::Postfix::Index>),
        ),
        'postfix:()' => macro-op(
            :qtype(TYPE<Q::Postfix::Call>),
        ),
        'postfix:.' => macro-op(
            :qtype(TYPE<Q::Postfix::Property>),
        ),
    ;

    for TYPE.keys -> $type {
        push @builtins, ($type => TYPE{$type});
    }

    sub install-op($name, $placeholder) {
        $name ~~ /^ (prefix | infix | postfix) ':' (.+) $/
            or die "This shouldn't be an op";
        my $type = ~$0;
        my $opname = ~$1;
        my %properties = hash($placeholder.qtype.type-chain.reverse.map({ .fields }).flat.map({ .<name> }).map({ $_ => NONE }));
        my $q = create($placeholder.qtype, |%properties);
        my $assoc = $placeholder.assoc;
        my %precedence = $placeholder.precedence;
        $opscope.install($type, $opname, $q, :$assoc, :%precedence);
    }

    my &ditch-sigil = { $^str.substr(1) };
    my &parameter = { create(TYPE<Q::Parameter>, :identifier(create(TYPE<Q::Identifier>, :name(wrap($^value))))) };

    return @builtins.map: {
        when .value ~~ _007::Type {
            .key => .value;
        }
        when .value ~~ Block {
            .key => wrap-fn(.value, .key);
        }
        when .value ~~ Placeholder::MacroOp {
            my $name = .key;
            install-op($name, .value);
            .key => wrap-fn(sub () {}, $name);
        }
        when .value ~~ Placeholder::Op {
            my $name = .key;
            install-op($name, .value);
            my &fn = .value.fn;
            .key => wrap-fn(&fn, $name);
        }
        default { die "Unknown type {.value.^name}" }
    };
}
