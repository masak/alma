use v6;
use Test;
use _007::Test;

{
    outputs 'sub foo() {}; say(foo)', "<sub foo()>\n", "zero-param sub";
    outputs 'sub fn(x, y, z) {}; say(fn)', "<sub fn(x, y, z)>\n", "sub with three parameters";
    outputs 'say(say)', "<sub say(arg)>\n", "builtin sub";
    outputs 'say(infix:<+>)', "<sub infix:<+>(lhs, rhs)>\n", "builtin sub (infix)";
    outputs 'say(infix:<\>>)', "<sub infix:«>»(lhs, rhs)>\n", "builtin sub (infix) -- contains > (I)";
    outputs 'say(infix:«>»)', "<sub infix:«>»(lhs, rhs)>\n", "builtin sub (infix) -- contains > (II)";
    outputs 'sub infix:<\>»>(lhs, rhs) {}; say(infix:<\>»>)',
        "<sub infix:<\>»>(lhs, rhs)>\n",
        "builtin sub (infix) -- contains both > and »";
    outputs 'macro foo() {}; say(foo)', "<macro foo()>\n", "zero-param macro";
    outputs 'macro mc(x, y, z) {}; say(mc)', "<macro mc(x, y, z)>\n", "macro with three parameters";
}

{
    outputs 'my foo = [0, 0, 7]; foo[2] = foo; say(foo)', "[0, 0, [...]]\n", "array with reference to itself";
    outputs 'my foo = {}; foo.x = foo; say(foo)', "\{x: \{...\}\}\n", "object with reference to itself";
}

done-testing;
