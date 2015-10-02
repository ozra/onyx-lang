Onyx - programming language
=======

## "tl;dr Summary" ##
_Enjoy writing an app that runs with trustworthy stability at speeds of C/C++ 
with just the effort of scripting or writing pseudo._

## Long version ##
* Use scientific findings for aspects of programming linguistics where research is available, in order to obtain:
    - Highest possible productivity (which according to findings seem to require "enjoying the process")
    - Most secure functioning possible produced by that effort
    - Efficient code naturally by the common patterns.
* Which from current findings, atm, means:
    - Find out what is done most often - assign shorter notation / operators for that, re-think syntax for traditional constructs that are not used often in practice today.
    - A terse and clear indent based syntax with voluntary explicit block ends (wysiwyg + safety net).
    - Statically type-checked, with inheritance, mixins, re-openable types, generics and type vars, but with all types inferred unless explicit annotation wanted or demanded by coder.
    - OOP-based, with functional-style coding fully possible where applicable (all of code if wished)
    - Dead simple to call C code by writing bindings to it in Onyx.
    - Advanced and hygienic templates and macros to avoid boilerplate code.
    - Compile quickly! (fast turn over).
    - Informative errors - the aim is for the compiler to be able to figure out as closely as possible what you _likely_ wanted and reduce debugging time.
    - Compile to efficient fast native code.
* Further goals:
    - Full compatibility with Crystal modules - the language semantics core - (any Crystal module can be used seamlessly in the same project) to enlarge the module universe.
* Usages?:
    - "Scripting": Because it compiles extremely quickly and you don't _need_ to explicitly type annotate anything - it could be used in place of Python, Ruby, etc, for pretty much any task.
    - System coding: Since binaries achieve speeds nearing (some times beating) C/C++, interfacing with C is dead simple, and hardening/strictening policies are available.
    - Game coding: As above.
    - Business systems: As above.
    - Analytics and math: As above.
    - Well, anything really, except hard real time applications (where you'd probably use C - however it is _fully possible_ in Onyx)

Onyx will be considered "design stage"/pre alpha while settling it. Input (RFC's) on the syntax and language in general is **highly welcomed**!
It's not intended as a competitor to Crystal, but rather a different approach to the same linguistic "core".
Crystal is a fantastic project and language, but the "stay true to Ruby" keeps
it from being _the_ next generation language of choice, because of accumulated inconsistencies.

Crystal is for those who do love the Ruby way.

Onyx is for those who simply want as productive and secure a language as possible by
building on scientific studies on computer linguistics (_something strangely
lacking in the community!!_), all languages created to date, and the common
patterns and problems faced in today's coding.
Because of the compatibility goal, some minor trade offs might have to be done, but
this goal will likely be a bigger pro.

As such it should be mentioned that the Crystal project is the main effort that
makes Onyx possible - without it, Onyx would still be one of my countless
experimental implementations that come to a halt and are re-iterated again and again.
Thanks to Crystal, Onyx can be implemented as a simple front-end, parser and
AST-rewriter, sharing the heavy bits of type inference, code generation and
standard-lib / modules.

Inspiration is taken from languages as diverse as Crystal (obviously), Haskell,
Rust, Nim, LiveScript, Go, Lisp, Python, C++, etc. - only "the best parts",
integrated, not hodge-podgy!

Why?
----

You want to write code as fast as pseudo.

You want it to compile quickly while developing.

You want that code to execute at speeds of C/C++.

You want to be able to increase demands and strictness on code _when needed_.


What does the current syntax draft look like?
--------------------------------------

```
-- Concise example to come! :)
```

Status
------

* The project is in very early experimental alpha "concept design" stage. The
 intention is that it remans in design stage until enough input and consensus
 from different developers to get the language in a "collectively correct
 direction" has been acquired.
* Consider Onyx a "private repo" for the nearest time being.
* The "core semantics language" Crystal is in alpha, close to beta.
* Clarity of error messages if most lacking atm (aside from syntax not being set
  in stone). That's a project that will be contributed directly into Crystal
  where possible, else in Onyx only (where applicable).

Installing
----------

Instructions to come.


Documentation
----------

To come. For standard library, refer to Crystals docs - the lib is shared.

Community
---------

Use "issues" for now. Add RFC's or ideas already if you feel like it!

Contributing
---------

Read the general [Contributing guide](https://github.com/ozra/onyx-lang/blob/master/Contributing.md), and then:
The code base follows the same guide lines and style as Crystal - since it
simplifies features making its way back into Crystal when reasonable.

1. Fork it ( https://github.com/ozra/onyx-lang/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request
