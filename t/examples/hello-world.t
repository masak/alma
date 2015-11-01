use Test;

my $output = qx[perl6 bin/007 examples/hello-world.007];
is $output, "Hello, world!\n", "correct output";

done-testing;
