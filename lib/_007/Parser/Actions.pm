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
        my $block = TYPE<Q::Block>.create(
            :parameterlist(TYPE<Q::ParameterList>.create(
                :parameters(empty-array()),
            )),
            :statementlist($<statementlist>.ast),
            :static-lexpad(empty-dict()),
        );
        make TYPE<Q::CompUnit>.create(:$block);
        self.finish-block($block);
    }

    method statementlist($/) {
        my $statements = wrap($<statement>».ast);
        make TYPE<Q::StatementList>.create(:$statements);
    }

    method statement:my ($/) {
        make TYPE<Q::Statement::My>.create(
            :identifier($<identifier>.ast),
            :expr($<EXPR> ?? $<EXPR>.ast !! NONE));
    }

    method statement:constant ($/) {
        die X::Syntax::Missing.new(:what("initializer on constant declaration"))
            unless $<EXPR>;

        make TYPE<Q::Statement::Constant>.create(
            :identifier($<identifier>.ast),
            :expr($<EXPR>.ast));

        my $value = bound-method($<EXPR>.ast, "eval")($*runtime);
        bound-method($<identifier>.ast, "put-value")($value, $*runtime);
    }

    method statement:expr ($/) {
        # XXX: this is a special case for macros that have been expanded at the
        #      top level of an expression statement, but it could happen anywhere
        #      in the expression tree
        if $<EXPR>.ast.isa("Q::Block") {
            make TYPE<Q::Statement::Expr>.create(:expr(TYPE<Q::Postfix::Call>.create(
                :identifier(TYPE<Q::Identifier>.create(:name(wrap("postfix:()")))),
                :operand(TYPE<Q::Term::Sub>.create(:identifier(NONE), :block($<EXPR>.ast))),
                :argumentlist(TYPE<Q::ArgumentList>.create())
            )));
        }
        else {
            make TYPE<Q::Statement::Expr>.create(:expr($<EXPR>.ast));
        }
    }

    method statement:block ($/) {
        die X::PointyBlock::SinkContext.new
            if $<pblock><parameterlist>;
        make TYPE<Q::Statement::Block>.create(:block($<pblock>.ast));
    }

    sub maybe-install-operator($identname, @trait) {
        return
            unless $identname ~~ /^ (< prefix infix postfix >)
                                    ':' (.+) /;

        my $type = ~$0;
        my $op = ~$1;

        my %precedence;
        my @prec-traits = <equal looser tighter>;
        my $assoc;
        for @trait -> $trait {
            my $name = $trait<identifier>.ast.properties<name>;
            if $name eq any @prec-traits {
                my $identifier = $trait<EXPR>.ast;
                my $prep = $name eq "equal" ?? "to" !! "than";
                die "The thing your op is $name $prep must be an identifier"
                    unless $identifier.isa("Q::Identifier");
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
                    unless $string.isa("Q::Literal::Str");
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

        my $block = TYPE<Q::Block>.create(
            :$parameterlist,
            :$statementlist,
            :static-lexpad(empty-dict()),
        );
        my $static-lexpad = $*runtime.current-frame.value<pad>;
        self.finish-block($block);

        my $outer-frame = $*runtime.current-frame;
        my $val;
        if $<routine> eq "sub" {
            make TYPE<Q::Statement::Sub>.create(:$identifier, :$traitlist, :$block);
            $val = TYPE<Sub>.create(:$name, :$parameterlist, :$statementlist, :$outer-frame, :$static-lexpad);
        }
        elsif $<routine> eq "macro" {
            make TYPE<Q::Statement::Macro>.create(:$identifier, :$traitlist, :$block);
            $val = TYPE<Macro>.create(:$name, :$parameterlist, :$statementlist, :$outer-frame, :$static-lexpad);
        }
        else {
            die "Unknown routine type $<routine>"; # XXX: Turn this into an X:: exception
        }

        bound-method($identifier, "put-value")($val, $*runtime);

        maybe-install-operator($name, $<traitlist><trait>);
    }

    method statement:return ($/) {
        die X::ControlFlow::Return.new
            unless $*insub;
        make TYPE<Q::Statement::Return>.create(:expr($<EXPR> ?? $<EXPR>.ast !! NONE));
    }

    method statement:throw ($/) {
        make TYPE<Q::Statement::Throw>.create(:expr($<EXPR> ?? $<EXPR>.ast !! NONE));
    }

    method statement:if ($/) {
        my %parameters = $<xblock>.ast;
        %parameters<else> = $<else> :exists
            ?? $<else>.ast
            !! NONE;

        make TYPE<Q::Statement::If>.create(|%parameters);
    }

    method statement:for ($/) {
        make TYPE<Q::Statement::For>.create(|$<xblock>.ast);
    }

    method statement:while ($/) {
        make TYPE<Q::Statement::While>.create(|$<xblock>.ast);
    }

    method statement:BEGIN ($/) {
        my $block = $<block>.ast;
        make TYPE<Q::Statement::BEGIN>.create(:$block);
        $*runtime.run(TYPE<Q::CompUnit>.create(:$block));
    }

    method statement:class ($/) {
        my $identifier = $<identifier>.ast;
        my $block = $<block>.ast;
        make TYPE<Q::Statement::Class>.create(:$block);
        my $val = Val::Type.of(EVAL qq[class :: \{
            method attributes \{ () \}
            method ^name(\$) \{ "{$identifier.properties<name>.value}" \}
        \}]);
        bound-method($identifier, "put-value")($val, $*runtime);
    }

    method traitlist($/) {
        my @traits = $<trait>».ast;
        if bag( @traits.map: *.properties<identifier>.properties<name>.value ).grep( *.value > 1 )[0] -> $p {
            my $trait = $p.key;
            die X::Trait::Duplicate.new(:$trait);
        }
        my $traits = wrap(@traits);
        make TYPE<Q::TraitList>.create(:$traits);
    }
    method trait($/) {
        make TYPE<Q::Trait>.create(:identifier($<identifier>.ast), :expr($<EXPR>.ast));
    }

    method blockoid ($/) {
        make $<statementlist>.ast;
    }
    method block ($/) {
        my $block = TYPE<Q::Block>.create(
            :parameterlist(TYPE<Q::ParameterList>.create(
                :parameters(empty-array()),
            )),
            :statementlist($<blockoid>.ast)
            :static-lexpad(NONE));
        make $block;
        self.finish-block($block);
    }
    method pblock ($/) {
        if $<parameterlist> {
            my $block = TYPE<Q::Block>.create(
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
        $q.isa($qtype)
            && $identifier.isa("Q::Identifier")
            && (my $macro = $*runtime.maybe-get-var($identifier.properties<name>.value)) ~~ _007::Object
            && $macro.isa("Macro")
            && $macro;
    }

    sub expand($macro, @arguments, &unexpanded-callback:()) {
        my $expansion = internal-call($macro, $*runtime, @arguments);

        if $expansion.isa("Q::Statement::My") {
            _007::Parser::Syntax::declare(TYPE<Q::Statement::My>, $expansion.properties<identifier>.properties<name>.value);
        }

        if $*unexpanded {
            return &unexpanded-callback();
        }
        else {
            if $expansion.isa("Q::Statement") {
                my $statements = wrap([$expansion]);
                $expansion = TYPE<Q::StatementList>.create(:$statements);
            }
            elsif $expansion === NONE {
                my $statements = wrap([]);
                $expansion = TYPE<Q::StatementList>.create(:$statements);
            }

            if $expansion.isa("Q::StatementList") {
                $expansion = TYPE<Q::Expr::StatementListAdapter>.create(:statementlist($expansion));
            }

            if $expansion.isa("Q::Block") {
                $expansion = TYPE<Q::Expr::StatementListAdapter>.create(:statementlist($expansion.properties<statementlist>));
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

            if $infix.isa("Q::Unquote") {
                @termstack.push(TYPE<Q::Unquote::Infix>.create(
                    :qtype($infix.properties<qtype>),
                    :expr($infix.properties<expr>),
                    :lhs($t1),
                    :rhs($t2),
                ));
                return;
            }

            if my $macro = is-macro($infix, TYPE<Q::Infix>, $infix.properties<identifier>) {
                @termstack.push(expand($macro, [$t1, $t2],
                    -> { $infix.type.create(:lhs($t1), :rhs($t2), :identifier($infix.properties<identifier>)) }));
            }
            else {
                @termstack.push($infix.type.create(:lhs($t1), :rhs($t2), :identifier($infix.properties<identifier>)));

                if $infix.isa("Q::Infix::Assignment") && $t1.isa("Q::Identifier") {
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

            if $prefix.isa("Q::Unquote") {
                make TYPE<Q::Unquote::Prefix>.create(
                    :qtype($prefix.properties<qtype>),
                    :expr($prefix.properties<expr>),
                    :operand($/.ast),
                );
                return;
            }

            if my $macro = is-macro($prefix, TYPE<Q::Prefix>, $prefix.properties<identifier>) {
                make expand($macro, [$/.ast],
                    -> { $prefix.type.create(:operand($/.ast), :identifier($prefix.properties<identifier>)) });
            }
            else {
                make $prefix.type.create(:operand($/.ast), :identifier($prefix.properties<identifier>));
            }
        }

        sub handle-postfix($/) {
            my $postfix = @postfixes.shift.ast;
            my $identifier = $postfix.properties<identifier>;
            if my $macro = is-macro($postfix, TYPE<Q::Postfix::Call>, $/.ast) {
                make expand($macro, $postfix.properties<argumentlist>.properties<arguments>.value,
                    -> { $postfix.type.create(:$identifier, :operand($/.ast), :argumentlist($postfix.properties<argumentlist>)) });
            }
            elsif $postfix.isa("Q::Postfix::Index") {
                make $postfix.type.create(:$identifier, :operand($/.ast), :index($postfix.properties<index>));
            }
            elsif $postfix.isa("Q::Postfix::Call") {
                make $postfix.type.create(:$identifier, :operand($/.ast), :argumentlist($postfix.properties<argumentlist>));
            }
            elsif $postfix.isa("Q::Postfix::Property") {
                make $postfix.type.create(:$identifier, :operand($/.ast), :property($postfix.properties<property>));
            }
            else {
                if my $macro = is-macro($postfix, TYPE<Q::Postfix>, $identifier) {
                    make expand($macro, [$/.ast],
                        -> { $postfix.type.create(:$identifier, :operand($/.ast)) });
                }
                else {
                    make $postfix.type.create(:$identifier, :operand($/.ast));
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
        my $identifier = TYPE<Q::Identifier>.create(
            :name(wrap("prefix:$op")),
            :frame($*runtime.current-frame),
        );
        make $*parser.opscope.ops<prefix>{$op}.type.create(:$identifier, :operand(NONE));
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
        make TYPE<Q::Literal::Str>.create(:$value);
    }

    method term:none ($/) {
        make TYPE<Q::Literal::None>.create();
    }

    method term:false ($/) {
        make TYPE<Q::Literal::Bool>.create(:value(FALSE));
    }

    method term:true ($/) {
        make TYPE<Q::Literal::Bool>.create(:value(TRUE));
    }

    method term:int ($/) {
        make TYPE<Q::Literal::Int>.create(:value(wrap(+$/)));
    }

    method term:str ($/) {
        make $<str>.ast;
    }

    method term:array ($/) {
        my $elements = wrap($<EXPR>».ast);
        make TYPE<Q::Term::Array>.create(:$elements);
    }

    method term:parens ($/) {
        make $<EXPR>.ast;
    }

    method term:regex ($/) {
        make TYPE<Q::Term::Regex>.create(:contents($<contents>.ast.properties<value>));
    }

    method term:identifier ($/) {
        make $<identifier>.ast;
        my $name = $<identifier>.ast.properties<name>.value;
        if !$*runtime.declared($name) {
            my $frame = $*runtime.current-frame;
            $*parser.postpone: sub checking-postdeclared {
                my $value = $*runtime.maybe-get-var($name, $frame);
                die X::Macro::Postdeclared.new(:$name)
                    if $value ~~ _007::Object && $value.isa("Macro");
                die X::Undeclared.new(:symbol($name))
                    unless $value ~~ _007::Object && $value.isa("Sub");
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
                make TYPE<Q::Term::Quasi>.create(:$contents, :$qtype);
                return;
            }
            elsif $qtype.value eq "Q::StatementList" {
                my $contents = $block.ast.properties<statementlist>;
                make TYPE<Q::Term::Quasi>.create(:$contents, :$qtype);
                return;
            }
            elsif $qtype.value ne "Q::Block"
                && $block.ast.isa("Q::Block")
                && $block.ast.properties<statementlist>.properties<statements>.value.elems == 1
                && $block.ast.properties<statementlist>.properties<statements>.value[0].isa("Q::Statement::Expr") {

                my $contents = $block.ast.properties<statementlist>.properties<statements>.value[0].properties<expr>;
                make TYPE<Q::Term::Quasi>.create(:$contents, :$qtype);
                return;
            }
        }

        for <argumentlist block compunit EXPR infix parameter parameterlist
            postfix prefix property propertylist statement statementlist
            term trait traitlist unquote> -> $subrule {

            if $/{$subrule} -> $submatch {
                my $contents = $submatch.ast;
                make TYPE<Q::Term::Quasi>.create(:$contents, :$qtype);
                return;
            }
        }

        die "Got something in a quasi that we didn't expect: {$/.keys}";   # should never happen
    }

    method term:sub ($/) {
        my $parameterlist = $<parameterlist>.ast;
        my $traitlist = $<traitlist>.ast;
        my $statementlist = $<blockoid>.ast;

        my $block = TYPE<Q::Block>.create(:$parameterlist, :$statementlist, :static-lexpad(empty-dict()));
        if $<identifier> {
            my $name = $<identifier>.ast.properties<name>;
            my $outer-frame = $*runtime.current-frame.value<outer-frame>;
            my $static-lexpad = $*runtime.current-frame.value<pad>;
            my $val = TYPE<Sub>.create(:$name, :$parameterlist, :$statementlist, :$outer-frame, :$static-lexpad);
            bound-method($<identifier>.ast, "put-value")($val, $*runtime);
        }
        self.finish-block($block);

        my $name = $<identifier> && $<identifier>.ast.properties<name>;
        my $identifier = $<identifier>
            ?? TYPE<Q::Identifier>.create(:$name, :frame(NONE))
            !! NONE;
        make TYPE<Q::Term::Sub>.create(:$identifier, :$traitlist, :$block);
    }

    method unquote ($/) {
        my $qtype = $<identifier>
            ?? $*runtime.get-var($<identifier>.ast.properties<name>.value)
            !! TYPE<Q::Term>;
        make TYPE<Q::Unquote>.create(:$qtype, :expr($<EXPR>.ast));
    }

    method term:new-object ($/) {
        my $type = $<identifier>.ast.properties<name>.value;
        my $type-var = $*runtime.get-var($type);
        my $type-obj = $type-var ~~ _007::Type
            ?? $type-var
            !! $type-var.type;

        if $type-obj ~~ _007::Type {
            # XXX: need to figure out how to do the corresponding error handling here
            # something with .fields, most likely?
        }

        # XXX: Need some way to detect undeclared or required properties with _007::Type
#            sub aname($attr) { $attr.name.substr(2) }
#            my %known-properties = $type-obj.attributes.map({ aname($_) => 1 });
#            for $<propertylist>.ast.value.value -> $p {
#                my $property = $p.key.value;
#                die X::Property::NotDeclared.new(:$type, :$property)
#                    unless %known-properties{$property};
#            }
#            for %known-properties.keys -> $property {
#                # If an attribute has an initializer, then we don't require that it be
#                # passed, since it will get a sensible value anyway.
#                next if $type-obj.^attributes.first({ .name.substr(2) eq $property }).build;
#
#                die X::Property::Required.new(:$type, :$property)
#                    unless $property eq any($<propertylist>.ast.value.value».key».value);
#            }

        make TYPE<Q::Term::Object>.create(
            :type(TYPE<Q::Identifier>.create(
                :name(wrap($type)),
                :frame(NONE),
            )),
            :propertylist($<propertylist>.ast));
    }

    method term:dict ($/) {
        make TYPE<Q::Term::Dict>.create(
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
        make TYPE<Q::PropertyList>.create(:$properties);
    }

    method property:str-expr ($/) {
        make TYPE<Q::Property>.create(:key($<str>.ast.properties<value>), :value($<value>.ast));
    }

    method property:identifier-expr ($/) {
        my $key = $<identifier>.ast.properties<name>;
        make TYPE<Q::Property>.create(:$key, :value($<value>.ast));
    }

    method property:identifier ($/) {
        my $key = $<identifier>.ast.properties<name>;
        make TYPE<Q::Property>.create(:$key, :value($<identifier>.ast));
    }

    method property:method ($/) {
        my $block = TYPE<Q::Block>.create(
            :parameterlist($<parameterlist>.ast),
            :statementlist($<blockoid>.ast),
            :static-lexpad(wrap({})),
        );
        my $name = $<identifier>.ast.properties<name>;
        my $identifier = TYPE<Q::Identifier>.create(:$name, :frame(NONE));
        make TYPE<Q::Property>.create(
            :key($name),
            :value(TYPE<Q::Term::Sub>.create(
                :$identifier,
                :$block,
                :traitlist(TYPE<Q::TraitList>.create(
                    :traits(wrap([])),
                )),
            )),
        );
        self.finish-block($block);
    }

    method infix($/) {
        my $op = ~$/;
        my $identifier = TYPE<Q::Identifier>.create(
            :name(wrap("infix:$op")),
            :frame($*runtime.current-frame),
        );
        make $*parser.opscope.ops<infix>{$op}.type.create(:$identifier, :lhs(NONE), :rhs(NONE));
    }

    method infix-unquote($/) {
        my $got = ~($<unquote><identifier> // "Q::Term");
        die X::TypeCheck.new(:operation<parsing>, :$got, :expected(_007::Object))
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
        my $identifier = TYPE<Q::Identifier>.create(
            :name(wrap("postfix:$op")),
            :frame($*runtime.current-frame),
        );
        # XXX: this can't stay hardcoded forever, but we don't have the machinery yet
        # to do these right enough
        if $<index> {
            make TYPE<Q::Postfix::Index>.create(index => $<EXPR>.ast, :$identifier, :operand(NONE));
        }
        elsif $<call> {
            make TYPE<Q::Postfix::Call>.create(argumentlist => $<argumentlist>.ast, :$identifier, :operand(NONE));
        }
        elsif $<prop> {
            make TYPE<Q::Postfix::Property>.create(property => $<identifier>.ast, :$identifier, :operand(NONE));
        }
        else {
            make $*parser.opscope.ops<postfix>{$op}.type.create(:$identifier, :operand(NONE));
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
        make TYPE<Q::Identifier>.create(:$name, :frame(NONE));
    }

    method argumentlist($/) {
        my $arguments = wrap($<EXPR>».ast);
        make TYPE<Q::ArgumentList>.create(:$arguments);
    }

    method parameterlist($/) {
        my $parameters = wrap($<parameter>».ast);
        make TYPE<Q::ParameterList>.create(:$parameters);
    }

    method parameter($/) {
        make TYPE<Q::Parameter>.create(:identifier($<identifier>.ast));
    }
}
