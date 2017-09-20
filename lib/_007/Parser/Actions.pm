use _007::Type;
use _007::Object;
use _007::Parser::Syntax;

class X::String::Newline is Exception {
    method message { "Found a newline inside a string literal" }
}

class X::PointyBlock::SinkContext is Exception {
    method message { "Pointy blocks cannot occur on the statement level" }
}

class X::Trait::Conflict is Exception {
    has Str $.trait1;
    has Str $.trait2;

    method message { "Traits '$.trait1' and '$.trait2' cannot coexist on the same routine" }
}

class X::Trait::Duplicate is Exception {
    has Str $.trait;

    method message { "Trait '$.trait' is used more than once" }
}

class X::Trait::IllegalValue is Exception {
    has Str $.trait;
    has Str $.value;

    method message { "The value '$.value' is not compatible with the trait '$.trait'" }
}

class X::Macro::Postdeclared is Exception {
    has Str $.name;

    method message { "Macro $.name declared after it was called" }
}

class X::Op::Nonassociative is Exception {
    has Str $.op1;
    has Str $.op2;

    method message {
        my $name1 = $.op1.type.substr(1, *-1);
        my $name2 = $.op2.type.substr(1, *-1);
        "'$name1' and '$name2' do not associate -- please use parentheses"
    }
}

class X::Precedence::Incompatible is Exception {
    method message { "Trying to relate a pre/postfix operator with an infix operator" }
}

sub empty-array() { wrap([]) }
sub empty-dict() { wrap({}) }

class _007::Parser::Actions {
    method finish-block($block) {
        $block.properties<static-lexpad> = $*runtime.current-frame.value<pad>;
        $*runtime.leave;
    }

    method TOP($/) {
        make $<compunit>.ast;
    }

    method compunit($/) {
        my $block = create(TYPE<Q::Block>,
            :parameterlist(create(TYPE<Q::ParameterList>,
                :parameters(empty-array()),
            )),
            :statementlist($<statementlist>.ast),
            :static-lexpad(empty-dict()),
        );
        make create(TYPE<Q::CompUnit>, :$block);
        self.finish-block($block);
    }

    method statementlist($/) {
        my $statements = wrap($<statement>».ast);
        make create(TYPE<Q::StatementList>, :$statements);
    }

    method statement:my ($/) {
        make create(TYPE<Q::Statement::My>,
            :identifier($<identifier>.ast),
            :expr($<EXPR> ?? $<EXPR>.ast !! NONE));
    }

    method statement:constant ($/) {
        die X::Syntax::Missing.new(:what("initializer on constant declaration"))
            unless $<EXPR>;

        make create(TYPE<Q::Statement::Constant>,
            :identifier($<identifier>.ast),
            :expr($<EXPR>.ast));

        my $value = bound-method($<EXPR>.ast, "eval", $*runtime)();
        bound-method($<identifier>.ast, "put-value", $*runtime)($value);
    }

    method statement:expr ($/) {
        # XXX: this is a special case for macros that have been expanded at the
        #      top level of an expression statement, but it could happen anywhere
        #      in the expression tree
        if $<EXPR>.ast.is-a("Q::Block") {
            make create(TYPE<Q::Statement::Expr>, :expr(create(TYPE<Q::Postfix::Call>,
                :identifier(create(TYPE<Q::Identifier>, :name(wrap("postfix:()")))),
                :operand(create(TYPE<Q::Term::Sub>, :identifier(NONE), :block($<EXPR>.ast))),
                :argumentlist(create(TYPE<Q::ArgumentList>))
            )));
        }
        else {
            make create(TYPE<Q::Statement::Expr>, :expr($<EXPR>.ast));
        }
    }

    method statement:block ($/) {
        die X::PointyBlock::SinkContext.new
            if $<pblock><parameterlist>;
        make create(TYPE<Q::Statement::Block>, :block($<pblock>.ast));
    }

