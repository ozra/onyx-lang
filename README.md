# Onyx - enjoyable, practical, efficient programming #

## "tl;dr Summary" ##
_Enjoy writing an app that runs with trustworthy stability at speeds of C/C++
with just the effort of scripting or pseudo._

## Index ##

- Long Version
- What do you mean with scientific approach?
- Usages?
- Relation to Crystal
- Inspiration
- Why?
- What does it look like currently?
- Installing
- Documentation
- Community
- Contributing

## Long Version ##
- **Use scientific findings** for aspects of programming linguistics where research is available - focused on the human interaction and performance - in order to obtain:
    - _Highest possible productivity_ (which according to findings seem to require "enjoying the process")
    - Most _secure functioning_ possible produced by that effort
    - _Efficient code_ naturally by the common patterns.
- **Which from current findings and interpretations means**:
    - _Statically strongly type-checked_, currently with inheritance, mixins, re-openable types, sum-types, generics and type vars. _ALL types inferred_ unless explicit annotation wanted or demanded by coder. Nil is a type!
    - A _terse and clear indent based syntax_ with voluntary explicit block ends (wysiwyg + safety net).
        - A lot of research regarding the fundamentals of brain functioning used in programming also points to visual recognition of structure.
        - Both _alpha-style and symbol-style notation_ offered for many constructs for starters (might change).
        - _Underscores and dashes_ (`snake_case` and `dash-case`/`lisp-case`) are used interchangeably in identifiers per preference.
    - Common constructs gets _terser notation_. Syntax for traditional constructs that are not used often in practice today gets demoted.
        - Speed of coding the same algorithm in different languages has been shown to strongly correlate with sloc!
    - _OOP-based_, with functional-style coding fully possible where applicable (all of code if wished)
        - OOP _structuring_ has shown tendencies of yielding more stable code than others.
    - Immutable coding (_read "functional"_) has been shown to be more solid, hence facilitating that is also a focus in Onyx.
        + OOP for structured encapsulated mutations, aim for immutable-coding elsewhere - or don't - Onyx won't stop you unless you ask it to (opposite of Rust).
    - Advanced and hygienic _templates and macros_ to avoid boilerplate code.
    - _Compile quickly!_ (fast turn over).
        - Because waiting sucks. And being able to use logging as debug method needs fast compiles.
    - _Informative errors_ - the aim is for the compiler to be able to figure out as closely as possible what you _likely_ wanted and reduce debugging time.
        - The "Did you mean this:..." we've come to love in clang (compare gcc)
    - Compile to _efficient fast native code_.
        - We wouldn't code imperative if it wasn't for a need for speed!
