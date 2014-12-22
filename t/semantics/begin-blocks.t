use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statements
          (begin (block (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "won't get printed"))))))))
        .

    is-result $ast, "", "BEGIN blocks don't run at runtime";
}

{
    my $program = q:to/./;
        BEGIN {
            say("So early, Mr. Bond");
        }
        .

    outputs-during-parse
        $program,
        "So early, Mr. Bond\n",
        "BEGIN blocks execute during parse";
}

done;
