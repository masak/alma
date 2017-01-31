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

## Pre-v1.0.0

Work on 007 falls into two main tracks:

* Features that help explore macro-like things (ultimately for Perl 6)
* Features for 007 the language (ultimately for 007)

The first track is still the *raison d'être* for 007. The second track rounds
007 off as a nicer tool to work with.

### Macro track

* The big focus is [quasi unquotes](https://github.com/masak/007/issues/30), a
  big part of making simple macros work as expected. The champion on this one
  is **masak**.
* Also want to close [a philosophical
  issue](https://github.com/masak/007/issues/7) about the statement/expression
  discrepancy that's exhibited in quasi blocks. We're quite near to being able
  to resolve this one now.
* Make unhygienic declarations that are injected into code [actually declare
  stuff](https://github.com/masak/007/issues/88). We can cheat majorly at this
  one at first, as long as it works.

### Language track

* We're planning to [give the web page a big
  facelift](https://github.com/masak/007/issues/67), including more examples
  and interactive Qtrees. The champion on this one is **masak**.
    * masak would also like to take this opportunity to tie together some kind
      of doc-comments, automated tests, and documentation on the web page.

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
* assignment protocol
* iterator protocol
* declaration protocol
* signature binder protocol
* control flow protocol