    sub maybe-install-operator(Str $identname, @trait) {
        return
            unless $identname ~~ /^ (< prefix infix postfix >)
                                    ':' (.+) /;

        my $type = ~$0;
        my $op = ~$1;

        my %precedence;
        my @prec-traits = <equal looser tighter>;
        my $assoc;
        for @trait -> $trait {
            my $name = $trait<identifier>.ast.properties<name>.value;
            if $name eq any @prec-traits {
                my $identifier = $trait<EXPR>.ast;
                my $prep = $name eq "equal" ?? "to" !! "than";
                die "The thing your op is $name $prep must be an identifier"
                    unless $identifier.is-a("Q::Identifier");
                sub check-if-op(Str $s) {
                    die "Unknown thing in '$name' trait"
                        unless $s ~~ /^ < pre in post > 'fix:' /;
                    die X::Precedence::Incompatible.new
                        if $type eq ('prefix' | 'postfix') && $s ~~ /^ in/
                        || $type eq 'infix' && $s ~~ /^ < pre post >/;
                    %precedence{$name} = $s;
                }($identifier.properties<name>.value);
            }
            elsif $name eq "assoc" {
                my $string = $trait<EXPR>.ast;
                die "The associativity must be a string"
                    unless $string.is-a("Q::Literal::Str");
                my Str $value = $string.properties<value>.value;
                die X::Trait::IllegalValue.new(:trait<assoc>, :$value)
                    unless $value eq any "left", "non", "right";
                $assoc = $value;
            }
            else {
                die "Unknown trait '$name'";
            }
        }

        if %precedence.keys > 1 {
            my ($trait1, $trait2) = %precedence.keys.sort;
            die X::Trait::Conflict.new(:$trait1, :$trait2)
                if %precedence{$trait1} && %precedence{$trait2};
        }

        $*parser.opscope.install($type, $op, :%precedence, :$assoc);
    }

    method statement:sub-or-macro ($/) {
        my $identifier = $<identifier>.ast;
        my $name = $identifier.properties<name>;
        my $parameterlist = $<parameterlist>.ast;
        my $traitlist = $<traitlist>.ast;
        my $statementlist = $<blockoid>.ast;

        my $block = create(TYPE<Q::Block>,
            :$parameterlist,
            :$statementlist,
            :static-lexpad(empty-dict()),
        );
        my $static-lexpad = $*runtime.current-frame.value<pad>;
        self.finish-block($block);

        my $outer-frame = $*runtime.current-frame;
        my $val;
        if $<routine> eq "sub" {
            make create(TYPE<Q::Statement::Sub>, :$identifier, :$traitlist, :$block);
            $val = create(TYPE<Sub>, :$name, :$parameterlist, :$statementlist, :$outer-frame, :$static-lexpad);
        }
        elsif $<routine> eq "macro" {
            make create(TYPE<Q::Statement::Macro>, :$identifier, :$traitlist, :$block);
            $val = create(TYPE<Macro>, :$name, :$parameterlist, :$statementlist, :$outer-frame, :$static-lexpad);
        }
        else {
            die "Unknown routine type $<routine>"; # XXX: Turn this into an X:: exception
        }

        bound-method($identifier, "put-value", $*runtime)($val);

        maybe-install-operator($name.value, $<traitlist><trait>);
    }

    method statement:return ($/) {
        die X::ControlFlow::Return.new
            unless $*insub;
        make create(TYPE<Q::Statement::Return>, :expr($<EXPR> ?? $<EXPR>.ast !! NONE));
    }

    method statement:throw ($/) {
        make create(TYPE<Q::Statement::Throw>, :expr($<EXPR> ?? $<EXPR>.ast !! NONE));
    }

    method statement:if ($/) {
        my %parameters = $<xblock>.ast;
        %parameters<else> = $<else> :exists
            ?? $<else>.ast
            !! NONE;

        make create(TYPE<Q::Statement::If>, |%parameters);
    }

    method statement:for ($/) {
        make create(TYPE<Q::Statement::For>, |$<xblock>.ast);
    }

    method statement:while ($/) {
        make create(TYPE<Q::Statement::While>, |$<xblock>.ast);
    }

    method statement:BEGIN ($/) {
        my $block = $<block>.ast;
        make create(TYPE<Q::Statement::BEGIN>, :$block);
        $*runtime.run(create(TYPE<Q::CompUnit>, :$block));
    }

