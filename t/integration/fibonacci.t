use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statementlist
          (stsub (identifier "fib") (block (parameterlist (param (identifier "n"))) (statementlist
            (if (infix:== (identifier "n") (int 0)) (block (parameterlist) (statementlist
              (return (int 1)))))
            (if (infix:== (identifier "n") (int 1)) (block (parameterlist) (statementlist
              (return (int 1)))))
            (return (infix:+ (postfix:() (identifier "fib") (argumentlist (infix:+ (identifier "n") (prefix:- (int 1)))))
                       (postfix:() (identifier "fib") (argumentlist (infix:+ (identifier "n") (prefix:- (int 2))))))))))
          (stexpr (postfix:() (identifier "say") (argumentlist (postfix:() (identifier "fib") (argumentlist (int 2))))))
          (stexpr (postfix:() (identifier "say") (argumentlist (postfix:() (identifier "fib") (argumentlist (int 3))))))
          (stexpr (postfix:() (identifier "say") (argumentlist (postfix:() (identifier "fib") (argumentlist (int 4)))))))
        .

    is-result $ast, "2\n3\n5\n", "recursive calls with returns work out fine";
}

done-testing;
