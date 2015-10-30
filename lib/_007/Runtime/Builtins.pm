use _007::Val;
use _007::Q;

class _007::Runtime::Builtins {
    has $.runtime;

    sub wrap($_) {
        when Val | Q { $_ }
        when Nil { Val::None.new }
        when Str { Val::Str.new(:value($_)) }
        when Int { Val::Int.new(:value($_)) }
        when Array | Seq { Val::Array.new(:elements(.map(&wrap))) }
        default { die "Got some unknown value of type ", .^name }
    }

    method get-subs {
        sub escape($_) {
            return (~$_).subst("\\", "\\\\", :g).subst(q["], q[\\"], :g);
        }

        sub stringify-inside-array($_) {
            when Val::Str {
                return q["] ~ escape(.value) ~ q["]
            }
            when Val::Array {
                return '[%s]'.&sprintf(.elements>>.&stringify-inside-array.join(', '));
            }
            when Q {
                return .Str;
            }
            return .value.Str;
        }

        my %builtins =
            say      => -> $arg {
                $.runtime.output.say($arg ~~ Val::Array ?? %builtins<str>($arg).Str !! ~$arg);
                Nil;
            },
            type     => -> $arg {
                $arg ~~ Val::Sub
                    ?? "Sub"
                    !! $arg.^name.substr('Val::'.chars);
            },
            str => sub ($_) {
                when Val::Array {
                    return stringify-inside-array($_);
                }
                when Val::None { return .Str }
                when Val { return .value.Str }
                die X::TypeCheck.new(
                    :operation<str()>,
                    :got($_),
                    :expected("something that can be converted to a string"));
            },
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

            'Q::Literal::Int' => -> $int { Q::Literal::Int.new($int.value) },
            'Q::Literal::Str' => -> $str { Q::Literal::Str.new($str.value) },
            'Q::Literal::Array' => -> $array { Q::Literal::Array.new($array.value) },
            'Q::Literal::None' => -> { Q::Literal::None.new },
            'Q::Block' => -> $paramlist, $stmtlist { Q::Block.new($paramlist, $stmtlist) },
            'Q::Identifier' => -> $name { Q::Identifier.new($name.value) },
            'Q::StatementList' => -> $array { Q::StatementList.new($array.value) },
            'Q::ParameterList' => -> $array { Q::ParameterList.new($array.value) },
            'Q::ArgumentList' => -> $array { Q::ArgumentList.new($array.elements) },
            'Q::Prefix::Minus' => -> $expr { Q::Prefix::Minus.new($expr) },
            'Q::Infix::Addition' => -> $lhs, $rhs { Q::Infix::Addition.new($lhs, $rhs) },
            'Q::Infix::Concat' => -> $lhs, $rhs { Q::Infix::Concat.new($lhs, $rhs) },
            'Q::Infix::Assignment' => -> $lhs, $rhs { Q::Infix::Assignment.new($lhs, $rhs) },
            'Q::Infix::Eq' => -> $lhs, $rhs { Q::Infix::Eq.new($lhs, $rhs) },
            'Q::Postfix::Call' => -> $expr, $arglist { Q::Postfix::Call.new($expr, $arglist) },
            'Q::Postfix::Index' => -> $expr, $pos { Q::Postfix::Index.new($expr, $pos) },
            'Q::Statement::My' => -> $ident, $assign = Empty { Q::Statement::My.new($ident, |$assign) },
            'Q::Statement::Constant' => -> $ident, $assign { Q::Statement::Constant.new($ident, $assign) },
            'Q::Statement::Expr' => -> $expr { Q::Statement::Expr.new($expr) },
            'Q::Statement::If' => -> $expr, $block { Q::Statement::If.new($expr, $block) },
            'Q::Statement::Block' => -> $block { Q::Statement::Block.new($block) },
            'Q::Statement::Sub' => -> $ident, $paramlist, $block { Q::Statement::Sub.new($ident, $paramlist, $block) },
            'Q::Statement::Macro' => -> $ident, $paramlist, $block { Q::Statement::Macro.new($ident, $paramlist, $block) },
            'Q::Statement::Return' => -> $expr = Empty { Q::Statement::Return.new(|$expr) },
            'Q::Statement::For' => -> $expr, $block { Q::Statement::For.new($expr, $block) },
            'Q::Statement::While' => -> $expr, $block { Q::Statement::While.new($expr, $block) },
            'Q::Statement::BEGIN' => -> $block { Q::Statement::BEGIN.new($block) },

            value => sub ($_) {
                when Q::Literal::None {
                    return Val::None.new;
                }
                when Q::Literal::Array {
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
        ;

        sub _007ize(&fn) {
            return sub (|c) { wrap &fn(|c) };
        }

        return my % = %builtins.map: {
            .key => Val::Sub::Builtin.new(.key, _007ize(.value))
        };
    }

    method property($obj, $propname) {
        my $value = do given $propname {
            when "value" {
                given $obj {
                    when Q::Literal::None {
                        Val::None.new;
                    }
                    when Q::Literal::Array {
                        Val::Array.new(:elements($obj.elements));
                    }
                    when Q::Literal {
                        $obj.value;
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
