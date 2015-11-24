use v6;
use Test;
use _007::Test;

{
    outputs 'sub foo() {}; say(foo)', "<sub foo()>\n", "zero-param sub";
    outputs 'sub fn(x, y, z) {}; say(fn)', "<sub fn(x, y, z)>\n", "sub with three parameters";
    outputs 'say(say)', "<sub say(arg)>\n", "builtin sub";
    outputs 'say(infix:<+>)', "<sub infix:<+>(lhs, rhs)>\n", "builtin sub (infix)";
    outputs 'macro foo() {}; say(foo)', "<macro foo()>\n", "zero-param macro";
    outputs 'macro mc(x, y, z) {}; say(mc)', "<macro mc(x, y, z)>\n", "macro with three parameters";
}

done-testing;
