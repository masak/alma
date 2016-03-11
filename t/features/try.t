use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        sub shoot() {
            try {
                say(41);
            }
        }
        shoot();
        .

    outputs $program, "41\n", "lone try";
}

{
    my $program = q:to/./;
        sub shoot() {
            try {
                return 41;
            }
            return 43;
        }
        say(shoot());
        .

    outputs $program, "41\n", "try returns value before sub";
}

{
    my $program = q:to/./;
        sub shoot() {
            try {
                return 41;
            }
            catch e {
                return 7;
            }
        }
        say(shoot());
        .

    outputs $program, "41\n", "a catch that doesn't run doesn't return anything";
}

{
    my $program = q:to/./;
        sub shoot() {
            try {
                throw new Exception { message: "Mr. Bond" };
            }
            catch e {
                return e.message;
            }
        }
        say(shoot());
        .

    outputs $program, "Mr. Bond\n", "exception gets caught in the catch in the sub";
}

{
    my $program = q:to/./;
        sub shoot() {
            throw new Exception { message: "oh, James" };
        }

        try {
            shoot();
        }
        catch e {
            say(e.message);
        }
        .

    outputs $program, "oh, James\n", "exception gets caught outside of the sub";
}

done-testing;
