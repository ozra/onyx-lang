# Onyx  - enjoyable, practical, efficient programming

## "tl;dr Summary"
_Enjoy writing an app that runs with trustworthy solid stability at speeds of C/C++ with the sole effort of scripting or pseudo coding._

## Point by Point

- Based on studies relating to _human interaction with code_ where possible
- Multi-paradigm
  - OOP _structured_
  - respectful of functional style coding
  - Full on mutating imperative knuckles fully available
- Strong type system
  - Types inferred globally.
  - Explicit annotation where wanted.
  - Inheritance (_single!  - no deadly diamond of death dilemma_)
  - Traits / mixins
  - All types re-openable (aka monkey patchable)
  - Sum-types (union types)
  - Nil is a type  - no weak ass C++/Java bullshit piss typing
  - Polymorphism and function overloading  - and when type is known: no cost over a straight call (and it might be inlined too). The code is very efficient (you can't make it faster yourself in C)
  - Generics and type-vars  - because Go is retarded.
- Almost everything can be changed by coder
  - Most constructs in the language is changeable, just an override away (but don't!)
  - Operator overloading  - of course
  - Iterators are implemented as methods, imperative / structural notation available also because of its commonality. And no, there's no execution overhead.
- Clean readable and writeable syntax
  - All the common forms of _casing_ is allowed interchangeably (without conflicts): `endash—case`, `dash-case`, `snake_case`~~, `camelCase`~~. This may change!
  - Something akin to UFCS may be implemented. Discuss in issue!
- FFI: Using C-API libs is piece of cake
- Garbage Collected (_even I_, have accepted it as the way of the future  - now: let's just make it even faster [post 1.0 target])
- Macros and templating
- _Helpful_ error messages (_* as soon as the language spec has stabilized_)
- Fast!
  - Pretty fast compiling
  - Really fast executable
  - I won't stop optimizing until hell freezes over.  - The compiler should make things fast  - you should focus on keeping your code maintainable.

### Run Down

- Optimize for human parsing (aka "readability")  - not computers parsing (_not_ lisp syntax uniformity)
- Human languages has exceptions to rules, so common constructs should get sugar if warranted.
- Any work should be enjoyable if we're smart about being human, so also coding.
- A language has to work for several scenarios, be _elegantly out of the way when prototyping_. Be _lovingly tough on disciplined code_ when demanded by coder.
- A language has to work for a wide range of coders. Any team bigger than one will have mixed levels of experience and requirements, while still working on the same code base.
- Writing idiomatic clear code should be the optimized way of writing code, no "creative smart coding" to speed things up. It's the compilers job to make it run fast!
- A bit of repeat of both above points: Not every coder, nor every _project_, nor every _part_ of a project, suits the same syntactic style. Variations are needed to express the actual tasks of a certain implementation  - DSL'ish requirements. For a given project, or even parts of project, a good style guideline should be set by/for teams. It should always be up to the developers. One (or even two variants) of an "official" Onyx style guide will be developed via discussions. Further, some _named style guides_ will be developed for different scenarios, so that some uniform choices to start off from exists  - sort of "style guide templates". Sticking as close as possible to them will of course facilitate collaboration.
- Some basic syntactic aspects has been shown to be important for all humans _apt to math and especially coding_ (except females [!], exceptions noted)  - and that is spatial cognition.

## Relation to Crystal

Onyx shares AST, most semantics and IR generation with Crystal. There are some additional semantics for more fine-grained control in some contexts. The actual machine code generation is done by LLVM, a god sent to language loving mankind! Currently, by internally flagging AST-nodes, Onyx can compile both onyx and crystal sources within the same program.

It's not intended as a competitor to Crystal, different coders are attracted to the two. Crystal is a fantastic project and language, the gripe for some of us is its "stay true to Ruby" motto, which keeps it from being _the_ next generation language of choice, because of accumulated inconsistencies hindering free innovation.

_Without the fantastic efforts of the Crystal team and the LLVM team, Onyx wouldn't be on its way today_.

## Inspiration

Inspiration is taken from languages as diverse as Crystal, Haskell,
Nim, LiveScript, JavaScript, Go, Rust, Lisp, Erlang, Python, Scala, C++, LLVM-IR(!), etc. Sometimes syntax, sometimes semantics, sometimes just an idea inspired by some concept.

## Why?

- You want to write code as fast as pseudo.
- You want code to be as readable as a grocery list. (_Worst analogy yet!_)
- You want it to compile quickly while developing.
- You want that code to execute at speeds nearing C/C++.
- You want to be able to increase demands and strictness on code _when needed_.
- You want to simply integrate C-libraries or libraries with C API's.


## Community

- IRC Channel `#onyx-lang` on freenode  - just in the startings so you might be the first person there ;-)
- Issues in github: https://github.com/ozra/onyx-lang/issues

