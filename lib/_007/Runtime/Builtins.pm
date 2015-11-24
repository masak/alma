use _007::Val;
use _007::Q;
use _007::Parser::OpScope;

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

    method get-subs {
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
            type     => -> $arg {
                $arg ~~ Val::Sub
                    ?? "Sub"
                    !! $arg.^name.substr('Val::'.chars);
            },
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

            'Q::Literal::Int' => -> $int { Q::Literal::Int.new(:value($int.value)) },
            'Q::Literal::Str' => -> $str { Q::Literal::Str.new(:value($str.value)) },
            'Q::Term::Array' => -> $array { Q::Term::Array.new(:elements($array.elements)) },
            'Q::Literal::None' => -> { Q::Literal::None.new },
            'Q::Block' => -> $paramlist, $stmtlist { Q::Block.new(:parameterlist($paramlist), :statementlist($stmtlist)) },
            'Q::Identifier' => -> $name { Q::Identifier.new(:name($name.value)) },
            'Q::StatementList' => -> $array { Q::StatementList.new(:statements($array.elements)) },
            'Q::ParameterList' => -> $array { Q::ParameterList.new(:parameters($array.elements)) },
            'Q::ArgumentList' => -> $array { Q::ArgumentList.new(:arguments($array.elements)) },
            'Q::Prefix::Minus' => -> $expr { Q::Prefix::Minus.new(:$expr) },
            'Q::Infix::Addition' => -> $lhs, $rhs { Q::Infix::Addition.new(:$lhs, :$rhs) },
            'Q::Infix::Concat' => -> $lhs, $rhs { Q::Infix::Concat.new(:$lhs, :$rhs) },
            'Q::Infix::Assignment' => -> $lhs, $rhs { Q::Infix::Assignment.new(:$lhs, :$rhs) },
            'Q::Infix::Eq' => -> $lhs, $rhs { Q::Infix::Eq.new(:$lhs, :$rhs) },
            'Q::Postfix::Call' => -> $expr, $arglist { Q::Postfix::Call.new(:$expr, :argumentlist($arglist)) },
            'Q::Postfix::Index' => -> $expr, $pos { Q::Postfix::Index.new(:$expr, :index($pos)) },
            'Q::Statement::My' => -> $ident, $assign = Any { Q::Statement::My.new(:$ident, :$assign) },
            'Q::Statement::Constant' => -> $ident, $assign { Q::Statement::Constant.new(:$ident, :$assign) },
            'Q::Statement::Expr' => -> $expr { Q::Statement::Expr.new(:$expr) },
            'Q::Statement::If' => -> $expr, $block { Q::Statement::If.new(:$expr, :$block) },
            'Q::Statement::Block' => -> $block { Q::Statement::Block.new(:$block) },
            'Q::Statement::Sub' => -> $ident, $block { Q::Statement::Sub.new(:$ident, :$block) },
            'Q::Statement::Macro' => -> $ident, $block { Q::Statement::Macro.new(:$ident, :$block) },
            'Q::Statement::Return' => -> $expr = Any { Q::Statement::Return.new(:$expr) },
            'Q::Statement::For' => -> $expr, $block { Q::Statement::For.new(:$expr, :$block) },
            'Q::Statement::While' => -> $expr, $block { Q::Statement::While.new(:$expr, :$block) },
            'Q::Statement::BEGIN' => -> $block { Q::Statement::BEGIN.new(:$block) },

            value => sub ($_) {
                when Q::Literal::None {
                    return Val::None.new;
                }
                when Q::Term::Array {
                    return Val::Array.new(:elements(.elements));
                }
                when Q::Literal {
                    return .value;
                }
                die X::TypeCheck.new(
                    :operation<value()>,
                    :got($_),
                    :expected("a Q::Literal type that has a value()"));
            },
            paramlist => sub ($_) {
                # XXX: typecheck
                return .parameterlist.parameters;
            },
            stmtlist => sub ($_) {
                # XXX: typecheck
                return .statementlist.statements;
            },
            expr => sub ($_) {
                # XXX: typecheck
                return .expr;
            },
            lhs => sub ($_) {
                # XXX: typecheck
                return .lhs;
            },
            rhs => sub ($_) {
                # XXX: typecheck
                return .rhs;
            },
            pos => sub ($_) {
                # XXX: typecheck
                return .index;
            },
            arglist => sub ($_) {
                # XXX: typecheck
                return .argumentlist.arguments;
            },
            ident => sub ($_) {
                # XXX: typecheck
                return .ident;
            },
            assign => sub ($_) {
                # XXX: typecheck
                return .assignment;
            },
            block => sub ($_) {
                # XXX: typecheck
                return .block;
            },
            name => sub ($_) {
                # XXX: typecheck
                return .name;
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
                    multi equal-value(@l, @r) { # arrays occur in the internals of Qtrees
                        sub equal-at-index($i) { equal-value(@l[$i], @r[$i]) }

                        @l == @r && |(^@l).map(&equal-at-index);
                    }
                    multi equal-value(Str $l, Str $r) { $l eq $r } # strings do too

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
        ;

        sub _007ize(&fn) {
            return sub (|c) { wrap &fn(|c) };
        }

        sub create-paramlist(@params) {
            Q::ParameterList.new(:parameters(
                @params».name».substr(1).map({ Q::Identifier.new(:name($_)) })
            ));
        }

        return @builtins.map: {
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
        my $scope = _007::Parser::OpScope.new;

        for self.get-subs -> Pair (:key($name), :value($subval)) {
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
                        | Q::Statement::Trait | Q::Postfix::Property {
                        $obj.ident;
                    }
                    die X::TypeCheck.new(
                        :operation<.ident>,
                        :got($obj),
                        :expected("any number of types with the .ident property"));
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
                        :expected("Q::Statement::My | Q::Statement::Constant"));
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
