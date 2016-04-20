use _007::Q;
use _007::Parser::Syntax;
use _007::Parser::Exceptions;

class _007::Parser::Actions {
    method finish-block($block) {
        $block.static-lexpad = $*runtime.current-frame.pad;
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
        self.finish-block($cu.block);
    }

    method statementlist($/) {
        make Q::StatementList.new(:statements(Val::Array.new(:elements($<statement>».ast))));
    }

    method statement:my ($/) {
        make Q::Statement::My.new(
            :identifier($<identifier>.ast),
            :expr($<EXPR> ?? $<EXPR>.ast !! Val::None.new));
    }

    method statement:constant ($/) {
        die X::Syntax::Missing.new(:what("initializer on constant declaration"))
            unless $<EXPR>;

        make Q::Statement::Constant.new(
            :identifier($<identifier>.ast),
            :expr($<EXPR>.ast));

        my $value = $<EXPR>.ast.eval($*runtime);
        $<identifier>.ast.put-value($value, $*runtime);
    }

    method statement:expr ($/) {
        # XXX: this is a special case for macros that have been expanded at the
        #      top level of an expression statement, but it could happen anywhere
        #      in the expression tree
        if $<EXPR>.ast ~~ Q::Block {
            make Q::Statement::Expr.new(:expr(Q::Postfix::Call.new(
                :operand($<EXPR>.ast),
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

    sub maybe-install-operator($identname, @trait) {
        return
            unless $identname ~~ / (< prefix infix postfix >)
                                    ':<' (<-[>]>+) '>' /;

        my $type = ~$0;
        my $op = ~$1;

        my %precedence;
        my @prec-traits = <equal looser tighter>;
        my $assoc;
        for @trait -> $trait {
            my $name = $trait<identifier>.ast.name;
            if $name eq any @prec-traits {
                my $identifier = $trait<EXPR>.ast;
                my $prep = $name eq "equal" ?? "to" !! "than";
                die "The thing your op is $name $prep must be an identifier"
                    unless $identifier ~~ Q::Identifier;
                sub check-if-op($s) {
                    die "Unknown thing in '$name' trait"
                        unless $s ~~ /< pre in post > 'fix:<' (<-[>]>+) '>'/;
                    %precedence{$name} = ~$0;
                    die X::Precedence::Incompatible.new
                        if $type eq ('prefix' | 'postfix') && $s ~~ /^ in/
                        || $type eq 'infix' && $s ~~ /^ < pre post >/;
                }($identifier.name);
            }
            elsif $name eq "assoc" {
                my $string = $trait<EXPR>.ast;
                die "The associativity must be a string"
                    unless $string ~~ Q::Literal::Str;
                my $value = $string.value.value;
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

        $*parser.oplevel.install($type, $op, :%precedence, :$assoc);
    }

    method statement:sub-or-macro ($/) {
        my $identifier = $<identifier>.ast;
        my $name = ~$<identifier>;
        my $parameterlist = $<parameterlist>.ast;
        my $traitlist = $<traitlist>.ast;
        my $statementlist = $<blockoid>.ast;

        my $block = Q::Block.new(:$parameterlist, :$statementlist);
        my %static-lexpad = $*runtime.current-frame.pad;
        self.finish-block($block);

        my $outer-frame = $*runtime.current-frame;
        my $val;
        if $<routine> eq "sub" {
            make Q::Statement::Sub.new(:$identifier, :$traitlist, :$block);
            $val = Val::Sub.new(:$name, :$parameterlist, :$statementlist, :$outer-frame, :%static-lexpad);
        }
        elsif $<routine> eq "macro" {
            make Q::Statement::Macro.new(:$identifier, :$traitlist, :$block);
            $val = Val::Macro.new(:$name, :$parameterlist, :$statementlist, :$outer-frame, :%static-lexpad);
        }
        else {
            die "Unknown routine type $<routine>"; # XXX: Turn this into an X:: exception
        }

        $identifier.put-value($val, $*runtime);

        maybe-install-operator($name, $<traitlist><trait>);
    }

    method statement:return ($/) {
        make Q::Statement::Return.new(:expr($<EXPR> ?? $<EXPR>.ast !! Val::None.new));
    }

    method statement:throw ($/) {
        make Q::Statement::Throw.new(:expr($<EXPR> ?? $<EXPR>.ast !! Val::None.new));
    }

    method statement:if ($/) {
        my %parameters = $<xblock>.ast;
        %parameters<else> = $<else> :exists
            ?? $<else>.ast
            !! Val::None.new;

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
        self.finish-block($block);
    }
    method pblock ($/) {
        if $<parameterlist> {
            my $block = Q::Block.new(
                :parameterlist($<parameterlist>.ast),
                :statementlist($<blockoid>.ast));
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

    method EXPR($/) {
        sub name($op) {
            $op.identifier.name.value.subst(/^ \w+ ":<"/, "").subst(/">" $/, "");
        }

        sub tighter($op1, $op2, $_ = $*parser.oplevel.infixprec) {
            .first(*.contains(name($op1)), :k) > .first(*.contains(name($op2)), :k);
        }

        sub equal($op1, $op2, $_ = $*parser.oplevel.infixprec) {
            .first(*.contains(name($op1)), :k) == .first(*.contains(name($op2)), :k);
        }

        sub left-associative($op) {
            return $*parser.oplevel.infixprec.first(*.contains(name($op))).assoc eq "left";
        }

        sub non-associative($op) {
            return $*parser.oplevel.infixprec.first(*.contains(name($op))).assoc eq "non";
        }

        my @opstack;
        my @termstack = $<termish>[0].ast;
        sub REDUCE {
            my $t2 = @termstack.pop;
            my $infix = @opstack.pop;
            my $t1 = @termstack.pop;

            if $infix ~~ Q::Unquote {
                @termstack.push(Q::Unquote::Infix.new(:expr($infix.expr), :lhs($t1), :rhs($t2)));
                return;
            }

            my $c = $*runtime.maybe-get-var($infix.identifier.name.value);
            if $c ~~ Val::Macro {
                my $expansion = $*runtime.call($c, [$t1, $t2]);
                if $*unexpanded {
                    @termstack.push($infix.new(:lhs($t1), :rhs($t2), :identifier($infix.identifier)));
                }
                else {
                    @termstack.push($expansion);
                }
            }
            else {
                @termstack.push($infix.new(:lhs($t1), :rhs($t2), :identifier($infix.identifier)));

                if $infix ~~ Q::Infix::Assignment && $t1 ~~ Q::Identifier {
                    my $block = $*runtime.current-frame();
                    my $symbol = $t1.name.value;
                    die X::Undeclared.new(:$symbol)
                        unless @*declstack[*-1]{$symbol} :exists;
                    my $decltype = @*declstack[*-1]{$symbol};
                    my $declname = $decltype.^name.subst(/ .* '::'/, "").lc;
                    die X::Assignment::RO.new(:typename("$declname '$symbol'"))
                        unless $decltype.is-assignable;
                    %*assigned{$block ~ $symbol}++;
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
            $op.identifier.name.value.subst(/^ \w+ ":<"/, "").subst(/">" $/, "");
        }

        sub tighter($op1, $op2, $_ = $*parser.oplevel.prepostfixprec) {
            .first(*.contains(name($op1)), :k) > .first(*.contains(name($op2)), :k);
        }

        sub equal($op1, $op2, $_ = $*parser.oplevel.prepostfixprec) {
            .first(*.contains(name($op1)), :k) == .first(*.contains(name($op2)), :k);
        }

        sub left-associative($op) {
            return $*parser.oplevel.prepostfixprec.first(*.contains(name($op))).assoc eq "left";
        }

        sub non-associative($op) {
            return $*parser.oplevel.prepostfixprec.first(*.contains(name($op))).assoc eq "non";
        }

        make $<term>.ast;

        my @prefixes = @<prefix>.reverse;   # evaluated inside-out
        my @postfixes = @<postfix>;

        sub handle-prefix($/) {
            my $prefix = @prefixes.shift.ast;

            if $prefix ~~ Q::Unquote {
                make Q::Unquote::Prefix.new(:expr($prefix.expr), :operand($/.ast));
                return;
            }

            my $c = $*runtime.maybe-get-var($prefix.identifier.name.value);
            if $c ~~ Val::Macro {
                my $expansion = $*runtime.call($c, [$/.ast]);
                if $*unexpanded {
                    make $prefix.new(:operand($/.ast), :identifier($prefix.identifier));
                }
                else {
                    make $expansion;
                }
            }
            else {
                make $prefix.new(:operand($/.ast), :identifier($prefix.identifier));
            }
        }

        sub handle-postfix($/) {
            my $postfix = @postfixes.shift.ast;
            my $identifier = $postfix.identifier;
            # XXX: factor the logic that checks for macro call out into its own helper sub
            if $postfix ~~ Q::Postfix::Call
            && $/.ast ~~ Q::Identifier
            && (my $macro = $*runtime.maybe-get-var($/.ast.name.value)) ~~ Val::Macro {
                my @arguments = $postfix.argumentlist.arguments.elements;
                my $expansion = $*runtime.call($macro, @arguments);

                if $expansion ~~ Q::Statement::My {
                    _007::Parser::Syntax::declare(Q::Statement::My, ~$expansion.identifier.name);
                }

                if $*unexpanded {
                    make $postfix.new(:$identifier, :operand($/.ast), :argumentlist($postfix.argumentlist));
                }
                elsif $expansion ~~ Q::Statement {
                    make Q::Expr::StatementListAdapter.new(
                        :statementlist(Q::StatementList.new(
                            :statements(Val::Array.new(:elements([$expansion])))
                        ))
                    );
                }
                else {
                    make $expansion;
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
                my $c = $*runtime.maybe-get-var($postfix.identifier.name.value);
                if $c ~~ Val::Macro {
                    my $expansion = $*runtime.call($c, [$/.ast]);
                    if $*unexpanded {
                        make $postfix.new(:$identifier, :operand($/.ast));
                    }
                    else {
                        make $expansion;
                    }
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
                die X::Op::Nonassociative.new(:op1($prefix.identifier.name.value), :op2($postfix.identifier.name.value))
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
            :name(Val::Str.new(:value("prefix:<$op>"))),
            :frame($*runtime.current-frame),
        );
        make $*parser.oplevel.ops<prefix>{$op}.new(:$identifier, :operand(Val::None));
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

    method term:int ($/) {
        make Q::Literal::Int.new(:value(Val::Int.new(:value(+$/))));
    }

    method term:str ($/) {
        make $<str>.ast;
    }

    method term:array ($/) {
        make Q::Term::Array.new(:elements(Val::Array.new(:elements($<EXPR>».ast))));
    }

    method term:parens ($/) {
        make $<EXPR>.ast;
    }

    method term:identifier ($/) {
        make $<identifier>.ast;
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

            if $qtype.value ne "Q::Block"
                && $block.ast ~~ Q::Block
                && $block.ast.statementlist.statements.elements.elems == 1
                && $block.ast.statementlist.statements.elements[0] ~~ Q::Statement::Expr {

                my $contents = $block.ast.statementlist.statements.elements[0].expr;
                make Q::Term::Quasi.new(:$contents, :$qtype);
                return;
            }
        }

        for <argumentlist block compunit EXPR infix parameter parameterlist
            postfix prefix property propertylist statement statementlist
            term trait traitlist unquote> -> $subrule {

            if $/{$subrule} -> $submatch {
                make Q::Term::Quasi.new(:contents($submatch.ast), :$qtype);
                return;
            }
        }

        die "Got something in a quasi that we didn't expect: {$/.keys}";   # should never happen
    }

    method term:sub ($/) {
        my $parameterlist = $<parameterlist>.ast;
        my $traitlist = $<traitlist>.ast;
        my $statementlist = $<blockoid>.ast;

        my $block = Q::Block.new(:$parameterlist, :$statementlist);
        if $<identifier> {
            my $name = ~$<identifier>;
            my $outer-frame = $*runtime.current-frame;  # XXX: this is not really the outer frame, is it?
            my %static-lexpad = $*runtime.current-frame.pad;
            my $val = Val::Sub.new(:$name, :$parameterlist, :$statementlist, :$outer-frame, :%static-lexpad);
            $<identifier>.ast.put-value($val, $*runtime);
        }
        self.finish-block($block);

        my $identifier = $<identifier>
            ?? Q::Identifier.new(:name(Val::Str.new(:value(~$<identifier>))))
            !! Val::None.new;
        make Q::Term::Sub.new(:$identifier, :$traitlist, :$block);
    }

    method unquote ($/) {
        make Q::Unquote.new(:expr($<EXPR>.ast));
    }

    method term:object ($/) {
        my $type = ~($<identifier> // "Object");
        my $type-obj = $*runtime.get-var($type).type;

        if $type-obj !=== Val::Object {
            sub aname($attr) { $attr.name.substr(2) }
            my %known-properties = $type-obj.attributes.map({ aname($_) => 1 });
            for $<propertylist>.ast.properties.elements -> $p {
                my $property = $p.key.value;
                die X::Property::NotDeclared.new(:$type, :$property)
                    unless %known-properties{$property};
            }
            for %known-properties.keys -> $property {
                # If an attribute has an initializer, then we don't require that it be
                # passed, since it will get a sensible value anyway.
                next if $type-obj.^attributes.first({ .name.substr(2) eq $property }).build;

                die X::Property::Required.new(:$type, :$property)
                    unless $property eq any($<propertylist>.ast.properties.elements».key».value);
            }
        }

        make Q::Term::Object.new(
            :type(Q::Identifier.new(:name(Val::Str.new(:value($type))))),
            :propertylist($<propertylist>.ast));
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
        make Q::Property.new(:key(Val::Str.new(:value(~$<identifier>))), :value($<value>.ast));
    }

    method property:identifier ($/) {
        make Q::Property.new(:key(Val::Str.new(:value(~$<identifier>))), :value($<identifier>.ast));
    }

    method property:method ($/) {
        my $block = Q::Block.new(
            :parameterlist($<parameterlist>.ast),
            :statementlist($<blockoid>.ast));
        my $name = Val::Str.new(:value(~$<identifier>));
        my $identifier = Q::Identifier.new(:$name);
        make Q::Property.new(:key($name), :value(
            Q::Term::Sub.new(:$identifier, :$block)));
        self.finish-block($block);
    }

    method infix($/) {
        my $op = ~$/;
        my $identifier = Q::Identifier.new(
            :name(Val::Str.new(:value("infix:<$op>"))),
            :frame($*runtime.current-frame),
        );
        make $*parser.oplevel.ops<infix>{$op}.new(:$identifier, :lhs(Val::None.new), :rhs(Val::None.new));
    }

    method infix-unquote($/) {
        my $got = ~($<unquote><identifier> // "Q::Term");
        die X::TypeCheck.new(:operation<parsing>, :$got, :expected(Q::Infix))
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
        my $identifier = Q::Identifier.new(
            :name(Val::Str.new(:value("postfix:<$op>"))),
            :frame($*runtime.current-frame),
        );
        # XXX: this can't stay hardcoded forever, but we don't have the machinery yet
        # to do these right enough
        if $<index> {
            make Q::Postfix::Index.new(index => $<EXPR>.ast, :$identifier, :operand(Val::None.new));
        }
        elsif $<call> {
            make Q::Postfix::Call.new(argumentlist => $<argumentlist>.ast, :$identifier, :operand(Val::None.new));
        }
        elsif $<prop> {
            make Q::Postfix::Property.new(property => $<identifier>.ast, :$identifier, :operand(Val::None.new));
        }
        else {
            make $*parser.oplevel.ops<postfix>{$op}.new(:$identifier, :operand(Val::None.new));
        }
    }

    method identifier($/) {
        make Q::Identifier.new(:name(Val::Str.new(:value(~$/))));
    }

    method argumentlist($/) {
        make Q::ArgumentList.new(:arguments(Val::Array.new(:elements($<EXPR>».ast))));
    }

    method parameterlist($/) {
        make Q::ParameterList.new(:parameters(Val::Array.new(:elements($<parameter>».ast))));
    }

    method parameter($/) {
        make Q::Parameter.new(:identifier($<identifier>.ast));
    }
}
