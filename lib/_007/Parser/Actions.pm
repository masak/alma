use _007::Q;
use _007::Parser::Exceptions;

class _007::Parser::Actions {
    method finish-block($block) {
        $block.static-lexpad = $*runtime.current-frame.pad;
        $*runtime.leave;
    }

    method TOP($/) {
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
            :ident($<identifier>.ast),
            :expr($<EXPR> ?? $<EXPR>.ast !! Val::None.new));
    }

    method statement:constant ($/) {
        die X::Syntax::Missing.new(:what("initializer on constant declaration"))
            unless $<EXPR>;

        make Q::Statement::Constant.new(
            :ident($<identifier>.ast),
            :expr($<EXPR>.ast));

        my $name = $<identifier>.ast.name.value;
        my $value = $<EXPR>.ast.eval($*runtime);
        $*runtime.put-var($name, $value);
    }

    method statement:expr ($/) {
        # XXX: this is a special case for macros that have been expanded at the
        #      top level of an expression statement, but it could happen anywhere
        #      in the expression tree
        if $<EXPR>.ast ~~ Q::Block {
            make Q::Statement::Expr.new(:expr(Q::Postfix::Call.new(
                :expr($<EXPR>.ast),
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
            my ($t1, $t2) = %precedence.keys.sort;
            die X::Trait::Conflict.new(:$t1, :$t2)
                if %precedence{$t1} && %precedence{$t2};
        }

        $*parser.oplevel.install($type, $op, :%precedence, :$assoc);
    }

    method statement:sub ($/) {
        my $ident = $<identifier>.ast;
        my $name = ~$<identifier>;
        my $parameterlist = $<parameterlist>.ast;
        my $statementlist = $<blockoid>.ast;

        my $block = Q::Block.new(:$parameterlist, :$statementlist);
        my %static-lexpad = $*runtime.current-frame.pad;
        self.finish-block($block);

        make Q::Statement::Sub.new(:$ident, :$block);

        my $outer-frame = $*runtime.current-frame;
        my $val = Val::Sub.new(:$name, :$parameterlist, :$statementlist, :$outer-frame, :%static-lexpad);
        $*runtime.declare-var($name, $val);

        maybe-install-operator($name, @<trait>);
    }

    method statement:macro ($/) {
        my $ident = $<identifier>.ast;
        my $name = ~$<identifier>;
        my $parameterlist = $<parameterlist>.ast;
        my $statementlist = $<blockoid>.ast;

        my $block = Q::Block.new(:$parameterlist, :$statementlist);
        my %static-lexpad = $*runtime.current-frame.pad;
        self.finish-block($block);

        make Q::Statement::Macro.new(:$ident, :$block);

        my $outer-frame = $*runtime.current-frame;
        my $val = Val::Macro.new(:$name, :$parameterlist, :$statementlist, :$outer-frame, :%static-lexpad);
        $*runtime.declare-var($name, $val);

        maybe-install-operator($name, @<trait>);
    }

    method statement:return ($/) {
        make Q::Statement::Return.new(:expr($<EXPR> ?? $<EXPR>.ast !! Val::None.new));
    }

    method statement:if ($/) {
        make Q::Statement::If.new(|$<xblock>.ast);
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

    method trait($/) {
        make Q::Trait.new(:ident($<identifier>.ast), :expr($<EXPR>.ast));
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
            make Q::Block.new(
                :parameterlist($<parameterlist>.ast),
                :statementlist($<blockoid>.ast));
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
        sub tighter($op1, $op2) {
            my $name1 = $op1.type.substr(1, *-1);
            my $name2 = $op2.type.substr(1, *-1);
            my $b = $*parser.oplevel.infixprec.first(*.contains($name1), :k)
                 > $*parser.oplevel.infixprec.first(*.contains($name2), :k);
            return $b;  # XXX: inexplicable runtime error if we return the value directly
        }

        sub equal($op1, $op2) {
            my $name1 = $op1.type.substr(1, *-1);
            my $name2 = $op2.type.substr(1, *-1);
            my $b = $*parser.oplevel.infixprec.first(*.contains($name1), :k)
                == $*parser.oplevel.infixprec.first(*.contains($name2), :k);
            return $b;  # XXX: inexplicable runtime error if we return the value directly
        }

        sub left-associative($op) {
            my $name = $op.type.substr(1, *-1);
            return $*parser.oplevel.infixprec.first(*.contains($name)).assoc eq "left";
        }

        sub non-associative($op) {
            my $name = $op.type.substr(1, *-1);
            return $*parser.oplevel.infixprec.first(*.contains($name)).assoc eq "non";
        }

        my @opstack;
        my @termstack = $<termish>[0].ast;
        sub REDUCE {
            my $t2 = @termstack.pop;
            my $op = @opstack.pop;
            my $t1 = @termstack.pop;

            my $name = $op.type.substr(1, *-1);
            my $c = $*runtime.maybe-get-var("infix:<$name>");
            if $c ~~ Val::Macro {
                @termstack.push($*runtime.call($c, [$t1, $t2]));
            }
            else {
                @termstack.push($op.new(:lhs($t1), :rhs($t2)));

                if $op === Q::Infix::Assignment {
                    die X::Immutable.new(:method<assignment>, :typename($t1.^name))
                        unless $t1 ~~ Q::Identifier;
                    my $block = $*runtime.current-frame();
                    my $var = $t1.name;
                    %*assigned{$block ~ $var}++;
                }
            }
        }

        for $<infix>».ast Z $<termish>[1..*]».ast -> ($infix, $term) {
            while @opstack && (tighter(@opstack[*-1], $infix)
                || equal(@opstack[*-1], $infix) && left-associative($infix)) {
                REDUCE;
            }
            die X::Op::Nonassociative.new(:op1(@opstack[*-1]), :op2($infix))
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
        sub tighter($op1, $op2) {
            my $name1 = $op1.type.substr(1, *-1);
            my $name2 = $op2.type.substr(1, *-1);
            my $b = $*parser.oplevel.prepostfixprec.first(*.contains($name1), :k)
                 > $*parser.oplevel.prepostfixprec.first(*.contains($name2), :k);
            return $b;  # XXX: inexplicable runtime error if we return the value directly
        }

        sub equal($op1, $op2) {
            my $name1 = $op1.type.substr(1, *-1);
            my $name2 = $op2.type.substr(1, *-1);
            my $b = $*parser.oplevel.prepostfixprec.first(*.contains($name1), :k)
                == $*parser.oplevel.prepostfixprec.first(*.contains($name2), :k);
            return $b;  # XXX: inexplicable runtime error if we return the value directly
        }

        sub left-associative($op) {
            my $name = $op.type.substr(1, *-1);
            return $*parser.oplevel.prepostfixprec.first(*.contains($name)).assoc eq "left";
        }

        sub non-associative($op) {
            my $name = $op.type.substr(1, *-1);
            return $*parser.oplevel.prepostfixprec.first(*.contains($name)).assoc eq "non";
        }

        make $<term>.ast;

        my @prefixes = @<prefix>.reverse;   # evaluated inside-out
        my @postfixes = @<postfix>;

        sub handle-prefix($/) {
            my $prefix = @prefixes.shift.ast;
            my $name = $prefix.type.substr(1, *-1);
            my $c = $*runtime.maybe-get-var("prefix:<$name>");
            if $c ~~ Val::Macro {
                make $*runtime.call($c, [$/.ast]);
            }
            else {
                make $prefix.new(:expr($/.ast));
            }
        }

        sub handle-postfix($/) {
            my $postfix = @postfixes.shift.ast;
            # XXX: factor the logic that checks for macro call out into its own helper sub
            my @p = $postfix.list;
            if @p[0] ~~ Q::Postfix::Call
            && $/.ast ~~ Q::Identifier
            && (my $macro = $*runtime.maybe-get-var($/.ast.name.value)) ~~ Val::Macro {
                my @args = @p[1]<argumentlist>.arguments.elements;
                my $qtree = $*runtime.call($macro, @args);
                make $qtree;
            }
            elsif @p >= 2 {
                make @p[0].new(:expr($/.ast), |@p[1]);
            }
            else {
                my $name = $postfix.type.substr(1, *-1);
                my $c = $*runtime.maybe-get-var("postfix:<$name>");
                if $c ~~ Val::Macro {
                    make $*runtime.call($c, [$/.ast]);
                }
                else {
                    make $postfix.new(:expr($/.ast));
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
                die X::Op::Nonassociative.new(:op1($prefix), :op2($postfix))
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
        make $*parser.oplevel.ops<prefix>{~$/};
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
        make Q::Term::Quasi.new(:block($<block>.ast));
    }

    method unquote ($/) {
        make Q::Unquote.new(:expr($<EXPR>.ast));
    }

    method term:object ($/) {
        my $type = ~($<identifier> // "Object");

        # XXX: It's not really the name "Object" we should special-case,
        #      it's the type object "Object" among the built-ins
        if $type ne "Object" {
            sub aname($attr) { $attr.name.substr(2) }
            my %known-properties = types(){$type}.attributes.map({ aname($_) => 1 });
            for $<propertylist>.ast.properties.elements -> $p {
                my $property = $p.key.value;
                die X::Property::NotDeclared.new(:$type, :$property)
                    unless %known-properties{$property};
            }
            for %known-properties.keys -> $property {
                die X::Property::Required.new(:$type, :$property)
                    unless $property eq any($<propertylist>.ast.properties.elements».key».value);
            }
        }

        make Q::Term::Object.new(
            :type(Q::Identifier.new(:name(Val::Str.new(:value($type))))),
            :propertylist($<propertylist>.ast));
    }

    method propertylist ($/) {
        make Q::PropertyList.new(:properties(Val::Array.new(:elements($<property>».ast))));
    }

    method property:str-expr ($/) {
        make Q::Property.new(:key($<str>.ast.value), :value($<value>.ast));
    }

    method property:ident-expr ($/) {
        make Q::Property.new(:key(Val::Str.new(:value(~$<identifier>))), :value($<value>.ast));
    }

    method property:ident ($/) {
        make Q::Property.new(:key(Val::Str.new(:value(~$<identifier>))), :value($<identifier>.ast));
    }

    method property:method ($/) {
        make Q::Property.new(:key(Val::Str.new(:value(~$<identifier>))), :value(Q::Block.new(
            :parameterlist($<parameterlist>.ast),
            :statementlist($<blockoid>.ast))));
    }

    method infix($/) {
        make $*parser.oplevel.ops<infix>{~$/};
    }

    method postfix($/) {
        # XXX: this can't stay hardcoded forever, but we don't have the machinery yet
        # to do these right enough
        if $<index> {
            make [Q::Postfix::Index, { index => $<EXPR>.ast }];
        }
        elsif $<call> {
            make [Q::Postfix::Call, { argumentlist => $<argumentlist>.ast }];
        }
        elsif $<prop> {
            make [Q::Postfix::Property, { ident => $<identifier>.ast }];
        }
        else {
            make $*parser.oplevel.ops<postfix>{~$/};
        }
    }

    method identifier($/) {
        make Q::Identifier.new(:name(Val::Str.new(:value(~$/))));
    }

    method argumentlist($/) {
        make Q::ArgumentList.new(:arguments(Val::Array.new(:elements($<EXPR>».ast))));
    }

    method parameterlist($/) {
        make Q::ParameterList.new(:parameters(Val::Array.new(:elements($<identifier>».ast))));
    }
}
