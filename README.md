# 007 [![Build Status](https://secure.travis-ci.org/masak/007.svg?branch=master)](http://travis-ci.org/masak/007)

007 is a small language created as a testbed for Perl 6 macros. Its goal as a
language is to inform the implementation of macros in Perl 6, by means of being
a faster-moving code base and easier to iterate on towards good solutions.

Rakudo already contains a rudimentary implementation of macros, but at this
point the most mature macro implementation for Perl 6 is embodied in 007.

The name "007" was chosen because the data type representing program fragments
is called `Q`.

## Get it

If you're just planning to be a 007 end user, `zef` is the recommended way to
install 007:

```sh
zef install 007
```

(If you want to install from source, see [the
documentation](http://masak.github.io/007/#installation-from-source).)

### Run it

Now this should work:

```sh
$ 007 -e='say("OH HAI")'
OH HAI

$ 007 examples/format.007
abracadabra
foo{1}bar
```

## Status

007 is currently in development.

The explicit goal is to reach some level of feature completeness for macros in
007, and then to backport that solution to Rakudo.

## Useful links

* [Documentation](http://masak.github.io/007/) (🔧  under construction 🔧 )
* [examples/ directory](https://github.com/masak/007/tree/master/examples)
* The [Roadmap](https://github.com/masak/007/blob/master/ROADMAP.md) outlines short- and long-term goals of the 007 project

To learn more about macros:

* [Hague grant application: Implementation of Macros in Rakudo](http://news.perlfoundation.org/2011/09/hague-grant-application-implem.html)
* [Macros progress report: after a long break](http://strangelyconsistent.org/blog/macros-progress-report-after-a-long-break)
* [Macros: what the FAQ are they?](http://strangelyconsistent.org/blog/macros-what-the-faq-are-they)

To learn more about 007:

* [Double oh seven](http://strangelyconsistent.org/blog/double-oh-seven) blog post
* [Has it been three years?](http://strangelyconsistent.org/blog/has-it-been-three-years) blog post
* This README.md used to contain a [pastiche of the cold open in Casino Royale (2006)](https://github.com/masak/007/tree/master/documentation/bond-pastiche.md), which was entertaining for some and confusing for others
