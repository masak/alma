# Roadmap

007 is still a v0.x.x product. We make no particular guarantees about backwards
compatibility yet, as we're heading towards some kind of publicly releasable
stable condition.

Most of the forward-looking and thinking happens in the [issue
queue](https://github.com/masak/007/issues), and that's still the place to go
to for all the nitty-gritty details about planning and tradeoffs. But the
picture given by the issue queue is conveys no sense of priorities or ordering.
That's what this roadmap is for.

About versions: we (masak and sergot) are still not convinced that 007 *needs*
versions. We probably won't do releases of any kind. 007 is not really meant to
have downstream consumers. It's not even meant to be a real, usable language.
For the purposes of this roadmap, however, the versions are a way to structure
milestones and hang important features off of them.

## Driving examples

After most of the rest of the roadmap was written, one issue in particular
emerged as setting the agenda for what needs to be done short-term with 007:
[#194](https://github.com/masak/007/issues/194). It has proved to be important because it re-focuses 007 to get useful
and usable macros ASAP.

Here's the current proposed order of macro examples to tackle:

* An `infix:<ff>` macro, same as Perl 6's operator. This macro hits a sweet
  spot of being simple and also clearly needing to be a macro. It ends up
  being code with some private state, since hitting the same `ff` expression
  several times will have results depending on what has happened to that
  expression before. ([#207](https://github.com/masak/007/issues/207))

* A `swap` macro. Takes two lvalues and swaps their contents. The term
  "lvalue" here is significant, as these need to be assignable. (That's also
  why a simple sub wouldn't be enough in this case, since we have
  call-by-value.) This macro needs the location protocol to be in place in
  order to work fully. ([#218](https://github.com/masak/007/issues/218))

* Reduction metaoperator, such as `[+](1, 2, 3)`. In 007, the `[+]` would
  parse into a code-generated anonymous subroutine. This one is interesting
  for two reasons. First, it *really* uses closures and hygiene all-out.
  Second, it requires `is parsed` to be implemented enough to pass the `+`
  part of `[+]` as a parameter to the macro so that it can be part of the
  generated code. ([#176](https://github.com/masak/007/issues/176))

* `postfix:<++>` and family; a total of four operators. Also requires the
  location protocol. ([#122](https://github.com/masak/007/issues/122))

* `+=` assignment operators and family. Requires both the location
  protocol and `is parsed`. ([#152](https://github.com/masak/007/issues/152))

* `.=` mutating method call. Also requires both the location protocol and
  `is parsed`. ([#203](https://github.com/masak/007/issues/203))

* Unbound methods. Something like `unbound .abs` to denote the longer
  `sub (obj, ...args) { return obj.abs(...args); }`. ([#202](https://github.com/masak/007/issues/202))

* Arrow functions. Something like `x => x * x` to denote the longer
  `sub (x) { return x * x; }`. ([#215](https://github.com/masak/007/issues/215))

* Ternary operator `?? !!`. Also needs `is parsed`. ([#163](https://github.com/masak/007/issues/163))

* `each()` macro. This one is interesting because it's built using a
  statement macro inside of it. ([#158](https://github.com/masak/007/issues/158))

These are features/bug fixes that will need to be in place for the above to
work:

* Making hygienic lookups work. ([#387](https://github.com/masak/007/issues/387))
* The location protocol. (See below.) ([#214](https://github.com/masak/007/issues/214))
* `is parsed`, or at least enough of it. ([#177](https://github.com/masak/007/issues/177))
* Various Qnode introspection and manipulation. (No issue for this yet.)

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

* The big focus is [quasi unquotes](https://github.com/masak/007/issues/30), a
  big part of making simple macros work as expected. The champion on this one
  is **masak**.
* Make unhygienic declarations that are injected into code [actually declare
  stuff](https://github.com/masak/007/issues/88). We can cheat majorly at this
  one at first, as long as it works.
* [`is parsed`](https://github.com/masak/007/issues/#177).

### Language track

* We're planning to [give the web page a big
  facelift](https://github.com/masak/007/issues/67), including more examples
  and interactive Qtrees. The champion on this one is **masak**.
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
