use v6;
use Test;
use _007::Test;

{
    outputs 'func foo() {}; say(foo)', "<func foo()>\n", "zero-param sub";
    outputs 'func fn(x, y, z) {}; say(fn)', "<func fn(x, y, z)>\n", "func with three parameters";
    outputs 'say(say)', "<func say(arg)>\n", "builtin sub";
    outputs 'say(infix:<+>)', "<func infix:<+>(lhs, rhs)>\n", "builtin func (infix)";
    outputs 'say(infix:<\>>)', "<func infix:«>»(lhs, rhs)>\n", "builtin func (infix) -- contains > (I)";
    outputs 'say(infix:«>»)', "<func infix:«>»(lhs, rhs)>\n", "builtin func (infix) -- contains > (II)";
    outputs 'func infix:<\>»>(lhs, rhs) {}; say(infix:<\>»>)',
        "<func infix:<\>»>(lhs, rhs)>\n",
        "builtin func (infix) -- contains both > and »";
    outputs 'macro foo() {}; say(foo)', "<macro foo()>\n", "zero-param macro";
    outputs 'macro mc(x, y, z) {}; say(mc)', "<macro mc(x, y, z)>\n", "macro with three parameters";
}

{
    outputs 'my foo = [0, 0, 7]; foo[2] = foo; say(foo)', "[0, 0, [...]]\n", "array with reference to itself";
    outputs 'my foo = {}; foo.x = foo; say(foo)', "\{x: \{...\}\}\n", "object with reference to itself";
}

done-testing;
