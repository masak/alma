use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        func A(k, x1, x2, x3, x4, x5) {
            if k <= 0 {
                return x4() + x5();
            } else {
                func B() {
                    k = k - 1;
                    return A(k, B, x1, x2, x3, x4);
                }
                return B();
            }
        }

        func x1() { return  1 }
        func x2() { return -1 }
        func x3() { return -1 }
        func x4() { return  1 }
        func x5() { return  0 }

        say(A(10, x1, x2, x3, x4, x5))
        .

    outputs $program, "-67\n", "007 is a man-compiler";
}

done-testing;