    method statement:class ($/) {
        my $identifier = $<identifier>.ast;
        my $block = $<block>.ast;
        make create(TYPE<Q::Statement::Class>, :$block);
        my $name = $identifier.properties<name>.value;
        my $val = _007::Type.new(:$name);
        bound-method($identifier, "put-value", $*runtime)($val);
    }

    method traitlist($/) {
        my @traits = $<trait>».ast;
        if bag( @traits.map: *.properties<identifier>.properties<name>.value ).grep( *.value > 1 )[0] -> $p {
            my $trait = $p.key;
            die X::Trait::Duplicate.new(:$trait);
        }
        my $traits = wrap(@traits);
        make create(TYPE<Q::TraitList>, :$traits);
    }
    method trait($/) {
        make create(TYPE<Q::Trait>, :identifier($<identifier>.ast), :expr($<EXPR>.ast));
    }

    method blockoid ($/) {
        make $<statementlist>.ast;
    }
    method block ($/) {
        my $block = create(TYPE<Q::Block>,
            :parameterlist(create(TYPE<Q::ParameterList>,
                :parameters(empty-array()),
            )),
            :statementlist($<blockoid>.ast)
            :static-lexpad(NONE));
        make $block;
        self.finish-block($block);
    }
    method pblock ($/) {
        if $<parameterlist> {
            my $block = create(TYPE<Q::Block>,
                :parameterlist($<parameterlist>.ast),
                :statementlist($<blockoid>.ast),
                :static-lexpad(empty-dict()));
            make $block;
            self.finish-block($block);
        } else {
            make $<block>.ast;
        }
    }
    method xblock ($/) {
        make {
            expr => $<EXPR>.ast,
            block => $<pblock>.ast
        };
    }

    sub is-macro($q, $qtype, $identifier) {
        $q.is-a($qtype)
            && $identifier.is-a("Q::Identifier")
            && defined((my $macro = $*runtime.maybe-get-var($identifier.properties<name>.value)))
            && $macro.is-a("Macro");
    }

    sub expand($macro, @arguments, &unexpanded-callback:()) {
        my $expansion = internal-call($macro, $*runtime, @arguments);

        if $expansion.is-a("Q::Statement::My") {
            _007::Parser::Syntax::declare(TYPE<Q::Statement::My>, $expansion.properties<identifier>.properties<name>.value);
        }

        if $*unexpanded {
            return &unexpanded-callback();
        }
        else {
            if $expansion.is-a("Q::Statement") {
                my $statements = wrap([$expansion]);
                $expansion = create(TYPE<Q::StatementList>, :$statements);
            }
            elsif $expansion === NONE {
                my $statements = wrap([]);
                $expansion = create(TYPE<Q::StatementList>, :$statements);
            }

            if $expansion.is-a("Q::StatementList") {
                $expansion = create(TYPE<Q::Expr::StatementListAdapter>, :statementlist($expansion));
            }

            if $expansion.is-a("Q::Block") {
                $expansion = create(TYPE<Q::Expr::StatementListAdapter>, :statementlist($expansion.properties<statementlist>));
            }

            return $expansion;
        }
    }

