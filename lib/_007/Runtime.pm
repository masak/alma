use _007::Q;

role Frame {
    has $.block;
    has %.pad;
}

constant NO_OUTER = {};

role _007::Runtime {
    has $.output;
    has @!frames;

    submethod BUILD(:$output) {
        $!output = $output;
        my $setting = Val::Block.new(
            :outer-frame(NO_OUTER));
        self.enter($setting);
        self.load-builtins;
    }

    method run(Q::Statements $statements) {
        my $compunit = Val::Block.new(
            :$statements,
            :outer-frame(self.current-frame));
        self.enter($compunit);

        $statements.run(self);
        self.leave;
        CATCH {
            when X::Control::Return {
                die X::ControlFlow::Return.new;
            }
        }
    }

    method enter($block) {
        my $frame = Frame.new(:$block);
        @!frames.push($frame);
        for $block.statements.static-lexpad.kv -> $name, $value {
            self.declare-var($name);
            self.put-var($name, $value);
        }
        for $block.statements.statements.kv -> $i, $_ {
            when Q::Statement::Sub {
                my $name = .ident.name;
                my $parameters = .parameters;
                my $statements = .statements;
                my $outer-frame = $frame;
                my $val = Val::Sub.new(:$name, :$parameters, :$statements, :$outer-frame);
                self.put-var($name, $val);
            }
        }
    }

    method leave {
        @!frames.pop;
    }

    method unroll-to($frame) {
        until self.current-frame === $frame {
            self.leave;
        }
        return;
    }

    method current-frame {
        @!frames[*-1];
    }

    method !find($symbol) {
        my $frame = self.current-frame;
        repeat while $frame !=== NO_OUTER {
            return $frame.pad
                if $frame.pad{$symbol} :exists;
            $frame = $frame.block.outer-frame;
        }
        die X::Undeclared.new(:$symbol);
    }

    method put-var($name, $value) {
        my %pad := self!find($name);
        %pad{$name} = $value;
    }

    method get-var($name) {
        my %pad := self!find($name);
        return %pad{$name};
    }

    method declare-var($name) {
        self.current-frame.pad{$name} = Val::None.new;
    }

    method declared($name) {
        try self!find($name) && return True;
        return False;
    }

    method declared-locally($name) {
        my $frame = self.current-frame;
        return True
            if $frame.pad{$name} :exists;
    }

    method register-subhandler {
        self.declare-var("--RETURN-TO--");
        self.put-var("--RETURN-TO--", $.current-frame);
    }

    method load-builtins {
        my %builtins =
            say      => -> $arg { self.output.say(~$arg) },
            type     => sub ($arg) { return 'Sub' if $arg ~~ Val::Sub; $arg.^name.substr('Val::'.chars) },
            str => sub ($_) {
                when Val { return Val::Str.new(:value(.value.Str)) }
                die X::TypeCheck.new(
                    :operation<str()>,
                    :got($_),
                    :expected("something that can be converted to a string"));
            },
            int => sub ($_) {
                when Val::Str {
                    return Val::Int.new(:value(.value.Int))
                        if .value ~~ /^ '-'? \d+ $/;
                    proceed;
                }
                when Val::Int {
                    return $_;
                }
                die X::TypeCheck.new(
                    :operation<int()>,
                    :got($_),
                    :expected("something that can be converted to an int"));
            },
            abs      => -> $arg { Val::Int.new(:value($arg.value.abs)) },
            min      => -> $a, $b { Val::Int.new(:value(min($a.value, $b.value))) },
            max      => -> $a, $b { Val::Int.new(:value(max($a.value, $b.value))) },
            chr      => -> $arg { Val::Str.new(:value($arg.value.chr)) },
            ord      => -> $arg { Val::Int.new(:value($arg.value.ord)) },
            chars    => -> $arg { Val::Int.new(:value($arg.value.Str.chars)) },
            uc       => -> $arg { Val::Str.new(:value($arg.value.uc)) },
            lc       => -> $arg { Val::Str.new(:value($arg.value.lc)) },
            trim     => -> $arg { Val::Str.new(:value($arg.value.trim)) },
            elems    => -> $arg { Val::Int.new(:value($arg.elements.elems)) },
            reversed => -> $arg { Val::Array.new(:elements($arg.elements.reverse)) },
            sorted   => -> $arg { Val::Array.new(:elements($arg.elements.sort)) },
            join     => -> $a, $sep { Val::Str.new(:value($a.elements.join($sep.value.Str))) },
            split    => -> $s, $sep { Val::Array.new(:elements($s.value.split($sep.value).map({ Val::Str.new(:value($_)) }))) },
            index    => -> $s, $substr { Val::Int.new(:value($s.value.index($substr.value) // -1)) },
            substr   => sub ($s, $pos, $chars?) { Val::Str.new(:value($s.value.substr($pos.value, $chars.defined ?? $chars.value !! $s.value.chars))) },
            charat   => -> $s, $pos { Val::Str.new(:value($s.value.comb[$pos.value] // die X::Subscript::TooLarge.new)) },
            filter   => -> $fn, $a {
                my $array = Val::Array.new;
                for $a.elements {
                    $array.elements.push($_) if self.call($fn, [$_]).truthy;
                }
                $array;
            },
            map      => -> $fn, $a {
                my $array = Val::Array.new;
                for $a.elements {
                    $array.elements.push(self.call($fn, [$_]));
                }
                $array;
            },
            'infix:<+>' => -> $lhs, $rhs { #`[not implemented here] },
            'prefix:<->' => -> $lhs, $rhs { #`[not implemented here] },

            'Q::Literal::Int' => -> $int { Q::Literal::Int.new($int.value) },
            'Q::Literal::Str' => -> $str { Q::Literal::Str.new($str.value) },
            'Q::Literal::Array' => -> $array { Q::Literal::Array.new($array.value) },
            'Q::Literal::None' => -> { Q::Literal::None.new },
            'Q::Block' => -> $params, $stmts { Q::Block.new($params, $stmts) },
            'Q::Identifier' => -> $name { Q::Identifier.new($name.value) },
            'Q::Statements' => -> $array { Q::Statements.new($array.value) },
            'Q::Parameters' => -> $array { Q::Parameters.new($array.value) },
            'Q::Arguments' => -> $array { Q::Arguments.new($array.elements) },
            'Q::Prefix::Minus' => -> $expr { Q::Prefix::Minus.new($expr) },
            'Q::Infix::Addition' => -> $lhs, $rhs { Q::Infix::Addition.new($lhs, $rhs) },
            'Q::Infix::Concat' => -> $lhs, $rhs { Q::Infix::Concat.new($lhs, $rhs) },
            'Q::Infix::Assignment' => -> $lhs, $rhs { Q::Infix::Assignment.new($lhs, $rhs) },
            'Q::Infix::Eq' => -> $lhs, $rhs { Q::Infix::Eq.new($lhs, $rhs) },
            'Q::Postfix::Call' => -> $expr, $args { Q::Postfix::Call.new($expr, $args) },
            'Q::Postfix::Index' => -> $expr, $pos { Q::Postfix::Index.new($expr, $pos) },
            'Q::Statement::My' => -> $ident, $assign = Empty { Q::Statement::My.new($ident, |$assign) },
            'Q::Statement::Constant' => -> $ident, $assign { Q::Statement::Constant.new($ident, $assign) },
            'Q::Statement::Expr' => -> $expr { Q::Statement::Expr.new($expr) },
            'Q::Statement::If' => -> $expr, $block { Q::Statement::If.new($expr, $block) },
            'Q::Statement::Block' => -> $block { Q::Statement::Block.new($block) },
            'Q::Statement::Sub' => -> $ident, $params, $block { Q::Statement::Sub.new($ident, $params, $block) },
            'Q::Statement::Macro' => -> $ident, $params, $block { Q::Statement::Macro.new($ident, $params, $block) },
            'Q::Statement::Return' => -> $expr = Empty { Q::Statement::Return.new(|$expr) },
            'Q::Statement::For' => -> $expr, $block { Q::Statement::For.new($expr, $block) },
            'Q::Statement::While' => -> $expr, $block { Q::Statement::While.new($expr, $block) },
            'Q::Statement::BEGIN' => -> $block { Q::Statement::BEGIN.new($block) },

            array => sub ($_) {
                when Val::Array {
                    return $_;
                }
                when Q::Statements {
                    return Val::Array.new(:elements(.statements));
                }
                when Q::Parameters {
                    return Val::Array.new(:elements(.parameters));
                }
                when Q::Arguments {
                    return Val::Array.new(:elements(.arguments));
                }
                die X::TypeCheck.new(
                    :operation<str()>,
                    :got($_),
                    :expected("something that can be converted to an array"));
            },
            value => sub ($_) {
                when Q::Literal {
                    return .eval(self);
                }
                die X::TypeCheck.new(
                    :operation<value()>,
                    :got($_),
                    :expected("a Q::Literal type that has a value()"));
            },
            params => sub ($_) {
                # XXX: typecheck
                my $retval = .parameters;
                return $retval ~~ Array
                    ?? Val::Array.new(:elements($retval))
                    !! $retval;
            },
            stmts => sub ($_) {
                # XXX: typecheck
                my $retval = .statements;
                return $retval ~~ Array
                    ?? Val::Array.new(:elements($retval))
                    !! $retval;
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
            args => sub ($_) {
                # XXX: typecheck
                my $retval = .arguments;
                return $retval ~~ Array
                    ?? Val::Array.new(:elements($retval))
                    !! $retval;
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
        ;

        for %builtins.kv -> $name, $sub {
            self.declare-var($name);
            self.put-var($name, Val::Sub::Builtin.new($sub));
        }
    }

    method sigbind($type, $c, @args) {
        die "$type with {$c.parameters.parameters.elems} parameters "       # XXX: make this into an X::
            ~ "called with {@args.elems} arguments"
            unless $c.parameters.parameters == @args;
        self.enter($c);
        for $c.parameters.parameters Z @args -> ($param, $arg) {
            my $name = $param.name;
            self.declare-var($name);
            self.put-var($name, $arg);
        }
    }

    multi method call(Val::Block $c, @args) {
        self.sigbind("Block", $c, @args);
        $c.statements.run(self);
        self.leave;
        return Val::None.new;
    }

    multi method call(Val::Sub $c, @args) {
        self.sigbind("Sub", $c, @args);
        self.register-subhandler;
        my $frame = self.current-frame;
        $c.statements.run(self);
        self.leave;
        CATCH {
            when X::Control::Return {
                die $_   # keep unrolling the interpreter's stack until we're there
                    unless .frame === $frame;
                self.unroll-to($frame);
                self.leave;
                return .value;
            }
        }
        return Val::None.new;
    }

    multi method call(Val::Sub::Builtin $c, @args) {
        my $result = $c.code.(|@args);
        return $result if $result;
        return Val::None.new;
    }
}
