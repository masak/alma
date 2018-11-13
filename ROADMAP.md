# Roadmap

Stability and backwards compatibility stand in conflict with the need to 
iterate on ideas and replace newly discovered better ideas with old
worse ideas. 

007 is still a v0.x.x product. There are no guarantees about backwards
compatibility, as the need for inwards fluidity exceeds the need for
outwards stability.

The [issue queue](https://github.com/masak/007/issues), and that's still the
place to go to for all the nitty-gritty details about planning and tradeoffs.
But the picture given by the issue queue is conveys no sense of priorities or
ordering. That's what this roadmap is for.

## Short-term priorities

* **Get the lexical hygiene implementation in place.**

  The model described in [#410](https://github.com/masak/007/issues/410)
  should be implemented. It's the only thing currently standing in the
  way of rudimentary implementations of `infix:<ff>`
  ([#207](https://github.com/masak/007/issues/207)) and `swap`
  ([#218](https://github.com/masak/007/issues/218)).

* **Expose locations to userland and make them work in macros.**

  Each variable represents a *location* which can be read from and
  written to using an object-oriented API. See
  [#214](https://github.com/masak/007/issues/214) for details. Macros
  that use any argument more than once need to rely on this protocol
  to avoid breaking the Single Evaluation Rule. For example, the
  `swap` macro needs this for a correct implementation. We can also
  do `postfix:<++>` and family
  ([#122](https://github.com/masak/007/issues/122)).

* **Implement stateful macros.**

  See [#312](https://github.com/masak/007/issues/312) and
  [#313](https://github.com/masak/007/issues/313). One thing this will
  immediately unlock is the ability to make `infix:<ff>` *stateful*, that
  is, the macro does not have "global" state but resets whenever the
  surrounding routine is re-entered.

* **Implement contextual macros.**

  This would unlock the `each()` macro
  ([#158](https://github.com/masak/007/issues/158)), junctions
  ([#210](https://github.com/masak/007/issues/210)), and possibly
  the `amb` macro ([#13](https://github.com/masak/007/issues/13)).

## `is parsed` macros

After most of the rest of the roadmap was written, one issue in particular
emerged as setting the agenda for what needs to be done short-term with 007:
[#194](https://github.com/masak/007/issues/194). It has proved to be important because it re-focuses 007 to get useful
and usable macros ASAP.

Most of those were mentioned above, but here are the ones that require some
form of `is parsed` mechanism, the underpinnings of which has a slightly more
uncertain time plan:

* Reduction metaoperator, such as `[+](1, 2, 3)`. In 007, the `[+]` would
  parse into a code-generated anonymous subroutine. This one is interesting
  for two reasons. It *really* uses closures and hygiene all-out.
  ([#176](https://github.com/masak/007/issues/176))

* `+=` assignment operators and family. Requires the location
  protocol. ([#152](https://github.com/masak/007/issues/152))

* `.=` mutating method call. Also requires the location protocol.
  ([#203](https://github.com/masak/007/issues/203))

* Unbound methods. Something like `unbound .abs` to denote the longer
  `sub (obj, ...args) { return obj.abs(...args); }`. ([#202](https://github.com/masak/007/issues/202))

* Arrow functions. Something like `x => x * x` to denote the longer
  `sub (x) { return x * x; }`. ([#215](https://github.com/masak/007/issues/215))

* Ternary operator `?? !!`. ([#163](https://github.com/masak/007/issues/163))

## Pre-v1.0.0

Work on 007 falls into two main tracks:

* Features that help explore macro-like things (ultimately for Perl 6)
* Features for 007 the language (ultimately for 007)

The first track is still the *raison d'être* for 007. The second track rounds
007 off as a nicer tool to work with.

See also the [Reach Hacker News
completeness](https://github.com/masak/007/issues/335) issue, which outlines
some shorter-term plans.

### Macro track

* The four short-term priorities all refer to macro features.
* One focus is [quasi unquotes](https://github.com/masak/007/issues/30), a
  big part of making simple macros work as expected. The champion on this one
  is **masak**.
* Make unhygienic declarations that are injected into code [actually declare
  stuff](https://github.com/masak/007/issues/88). We can cheat majorly at this
  one at first, as long as it works.
* [`is parsed`](https://github.com/masak/007/issues/#177).

### Language track

* We're in the midst of [giving the web page a big
  facelift](https://github.com/masak/007/issues/67), including more examples.
  The champion on this one is **masak**.
* Implement some more [code inspection](https://github.com/masak/007/issues/222).

### General cleanup that should happen before v1.0.0

* [More Q node test coverage](https://github.com/masak/007/issues/52).
* Various things to make the parser give better errors, like [this
  issue](https://github.com/masak/007/issues/10) and [this
  issue](https://github.com/masak/007/issues/48) and [this
  issue](https://github.com/masak/007/issues/76) and [this
  issue](https://github.com/masak/007/issues/94).
* Go through the code base and remove all `XXX` comments, fixing them or
  promoting them into issues.
* [Start keeping a changelog](http://keepachangelog.com/).

## Post-v1.0.0

As v1.0.0 rolls by, it might be good to take stock and decide a new focus for
the next major version. However, from this vantage point, these are the
expected areas of focus after v1.0.0.

* [imports](https://github.com/masak/007/issues/53)
* [exceptions](https://github.com/masak/007/issues/65) (already underway)
* [class declarations](https://github.com/masak/007/issues/32) (already underway)
* [ADTs and pattern matching](https://github.com/masak/007/issues/34)
* [007 runtime in 007](https://github.com/masak/007/issues/51) (already underway)
* [type checking](https://github.com/masak/007/issues/33)
* [Qtree visitors](https://github.com/masak/007/issues/26)
* [007 parser in 007](https://github.com/masak/007/issues/38)
* [syntax macros](https://github.com/masak/007/issues/80)

Two things would be worthy enough to produce a v2.0.0 version. Either 007 being
bootstrapping enough to have both a runtime and a parser written in itself; or
007 having all three of regular macros, syntax macros, and visitor macros.

## Various protocols

XXX Will have to describe these protocols more in detail later. All the information
is currently scattered in the issue queue, which is what this roadmap is meant to
counteract.

Suffice it to say for now that "protocols" seem to be a fruitful approach to making
a language both extensible, introspectable, and bootstrappable all at once.

* boolification protocol
* equality protocol
* location protocol
* loop protocol
* declaration protocol
* signature binder protocol
* control flow protocol
