#!/usr/bin/env onyx


-- 1. template dpp - dpp isn't looked up - probably signature mismatch
-- 2. sigsegv crash on the foo?bar?qwo chain


-- Some Monofonts Safe Unicode Glyphs:
-- ®©ªµþ¥€$£¢œ·°¤×÷¿¡¹²³§¶-–—“”‘’()[]{}‹›«»½ßð
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


-- Test all possible constructs in one go
say "\n\nBefore requires!\n\n"

require "./crystal-scopes"
require "wild_colors"


'std-int-width = 64
'std-real-width = 64


-- '!literal-int = Int64
-- comment specials like TODO, todo, fixme, FIXME and such

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -


_debug_compiler_start_ = true

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

say "\nLet's ROCK\n".red

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -


template dpp(...exps) =
   _debug_compiler_start_ = true

   {% for exp in exps %}
      $.puts " string here { {=exp.stringify=} } and here too = { ({=exp=}).inspect }"
   {% end %}
end -- dpp
  -- *TODO* above end, if no comment after, makes one line-no disappear

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
say "Function / Lambda Return Type Syntax"

One = 1; Two = 2; Three = 3; Four = 4; Five = 5; Six = 6

foo-01() -> Int
   One

foo-02() ->
   Two

foo-03() -> Int: Three
foo-04() ->: Four
foo-05() ->; Five
foo-06() -> return Six

foo-07() -> Int
   7

foo-08() ->
   8

foo-09() -> Int then 9
foo-10() -> Int do 10
foo-11() -> Int => 11
foo-12() -> Int: 12

foo-13() -> 13
foo-14() ->: 14

-- foo-err-01() -> One  -- should error
-- foo-err-02() -> Int; 1  -- should error

foo-nil-01() ->! say "ok"
foo-nil-02() -> Nil: say "ok"



-- BODY = EXPR+
-- NEST = `;` | `:` | `=>` | INDENT
-- TYPE_AND_BODY = ( TYPE_LIKE? NEST_BODY )
-- NON_TYPE_BODY = BODY  | where BODY.size > 1 or BODY.0 != TYPE_LIKE
-- LAMBDA = `(` ARGS* `)` `->` ( (TYPE NEST BODY) | NON_TYPE_BODY)

fn-01 = () -> 1
fn-02 = () ->; 2
fn-03 = () -> Int: 3
fn-04 = () -> Int: Four
fn-05 = () ->: Five
fn-06 = () ->; Six

say "Function Definition Head Variations - Func Def"
say foo-01
say foo-02
say foo-03
say foo-04
say foo-05
say foo-06
say foo-07
say foo-08
say foo-09
say foo-10
say foo-11
say foo-12
say foo-13
say foo-14

-- foo-err-01
-- foo-err-02

say foo-nil-01
say foo-nil-02

say "Lambda Definition Variations"
say fn-01()
say fn-02()
say fn-03()
say fn-04()
say fn-05()
say fn-06()

-- Loose ideas:
--
-- Where clause for func-heads etc.
--
-- foo(x Tee, y Too, z, u) ->
--    where
--       Tee < Foo                       -- type var - matches and propagates type to first matched
--       type Too = Bar | (Zoo & Qwo)    -- type alias - restricts each time individually
--       z Tee
--       u = 47
--
-- foo( ...parameters... ) ->
--    where parameters are
--       Tee < Foo                       -- type var - matches and propagates type to first matched
--       type Too = Bar | (Zoo & Qwo)    -- type alias - restricts each time individually
--       z Tee
--       u = 47

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

say "Lambda Type as value"

-- lambda-type = '(Intp, Bool) -> Intp  -- FUCKS UP HIGHLIGHT IN ATOM ONLY
-- lambda-type = (Intp, Bool) -> Intp  -- NOT ALLOWED YET
-- pp lambda-type

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

p for y in [1,2,3]: say y
say for y in [1,2,3]: say y

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
say "Ternary if"

tern-test(a) -> if a == true ? "tt ternary true" : "tt ternary false"

say tern-test true
say tern-test false
say if true ? "ternary true" : "ternary false"
say "suffix true" if true

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
say "Basic Nil Reasoning"

maybe-nil = 5 or nil
is-nil = nil and 5 or 5 and nil

pp say maybe-nil.nil?
pp say maybe-nil.is?
pp say is-nil.nil?
pp say is-nil.is?

say maybe-nil.is!
say maybe-nil.its!
say maybe-nil.must!
-- say is-nil.is!
-- say is-nil.its!
-- say is-nil.must!

-- nil-sugar,  nil-chaining
say "Nil-call-chain-sugar"

-- type Kwattro  - *TODO* improve error message!

type Nilish
   @val = 0

   init(@nil-at = 0) ->

   internal() ->
      say (foo?bar?qwo || 0) + 200
      -- say "SHOULD BE: but it crashes atm: `(foo?bar?qwo || 0) + 200`"
      -- say (foo~bar?~qwo || 0) + 200

   foo()  ->   @val = 1; if @nil-at >= 1 ? this : nil
   bar?() ->   @val = 2; if @nil-at >= 2 ? this : nil
   bar()  ->   raise "don't call me!"
   qwo()  ->   @val = 3; if @nil-at >= 3 ? 46 : nil

nfoo = nil
say (nfoo?foo?bar?qwo || 0) + 50
nfoo?internal

nfoo = Nilish 1
say (nfoo?foo?bar?qwo || 0) + 100
nfoo.internal

nfoo = Nilish 2
say (nfoo?foo?bar?qwo || 0) + 100
nfoo.internal

nfoo = Nilish 3
say (nfoo?foo?bar?qwo || 0) + 100
nfoo.internal

-- NOT LEGAL YET
-- nfoo = Nilish 2
-- say (nfoo~foo~bar?~qwo || 0) + 100
-- say ((nfoo.try ~.foo.try ~.bar?.try ~.qwo) || 0) + 300
-- nfoo.internal

-- '!literal-int = Int64

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- suffix (v IntegerLiteral) = Intp _
-- suffix (real)     = Real _
-- suffix (number)r  = Real _
-- suffix (number)f  = _f32    -- here mapping to other "lower level" suffixes those turn into actual AST-flags and further on actual op-codes
-- suffix (number)d  = _f64

-- module Geometry.Suffixes<B = 1.0>
--    BaseUnitFromMeter = B

--    suffix (number)mm    = {=number=}_r * (1000r * BaseUnitFromMeter)
--    suffix (number)cm    = {=number=}_r * (100r * BaseUnitFromMeter)
--    suffix (number)dm    = {=number=}_r * (10r * BaseUnitFromMeter)
--    suffix (number)m     = {=number=}_r
--    suffix (number)km    = {=number=}_r * (0.001r * BaseUnitFromMeter)
--    suffix (number)svmil = {=number=}r * (0.0001r * BaseUnitFromMeter)

-- Geometry.All:
--    mixin Suffixes, Functions

-- Geometry.All:
--    dist = 47km + 300m

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

indent-call(x, y, ...z) -> "{x}, {y}, {z}"

say indent-call
   "a", "b"
   47, 23, 11
   12
   indent-call "masta", indent-call
      "blasta"
      "blaaasta"


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
-- TUPLES

vx = 2; vy = 3
a = 1
b = 3
c = 2
that = "That"

do-tup(x Tup) -> x

good-ole-set = {47, "Hey", 3}

say typeof(good-ole-set)
say good-ole-set.i-type


-- OTHER SYNTAX ALTERNATIVES

-- a = ⦉1, 2, 3⦊
-- a = ⦉1, 2, a[0] > 5⦊


say "<\{...\}> NAMED TUPLE SYNTAX"

ntup = <{forty: 47, thirteen: 13, yo: "yo"}>
say ntup, typeof(ntup), ntup.i-type

-- is allowed for named also, currently:
ntup = <[forty: 47, thirteen: 13, yo: "yo"]>
say ntup, typeof(ntup), ntup.i-type

ntup = ‹forty: 47, thirteen: 13, yo: "yo"›
say ntup, typeof(ntup), ntup.i-type

