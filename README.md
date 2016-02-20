# Onyx - enjoyable, practical, efficient programming #

## "tl;dr Summary" ##
_Enjoy writing an app that runs with trustworthy solid stability at speeds of C/C++ with the sole effort of scripting or pseudo coding._

## Index ##

- Distilled Version
- Philosophical Version
- What do you mean with scientific approach?
- Run Down
- Usages?
- Relation to Crystal
- Inspiration
- Why?
- What does it look like currently?
- Installing
- Documentation
- Community
- Contributing

## Distilled Version ##

- Multi-paradigm
    + OOP _structured_
    + respectful of functional style coding
    + Full on mutating imperative knuckles fully available
- Strong type system
    + Types inferred globally.
    + Manual annotation where wanted.
    + Inheritance (_single! - no deadly diamond of death dilemma_)
    + Traits/mixins
    + All types re-openable (aka monkey patchable)
    + Sum-types (union types)
    + Nil is a type - no weak ass C++/Java bullshit piss typing
    + Polymorphism and function overloading - and when type is known: no cost over a straight call (and it might be inlined too). The code is very efficient (you can't make it faster yourself in C)
    + Generics and type-vars - because Go is retarded.
- Almost everything can be changed by coder
    + Most constructs in the language is changeable, just an override away
    + Operator overloading - of course
    + Iterators are implemented as methods, imperative / structural notation available also because of its commonality. And no, there's no execution overhead.
- Clean readable and writeable syntax
    + All the common forms of _casing_ is allowed interchangeably (without conflicts): `endash—case`, `dash-case`, `snake_case`, `camelCase`. This may change!
    + UFCS will _likely_ be implemented. Discuss in issue!
- FFI: Using C-API libs is piece of cake
- Garbage Collected (_even I_, have accepted it as the way of the future - now: let's just make it even faster [post 1.0 target])
- Macros and templating (_* in the works_)
- _Helpful_ error messages (_* as soon as the language spec has stabilized_)
- Fast!
    + Pretty fast compiling
    + Really fast executable
    + I won't stop optimizing until hell freezes over. - The compiler should make things fast - you should focus on keeping your code maintainable.

## Philosophical Version ##

- **Use scientific findings** for aspects of programming linguistics where research is available - focused on the human interaction and performance - in order to obtain:
    - _Highest possible productivity_ (which according to findings seem to require "enjoying the process")
    - Most _secure functioning_ possible produced by that effort
    - _Efficient code_ naturally by the common patterns.
- **Which from current findings and interpretations means**:
    - _Statically strongly type-checked_, currently with inheritance, mixins, re-openable types, sum-types, generics, type vars and polymorphism. _ALL types inferred_ unless explicit annotation wanted or demanded by coder. Nil is a type!
    - A _terse and clear indent based syntax_ with voluntary explicit block ends (wysiwym + safety net).
        - A lot of research regarding the fundamentals of brain functioning used in programming also points to visual recognition of structure.
        - Both _alpha-style and symbol-style notation_ offered for many constructs for starters (might change).
        - _Underscores and dashes_ (`snake_case` and `dash-case`/`lisp-case`) are used interchangeably in identifiers per preference. (for completeness, I've implemented an experimental transparent humpCase integration too)
    - Common constructs gets _terser notation_. Syntax for traditional constructs that are not used often in practice today gets demoted.
        - Speed of coding the same algorithm in different languages has been shown to strongly correlate with sloc (or lloc)!
    - _OOP-based_, with functional-style coding fully possible where applicable (all of code if wished)
        - OOP _structuring_ has shown tendencies of resulting in more stable code than others.
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
    - Full _compatibility with Crystal_ modules - the language AST core - (any Crystal module can be used seamlessly in the same project) to enlarge the module universe.
        - It's hard for novel new-kid-on-the-block languages to get established when there are no libs (well, even then). Sharing a module universe with another language facilitates usage of both in the real world.
    - During development, we'll _try_ to build "upgrade" functionality into the
    compiler to upgrade user code when syntax changes / gets deprecated. That way more serious code can be written without worrying about completely rewriting it. (I'm using it for side-projects in order to get "real-world testing" of it)

## What do you mean with scientific approach? ##

Well, there are very few quantitative - or otherwise - studies concerning coding directly. So admittedly the statement could be seen as kind of vague.
_The focus is on the actual performance of a human being reading, writing and reasoning on code to accomplish a task._

What is _not_ meant is "highly abstract functional lambda theory proofs from outer space when the cat is and isn't in the cradle and/or you give a shit".

Now, I've posted my share of dis-attributed "Einsten"-quotes in social media, so I can hardly claim to be a scientist. I rely on you helping out in interpreting studies and verifying sources, if you feel so inclined.

### Run Down ###

- Optimize for human parsing (aka "readability") - not computers parsing (_not_ lisp syntax uniformity)
- Human languages has exceptions to rules, so common constructs should get sugar if warranted.
- Any work should be enjoyable if we're smart about being human, so also coding.
- A language has to work for several scenarios, be _elegantly out of the way when prototyping_. Be _lovingly tough on disciplined code_ when demanded by coder.
- A language has to work for a wide range of coders. Any team bigger than one will have mixed levels of experience and requirements, while still working on the same code base.
- Writing idiomatic clear code should be the optimized way of writing code, no "creative smart coding" to speed things up. It's the compilers job to make it run fast!
- A bit of repeat of both above points: Not every coder, nor every _project_, nor every _part_ of a project, suits the same syntactic style. Variations are needed to express the actual tasks of a certain implementation - DSL'ish requirements. For a given project, or even parts of project, a good style guideline should be set by/for teams. It should always be up to the developers. One (or even two variants) of an "official" Onyx style guide will be developed via discussions. Further, some _named style guides_ will be developed for different scenarios, so that some uniform choices to start off from exists - sort of "style guide templates". Sticking as close as possible to them will of course facilitate collaboration.
- Some basic syntactic aspects has been shown to be important for all humans _apt to math and especially coding_ (except females [!], exceptions noted) - and that is spatial cognition.

## Usages? ##

* _"Scripting"_: Because it compiles quickly and you don't _need_ to explicitly type annotate anything - it could be used in place of Python, Ruby, etc, for pretty much any task.
* _System coding_: Since binaries achieve speeds nearing C/C++, interfacing with C is dead simple, and hardening/strictening policies are available.
* _Game coding_: As above.
* _Business systems_: As above.
* _Analytics and math_: As above.
* **Well, anything really**, except hard real time applications (where you'd probably use C - however it is _fully possible_ in Onyx). But fingers crossed a side project of mine _might_ solve that.

## Relation to Crystal ##

Onyx shares AST, most semantics and IR generation with Crystal. There are some additional semantics for more fine-grained control in some contexts. The actual machine code generation is done by LLVM, a god sent to language loving mankind! Currently, by internally flagging AST-nodes, Onyx can compile both onyx and crystal sources within the same program.

It's not intended as a competitor to Crystal, different coders are attracted to the two. Crystal is a fantastic project and language, the gripe for some of us is its "stay true to Ruby" motto, which keeps it from being _the_ next generation language of choice, because of accumulated inconsistencies hindering free innovation.

_Without the fantastic efforts of the Crystal team and the LLVM team, Onyx wouldn't be on its way today_. Onyx would still be one of my countless experimental implementations that come to a halt when other life matters are pressing, and then re-iterated again and again (I coded my first _transpiler_ [simple heuristic] to C/C++ in '99-'00, called Cython [_no relation to the project with the same name that came eight years later!_]). Well my first language when I was 12, but that was more of a tongue in cheek thing, called "CP Torsk 0.2" ("CP Cod 0.2"). Hmm, for the Amiga if I remember correctly, maybe it was the Commodore 64.

_**Crystal** is for those who do love the Ruby way._

_**Onyx** is for those who simply want a language as fun, productive and secure as possible_. The path to this is by building on scientific studies on computer linguistics, and especially, humans reasoning and interaction with code (_something strangely lacking in the industry!_), inspiration from other languages created to date, the common patterns and problems faced in today's coding - and _that's where **you come in to the picture**_. _Your input is what will shape the language._
Because of Onyx compatibility goal with Crystal, some minor trade-offs might
have to be made, but the gains of a greater module universe, being a
"language family", will likely be a much bigger pro.

## Inspiration ##

Inspiration is taken from languages as diverse as Crystal, Haskell,
Nim, LiveScript, JavaScript, Go, Rust, Lisp, Erlang, Python, Scala, C++, LLVM-IR(!), etc. Sometimes syntax, sometimes semantics, sometimes just an idea inspired by some concept.

## Why? ##

- You want to write code as fast as pseudo.

- You want code to be as readable as a grocery list. (_Worst analogy yet!_)

- You want it to compile quickly while developing.

- You want that code to execute at speeds nearing C/C++.

- You want to be able to increase demands and strictness on code _when needed_.

- You want to simply integrate C-libraries or libraries with C API's.

## Why not \[language X\]? ##

This section is without doubt flame-war material. Feel free to chip in and I'll revise the texts.

### Why not C++? ###

Oh, come on! I've coded in that for 17 years. Enough!

### Why not Rust? ###

It sticks with an archaic syntax: the braces style, which could be seen as a minor point of course, and debatable (the studies I interpret as supporting significant indent could be challenged).
Rust is way to clumsy and strict for coding up prototypes in.
It relies on manual memory management, something even I've come to believe can be replaced with full throughput and predictable latency very soon.
There aren't yet any (afaik) statistics on time consumption working in Rust, but my guess is that you'll have to pay 10 people to do the job of 1 to reach the same deadline in Rust (ok - don't quote me on that - it was probably quite unfair!). Time that could be spent making a working solution, revising algorithms, instead of a solution never causing null exceptions but still not working. By the way, null exceptions doesn't happen in Onyx (unless you start using _pointers irresponsibly_).

### Why not Go? ###

Same goes for syntax here.
It still hasn't got generics, which _really_ is a must have - I can't see how they don't realize that. The main reason not including it seems to be fear of complicating the compiler. God. With their budget? (mine is currently zero, and Crystals' about $4K for years of work).
Further, the type inference in Go is next to non-existent. In Onyx you rarely have to type anything at all - unless you want to (it is good practise).
Go doesn't have macros or templatish constructions - also a big fail as far as I'm concerned.
It also (correct me if I'm wrong) allow assigning `nil` to any reference. In Onyx any variable that can be nil must also have the Nil type summed in. The type system will therefore catch any place where you access something that could be nil and ensure you handle it.

### Something else? ###

Any other contender you think is better? Tell us. So Onyx can be made better.


## What does it look like currently? ##

GitHub doesn't accept highlighters until there are hundreds of repositories using it, so to view these with highlighting you currently have to resort to _Sublime Text_.

For Crystalers, the front page example in Onyx will be very familiar:

```onyx
-- A very basic HTTP server
require "http/server"

server = HTTP.Server 8080, |request|
  HTTP.Response.ok "text/plain", "Hello world! You called me on {request.path} at {Time.now}!"

say "Listening on http://0.0.0.0:8080"
server.listen
```

A rather contrived example, just to show some basic constructs:

```onyx

-- *TODO* *UNTESTED* *VERIFY*

type Greeter
    greeting–phrase = "Greetings,"

    init() ->

    init(@greeting–phrase) ->

    greet(who–or–what) ->!
        say make–greeting who–or–what

    make–greeting(who–or–what) ->
        "{@greeting–phrase} {who–or–what}"
    end
end

type HelloWorldishGreeter < Greeter
    greeting–phrase = "Hello"
end-type

greeter = HelloWorldishGreeter "Goodbye cruel"
greeter.greet "world"  -- => "Goodbye cruel world"

```

And with some added explanations:
```onyx

-- *TODO* *UNTESTED* *VERIFY*

-- comments are started with two dashes - rather natural
-- types inherits `Reference` by default if nothing else specified
-- all types begin with a capital

type Greeter
    greeting–phrase = "Greetings,"  -- can prefix with `@` (like usage syntax)
    -- @greeting–phrase Str = "Greetings," -- typing it explicitly
    -- separator (-|–|_|aA) completely interchangable so above can be referred
    -- to as @greeting_phrase, @greetingPhrase etc. from _your_ code - should
    -- you prefer a different style than a lib-author

    init() ->        -- does nothing - just keep defaults

    init(@greeting–phrase) ->
        -- does nothing in body. Sugar for assigning a member in the parameter
        -- did all we need! (the `@` prefix to parameter name)

    -- above could have been written more verbose; in many different levels.
    -- init(greeting–phrase Str) ->
    --     @greeting–phrase = greeting–phrase
    -- end–def  -- ending expressions blocks, is implicit, but can be done
                -- explicitly. Here it even designates the type of block (def)

    -- define a method that greets someone
    greet(who–or–what) ->!  -- `->!` is a short cut for methods that returns
                            -- "nothing", it's ensured that return value is nil
        say make–greeting who–or–what
        -- say(make–greeting(who–or–what)) -- parentheses or "juxtapos-calls"

    -- a method that constructs the message
    make–greeting(who–or–what) ->
        -- interpolation of exprs within strings is done with simple braces
        "{@greeting–phrase} {who–or–what}"  -- last expression is returned
    end  -- as mentioned, you can explicitly end code block at will

    -- All on one line works too of course:
    -- make–greeting(who–or–what) -> "{@greeting–phrase} {who–or–what}"

end–type -- you can be even more explicit about end–tokens at will

type HelloWorldishGreeter < Greeter
    greeting–phrase = "Hello"
end

greeter = HelloWorldishGreeter "Goodbye cruel"
-- Some variations of writing the same thing (call syntax on a type is sugar
-- for calling a `new` function defined on the type):
-- greeter = HelloWorldishGreeter("Goodbye cruel")
-- greeter = HelloWorldishGreeter.new("Goodbye cruel")
-- greeter = HelloWorldishGreeter.new "Goodbye cruel"

greeter.greet "world" --  => "Goodbye cruel world"

```


## Status ##

* Onyx is in "design stage"/"RFC stage"/alpha while settling it. Input (RFC's) on the syntax and language in general are **highly welcomed**!
* Currently the basic first syntax ideas are implemented, it only has about two weeks total full time of coding on it yet (spare time...). Several keywords to do the same thing are available many times, until agreement on what to keep and what to ditch comes up.
* Some syntax doesn't have semantics yet, until it gets carved deeper in the onyx. For example declaring func's `pure`, `method`, `lenient`. And mutable/immutable modifiers on parameters and variables. Value vs ref control also.
* The "AST-core" maintained in Crystal is in alpha, close to beta.

## Roadmap ##

* => Conception
* Implement first basic functionality of "open draft".
* Work on the configurable formatter in order to enable the "Syntax Preference Study"
* Continually nail down core syntax and semantic concepts while implementing syntax, iteratively.
* Implement final core semantics according to agreed upon
    - PR as much as is accepted directly to Crystal code base
* Cleanup and refactor after all PoC changes and implementations
* Iron out bugs and do final language tweaks
* Iron out bugs some more
* => Onyx 1.0 - world domination ;-)
* Improve low level aspects of language core
    - PR as much as is accepted directly to Crystal code base:
    - Tailor made GC for optimal throughput and lowest latency
        + I'm working very sporadically on a conceptual GC specifically targeting 64 bit, that - if it turns out as well as I hope - might blow most other things out of the water, _both_ throughput-wise _and_ latency-wise. But don't hold your breath on this one. I'll keep it private until there's something to show for, or it turns out to be a disaster (spare time primarily goes in to Onyx atm).
    - Facilitate different levels of manual memory management when wanted
        + If above mentioned GC works out as planned, it will probably be faster and have lower latency than manual memory management - in that case this point is severely moot. But once again: long way there.
* => Onyx 1.2+

## Installing ##

- You will want the highlighter for Sublime Text: `git clone https://github.com/ozra/sublime-onyx.git` (it should be easily ported to Atom, TextMate, etc., if you want to - please think about if you're prepared to maintain it, if deciding to do so, or leave it to someone who wants too - it's annoying with out-of-date add-ons for everyone). The Sublime highlighter will be kept up to date with changing language constructs.

- Clone the source tree: `git clone https://github.com/ozra/onyx-lang.git`

- `cd` in to it and `make bootstrap` - to automatically download, install Crystal and compile and install Onyx. It's installed into `/opt/onyx/` to keep it separated from your package-managed `/usr/local/`. A link to the binary is made in `/usr/local/bin/`.
    + You need `git` and `wget` on your system.
    + The script is unfortunately Linux 64 bit only atm. Anyone handy with Mac OS etc. is welcome to shape it up.

## Documentation ##

- For the language itself - see the issues in GitHub. Since the language is taking shape and changing - that serves both as current documentation and a way of chipping in. Syntax constructs are described there.
- For the standard library, refer to Crystals docs for now - the lib is shared. There are some planned preferred de facto deviations, but they will be compatible.

## Onyx Project Code of Conduct ##

Whatever you think promotes and helps the language forward is enough for code of conduct for now. Cursing is ~~fucking~~ allowed, but not necessarily decreed. If someone is offended - you've probably been an asshole;  acknowledge it and apologize. We can all stumble down that road some times. Apologizing is a strong and proud act.

If someone starts acting in a way that reduces others' happiness or
productivity _chronically_, then we might revise this.

Everyone with an interest is welcome, no matter where you come from linguistically or otherwise (creed, religion, sexual orientation, sexual make-up or _even_ musical taste). In fact different backgrounds are essential for a good project.

## Community ##

Use "issues" for now. Add RFC's or ideas already if you feel like it!

Read the general [Contributing guide](https://github.com/ozra/onyx-lang/blob/master/Contributing.md),
(it's very terse, you will get through it!)

## Contributing ##

Read the general [Contributing guide](https://github.com/ozra/onyx-lang/blob/master/Contributing.md),
(it's very terse, you will get through it!):

