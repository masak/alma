use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (compunit
          (stexpr (call (infix (ident "infix:<+>") (int 38) (int 4)))))
        .

    is-result $ast, "42\n", "numeric addition works";
}

{
    my $ast = q:to/./;
        (compunit
          (stexpr (call (infix (ident "infix:<~>") (str "Jame") (str "s Bond")))))
        .

    is-result $ast, "James Bond\n", "string concatenation works";
}

done;
