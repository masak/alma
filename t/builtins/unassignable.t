use _007::Value;
use _007::Builtins;
use Test;
use _007::Test;

for get-all-dict-properties(builtins-pad()) {
    my $name = is-callable(.value)
        ?? escaped-name(.value)
        !! .key;
    
    my $program = qq:to/./;
        {$name} = "trying to assign this built-in";
        .

    parse-error
        $program,
        X::Assignment::ReadOnly,
        "can't assign to '{$name}' built-in";
}

done-testing;
