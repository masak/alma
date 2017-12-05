use v6;
use Test;
use _007::Test;

{
    my $msg = "Mr. Bond";
    my $program = q:s:to/./;
        throw new Exception { message: "$msg" };
        .

    throws-exception $program, $msg, "throwing an exception";
}

done-testing;
