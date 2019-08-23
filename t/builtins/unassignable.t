use Alma::Builtins;
use Test;
use Alma::Test;

for builtins-pad().properties {
    my $name = .value.?escaped-name || .key;
    
    my $program = qq:to/./;
        {$name} = "trying to assign this built-in";
        .

    parse-error
        $program,
        X::Assignment::ReadOnly,
        "can't assign to '{$name}' built-in";
}

done-testing;
