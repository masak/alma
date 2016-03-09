use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        sub A(k, x1, x2, x3, x4, x5) {
            if k <= 0 {
                return x4() + x5();
            } else {
                sub B() {
                    k = k - 1;
                    return A(k, B, x1, x2, x3, x4);
                }
                return B();
            }
        }

        sub x1() { return  1 }
        sub x2() { return -1 }
        sub x3() { return -1 }
        sub x4() { return  1 }
        sub x5() { return  0 }

        say(A(10, x1, x2, x3, x4, x5))
        .

    outputs $program, "-67\n", "007 is a man-compiler";
}

done-testing;
