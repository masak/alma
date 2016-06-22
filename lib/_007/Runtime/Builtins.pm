use _007::Val;
use _007::Q;
use _007::OpScope;

class Val::Sub::Builtin is Val::Sub {
    has $.code;
    has $.qtype;
    has $.assoc;
    has %.precedence;

    method new(Str $name, $code, :$qtype, :$assoc, :%precedence,
            :$parameterlist = Q::ParameterList.new,
            :$statementlist = Q::StatementList.new) {
        self.bless(
            :name(Val::Str.new(:value($name))),
            :$code,
            :$qtype,
            :$assoc,
            :%precedence,
            :$parameterlist,
            :$statementlist,
        )
    }
}

class _007::Runtime::Builtins {
    has $.runtime;

    method get-builtins {
        my &str = sub ($_) {
            when Val { return .Str }
            die X::TypeCheck.new(
                :operation<str()>,
                :got($_),
                :expected("something that can be converted to a string"));
        };

        sub wrap($_) {
            when Val | Q { $_ }
            when Nil  { Val::None.new }
            when Bool { Val::Int.new(:value(+$_)) }
            when Int  { Val::Int.new(:value($_)) }
            when Str  { Val::Str.new(:value($_)) }
            when Array | Seq | List { Val::Array.new(:elements(.map(&wrap))) }
            default { die "Got some unknown value of type ", .^name }
        }

        # These multis are used below by infix:<==> and infix:<!=>
        multi equal-value($, $) { False }
        multi equal-value(Val::None, Val::None) { True }
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

        my @builtins =
            say      => -> $arg {
                $.runtime.output.say($arg ~~ Val::Array ?? &str($arg).Str !! ~$arg);
                Nil;
            },
            prompt => sub ($arg) {
                return wrap(prompt($arg));
            },
            type => -> $arg { Val::Type.of($arg.WHAT) },
            str => &str,
            int => sub ($_) {
                when Val::Str {
                    return .value.Int
                        if .value ~~ /^ '-'? \d+ $/;
                    proceed;
                }
                when Val::Int {
                    return .value;
                }
                die X::TypeCheck.new(
                    :operation<int()>,
                    :got($_),
                    :expected(Val::Int));
            },
            min      => -> $a, $b { min($a.value, $b.value) },
            max      => -> $a, $b { max($a.value, $b.value) },

            # OPERATORS

            # assignment precedence
            'infix:<=>' => Val::Sub::Builtin.new('infix:<=>',
                sub ($lhs, $rhs) {
                    # can't express this one as a built-in sub -- because the lhs is an lvalue
                    # XXX: investigate expressing it as a built-in macro
                },
                :qtype(Q::Infix::Assignment),
                :assoc<right>,
            ),

            # disjunctive precedence
            'infix:<||>' => Val::Sub::Builtin.new('infix:<||>',
                sub ($lhs, $rhs) {
                    # implemented in Q.pm as .eval method
                },
                :qtype(Q::Infix::Or),
            ),
            'infix:<//>' => Val::Sub::Builtin.new('infix:<//>',
                sub ($lhs, $rhs) {
                    # implemented in Q.pm as .eval method
                },
                :qtype(Q::Infix::DefinedOr),
                :precedence{ equal => "||" },
            ),

            # conjunctive precedence
            'infix:<&&>' => Val::Sub::Builtin.new('infix:<&&>',
                sub ($lhs, $rhs) {
                    # implemented in Q.pm as .eval method
                },
                :qtype(Q::Infix::And),
            ),

            # comparison precedence
            'infix:<==>' => Val::Sub::Builtin.new('infix:<==>',
                sub ($lhs, $rhs) {
                    my %*equality-seen;
                    return wrap(equal-value($lhs, $rhs));
                },
                :qtype(Q::Infix::Eq),
            ),
            'infix:<!=>' => Val::Sub::Builtin.new('infix:<!=>',
                sub ($lhs, $rhs) {
                    my %*equality-seen;
                    return wrap(!equal-value($lhs, $rhs))
                },
                :qtype(Q::Infix::Ne),
                :precedence{ equal => "==" },
            ),
            'infix:<<>' => Val::Sub::Builtin.new('infix:<<=>',
                sub ($lhs, $rhs) {
                    return wrap(less-value($lhs, $rhs))
                },
                :qtype(Q::Infix::Lt),
                :precedence{ equal => "==" },
            ),
            'infix:<<=>' => Val::Sub::Builtin.new('infix:<<=>',
                sub ($lhs, $rhs) {
                    my %*equality-seen;
                    return wrap(less-value($lhs, $rhs) || equal-value($lhs, $rhs))
                },
                :qtype(Q::Infix::Le),
                :precedence{ equal => "==" },
            ),
            'infix:<>>' => Val::Sub::Builtin.new('infix:<>>',
                sub ($lhs, $rhs) {
                    return wrap(more-value($lhs, $rhs) )
                },
                :qtype(Q::Infix::Gt),
                :precedence{ equal => "==" },
            ),
            'infix:<>=>' => Val::Sub::Builtin.new('infix:<>=>',
                sub ($lhs, $rhs) {
                    my %*equality-seen;
                    return wrap(more-value($lhs, $rhs) || equal-value($lhs, $rhs))
                },
                :qtype(Q::Infix::Ge),
                :precedence{ equal => "==" },
            ),

            # cons precedence
            'infix:<::>' => Val::Sub::Builtin.new('infix:<::>',
                sub ($lhs, $rhs) {
                    die X::TypeCheck.new(:operation<::>, :got($rhs), :expected(Val::Array))
                        unless $rhs ~~ Val::Array;
                    return wrap([$lhs, |$rhs.elements]);
                },
                :qtype(Q::Infix::Cons),
                :assoc<right>,
            ),

            # additive precedence
            'infix:<+>' => Val::Sub::Builtin.new('infix:<+>',
                sub ($lhs, $rhs) {
                    die X::TypeCheck.new(:operation<+>, :got($lhs), :expected(Val::Int))
                        unless $lhs ~~ Val::Int;
                    die X::TypeCheck.new(:operation<+>, :got($rhs), :expected(Val::Int))
                        unless $rhs ~~ Val::Int;
                    return wrap($lhs.value + $rhs.value);
                },
                :qtype(Q::Infix::Addition),
            ),
            'infix:<~>' => Val::Sub::Builtin.new('infix:<~>',
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
            'infix:<->' => Val::Sub::Builtin.new('infix:<->',
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
            'infix:<*>' => Val::Sub::Builtin.new('infix:<*>',
                sub ($lhs, $rhs) {
                    die X::TypeCheck.new(:operation<*>, :got($lhs), :expected(Val::Int))
                        unless $lhs ~~ Val::Int;
                    die X::TypeCheck.new(:operation<*>, :got($rhs), :expected(Val::Int))
                        unless $rhs ~~ Val::Int;
                    return wrap($lhs.value * $rhs.value);
                },
                :qtype(Q::Infix::Multiplication),
            ),
            'infix:<%>' => Val::Sub::Builtin.new('infix:<%>',
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
            'infix:<%%>' => Val::Sub::Builtin.new('infix:<%%>',
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
            'infix:<x>' => Val::Sub::Builtin.new('infix:<x>',
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
            'infix:<xx>' => Val::Sub::Builtin.new('infix:<xx>',
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
            'infix:<~~>' => Val::Sub::Builtin.new('infix:<~~>',
                sub ($lhs, $rhs) {
                    die X::TypeCheck.new(:operation<~~>, :got($rhs), :expected(Val::Type))
                        unless $rhs ~~ Val::Type;

                    return wrap($lhs ~~ $rhs.type);
                }
            ),

            # prefixes
            'prefix:<->' => Val::Sub::Builtin.new('prefix:<->',
                sub ($expr) {
                    die X::TypeCheck.new(:operation<->, :got($expr), :expected(Val::Int))
                        unless $expr ~~ Val::Int;
                    return wrap(-$expr.value);
                },
                :qtype(Q::Prefix::Minus),
            ),
            'prefix:<!>' => Val::Sub::Builtin.new('prefix:<!>',
                sub ($a) {
                    return wrap(!$a.truthy)
                },
                :qtype(Q::Prefix::Not),
            ),
            'prefix:<^>' => Val::Sub::Builtin.new('prefix:<^>',
                sub ($n) {
                    die X::TypeCheck.new(:operation<^>, :got($n), :expected(Val::Int))
                        unless $n ~~ Val::Int;
                    return wrap([^$n.value]);
                },
                :qtype(Q::Prefix::Upto),
            ),

            # postfixes
            'postfix:<[]>' => Val::Sub::Builtin.new('postfix:<[]>',
                sub ($expr, $index) {
                    # can't express this one as a built-in sub
                },
                :qtype(Q::Postfix::Index),
            ),
            'postfix:<()>' => Val::Sub::Builtin.new('postfix:<()>',
                sub ($expr, $arguments) {
                    # can't express this one as a built-in sub
                },
                :qtype(Q::Postfix::Call),
            ),
            'postfix:<.>' => Val::Sub::Builtin.new('postfix:<.>',
                sub ($expr, $property) {
                    # can't express this one as a built-in sub
                },
                :qtype(Q::Postfix::Property),
            ),
        ;

        sub tree-walk(%package) {
            for %package.keys.map({ %package ~ "::$_" }) -> $name {
                # make a little exception for Val::Sub::Builtin, which is just an
                # implementation detail and doesn't have a corresponding builtin
                # (because it tries to pass itself off as a Val::Sub)
                next if $name eq "Val::Sub::Builtin";
                my $type = ::($name);
                push @builtins, ($type.^name.subst("Val::", "") => Val::Type.of($type));
                tree-walk($type.WHO);
            }
        }
        tree-walk(Val::);
        tree-walk(Q::);

        sub _007ize(&fn) {
            return sub (|c) { wrap &fn(|c) };
        }

        sub create-parameterlist(@parameters) {
            Q::ParameterList.new(:parameters(
                Val::Array.new(:elements(@parameters».name».substr(1).map({
                    Q::Parameter.new(:identifier(Q::Identifier.new(:name(Val::Str.new(:value($_))))))
                })))
            ));
        }

        return @builtins.map: {
            when .value ~~ Val::Type {
                .key => .value;
            }
            when .value ~~ Callable {
                my $parameterlist = create-parameterlist(.value.signature.params);
                .key => Val::Sub::Builtin.new(.key, _007ize(.value), :parameterlist($parameterlist));
            }
            when .value ~~ Val::Sub::Builtin {
                .value.parameterlist = create-parameterlist(.value.code.signature.params);
                $_
            }
            default { die "Unknown type {.value.^name}" }
        };
    }

    method opscope {
        my $scope = _007::OpScope.new;

        for self.get-builtins -> Pair (:key($name), :value($subval)) {
            $name ~~ /^ (prefix | infix | postfix) ':<' (.+) '>' $/
                or next;
            my $type = ~$0;
            my $opname = ~$1;
            my $qtype = $subval.qtype;
            my $assoc = $subval.assoc;
            my %precedence = $subval.precedence;
            $scope.install($type, $opname, $qtype, :$assoc, :%precedence);
        }

        return $scope;
    }
}
