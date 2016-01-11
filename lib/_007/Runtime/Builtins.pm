use _007::Val;
use _007::Q;
use _007::OpScope;

class Val::Sub::Builtin is Val::Sub {
    has $.code;
    has $.qtype;
    has $.assoc;
    has %.precedence;

    method new($name, $code, :$qtype, :$assoc, :%precedence,
            :$parameterlist = Q::ParameterList.new,
            :$statementlist = Q::StatementList.new) {
        self.bless(
            :$name,
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
            sub equal-at-index($i) {
                equal-value($l.elements[$i], $r.elements[$i]);
            }

            [&&] $l.elements == $r.elements,
                |(^$l.elements).map(&equal-at-index);
        }
        multi equal-value(Val::Object $l, Val::Object $r) {
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
                    :expected("something that can be converted to an int"));
            },
            abs      => -> $arg { $arg.value.abs },
            min      => -> $a, $b { min($a.value, $b.value) },
            max      => -> $a, $b { max($a.value, $b.value) },
            chr      => -> $arg { $arg.value.chr },
            ord      => -> $arg { $arg.value.ord },
            chars    => -> $arg { $arg.value.Str.chars },
            uc       => -> $arg { $arg.value.uc },
            lc       => -> $arg { $arg.value.lc },
            trim     => -> $arg { $arg.value.trim },
            elems    => -> $arg { $arg.elements.elems },
            reversed => -> $arg { $arg.elements.reverse },
            sorted   => -> $arg { $arg.elements>>.value.sort },
            join     => -> $a, $sep { $a.elements.join($sep.value.Str) },
            split    => -> $s, $sep { $s.value.split($sep.value) },
            index    => -> $s, $substr { $s.value.index($substr.value) // -1 },
            substr   => sub ($s, $pos, $chars?) { $s.value.substr($pos.value, $chars.defined ?? $chars.value !! $s.value.chars) },
            charat   => -> $s, $pos { $s.value.comb[$pos.value] // die X::Subscript::TooLarge.new(:value($pos.value), :length($s.value.elems)) },
            filter   => -> $fn, $a { $a.elements.grep({ $.runtime.call($fn, [$_]).truthy }) },
            map      => -> $fn, $a { $a.elements.map({ $.runtime.call($fn, [$_]) }) },
            melt     => sub ($q) {
                die X::TypeCheck.new(:operation<melt>, :got($q), :expected(Q::Expr))
                    unless $q ~~ Q::Expr;
                return $q.eval($.runtime);
            },
            concat   => sub ($a, $b) {
                die X::TypeCheck.new(:operation<concat>, :got($a), :expected(Val::Array))
                    unless $a ~~ Val::Array;
                die X::TypeCheck.new(:operation<concat>, :got($b), :expected(Val::Array))
                    unless $b ~~ Val::Array;
                return wrap([|$a.elements , |$b.elements]);
            },

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
                    return wrap(equal-value($lhs, $rhs));
                },
                :qtype(Q::Infix::Eq),
            ),
            'infix:<!=>' => Val::Sub::Builtin.new('infix:<!=>',
                sub ($lhs, $rhs) {
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

        my @val-types =
            Val::Array,
            Val::Block,
            Val::Int,
            Val::None,
            Val::Macro,
            Val::Object,
            Val::Str,
            Val::Sub,
            Val::Type,
        ;

        for @val-types -> $type {
            push @builtins, ($type.^name.subst("Val::", "") => Val::Type.of($type));
        }

        my @q-types =
            Q::ArgumentList,
            Q::Block,
            Q::CompUnit,
            Q::Identifier,
            Q::Infix,
            Q::Infix::Addition,
            Q::Infix::Subtraction,
            Q::Infix::Multiplication,
            Q::Infix::Concat,
            Q::Infix::Assignment,
            Q::Infix::Eq,
            Q::Infix::Ne,
            Q::Infix::Gt,
            Q::Infix::Ge,
            Q::Infix::Lt,
            Q::Infix::Le,
            Q::Infix::And,
            Q::Infix::Or,
            Q::Infix::TypeEq,
            Q::Prefix::Not,
            Q::Prefix::Upto,
            Q::Infix::Replicate,
            Q::Infix::ArrayReplicate,
            Q::Infix::Cons,
            Q::Literal::Int,
            Q::Literal::None,
            Q::Literal::Str,
            Q::Parameter,
            Q::ParameterList,
            Q::Postfix,
            Q::Postfix::Index,
            Q::Postfix::Call,
            Q::Postfix::Property,
            Q::Prefix,
            Q::Prefix::Minus,
            Q::Property,
            Q::PropertyList,
            Q::Statement::BEGIN,
            Q::Statement::Block,
            Q::Statement::Constant,
            Q::Statement::Expr,
            Q::Statement::For,
            Q::Statement::Macro,
            Q::Statement::If,
            Q::Statement::My,
            Q::Statement::Return,
            Q::Statement::Sub,
            Q::Statement::While,
            Q::StatementList,
            Q::Term::Array,
            Q::Term::Object,
            Q::Term::Quasi,
            Q::Term::Sub,
            Q::Trait,
            Q::TraitList,
            Q::Unquote,
            Q::Unquote::Infix,
            Q::Unquote::Prefix,
        ;

        for @q-types -> $type {
            push @builtins, ($type.^name => Val::Type.of($type));
        }

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
