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

    outputs $program, "41\n", "try without finally";
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
            finally {
                return 42;
            }
        }
        say(shoot());
        .

    outputs $program, "42\n", "finally returns value before try";
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

    outputs $program, "7\n", "single catch";
}

{
    my $program = q:to/./;
        sub shoot() {
            try {
                return 41;
            }
            catch e {
            }
            catch e {
                return 7;
            }
        }
        say(shoot());
        .

    outputs $program, "7\n", "multiple catches";
}

done-testing;