ntup = (forty: 47, thirteen: 13, yo: "yo")
say ntup, typeof(ntup), ntup.i-type

-- Parenthesized namedtuple shouldn't require trailing comma
ntup = (forty: 47)
say ntup, typeof(ntup), ntup.i-type


say "<[...]> TUPLE SYNTAX"

tup1 = <[47, 13, "yo"]>
tup2 = <[#exacto, that]>
tup3 = <[that]>
tup4 = <[]>

tup5 = <[
   "ml"
   "tup", "are"
   "also", "ok", 5,
   that
   "as"
   7, "sual"
]>

tup6 = do-tup <[
   "ml"
   "tup", "are"
   "also", "ok", 5,
   that
   "as"
   7, "sual"
]>

tup7 = <[a < b, b > c]>
tup8 = <[true, a < b > c, false]>
do-tup <[1, 2]>
do-tup(<[1, 2]>)
if do-tup <[1]> => say "tup tup yeay {do-tup <[1]>}"
bzz = do-tup <[that]> if true

say "(...) TUPLE SYNTAX"

tup1 = ( 47, 13, "yo" )
tup2 = (#exacto, that)
tup3 = (that,)

tup4 = (,)

tup5 = (
   "ml"
   "tup", "are"
   "also", "ok", 5,
   that
   "as"
   7, "sual"
)

tup6 = do-tup (
   "ml"
   "tup", "are"
   "also", "ok", 5,
   that
   "as"
   7, "sual"
)

tup7 = (a < b, b > c)
tup8 = (true, a < b > c, false)
do-tup (1, 2)
do-tup((1, 2))
if do-tup (1,) => say "tup tup yeay {do-tup (1,)}"
bzz = do-tup (that,) if true

-- say tup1, tup2, tup3, tup4, tup5, tup6, tup7, tup8

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

tag–hash = {#apa: "Apa", #katt: "Katt", #panter: "Panter"}
say "tag–hash: {tag–hash}"

json–hash = {"apa": "Apa", "katt": "Katt", "panter": "Panter"}
say "json–correct–hash: {json–hash}"

js–hash = {apa: "Apa", katt: "Katt", panter: "Panter"}
say "perhaps to be js–hash: {js–hash}"

apa = #apa
katt = "katt"
panter = 947735

arrow–hash = {apa => "Apa", katt => "Katt", panter => "Panter"}
say "arrow–hash: {arrow–hash}"

tag–hash–2 = {
   #apa: "Apa",
   #katt: "Katt", #panter: "Panter",
   #filurer: [
      "Filur"
      "Kappo",
      "Nugetto"
   ]
   #tuple1: ‹
      "47",
      13,
      3.1415
      "yep"
      #Boo
   ›
   #tuple2: <[
      "47",
      13,
      3.1415
      "yep"
      #Boo
   ]>
   #tuple3: (
      "47",
      13,
      3.1415
      "yep"
      #Boo
   )
   #bastard: "Bastard"
}
say "tag–hash–2 type is {typeof(tag–hash–2)}"
say "tag–hash–2 value is {tag–hash–2}"



tuple1a = (13, 32, 47, 2)
tuple2a = ("foo", 1, {1, 2, 3})

-- tuple1c = 〈13, 32, 47, 2〉
-- tuple2c = 〈"foo", 1, {1, 2, 3}〉

-- tuple1d = ‹13, 32, 47, 2›
-- tuple2d = ‹"foo", 1, {1, 2, 3}›

-- tuple1e = «13, 32, 47, 2»
-- tuple2e = «"foo", 1, {1, 2, 3}»

-- tuple1f = （13, 32, 47, 2）
-- tuple2f = （"foo", 1, {1, 2, 3}）

-- tuple1g = ⦅13, 32, 47, 2⦆
-- tuple2g = ⦅"foo", 1, {1, 2, 3}⦆


set1 = {1, 2, 3, 5}
set2 = {"foo", 47, "mine", 13}

list = [47, 13, 42, 11]

say "- - ACCESS TERSECUTS! - -".yellow

say list.1, list.2?, list.4?
say "With to-s: {list.1}, {list.2?to-s.+ "X"}, {list.4?to-s.+ "X"}"

say tag-hash-2#katt
say "with to_s: '{tag-hash-2#katt?to-s}'"

say json-hash:katt, json-hash:panter

if json-hash:katt: say "Yeeeaaaah"  -- syntactic test for the colon discrepancy

say json-hash:neat-literal?
say "with to_s: {json-hash:neat-literal?to-s}"

json-hash:neat-literal = "47777777"
say json-hash:neat-literal
say "with to_s after: {json-hash:neat-literal?to-s}"


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

a1 = String
b1 = "fdsaf"

say "a ~~ b == {a1 ~~ b1}"
say "Intp !~~ b == {Intp !~~ b1}"
say "a !~~ b == {a1 !~~ b1}"

x = /x/

say "x ~~ \"zxy\" == {x ~~ "zxy"}"
say "\"zxy\" ~~ x == {"zxy" ~~ x}"
say "x !~~ \"zxy\" == {x !~~ "zxy"}"
say "\"zxy\" !~~ x == {"zxy" !~~ x}"

say "x =~ \"zxy\" == {x =~ "zxy"}"
say "\"zxy\" =~ x == {"zxy" =~ x}"

-- say "x !~ \"xy\" == {x !~ "xy"}"
-- say "\"xy\" !~ x == {"xy" !~ x}"

branch x
   "nilx"
      say "~~ was rex"
   0.0
      say "~~ was 0.0"
   *
      say "was not eq"

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -


say %s(\nfunction(foo) { SomeJsCode(foo("bar}")); }\n)

foos = %:MY_STR
1. lots asf self_def fds
 f  fsd fsdf asdf
  fasef _debug_compiler_start_ = {_debug_compiler_start_} here
fasd
MY_STR.upcase.reverse

say foos

foos = %s:MY_STR
2. lots asf self_def fds
 f  fsd fsdf asdf
  fasef _debug_compiler_start_ == {_debug_compiler_start_} here
fasd
MY_STR

say foos

foos = %:  MY_STR
3. lots asf self_def fds
 f  fsd fsdf asdf
  fasef _debug_compiler_start_ = {_debug_compiler_start_} here
fasd
MY_STR

say foos

foos = %s: MY_STR
4. lots asf self_def fds
 f  fsd fsdf asdf
  fasef _debug_compiler_start_ == {_debug_compiler_start_} here
fasd
MY_STR

say foos

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

pp 471
dpp 472
dpp 1..2
dpp 1 .. 2


fun-a(x) -> say "fun-a says: '{x}' and '{x[String]}'"
fun-a {String => String}
say ({String => String}).i-type
say typeof({String => String})

fun-b(x) -> say "fun-b says: '{x}' and '{x.first}'"
fun-b [String]

-- a-function(messages List<Str>, pairs {String => String}) ->


say "
    ...
    asdfaASDF FDSAsd
FDF
".downcase

say %<
   ...
   fasfd FDSAF
FDSA
>.downcase


the-function(a Int64? = nil, b Int64? = nil) -> true
the-function         -- a is nil, #b is nil
the-function 1       -- a is 1, #b is nil
the-function b: 2  -- a is nil, #b is 2
the-function 1, 2    -- error, #b must be assigned by name

if the-function a: 1, b: 2: say "the-function says yes!"
if !the-function a: 1, b: 2: say "-" else: "the-function says no!"


my-foo(x, y, opts Map<Str, Str|Int64|Nil>) ->
   say "csx { opts:magic_port?.i-type }"
   say "csx { opts:x?.i-type }"
   say "csx { typeof(opts:x?) }"
   -- host = opts:host_name as Str? || "default_host"
   -- magic-port = opts:magic_port as Int64? || 47
   -- p x, y, host, magic-port
end


Mod: mod-foo() -> say "I'm in Mod"

alias ModAlias = Mod

ModAlias:
   mod-foo


type Droogs = Map  -- test multi-level alias resolution

my-foo 1, 2, Droogs<Str, Str|Int64|Nil>{
   "my_name_is": "Totally irrelevant"
   "host_name": "da_host.yo"
   --   "x": 1
}




