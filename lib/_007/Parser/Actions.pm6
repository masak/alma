use _007::Val;
use _007::Value;
use _007::Parser::Syntax;
use MONKEY-SEE-NO-EVAL;

class X::String::Newline is Exception {
    method message { "Found a newline inside a string literal" }
}

class X::PointyBlock::SinkContext is Exception {
    method message { "Pointy blocks cannot occur on the statement level" }
}

class X::Trait::Duplicate is Exception {
    has Str $.trait;

    method message { "Trait '$.trait' is used more than once" }
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

class X::Property::NotDeclared is Exception {
    has Str $.type;
    has Str $.property;

    method message { "The property '$.property' is not defined on type '$.type'" }
}

class X::Property::Required is Exception {
    has Str $.type;
    has Str $.property;

    method message { "The property '$.property' is required on type '$.type'" }
}

class X::Property::Duplicate is Exception {
    has Str $.property;

    method message { "The property '$.property' was declared more than once in a property list" }
}

class X::Export::Nothing is Exception {
    method message { "Nothing to export" }
}

class X::Assignment::ReadOnly is Exception {
    has Str $.declname;
    has Str $.symbol;

    method message { "Cannot assign to $.declname $.symbol" }
}

sub ast-if-any($submatch) {
    $submatch
        ?? $submatch.ast
        !! NONE;
}

class _007::Parser::Actions {
    sub finish-block($block) {
        $block.static-lexpad = get-dict-property($*runtime.current-frame, "pad");
        $*runtime.leave;
    }

    method TOP($/) {
        make $<compunit>.ast;
    }

    method compunit($/) {
        my $cu = make-q-compunit(make-q-block(
            make-q-parameterlist(),
            $<statementlist>.ast
        ));
        make $cu;
        finish-block($cu.block);
    }

    method statementlist($/) {
        make make-q-statementlist(make-array($<statement>».ast));
    }

    method statement:expr ($/) {
        if $<export> {
            # For now, we're just enforcing that there's a `my` at the far left, according to the
            # rules in https://github.com/masak/007/issues/404#issuecomment-432176865 -- we're
            # not actually doing anything with the information yet

            sub panicExportNothing() {
                die X::Export::Nothing.new;
            }

            multi enforce-leftmost-my(_007::Value $ where &is-q-term-my) {}     # everything's fine
            multi enforce-leftmost-my(_007::Value $ where &is-q-term) { panicExportNothing() }
            multi enforce-leftmost-my(_007::Value $ where &is-q-prefix) { panicExportNothing() }
            multi enforce-leftmost-my(_007::Value $postfix where &is-q-postfix) { enforce-leftmost-my($postfix.term) }
            multi enforce-leftmost-my(_007::Value $infix where &is-q-infix) { enforce-leftmost-my($infix.lhs) }

            enforce-leftmost-my($<EXPR>.ast);
        }

        # XXX: this is a special case for macros that have been expanded at the
        #      top level of an expression statement, but it could happen anywhere
        #      in the expression tree
        if is-q-block($<EXPR>.ast) {
            make make-q-statement-expr(make-q-postfix-call(
                make-q-identifier(make-str("postfix:()")),
                make-q-term-func(NONE, $<EXPR>.ast),
                make-q-argumentlist()
            ));
        }
        else {
            make make-q-statement-expr($<EXPR>.ast);
        }
    }

    method statement:block ($/) {
        die X::PointyBlock::SinkContext.new
            if $<pblock><parameterlist>;
        make make-q-statement-block($<pblock>.ast);
    }

    method statement:func-or-macro ($/) {
        my $identifier = $<identifier>.ast;
        my $name = $identifier.name;
        my $parameterlist = $<parameterlist>.ast;
        my $traitlist = $<traitlist>.ast;
        my $statementlist = $<blockoid>.ast;

        my $block = make-q-block($parameterlist, $statementlist);
        my $static-lexpad = get-dict-property($*runtime.current-frame, "pad");
        finish-block($block);

        my $outer-frame = $*runtime.current-frame;
        my $val;
        if $<routine> eq "func" {
            make make-q-statement-func($identifier, $traitlist, $block);
            $val = make-func($name, $parameterlist, $statementlist, $outer-frame, $static-lexpad);
        }
        elsif $<routine> eq "macro" {
            make make-q-statement-macro($identifier, $traitlist, $block);
            $val = make-macro($name, $parameterlist, $statementlist, $outer-frame, $static-lexpad);
        }
        else {
            die "Unknown routine type $<routine>"; # XXX: Turn this into an X:: exception
        }

        $*runtime.put-var($identifier, $val);

        $*parser.opscope.maybe-install($name, $<traitlist><trait>);
    }

