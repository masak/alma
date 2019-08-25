use Test;
use Alma::Test;

outputs(
    q[say("Hello, world!");],
    "Hello, world!\n",
    "Running 'hello world' works",
);

done-testing;
