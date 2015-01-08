The language 007 has these categories of operator:

    prefix
    infix
    postfix

When an expression is evaluated, it is matched according to this grammar:

    expr = <termish> +% <infix>
    termish = <prefix>* <term> <postfix>*

Infix and postfix share a namespace, and so defining any of these makes it
illegal to define the other:

    infix:<[>
    postfix:<[>

However, `prefix:<[>` can co-exist with either of those.

The three categories of operator and `term` have a kind of preconditions and
postconditions regarding the expression parser state:

    --ET--> term    --EO-->
    --ET--> prefix  --ET-->
    --EO--> infix   --ET-->
    --EO--> postfix --EO-->

Furthermore, the expression parser always starts in state `ET` (**Expect Term**)
and ends in state `EO` (**Expect Operator**).

So, matching an expression means getting a stream of tokens `[<prefix>*
<term> <postfix>*] +% <infix>`. These tokens are constructed into a tree as
follows.

* Prefixes and postfixes around a term are handled from innermost to outermost.

* If a prefix and a postfix are both about to be handled, then the one with
  the tightest priority gets handled first.

* Infixes are then handled in order of decreasing tightness.

* If two adjacent infix operators have the same tightness, their associativity
  determines which one gets handled first.

These simple rules have a number of consequences:

* There are two "layers" of precedence: the (tighter) prefix/postfix layer,
  and the (looser) infix layer.

* When an operator is added, it specifies which precedence it has; either
  tigher than, looser than, or equal to some existing operator within its
  layer. Specifying precedence relative to an operator from the wrong layer
  is not allowed.

* If no relation is specified, it automatically gets the tightest precedence
  within its layer.

* Unless an operator specifies itself to be equal in precedence to another,
  it ends up on a its own, new precedence level.

* Infix operators have right or left associativity. An infix operator that
  ends up on its own, new level also gets to specify its associativity. All
  later operators on that level get the same associativity.

* If an infix operator on a new level doesn't specify associativity, it
  automatically gets right associativity.
