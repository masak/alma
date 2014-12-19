# 007

A small language. A test bed for macro ideas.

## TODO

* `typeof()`
* setting
* EXPR parser
* subroutines for ops
* fibonacci
* [man or boy](https://en.wikipedia.org/wiki/Man_or_boy_test)
* BEGIN blocks
* constants
* making Q:: types first-class values
* macros
* quasi blocks
* unquotes

Dependency graph for some important todo items:

    setting         EXPR parser     BEGIN blocks
         \            /                 |
        subroutines for ops         constants           first-class Q::
                        \               |                /    |
                         \----------macros--------------/   quasi
                                         \                    |
                                          \-----------------unquotes