    method EXPR($/) {
        sub name($op) {
            $op.properties<identifier>.properties<name>.value;
        }

        sub tighter($op1, $op2, $_ = $*parser.opscope.infixprec) {
            .first(*.contains(name($op1)), :k) > .first(*.contains(name($op2)), :k);
        }

        sub equal($op1, $op2, $_ = $*parser.opscope.infixprec) {
            .first(*.contains(name($op1)), :k) == .first(*.contains(name($op2)), :k);
        }

        sub left-associative($op) {
            return $*parser.opscope.infixprec.first(*.contains(name($op))).assoc eq "left";
        }

        sub non-associative($op) {
            return $*parser.opscope.infixprec.first(*.contains(name($op))).assoc eq "non";
        }

        # XXX: this needs to be lifted up to 007 eventually
        sub is-assignable(_007::Type $decltype) {
            return $decltype === TYPE<Q::Parameter> || $decltype === TYPE<Q::Statement::My>;
        }

        my @opstack;
        my @termstack = $<termish>[0].ast;
        sub REDUCE {
            my $t2 = @termstack.pop;
            my $infix = @opstack.pop;
            my $t1 = @termstack.pop;

            if $infix.is-a("Q::Unquote") {
                @termstack.push(create(TYPE<Q::Unquote::Infix>,
                    :qtype($infix.properties<qtype>),
                    :expr($infix.properties<expr>),
                    :lhs($t1),
                    :rhs($t2),
                ));
                return;
            }

            if my $macro = is-macro($infix, TYPE<Q::Infix>, $infix.properties<identifier>) {
                @termstack.push(expand($macro, [$t1, $t2],
                    -> { create($infix.type, :lhs($t1), :rhs($t2), :identifier($infix.properties<identifier>)) }));
            }
            else {
                @termstack.push(create($infix.type, :lhs($t1), :rhs($t2), :identifier($infix.properties<identifier>)));

                if $infix.is-a("Q::Infix::Assignment") && $t1.is-a("Q::Identifier") {
                    my $frame = $*runtime.current-frame;
                    my $symbol = $t1.properties<name>.value;
                    die X::Undeclared.new(:$symbol)
                        unless @*declstack[*-1]{$symbol} :exists;
                    my $decltype = @*declstack[*-1]{$symbol};
                    my $declname = $decltype.^name.subst(/ .* '::'/, "").lc;
                    die X::Assignment::RO.new(:typename("$declname '$symbol'"))
                        unless is-assignable($decltype);
                    %*assigned{$frame.id ~ $symbol}++;
                }
            }
        }

        for $<infix>».ast Z $<termish>[1..*]».ast -> ($infix, $term) {
            while @opstack && (tighter(@opstack[*-1], $infix)
                || equal(@opstack[*-1], $infix) && left-associative($infix)) {
                REDUCE;
            }
            die X::Op::Nonassociative.new(
                :op1(@opstack[*-1].properties<identifier>.properties<name>.value),
                :op2($infix.properties<identifier>.properties<name>.value))
                if @opstack && equal(@opstack[*-1], $infix) && non-associative($infix);
            @opstack.push($infix);
            @termstack.push($term);
        }
        while @opstack {
            REDUCE;
        }

        make @termstack[0];
    }

    method termish($/) {
        sub name($op) {
            $op.properties<identifier>.properties<name>.value;
        }

        sub tighter($op1, $op2, $_ = $*parser.opscope.prepostfixprec) {
            .first(*.contains(name($op1)), :k) > .first(*.contains(name($op2)), :k);
        }

        sub equal($op1, $op2, $_ = $*parser.opscope.prepostfixprec) {
            .first(*.contains(name($op1)), :k) == .first(*.contains(name($op2)), :k);
        }

        sub left-associative($op) {
            return $*parser.opscope.prepostfixprec.first(*.contains(name($op))).assoc eq "left";
        }

        sub non-associative($op) {
            return $*parser.opscope.prepostfixprec.first(*.contains(name($op))).assoc eq "non";
        }

        make $<term>.ast;

        my @prefixes = @<prefix>.reverse;   # evaluated inside-out
        my @postfixes = @<postfix>;

        sub handle-prefix($/) {
            my $prefix = @prefixes.shift.ast;

            if $prefix.is-a("Q::Unquote") {
                make create(TYPE<Q::Unquote::Prefix>,
                    :qtype($prefix.properties<qtype>),
                    :expr($prefix.properties<expr>),
                    :operand($/.ast),
                );
                return;
            }

            if my $macro = is-macro($prefix, TYPE<Q::Prefix>, $prefix.properties<identifier>) {
                make expand($macro, [$/.ast],
                    -> { create($prefix.type, :operand($/.ast), :identifier($prefix.properties<identifier>)) });
            }
            else {
                make create($prefix.type, :operand($/.ast), :identifier($prefix.properties<identifier>));
            }
        }

        sub handle-postfix($/) {
            my $postfix = @postfixes.shift.ast;
            my $identifier = $postfix.properties<identifier>;
            if is-macro($postfix, TYPE<Q::Postfix::Call>, $/.ast) -> $macro {
                make expand($macro, $postfix.properties<argumentlist>.properties<arguments>.value, -> {
                    create($postfix.type, :$identifier, :operand($/.ast), :argumentlist($postfix.properties<argumentlist>));
                });
            }
            elsif $postfix.is-a("Q::Postfix::Index") {
                make create($postfix.type, :$identifier, :operand($/.ast), :index($postfix.properties<index>));
            }
            elsif $postfix.is-a("Q::Postfix::Call") {
                make create($postfix.type, :$identifier, :operand($/.ast), :argumentlist($postfix.properties<argumentlist>));
            }
            elsif $postfix.is-a("Q::Postfix::Property") {
                make create($postfix.type, :$identifier, :operand($/.ast), :property($postfix.properties<property>));
            }
            else {
                if is-macro($postfix, TYPE<Q::Postfix>, $identifier) -> $macro {
                    make expand($macro, [$/.ast], -> {
                        create($postfix.type, :$identifier, :operand($/.ast));
                    });
                }
                else {
                    make create($postfix.type, :$identifier, :operand($/.ast));
                }
            }
        }

        while @postfixes || @prefixes {
            if @postfixes && !@prefixes {
                handle-postfix($/);
            }
            elsif @prefixes && !@postfixes {
                handle-prefix($/);
            }
            else {
                my $prefix = @prefixes[0].ast;
                my $postfix = @postfixes[0].ast;
                die X::Op::Nonassociative.new(:op1(name($prefix)), :op2(name($postfix)))
                    if equal($prefix, $postfix) && non-associative($prefix);
                if tighter($prefix, $postfix)
                    || equal($prefix, $postfix) && left-associative($prefix) {

                    handle-prefix($/);
                }
                else {
                    handle-postfix($/);
                }
            }
        }
    }

