-- Test all possible constructs in one go
say "\n\nBefore requires!\n\n"

require "./crystal-scopes"
require "wild_colors"

say "\nLet's ROCK\n".red

say %s(\nfunction(foo) { SomeJsCode(foo("bar}")); }\n)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

_debug_start_ = true

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- *TODO* maddafuckin templates and macros!
--
-- -- template pow2-round-up(v, r) =
-- -- template pow2-round-up(v, r) ->
-- macro pow2-round-up(v, r) =
--    {% if r != 2 || r != 4 || r != 8 || r != 16 || r != 32 || r != 64 ||
--          r != 128 || r != 256 || r != 512 || r != 1024 || r != 2048 ||
--          r != 4096 || r != 8192 || r != 16378 || r != 32768 || r != 65536
--    %}
--       raise "pow2-round-up requires a single power-of-two value as rounding ref"
--    {% else %}
--       (
--          -- silly thing to do, caching a constant expr, but we're testing all features here, m'kay!
--          %ref-v = {{r}} - 1
--          ({{v}} + %ref-v) .&. (.~. %ref-v)
--       )
--    {% end %}
-- end

-- pp 4096 == pow2-round-up 3027, 4096
-- pp 8192 == pow2-round-up 4097, 4096
-- pp 8192 == pow2-round-up 4097, 4093 -- Should fail!

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- \!Int=I64
-- \!Real=Float32

\!literal-int=I64
\!literal-real=Float32

-- *TODO* *TEMP*
type Ints = StdInt
type Real = Float64

type MoreInts = Int32 | Int64 | I8

say MoreInts

type SomeFacts < flags U8
   AppleLover
   PearLover
   CoolDude
end

facts = SomeFacts.flags AppleLover, CoolDude
say "facts: {facts}"
say typeof(facts)

facts = facts.|. SomeFacts.PearLover
say "facts: {facts}"

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- *TODO*
-- change soft lambda syntax?
-- /\|([\w, ]+?)\|/   =>   "($1) ~>"

MY_CONST = do
   x = 0
   2.upto(4).each |a|
      x += a
      say "calculating MY_CONST, {a}"
   x

pp MY_CONST
-- *TODO* $.say / Program.say ?
pp $.say "blargh"
-- *TODO* $.MY_CONST / Program.MY_CONST ?
pp $.MY_CONST
pp ::MY_CONST
-- pp Program.MY_CONST

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

$my-global = 47
$my-typed-global 'I32
\!literal-int=Int32
$my-typed-and-assigned-global 'I32 = 47
$my-global = $my-typed-and-assigned-global

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

module Djur
   module Boo begins

   APA = 47

   type Apa < object Reference
      \!literal-int=I64

      Self.foo = 1
      Type.bar = 2

      @foo     Ints
      bar      Ints
      @foo’    Ints  = 47
      bar’           = 47
      @foo’’   Ints
      bar’’    Ints

      foo3 'Ints
      bar3 ^Ints
      qwo3 ~Ints

      -- xfoo! Ints = 47  -- should fail, and does
      -- xbar? Ints = 42  -- should fail, and does

      Type.my-def() -> say "Hit the spot! { Type.foo’ }, { @@bar }"
      inst-def() -> say "Hit the spot! { @foo’ }, { @bar }"
   end

   --enum Legs
   type Legs < enum
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

      Type.is-six?(v) ->
         v == SIX
   end
end

-- module Djur
--    module Boo
--       APA = 42 -- *NOTE* - should we change behaviour so that consts can be monkey overridden too?
--    end
-- end


say "1"

Djur::Boo::Apa.my-def
say "Djur::Boo::Legs::TWO = {Djur::Boo::Legs::TWO}"

-- say Djur.Boo.Apa.foo’ -- *NOTE* perhaps a better error message: "No method with the name `{name}` found, only a private variable. Make a getter and/or setter method to access it from the outside world"
Djur.Boo.Apa.my-def
say "Djur.Boo.Legs.TWO = {Djur.Boo.Legs.TWO}"
say "Djur.Boo.Legs.is-six?(EIGHT) = {Djur.Boo.Legs.is-six?(Djur.Boo.Legs.EIGHT)}"


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- t = Time.Span(0)
-- t = Time.Span 0

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

