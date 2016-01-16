# Roadmap

007 is conceptually still a v0.x.x product. That is, we make no particular
guarantees about backwards compatibility yet, as we're heading towards some
kind of publicly releasable stable condition.

Most of the forward-looking and thinking happens in the [issue
queue](https://github.com/masak/007/issues), and that's still the place to go
to for all the nitty-gritty details about planning and tradeoffs. But the
picture given by the issue queue is messy, disjointed, and conveys no sense of
priorities or ordering. That's what this roadmap is for.

About versions: we (masak and sergot) are still not convinced that 007 *needs*
versions. We probably won't do releases of any kind. 007 is not really meant to
have downstream consumers. It's not even meant to be a real, usable language.
For the purposes of this roadmap, however, the versions are a way to structure
milestones and hang important features off of them.

## Pre-v1.0.0

Work on 007 will probably always fall into two main tracks:

* Features that help explore macro-like things (ultimately for Perl 6)
* Features for 007 the language (ultimately for 007)

The first track is still the *raison d'être* for 007. The second track rounds
007 off as a nicer tool to work with.

### Macro track

* The big focus is [quasi unquotes](https://github.com/masak/007/issues/30), a
  big part of making simple macros work as expected. The champion on this one
  is **masak**.
* We want [a `.detach()` operation on
  Qtrees](https://github.com/masak/007/issues/62).
* Also want to close [a philosophical
  issue](https://github.com/masak/007/issues/7) about the statement/expression
  discrepancy that's exhibited in quasi blocks.
* Make unhygienic declarations that are injected into code [actually declare
  stuff](https://github.com/masak/007/issues/88). We can cheat majorly at this
  one at first, as long as it works.

### Language track

* The first big thing to fix here is [an `examples/`
  directory](https://github.com/masak/007/issues/54). The champion for this one
  is **masak**.
    * [The format macro
      example](https://github.com/masak/007/issues/54#issuecomment-151440144)
      requires macros to be ready enough, which they sort of are (synthetic
      macros now work) and sort of are not (still waiting for quasi unquotes).
    * As part of this, we should also add the [man or boy
      test](https://github.com/masak/007/issues/22), to show that 007 is no
      worse than Algol.
* The second big thing is to [give the web page a big
  facelift](https://github.com/masak/007/issues/67), including more examples
  and interactive Qtrees. The champion on this one is **masak**.
    * This will require another parsing-related change: [generating a version
      of the Qtree output for tools](https://github.com/masak/007/issues/64),
      so that they can see e.g. macros in their unexpanded form.
    * masak would also like to take this opportunity to tie together some kind
      of doc-comments, automated tests, and documentation on the web page.

### General cleanup that should happen before v1.0.0

* [More Q node test coverage](https://github.com/masak/007/issues/52).
* Looking through Q names and similar names, [maximizing for
  consistency](https://github.com/masak/007/issues/81).
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
* [exceptions](https://github.com/masak/007/issues/65)
* [class declarations](https://github.com/masak/007/issues/32)
* [ADTs and pattern matching](https://github.com/masak/007/issues/34)
* [007 runtime in 007](https://github.com/masak/007/issues/51)
* [type checking](https://github.com/masak/007/issues/33)
* [Qtree visitors](https://github.com/masak/007/issues/26)
* [007 parser in 007](https://github.com/masak/007/issues/38)
* [syntax macros](https://github.com/masak/007/issues/80)

Two things would be worthy enough to produce a v2.0.0 version. Either 007 being
bootstrapping enough to have both a runtime and a parser written in itself; or
007 having all three of regular macros, syntax macros, and visitor macros.
