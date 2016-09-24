## ongoing... - (2016-09-??) ##

* now use `x.i-type`, `x.inst-type`, `x.rtype` or any of the other trial variations for getting the current run-time type instead of `x.class`


## 0.192.21 - (2016-09-24) ##

* ~~Change~~ Add char-literal syntax `_"x"` (less symbolic noise), for evaluation.
* Fix missed case for "hard-tuple-indexing" type inference
* Code cleanups
* Re-introduce I32, F64, etc. type aliases
* Removed "nil-ensurer" for `->!` functions, since Crystal has implemented similar code as of late.
* Refined terser "backslash fragment syntax", aka "The Cigar Walk Fragment Syntax": `x.map \v\ v + 2`, etc. Both previous syntaxes are still in - for now.
* Touched up the `make boostrap` a bit more. It should now install onyx simply on any _debian derivative_. Unfortunately no other OSes are supported in the installer _yet_. Please be a doll and help out!
* Give up the restriction of one-letter generic parameter names. Long type-var names now allowed.
* Finally removed the awkwardly ruled angular tuple syntax (`tup = <1, 2, 3>`)
* Build-time flags used for Onyx-compiler dev for easy dissection in the event of future compatibility problems with crystal lib.
* Changed function def syntax: return type goes _after_ arrow, according to the RFC-suggestion.
* Removed archaic identifier-mangling in crystal lexer
* `in` / `in?` operator. As usual, many variants to begin with: `x in y`, `x in? y`, any of them goes in the following combos too: `x not in y`, `x is in y`, `x isnt in y`. Only reasonable to keep really is `not in`, of the modifying variants.


## 0.191.12 - (2016-09-19) ##

* New syntax for external name specification in args `foo(outer => inner SomeType = some-value) ->`.
* Added named tuples syntax.
* Doc-generation prettier and Onyx-friendlier rendering and pretty-urls.
* The complex type-name babeling system is eliminated and replaced with dead simple solution. Much easier to maintain. Much more efficient.
* Improved AST-dump and terse AST-dump for easier compiler hacking and debugging.
* Some bugs squashed
* Some refactorings and clean ups
* Fixed bug with type-inference for results of constant number indexed tuples
* More small stuff, forgotten during summer...


## 0.106.1 - (2016-05-11) ##

* Optimized compilation further. About 600% vs "initial". 20% lower RAM use.
* TIME FOR SUMMER BREAK ;-)


## 0.106.0 - (2016-05-09) ##

* `Self` now returns to the "current type", `this` refers to "this instance". `self` is a reserved word to catch mistakes by coders used to langs with reversed connotations.
* `none?` and `!`/`not` are now language-constructs / pseudo-methods instead of methods, helping nil-inference.


## 0.105.7 - (2016-05-07) ##

* New variant of tuple delimiters syntax: `<[el, em, ents]>`
* `%n` (where n = 1 - 9) can be used in addition to `_n` for auto-paramed fragments. The underscore variant will probably be dropped.
* Type syntax rewritten to "style type D" (see issue #18)
* Semantics changed for types so that re-opening without using `extend` errors. Also extend on non-defined type errors. Found a bug in code immediately after running with this!


## 0.105.6 - (2016-05-05) ##

* Some minor re-factorings in some places
* `Type[Typ]` has been eliminated because of clash with type-level `[]` macros, and const-indexing. Now available `Type<Typ>` and `Type‹Typ›` (unicode, not decided delimiters, just for test currently)
* Modules `extend Self` "by default". "traits", mixed in to types, don't have this behaviour.
* Improved func-parsing in some edge-cases
* The alternative to use `def`-keyword before funcs has been removed.
* Improved auto-parametrization for "fragments".
* It's no longer allowed to declare instance-vars without `@` in the type-def. Just use `@name` from now on.
* Fixed edge-cases for alternative fragment-syntax (the backslash variant)
* Fix rendering edge-cases of identifiers in stylizer/to-s
* Now indentation syntax is available for types too. Very clean way of building trees etc.


## 0.105.5 - ? ##

## 0.105.4 - (2016-04-27) ##

* Optimized codegen, now compile speed is up to 400% greater for devel (!) Can't believe the timings. More tests required.
* Fixes to certain cases of babeling in cross-language macroing
* implements? works properly.


## 0.105.3 - (2016-04-27) ##

* (WIP) Doc-gen - details regarding babeling left to fix
* Attempt at optimizing codegen, at least it avoids writing about 800 temp files now (speed up? Not measurable :-/ ).
* `implements?` use either method-name or trait as arg. some edge cases to fix.


## 0.105.2 - (2016-04-20) ##

* Tiny touches regarding safety-belting compilation and lib-paths, better than nothing
* StringPooling in Onyx-lexer added too.


## 0.105.1 - (2016-04-18) ##

* User defined literal suffixes, stage 1, WIP.
* "Upgraded" to new type-def member-vars inference.


## 0.104.2 - (2016-04-11) ##

* Fix ternary-if edge-cases
* Stronger checking on globals with name-babeling


## 0.104.1 - (2016-04-09) ##

* First implementation of macros working with (few) tests. Expect bugs!
* Nil-sugar call-chain: `x = foo?bar?qwo` => `x = foo.try ~.bar.try ~.qwo`. Methods with final question mark are used if available, else plain-name version (since de-facto `method?` returns Type|Nil.
* Internal translations ("babelfishing") of type names and method names where needed between Onyx <-> Crystal worlds. WIP. Expect bugs.


## 0.104.0 - (2016-03-27) ##

* **(breaking change)** Named arguments have been changed back to `name: value`. Space after colon is required! (`name:key` is shorthand subscripting with string key)


## 0.103.0 - (2016-03-26) ##

* **(breaking change)** New trial syntax A for Tuple literals: `<my, tup>`.
* **(breaking change)** New trial syntax B for Tuple literals: `(my, tup)`.
* New call syntax alternative: indented args. Use for DSL-like code (Temel for instance).


## 0.102.0 - (2016-03-24) ##

* **(breaking change)** Renamed operator `===` to `~~` and added negated version: `!~~` (#67)
* Switched functionality of `*` and `**` visibility modifier. `*` now means "protected" (#62)
* Fixed bug in one line functions beginning with `!` (was treated as nil-sugar-func)
* Onyx-specific additions to standard types relating to comparisons


## 0.101.0 - (2015-11-20) ##
* Realized there should be a change log at some point ;-)
