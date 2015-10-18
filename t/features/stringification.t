use v6;
use Test;
use _007::Test;

{
    outputs 'sub foo() {}; say(foo)', "<sub foo()>\n", "zero-param sub";
    outputs 'sub fn(x, y, z) {}; say(fn)', "<sub fn(x, y, z)>\n", "sub with three parameters";
    outputs 'macro foo() {}; say(foo)', "<macro foo()>\n", "zero-param macro";
    outputs 'macro mc(x, y, z) {}; say(mc)', "<macro mc(x, y, z)>\n", "macro with three parameters";
}

done-testing;
