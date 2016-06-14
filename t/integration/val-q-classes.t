use v6;
use MONKEY-SEE-NO-EVAL;
use Test;
use _007;

sub tree-walk($package, @accum) {
    for $package.keys -> $key {
        my $name = "{$package}::{$key}";
        # make a little exception for Val::Sub::Builtin, which is just an
        # implementation detail and doesn't have a corresponding builtin
        # (because it tries to pass itself off as a Val::Sub)
        next if $name eq "Val::Sub::Builtin";
        push @accum, $name;
        tree-walk(EVAL("{$name}::"), @accum)
    }
}

my @p6types;
tree-walk(Q::, @p6types);
tree-walk(Val::, @p6types);

my @builtins = "lib/_007/Runtime/Builtins.pm".IO.lines.map({
    ~$0 if /^ \h+ ([Val|Q] "::" <-[,]>+) "," \h* $/
});

{
    my $missing-p6types = (@builtins (-) @p6types).keys.map({ "- $_" }).join("\n");
    is $missing-p6types, "", "all built-in types are also p6 types";
}

{
    my $missing-builtins = (@p6types (-) @builtins).keys.map({ "- $_" }).join("\n");
    is $missing-builtins, "", "all p6 types are also built-in types";
}

done-testing;
