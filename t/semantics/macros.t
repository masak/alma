use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statements
          (macro (ident "f") (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "OH HAI from inside macro")))))))
        .

    is-result $ast, "", "macro";
}

done;