- **Further**:
    - Dead _simple to call C code_ by writing bindings to it in Onyx.
    - Full _compatibility with Crystal_ modules - the language semantics core - (any Crystal module can be used seamlessly in the same project) to enlarge the module universe.
        - It's hard for novel new-kid-on-the-block languages to get established when there are no libs (well, even then). Sharing a module universe with another language facilitates both's usage in the real world.
    - During development, we'll _try_ to build "upgrade" functionality into the
    compiler to upgrade user code when syntax changes / gets depreceated. That way more serious code can be written without worrying about completely rewriting it. (I'm using it for side-projects in order to get real-world testing of it)

## What do you mean with scientific approach? ##
Well, there are very few quantitative, or otherwise, studies concerning coding directly. So admittedly the statement could be seen a kind of vague.
_The focus is on the actual performance of a human being reading and writing code to accomplish a task._

What is _not_ meant is "highly abstract functional lambda theory proofs yada yada".

Run down:

- Optimize for human parsing (aka "readability")- not computers parsing (_not_ lisp syntax uniformity)
- Human languages has exceptions to rules, so common constructs should get sugar if warranted.
- Any work should be enjoyable if we're smart about being human, so also coding.
- A language has to work for several scenarios, be _elegantly out of the way when prototyping_. Be _lovingly tough on disciplined code_ when demanded by coder.
- A language has to work for a wide range of coders. Any team bigger than one will have mixed levels of experience and requirements, while still working on the same code base.
- Writing idiomatic clear code should be the optimized way of writing code, no "creative smart coding" to speed things up. It's the compilers job to make it run fast!
- A bit of repeat of both above points: Not every coder, nor every _project_ suits the same syntactic style. Variations are needed to express the actual tasks of a certain implementation - DSL'ish requirements. For a given project, or even parts of project, a good style guideline should be set by/for teams. It should always be up to the developers. One (or even two variants) of an "official" Onyx style guide will be developed via discussions. Further, some _named style guides_ will be developed for different scenarios, so that some uniform choices to start off from exists - sort of "style guide templates". Sticking as close as possible to them will of course facilitate collaboration.
- Some basic syntactic aspects has been shown to be important for all humans _apt to math and especially coding_ (except females [!], exceptions noted) - and that is spatiality.

## Usages? ##
* _"Scripting"_: Because it compiles quickly and you don't _need_ to explicitly type annotate anything - it could be used in place of Python, Ruby, etc, for pretty much any task.
* _System coding_: Since binaries achieve speeds nearing C/C++, interfacing with C is dead simple, and hardening/strictening policies are available.
* _Game coding_: As above.
* _Business systems_: As above.
* _Analytics and math_: As above.
* **Well, anything really**, except hard real time applications (where you'd probably use C - however it is _fully possible_ in Onyx). But fingers crossed a side project of mine _might_ solve that.

## Relation to Crystal ##

Onyx uses Crystal backend semantics, type inference and LLVM-IR generation, and as such it's basically an alternative syntax / front-end. There are some additional semantics for more fine-grained control in some contexts. The actual machine code generation is done by LLVM, a god sent to language loving mankind!

It's not intended as a competitor to Crystal, different coders are attracted to the two. Crystal is a fantastic project and language, the gripe for some of us is its "stay true to Ruby" motto, which keeps it from being _the_ next generation language of choice, because of accumulated inconsistencies hindering free innovation.

Without the effort of the Crystal team, and the LLVM team, Onyx wouldn't be on its way _today_ - Onyx would still be one of my countless experimental implementations that come to a halt when other life matters are pressing, and then re-iterated again and again (I coded my first _transpiler_ [simple heuristic] to C/C++ in '99-'00, called Cython [_no relation to the project with the same name that came eight years later!_]). Well my first language when I was 12, but that was more of a tongue in cheek thing, called "CP Torsk 0.2" ("CP Cod 0.2"). Hmm, for the Amiga if I remember correctly, maybe it was the Commodore 64.

_**Crystal** is for those who do love the Ruby way._

_**Onyx** is for those who simply want a language as fun, productive and secure as possible_. The path to this is by building on scientific studies on computer linguistics (_something strangely lacking in the community!!_), inspiration from other languages created to date, the common patterns and problems faced in today's coding - and _that's where **you come in to the picture**_. _Your input is what will shape the language._
Because of Onyx compatibility goal with Crystal, some minor trade offs might
have to be done, but the gains of a greater module universe, being a
"language family", will likely be a much bigger pro.

## Inspiration ##
Inspiration is taken from languages as diverse as Crystal (obviously), Haskell,
Nim, LiveScript, Go, Rust, Lisp, Erlang, Python, Scala, C++, etc. Sometimes syntax, sometimes semantics, sometimes just an idea inspired by some concept.

## Why? ##

- You want to write code as fast as pseudo.

- You want code to be as readable as a grocery list. (_Worst analogy yet!_)

- You want it to compile quickly while developing.

- You want that code to execute at speeds of C/C++.

- You want to be able to increase demands and strictness on code _when needed_.

- Onyx loves you unconditionally - and so won't imprison you; an onyx-to-crystal converter is one future aim - so that you can opt over to that if you'd wish to for some reason.

## What does it look like currently? ##

For Crystalers, the front page example in Onyx will be very familiar:
```onyx
-- A very basic HTTP server
require "http/server"

server = HTTP::Server 8080, |request|
  HTTP::Response.ok "text/plain", "Hello world, got {{request.path}}!"

say "Listening on http://0.0.0.0:8080"
server.listen
```

A rather contrived example, just to show some basic constructs:
```onyx

-- types inherits `Class` by default if nothing else specified

type Greeter
    greeting–phrase = "Greetings,"
    -- greeting–phrase Str = "Greetings," -- a more explicit way

    init() ->
        -- do nothing - just keep defaults

    init(@greeting–phrase) ->
        -- do nothing here. Sugar for assigning a member did all we need!

    -- above could have been written more verbose; in many different levels.
    -- def init(greeting–phrase Str) ->
    --     @greeting–phrase = greeting–phrase
    -- end–def

    -- define a method that greets someone
    greet(who–or–what) ->!  -- returns nothing
        say make–greeting who–or–what
        -- say(make–greeting(who–or–what)) -- parentheses or "juxtapos-calls"

    -- a method that constructs the message
    make–greeting(who–or–what) ->
        "{{@greeting–phrase}} {{who–or–what}}"  -- returns last expression
    end  -- you can explicitly end code block at will

    -- All on one line works too of course:
    -- make–greeting(who–or–what) -> "{{@greeting–phrase}} {{who–or–what}}"

end–type -- you can be even more explicit about end–tokens at will

type HelloWorldishGreeter << Greeter
    greeting–phrase = "Hello"
end

greeter = HelloWorldishGreeter("Goodbye cruel")
greeter.greet "World" --  => "Goodbye cruel World"
-- greeter.greet_someone "World" -- separator (-|–|_) completely interchangable

```


## Status ##

* Onyx is in "design stage"/"RFC stage"/alpha while settling it. Input (RFC's) on the syntax and language in general are **highly welcomed**!
* Currently the basic first syntax ideas are implemented, it only has about two weekstotal time of coding on it yet you see. Several keywords to do the same thing are available many times, until agreement on what to keep and what to ditch comes up.
* Some syntax doesn't have semantics yet, until it gets carved deeper in the onyx. For example declaring func's `pure`, `method`, `lenient`. And mutable/immutable modifiers on parameters and variables. Value vs ref control also.
* Macros and templates syntax has not been worked on at all yet. Semantics are in place via Crystal AST, so all that's needed is parsing it.
* The "core semantics language" Crystal is in alpha, close to beta.
* **It will need a few more weeks of coding before it's ready for public consumption, I think.**

## Roadmap ##

* => Conception
* Implement first basic functionality of "open draft".
* Work on the formatter in order to enable the "Syntax Preference Study"
* Continually nail down core syntax and semantic concepts while implementing syntax, iteratively.
* Implement final core semantics according to agreed upon
    - PR as much as is accepted directly to Crystal code base
* Important: cleanup and refactor after all PoC changes and implementations
* Iron out bugs and do final language tweaks
* Iron out bugs more
* => Onyx 1.0 - world domination ;-)
* Improve low level aspects of language core
    - PR as much as is accepted directly to Crystal code base:
    - Tailor made GC for optimal throughput and lowest latency
        + I'm already working sporadically on a conceptual GC specifically targeting 64 bit, that - if it turns out as well as I hope - might blow most other things out of the water, _both_ throughput-wise _and_ latency-wise. But don't hold your breath on this one. I'll keep it private until there's something to show for, or it turns out to be a disaster (spare time goes in to Onyx atm).
    - Possibly tailor made co-routines low level code (_if_ LLVM reveals IR facilitating that)
    - facilitate different levels of manual memory management when wanted
        + If above mentioned GC works out as planned, it will probably be faster and have lower latency than manual memory management - in that case this point is severely moot. But once again: long way there.
    - => Onyx 1.2+

## Installing ##

For the time being:

- You might want the highlighter for Sublime Text: `git clone https://github.com/ozra/sublime-onyx.git` (it should be easily ported to Atom, Text Mate, etc., please think about if you're prepared to maintain it, if deciding to do so, or leave it to someone who wants too - it's annoying with out-of-date add-ons for everyone). The Sublime highlighter will be kept up to date with changing language constructs.
- Install Crystal (compiler source is in crystal for easy sharing)
- clone repo `git clone https://github.com/ozra/onyx-lang.git`
- `make`
- Running the freshly built compiler currently looks a mouthful, in order to ease the pain of 3rd-party libs, onyx cornerstone libs ("stdlib"), etc.
`--stats` and `--verbose` can be nice when hacking on it.
Change `./spec/onyx-compiler/first-test.ox` to your application main file to compile your onyx project. Use `release` command instead of `devel` to compile with optimizations.
```
CRYSTAL_PATH=./src \
      .build/onyx devel --stats --verbose --link-flags "-L/opt/crystal/embedded/lib" \
      ./spec/onyx-compiler/first-test.ox
```

## Documentation ##

- For the language itself - follow the issues in GitHub. Since the language is taking shape and changing - that serves both as current documentation and a way of chipping in. Syntax constructs are described there.
- For the standard library, refer to Crystals docs for now - the lib is shared.

## Community ##

Use "issues" for now. Add RFC's or ideas already if you feel like it!
Read the general [Contributing guide](https://github.com/ozra/onyx-lang/blob/master/Contributing.md),
(it's very terse, you will get through it!)

## Contributing ##

Read the general [Contributing guide](https://github.com/ozra/onyx-lang/blob/master/Contributing.md),
(it's very terse, you will get through it!) and then:

The code base follows the same guide lines and style as Crystal - since it
simplifies features making its way back into the Crystal project when reasonable.

1. Fork it ( https://github.com/ozra/onyx-lang/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

**Do some sausage making before commit** - we want one commit: "Add this-and-that-feature", _not_: ~~"changed x", "fix y", "forgot trailing spaces", "this-and-that-feature done"~~

