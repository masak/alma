use v6;
use Test;

my @p6types = flat
    "lib/_007/Q.pm".IO.lines.map({ ~$0 if /^ < class role > \h+ ("Q::" \S+)/ }),
    "lib/_007/Val.pm".IO.lines.map({ ~$0 if /^ class \h+ ("Val::" \S+)/ });

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
