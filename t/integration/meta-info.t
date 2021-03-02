use v6;
use Test;
use Alma::Test;

my @lib-pms = find("lib", / ".rakumod" $/)».Str;

my @meta-info-pms = "META6.json".IO.lines.map({ ~$0 if /\" \h* \: \h* \" (lib\/Alma<-["]>+)/ });

{
    my $missing-meta-info-lines = (@lib-pms (-) @meta-info-pms).keys.map({ "- $_" }).join("\n");
    is $missing-meta-info-lines, "", "all .rakumod files in lib/ are declared in META6.json";
}

{
    my $superfluous-meta-info-lines = (@meta-info-pms (-) @lib-pms).keys.map({ "- $_" }).join("\n");
    is $superfluous-meta-info-lines, "", "all .rakumod files declared in META6.json also exist in lib/";
}

{
    is trailing-commas(slurp "META6.json"), "", "there are no trailing commas in the META6.json file";
}

done-testing;