    method prefix($/) {
        my $op = ~$/;
        my $identifier = create(TYPE<Q::Identifier>,
            :name(wrap("prefix:$op")),
            :frame($*runtime.current-frame),
        );
        make create($*parser.opscope.ops<prefix>{$op}.type, :$identifier, :operand(NONE));
    }

    method prefix-unquote($/) {
        make $<unquote>.ast;
    }

    method str($/) {
        sub check-for-newlines($s) {
            die X::String::Newline.new
                if $s ~~ /\n/;
        }(~$0);
        my $value = wrap((~$0).subst(q[\"], q["], :g).subst(q[\\\\], q[\\], :g));
        make create(TYPE<Q::Literal::Str>, :$value);
    }

    method term:none ($/) {
        make create(TYPE<Q::Literal::None>);
    }

    method term:false ($/) {
        make create(TYPE<Q::Literal::Bool>, :value(FALSE));
    }

    method term:true ($/) {
        make create(TYPE<Q::Literal::Bool>, :value(TRUE));
    }

    method term:int ($/) {
        make create(TYPE<Q::Literal::Int>, :value(wrap(+$/)));
    }

    method term:str ($/) {
        make $<str>.ast;
    }

    method term:array ($/) {
        my $elements = wrap($<EXPR>».ast);
        make create(TYPE<Q::Term::Array>, :$elements);
    }

    method term:parens ($/) {
        make $<EXPR>.ast;
    }

    method term:regex ($/) {
        make create(TYPE<Q::Term::Regex>, :contents($<contents>.ast.properties<value>));
    }

    method term:identifier ($/) {
        make $<identifier>.ast;
        my $name = $<identifier>.ast.properties<name>.value;
        if !$*runtime.declared($name) {
            my $frame = $*runtime.current-frame;
            $*parser.postpone: sub checking-postdeclared {
                my $value = $*runtime.maybe-get-var($name, $frame);
                die X::Undeclared.new(:symbol($name))
                    unless defined $value;
                die X::Macro::Postdeclared.new(:$name)
                    if $value.is-a("Macro");
                die X::Undeclared.new(:symbol($name))
                    unless $value.is-a("Sub");
            };
        }
    }

    method term:block ($/) {
        make $<pblock>.ast;
    }