type Blk
   init(x, &block) ->  -- (T) -> U - does not work for block...
      yield x + 1
      yield x - 2
   ;
;

blk = Blk(4, |x|
   say "in blk init block: {x}"
)

blk2 = Blk 7, |x|
   say "in blk2 init block: {x}"


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

trait Functor
--   call() -> abstract
end

type MyFunctor
   mixin Functor

   foo = 47

   call() -> "call()"

   call(a, b) -> "call {a}, {b}, {@foo}"

   bar() -> true

end

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


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- reopen String type and override '<<' operator to act as "concat" (like '+',
-- but auto-coercing)
type String: <<(obj) -> "{self}{obj}"

say("fdaf" + "fdsf" << "aaasd" << 47.13 << " - yippie!")


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

fun-with-various-local-vars(a I32|I64|Real = 0) ->!
   say "a type = {typeof(a)}"

   -- declare assign with type inference
   zar1 = 1


   -- -- *TODO* after all basic control structs are implemented

   -- zar2 ^Ints
   -- zar4 'Real
   -- zar3 ~Str

   -- -- zar4 'Ints = 1
   -- -- zar5 ~Ints = 1
   -- -- zar6 ^Ints = 1
   -- -- zar7 '= 1
   -- -- zar8 '*= 1
   -- -- zar9 'auto = 1

   -- pp zar2.class, zar4.class, zar3.class
   -- -- May currently crash - all values are undefined becaused they're alloca'd
   -- -- when typed currently. They should _not_ be. ONLY typed for TySys!
   -- -- pp zar2, zar4, zar3

   say "fun-with-various-local-vars {zar1}" -- , {LocalConst}"


fun-with-various-local-vars 47

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

fun-with-exception-action(x) ->!
   try:
      a = 1 / 0

   rescue e IndexError | ArgumentError do
      say "In fun: Rescued {e}"

   rescue DivisionByZero:
      say "In fun: Rescued divizon by zero"

   rescue e =>
      say "Rescued some kind of shit"

   fulfil:
      say "In fun: Nothing to rescue - yippie!"

   ensure do
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


\!literal-int=I64

foo-named(awol, foo = 47, bar = "fds") ->!
   say "{awol}, {foo}, {bar}"

foo-named 1, "blarg", "qwö qwö"
foo-named 2, 42, #bar = "yo"
foo-named 3, #foo = 11, #bar = "yo"

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

list = List[Str]()
list << "foo"
list << "yaa"

v = list.map(|x, y| x + "1")
w = list.map |x, y| "{x} 47"
i = list.map |x, y| => "{x} 13"
j = list.map ~> "{_1} 13"

puts "{v}, {w}"


list = [47, 13, 42, 11]
x = list.each(|v| p v).map(~> _1 * 2)
y = ((list.each(|v| p v)).map(~> _1 * 2))
z = list.each(|v| p v).map ~> _1 * 2
u = list.each(|v| p v).map ~> _1 * 2

-- def say(s) -> puts s

\!literal-int=I32

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

