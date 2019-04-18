use Test;
use _007::Test;

for dir("t/community/code/") -> IO::Path $file {
    my $program = slurp($file.path);
    my $success = compile-and-check-success($program);

    ok $success, "{$file.path} compiles ok";
}

done-testing;