    method statement:return ($/) {
        die X::ControlFlow::Return.new
            unless $*in-routine;
        my $expr = ast-if-any($<EXPR>);
        make make-q-statement-return($expr);
    }

    method statement:throw ($/) {
        my $expr = ast-if-any($<EXPR>);
        make make-q-statement-throw($expr);
    }

    method statement:next ($/) {
        die X::ControlFlow.new
            unless $*in-loop;
        make make-q-statement-next();
    }

    method statement:last ($/) {
        die X::ControlFlow.new
            unless $*in-loop;
        make make-q-statement-last();
    }

    method statement:if ($/) {
        my %parameters = $<xblock>.ast;
        %parameters<else> = ast-if-any($<else>);

        make make-q-statement-if(|%parameters);
    }

    method statement:for ($/) {
        make make-q-statement-for($<EXPR>.ast, $<pblock>.ast);
    }

    method statement:while ($/) {
        make make-q-statement-while($<EXPR>.ast, $<pblock>.ast);
    }

    method statement:BEGIN ($/) {
        my $statement = $<statement>.ast;
        make make-q-statement-begin($statement);
        $statement.run($*runtime);
    }

    method statement:class ($/) {
        my $identifier = $<identifier>.ast;
        my $block = $<block>.ast;
        make make-q-statement-class($block);
        my $val = Val::Type.of(EVAL qq[class :: \{
            method attributes \{ () \}
            method ^name(\$) \{ "{$identifier.name.native-value}" \}
        \}]);
        $*runtime.put-var($identifier, $val);
    }

    method traitlist($/) {
        my @traits = $<trait>».ast;
        if bag( @traits.map: *.identifier.name.native-value ).grep( *.value > 1 )[0] -> $p {
            my $trait = $p.key;
            die X::Trait::Duplicate.new(:$trait);
        }
        make make-q-traitlist(make-array(@traits));
    }

    method trait($/) {
        make make-q-trait($<identifier>.ast, $<EXPR>.ast);
    }

    method blockoid ($/) {
        make $<statementlist>.ast;
    }

    method block ($/) {
        my $block = make-q-block(
            make-q-parameterlist(),
            $<blockoid>.ast,
        );
        make $block;
        finish-block($block);
    }

