## 0.104.3 - (2016-**-**) ##

* User defined literal suffixes. Replaces the prior PoC-implementation of literal-type-redef pragmas with a much more generic usable construct.
* 


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
