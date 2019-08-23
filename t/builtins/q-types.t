use Alma::Q;
use Test;
use Alma::Test;

my @q-types;

sub tree-walk(%package) {
    for %package.keys.map({ %package ~ "::$_" }) -> $name {
        my $type = ::($name);
        push @q-types, $type.^name.subst('::', '.', :g);
        tree-walk($type.WHO);
    }
}

push @q-types, "Q";
tree-walk(Q::);
@q-types.=sort;

for @q-types -> $q-type {
    my $program = qq:to/./;
        say({$q-type});
        .

    outputs $program, "<type {$q-type}>\n", "can access {$q-type}";
}

done-testing;