    method pblock ($/) {
        if $<parameterlist> {
            my $block = make-q-block(
                $<parameterlist>.ast,
                $<blockoid>.ast,
            );
            make $block;
            finish-block($block);
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

    sub is-a-macro($q where &is-q, $qtype where &is-type, $identifier where &is-q-identifier) {
        is-instance($q, $qtype)
            && is-q-identifier($identifier)
            && is-macro(my $macro = $*runtime.maybe-get-var($identifier.name.native-value))
            && $macro;
    }

    sub expand($macro, @arguments, &unexpanded-callback:()) {
        my $expansion = $*runtime.call($macro, @arguments);

        if $*unexpanded {
            return &unexpanded-callback();
        }
        else {
            if is-q-statement($expansion) {
                $expansion = make-q-statementlist(make-array([$expansion]));
            }
            elsif $expansion === NONE {
                $expansion = make-q-statementlist();
            }

            if is-q-statementlist($expansion) {
                $*runtime.enter($*runtime.current-frame, make-dict(), $expansion);
                $expansion = make-q-block(
                    make-q-parameterlist(),
                    $expansion,
                );
                finish-block($expansion);

            }

            if is-q-block($expansion) {
                $expansion = make-q-expr-blockadapter($expansion);
            }

            check($expansion, $*runtime);
            return $expansion;
        }
    }

    sub create-of-type($obj, %slots) {
        _007::Value.new(:type($obj.type), :%slots);
    }

    method EXPR($/) {
        sub name($op) {
            $op.identifier.name.native-value;
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

        my @opstack;
        my @termstack = $<termish>[0].ast;
        sub REDUCE {
            my $t2 = @termstack.pop;
            my $infix = @opstack.pop;
            my $t1 = @termstack.pop;

            if is-q-unquote($infix) {
                @termstack.push(make-q-unquote-infix($infix.qtype, $infix.expr, $t1, $t2));
                return;
            }

            if my $macro = is-a-macro($infix, TYPE<Q.Infix>, $infix.identifier) {
                @termstack.push(expand($macro, [$t1, $t2],
                    -> { create-of-type($infix.type, { :lhs($t1), :rhs($t2), :identifier($infix.identifier) }) }));
            }
            else {
                @termstack.push(create-of-type($infix.type, { :lhs($t1), :rhs($t2), :identifier($infix.identifier) }));

                if is-q-infix-assignment($infix) && is-q-identifier($t1) {
                    my $frame = $*runtime.current-frame;
                    my $symbol = $t1.name.native-value;
                    if @*declstack[*-1]{$symbol} :!exists {
                        if $*runtime.maybe-get-var($symbol) {
                            die X::Assignment::ReadOnly.new(:declname("builtin"), :$symbol);
                        }
                        die X::Undeclared.new(:$symbol)
                    }
                    my $decltype = @*declstack[*-1]{$symbol};
                    my $declname = $decltype.^name.subst(/ .* '::'/, "").lc;
                    die X::Assignment::ReadOnly.new(:$declname, :$symbol)
                        unless $decltype.is-assignable;
                    %*assigned{$frame.WHICH ~ $symbol}++;
                }
            }
        }

        for $<infix>».ast Z $<termish>[1..*]».ast -> ($infix, $term) {
            while @opstack && (tighter(@opstack[*-1], $infix)
                || equal(@opstack[*-1], $infix) && left-associative($infix)) {
                REDUCE;
            }
            die X::Op::Nonassociative.new(
                :op1(@opstack[*-1].identifier.name.native-value),
                :op2($infix.identifier.name.native-value),
            )
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
            $op.identifier.name.native-value;
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

            if is-q-unquote($prefix) {
                make make-q-unquote-prefix($prefix.qtype, $prefix.expr, $/.ast);
                return;
            }

            if my $macro = is-a-macro($prefix, TYPE<Q.Prefix>, $prefix.identifier) {
                make expand($macro, [$/.ast],
                    -> { create-of-type($prefix.type, { :operand($/.ast), :identifier($prefix.identifier) }) });
            }
            else {
                make create-of-type($prefix.type, { :operand($/.ast), :identifier($prefix.identifier) });
            }
        }

        sub handle-postfix($/) {
            my $postfix = @postfixes.shift.ast;
            my $identifier = $postfix.identifier;
            if my $macro = is-a-macro($postfix, TYPE<Q.Postfix.Call>, $/.ast) {
                make expand($macro, get-all-array-elements($postfix.argumentlist.arguments),
                    -> { create-of-type($postfix.type, { :$identifier, :operand($/.ast), :argumentlist($postfix.argumentlist) }) });
            }
            elsif is-q-postfix-index($postfix) {
                make create-of-type($postfix.type, { :$identifier, :operand($/.ast), :index($postfix.index) });
            }
            elsif is-q-postfix-call($postfix) {
                make create-of-type($postfix.type, { :$identifier, :operand($/.ast), :argumentlist($postfix.argumentlist) });
            }
            elsif is-q-postfix-property($postfix) {
                make create-of-type($postfix.type, { :$identifier, :operand($/.ast), :property($postfix.property) });
            }
            else {
                if my $macro = is-a-macro($postfix, TYPE<Q.Postfix>, $identifier) {
                    make expand($macro, [$/.ast],
                        -> { create-of-type($postfix.type, { :$identifier, :operand($/.ast) }) });
                }
                else {
                    make expand($macro, [$/.ast],
                        -> { create-of-type($postfix.type, { :$identifier, :operand($/.ast) }) });
                }
                else {
                    make create-of-type($postfix.type, { :$identifier, :operand($/.ast) });
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
        my $identifier = make-q-term-identifier(make-str("prefix:$op"));
        make create-of-type($*parser.opscope.ops<prefix>{$op}, { :$identifier, :operand(NONE) });
    }

    method prefix-unquote($/) {
        make $<unquote>.ast;
    }

    method str($/) {
        sub check-for-newlines($s) {
            die X::String::Newline.new
                if $s ~~ /\n/;
        }(~$0);
        my $value = make-str((~$0).subst(q[\"], q["], :g).subst(q[\\\\], q[\\], :g));
        make make-q-literal-str($value);
    }

    method term:none ($/) {
        make make-q-literal-none();
    }

    method term:false ($/) {
        make make-q-literal-book(make-bool(False));
    }

    method term:true ($/) {
        make make-q-literal-bool(make-bool(True));
    }

    method term:int ($/) {
        make make-q-literal-int(make-int(+$/));
    }

    method term:str ($/) {
        make $<str>.ast;
    }

    method term:array ($/) {
        make make-q-term-array(make-array($<EXPR>».ast));
    }

    method term:parens ($/) {
        make $<EXPR>.ast;
    }

    method regex-part($/) {
        make make-regex-alternation($<regex-group>».ast);
    }

    method regex-group($/) {
        make make-q-regex-group($<regex-quantifier>».ast);
    }

    method regex-quantified($/) {
        given $<quantifier>.Str {
            when ''  { make $<regex-fragment>.ast }
            when '+'  { make make-q-regex-oneormore($<regex-fragment>.ast) }
            when '*'  { make make-q-regex-zeroormore($<regex-fragment>.ast) }
            when '?'  { make make-q-regex-zeroorone($<regex-fragment>.ast) }
            default { die 'Unrecognized regex quantifier '; }
        }
    }

    method regex-fragment:str ($/) {
        make make-q-regex-str($<str>.ast.value);
    }

    method regex-fragment:identifier ($/) {
        make make-q-regex-identifier($<term>.ast);
    }

    method regex-fragment:call ($/) {
        make make-q-regex-call($<identifier>.ast);
    }

    method regex-fragment:group ($/) {
        make $<regex-part>.ast;
    }

    method term:regex ($/) {
        make make-q-term-regex($<regex-part>.ast);
    }

    method term:identifier ($/) {
        my $name = $<identifier>.ast.name.native-value;
        if !$*runtime.declared($name) {
            my $frame = $*runtime.current-frame;
            $*parser.postpone: sub checking-postdeclared {
                my $value = $*runtime.maybe-get-var($name, $frame);
                die X::Macro::Postdeclared.new(:$name)
                    if is-macro($value);
                die X::Undeclared.new(:symbol($name))
                    unless is-func($value);
            };
        }
        make make-q-term-identifier($<identifier>.ast.name);
    }

    method term:block ($/) {
        make $<pblock>.ast;
    }

    method term:quasi ($/) {
        my $qtype = make-str(~($<qtype> // ""));

        if $<block> -> $block {
            # If the quasi consists of a block with a single expression statement, it's very
            # likely that what we want to inject is the expression, not the block.
            #
            # The exception to that heuristic is when we've explicitly specified `@ Q.Block`
            # on the quasi.
            #
            # This is not a "nice" solution, nor a comprehensive one. In the end it's connected
            # to the troubled musings in <https://github.com/masak/007/issues/7>, which aren't
            # completely solved yet.

            if $qtype.native-value eq "Q.Statement" {
                # XXX: make sure there's only one statement (suboptimal; should parse-error sooner)
                my $contents = get-array-element($block.ast.statementlist.statements, 0);
                make make-q-term-quasi($contents, $qtype);
                return;
            }
            elsif $qtype.native-value eq "Q.StatementList" {
                my $contents = $block.ast.statementlist;
                make make-q-term-quasi($contents, $qtype);
                return;
            }
            elsif $qtype.native-value ne "Q.Block"
                && is-q-block($block.ast)
                && get-array-length($block.ast.statementlist.statements) == 1
                && is-q-statement-expr(get-array-element($block.ast.statementlist.statements, 0)) {

                my $contents = get-array-element($block.ast.statementlist.statements, 0).expr;
                make make-q-term-quasi($contents, $qtype);
                return;
            }
        }

        die "Got something in a quasi that we didn't expect: {$/.keys}"    # should never happen
            if !$/.hash.keys.grep({ $_ ne "qtype" });

        my $contents = $/.hash.pairs.first({ .key ne "qtype" }).value.ast;
        make q-term-quasi($contents, $qtype);
    }

    method term:func ($/) {
        my $parameterlist = $<parameterlist>.ast;
        my $traitlist = $<traitlist>.ast;
        my $statementlist = $<blockoid>.ast;

        my $block = make-q-block($parameterlist, $statementlist);
        if $<identifier> {
            my $name = $<identifier>.ast.name;
            my $outer-frame = get-dict-property($*runtime.current-frame, "outer-frame");
            my $static-lexpad = get-dict-property($*runtime.current-frame, "pad");
            my $val = make-func($name, $parameterlist, $statementlist, $outer-frame, $static-lexpad);
            $*runtime.put-var($<identifier>.ast, $val);
        }
        finish-block($block);

        my $name = $<identifier>.ast.name;
        my $identifier = ast-if-any($<identifier>);
        make make-q-term-func($identifier, $traitlist, $block);
    }

    method unquote ($/) {
        my $qtype = TYPE<Q.Term>;
        if $<identifier> {
            for $<identifier>.list -> $fragment {
                my $identifier = ~$fragment;
                $qtype = $++
                    ?? $*runtime.property($qtype, $identifier)
                    !! $*runtime.get-var($identifier);
            }
        }
        make make-q-unquote($qtype, $<EXPR>.ast);
    }

    sub is-role($type) {
        my role R {};
        return $type.HOW ~~ R.HOW.WHAT;
    }

    method term:new-object ($/) {
        my $type;
        for $<identifier>.list -> $fragment {
            my $identifier = ~$fragment;
            $type = $++
                ?? $*runtime.property($type, $identifier)
                !! $*runtime.maybe-get-var($identifier);
        }
        my $type-obj = $type.type;
        my $name = $type-obj.^name.subst("::", ".", :g);

        if $type-obj !=== TYPE<Dict> && !is-type($type-obj) {
            if is-role($type-obj) {
                die X::Uninstantiable.new(:$name);
            }
            sub aname($attr) { $attr.name.substr(2) }
            my %known-properties = $type-obj === TYPE<Type>
                ?? (value => 1)
                !! $type-obj.attributes.map({ aname($_) => 1 });
            for get-all-array-elements($<propertylist>.ast.properties) -> $p {
                my $property = $p.key.native-value;
                die X::Property::NotDeclared.new(:type($name), :$property)
                    unless %known-properties{$property};
            }
            for %known-properties.keys -> $property {
                # If an attribute has an initializer, then we don't require that it be
                # passed, since it will get a sensible value anyway.
                next if $type-obj.^attributes.first({ .name.substr(2) eq $property }).build;

                die X::Property::Required.new(:type($name), :$property)
                    unless $property eq any(get-all-array-elements($<propertylist>.ast.properties)».key».native-value);
            }
        }

        make make-q-term-object($type, $<propertylist>.ast);
    }

    method term:dict ($/) {
        make make-q-term-dict($<propertylist>.ast);
    }

    method term:my ($/) {
        my $identifier = $<identifier>.ast;

        make make-q-term-my(make-q-term-identifier($identifier.name));

        $*parser.opscope.maybe-install($identifier.name, []);
    }

    method propertylist ($/) {
        my %seen;
        for $<property>».ast -> _007::Value $p where &is-q-property {
            my Str $property = $p.key.native-value;
            die X::Property::Duplicate.new(:$property)
                if %seen{$property}++;
        }

        make make-q-propertylist(make-array($<property>».ast));
    }

    method property:str-expr ($/) {
        make make-q-property($<str>.ast.value, $<value>.ast);
    }

    method property:identifier-expr ($/) {
        my $key = $<identifier>.ast.name;
        make make-q-property($key, $<value>.ast);
    }

    method property:identifier ($/) {
        self."term:identifier"($/);
        my $value = $/.ast;
        my $key = $value.name;
        make make-q-property($key, $value);
    }

    method property:method ($/) {
        my $block = make-q-block($<parameterlist>.ast, $<blockoid>.ast);
        my $name = $<identifier>.ast.name;
        my $identifier = make-q-identifier($name);
        make make-q-property($name, make-q-term-func($identifier, $block));
        finish-block($block);
    }

    method infix($/) {
        my $op = ~$/;
        my $identifier = make-q-term-identifier(make-str("infix:$op"));
        make create-of-type($*parser.opscope.ops<infix>{$op}, { :lhs(NONE), :rhs(NONE) });
    }

    method infix-unquote($/) {
        my $got = ~($<unquote><identifier>.join(".") // "Q.Term");
        die X::TypeCheck.new(:operation<parsing>, :$got, :expected(TYPE<Q.Infix>))
            unless $got eq "Q.Infix";

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
        my $identifier = make-q-term-identifier(make-str("postfix:$op"));
        # XXX: this can't stay hardcoded forever, but we don't have the machinery yet
        # to do these right enough
        if $<index> {
            make make-q-postfix-index($identifier, NONE, $<EXPR>.ast);
        }
        elsif $<call> {
            make make-q-postfix-index($identifier, NONE, $<argumentlist>.ast);
        }
        elsif $<prop> {
            make make-q-postfix-index($identifier, NONE, $<property>.ast);
        }
        else {
            make create-of-type($*parser.opscope.ops<postfix>{$op}, { :$identifier, :operand(NONE) });
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
        make make-q-identifier(make-str($value));
    }

    method argumentlist($/) {
        make make-q-argumentlist(make-array($<EXPR>».ast));
    }

    method parameterlist($/) {
        make make-q-parameterlist(make-array($<parameter>».ast));
    }

    method parameter($/) {
        my $identifier = $<identifier>.ast;
        my $name = $identifier.name;

        make make-q-parameter($identifier);

        $*parser.opscope.maybe-install($name, []);
    }
}

sub check(_007::Value $ast where &is-q, $runtime) is export {
    my %*assigned;
    handle($ast);

    # a bunch of nodes we don't care about descending into
    multi handle(_007::Value $ where &is-q-parameterlist) {}
    multi handle(_007::Value $ where &is-q-statement-return) {}
    multi handle(_007::Value $ where &is-q-statement-begin) {}
    multi handle(_007::Value $ where &is-q-literal) {}
    multi handle(_007::Value $ where &is-q-postfix) {}

    multi handle(_007::Value $statementlist where &is-q-statementlist) {
        for get-all-array-elements($statementlist.statements) -> $statement {
            handle($statement);
        }
    }

    multi handle(_007::Value $block where &is-q-statement-block) {
        $runtime.enter($runtime.current-frame, $block.block.static-lexpad, $block.block.statementlist);
        handle($block.block.statementlist);
        $block.block.static-lexpad = get-dict-property($runtime.current-frame, "pad");
        $runtime.leave();
    }

    multi handle(_007::Value $expr where &is-q-statement-expr) {
        handle($expr.expr);
    }

    multi handle(_007::Value $func where &is-q-statement-func) {
        my $outer-frame = $runtime.current-frame;
        my $name = $func.identifier.name;
        my $val = make-func($name, $func.block.parameterlist, $func.block.statementlist, $outer-frame);
        $runtime.enter($outer-frame, make-dict(), $func.block.statementlist, $val);
        handle($func.block);
        $runtime.leave();

        $runtime.declare-var($func.identifier, $val);
    }

    multi handle(_007::Value $macro where &is-q-statement-macro) {
        my $outer-frame = $runtime.current-frame;
        my $name = $macro.identifier.name;
        my $val = make-macro(
            $macro.identifier.name,
            $macro.block.parameterlist,
            $macro.block.statementlist,
            $outer-frame,
        );
        $runtime.enter($outer-frame, make-dict(), $macro.block.statementlist, $val);
        handle($macro.block);
        $runtime.leave();

        $runtime.declare-var($macro.identifier, $val);
    }

    multi handle(_007::Value $if where &is-q-statement-if) {
        handle($if.block);
    }

    multi handle(_007::Value $for where &is-q-statement-for) {
        handle($for.block);
    }

    multi handle(_007::Value $while where &is-q-statement-while) {
        handle($while.block);
    }

    multi handle(_007::Value $block where &is-q-block) {
        $runtime.enter($runtime.current-frame, make-dict(), make-q-statementlist());
        handle($block.parameterlist);
        handle($block.statementlist);
        $block.static-lexpad = get-dict-property($runtime.current-frame, "pad");
        $runtime.leave();
    }

    multi handle(_007::Value $object where &is-q-term-dict) {
        handle($object.propertylist);
    }

    multi handle(_007::Value $my where &is-q-term-my) {
        my $symbol = $my.identifier.name.native-value;
        my $block = $runtime.current-frame();
        die X::Redeclaration.new(:$symbol)
            if $runtime.declared-locally($symbol);
        die X::Redeclaration::Outer.new(:$symbol)
            if %*assigned{$block ~ $symbol};
        $runtime.declare-var($my.identifier);
    }

    multi handle(_007::Value $propertylist where &is-q-propertylist) {
        my %seen;
        for $propertylist.properties.elements -> $p where &is-q-property {
            my Str $property = $p.key.native-value;
            die X::Property::Duplicate.new(:$property)
                if %seen{$property}++;
        }
    }

    multi handle(_007::Value $infix where &is-q-infix) {
        handle($infix.lhs);
        handle($infix.rhs);
    }

    multi handle(_007::Value $blockadapter where &is-q-expr-blockadapter) {
        handle($blockadapter.block);
    }

    multi handle(_007::Value $call where &is-q-postfix-call) {
        handle($call.operand);
        for get-all-array-elements($call.argumentlist.arguments) -> $e {
            handle($e);
        }
    }

    multi handle(_007::Value $func where &is-q-term-func) {
        handle($func.block);
    }

    multi handle(_007::Value $ where &is-q-term) {}
}