-- *TODO*
-- fn f(y ()->) nil - func general def (context determined / analyzed mode)
-- fu f(y ()->) nil - pure function (NO s-fx
-- fx f(y ()->) nil - explicitly procedural func, any s-fx
-- fi f(y ()->) nil - member function, instance mutating s-fx only
-- mf f(y ()->) nil - member function, instance mutating s-fx only

def f(y ()->) -> nil
fn g(y ()->) -> nil
g(y ()->) -> nil

--   -- (Seq[Int32]()).flat_map ~>
f () ->
   ([] of Ints).flat-map ~>
      [] of Ints

f(() ->
   ([] of Ints).flat-map(~>
      [] of Ints
   )
)

(f () ->
   (([] of Ints).flat-map ~>
      [] of Ints
   )
)

-- f(() ->
--    ([0 x Ints]).flat-map(~>
--       [0 x Ints]
--    )
-- )

-- (f () ->
--    ((['Ints]).flat-map ~>
--       ['Ints]
--    )
-- )

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

char = %"a"
say "char: {char} ({ typeof(char) })"

straight-str = %s<no {interpolation\t here}\n\tOk!>
say "straight-str: {straight-str} ({ typeof(straight-str) })"

-- *NOTE* consider this, _iff_ standard string is changed to interpolate on {/}
-- tpl-str = %t<requires heavier delimiting %{interpolation here}>
-- say "tpl-str: {tpl-str} ({ typeof(tpl-str) })"

the–str = "kjhgkjh" \
   "dfghdfhgd"

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

\!literal-int=StdInt

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

   end–while -- -while
end–if
-- if (a == 47
--    && a != 48
-- )
--    say "Yeay 47 == 47"

-- zoo( \
--    a, \
--    b, \
--    c I32 \
-- ) ->
--    Str.new(a + b) + c.to–s
-- end

-- def ab=(v)
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
def zoo*(a; b; ...c 'Ints) Str ->  # pure
   if true:
      i = 1

      if (a == 1 &&
         a >
          0 &&
         a <
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
            for val[ix] in {"c", "b", "a"} by 2
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

   end–if


   qwo = "{(a + b)} {c.to–s}"
   (a + b).to–s + " " + c.to–s + " == " + qwo
end

p zoo 1, 2, 47, 42

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

reg–ex = /foo (ya)(.*)/i
m1 = "asdf foo ya fdsa".match reg–ex
m2 = "fda" =~ reg–ex

say "m1 = " + m1.to–s
say "m2 = " + m2.to–s

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -


def qwo(a 'Ints, b ~Ints) ->
end

def qwo2(a ^Ints, b 'Ints) -> end

def qwo3(a 'Ints, b mut Ints) Str -> -- Str

def qwo4(a Ints; b Ints) ->
end

qwo2 1, 2

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

n = 4747 >> 3
n >>= 1
say "n = " + n.to–s + " from " + 4747.to–s
-- say "n = " + $n + " from " + $4747

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

json–hash = {"apa": "Apa", "katt": "Katt", "panter": "Panter"}
say "json–correct–hash: {json–hash}"


tag–hash = {#apa: "Apa", #katt: "Katt", #panter: "Panter"}
say "tag–hash: {tag–hash}"

apa = #apa
katt = "katt"
panter = 947735

-- *TODO* Allow below to act just as a JS-hash?
-- now it acts like arrow hash
js–hash = {apa: "Apa", katt: "Katt", panter: "Panter"}
say "perhaps to be js–hash: {js–hash}"

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
   #tuple: { "47",
      13,
      3.1415
      "yep"
      #Boo
   }
   #bastard: "Bastard"
}
say "tag–hash–2 type is {typeof(tag–hash–2)}"
say "tag–hash–2 value is {tag–hash–2}"

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- type TradeSide < Enum[Int8]
-- enum TradeSide Int8
type TradeSide < enum Int8
   Unknown
   Buy
   Sell

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- crystal style 1 `case ref`
case n
when 1, 2
   say "NOP: is 1|2"
when 2
   say "NOP: is 3"
else
   say "16:  " + n.to–s
end

-- crystal style 1 `case`
case
when n == 1
   say "NOP 1"
when n == 47, n == 593
   say "17"
else
   say "NOP " + n.to–s
end

-- crystal style 1B `case ref`
case n
when 1, 2
   say "NOP: is 1|2"
when 2
   say "NOP: is 3"
else
   say "17.1:  " + n.to–s

-- crystal style 1B `case`
case
when n == 1
   say "NOP 1"
when n == 47, n == 593
   say "17.2"
else
   say "NOP " + n.to–s

-- crystal style 2 `case ref`
case n
   when 1, 2
      say "NOP: is 1|2"
   when 2
      say "NOP: is 3"
   else
      say "17.3: " + n.to–s
end

-- crystal style 2 `case`
case
   when n == 1
      say "NOP 1"
   when n == 47, n == 593
      say "17.4"
   else
      say "NOP " + n.to–s
end

-- onyx style 1 `case ref`
match n
   593
      say "18"
   2 =>
      say "NO is 2"
   *
      say "NO " + n.to–s
end

-- onyx style 1 `case`
cond
   n == 1 =>
      say "NO is 1"
   n == 593 =>
      if false
      else
         say "19"
   * =>
      say "NO " + n.to–s
end–case

-- onyx style 2 `case ref`
branch n
   593
      say "19.1"
   2 =>
      say "NO is 2"
   *
      say "NO " + n.to–s

-- onyx style 2 `case`
case
   n == 1
      say "NO is 1"
   n == 593 =>
      if false
      else
         say "19.2"
   *
      say "NO " + n.to–s

-- onyx style 3 `case ref`
match n
   1 => say "is 1"
   2 => say "is 2"
   * => if false => say "NO" else say "20: " + n.to–s
end–case

-- onyx style 3 `case`
branch
   n == 593   => say "21"
   n == 2     => say "is 2"
   *          => say n.to–s

-- onyx style 4 `case ref`
case n
   1 do say "is 1"
   2 then say "is 2"
   * do if false then say "NO" else say "22: " + n.to–s

-- onyx style 4 `case`
branch
   n == 593   then say "23"
   n == 2     do say "is 2"
   *          then say n.to–s

-- onyx style 5 `case ref`
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

-- onyx style 6 `case ref`
match n
   1: say "is 1"
   2: say "is 2"
   *: if false => say "NO" else say "20: " + n.to–s
end–case

-- onyx style 6 `case`
branch
   n == 593   : say ": 23.3a"
   n == 2     : say "is 2"
   *          : say n.to–s

-- onyx style 6b `case`
cond
   n == 593:   say ": 23.3b"
   n == 2:     say "is 2"
   *:          say n.to–s

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

for v[i] in [#apa, #katt]: say ": {i}: {v}"

if true: say ": true"

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

def foo(a, b, c Str) ->
   (a + b).to–s + c
end

x = foo a, 2, "3"

a = (a Ints, b Ints) -> (a + b).to–s; end
b = (a Str, _ Ints, b 'Bool; c Real) ->
   "{a} {x}" -- t"{a} {x}"

say "23.4 def lambda c"
c = (a ~Ints, b 'Str, c 'Ints) -> a.to–s + b + c.to–s

\!real-literal=Float64
p b.call "23.5a Closured Lambda says", 0, true, 0.42
p b "23.5b Closured Lambda says", 1, true, 0.47

pp typeof(b), b.class

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

type Fn = Proc

-- two funcs with each two params taking lambdas, declared with canonical type
-- syntax and lambda-style type syntax respectively
def booze1(f1 Fn[I32,List<*>,List<List[Ptr<Int32>]>], f2 Fn[Str, Nil, List<Bool>]) ->
def booze2(f1 (List<*>, List<List[Ptr<Int32>]>) -> I32, f2 (Nil, List<Bool>) -> Str) ->

say "List[List<Ptr[Int32]>] => " + List[List<Ptr[Int32]>].to–s

booze2(f1 (I32,auto) -> Nil; f2 (Str) -> Nil) ->

def booze3(f1 (I32, * -> Nil); f2 (Str -> Nil)) ->
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
-- for: while–loops for the 'stepping' case must be generated

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

list = [#abra, #baba, #cadabra]

say "the list ({list.class}): {list}"

list = ["foo", "yaa", "qwö"]

say "the 2nd list ({list.class}): {list}"

-- single line block style #2
y = list.each(|v| p v).map ~> _1 * 2

-- multiline block style #2
y = (list.each |v|
   p v
).map ~>
   _1 * 2

list.each–with–index ~>
   p _1
   break if _2 == 4

(list.map ~> _1 + "X").each–with–index ~>
   p _1
   break if _2 == 4

list.each–with–index |v, i|
   p v
   break if i == 4

(list.map |x| x + "X").each–with–index |x,y|
   p x
   break if y == 4

list.each–with–index ~>
   p _1
   break if _2 == 4

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

for val in list
   say val

list.each |val|
  say("implicit nest {val.to_s}")
end

for val in list =>
   say val

for crux in list do say "do nest" + crux.to_s

for arrowv in list => say "=> nest" + arrowv.to_s
for spccolonv in list : say "\\s: nest" + spccolonv.to_s
for colonv in list: say ": nest" + colonv.to_s

for ,ix in list
   if true begins
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
end–trait

-- *TODO* - should really be able to add data, props, etc. EVERYTHING as in type!
trait AnotherTrait[S1]
   -- *NOTE* should we allow member data in traits too?
   -- another–val = 0  -- "can't use instance variables at the top level"

   val() -> @another–val
   valhalla() -> abstract
   -- valhalla2() -> abstract; say 47 -- should fail - and does
   valhalla3() -> abstract
end

type Qwa < abstract
   mixin TheTrait
end–type

type Bar < Qwa
   Self.my–foo Int64 = 47i64
   Self.some–other–foo 'Ints = 42
   Self.yet–a-foo = 42

   \!literal-int=Int32

   Type.RedFoo = 5
   Type.GreenFoo = 7

   RedBar = 6
   GreenBar = 8

   foo–a Str = ""
   foo–b Ints = 0_i64
   foo–c I64 = 0_i64
   foo-ya I32 = 0

   Self.set–foo(v) ->
      Self.my–foo = v

   Type.get–foo() ->
      @@my–foo

Bar.set-foo 4
say "Bar.get-foo = {Bar.get-foo}"

say "declare a Foo type"

--| The "normal" Foo which is expressed with arrow function syntax
type Foo[S1] < Bar
   mixin AnotherTrait[S1]
   -- < AnotherTrait[S1]

   -- "free" notation at member declaration
   foo–x I64 = 47_i64  \get \set
   foo–y = 48
   foo–z = "bongo"  \get
   foo–u Ints = 47  \ get set
   foo–w = 47       \ set

   -- at-notation at declaration too?
   ifdef x86_64
    bar–x  I64  = 47_i64  # get set
   else
    @bar–x I32  = 47_i32  # get set

   bar–y        = 48
   bar–z        = "bongo"  # get
   @bar–u  Ints = 47  # get set
   @bar–w       = 47  # get

   ifdef x86_64
    init(a S1) ->
       @foo–a = a
   else
    init(b S1) ->
       @foo–a = b
   end

   init() ->

   -- say "Hey in Foo"  -- NOT LEGAL ANYMORE!

   -- *TODO* pragma "blocks"!
   -- \ pure
   --    fn–1aa(x) -> nil \public   -- should this be legal? - looks very confusing!
   --    fn–1ab(x) Nil -> nil  \ pure public   -- should this be legal? - looks very confusing!
   \ pure
   fn–1aa(x) -> nil  -- \public   -- should this be legal? - looks very confusing!
   \pure
   fn–1ab(x) Nil -> nil  \ pure -- public   -- should this be legal? - looks very confusing!

   -- \ private inline
   \ inline
   \ pure
   fn–1ba*(x) ->! nil
   fn–1ca(x) ->!  \pure
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
   -- fn–1h(x) String ->!
   --    say "Hey"
   --    say "you!"
   --    "fdsa"

   -- Should Error _iff_ instantiated, because of mismatching return type
   fn–1i(x) ->!
      say "Yeay"
      return "Foo"

   fn–a(a, b) -> "a: {a}, {b}" # pure

   def fn–b(a S1, b Ints) -> -- fdsa
      "b: {a}, {b}"

   -- # private
   --    fn–c(a, b S1) S1 -> # redef inline
   --       "c: {a}, {b}"

   --    end–def

   --    -- fn–c(a, b I32) redef private ->
   --    fn–c(a, b Ints) -> # redef
   --       "c: {a}, {b}"

   -- # private
   fn–c*(a, b S1) S1 -> # redef inline
      "c: {a}, {b}"

   end–def

   --# protected
   -- fn–c(a, b I32) redef protected ->
   fn–c**(a, b Ints) -> # redef
      "c: {a}, {b}"

   fn–d1(a, b) ->
      @foo–a = a
      @foo–b = b
      fn–e
   end

   fn–d2(a S1, b Ints) ->
      @foo–a = a
      @foo–b = b
      fn–e

   -- fn–d3(a S1, b <IntT>) ->
   --    @foo–a = a
   --    c IntT
   --    c = b
   --    @foo–b = c
   --    fn–e

   fn–e() -> fa = @foo–a ; "e: {fa}, {@foo_b}"

   # flatten
   call() -> fn–e

   [](i) -> @foo–b + i

end–type

-- *TODO* type level 'pure'/'mepure' spec - should be possible to "make" the
-- type that (all monkey patches obey it), and also a LEXICAL variant which
-- rules only in the specific lexical declaration context (for adding a bunch of
-- pure funcs to Program for instance

--| A Foo type in style 2 (non-arrow function defs)
--| <S1> is primary variable type
type FooStyle2<S1> < Bar
   mixin AnotherTrait<S1>

   -- "free" notation at member declaration
   @foo–x I64 = 47_i64  # get set
   @foo–y = 48
   @foo–z = "bongo"  # get
   @foo–u Ints = 47  | get set
   @foo–w = 47       |set

   -- at-notation at declaration too?
   ifdef x86_64
      @bar–x I64 = 47_i64  | get set
   else
      @bar–x I32 = 47_i32  |get |set

   @bar–y = 48
   @bar–z = "bongo"  |get
   @bar–u Ints = 47  | get set
   getter @bar–w = 47

   --| Initialize with primary variable type
   ifdef x86_64
      -- fn init(a S1)
      fn init(a S1) ->
         @foo–a = a
   else
      -- fn init(b S1)
      fn init(b S1) ->
         @foo–a = b
   end

   -- fn init()
   fn init() ->

   -- say "Hey in Foo"  -- NOT LEGAL ANYMORE!


   -- |pure
   --    fn fn–1aa(x) ->  |public;  nil   -- should this be legal? - looks very confusing!
   --    fn fn–1ab(x) Nil -> |public;  nil   -- should this be legal? - looks very confusing!

   -- |private |inline:
   --    fn fn–1ba(x)! -> nil
   --    fn fn–1ca(x)! ->
   --    fn fn–1da(x) -> nil | pure
   --    fn fn–1ea(x)! -> nil | pure

   --| Do some 1aa action!
   |pure
   fn fn–1aa(x) ->  |pure;  nil   -- should this be legal? - looks very confusing!
   fn fn–1ab(x) Nil -> | pure;  nil   -- should this be legal? - looks very confusing!

   -- |private |inline
   |inline |pure
   fn fn–1ba*(x) ->! nil
   fn fn–1ca(x) ->!
   fn fn–1da(x) -> nil | pure
   fn fn–1ea(x) ->! nil | pure

   -- fn fn–1fa(x)!

   -- fn fn–1ga(x)!
   --    ifdef x86_64
   --       say "Hey"
   --    else
   --       say "you!"
   -- ;

   fn fn–1fa(x) ->!

   fn fn–1ga(x) ->!
      ifdef x86_64
         say "Hey"
      else
         say "you!"
   ;

   -- This should fail on parse because of ret-type + nil-ret flag
   -- fn–1h(x) String ->!
   --    say "Hey"
   --    say "you!"
   --    "fdsa"

   -- Should Error _iff_ instantiated, because of mismatching return type
   -- fn fn–1i(x)!
   fn fn–1i(x) ->!
      say "Yeay"
      return "Foo"

   fn fn–a(a, b) -> "a: {a}, {b}"

   -- fn fn–b(a S1, b Ints) -- fdsa
   fn fn–b(a S1, b Ints) -> -- fdsa
      "b: {a}, {b}"

   -- | private
   --    fn fn–c(a, b S1) S1 | redef inline
   --       "c: {a}, {b}"
   --    end–fn

   --    -- fn–c(a, b I32) redef private ->
   --    fn fn–c(a, b Ints) |redef
   --       "c: {a}, {b}"

   -- | private
   fn fn–c*(a, b S1) S1 -> | redef inline
      "c: {a}, {b}"
   end–fn

   -- fn–c(a, b I32) redef private ->
   fn fn–c**(a, b Ints) -> |redef
      "c: {a}, {b}"

   -- fn fn–d1(a, b)
   fn fn–d1(a, b) ->
      @foo–a = a
      @foo–b = b
      fn–e
   end

   -- fn fn–d2(a S1, b Ints)
   fn fn–d2(a S1, b Ints) ->
      @foo–a = a
      @foo–b = b
      fn–e

   -- fn–d3(a S1, b <IntT>) ->
   --    @foo–a = a
   --    c IntT
   --    c = b
   --    @foo–b = c
   --    fn–e

   fn fn–e() -> fa = @foo–a ; "e: {fa}, {@foo_b}"

   |flatten
   fn call() -> fn–e

   fn [](i) -> @foo–b + i

end–type

-- *TODO* Anonymous types!
-- anon-typed = new Bar
--    mixin AnotherTrait<I64>

--    fn-x(x) -> "I am Anon"


say "create a Foo instance"
foo = Foo[Str]()

pp foo.foo-x
pp foo.foo-w = 46
-- pp foo.foo-y -- should fail
-- pp foo.foo-w -- should fail

say "done"
say foo.fn–a "24 blargh", 47
say foo.fn–b "25 blargh", 47
-- say foo.fn–c "26 blargh", 47   -- should fail: private
say foo.fn–d1 "27 blargh", 47
foo.fn–d2 "28 blargh", 47
say foo.fn–e

boo = Foo[Str]()
boo = Foo[Str].new
boo = Foo[Str].new()

boo = Foo<Str>()
boo = Foo<Str>.new
boo = Foo<Str>.new()

bar = Foo<Str>("No Blargh")
bar = Foo("No Blargh")
bar = Foo "No Blargh"
bar = Foo[Str] "No Blargh"
bar = Foo.new "No Blargh"
bar = Foo[Str].new "29 Blargh"

say "done"
say bar.fn–e
say "functor call"
say bar()
bar.fn–d2 "30 blargh", 47

say "varying word-delimiters"
say bar.fn–e
say bar.fn-e
say bar.fn_e
say bar.fnE

say "shit-sandwich"
shit-sandwich =  bar.fnE
shitSandwich = "arghh"
say shitSandwich

say bar.call()
say bar()

-- foo.valhalla  -- should fail - abstract
-- say bar.fn-1i(1)  -- should make fn-1i fail because it has mismatching return type

say typeof(foo)
say foo.class

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
-- just to show how c-lib interfacing works.

|link("gmp")

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

      -- Just testing ifdef in all contexts
      ifdef x86_64
         _mp_d     Ptr[ULong]
      else
         _mp_d     Ptr<ULong>
      end
   end

   alias MpzP = Ptr[Mpz]

   fun init = __gmpz_init(x MpzP)
   fun init_set_si = __gmpz_init_set_si(rop Ptr<Mpz>, op Long)
   fun init_set_str = __gmpz_init_set_str(rop MpzP, str Ptr[UInt8], base Int)

   fun get_si = __gmpz_get_si(op MpzP) Long
   fun get_str = __gmpz_get_str(str Ptr[UInt8], base Int, op MpzP) Ptr[UInt8]

   fun add = __gmpz_add(rop MpzP, op1 MpzP, op2 MpzP)
   fun set-memory-functions = __gmp_set_memory_functions(malloc (SizeT) -> Ptr[Void], realloc (Ptr[Void], SizeT, SizeT) -> Ptr[Void], free (Ptr[Void], SizeT) -> Void )

end

MyLibGmp.set-memory-functions(
   (size) ->
      GC.malloc(size)
   , (ptr, old_size, new_size) -> GC.realloc(ptr, new_size); end,
   ((ptr, size) -> GC.free(ptr) )
)

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
   if a.is-a? Str
      MyLibGmp.init-set-str pointerof(bigv1), a, 10
   else
      MyLibGmp.init-set-si pointerof(bigv1), a
   end

   if b.of? Str
      MyLibGmp.init-set-str out bigv2, b, 10
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

-- Onyx cleaner hierarchical access syntax handles all Crystal constructables

-- # Should work:
pp CrystalModule
pp CrystalModule.ROOT_CONST
pp CrystalModule.CrystalClass
pp CrystalModule.CrystalClass.CLASS_ROOT_CONST
pp CrystalModule.self_def
pp CrystalModule.CrystalClass.class_func

-- # Should not work
-- pp CrystalModule.MODULE_CONST
-- pp CrystalModule.CrystalClass.CLASS_CONST
-- pp CrystalModule.root_def
-- pp CrystalModule::CrystalClass.memb_func

-- # Should work if `extend self`:
pp CrystalModule2
pp CrystalModule2.ROOT_CONST
pp CrystalModule2.CrystalClass
pp CrystalModule2.CrystalClass.CLASS_ROOT_CONST
pp CrystalModule2.self_def
pp CrystalModule2.CrystalClass.class_func
pp CrystalModule2.root_def

-- # Should not work despite `extend self`:
-- pp CrystalModule.MODULE_CONST
-- pp CrystalModule.CrystalClass.CLASS_CONST
-- pp CrystalModule::CrystalClass.memb_func

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
-- This module begins here and continues to EOF
module AllTheRest begins

type RestFoo < value
   rest-foo() ->
      true


xx = 47
yy = 47.47


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
say "{ "foo".magenta }, { "bar".grey }, { "qwo".white }"
say "{ "foo".magenta2 }, { "bar".grey2 }, { "qwo".white }"
say "All DOWN ".red
say "         AND OUT".red2