    method term:quasi ($/) {
        my $qtype = wrap(~($<qtype> // ""));

        if $<block> -> $block {
            # If the quasi consists of a block with a single expression statement, it's very
            # likely that what we want to inject is the expression, not the block.
            #
            # The exception to that heuristic is when we've explicitly specified `@ Q::Block`
            # on the quasi.
            #
            # This is not a "nice" solution, nor a comprehensive one. In the end it's connected
            # to the troubled musings in <https://github.com/masak/007/issues/7>, which aren't
            # completely solved yet.

            if $qtype.value eq "Q::Statement" {
                # XXX: make sure there's only one statement (suboptimal; should parse-error sooner)
                my $contents = $block.ast.properties<statementlist>.properties<statements>.value[0];
                make create(TYPE<Q::Term::Quasi>, :$contents, :$qtype);
                return;
            }
            elsif $qtype.value eq "Q::StatementList" {
                my $contents = $block.ast.properties<statementlist>;
                make create(TYPE<Q::Term::Quasi>, :$contents, :$qtype);
                return;
            }
            elsif $qtype.value ne "Q::Block"
                && $block.ast.is-a("Q::Block")
                && $block.ast.properties<statementlist>.properties<statements>.value.elems == 1
                && $block.ast.properties<statementlist>.properties<statements>.value[0].is-a("Q::Statement::Expr") {

                my $contents = $block.ast.properties<statementlist>.properties<statements>.value[0].properties<expr>;
                make create(TYPE<Q::Term::Quasi>, :$contents, :$qtype);
                return;
            }
        }

        for <argumentlist block compunit EXPR infix parameter parameterlist
            postfix prefix property propertylist statement statementlist
            term trait traitlist unquote> -> $subrule {

            if $/{$subrule} -> $submatch {
                my $contents = $submatch.ast;
                make create(TYPE<Q::Term::Quasi>, :$contents, :$qtype);
                return;
            }
        }

        die "Got something in a quasi that we didn't expect: {$/.keys}";   # should never happen
    }

    method term:sub ($/) {
        my $parameterlist = $<parameterlist>.ast;
        my $traitlist = $<traitlist>.ast;
        my $statementlist = $<blockoid>.ast;

        my $block = create(TYPE<Q::Block>, :$parameterlist, :$statementlist, :static-lexpad(empty-dict()));
        if $<identifier> {
            my $name = $<identifier>.ast.properties<name>;
            my $outer-frame = $*runtime.current-frame.value<outer-frame>;
            my $static-lexpad = $*runtime.current-frame.value<pad>;
            my $val = create(TYPE<Sub>, :$name, :$parameterlist, :$statementlist, :$outer-frame, :$static-lexpad);
            bound-method($<identifier>.ast, "put-value", $*runtime)($val);
        }
        self.finish-block($block);

        my $name = $<identifier> && $<identifier>.ast.properties<name>;
        my $identifier = $<identifier>
            ?? create(TYPE<Q::Identifier>, :$name, :frame(NONE))
            !! NONE;
        make create(TYPE<Q::Term::Sub>, :$identifier, :$traitlist, :$block);
    }

    method unquote ($/) {
        my $qtype = $<identifier>
            ?? $*runtime.get-var($<identifier>.ast.properties<name>.value)
            !! TYPE<Q::Term>;
        make create(TYPE<Q::Unquote>, :$qtype, :expr($<EXPR>.ast));
    }

    method term:new-object ($/) {
        my $type = $<identifier>.ast.properties<name>.value;
        my $type-obj = $*runtime.get-var($type);

        my $known-properties = set($type-obj.type-chain.reverse.map({ .fields }).flat);
        my $seen-properties = set();
        for $<propertylist>.ast.properties<properties>.value -> $p {
            my $property = $p.properties<key>.value;
            # Here we make a slight exception for the wrapped types
            next if $property eq "value" && $type eq "Int" | "Str" | "Array" | "Dict";
            die X::Property::NotDeclared.new(:$type, :$property)
                unless $property (elem) $known-properties;
            $seen-properties (|)= $property;
        }
        for $known-properties.keys -> $property {
            # XXX: once we handle optional properties, we will `next` here

            die X::Property::Required.new(:$type, :$property)
                unless $property (elem) $seen-properties;
        }

        make create(TYPE<Q::Term::Object>,
            # XXX: couldn't we just pass $type here?
            :type(create(TYPE<Q::Identifier>,
                :name(wrap($type)),
                :frame(NONE),
            )),
            :propertylist($<propertylist>.ast));
    }

    method term:dict ($/) {
        make create(TYPE<Q::Term::Dict>,
            :propertylist($<propertylist>.ast));
    }

    method propertylist ($/) {
        my %seen;
        for $<property>».ast -> $p {
            my Str $property = $p.properties<key>.value;
            die X::Property::Duplicate.new(:$property)
                if %seen{$property}++;
        }

        my $properties = wrap($<property>».ast);
        make create(TYPE<Q::PropertyList>, :$properties);
    }

    method property:str-expr ($/) {
        make create(TYPE<Q::Property>, :key($<str>.ast.properties<value>), :value($<value>.ast));
    }

    method property:identifier-expr ($/) {
        my $key = $<identifier>.ast.properties<name>;
        make create(TYPE<Q::Property>, :$key, :value($<value>.ast));
    }

    method property:identifier ($/) {
        my $key = $<identifier>.ast.properties<name>;
        make create(TYPE<Q::Property>, :$key, :value($<identifier>.ast));
    }

    method property:method ($/) {
        my $block = create(TYPE<Q::Block>,
            :parameterlist($<parameterlist>.ast),
            :statementlist($<blockoid>.ast),
            :static-lexpad(wrap({})),
        );
        my $name = $<identifier>.ast.properties<name>;
        my $identifier = create(TYPE<Q::Identifier>, :$name, :frame(NONE));
        make create(TYPE<Q::Property>,
            :key($name),
            :value(create(TYPE<Q::Term::Sub>,
                :$identifier,
                :$block,
                :traitlist(create(TYPE<Q::TraitList>,
                    :traits(wrap([])),
                )),
            )),
        );
        self.finish-block($block);
    }

    method infix($/) {
        my $op = ~$/;
        my $identifier = create(TYPE<Q::Identifier>,
            :name(wrap("infix:$op")),
            :frame($*runtime.current-frame),
        );
        make create($*parser.opscope.ops<infix>{$op}.type, :$identifier, :lhs(NONE), :rhs(NONE));
    }

    method infix-unquote($/) {
        my $got = ~($<unquote><identifier> // "Q::Term");
        die X::Type.new(:operation<parsing>, :$got, :expected(TYPE<Q::Infix>))
            unless $got eq "Q::Infix";

        make $<unquote>.ast;
    }

    method postfix($/) {
        my $op = (~$/).trim;
        if $<index> {  # XXX: more hardcoding :(
            $op = "[]";
        }
        elsif $<call> {
            $op = "()";
        }
        elsif $<prop> {
            $op = ".";
        }
        my $identifier = create(TYPE<Q::Identifier>,
            :name(wrap("postfix:$op")),
            :frame($*runtime.current-frame),
        );
        # XXX: this can't stay hardcoded forever, but we don't have the machinery yet
        # to do these right enough
        if $<index> {
            make create(TYPE<Q::Postfix::Index>, index => $<EXPR>.ast, :$identifier, :operand(NONE));
        }
        elsif $<call> {
            make create(TYPE<Q::Postfix::Call>, argumentlist => $<argumentlist>.ast, :$identifier, :operand(NONE));
        }
        elsif $<prop> {
            make create(TYPE<Q::Postfix::Property>, property => $<identifier>.ast, :$identifier, :operand(NONE));
        }
        else {
            make create($*parser.opscope.ops<postfix>{$op}.type, :$identifier, :operand(NONE));
        }
    }

    method identifier($/) {
        my $value = ~$/;
        sub () {
            $value ~~ s[':<' ([ '\\>' | '\\\\' | <-[>]> ]+) '>' $] = ":{$0}";
            $value ~~ s[':«' ([ '\\»' | '\\\\' | <-[»]> ]+) '»' $] = ":{$0}";
            $value ~~ s:g['\\>'] = '>';
            $value ~~ s:g['\\»'] = '»';
            $value ~~ s:g['\\\\'] = '\\';
        }();
        my $name = wrap($value);
        make create(TYPE<Q::Identifier>, :$name, :frame(NONE));
    }

    method argumentlist($/) {
        my $arguments = wrap($<EXPR>».ast);
        make create(TYPE<Q::ArgumentList>, :$arguments);
    }

    method parameterlist($/) {
        my $parameters = wrap($<parameter>».ast);
        make create(TYPE<Q::ParameterList>, :$parameters);
    }

    method parameter($/) {
        make create(TYPE<Q::Parameter>, :identifier($<identifier>.ast));
    }
}