type Xoo
   @@my-instance-count = 0

   Self.get-count() ->
      @@my-instance-count

   Self.my-new() ->
      say "My own new function"
      @@my-instance-count += 1
      return new()
   end
end

say Xoo.get-count     --> 0
foox = Xoo.my-new
barx = Xoo.my-new
say foox.i-type
say Xoo.get-count     --> 2

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

say "- - Templates & Macros - -".yellow



Mac:
   template horribly-formatted-pow2-round-up(v, r) =
    (
      {% if r != 2 && r != 4 && r != 8 && r != 16 && r != 32 && r != 64 &&
            r != 128 && r != 256 && r != 512 && r != 1024 && r != 2048 &&
            r != 4096 && r != 8192 && r != 16378 && r != 32768 && r != 65536
      %}
         raise "pow2-round-up requires a single power-of-two value as rounding ref! Got {{=r=}}"

           %z = nil
         if 1

      {% else %}
         _debug_compiler_start_ = true

         (do
            -- silly thing to do, caching a constant expr, but we're testing all features here, m'kay!
            %ref-v = {=r=} - 1
            %z = ({=v=} + %ref-v) .&. (.~. %ref-v)

            if true
            say "fooo ya { %z }"
            say "qwaaa {{=r=}}"
         else
               say "booo ya"
        end
-- comm at 0
         end
               )

         if 2

      {% end %}

            say "is true"
            %z
         end
          %z
     )

include Mac

horribly-formatted-pow2-round-up 3027, 4096
horribly-formatted-pow2-round-up 4097, 4096
horribly-formatted-pow2-round-up 4097, 65536

dpp 4096 == horribly-formatted-pow2-round-up 3027, 4096
dpp 8192 == horribly-formatted-pow2-round-up 4097, 4096
dpp 65536 == horribly-formatted-pow2-round-up 4097, 65536

-- pp 8192 == horribly-formatted-pow2-round-up 4097, 4093  ---> Should fail!

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- '!Intp=Int64
-- '!Real=Float32

-- '!literal-int = Int64
-- '!literal-real = Float32



type MoreInt = Int32 | Int64 | Int8
say MoreInt

flags SomeFacts < UInt8
   AppleLover
   PearLover
   CoolDude
end

-- facts = AppleLover .|. CoolDude

facts = SomeFacts.flags AppleLover, CoolDude
say "facts: {facts}"
say type-decl(facts)
say typedecl facts
say typeof facts, "blargh", 1
say (type_decl facts, "blargh", 1)
say type–decl(facts, "blargh", 1)

facts .|.= SomeFacts.PearLover
say "facts: {facts}"

--- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- ---
say "Some Type Reasoning".yellow

pp dtype 47 || "a"
pp d-type 47 || "a"
pp c–type 47 || "a"
pp c_type 47 || "a"
pp d–type(47 || "a")
pp d–type(facts)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

MY_CONST = do
   x = 0
   -- 2.upto(4).each-with-index (a, i)\
   (2..4).each-with-index (a, i)\
      x += a
      say "calculating MY_CONST, {a}, {i}"
   x

pp MY_CONST
dpp MY_CONST
-- *TODO* $.say / Program.say ?
pp $.say "blargh"
-- *TODO* $.MY_CONST / Program.MY_CONST ?
pp $.MY_CONST
-- pp ::MY_CONST
-- pp Program.MY_CONST


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- -- *TODO* ' should not be needed before Int32!
-- -- '!literal-int = Int32
Glob: @@my-global = 47_i32 'get 'set
-- -- '!literal-int = Int64

Glob: @@my-typed-global 'Int32|Nil 'get 'set
-- -- '!literal-int=Int32
Glob: @@my-typed-and-assigned-global 'Int32 = 47i32 'get 'set
Glob.my-global = Glob.my-typed-and-assigned-global

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

Djur:
   module Boo below -- *TODO* should work without kwd. Move path->moddef check to *-suffix

   APA = 47

   type Apa
      -- '!literal-int=Int64

      @@foo’ = 1
      @@bar  = 2

      @foo     Intp  -- Idt
      @bar     Intp  -- Ist
      @foo’    Intp  = 47
      @bar’         = 47
      @foo’’   Intp
      @bar’’   Intp

      @foo3    'Intp
      @bar3    ^Intp
      @qwo3    ~Intp

      init() ->
         @foo   = 47
         @bar   = 42
         @foo’’ = 0
         @bar’’ = 0
         @foo3  = 47
         @bar3  = 47
         @qwo3  = 47

      -- xfoo! Intp = 47  -- should fail, and does
      -- xbar? Intp = 42  -- should fail, and does

      Self.my-def() -> say "Hit the spot! { @@foo’ }, { @@bar }"
      inst-def() -> say "Hit the spot! { @foo’ }, { @bar }"
   end

   --enum Legs
   enum Legs
      NONE
      TWO
      FOUR
      SIX
      EIGHT

      -- ERRORS - UNDEFINED CONSTANT WHEN USED!!!
      -- ifdef x86_64
      --    EIGHT
      --    TUSEN
      -- else
      --    EIGHT

      Self.is-six?(v) ->
         v is SIX
   end
end

-- module Djur
--    module Boo
--       APA = 42 -- *NOTE* - should we change behaviour so that consts can be monkey overridden too?
--    end
-- end


say "1"

-- Djur::Boo::Apa.my-def
-- say "Djur::Boo::Legs::TWO = {Djur::Boo::Legs::TWO}"

-- say Djur.Boo.Apa.foo’ -- *NOTE* perhaps a better error message: "No method with the name `{name}` found, only a private variable. Make a getter and/or setter method to access it from the outside world"
Djur.Boo.Apa.my-def
say "Djur.Boo.Legs.TWO = {Djur.Boo.Legs.TWO}"
say "Djur.Boo.Legs.is-six?(EIGHT) = {Djur.Boo.Legs.is-six?(Djur.Boo.Legs.EIGHT)}"


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- t = Time.Span(0)
-- t = Time.Span 0

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

type Blk
   @foo = 1
   @bar = "qwö"

   init(x, ~fragment) ->  -- (T) -> U - does not work for fragment...
      yield x + @foo
      yield x - 2
   ;
   deinit() ->
      say "Blk.deinit {@bar}"
   ;
;

-- ext Balk: baza() -> false  -- should error!

ext Blk: foo() -> say "Blk.foo"
Blk.bar() -> say "Blk.bar"


blk = Blk(4, (x)\
   say "in blk init fragment: {x}"
)

blk2 = Blk(4, \x\
   say "in blk init fragment: {x}"
)

blk2 = Blk 7, \
   say "in blk2 init fragment: { %1 }"

blk3 = Blk
   1
   (x)\
      say "in blk2 init fragment: {x}"

blk2 = nil
blk3 = nil

blk.foo
Blk.bar

foo-list = [] of Blk
for i in 1..50000
   foo-list << Blk 47, \

-- sleep 1

for i in 1..50000
   foo-list << Blk 47, \
pp foo-list.size
foo-list = nil

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

trait Functor
--   call() -> abstract

type MyFunctor
   mixin Functor

   @foo = 47

   call() -> "call()"
   call(a, b) -> "call {a}, {b}, {@foo}"
   bar() -> true

myfu = MyFunctor()

pp myfu.bar
pp myfu.call "ctest", "cfooo"
say myfu "test", "fooo"
say myfu  -- should NOT result in a call!
say myfu()

my-fun-fun(f) ->
   f "testing", "it"

pp my-fun-fun myfu

my-lambda = (x Str) -> say "x: {x}"
my-lambda "47"
my-lambda("47")
my-lambda.call "47"
my-lambda.call("47")


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- reopen String type and override '<<' operator to act as "concat" (like '+',
-- but auto-coercing)

ext String: <<(obj) -> "{this}{obj}"

say("fdaf" + "fdsf" << "aaasd" << 47.13 << " - yippie!")


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

