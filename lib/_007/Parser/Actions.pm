use _007::Q;

class _007::Parser::Actions {
    method finish-block($block) {
        $block.static-lexpad = $*runtime.current-frame.pad;
        $*runtime.leave;
    }

    method TOP($/) {
        my $cu = Q::CompUnit.new(Q::Block.new(
            Q::ParameterList.new,
            $<statementlist>.ast
        ));
        make $cu;
        self.finish-block($cu.block);
    }

    method statementlist($/) {
        make Q::StatementList.new($<statement>».ast);
    }

    method statement:my ($/) {
        if $<EXPR> {
            make Q::Statement::My.new($<identifier>.ast, $<EXPR>.ast);
        }
        else {
            make Q::Statement::My.new($<identifier>.ast);
        }
    }

    method statement:constant ($/) {
        if $<EXPR> {
            make Q::Statement::Constant.new($<identifier>.ast, $<EXPR>.ast);
        }
        else {  # XXX: remove this part once we throw an error
            make Q::Statement::Constant.new($<identifier>.ast);
        }
        my $name = $<identifier>.ast.name;
        my $value = $<EXPR>.ast.eval($*runtime);
        $*runtime.put-var($name, $value);
    }

    method statement:expr ($/) {
        if $<EXPR>.ast ~~ Q::Block {
            my @statementlist = $<EXPR>.ast.statementlist.list;
            die "Can't handle this case with more than one statement yet" # XXX
                if @statementlist > 1;
            make @statementlist[0];
        }
        else {
            make Q::Statement::Expr.new($<EXPR>.ast);
        }
    }

    method statement:block ($/) {
        die X::PointyBlock::SinkContext.new
            if $<pblock><parameterlist>;
        make Q::Statement::Block.new($<pblock>.ast);
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
                my $value = $string.value;
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
        my $identifier = $<identifier>.ast;
        my $name = ~$<identifier>;
        my $parameterlist = $<parameterlist>.ast;
        my $statementlist = $<blockoid>.ast;

        my $block = Q::Block.new($parameterlist, $statementlist);
        self.finish-block($block);
        my $sub = Q::Statement::Sub.new(
            $identifier,
            $block);

        make $sub;

        my $outer-frame = $*runtime.current-frame;
        my $val = Val::Sub.new(:$name, :$parameterlist, :$statementlist, :$outer-frame);
        $*runtime.declare-var($name, $val);

        maybe-install-operator($identifier.name, @<trait>);
    }

    method statement:macro ($/) {
        my $identifier = $<identifier>.ast;
        my $name = ~$<identifier>;
        my $parameterlist = $<parameterlist>.ast;
        my $statementlist = $<blockoid>.ast;

        my $block = Q::Block.new($parameterlist, $statementlist);
        self.finish-block($block);
        my $macro = Q::Statement::Macro.new(
            $identifier,
            $block);

        make $macro;

        my $outer-frame = $*runtime.current-frame;
        my $val = Val::Macro.new(:$name, :$parameterlist, :$statementlist, :$outer-frame);
        $*runtime.declare-var($name, $val);

        maybe-install-operator($identifier.name, @<trait>);
    }

    method statement:return ($/) {
        if $<EXPR> {
            make Q::Statement::Return.new(
                $<EXPR>.ast);
        }
        else {
            make Q::Statement::Return.new;
        }
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
        make Q::Statement::BEGIN.new($block);
        $*runtime.run(Q::CompUnit.new($block));
    }

    method trait($/) {
        make Q::Trait.new($<identifier>.ast, $<EXPR>.ast);
    }

    method blockoid ($/) {
        make $<statementlist>.ast;
    }
    method block ($/) {
        my $block = Q::Block.new(
            Q::ParameterList.new,
            $<blockoid>.ast);
        make $block;
        self.finish-block($block);
    }
    method pblock ($/) {
        if $<parameterlist> {
            make Q::Block.new(
                $<parameterlist>.ast,
                $<blockoid>.ast);
        } else {
            make $<block>.ast;
        }
    }
    method xblock ($/) {
        make ($<EXPR>.ast, $<pblock>.ast);
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
            my $c = try $*runtime.get-var("infix:<$name>");
            if $c ~~ Val::Macro {
                @termstack.push($*runtime.call($c, [$t1, $t2]));
            }
            else {
                @termstack.push($op.new($t1, $t2));

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
            my $c = try $*runtime.get-var("prefix:<$name>");
            if $c ~~ Val::Macro {
                make $*runtime.call($c, [$/.ast]);
            }
            else {
                make $prefix.new($/.ast);
            }
        }

        sub handle-postfix($/) {
            my $postfix = @postfixes.shift.ast;
            # XXX: factor the logic that checks for macro call out into its own helper sub
            my @p = $postfix.list;
            if @p[0] ~~ Q::Postfix::Call
            && $/.ast ~~ Q::Identifier
            && (try my $macro = $*runtime.get-var($/.ast.name)) ~~ Val::Macro {
                my @args = @p[1].arguments;
                my $qtree = $*runtime.call($macro, @args);
                make $qtree;
            }
            elsif @p >= 2 {
                make @p[0].new($/.ast, @p[1]);
            }
            else {
                my $name = $postfix.type.substr(1, *-1);
                my $c = try $*runtime.get-var("postfix:<$name>");
                if $c ~~ Val::Macro {
                    make $*runtime.call($c, [$/.ast]);
                }
                else {
                    make $postfix.new($/.ast);
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

    method term:none ($/) {
        make Q::Literal::None.new;
    }

    method term:int ($/) {
        make Q::Literal::Int.new(+$/);
    }

    method term:str ($/) {
        sub check-for-newlines($s) {
            die X::String::Newline.new
                if $s ~~ /\n/;
        }(~$0);
        make Q::Literal::Str.new(~$0);
    }

    method term:array ($/) {
        make Q::Literal::Array.new($<EXPR>».ast);
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
        make Q::Quasi.new($<statementlist>.ast);
    }

    method unquote ($/) {
        make Q::Unquote.new($<EXPR>.ast);
    }

    method infix($/) {
        make $*parser.oplevel.ops<infix>{~$/};
    }

    method postfix($/) {
        # XXX: this can't stay hardcoded forever, but we don't have the machinery yet
        # to do these right enough
        if $<index> {
            make [Q::Postfix::Index, $<EXPR>.ast];
        }
        elsif $<call> {
            make [Q::Postfix::Call, $<argumentlist>.ast];
        }
        elsif $<prop> {
            make [Q::Postfix::Property, $<identifier>.ast];
        }
        else {
            make $*parser.oplevel.ops<postfix>{~$/};
        }
    }

    method identifier($/) {
        make Q::Identifier.new(~$/);
    }

    method argumentlist($/) {
        make Q::ArgumentList.new($<EXPR>».ast);
    }

    method parameterlist($/) {
        make Q::ParameterList.new($<identifier>».ast);
    }
}
