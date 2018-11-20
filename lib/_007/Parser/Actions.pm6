use _007::Val;
use _007::Q;
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

class _007::Parser::Actions {
    sub finish-block($block) {
        $block.static-lexpad = $*runtime.current-frame.properties<pad>;
        $*runtime.leave;
    }

    method TOP($/) {
        make $<compunit>.ast;
    }

    method compunit($/) {
        my $cu = Q::CompUnit.new(:block(Q::Block.new(
            :parameterlist(Q::ParameterList.new),
            :statementlist($<statementlist>.ast)
        )));
        make $cu;
        finish-block($cu.block);
    }

    method statementlist($/) {
        make Q::StatementList.new(:statements(Val::Array.new(:elements($<statement>».ast))));
    }

    method statement:expr ($/) {
        if $<export> {
            # For now, we're just enforcing that there's a `my` at the far left, according to the
            # rules in https://github.com/masak/007/issues/404#issuecomment-432176865 -- we're
            # not actually doing anything with the information yet

            sub panicExportNothing() {
                die X::Export::Nothing.new;
            }

            multi enforce-leftmost-my(Q::Term::My $) {}     # everything's fine
            multi enforce-leftmost-my(Q::Term $) { panicExportNothing() }
            multi enforce-leftmost-my(Q::Prefix $) { panicExportNothing() }
            multi enforce-leftmost-my(Q::Postfix $postfix) { enforce-leftmost-my($postfix.term) }
            multi enforce-leftmost-my(Q::Infix $infix) { enforce-leftmost-my($infix.lhs) }

            enforce-leftmost-my($<EXPR>.ast);
        }

        # XXX: this is a special case for macros that have been expanded at the
        #      top level of an expression statement, but it could happen anywhere
        #      in the expression tree
        if $<EXPR>.ast ~~ Q::Block {
            make Q::Statement::Expr.new(:expr(Q::Postfix::Call.new(
                :identifier(Q::Identifier.new(:name(Val::Str.new(:value("postfix:()"))))),
                :operand(Q::Term::Func.new(:identifier(NONE), :block($<EXPR>.ast))),
                :argumentlist(Q::ArgumentList.new)
            )));
        }
        else {
            make Q::Statement::Expr.new(:expr($<EXPR>.ast));
        }
    }

    method statement:block ($/) {
        die X::PointyBlock::SinkContext.new
            if $<pblock><parameterlist>;
        make Q::Statement::Block.new(:block($<pblock>.ast));
    }

    method statement:func-or-macro ($/) {
        my $identifier = $<identifier>.ast;
        my $name = $identifier.name;
        my $parameterlist = $<parameterlist>.ast;
        my $traitlist = $<traitlist>.ast;
        my $statementlist = $<blockoid>.ast;

        my $block = Q::Block.new(:$parameterlist, :$statementlist);
        my $static-lexpad = $*runtime.current-frame.properties<pad>;
        finish-block($block);

        my $outer-frame = $*runtime.current-frame;
        my $val;
        if $<routine> eq "func" {
            make Q::Statement::Func.new(:$identifier, :$traitlist, :$block);
            $val = Val::Func.new(:$name, :$parameterlist, :$statementlist, :$outer-frame, :$static-lexpad);
        }
        elsif $<routine> eq "macro" {
            make Q::Statement::Macro.new(:$identifier, :$traitlist, :$block);
            $val = Val::Macro.new(:$name, :$parameterlist, :$statementlist, :$outer-frame, :$static-lexpad);
        }
        else {
            die "Unknown routine type $<routine>"; # XXX: Turn this into an X:: exception
        }

        $identifier.put-value($val, $*runtime);

        $*parser.opscope.maybe-install($name, $<traitlist><trait>);
    }

    method statement:return ($/) {
        die X::ControlFlow::Return.new
            unless $*in_routine;
        make Q::Statement::Return.new(:expr($<EXPR> ?? $<EXPR>.ast !! NONE));
    }

    method statement:throw ($/) {
        make Q::Statement::Throw.new(:expr($<EXPR> ?? $<EXPR>.ast !! NONE));
    }

    method statement:if ($/) {
        my %parameters = $<xblock>.ast;
        %parameters<else> = $<else> :exists
            ?? $<else>.ast
            !! NONE;

        make Q::Statement::If.new(|%parameters);
    }