fun-with-various-local-vars(a Int32|Int64|Real = 0) ->!
   say "a type = {typeof(a)}"

   -- declare assign with type inference
   zar1 = 1


   -- -- *TODO* after all basic control structs are implemented

   -- zar2 ^Intp
   -- zar4 'Real
   -- zar3 ~Str

   -- -- zar4 'Intp = 1
   -- -- zar5 ~Intp = 1
   -- -- zar6 ^Intp = 1
   -- -- zar7 '= 1
   -- -- zar8 '*= 1
   -- -- zar9 'auto = 1

   -- pp zar2.i-type, zar4.i-type, zar3.i-type
   -- -- May currently crash - all values are undefined becaused they're alloca'd
   -- -- when typed currently. They should _not_ be. ONLY typed for TySys!
   -- -- pp zar2, zar4, zar3

   say "fun-with-various-local-vars {zar1}" -- , {LocalConst}"


fun-with-various-local-vars 47

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

fun-with-exception-action(x) ->!
   try
      a = 1 / 0

   rescue e IndexError | ArgumentError
      say "In fun: Rescued {e}"

   rescue DivisionByZero:
      say "In fun: Rescued divizon by zero"

   rescue e =>
      say "Rescued some kind of shit"

   fulfil
      say "In fun: Nothing to rescue - yippie!"

   ensure
      say "In fun: Oblivious to what happened!"

   a = 1 / x
   nil

fulfil
   say "eof fun-with-exception-action - ONLY on SUCCESS!"

ensure
   say "eof fun-with-exception-action - EVEN on RAISE!"


say ""
say "call fun-with-exception-action 1"

try
   fun-with-exception-action 1
   say "after call fun-with-exception-action"
rescue
   say "rescued fun-with-exception-action in Program"
end

say "after try/rescue call fun-with-exception-action"
say ""

say ""
say "call fun-with-exception-action 0"

try
   fun-with-exception-action 0
   say "after call fun-with-exception-action"
rescue
   say "rescued fun-with-exception-action in Program"
end

say "after try/rescue call fun-with-exception-action"
say ""

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -


-- '!literal-int=Int64

foo-named(awol => my-awol Intp, foo: my-foo = 47, bar = "fds") ->!
   say "foo-named: (awol): {my-awol}, foo: {my-foo}, bar: {bar}"
   -- say "foo-named: (awol): {awol}, foo: {my-foo}, bar: {bar}" -- should fail

foo-named 1, "blarg", "qwö qwö"
foo-named 2, 42, bar: "yo"
foo-named 3, foo: 11, bar: "yo"
foo-named awol: 4, foo: 11, bar: "yo"
-- foo-named my-awol: 4, foo: 11, bar: "yo" -- should fail

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

list = Li<Str>()
list << "foo"
list << "yaa" << "dbl"

-- v = list.map((x, y) ~> x + "1")  -- should fail: to many args to block
v = list.map((x) ~> x + "1")
w = list.map (x) ~> "{x} 47"

i = list.map (x) ~> "{x} 13"
-- i = list.map (x) ~> => "{x} 13"  -- *TODO* SHOULD ERR for good form!

j = list.map \\ "{_1} 13"

puts "{v}, {w}"

list = [47, 13, 42, 11]

list.each-with-index (v, i) ~> say "each-with-index: v: {v}, i: {i}"
list.each (v) ~> say "each-with-index-value: v: {v}"

say " x:"
x = list.each((v) ~> p v).map(~> _1 * 2)
say " y:"
y = ( ( list.each((v) ~> p v) ).map(~> _1 * 2) )
say " z:"
z = list.each((v) ~> p v).map ~> _1 * 2
say " u:"
u = list.each((v) ~> p v).map ~> _1 * 2
say " v:"
v = ( ( list.each((v) ~> p v) ).map \.* 2 )
say " w:"
w = ( ( list.each((v) ~> p v) ).map(~.* 2))
say " pw:"

pw = (list.each ~>p _1).map \.* 2


p "Some fragment usage again, with \\...\\ syntax"

say " x:"
x = list.each(\v\ p v).map(\\_1 * 2)
say " y:"
y = ( list.each(\v\ p v) ).map \\
   _1 * 2
say " z:"
z = list.each(\v\ p v).map \
   _1 * 2
say " u:"
u = list.each(\v\ p v).map \\ _1 * 2
say " v:"
v = ( ( list.each(\v\ p v) ).map \.* 2 )
say " w:"
w = ( ( list.each(\v\ p v) ).map(\.* 2))
say " pw:"

pw = (list.each ~>p _1).map \.* 2


say "All lists should equal [94, 26, 84, 22]"

say x
say y
say z
say u
say v
say w
say pw


-- say(s) -> puts s


-- '!literal-int=Int32


DEBUG–SEPARATOR = 47


-- Change array literal notation for typed arr (thus empty arr)!?

