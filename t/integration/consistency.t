use v6;
use Test;

my @classes = flat
    qx[perl6 -ne 'say ~$0 if /^class \h+ ("Q::" \S+)/' lib/_007/Q.pm].lines,
    qx[perl6 -ne 'say ~$0 if /^class \h+ ("Val::" \S+)/' lib/_007/Val.pm].lines;
my @builtins = qx!perl6 -ne 'say ~$0 if /"=> Val::Type.of(" (<-[)]>+)/' lib/_007/Runtime/Builtins.pm!.lines;

{
    my $missing-classes = (@builtins (-) @classes).keys.map({ "- $_" }).join("\n");
    is $missing-classes, "", "all built-in types are also classes";
}

{
    my $missing-builtins = (@classes (-) @builtins).keys.map({ "- $_" }).join("\n");
    is $missing-builtins, "", "all classes are also built-in types";
}

done-testing;
