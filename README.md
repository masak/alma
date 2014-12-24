# 007

A small language. A test bed for macro ideas.

## TODO

* subroutines for ops
* [man or boy](https://en.wikipedia.org/wiki/Man_or_boy_test)
* making Q:: types first-class values
* macros
* quasi blocks
* unquotes

Dependency graph for some important todo items:

                                                        first-class Q::
                                                         /    |
        subroutines for ops         macros--------------/   quasi
                 |                   /   \                    |
        operator macros-------------/     \-----------------unquotes
