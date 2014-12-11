use v6;
use _007;
use Test;

sub read(Str $ast) is export {
    my %qclass_lookup =
        int         => Q::Literal::Int,
        str         => Q::Literal::Str,
        array       => Q::Literal::Array,
        block       => Q::Literal::Block,
        ident       => Q::Term::Identifier,

        '+'         => Q::Expr::Infix::Addition,
        '~'         => Q::Expr::Infix::Concat,
        assign      => Q::Expr::Assignment,
        '=='        => Q::Expr::Infix::Eq,
        call        => Q::Expr::Call::Sub,
        index       => Q::Expr::Index,

        vardecl     => Q::Statement::VarDecl,
        stexpr      => Q::Statement::Expr,
        if          => Q::Statement::If,
        stblock     => Q::Statement::Block,
        sub         => Q::Statement::Sub,
        return      => Q::Statement::Return,
        for         => Q::Statement::For,

        statements  => Q::Statements,
        parameters  => Q::Parameters,
        arguments   => Q::Arguments,
    ;

    my grammar _007::Syntax {
        regex TOP { \s* <expr> \s* }
        proto token expr {*}
        token expr:list { '(' ~ ')' [<expr>+ % \s+] }
        token expr:int { '-'? \d+ }
        token expr:str { '"' ~ '"' (<-["]>*) }
        token expr:symbol { <!before '"'><!before \d> [<!before ')'> \S]+ }
    }

    my $actions = role {
        method TOP($/) { make $<expr>.ast }
        method expr:list ($/) {
            my $qname = ~$<expr>[0];
            die "Unknown name: $qname"
                unless %qclass_lookup{$qname} :exists;
            my $qclass = %qclass_lookup{$qname};
            my @rest = $<expr>».ast[1..*];
            make $qclass.new(|@rest);
        }
        method expr:symbol ($/) { make ~$/ }
        method expr:int ($/) { make +$/ }
        method expr:str ($/) { make ~$0 }
    };

    _007::Syntax.parse($ast, :$actions)
        or die "failure";
    return $/.ast;
}

role Output {
    has $.result = "";

    method say($s) { $!result ~= $s ~ "\n" }
}

sub is-result($input, $expected, $desc = "MISSING TEST DESCRIPTION") is export {
    my $ast = read($input);
    my $output = Output.new;
    my $runtime = _007.runtime(:$output);
    $runtime.run($ast, :$output);

    is $output.result, $expected, $desc;
}

sub is-error($input, $expected-error, $desc = $expected-error.^name) is export {
    my $ast = read($input);
    my $output = Output.new;
    my $runtime = _007.runtime(:$output);
    $runtime.run($ast, :$output);

    CATCH {
        when $expected-error {
            pass $desc;
        }
    }
    flunk $desc;
}
