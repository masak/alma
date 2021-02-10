# Alma [![Build Status](https://secure.travis-ci.org/masak/alma.svg?branch=master)](http://travis-ci.org/masak/alma)

Alma is a small language created as a testbed for Raku macros. Its goal as a
language is to inform the implementation of macros in Raku, by means of being
a faster-moving code base and easier to iterate on towards good solutions.

Rakudo already contains a rudimentary implementation of macros, but at this
point the most mature macro implementation for Raku is embodied in Alma.

Alma was previously known as "007", in reference to the "Q" data structure
which represents program fragments.

## Get it

If you're just planning to be a Alma end user, `zef` is the recommended way to
install Alma:

```sh
zef install alma
```

(If you want to install from source, see [the
documentation](http://masak.github.io/alma/#installation-from-source).)

### Run it

Now this should work:

```sh
$ alma -e='say("OH HAI")'
OH HAI

$ alma examples/format.alma
abracadabra
foo{1}bar
```

## Status

Alma is currently in development.

The explicit goal is to reach some level of feature completeness for macros in
Alma, and then to backport that solution to Rakudo.

## Useful links

* [Documentation](http://masak.github.io/alma/) (🔧  under construction 🔧 )
* [examples/ directory](https://github.com/masak/alma/tree/master/examples)
* The [Roadmap](https://github.com/masak/alma/blob/master/ROADMAP.md) outlines short- and long-term goals of the Alma project

To learn more about macros:

* [Hague grant application: Implementation of Macros in Rakudo](http://news.perlfoundation.org/2011/09/hague-grant-application-implem.html)
* [Macros progress report: after a long break](http://strangelyconsistent.org/blog/macros-progress-report-after-a-long-break)
* [Macros: what the FAQ are they?](http://strangelyconsistent.org/blog/macros-what-the-faq-are-they)

To learn more about Alma:

* [Double oh seven](http://strangelyconsistent.org/blog/double-oh-seven) blog post
* [Has it been three years?](http://strangelyconsistent.org/blog/has-it-been-three-years) blog post
* This README.md used to contain a [pastiche of the cold open in Casino Royale (2006)](https://github.com/masak/alma/tree/master/documentation/bond-pastiche.md), which was entertaining for some and confusing for others
