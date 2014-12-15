use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        my n = 7
        .

    my $ast = q:to/./;
        (statements
          (vardecl (ident "n") (assign (ident "n") (int 7))))
        .

    parses-to $program, $ast, "can skip the last semicolon";
}

{
    my $program = q:to/./;
        my s = "Bond
        ";
        .

    parse-error $program, X::String::Newline, "can't have a newline in a string";
}

{
    my $program = q:to/./;
        say     (
            38
        +
            4       )
                ;
        .

    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (+ (int 38) (int 4))))))
        .

    parses-to $program, $ast, "spaces are fine here and there";
}

{
    my $program = q:to/./;
        say("A" ~ "B" ~ "C" ~ "D");
        .

    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (~ (~ (~ (str "A") (str "B")) (str "C")) (str "D"))))))
        .

    parses-to $program, $ast, "concat works any number of times (and is left-associative)";
}

{
    my $program = q:to/./;
        my aaa = [[[1]]];
        say(aaa[0][0][0]);
        .

    my $ast = q:to/./;
        (statements
          (vardecl (ident "aaa") (assign (ident "aaa") (array (array (array (int 1))))))
          (stexpr (call (ident "say") (arguments (index (index (index (ident "aaa") (int 0)) (int 0)) (int 0))))))
        .

    parses-to $program, $ast, "array indexing works any number of times";
}

done;
