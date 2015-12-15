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

    sub wrap($_) {
        when Val | Q { $_ }
        when Nil { Val::None.new }
        when Str { Val::Str.new(:value($_)) }
        when Int { Val::Int.new(:value($_)) }
        when Array | Seq | List { Val::Array.new(:elements(.map(&wrap))) }
        default { die "Got some unknown value of type ", .^name }
    }

    method get-builtins {
        my &str = sub ($_) {
            when Val { return .Str }
            die X::TypeCheck.new(
                :operation<str()>,
                :got($_),
                :expected("something that can be converted to a string"));
        };

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

            'prefix:<->' => Val::Sub::Builtin.new('prefix:<->',
                sub ($expr) {
                    die X::TypeCheck.new(:operation<->, :got($expr), :expected(Val::Int))
                        unless $expr ~~ Val::Int;
                    return wrap(-$expr.value);
                },
                :qtype(Q::Prefix::Minus),
                :assoc<left>,
            ),
            'infix:<=>' => Val::Sub::Builtin.new('infix:<=>',
                sub ($lhs, $rhs) {
                    # can't express this one as a built-in sub -- because the lhs is an lvalue
                    # XXX: investigate expressing it as a built-in macro
                },
                :qtype(Q::Infix::Assignment),
                :assoc<right>,
            ),
            'infix:<==>' => Val::Sub::Builtin.new('infix:<=>',
                sub ($lhs, $rhs) {
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

                    # converting Bool->Int because the implemented language doesn't have Bool
                    return wrap(+equal-value($lhs, $rhs));
                },
                :qtype(Q::Infix::Eq),
                :assoc<left>,
            ),
            'infix:<+>' => Val::Sub::Builtin.new('infix:<+>',
                sub ($lhs, $rhs) {
                    die X::TypeCheck.new(:operation<+>, :got($lhs), :expected(Val::Int))
                        unless $lhs ~~ Val::Int;
                    die X::TypeCheck.new(:operation<+>, :got($rhs), :expected(Val::Int))
                        unless $rhs ~~ Val::Int;
                    return wrap($lhs.value + $rhs.value);
                },
                :qtype(Q::Infix::Addition),
                :assoc<left>,
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
                :assoc<left>,
            ),
            'infix:<*>' => Val::Sub::Builtin.new('infix:<*>',
                sub ($lhs, $rhs) {
                    die X::TypeCheck.new(:operation<*>, :got($lhs), :expected(Val::Int))
                        unless $lhs ~~ Val::Int;
                    die X::TypeCheck.new(:operation<*>, :got($rhs), :expected(Val::Int))
                        unless $rhs ~~ Val::Int;
                    return wrap($lhs.value * $rhs.value);
                },
                :qtype(Q::Infix::Multiplication),
                :assoc<left>,
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
            'postfix:<[]>' => Val::Sub::Builtin.new('postfix:<[]>',
                sub ($expr, $index) {
                    # can't express this one as a built-in sub
                },
                :qtype(Q::Postfix::Index),
                :assoc<right>,
            ),
            'postfix:<()>' => Val::Sub::Builtin.new('postfix:<()>',
                sub ($expr, $arguments) {
                    # can't express this one as a built-in sub
                },
                :qtype(Q::Postfix::Call),
                :assoc<right>,
            ),
            'postfix:<.>' => Val::Sub::Builtin.new('postfix:<.>',
                sub ($expr, $property) {
                    # can't express this one as a built-in sub
                },
                :qtype(Q::Postfix::Property),
                :assoc<right>,
            ),
            "None"                   => Val::Type.of(Val::None),
            "Int"                    => Val::Type.of(Val::Int),
            "Str"                    => Val::Type.of(Val::Str),
            "Array"                  => Val::Type.of(Val::Array),
            "Object"                 => Val::Type.of(Val::Object),
            "Type"                   => Val::Type.of(Val::Type),
            "Block"                  => Val::Type.of(Val::Block),
            "Sub"                    => Val::Type.of(Val::Sub),
            "Macro"                  => Val::Type.of(Val::Macro),
            "Q::Identifier"          => Val::Type.of(Q::Identifier),
            "Q::Literal::None"       => Val::Type.of(Q::Literal::None),
            "Q::Literal::Int"        => Val::Type.of(Q::Literal::Int),
            "Q::Literal::Str"        => Val::Type.of(Q::Literal::Str),
            "Q::Term::Array"         => Val::Type.of(Q::Term::Array),
            "Q::Term::Object"        => Val::Type.of(Q::Term::Object),
            "Q::Property"            => Val::Type.of(Q::Property),
            "Q::PropertyList"        => Val::Type.of(Q::PropertyList),
            "Q::Block"               => Val::Type.of(Q::Block),
            "Q::Identifier"          => Val::Type.of(Q::Identifier),
            "Q::Unquote"             => Val::Type.of(Q::Unquote),
            "Q::Prefix"              => Val::Type.of(Q::Prefix),
            "Q::Prefix::Minus"       => Val::Type.of(Q::Prefix::Minus),
            "Q::Infix"               => Val::Type.of(Q::Infix),
            "Q::Infix::Addition"     => Val::Type.of(Q::Infix::Addition),
            "Q::Infix::Subtraction"  => Val::Type.of(Q::Infix::Subtraction),
            "Q::Infix::Multiplication" => Val::Type.of(Q::Infix::Multiplication),
            "Q::Infix::Concat"       => Val::Type.of(Q::Infix::Concat),
            "Q::Infix::Assignment"   => Val::Type.of(Q::Infix::Assignment),
            "Q::Infix::Eq"           => Val::Type.of(Q::Infix::Eq),
            "Q::Postfix"             => Val::Type.of(Q::Postfix),
            "Q::Postfix::Index"      => Val::Type.of(Q::Postfix::Index),
            "Q::Postfix::Call"       => Val::Type.of(Q::Postfix::Call),
            "Q::Postfix::Property"   => Val::Type.of(Q::Postfix::Property),
            "Q::ParameterList"       => Val::Type.of(Q::ParameterList),
            "Q::Parameter"           => Val::Type.of(Q::Parameter),
            "Q::ArgumentList"        => Val::Type.of(Q::ArgumentList),
            "Q::Statement::My"       => Val::Type.of(Q::Statement::My),
            "Q::Statement::Constant" => Val::Type.of(Q::Statement::Constant),
            "Q::Statement::Expr"     => Val::Type.of(Q::Statement::Expr),
            "Q::Statement::If"       => Val::Type.of(Q::Statement::If),
            "Q::Statement::Block"    => Val::Type.of(Q::Statement::Block),
            "Q::CompUnit"            => Val::Type.of(Q::CompUnit),
            "Q::Statement::For"      => Val::Type.of(Q::Statement::For),
            "Q::Statement::While"    => Val::Type.of(Q::Statement::While),
            "Q::Statement::Return"   => Val::Type.of(Q::Statement::Return),
            "Q::Statement::Sub"      => Val::Type.of(Q::Statement::Sub),
            "Q::Statement::Macro"    => Val::Type.of(Q::Statement::Macro),
            "Q::Statement::BEGIN"    => Val::Type.of(Q::Statement::BEGIN),
            "Q::StatementList"       => Val::Type.of(Q::StatementList),
            "Q::Trait"               => Val::Type.of(Q::Trait),
            "Q::Term::Quasi"         => Val::Type.of(Q::Term::Quasi),
        ;

        sub _007ize(&fn) {
            return sub (|c) { wrap &fn(|c) };
        }

        sub create-paramlist(@params) {
            Q::ParameterList.new(:parameters(
                Val::Array.new(:elements(@params».name».substr(1).map({
                    Q::Parameter.new(:ident(Q::Identifier.new(:name(Val::Str.new(:value($_))))))
                })))
            ));
        }

        return @builtins.map: {
            when .value ~~ Val::Type {
                .key => .value;
            }
            when .value ~~ Callable {
                 my $paramlist = create-paramlist(.value.signature.params);
                 .key => Val::Sub::Builtin.new(.key, _007ize(.value), :parameterlist($paramlist));
            }
            when .value ~~ Val::Sub::Builtin {
                .value.parameterlist = create-paramlist(.value.code.signature.params);
                $_
            }
            default { die "Unknown type {.value.^name}" }
        };
    }

    method opscope {
        my $scope = _007::OpScope.new;

        for self.get-builtins -> Pair (:key($name), :value($subval)) {
            $name ~~ /^ (prefix | infix | postfix) ':<' (<-[\>]>+) '>' $/
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

    method property($obj, $propname) {
        my $value = do given $propname {
            when "value" {
                given $obj {
                    when Q::Literal::None {
                        Val::None.new;
                    }
                    when Q::Literal {
                        $obj.value;
                    }
                    when Q::Term::Array {
                        Val::Array.new(:elements($obj.elements));
                    }
                    die X::TypeCheck.new(
                        :operation<.value>,
                        :got($obj),
                        :expected("a Q::Literal type that has a .value"));
                }
            }
            when "paramlist" {
                given $obj {
                    when Q::Block {
                        $obj.parameterlist.parameters;
                    }
                    die X::TypeCheck.new(
                        :operation<.paramlist>,
                        :got($obj),
                        :expected("Q::Block"));
                }
            }
            when "stmtlist" {
                given $obj {
                    when Q::Block {
                        $obj.statementlist.statements;
                    }
                    die X::TypeCheck.new(
                        :operation<.stmtlist>,
                        :got($obj),
                        :expected("Q::Block"));
                }
            }
            when "lhs" {
                given $obj {
                    when Q::Infix {
                        $obj.lhs;
                    }
                    die X::TypeCheck.new(
                        :operation<.lhs>,
                        :got($obj),
                        :expected("Q::Infix"));
                }
            }
            when "rhs" {
                given $obj {
                    when Q::Infix {
                        $obj.rhs;
                    }
                    die X::TypeCheck.new(
                        :operation<.rhs>,
                        :got($obj),
                        :expected("Q::Infix"));
                }
            }
            when "pos" {
                given $obj {
                    when Q::Postfix::Index {
                        $obj.index;
                    }
                    die X::TypeCheck.new(
                        :operation<.pos>,
                        :got($obj),
                        :expected("Q::Postfix::Index"));
                }
            }
            when "arglist" {
                given $obj {
                    when Q::Postfix::Call {
                        $obj.argumentlist.arguments;
                    }
                    die X::TypeCheck.new(
                        :operation<.arglist>,
                        :got($obj),
                        :expected("Q::Postfix::Call"));
                }
            }
            when "ident" {
                given $obj {
                    when Q::Statement::My | Q::Statement::Constant
                        | Q::Statement::Sub | Q::Statement::Macro
                        | Q::Trait {
                        $obj.ident;
                    }
                    die X::TypeCheck.new(
                        :operation<.ident>,
                        :got($obj),
                        :expected("any number of types with the .ident property"));
                }
            }
            when "property" {
                given $obj {
                    when Q::Postfix::Property {
                        $obj.property;
                    }
                    die X::TypeCheck.new(
                        :operation<.property>,
                        :got($obj),
                        :expected(Q::Postfix::Property));
                }
            }
            when "assign" {
                given $obj {
                    when Q::Statement::My | Q::Statement::Constant {
                        $obj.assign;
                    }
                    die X::TypeCheck.new(
                        :operation<.assign>,
                        :got($obj),
                        :expected("Q::Statement::My | Q::Statement::Constant"));
                }
            }
            when "expr" {
                given $obj {
                    when Q::Statement::If | Q::Statement::For
                        | Q::Statement::While | Q::Statement::Expr
                        | Q::Unquote | Q::Prefix | Q::Postfix
                        | Q::Statement::Return | Q::Trait {
                        $obj.expr;
                    }
                    die X::TypeCheck.new(
                        :operation<.expr>,
                        :got($obj),
                        :expected("Q::Statement::My | Q::Statement::Constant"));
                }
            }
            when "block" {
                given $obj {
                    when Q::Statement::Block | Q::Statement::If
                        | Q::Statement::For | Q::Statement::While
                        | Q::Statement::BEGIN {
                        $obj.block;
                    }
                    die X::TypeCheck.new(
                        :operation<.block>,
                        :got($obj),
                        :expected("Q::Statement::Block | Q::Statement::If | "
                            ~ "Q::Statement::For | Q::Statement::While | "
                            ~ "Q::Statement::BEGIN"));
                }
            }
            when "name" {
                given $obj {
                    when Q::Identifier {
                        $obj.name;
                    }
                    die X::TypeCheck.new(
                        :operation<.name>,
                        :got($obj),
                        :expected("Q::Identifier"));
                }
            }
            default {
                die "Property '$propname' not found on ", $obj.^name; # XXX: turn into X::
            }
        };

        return wrap($value);
    }
}
