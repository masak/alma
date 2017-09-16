use _007::Object;

proto type-of($) is export {*}
multi type-of(_007::Object $obj) { $obj.type }
multi type-of(_007::Type $obj) { TYPE<Type> }

sub builtins(:$input!, :$output!, :$opscope!) is export {
    # These multis are used below by infix:<==> and infix:<!=>
    multi equal-value($, $) { False }
    multi equal-value(_007::Object $l, _007::Object $r) {
        return False
            unless $l.type === $r.type;
        if $l.isa("Int") {
            return $l.value == $r.value;
        }
        elsif $l.isa("Str") {
            return $l.value eq $r.value;
        }
        elsif $l.isa("Array") {
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
        elsif $l.isa("Dict") {
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
        elsif $l.isa("NoneType") {
            return True;
        }
        elsif $l.isa("Bool") {
            return $l === $r;
        }
        elsif $l.isa("Sub") {
            return $l.properties<name>.value eq $r.properties<name>.value
                && equal-value($l.properties<parameterlist>, $r.properties<parameterlist>)
                && equal-value($l.properties<statementlist>, $r.properties<statementlist>);
        }
        elsif $l.isa("Q") {
            sub same-propvalue($prop) {
                equal-value($l.properties{$prop}, $r.properties{$prop});
            }

            [&&] $l.type === $r.type,
                |$l.type.type-chain.reverse.map({ .fields }).flat.grep({ $_ ne "frame" }).map(&same-propvalue);
        }
        else {
            die "Unknown type ", $l.type.^name;
        }
    }
    multi equal-value(_007::Type $l, _007::Type $r) { $l === $r }

    multi less-value($, $) {
        die X::TypeCheck.new(
            :operation<less>,
            :got($_),
            :expected(_007::Object));
    }
    multi less-value(_007::Object $l, _007::Object $r) {
        die X::TypeCheck.new(:operation<less>, :got($_), :expected(_007::Object))
            unless $l.type === $r.type;
        return $l.isa("Int")
            ?? $l.value < $r.value
            !! $l.isa("Str")
                ?? $l.value lt $r.value
                !! die "Unknown type ", $l.type.Str;
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
        return $l.isa("Int")
            ?? $l.value > $r.value
            !! $l.isa("Str")
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
            $output.print($arg ~ "\n");
            Nil;
        },
        prompt => sub ($arg) {
            $output.print($arg);
            $output.flush();
            return wrap($input.get());
        },
        type => sub ($arg) {
            type-of($arg);
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
                die X::TypeCheck.new(:operation<~~>, :got($rhs), :expected(_007::Type))
                    unless $rhs ~~ _007::Type;

                return wrap(?$lhs.isa($rhs));
            },
            :qtype(TYPE<Q::Infix::TypeMatch>),
            :precedence{ equal => "infix:==" },
        ),
        'infix:!~~' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<~~>, :got($rhs), :expected(_007::Type))
                    unless $rhs ~~ _007::Type;

                return wrap(!$lhs.isa($rhs));
            },
            :qtype(TYPE<Q::Infix::TypeNonMatch>),
            :precedence{ equal => "infix:==" },
        ),

        # cons precedence
        'infix:::' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<::>, :got($rhs), :expected(_007::Object))
                    unless $rhs ~~ _007::Object && $rhs.isa("Array");
                return wrap([$lhs, |$rhs.value]);
            },
            :qtype(TYPE<Q::Infix::Cons>),
            :assoc<right>,
        ),

        # additive precedence
        'infix:+' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<+>, :got($lhs), :expected(_007::Object))
                    unless $lhs ~~ _007::Object && $lhs.isa("Int");
                die X::TypeCheck.new(:operation<+>, :got($rhs), :expected(_007::Object))
                    unless $rhs ~~ _007::Object && $rhs.isa("Int");
                return wrap($lhs.value + $rhs.value);
            },
            :qtype(TYPE<Q::Infix::Addition>),
        ),
        'infix:~' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<~>, :got($lhs), :expected(_007::Object))
                    unless $lhs ~~ _007::Object && $lhs.isa("Str");
                die X::TypeCheck.new(:operation<~>, :got($rhs), :expected(_007::Object))
                    unless $rhs ~~ _007::Object && $rhs.isa("Str");
                return wrap($lhs.value ~ $rhs.value);
            },
            :qtype(TYPE<Q::Infix::Concat>),
            :precedence{ equal => "infix:+" },
        ),
        'infix:-' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<->, :got($lhs), :expected(_007::Object))
                    unless $lhs ~~ _007::Object && $lhs.isa("Int");
                die X::TypeCheck.new(:operation<->, :got($rhs), :expected(_007::Object))
                    unless $rhs ~~ _007::Object && $rhs.isa("Int");
                return wrap($lhs.value - $rhs.value);
            },
            :qtype(TYPE<Q::Infix::Subtraction>),
        ),

        # multiplicative precedence
        'infix:*' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<*>, :got($lhs), :expected(_007::Object))
                    unless $lhs ~~ _007::Object && $lhs.isa("Int");
                die X::TypeCheck.new(:operation<*>, :got($rhs), :expected(_007::Object))
                    unless $rhs ~~ _007::Object && $rhs.isa("Int");
                return wrap($lhs.value * $rhs.value);
            },
            :qtype(TYPE<Q::Infix::Multiplication>),
        ),
        'infix:%' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<%>, :got($lhs), :expected(_007::Object))
                    unless $lhs ~~ _007::Object && $lhs.isa("Int");
                die X::TypeCheck.new(:operation<%>, :got($rhs), :expected(_007::Object))
                    unless $rhs ~~ _007::Object && $rhs.isa("Int");
                die X::Numeric::DivideByZero.new(:using<%>, :numerator($lhs.value))
                    if $rhs.value == 0;
                return wrap($lhs.value % $rhs.value);
            },
            :qtype(TYPE<Q::Infix::Modulo>),
        ),
        'infix:%%' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<%%>, :got($lhs), :expected(_007::Object))
                    unless $lhs ~~ _007::Object && $lhs.isa("Int");
                die X::TypeCheck.new(:operation<%%>, :got($rhs), :expected(_007::Object))
                    unless $rhs ~~ _007::Object && $rhs.isa("Int");
                die X::Numeric::DivideByZero.new(:using<%%>, :numerator($lhs.value))
                    if $rhs.value == 0;
                return wrap($lhs.value %% $rhs.value);
            },
            :qtype(TYPE<Q::Infix::Divisibility>),
        ),
        'infix:x' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<x>, :got($lhs), :expected(_007::Object))
                    unless $lhs ~~ _007::Object && $lhs.isa("Str");
                die X::TypeCheck.new(:operation<x>, :got($rhs), :expected(_007::Object))
                    unless $rhs ~~ _007::Object && $rhs.isa("Int");
                return wrap($lhs.value x $rhs.value);
            },
            :qtype(TYPE<Q::Infix::Replicate>),
            :precedence{ equal => "infix:*" },
        ),
        'infix:xx' => op(
            sub ($lhs, $rhs) {
                die X::TypeCheck.new(:operation<xx>, :got($lhs), :expected(_007::Object))
                    unless $lhs ~~ _007::Object && $lhs.isa("Array");
                die X::TypeCheck.new(:operation<xx>, :got($rhs), :expected(_007::Object))
                    unless $rhs ~~ _007::Object && $rhs.isa("Int");
                return wrap(| $lhs.value xx $rhs.value);
            },
            :qtype(TYPE<Q::Infix::ArrayReplicate>),
            :precedence{ equal => "infix:*" },
        ),

        # prefixes
        'prefix:~' => op(
            sub prefix-str($expr) { wrap($expr.Str) },
            :qtype(TYPE<Q::Prefix::Str>),
        ),
        'prefix:+' => op(
            sub prefix-plus($expr) {
                if $expr ~~ _007::Object {
                    if $expr.isa("Str") {
                        return wrap($expr.value.Int)
                            if $expr.value ~~ /^ '-'? \d+ $/;
                    }
                    elsif $expr.isa("Int") {
                        return $expr;
                    }
                }
                die X::TypeCheck.new(
                    :operation("prefix:<+>"),
                    :got($expr),
                    :expected(_007::Object));
            },
            :qtype(TYPE<Q::Prefix::Plus>),
        ),
        'prefix:-' => op(
            sub prefix-minus($expr) {
                if $expr ~~ _007::Object {
                    if $expr.isa("Str") {
                        return wrap(-$expr.value.Int)
                            if $expr.value ~~ /^ '-'? \d+ $/;
                    }
                    elsif $expr.isa("Int") {
                        return wrap(-$expr.value);
                    }
                }
                die X::TypeCheck.new(
                    :operation("prefix:<->"),
                    :got($expr),
                    :expected(_007::Object));
            },
            :qtype(TYPE<Q::Prefix::Minus>),
        ),
        'prefix:?' => op(
            sub ($a) {
                return wrap(?$a.truthy)
            },
            :qtype(TYPE<Q::Prefix::So>),
        ),
        'prefix:!' => op(
            sub ($a) {
                return wrap(!$a.truthy)
            },
            :qtype(TYPE<Q::Prefix::Not>),
        ),
        'prefix:^' => op(
            sub ($n) {
                die X::TypeCheck.new(:operation<^>, :got($n), :expected(_007::Object))
                    unless $n ~~ _007::Object && $n.isa("Int");
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
        my %properties = hash($placeholder.qtype.type-chain.reverse.map({ .fields }).flat.map({ $_ => NONE }));
        my $q = create($placeholder.qtype, |%properties);
        my $assoc = $placeholder.assoc;
        my %precedence = $placeholder.precedence;
        $opscope.install($type, $opname, $q, :$assoc, :%precedence);
    }

    my &ditch-sigil = { $^str.substr(1) };
    my &parameter = {
        create(TYPE<Q::Parameter>, :identifier(create(TYPE<Q::Identifier>,
            :name(wrap($^value)),
            :frame(NONE),
        )))
    };

    return @builtins.map: {
        when .value ~~ _007::Type {
            .key => .value;
        }
        when .value ~~ Block {
            my @elements = .value.signature.params».name».&ditch-sigil».&parameter;
            my $parameters = wrap(@elements);
            my $parameterlist = create(TYPE<Q::ParameterList>, :$parameters);
            my $statementlist = create(TYPE<Q::StatementList>, :statements(wrap([])));
            .key => wrap-fn(.value, .key, $parameterlist, $statementlist);
        }
        when .value ~~ Placeholder::MacroOp {
            my $name = .key;
            install-op($name, .value);
            my @elements = .value.qtype.fields.grep({ $_ ne "identifier" })».&parameter;
            my $parameters = wrap(@elements);
            my $parameterlist = create(TYPE<Q::ParameterList>, :$parameters);
            my $statementlist = create(TYPE<Q::StatementList>, :statements(wrap([])));
            .key => wrap-fn(sub () {}, $name, $parameterlist, $statementlist);
        }
        when .value ~~ Placeholder::Op {
            my $name = .key;
            install-op($name, .value);
            my &fn = .value.fn;
            my @elements = &fn.signature.params».name».&ditch-sigil».&parameter;
            my $parameters = wrap(@elements);
            my $parameterlist = create(TYPE<Q::ParameterList>, :$parameters);
            my $statementlist = create(TYPE<Q::StatementList>, :statements(wrap([])));
            .key => wrap-fn(&fn, $name, $parameterlist, $statementlist);
        }
        default { die "Unknown type {.value.^name}" }
    };
}