    method statement:for ($/) {
        make Q::Statement::For.new(|$<xblock>.ast);
    }

    method statement:while ($/) {
        make Q::Statement::While.new(|$<xblock>.ast);
    }

    method statement:BEGIN ($/) {
        my $block = $<block>.ast;
        make Q::Statement::BEGIN.new(:$block);
        $*runtime.run(Q::CompUnit.new(:$block));
    }

    method statement:class ($/) {
        my $identifier = $<identifier>.ast;
        my $block = $<block>.ast;
        make Q::Statement::Class.new(:$block);
        my $val = Val::Type.of(EVAL qq[class :: \{
            method attributes \{ () \}
            method ^name(\$) \{ "{$identifier.name.value}" \}
        \}]);
        $identifier.put-value($val, $*runtime);
    }

    method traitlist($/) {
        my @traits = $<trait>».ast;
        if bag( @traits.map: *.identifier.name.value ).grep( *.value > 1 )[0] -> $p {
            my $trait = $p.key;
            die X::Trait::Duplicate.new(:$trait);
        }
        make Q::TraitList.new(:traits(Val::Array.new(:elements(@traits))));
    }
    method trait($/) {
        make Q::Trait.new(:identifier($<identifier>.ast), :expr($<EXPR>.ast));
    }

    method blockoid ($/) {
        make $<statementlist>.ast;
    }
    method block ($/) {
        my $block = Q::Block.new(
            :parameterlist(Q::ParameterList.new),
            :statementlist($<blockoid>.ast));
        make $block;
        finish-block($block);
    }
    method pblock ($/) {
        if $<parameterlist> {
            my $block = Q::Block.new(
                :parameterlist($<parameterlist>.ast),
                :statementlist($<blockoid>.ast));
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

    sub is-macro($q, $qtype, $identifier) {
        $q ~~ $qtype
            && $identifier ~~ Q::Identifier
            && (my $macro = $*runtime.maybe-get-var($identifier.name.value)) ~~ Val::Macro
            && $macro;
    }

    sub expand($macro, @arguments, &unexpanded-callback:()) {
        my $expansion = $*runtime.call($macro, @arguments);

        if $*unexpanded {
            return &unexpanded-callback();
        }
        else {
            if $expansion ~~ Q::Statement {
                $expansion = Q::StatementList.new(:statements(Val::Array.new(:elements([$expansion]))));
            }
            elsif $expansion === NONE {
                $expansion = Q::StatementList.new(:statements(Val::Array.new(:elements([]))));
            }

            if $expansion ~~ Q::StatementList {
                $*runtime.enter($*runtime.current-frame, Val::Object.new, $expansion);
                $expansion = Q::Block.new(
                    :parameterlist(Q::ParameterList.new())
                    :statementlist($expansion));
                finish-block($expansion);

            }

            if $expansion ~~ Q::Block {
                $expansion = Q::Expr::BlockAdapter.new(:block($expansion));
            }

            check($expansion, $*runtime);
            return $expansion;
        }
    }

    method EXPR($/) {
        sub name($op) {
            $op.identifier.name.value;
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

            if $infix ~~ Q::Unquote {
                @termstack.push(Q::Unquote::Infix.new(:qtype($infix.qtype), :expr($infix.expr), :lhs($t1), :rhs($t2)));
                return;
            }

            if my $macro = is-macro($infix, Q::Infix, $infix.identifier) {
                @termstack.push(expand($macro, [$t1, $t2],
                    -> { $infix.new(:lhs($t1), :rhs($t2), :identifier($infix.identifier)) }));
            }
            else {
                @termstack.push($infix.new(:lhs($t1), :rhs($t2), :identifier($infix.identifier)));

                if $infix ~~ Q::Infix::Assignment && $t1 ~~ Q::Identifier {
                    my $frame = $*runtime.current-frame;
                    my $symbol = $t1.name.value;
                    die X::Undeclared.new(:$symbol)
                        unless @*declstack[*-1]{$symbol} :exists;
                    my $decltype = @*declstack[*-1]{$symbol};
                    my $declname = $decltype.^name.subst(/ .* '::'/, "").lc;
                    die X::Assignment::RO.new(:typename("$declname '$symbol'"))
                        unless $decltype.is-assignable;
                    %*assigned{$frame.id ~ $symbol}++;
                }
            }
        }

        for $<infix>».ast Z $<termish>[1..*]».ast -> ($infix, $term) {
            while @opstack && (tighter(@opstack[*-1], $infix)
                || equal(@opstack[*-1], $infix) && left-associative($infix)) {
                REDUCE;
            }
            die X::Op::Nonassociative.new(:op1(@opstack[*-1].identifier.name.value), :op2($infix.identifier.name.value))
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
            $op.identifier.name.value;
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

            if $prefix ~~ Q::Unquote {
                make Q::Unquote::Prefix.new(:qtype($prefix.qtype), :expr($prefix.expr), :operand($/.ast));
                return;
            }

            if my $macro = is-macro($prefix, Q::Prefix, $prefix.identifier) {
                make expand($macro, [$/.ast],
                    -> { $prefix.new(:operand($/.ast), :identifier($prefix.identifier)) });
            }
            else {
                make $prefix.new(:operand($/.ast), :identifier($prefix.identifier));
            }
        }

        sub handle-postfix($/) {
            my $postfix = @postfixes.shift.ast;
            my $identifier = $postfix.identifier;
            if my $macro = is-macro($postfix, Q::Postfix::Call, $/.ast) {
                # XXX: special case (because primitive); is there somewhere else we can define this logic?
                if $macro === $*runtime.lvalue-builtin {
                    make Q::Term::Object.new(
                        :type(Val::Type.of(Val::Location)),
                        :propertylist(Q::PropertyList.new())
                    );
                }
                else {
                    make expand($macro, $postfix.argumentlist.arguments.elements,
                        -> { $postfix.new(:$identifier, :operand($/.ast), :argumentlist($postfix.argumentlist)) });
                }
            }
            elsif $postfix ~~ Q::Postfix::Index {
                make $postfix.new(:$identifier, :operand($/.ast), :index($postfix.index));
            }
            elsif $postfix ~~ Q::Postfix::Call {
                make $postfix.new(:$identifier, :operand($/.ast), :argumentlist($postfix.argumentlist));
            }
            elsif $postfix ~~ Q::Postfix::Property {
                make $postfix.new(:$identifier, :operand($/.ast), :property($postfix.property));
            }
            else {
                if my $macro = is-macro($postfix, Q::Postfix, $identifier) {
                    make expand($macro, [$/.ast],
                        -> { $postfix.new(:$identifier, :operand($/.ast)) });
                }
                else {
                    make $postfix.new(:$identifier, :operand($/.ast));
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
        my $identifier = Q::Identifier.new(
            :name(Val::Str.new(:value("prefix:$op"))),
            :frame($*runtime.current-frame),
        );
        make $*parser.opscope.ops<prefix>{$op}.new(:$identifier, :operand(Val::NoneType));
    }

    method prefix-unquote($/) {
        make $<unquote>.ast;
    }

    method str($/) {
        sub check-for-newlines($s) {
            die X::String::Newline.new
                if $s ~~ /\n/;
        }(~$0);
        my $value = (~$0).subst(q[\"], q["], :g).subst(q[\\\\], q[\\], :g);
        $value = Val::Str.new(:$value);
        make Q::Literal::Str.new(:$value);
    }

    method term:none ($/) {
        make Q::Literal::None.new;
    }

    method term:false ($/) {
        make Q::Literal::Bool.new(:value(Val::Bool.new(:value(False))));
    }

    method term:true ($/) {
        make Q::Literal::Bool.new(:value(Val::Bool.new(:value(True))));
    }

    method term:int ($/) {
        make Q::Literal::Int.new(:value(Val::Int.new(:value(+$/))));
    }

    method term:str ($/) {
        make $<str>.ast;
    }

    method term:array ($/) {
        make Q::Term::Array.new(:elements(Val::Array.new(:elements($<EXPR>».ast))));
    }

    method term:tuple ($/) {
        if $<EXPR>.elems != 1 || $<commas>.elems == $<EXPR>.elems {
            make Q::Term::Tuple.new(:elements(Val::Tuple.new(:elements($<EXPR>».ast))));
        }
        else {
            make $<EXPR>[0].ast;
        }
    }

    method regex-part($/) {
        make Q::Regex::Alternation.new(:alternatives($<regex-group>».ast));
    }

    method regex-group($/) {
        make Q::Regex::Group.new(:fragments($<regex-quantified>».ast));
    }

    method regex-quantified($/) {
        given $<quantifier>.Str {
            when ''  { make $<regex-fragment>.ast }
            when '+'  { make Q::Regex::OneOrMore.new(:fragment($<regex-fragment>.ast)) }
            when '*'  { make Q::Regex::ZeroOrMore.new(:fragment($<regex-fragment>.ast)) }
            when '?'  { make Q::Regex::ZeroOrOne.new(:fragment($<regex-fragment>.ast)) }
            default { die 'Unrecognized regex quantifier '; }
        }
    }

    method regex-fragment:str ($/) {
        make Q::Regex::Str.new(:contents($<str>.ast.value));
    }

    method regex-fragment:identifier ($/) {
        make Q::Regex::Identifier.new(:identifier($<identifier>.ast));
    }

    method regex-fragment:call ($/) {
        make Q::Regex::Call.new(:identifier($<identifier>.ast));
    }

    method regex-fragment:group ($/) {
        make $<regex-part>.ast;
    }

    method term:regex ($/) {
        make Q::Term::Regex.new(:contents($<regex-part>.ast));
    }

    method term:identifier ($/) {
        make $<identifier>.ast;
        my $name = $<identifier>.ast.name.value;
        if !$*runtime.declared($name) {
            my $frame = $*runtime.current-frame;
            $*parser.postpone: sub checking-postdeclared {
                my $value = $*runtime.maybe-get-var($name, $frame);
                die X::Macro::Postdeclared.new(:$name)
                    if $value ~~ Val::Macro;
                die X::Undeclared.new(:symbol($name))
                    unless $value ~~ Val::Func;
            };
        }
    }

    method term:block ($/) {
        make $<pblock>.ast;
    }

    method term:quasi ($/) {
        my $qtype = Val::Str.new(:value(~($<qtype> // "")));

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

            if $qtype.value eq "Q.Statement" {
                # XXX: make sure there's only one statement (suboptimal; should parse-error sooner)
                my $contents = $block.ast.statementlist.statements.elements[0];
                make Q::Term::Quasi.new(:$contents, :$qtype);
                return;
            }
            elsif $qtype.value eq "Q.StatementList" {
                my $contents = $block.ast.statementlist;
                make Q::Term::Quasi.new(:$contents, :$qtype);
                return;
            }
            elsif $qtype.value ne "Q.Block"
                && $block.ast ~~ Q::Block
                && $block.ast.statementlist.statements.elements.elems == 1
                && $block.ast.statementlist.statements.elements[0] ~~ Q::Statement::Expr {

                my $contents = $block.ast.statementlist.statements.elements[0].expr;
                make Q::Term::Quasi.new(:$contents, :$qtype);
                return;
            }
        }

        die "Got something in a quasi that we didn't expect: {$/.keys}"    # should never happen
            if !$/.hash.keys.grep({ $_ ne "qtype" });

        my $contents = $/.hash.pairs.first({ .key ne "qtype" }).value.ast;
        make Q::Term::Quasi.new(:$contents, :$qtype);
    }

    method term:func ($/) {
        my $parameterlist = $<parameterlist>.ast;
        my $traitlist = $<traitlist>.ast;
        my $statementlist = $<blockoid>.ast;

        my $block = Q::Block.new(:$parameterlist, :$statementlist);
        if $<identifier> {
            my $name = $<identifier>.ast.name;
            my $outer-frame = $*runtime.current-frame.properties<outer-frame>;
            my $static-lexpad = $*runtime.current-frame.properties<pad>;
            my $val = Val::Func.new(:$name, :$parameterlist, :$statementlist, :$outer-frame, :$static-lexpad);
            $<identifier>.ast.put-value($val, $*runtime);
        }
        finish-block($block);

        my $name = $<identifier>.ast.name;
        my $identifier = $<identifier>
            ?? Q::Identifier.new(:$name)
            !! NONE;
        make Q::Term::Func.new(:$identifier, :$traitlist, :$block);
    }

    method unquote ($/) {
        my $qtype = Q::Term;
        if $<identifier> {
            for $<identifier>.list -> $fragment {
                my $identifier = ~$fragment;
                $qtype = $++
                    ?? $*runtime.property($qtype, $identifier)
                    !! $*runtime.get-var($identifier);
            }
        }
        make Q::Unquote.new(:$qtype, :expr($<EXPR>.ast));
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

        if $type-obj !=== Val::Object {
            if is-role($type-obj) {
                die X::Uninstantiable.new(:$name);
            }

            sub aname($attr) { $attr.name.substr(2) }
            my %known-properties = $type-obj.attributes.map({ aname($_) => 1 });
            for $<propertylist>.ast.properties.elements -> $p {
                my $property = $p.key.value;
                die X::Property::NotDeclared.new(:type($name), :$property)
                    unless %known-properties{$property};
            }
            for %known-properties.keys -> $property {
                # If an attribute has an initializer, then we don't require that it be
                # passed, since it will get a sensible value anyway.
                next if $type-obj.^attributes.first({ .name.substr(2) eq $property }).build;

                die X::Property::Required.new(:type($name), :$property)
                    unless $property eq any($<propertylist>.ast.properties.elements».key».value);
            }
        }

        make Q::Term::Object.new(:$type, :propertylist($<propertylist>.ast));
    }

    method term:object ($/) {
        make Q::Term::Object.new(
            :type(Val::Type.of(Val::Object)),
            :propertylist($<propertylist>.ast));
    }

    method term:my ($/) {
        my $identifier = $<identifier>.ast;
        my $name = $identifier.name;

        make Q::Term::My.new(:identifier($identifier));

        $*parser.opscope.maybe-install($name, []);
    }

    method propertylist ($/) {
        my %seen;
        for $<property>».ast -> Q::Property $p {
            my Str $property = $p.key.value;
            die X::Property::Duplicate.new(:$property)
                if %seen{$property}++;
        }

        make Q::PropertyList.new(:properties(Val::Array.new(:elements($<property>».ast))));
    }

    method property:str-expr ($/) {
        make Q::Property.new(:key($<str>.ast.value), :value($<value>.ast));
    }

    method property:identifier-expr ($/) {
        my $key = $<identifier>.ast.name;
        make Q::Property.new(:$key, :value($<value>.ast));
    }

    method property:identifier ($/) {
        my $key = $<identifier>.ast.name;
        make Q::Property.new(:$key, :value($<identifier>.ast));
    }

    method property:method ($/) {
        my $block = Q::Block.new(
            :parameterlist($<parameterlist>.ast),
            :statementlist($<blockoid>.ast));
        my $name = $<identifier>.ast.name;
        my $identifier = Q::Identifier.new(:$name);
        make Q::Property.new(:key($name), :value(
            Q::Term::Func.new(:$identifier, :$block)));
        finish-block($block);
    }

    method infix($/) {
        my $op = ~$/;
        my $identifier = Q::Identifier.new(
            :name(Val::Str.new(:value("infix:$op"))),
        );
        make $*parser.opscope.ops<infix>{$op}.new(:$identifier, :lhs(NONE), :rhs(NONE));
    }

    method infix-unquote($/) {
        my $got = ~($<unquote><identifier>.join(".") // "Q.Term");
        die X::TypeCheck.new(:operation<parsing>, :$got, :expected(Q::Infix))
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
        my $identifier = Q::Identifier.new(
            :name(Val::Str.new(:value("postfix:$op"))),
            :frame($*runtime.current-frame),
        );
        # XXX: this can't stay hardcoded forever, but we don't have the machinery yet
        # to do these right enough
        if $<index> {
            make Q::Postfix::Index.new(index => $<EXPR>.ast, :$identifier, :operand(NONE));
        }
        elsif $<call> {
            make Q::Postfix::Call.new(argumentlist => $<argumentlist>.ast, :$identifier, :operand(NONE));
        }
        elsif $<prop> {
            make Q::Postfix::Property.new(property => $<identifier>.ast, :$identifier, :operand(NONE));
        }
        else {
            make $*parser.opscope.ops<postfix>{$op}.new(:$identifier, :operand(NONE));
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
        make Q::Identifier.new(:name(Val::Str.new(:$value)));
    }

    method argumentlist($/) {
        make Q::ArgumentList.new(:arguments(Val::Array.new(:elements($<EXPR>».ast))));
    }

    method parameterlist($/) {
        make Q::ParameterList.new(:parameters(Val::Array.new(:elements($<parameter>».ast))));
    }

    method parameter($/) {
        my $identifier = $<identifier>.ast;
        my $name = $identifier.name;

        make Q::Parameter.new(:$identifier);

        $*parser.opscope.maybe-install($name, []);
    }
}

sub check(Q $ast, $runtime) is export {
    my %*assigned;
    handle($ast);

    # a bunch of nodes we don't care about descending into
    multi handle(Q::ParameterList $) {}
    multi handle(Q::Statement::Return $) {}
    multi handle(Q::Statement::BEGIN $) {}
    multi handle(Q::Literal $) {}
    multi handle(Q::Term $) {} # with two exceptions, see below
    multi handle(Q::Postfix $) {}

    multi handle(Q::StatementList $statementlist) {
        for $statementlist.statements.elements -> $statement {
            handle($statement);
        }
    }

    multi handle(Q::Statement::Block $block) {
        $runtime.enter($runtime.current-frame, $block.block.static-lexpad, $block.block.statementlist);
        handle($block.block.statementlist);
        $block.block.static-lexpad = $runtime.current-frame.properties<pad>;
        $runtime.leave();
    }

    multi handle(Q::Statement::Expr $expr) {
        handle($expr.expr);
    }

    multi handle(Q::Statement::Func $func) {
        my $outer-frame = $runtime.current-frame;
        my $name = $func.identifier.name;
        my $val = Val::Func.new(:$name,
            :parameterlist($func.block.parameterlist),
            :statementlist($func.block.statementlist),
            :$outer-frame
        );
        $runtime.enter($outer-frame, Val::Object.new, $func.block.statementlist, $val);
        handle($func.block);
        $runtime.leave();

        $runtime.declare-var($func.identifier, $val);
    }

    multi handle(Q::Statement::Macro $macro) {
        my $outer-frame = $runtime.current-frame;
        my $name = $macro.identifier.name;
        my $val = Val::Macro.new(:$name,
            :parameterlist($macro.block.parameterlist),
            :statementlist($macro.block.statementlist),
            :$outer-frame
        );
        $runtime.enter($outer-frame, Val::Object.new, $macro.block.statementlist, $val);
        handle($macro.block);
        $runtime.leave();

        $runtime.declare-var($macro.identifier, $val);
    }

    multi handle(Q::Statement::If $if) {
        handle($if.block);
    }

    multi handle(Q::Statement::For $for) {
        handle($for.block);
    }

    multi handle(Q::Statement::While $while) {
        handle($while.block);
    }

    multi handle(Q::Block $block) {
        $runtime.enter($runtime.current-frame, Val::Object.new, Q::StatementList.new);
        handle($block.parameterlist);
        handle($block.statementlist);
        $block.static-lexpad = $runtime.current-frame.properties<pad>;
        $runtime.leave();
    }

    multi handle(Q::Term::Object $object) {
        handle($object.propertylist);
    }

    multi handle(Q::Term::My $my) {
        my $symbol = $my.identifier.name.value;
        my $block = $runtime.current-frame();
        die X::Redeclaration.new(:$symbol)
            if $runtime.declared-locally($symbol);
        die X::Redeclaration::Outer.new(:$symbol)
            if %*assigned{$block ~ $symbol};
        $runtime.declare-var($my.identifier);
    }

    multi handle(Q::PropertyList $propertylist) {
        my %seen;
        for $propertylist.properties.elements -> Q::Property $p {
            my Str $property = $p.key.value;
            die X::Property::Duplicate.new(:$property)
                if %seen{$property}++;
        }
    }

    multi handle(Q::Infix $infix) {
        handle($infix.lhs);
        handle($infix.rhs);
    }

    multi handle(Q::Expr::BlockAdapter $blockadapter) {
        handle($blockadapter.block);
    }

    multi handle(Q::Postfix::Call $call) {
        handle($call.operand);
        for $call.argumentlist.arguments.elements.list -> $e {
            handle($e);
        }
    }

    multi handle(Q::Term::Func $func) {
        handle($func.block);
    }

    multi handle(Q::Prefix $prefix) {
        handle($prefix.operand);
    }
}
