# Onyx - pragmatic, get-shit-done, beautiful, fast & stable programming #

## "tl;dr Summary" ##
_Enjoy writing apps that runs with trustworthy solid stability at speeds nearing C/C++ with the feeling of simply pseudo coding!_

## Onyx is / has Goal of ##

- Being pragmatic - get shit done! Does what you mean!
    - OOP-_structured_ (studies point to pros)
    - Imperative (because it still is the only way for fast programs, and small processors get more and more use)
    - Easy to code functional where possible (because it _is_ safer, studies also say so)
    - Concurrency, currently via channels and fibers - this area will get a lot of attention once the language settles. Because Moores Law is dead.
- Utilize scientific studies where available for the language design
    - Human<->Code centric studies - _not_ theoretical lambda-calculus
- Innovate freely to simply make a better language - think outside the box!
- Look at available prior art for inspiration as much as possible - remember the box!
- Compiles to high performance native machine code
- Compile fast in dev-mode for swift compile-test cycle
- Type system:
    - Strongly typed - (Nil is a type) no more Java/C++/Go-null-exceptions bullshit!
    - And still: _almost global_ type inference (_the fully global has been ditched for compilation speed reasons_) - you can get away with _almost_ never writing a type-name (basically only types has to be typed ;-) ).
    - Inheritance (_single! - no deadly diamond of death dilemma_)
    - Traits (mixins)
    - All types re-openable (aka monkey patchable)
    - Sum-types
    - Polymorphism and overloading - most of the time: no cost over a straight call. The code is very efficient (you can't make it faster yourself in C :-) )
    - Generics and type-vars - because Go is retarded.
- Almost everything can be changed by coder
    - Most constructs in the language is just an override away
    - Operator overloading - of course
    - Iterators are simply implemented as methods taking "fragments". And no, there's no execution overhead over a hand-written while-loop.
- Clean readable and writeable syntax
    + The common forms of _"casing"_ is allowed interchangeably (without conflicts): `dash-case`, `snake_case`, `endash—case` ~~, `camelCase`~~.
- FFI: Using C-API libs is piece of cake
- Garbage Collected (_even I_, have accepted it as the way of the future - now: _let's just make it even faster [post 1.0 target]_)
- Template-macros and AST-macros
- A _terse and clear indent based syntax_ with voluntary explicit block ends (wysiwym + safety net).
    - A lot of research regarding the fundamentals of brain functioning used in programming points to spatiality and visual recognition of structure.
- Full compatibility with _Crystal lang modules_ - the language AST core - (any Crystal module can be used seamlessly in the same project) - this enlarges the module universe tremendously.
    - It's hard for novel new-kid-on-the-block languages to get established when there are no libs (well, even then). Sharing a module universe with another language facilitates usage of both in the real world.
- _Helpful_ error messages (_will be improved more when the language spec has stabilized_)
    - The "Did you mean this:..." we've come to love in clang (compare gcc) - and even deeper analysis of likely errors
- I won't stop optimizing until hell freezes over. - The compiler should make things fast - you should focus on keeping your code maintainable.
- Modules, pretty much like name spaces
- Closures, of course

## What Do You Mean With Scientific Approach? ##

Well, there aren't that many studies concerning coding directly. So admittedly the statement could be seen as kind of vague.
_The focus is on the actual process of a human being reading, writing and reasoning on code to accomplish a task_, including prototyping, refining, re-factoring, etc.

What is _not_ meant is "highly abstract functional lambda theory proofs from outer space when the cat is and isn't in the cradle and/or you give a shit".

### Run Down ###

- Optimize for human readability (and writability) - not computers parsing (_not_ lisp syntax uniformity). The compiler should work hard - not you!
- Any work should be enjoyable if we're smart about being human, so also coding.
- A language has to work for several scenarios, be _elegantly out of the way when prototyping_. Be _lovingly tough on disciplined code_ when demanded by coder.
- A language has to work for a wide range of coders. Any team bigger than one will have mixed levels of experience and requirements, while still working on the same code base.
- Writing idiomatic clear code should be the optimized way of writing code, no "creative smart coding" to speed things up. It's the compilers job to make it run fast! (But sometimes you just need to dive into the black box)
- Some basic syntactic aspects has been shown to be important for all humans _apt to math and especially coding_ (except females [!], exceptions noted) - and that is **spatial cognition**.

## Relation to Crystal ##

Onyx is built upon the AST, most semantics and IR generation of Crystal. There are some additional semantics for more fine-grained control in some contexts. The syntax is entirely different. The actual machine code generation is done by LLVM, a god sent to language loving mankind! Currently, by internally flagging AST-nodes, Onyx can compile both onyx _and_ crystal sources within the same program. Therefore great praise and credit goes out to the efforts of the Crystal team and the LLVM team, whom without Onyx would not be in this stage.

## About Oscar Campbell ##

I've always loved linguistics, programming and manipulation of text. I coded my first language 25 years ago (when I was twelve). Well, it was called "CP Torsk 0.2" ("CP Cod 0.2"), so not _that_ serious. For the Amiga or Commodore 64 if I remember correctly.

Onyx is the final frontier - this is where the accumulated interest and experiences will play out fully.

## Inspiration ##

Most of Onyx is accumulated ideas with no basis in any of the modern languages. Fortunately, many concepts have ended up in similar ways as other new languages (we all have the same languages as reference, so we're bound to come up with similar ideas). I've then looked at the newer languages to see if they have some better ideas to steal from. Amateurs borrow - pros steal.
So, inspiration has been taken from languages as diverse as LiveScript, Haskell, Nim, Go, Rust, Erlang, Python, Lisp, Swift, Scala, C++, LLVM-IR(!), etc. Sometimes syntax, sometimes semantics, sometimes just an idea inspired by some concept.

## What does it look like currently? ##

GitHub doesn't accept highlighters until there are hundreds of repositories using it, so to view these with highlighting you currently have to resort to _Sublime Text_ or _Atom_.

For Crystalers, the front page example in Onyx will be very familiar (lent the examples):

```onyx
-- A very basic HTTP server
require "http/server"

server = HTTP.Server 8080, (request) ~>
  HTTP.Response.ok "text/plain", "Hello world! You called me on {request.path} at {Time.now}!"

say "Listening on http://0.0.0.0:8080"
server.listen
```

A rather contrived example, just to show some basic constructs:

```onyx

type Greeter
    @greeting–phrase = "Greetings,"

    init() ->
    init(@greeting–phrase) ->

    greet(who–or–what) ->!
        say make–greeting who–or–what

    make–greeting(who–or–what) ->
        "{@greeting–phrase} {who–or–what}"
end

type HelloWorldishGreeter < Greeter
    @greeting–phrase = "Hello"
end

ext HelloWorldishGreeter: greet(who-or-what) -> previous-def(who-or-what).red

greeter = HelloWorldishGreeter "Goodbye cruel"
greeter.greet "world"  -- => "Goodbye cruel world"

```

And with some added explanations:
```onyx

-- Comments are started with two dashes - rather natural.
-- Types inherits `Reference` by default if nothing else specified.
-- All types begin with a capital

type Greeter
    @greeting–phrase = "Greetings,"  -- member-vars are prefixed with `@`
    -- separator (-|–|_) completely interchangeable so above can be referred
    -- to as @greeting_phrase, @greeting-phrase etc. from _your_ code - should
    -- you prefer a different style than a lib-author

    init() ->        -- init does nothing - just keep defaults

    init(@greeting–phrase) ->
        -- does nothing in body. Sugar for assigning a member in the parameter
        -- did all we need! (the `@` prefix to parameter name)

    -- above could have been written more verbose; in many different levels.
    -- init(greeting–phrase Str) ->
    --     @greeting–phrase = greeting–phrase
    -- end      -- ending expressions blocks, is implicit, but can be done
                -- explicitly.

    -- define a method that greets someone
    greet(who–or–what) ->!  -- `!` is sugar notation for methods that returns
                            -- "nothing", it's ensured that return value is nil
        say make–greeting who–or–what
        -- say(make–greeting(who–or–what)) -- parentheses or "juxtapos-calls"

    -- a method that constructs the message
    make–greeting(who–or–what) ->
        -- interpolation of exprs within strings is done with simple braces
        "{@greeting–phrase} {who–or–what}"  -- last expression is returned

    -- All on one line works too of course:
    -- make–greeting(who–or–what) -> "{@greeting–phrase} {who–or–what}"

end  -- as already mentioned, you can explicitly end code block at will

-- another type, inheriting Greeter
type HelloWorldishGreeter < Greeter
    @greeting–phrase = "Hello"
end

-- re-open the type! Here using nest-token instead of indent (colon here)
ext HelloWorldishGreeter: greet(who-or-what) -> previous-def(who-or-what).red

greeter = HelloWorldishGreeter "Goodbye cruel"
-- Some variations for instantiating: (call syntax on a type is sugar
-- for calling a `new` function defined on the type):
-- greeter = HelloWorldishGreeter("Goodbye cruel")
-- greeter = HelloWorldishGreeter.new("Goodbye cruel")
-- greeter = HelloWorldishGreeter.new "Goodbye cruel"

greeter.greet "world" --  => "Goodbye cruel world"

```


## Status ##

* Onyx is still in design-/RFC-stage. Input on the syntax and language in general are **highly welcomed**!
* It is tightening up, still some syntactic changes occur.
* Some syntax doesn't have semantics yet, until it gets carved deeper in the onyx. For example declaring func's `pure`, explicit `let`/`mut` on params, etc.

## Roadmap ##

See it's own issue.

## Installing ##

- You will want the highlighter for Sublime Text or Atom: `git clone https://github.com/ozra/sublime-onyx.git`. The Sublime and Atom highlighter will be kept up to date with changing language constructs. It should be easily portable to TextMate and LimeText.

- Clone the source tree: `git clone https://github.com/ozra/onyx-lang.git`

- `cd` in to it and `make bootstrap` - to automatically download, install Crystal and compile and install Onyx. It's installed into `/opt/onyx/` to keep it separated from your package-managed `/usr/local/`. A link to the binary is made in `/usr/local/bin/`.
    + You need `git`, `wget` and some more stuff on your system (the scipt solves most on debian-based systems currently).
    + The script is unfortunately Debian-ish Linux centric atm. Anyone handy with other distros, Mac OS and Free BSF etc. are welcome to shape it up and PR.

## Documentation ##

- For the language itself - see the issues in GitHub. Since the language is taking shape and changing - that serves both as current documentation and a way of chipping in. Syntax constructs are described there - look for tag "doubles-as-docs".
- Standard library docs are coming _soon_.

## Onyx Project Code of Conduct ##

Whatever you think promotes and helps the language forward is enough for code of conduct for now. Cursing is ~~fucking~~ allowed, but not necessarily decreed. If someone is offended - you've probably been an asshole;  acknowledge it and apologize. We can all stumble down that road some times. Apologizing is a strong and proud act.

Everyone with an interest is welcome, no matter where you come from linguistically or otherwise (creed, religion, sexual orientation, sexual make-up or _even_ musical taste). In fact different backgrounds are essential for a good project!

## Community ##

Use "issues" for now. Add RFC's or ideas already if you feel like it!

There is also an IRC-channel now on freenode `#onyx-lang`, I'll try to remember to login.

Read the general [Contributing guide](https://github.com/ozra/onyx-lang/blob/master/Contributing.md),
(it's very terse, you will get through it!)

## Contributing ##

Read the general [Contributing guide](https://github.com/ozra/onyx-lang/blob/master/Contributing.md),
(it's very terse, you will get through it!):