-- a = [32, 47 'Int32]
--  or
-- a = [Int32: 32, 47]

-- a = [Int32:]
--  or
-- a = [] Int32

-- a = [200 x Int32]  -- static array literal

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -


f(y ()->) -> nil
g(y ()->) -> nil
g(y ()->) -> nil -- redefines exactly the same
g(y Fn) -> nil -- redefines exactly the same

--   -- (Seq<Int32>()).flat_map ~>
f () ->
   ([] of Intp).flat-map ~>
      [] of Intp

f(() ->
   ([] of Intp).flat-map(~>
      [] of Intp
   )
)

(f () ->
   (([] of Intp).flat-map ~>
      [] of Intp
   )
)

-- f(() ->
--    ([0 x Intp]).flat-map(~>
--       [0 x Intp]
--    )
-- )

-- (f () ->
--    ((['Intp]).flat-map ~>
--       ['Intp]
--    )
-- )

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -


n = 3
do-something(x) -> say "do-something {x}"

match n
   1
      do-something 1
   .== 5
      do-something 2
   .< 10
      do-something 3
   *
      do-something 4



char = _"a"
char2 = %"b"
say "char: {char} ({ typeof(char) })"
say "char 2: {char2} ({ typeof(char2) })"

straight-str = %s<no {interpolation\t here}\n\tOk!>
say "straight-str: {straight-str} ({ typeof(straight-str) })"

-- *TODO* %{...{x} } - doesn't interpolate
say %(char: "{char}" ({ typeof(char) }))

-- *NOTE* consider this, _iff_ standard string is changed to interpolate on {/}
-- tpl-str = %t<requires heavier delimiting %{interpolation here}>
-- say "tpl-str: {tpl-str} ({ typeof(tpl-str) })"


-- *TODO* "str" \n\INDENT\etc "str" shall become ONE string!
the–str = "111kjhgkjh"
--   "222dfghdfhgd"

yet-a–str = "111kjhgkjh
   222dfghdfhgd
   333asdfdf
"

say "the broken str: {the-str}"

say "the 2nd broken str: {yet-a-str}"

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

say "literal and symbolic boolean operator styles"
pp (true && false) is (true and false)
pp (true || false) is (true or false)
pp !true is not true
pp (false isnt true) is (false != true)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- '!literal-int=StdInt

-- first comment
a = 47  --another comment

if a == 47 &&
   a != 48
   say "0 - a tricky one"

if (a == 47 &&
   a != 48
)
   say "1"
;

if (a is 48 - 1 and
   a isnt 49
) =>
   say "2"

if likely true =>
   i = 1

   if (a is
         48 - 1 and
      (not(a is 49) or a isnt 49)
   ):
      say "3"

   while i > 0
      i -= 1
      say "3.1" if true isnt false
      if likely not (true is false)
         say "3.2"
      if true => say "3.3"
      if true do say "3.4"
      if true then say "4 "; say "5"; if true then say "5.1"
      if unlikely false: say "NO" else do say "5.2a "; say "5.3a"; if true: say "5.4a"
      if false: else do say "5.2b "; say "5.3b"; if true => say "5.4b"
      if false =>
         -- comment after indent
         if 47 => say "NO"
         -- for i in 0..6 => p i.to–s; say "."
         if 47: say "NO"
      if true
         -- comment after indent
         if not false then say "6"
         -- for i in 0..6 => p i.to–s; say "."
         if 47 => say "7"

   end -- end–while -- -while
end -- end–if
-- if (a == 47
--    && a != 48
-- )
--    say "Yeay 47 == 47"

-- zoo( \
--    a, \
--    b, \
--    c Int32 \
-- ) ->
--    Str.new(a + b) + c.to–s
-- end

-- ab=(v)
--    @prog–v = v
-- end


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

[ab, ac] = [3, 2]
[aa, ab, ac, ad] = [1, ac, ab, 4]
say "should be 3: " + ac.to–s

DEBUG–SEPARATOR

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- -#pure -#private
-- # private
-- zoo*(a; b; ...c 'Intp) -> Str  'pure  # *TODO* variation two (type after arrow)
zoo*(a; b; ...c 'Intp) -> Str  'pure
   if true:
      i = 1

      if (a == 1 &&
         a >=
          0 &&
         a <=
          9999 &&
         a != 2
      ) =>
         say "8"

      while i > 0
         i -= 1
         if true => say "9 "; say "10"
         if false =>
            -- comment after indent
            if 41 => say "NO"
            elsif 42 => say "NO"
            elif 43 => say "NO"
            else => say "NO"

            -- for i in 0..6 => p i.to–s; say "."
            if 47 => say "NO"
         else
            say "11"
            for val[ix] in <["c", "b", "a"]> by 2
               p "{val}, {ix}"

         if true
            -- comment after indent
            if 47 => say "12"
            -- for i in 0..6 => p i.to–s; say "."

            if !47 => say "NO" else => say "12"; end; if 1 => say "13"; end;

            if 47 => say "14" else say "NO"; end; if 1 => say "15";

            -- new idea for else syntax when symbolic style:

            -- if !47 => say "nop2" *> say "yup3"; end; if 1 => say "more yup3";
         --end–while -- explicit bug to test errors
      end
      -- end–while -- -while

   end -- end–if


   qwo = "{(a + b)} {c.to–s}"
   (a + b).to–s + " " + c.to–s + " == " + qwo
end

-- 'literal-int=Intp

p zoo 1, 2, 47, 42

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

reg–ex = /foo (ya)(.*)/i
m1 = "asdf foo ya fdsa".match reg–ex
m2 = "fda" =~ reg–ex

say "m1 = " + m1.to–s
say "m2 = " + m2.to–s

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -


qwo(a 'Intp, b ~Intp) ->
end

qwo2(a ^Intp, b 'Intp) -> end

-- qwo3(a 'Intp, b mut Intp) -> Str -- Str  -- should fail - *TODO* error message points to +3 cols
qwo3(a 'Intp, b mut Intp) -> Str => "foo" -- Str

qwo4(a Intp; b Intp) ->
end

qwo2 1, 2

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

foo-list = Li<Li<Li<Str>>> 1
say foo–list

n = 4747 >> 3
n >>= 1
m = 4747 << 3
m <<= 1

say "n = " + n.to–s + " from " + 4747.to–s
-- say "n = " + $n + " from " + $4747



-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- type TradeSide < Enum<Int8>
-- enum TradeSide Int8
enum TradeSide < Int8
   Unknown
   Buy
   Sell


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- crystal style 1 `switch ref`
switch n
when 1, 2
   say "NOP: is 1|2"
when 2
   say "NOP: is 3"
else
   say "16:  " + n.to–s
end

-- crystal style 1 `case`
branch
when n == 1
   say "NOP 1"
when n == 47, n == 593
   say "17"
else
   say "NOP " + n.to–s
end

-- crystal style 1B `switch ref`
switch n
case 1, 2
   say "NOP: is 1|2"
case 2
   say "NOP: is 3"
else
   say "17.1:  " + n.to–s

-- crystal style 1B `case`
branch
when n == 1
   say "NOP 1"
when n == 47, n == 593
   say "17.2"
else
   say "NOP " + n.to–s

-- crystal style 2 `switch ref`
switch n
   when 1, 2
      say "NOP: is 1|2"
   when 2
      say "NOP: is 3"
   else
      say "17.3: " + n.to–s
end

-- crystal style 2 `case`
branch
   when n == 1
      say "NOP 1"
   when n == 47, n == 593
      say "17.4"
   else
      say "NOP " + n.to–s
end

-- onyx style 1 `switch ref`
match n
   593
      say "18"
   2 =>
      say "NO is 2"
   *
      say "NO " + n.to–s
end

-- onyx style 1 `case`
branch
   n == 1 =>
      say "NO is 1"
   n == 593 =>
      if false
      else
         say "19"
   * =>
      say "NO " + n.to–s
end -- end–branch  -- revisit end-handling

-- onyx style 2 `switch ref`
match n
   593
      say "19.1"
   2 =>
      say "NO is 2"
   *
      say "NO " + n.to–s

-- onyx style 2 `case`
branch
   n == 1
      say "NO is 1"
   n == 593 =>
      if false
      else
         say "19.2"
   *
      say "NO " + n.to–s

-- onyx style 3 `switch ref`
match n
   1 => say "is 1"
   2 => say "is 2"
   * => if false => say "NO" else say "20: " + n.to–s
end -- end–branch

-- onyx style 3 `case`
branch
   n == 593   => say "21"
   n == 2     => say "is 2"
   *          => say n.to–s

-- onyx style 4 `switch ref`
switch n
   1 do say "is 1"
   2 then say "is 2"
   * do if false then say "NO" else say "22: " + n.to–s

-- onyx style 4 `case`
branch
   n == 593   then say "23"
   n == 2     do say "is 2"
   *          then say n.to–s

-- onyx style 5 `switch ref`
match n
| 593
   say "23.1"
| 2 =>
   say "NO is 2"
| *
   say "NO " + n.to–s

-- onyx style 5 `case`
branch
   | n == 1
      say "NO is 1"
   | n == 593 =>
      if false
      else
         say "23.2"
   | *
      say "NO " + n.to–s

-- onyx style 6 `switch ref`
match n
   1: say "is 1"
   2: say "is 2"
   *: if false => say "NO" else say "20: " + n.to–s
end -- end–match

-- onyx style 6 `case`
branch
   n is 593   : say ": 23.3a"
   n is 2     : say "is 2"
   *          : say n.to–s

-- onyx style 6b `case`
branch
   n == 593:   say ": 23.3b"
   n == 2:     say "is 2"
   *:          say n.to–s

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

for v[i] in [#apa, #katt]: say ": {i}: {v}"

if true: say ": true"

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

foo(a, b, c Str) ->
   (a + b).to–s + c
end

x = foo a, 2, "1"

a = (a Intp, b Intp) -> (a + b).to–s; end
b = (a Str, _ Intp, b 'Bool; c Real) ->
   "{a} {x}" -- t"{a} {x}"

say "23.4 def lambda c"
c = (a ~Intp, b 'Str, c 'Intp) -> a.to–s + b + c.to–s

-- '!real-literal=Float64
p b.call "23.5a Closured Lambda says", 0, true, 0.42
p b "23.5b Closured Lambda says", 1, true, 0.47

pp typeof(b), b.i-type

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- type Fn = Lambda  -- in default type layer now

-- two funcs with each two params taking lambdas, declared with canonical type
-- syntax and lambda-style type syntax respectively
booze1(f1 Fn<Int32,List<*>,List<List<Ptr<Int32>>>>, f2 Lambda<Str, Nil, List<Bool>>) ->
booze2(f1 (List<*>, List<List<Ptr<Int32>>>) -> Int32, f2 (Nil, List<Bool>) -> Str) ->

say "List<List<Ptr<Int32>>> => " + List<List<Ptr<Int32>>>.to–s
-- say "Li<Li<Ptr<Int32>>> => " + Li<Li<Ptr<Int32>>>.to–s

booze2(f1 (Int32,auto) -> Nil; f2 (Str) -> Nil) ->

-- This notation of Lambdas-Type has been depreceated
-- booze3(f1 (Int32, * -> Nil); f2 (Str -> Nil)) ->
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- *TODO* (OR NOT)

-- -- a–closure–lambda1 = [&i,=v](a, b) -> do–shit(a, b, @i, @v)
-- -- a–closure–lambda2 = ([&i,=v]; a, b) -> do–shit(a, b, @i, @v)
-- -- a–closure–lambda3 = {&i,=v}(a, b) -> do–shit(a, b, @i, @v)

-- Self == "this type"
-- this == "this instance"  -- or:
-- me == "this instance" ?  -- or:
-- my == -""-

-- for: to_s for onyx and crystal must spit out the for–loop
-- for: while–loops for the 'stepping' switch must be generated

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

list = [#abra, #baba, #cadabra]

say "the tag list ({list.i-type}): {list}"

list = ["foo", "yaa", "qwö"]

say "the str list ({list.i-type}): {list}"


--- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- ---
say "`in`/`in?` operator"

say "foo" in list is true
say 47 in list is true
say "foo" in? list is true
say 47 in? list is true
say "foo" isnt in list is true
say 47 not in list is true
say "foo" is in? list is true
say 47 is in list is true


--- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- ---
say "Iterating and fragments"

-- single line fragment style #2
y = list.each((v) ~> p v).map ~.* 2

-- multiline fragment style #2
y = (list.each (v) ~>
   p v
).map ~>
   _1 * 2


y = list
.each ~>
   p _1
.map ~>
   _1 * 2

say "mega fettma y = {y}"

list.each–with–index ~>
   p _1
   if _2 == 4
      break
   end

(list.map ~> _1 + "X").each-with-index ~>
   p _1
   break if _2 == 4

list.each-with-index (v, i) ~>
   p v
   if i == 4 => break

(list.map (x) ~> x + "X").each-with-index (x, y) ~>
   p x
   break if y == 4

list.each-with-index ~>
   p _1
   if _2 is 4 then break

list.each-with-index \
   break if _2 == 1


say "auto params using `%n`"

list.each-with-index \
   p %1
   break if %2 is 4

(list.map \\%1.+ "X").each-with-index \
   p %1
   break if %2 == 4

(list.map \.+ "X").each-with-index \
   p %1
   break if %2 == 4

list.each-with-index (v, i)\
   p v
   break if i == 4

(list.map (x)\ x + "X").each-with-index (x, y)\
   p x
   break if y == 4

list.each-with-index \
   p %1
   break if %2 == 4



-- for i from 0 til 10
--    say "from til loop {i}"


-- -- list.each_with_index ~>
-- --    p _1
-- --    break if _2 == 4
-- -- list.each ~> p _1
-- -- list.each ~> p _1
-- -- list.each ~> p _1
--

-- -- foo–list = [1, 2, 3]
-- -- mapped–list    = foo–list.map (x)-} x * 2
-- -- mapped–list2   = foo–list.map ~} _1 * 2
-- -- say "Mapped list: {mapped–list}"

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

list.each (val) ~>
   say("implicit nest {val.to-s}")

list.each (val)\
   say("implicit nest {val.to-s}")

list.each ~>
   say("implicit nest {_1.to-s}")

failing-fragment = true

list.each \
   say("implicit nest {_1.to-s}")

list.each \\ say("implicit nest {_1.to-s}")
list.each \\say("implicit nest {_1.to-s}")

for val in list
   say val

for val in list =>
   say val

for crux in list do say "do nest" + crux.to_s
for arrowv in list => say "=> nest" + arrowv.to_s
for spccolonv in list : say "\\s: nest" + spccolonv.to_s
for colonv in list: say ": nest" + colonv.to_s

for ,ix in list
   if true throughout
   say "begins-block:"
   say "  {ix}"

for val, ix in list
   say "{val}, {ix}"

for ix: val in list
   say "{val}, {ix}"

for ix:val in list
   p "{val}, {ix}"

for ix: in list
   say ix

for val[ix] in list
   say "{val}, {ix}"

for [ix] in list
   say ix

for val[ix] in ["c", "b", "a"]
   say "{val}, {ix}"

for val[ix] in {"c", "b", "a"}
   say "{val}, {ix}"

for val[ix] in {"c", "b", "a"} -- by -1
   say "{val}, {ix}"

for val[ix] in ["c", "b", "a"] -- by 2
   say "{val}, {ix}"


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

trait TheTrait
   is–cool–traited?() -> true
end -- end–trait

-- *TODO* - should really be able to add data, props, etc. EVERYTHING as in type!
trait AnotherTrait<S1>
   -- *TODO* inited another-val below doesn't catch-all in sub-types!
   -- @another–val = 0  -- "can't use instance variables at the top level"
   @a-t-val S1

   -- val() -> @another–val
   valhalla() -> abstract
   -- valhalla2() -> abstract; say 47 -- should fail - and does
   valhalla3() -> abstract
end

type Qwa 'abstract
   mixin TheTrait
end -- end–type

type Bar < Qwa
   @@my–foo Int64 = 47i64
   @@some–other–foo 'Intp = 42
   @@yet–a-foo = 42

   -- '!literal-int=Int32

   -- *TODO* use-switch for this?
   -- Self.RedFoo = 5
   -- Self.GreenFoo = 7

   RedBar = 6
   GreenBar = 8

   @foo–a Str = ""
   @foo–b Intp = 0_i64
   @foo–c Int64 = 0_i64
   @foo-ya Int32 = 0i32

   Self.set–foo(v) ->
      @@my–foo = v

   Self.get–foo() ->
      @@my–foo

Bar.set-foo 4
say "Bar.get-foo = {Bar.get-foo}"

say "declare a Foo type"



--
-- *TODO*
--
-- add tests for
--  splat type params
--  named type params


--| The "normal" Foo which is expressed with arrow function syntax
type Foo<LongGenericPar> < Bar
   mixin AnotherTrait<LongGenericPar>

   -- "free" notation at member declaration
   @foo–x Int64 = 47_i64  'get 'set
   @foo–y = 48
   @foo–z = "bongo"  'get
   @foo–u Intp = 47  'get 'set

   -- *TODO* WTF!
   @foo-w = 474242       'set
   @foo–w = 474747       'set

   -- at-notation at declaration too?
   ifdef x86_64
    @bar–x  Int64  = 47_i64  'get 'set
   else
    @bar–x Int32  = 47_i32  'get 'set

   @bar–y        = 48
   @bar–z        = "bongo"  'get
   @bar–u  Intp = 47  'get 'set
   @bar–w       = 47  'get

   ifdef x86_64
    init(a LongGenericPar) ->
       @foo–a = a
       @a-t-val = a
   else
    init(b LongGenericPar) ->
       @foo–a = b
       @a-t-val = a
   end

   init() ->
      @a-t-val = ""

   -- say "Hey in Foo"  -- NOT LEGAL ANYMORE!



   -- *TEMP*
   get-foo-w() -> @foo-w


   'pure
   fn–1aa(x) -> nil  -- 'public   -- should this be legal? - looks very confusing!
   'pure
   -- fn–1ab(x) -> Nil; nil  'pure -- 'public   -- should this be legal? - looks very confusing!
   fn–1ab(x) -> Nil: nil  'pure -- 'public   -- should this be legal? - looks very confusing!
   fn–1abb(x) -> Nil

   'inline 'pure
   fn–1ba*(x) ->! nil
   fn–1ca(x) ->!  'pure
   fn–1da(x) -> nil
   fn–1ea(x) ->! nil
   fn–1fa(x) ->!

   fn–1ga(x) ->!
      ifdef x86_64
         say "Hey"
      else
         say "you!"
   ;
   -- This should fail on parse because of ret-type + nil-ret flag
   -- fn–1h(x) -> String!
   --    say "Hey"
   --    say "you!"
   --    "fdsa"

   -- Should Error _iff_ instantiated, because of mismatching return type
   fn–1i(x) ->!
      say "Yeay"
      return "Foo"

   fn–a(a, b) -> "a: {a}, {b}" 'pure

   fn–b(a LongGenericPar, b Intp) -> -- fdsa
      "b: {a}, {b}"

   -- fn–c*(a, b LongGenericPar) -> LongGenericPar 'redef 'inline
   fn–c*(a, b LongGenericPar) -> LongGenericPar 'redef 'inline
      "c: {a}, {b}"

   end -- end–def

   --# protected
   -- fn–c(a, b Int32) redef protected ->
   fn–c**(a, b Intp) -> 'redef
      "c: {a}, {b}"

   fn–d1(a, b) ->
      @foo–a = a
      @foo–b = b
      fn–e
   end

   fn–d2(a LongGenericPar, b Intp) ->
      @foo–a = a
      @foo–b = b
      fn–e

   -- fn–d3(a LongGenericPar, b T) ->
   --    @foo–a = a
   --    c 'T
   --    c = b
   --    @foo–b = c
   --    fn–e

   fn–e() -> fa = @foo–a ; "e: {fa}, {@foo_b}"

   'flatten
   call() -> fn–e

   [](i) -> @foo–b + i

end -- end–type

-- *TODO* type level 'pure'/'mepure' spec - should be possible to "make" the
-- type that (all monkey patches obey it), and also a LEXICAL variant which
-- rules only in the specific lexical declaration context (for adding a bunch of
-- pure funcs to Program for instance

--| A Foo type in style 2 (non-arrow function defs)
--| <LongGenericPar> is primary variable type
type FooStyle2<LongGenericPar> < Bar
   mixin AnotherTrait<LongGenericPar>

   -- "free" notation at member declaration
   @foo–x Int64 = 47_i64  'get 'set
   @foo–y = 48
   @foo–z = "bongo"  'get
   @foo–u Intp = 47  'get 'set
   @foo–w = 47       'set

   -- at-notation at declaration too?
   ifdef x86_64
      @bar–x Int64 = 47_i64  'get 'set
   else
      @bar–x Int32 = 47_i32  'get 'set

   @bar–y = 48
   @bar–z = "bongo"  'get
   @bar–u Intp = 47  'get 'set
   -- getter @bar–w = 47
   @bar–w = 47       'get

   --| Initialize with primary variable type
   ifdef x86_64
      -- init(a LongGenericPar)
      init(a LongGenericPar) ->
         @foo–a = a
         @a-t-val = b
   else
      -- init(b LongGenericPar)
      init(b LongGenericPar) ->
         @foo–a = b
         @a-t-val = b
   end

   -- init()
   init() ->
       @a-t-val = ""

   -- say "Hey in Foo"  -- NOT LEGAL ANYMORE!

   --| Do some 1aa action!
   'pure
   fn–1aa(x) -> 'pure;  nil   -- should this be legal? - looks very confusing!
   fn–1ab(x) -> Nil 'pure:  nil   -- should this be legal? - looks very confusing!
   -- fn–1ab(x) -> Nil 'pure:  nil   -- should this be legal? - looks very confusing!

   -- (private ) ~>inline
   'inline 'pure
   fn–1ba*(x) ->! nil
   fn–1ca(x) ->!
   fn–1da(x) -> nil 'pure
   fn–1ea(x) ->! nil 'pure

   fn–1fa(x) ->!

   fn–1ga(x) ->!
      ifdef x86_64
         say "Hey"
      else
         say "you!"
   ;

   -- This should fail on parse because of ret-type + nil-ret flag
   -- fn–1h(x) -> String!
   --    say "Hey"
   --    say "you!"
   --    "fdsa"

   -- Should Error _iff_ instantiated, because of mismatching return type
   -- fn–1i(x)!
   fn–1i(x) ->!
      say "Yeay"
      return "Foo"

   fn–a(a, b) -> "a: {a}, {b}"

   -- fn–b(a LongGenericPar, b Intp) -- fdsa
   fn–b(a LongGenericPar, b Intp) -> -- fdsa
      "b: {a}, {b}"

   -- fn–c*(a, b LongGenericPar) -> LongGenericPar 'redef 'inline
   fn–c*(a, b LongGenericPar) -> LongGenericPar 'redef 'inline
      "c: {a}, {b}"
   end -- end–def
   -- end fn–c

   fn–c**(a, b Intp) -> 'redef
      "c: {a}, {b}"

   -- fn–d1(a, b)
   fn–d1(a, b) ->
      @foo–a = a
      @foo–b = b
      fn–e
   end

   -- fn–d2(a LongGenericPar, b Intp)
   fn–d2(a LongGenericPar, b Intp) ->
      @foo–a = a
      @foo–b = b
      fn–e

   fn–e() -> fa = @foo–a ; "e: {fa}, {@foo_b}"

   'flatten
   call() -> fn–e

   [](i) -> @foo–b + i

end -- end–type
-- *TODO* Anonymous types!
-- anon-typed = new Bar
--    mixin AnotherTrait<Int64>

--    fn-x(x) -> "I am Anon"

say "create a Foo instance"
foo = Foo<Str>()

pp foo.implements? #foo-x
pp foo.implements? #foo_x
pp foo.implements? foo-x
pp foo.implements? foo_x
pp foo.implements? foo_zz
pp foo.implements? TradeSide
pp foo.implements? Foo
pp foo.implements? Bar
pp foo.implements? AnotherTrait
pp foo.implements? Any
pp foo.implements? Struct
pp foo.implements? Value
pp foo.implements? Intp

pp 1_i32.implements? Intp
pp 1_i64.implements? Intp

pp 1_u32.implements? Intp
pp 1_u64.implements? Intp

pp 1_u8.implements? Any
pp 1_u8.implements? Value
pp 1_u8.implements? Struct
pp 1_u8.implements? Intp
pp 1_u8.implements? Int -- AnyInt
pp 1_u8.implements? Int32
say 1_u8.implements? Int32
pp 1_u8.implements? UInt8
say 1_u8.implements? UInt8

pp foo.foo-x

-- *TODO* this doesn't work out as it should! foo-w is never set!!!??
say "foo.foo-w = 463"
foo.foo-w = 463

dpp foo.foo-w = 461

say "foo.get-foo-w {foo.get-foo-w}"
-- pp foo.foo-y -- should fail
-- pp foo.foo-w -- should fail

say "done"
say foo.fn–a "24 blargh", 47
say foo.fn–b "25 blargh", 47
-- say foo.fn–c "26 blargh", 47   -- should fail: private
say foo.fn–d1 "27 blargh", 47
foo.fn–d2 "28 blargh", 47
say foo.fn–e

-- boo = Foo<Str>()
-- boo = Foo‹Str›()
-- boo = Foo⟨Str⟩()
-- boo = Foo❬Str❭()
-- boo = Foo⟦Str⟧()
-- boo = Foo❰Str❱()
-- boo = Foo⦇Str⦈()
-- -- boo = Foo⦉Str⦊()
-- -- boo = Foo〚Str〛()

boo = Foo‹Str›()
boo = Foo‹Str›.new
boo = Foo‹Str›.new()

bar = Foo<Str>("No Blargh")
bar = Foo("No Blargh")
bar = Foo "29 Blargh"

say "done"
say bar.fn–e
say "functor call"
say bar()
bar.fn–d2 "30 blargh", 47

say "varying word-delimiters"
say bar.fn–e
say bar.fn-e
say bar.fn_e
-- say bar.fnE

say "shit-sandwich"
shit-sandwich =  bar.fn-e -- fnE
-- shitSandwich = "arghh"
-- say shitSandwich

say bar.call()
say bar()

-- foo.valhalla  -- should fail - abstract
-- say bar.fn-1i(1)  -- should make fn-1i fail because it has mismatching return type

say typeof(foo)
say foo.i-type

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

say "7 .&. 12 == { 7 .&. 12 }"
say "12 .|. 1 == { 12 .|. 1 }"
say "12 .^. 2 == { 12 .^. 2 }"
say ".~. 12 == { .~. 12 }"

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- Suffix-if - possible change:
-- *NOTE* - perhaps it should be supported to set var in cond and it's avail in prefix then-branch

-- say "Yes indeed we got {if-var}" if if-var = 47

-- tmp(x) ->
--    return a if (a = x)
--    say "Got a {a}"

-- tmp 4747

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
-- Try some C FFI API

-- NOTE! This is already available wrapped in the BigInt-type - which implements
-- all operators so it can be used like any other number type. This example is
-- just to show how c-lib interfacing is written in Onyx.

'link("gmp")

api MyLibGmp
   TEST_CONST = 47

   alias Int = LibC.Int
   alias Long = LibC.Long
   alias ULong = LibC.ULong
   alias SizeT = LibC.SizeT
   alias Double = LibC.Double

   ifdef x86_64
      alias TestT = UInt64
   else
      alias TestT = UInt32
   end

   struct Mpz
      _mp_alloc Int32
      _mp_size  Int32

      -- Just testing `ifdef` in all contexts
      ifdef x86_64
         _mp_d     Ptr<ULong>
      else
         _mp_d     Ptr<ULong>
      end
   end

   alias MpzP = Ptr<Mpz>

   -- init = __gmpz_init(x MpzP) -> Void
   -- init_set_si = __gmpz_init_set_si(rop MpzP, op Long) -> Void
   -- init_set_str = __gmpz_init_set_str(rop Ptr<Mpz>, str Ptr<UInt8>, base Int) -> Void
   --
   -- get_si = __gmpz_get_si(op MpzP) -> Long
   -- get_str = __gmpz_get_str(str Ptr<UInt8>, base Int, op MpzP) -> Ptr<UInt8>
   --
   -- add = __gmpz_add(rop MpzP, op1 MpzP, op2 MpzP) -> Void
   -- set-memory-functions = __gmp_set_memory_functions(malloc '(SizeT)->Ptr<Void>, realloc '(Ptr<Void>,SizeT,SizeT)->Ptr<Void>, free '(Ptr<Void>,SizeT)->Void ) -> Void

   init = __gmpz_init(x MpzP) -> Void
   init_set_si = __gmpz_init_set_si(rop MpzP, op Long) -> Void
   init_set_str = __gmpz_init_set_str(rop Ptr<Mpz>, str Ptr<UInt8>, base Int) -> Void

   get_si = __gmpz_get_si(op MpzP) -> Long
   get_str = __gmpz_get_str(str Ptr<UInt8>, base Int, op MpzP) -> Ptr<UInt8>

   add = __gmpz_add(rop MpzP, op1 MpzP, op2 MpzP) -> Void
   set-memory-functions = __gmp_set_memory_functions(malloc '(SizeT)->Ptr<Void>, realloc '(Ptr<Void>,SizeT,SizeT)->Ptr<Void>, free '(Ptr<Void>,SizeT)->Void ) -> Void
   -- set-memory-functions-2 = __gmp_set_memory_functions(
   --                               malloc '(SizeT)->Ptr<Void>,
   --                               realloc '(Ptr<Void>,SizeT,SizeT)->Ptr<Void>,
   --                               free '(Ptr<Void>,SizeT)->Void
   --                            ) Void

end

-- indent call style
MyLibGmp.set-memory-functions
   (size) -> GC.malloc(size)
   (ptr, old_size, new_size) -> GC.realloc(ptr, new_size)
   (ptr, size) -> GC.free(ptr)

-- indent call style 2
MyLibGmp.set-memory-functions
   (size) ->
      GC.malloc(size)

   (ptr, old_size, new_size) ->
      GC.realloc ptr, new_size

   (ptr, size) ->
      GC.free ptr

-- old school call style
MyLibGmp.set-memory-functions(
   (size) ->
      GC.malloc(size)
   , (ptr, old_size, new_size) -> GC.realloc(ptr, new_size); end,
   ((ptr, size) -> GC.free(ptr))
)

x = 7
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- add-as-big-ints(a T, b T) ->
add-as-big-ints(a, b) ->
   -- bigret 'MyLibGmp.Mpz
   bigv1 = raw MyLibGmp.Mpz
   -- bigv1 = MyLibGmp.Mpz.alloc
   -- bigv1 'MyLibGmp.Mpz
   -- bigv2 'MyLibGmp.Mpz - implicitly created with `out` arg modifier
   -- y = MyLibGmp.Mpz.raw  -- optimally only like this - and escape analysis takes care of stack|heap choice
   -- y '= raw MyLibGmp.Mpz  -- optimally only like this - and escape analysis takes care of stack|heap choice
   -- z = ?MyLibGmp.Mpz  -- optimally only like this - and escape analysis takes care of stack|heap choice

   MyLibGmp.init out bigret

   -- if T == Str
   if a.of? Str
      MyLibGmp.init-set-str pointerof(bigv1), a, 10
   else
      MyLibGmp.init-set-si pointerof(bigv1), a
   end

   -- if b.of? Str
   --    MyLibGmp.init-set-str out bigv2, b, 10
   -- else
   --    -- Catch 22:

   --    -- WILL FAIL, because it's already "outed" above:
   --    -- MyLibGmp.init-set-si out bigv2, b

   --    -- WILL FAIL, because above "doesn't happen" when non-Str-path is taken:
   --    -- MyLibGmp.init-set-si pointerof(bigv2), b  -- used to (falsely) work - now fails - ORC/160830

   -- end

   --# Temporarily until above is sorted out:
   bigv2 = raw MyLibGmp.Mpz
   if b.of? Str
      MyLibGmp.init-set-str pointerof(bigv2), b, 10
   else
      MyLibGmp.init-set-si pointerof(bigv2), b
   end

   MyLibGmp.add pointerof(bigret), pointerof(bigv1), pointerof(bigv2)
   result = Str MyLibGmp.get-str nil, 10, pointerof(bigret)

   say "bigint add result: { result }"


pp MyLibGmp.TEST_CONST

add-as-big-ints 42, 47
add-as-big-ints "42", "47"
add-as-big-ints "42", 47
add-as-big-ints(
   "42543453146456243561345431543513451345245643256257798063244",
   "47098098432409798761098750982709854959543145346542564256245"
)


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
-- Reaching, scopes and visibility:

-- Onyx, arguebly cleaner, hierarchical access syntax handles all Crystal constructables

-- # Should work:
say "Non self-extended:".white
p "CrystalModule", CrystalModule
p "CrystalModule.ROOT_CONST", CrystalModule.ROOT_CONST
p "CrystalModule.CrystalClass", CrystalModule.CrystalClass
p "CrystalModule.CrystalClass.CLASS_ROOT_CONST", CrystalModule.CrystalClass.CLASS_ROOT_CONST
p "CrystalModule.self_def", CrystalModule.self_def
p "CrystalModule.CrystalClass.class_func", CrystalModule.CrystalClass.class_func

-- # Should not work
-- pp "CrystalModule.MODULE_CONST", CrystalModule.MODULE_CONST
-- pp "CrystalModule.CrystalClass.CLASS_CONST", CrystalModule.CrystalClass.CLASS_CONST
-- pp "CrystalModule.root_def", CrystalModule.root_def
-- pp "CrystalModule::CrystalClass.memb_func", CrystalModule::CrystalClass.memb_func

-- # Should work if `extend self`:
say "self-extended (includes root_def):".white
p "CrystalModule2", CrystalModule2
p "CrystalModule2.ROOT_CONST", CrystalModule2.ROOT_CONST
p "CrystalModule2.CrystalClass", CrystalModule2.CrystalClass
p "CrystalModule2.CrystalClass.CLASS_ROOT_CONST", CrystalModule2.CrystalClass.CLASS_ROOT_CONST
p "CrystalModule2.self_def", CrystalModule2.self_def
p "CrystalModule2.CrystalClass.class_func", CrystalModule2.CrystalClass.class_func
p "CrystalModule2.root_def", CrystalModule2.root_def

-- # Should not work despite `extend self`:
-- pp "CrystalModule.MODULE_CONST", CrystalModule.MODULE_CONST
-- pp "CrystalModule.CrystalClass.CLASS_CONST", CrystalModule.CrystalClass.CLASS_CONST
-- pp "CrystalModule::CrystalClass.memb_func", CrystalModule::CrystalClass.memb_func

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
-- This module begins here and continues to EOF
module AllTheRest below -- begins, below, (follows), throughout

struct RestFoo
   rest-foo() ->
      true

extend RestFoo
   other-foo() ->
      false

ext RestFoo
   -- rest-foo() -> Bool 'redef
   rest-foo() -> Bool 'redef
      false

xx = 47
yy = 47.47


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
say "{ "foo".magenta }, { "bar".grey }, { "qwo".white }"
say "{ "foo".magenta2 }, { "bar".grey2 }, { "qwo".white }"
say "All DOWN ".red
say "         AND OUT".red2
