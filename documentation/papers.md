## Dylan

<dl>
  <dt>D-Expressions: Lisp Power, Dylan Style</dt>
  <dd><a href="http://people.csail.mit.edu/jrb/Projects/dexprs.pdf">A 2001 paper about procedural macros in Dylan</a></dd>
</dl>

## PLOT

David Moon (Common Lisp contributor, inventor of ephemeral garbage collection, co-author of Flavors and Emacs, and co-designer of Dylan) is/was working on a language with goals that seem similar to Alma's.

<dl>
  <dt>Programming Language for Old Timers</dt>
  <dd><a href="http://users.rcn.com/david-moon/PLOT/">Language web page</a></dd>
  <dt>Genuine, Full-power, Hygienic Macro System for a Language with Syntax</dt>
  <dd><a href="http://users.rcn.com/david-moon/PLOT/Moon-ILC09.pdf">2009 talk about the language</a></dd>
</dl>

## Scala

Eugene Burmako implemented macros in Scala. (I don't know the full picture here, except that Scala went through two generations of macros.)

<dl>
  <dt>Scala Macros: Let Our Powers Combine!</dt>
  <dd><a href="https://infoscience.epfl.ch/record/186844/files/2013-04-22-LetOurPowersCombine.pdf">On How Rich Syntax and Static Types Work with Metaprogramming</a></dd>
  <dt>Rethinking Scala macros</dt>
  <dd><a href="http://scalamacros.org/paperstalks/2014-03-02-RethinkingScalaMacros.pdf">a 2014 talk</a></dd>
</dl>

## Julia

<dl>
  <dt>Julia's macros, expressions, etc. for and by the confused</dt>
  <dd><a href="http://gray.clhn.org/dl/macros_etc.pdf">2014 talk</a></dd>
</dl>

## Rust

<dl>
  <dt>A Love Letter to Rust Macros</dt>
  <dd><a href="https://happens.lol/posts/a-love-letter-to-rust-macros/">Blog post by Hilmar Wiegand (happens)</a></dd>
</dl>

## Racket

<dl>
  <dt>Macros</dt>
  <dd><a href="https://docs.racket-lang.org/guide/macros.html">From the Racket Guide</a></dd>
  <dt>Fear of Macros</dt>
  <dd><a href="http://www.greghendershott.com/fear-of-macros/">A practical guide to Racket macros</a></dd>
</dl>

## Macro hygiene

<dl>
  <dt>A Theory of Typed Hygienic Macros</dt>
  <dd><a href="http://www.ccs.neu.edu/home/dherman/research/publications/dissertation.pdf">David Herman's 2010 dissertation</a></dd>
</dl>

## Type systems as macros

<dl>
  <dt>Type Systems as Macros</dt>
  <dd><a href="http://www.ccs.neu.edu/home/stchang/pubs/ckg-popl2017.pdf">a 2017 paper</a></dd>
  <dt>A Programmable Programming Language</dt>
  <dd><a href="http://silo.cs.indiana.edu:8346/c211/impatient/cacm-draft.pdf">a 2017 draft of a paper</a></dd>
  <dt>Macros as Multi-Stage Computations: Type-Safe, Generative, Binding Macros in MacroML</dt>
  <dd><a href="https://www.researchgate.net/profile/Walid_Taha2/publication/2359751_Macros_as_Multi-Stage_Computations_Type-Safe_Generative_Binding_Macros_in_MacroML/links/0c960539d76f3e44a5000000.pdf">a 2001 paper</a></dd>
  <dt>Safely Composable Type-Specific Languages</dt>
  <dd><a href="https://apps.dtic.mil/dtic/tr/fulltext/u2/1057425.pdf">a 2014 paper</a></dd>
</dl>

## Oleg Kiselyov

<dl>
  <dt>Systematic Macro programming</dt>
  <dd><a href="http://okmij.org/ftp/Scheme/macros.html#Macro-CPS-programming">Macros compose better if written in a continuation-passing style</a></dd>
</dl>

## Programming language design

<dl>
  <dt>Next-Paradigm Programming Languages: What Will They Look Like and What Changes Will They Bring?</dt>
  <dd><a href="https://arxiv.org/pdf/1905.00402.pdf">2019 paper</a></dd>
  <dd><a href="https://news.ycombinator.com/item?id=19803379">HN discussion</a></dd>
</dl>

## Programming language history

<dl>
  <dt>The use of sub-routines in programmes</dt>
  <dd><a href="http://www.laputan.org/pub/papers/wheeler.pdf">1952 paper by David Wheeler</a></dd>
</dl>

## Papers from diakopter

<dl>
  <dt>Size-Change Termination and Constraint Transition Systems </dt>
  <dd>Size-Change Termination is <a href="http://www2.mta.ac.il/~amirben/sct.html">a method of proving the termination of computer programs</a></dd>
  <dt>Functional Pearl: Theorem-Proving for All</dt>
  <dd><a href="https://arxiv.org/pdf/1806.03541.pdf">Equational Reasoning in Liquid Haskell</a></dd>
  <dt>(The closest thing diakopter could find to) how to write a type checker</dt>
  <dd><a href="https://github.com/jozefg/higher-order-unification/blob/master/explanation.md">An Explanation of Unification.hs</a></dd>
  <dt>OMeta: an Object-Oriented Language for Pattern Matching</dt>
  <dd>diakopter said I should read <a href="http://www.tinlizzie.org/~awarth/papers/dls07.pdf">this one</a> after I explained my mutable parser ideas to him. he added "when you're defining the grammar, the actions aren't just parser combinators, they can run any arbitrary code/application/reduction or chain thunks. I think the solution to making a parse-time-extensible grammar/parser is to get rid of the "compilation" step entirely (as OMeta does), and make the grammar/parser an object whose entire state and API is available to code in the grammar actions. so the parser wouldn't try to "optimize" at all, but instead act fully as an interpreter. so if you add/replace a rule to the grammar, the point at which it's supposed to enact the change can swap in a modified grammar on a stack"</dd>
  <dt>Formal verification of AI software</dt>
  <dd><a href="https://ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/19890015440.pdf">"this paper is awesome"</a></dd>
  <dt>Compiling with continuations or without? Whatever</dt>
  <dd><a href="https://www.researchgate.net/profile/Youyou_Cong/publication/335277314_Compiling_with_Continuations_or_without_Whatever/links/5d5c6702299bf1b97cfa1893/Compiling-with-Continuations-or-without-Whatever.pdf?origin=publication_detail">some talk slides</a></dd>
  <dt>An algebraic approach to typechecking and elaboration</dt>
  <dd><a href="https://bentnib.org/docs/algebraic-typechecking-20150218.pdf">a paper</a>. diakopter says "the final question of the last slide is relevant"</dd>
  <dd><a href="https://www.youtube.com/watch?v=ypU3j6Wpkoo">talk video</a></dd>
</dl>
