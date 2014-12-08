use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (compunit
          (stblock (block (parameters) (statements
            (stexpr (call (ident "say") (str "OH HAI from inside block")))))))
        .

    is-result $ast, "OH HAI from inside block\n", "immediate blocks work";
}

done;
