
require "./my-gmp-lib"

_debug_start_ = true

\!Int=I64
\!Real=Float32

\!int-literal=I64
\!real-literal=Float32


-- *TODO* *TEMP*
alias Itr = StdInt
alias Real = Float64

module Djur
   module Boo begins

   APA = 47

   type Apa
      \!Int=I64

      @@foo = 2
      Type.bar = 2

      @foo     Itr
      bar      Itr
      @foo’    Itr   = 47
      bar’           = 47
      @foo’’   Itr
      bar’’    Itr

      foo3 'Itr
      bar3 ^Itr
      qwo3 ~Itr

      -- xfoo! Itr = 47  -- should fail, and does
      -- xbar? Itr = 42  -- should fail, and does

      Type.my-def() -> say "Hit the spot! {{ Type.foo’ }}, {{ @@bar }}"
      inst-def() -> say "Hit the spot! {{ @foo’ }}, {{ @bar }}"
   end

   enum Legs
      NONE
      TWO
      FOUR
      SIX
      EIGHT

      Type.is-six?(v) ->
         v == SIX
   end
end

-- module Djur
--    module Boo
--       APA = 42
--    end
-- end

-- t = Time.Span(0)
-- t = Time.Span 0

type Blk
   init(&block) ->  -- (T) -> U - does not work for block...
      yield 1
      yield 2
end

blk = Blk(|x|
   say "in blk init block: {{x}}"
   nil
)

blk2 = Blk |x|
   say "in blk init block: {{x}}"
   nil

say "1"

Djur::Boo::Apa.my-def
say "Djur::Boo::Legs::TWO = {{Djur::Boo::Legs::TWO}}"

-- say Djur.Boo.Apa.foo’ -- *NOTE* perhaps a better error message: "No method with the name `{{name}}` found, only a private variable. Make a getter and/or setter method to access it from the outside world"
Djur.Boo.Apa.my-def
say "Djur.Boo.Legs.TWO = {{Djur.Boo.Legs.TWO}}"
say "Djur.Boo.Legs.is-six?(EIGHT) = {{Djur.Boo.Legs.is-six?(Djur.Boo.Legs.EIGHT)}}"

-- override '<<' operator on String to act as str combine (like '+' but auto-coercing)
type String: <<(s) -> "{{self}}{{s}}"

say "fdaf" + "fdsf" << "aaasd" << 47.13


fun-with-various-local-vars() ->!
   -- declare assign with type inference
   zar1 = 1

   -- *TODO* after all basic control structs are implemented
   -- zar2 ^Itr
   -- zar2 ~Itr
   -- zar2 'Itr = 1
   -- zar0 ~Itr
   -- zar3 '= 1
   -- zar4 '*= 1
   -- zar5 'auto = 1

--    begin
--       a = 1 / 0

--    rescue e
--       say "Rescued divizon by zero: {{e}}"

-- ensure
--    say "/fun-with-various-local-vars"

-- say "call fun-with-various-local-vars"
-- fun-with-various-local-vars


\!Int=I64

foo-named(awol, foo = 47, bar = "fds") ->!
   say "{{awol}}, {{foo}}, {{bar}}"

foo-named 1, "blarg", "qwö qwö"
foo-named 2, 42, #bar = "yo"
foo-named 3, #foo = 11, #bar = "yo"

list = List[Str]()
list << "foo"
list << "yaa"

-- x = list.map
-- x = list.map()
-- y = list.map 1
-- z = list.map apa
-- u = list.map(apa)
v = list.map(|x, y| x + "1")
w = list.map |x, y| "{{x}} 47"
i = list.map |x, y| => "{{x}} 13"
j = list.map ~> "{{_1}} 13"

puts "{{v}}, {{w}}"


list = [47, 13, 42, 11]
x = list.each(|v| p v).map(~> _1 * 2)
y = ((list.each(|v| p v)).map(~> _1 * 2))
z = list.each(|v| p v).map ~> _1 * 2
u = list.each(|v| p v).map ~> _1 * 2

def say(s) -> puts s

say "Let's ROCK"

\!Int=I32

DEBUG–SEPARATOR = 47

-- Change array literal notation for typed arr (thus empty arr)!?
-- a = [32, 47 : Int32]
-- a = [:Int32]
-- a = [] Int32

def f(y ()->) -> nil

--   -- (Seq[Int32]()).flat_map ~>
f () ->
   ([] of Itr).flat-map ~>
      [] of Itr

f(() ->
   ([] of Itr).flat-map(~>
      [] of Itr
   )
)

(f () ->
   (([] of Itr).flat-map ~>
      [] of Itr
   )
)



\!Int=StdInt

-- first comment
a = 47  --another comment
char = c"a"
say "char: {{char}} ({{ typeof(char) }})"

--| (NO LONGER) weirdly placed comment


-- foo(a, b, c I32) ->
--    Str(a + b) + c.to–s

the–str = "kjhgkjh" \
   "dfghdfhgd"

-- how about (though that's the range–exclusive operator):
-- the–str = "kjhgkjh" ...
--    "dfghdfhgd"

if (a == 47 &&
   a != 48
)
   say "1"

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
      if false : else do say "5.2b "; say "5.3b"; if true => say "5.4b"
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

[ab, ac] = [3, 2]
[aa, ab, ac, ad] = [1, ac, ab, 4]
say "should be 3: " + ac.to–s

DEBUG–SEPARATOR

-- -#pure -#private
\private
def zoo(a, b, ...c 'Itr) Str ->  \pure
   if true:
      i = 1

      if (a == 1 &&
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
               p "{{val}}, {{ix}}"

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


   qwo = "{{(a + b)}} {{c.to–s}}"
   (a + b).to–s + " " + c.to–s + " == " + qwo
end

p zoo 1, 2, 47, 42

reg–ex = /foo (ya)(.*)/i
m1 = "asdf foo ya fdsa".match reg–ex
m2 = "fda" =~ reg–ex

say "m1 = " + m1.to–s
say "m2 = " + m2.to–s

def foo(a, b, c Str) ->
   (a + b).to–s + c

end


def qwo(a 'Itr, b ~Itr) ->
end

def qwo2(a ^Itr, b 'Itr) -> end

def qwo3(a 'Itr, b mut Itr) Str -> -- Str

def qwo4(a Itr; b Itr) ->
end

qwo2 1, 2

n = 4747 >> 3
n >>= 1
say "n = " + n.to–s + " from " + 4747.to–s
-- say "n = " + $n + " from " + $4747


json–hash = {"apa": "Apa", "katt": "Katt", "panter": "Panter"}
say "json–correct–hash: {{json–hash}}"


tag–hash = {#apa: "Apa", #katt: "Katt", #panter: "Panter"}
say "tag–hash: {{tag–hash}}"

apa = #apa
katt = "katt"
panter = 947735

-- *TODO* Allow below to act just as a JS-hash?
-- now it acts like arrow hash
js–hash = {apa: "Apa", katt: "Katt", panter: "Panter"}
say "perhaps to be js–hash: {{js–hash}}"

arrow–hash = {apa => "Apa", katt => "Katt", panter => "Panter"}
say "arrow–hash: {{arrow–hash}}"

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
say "tag–hash–2 type is {{typeof(tag–hash–2)}}"
say "tag–hash–2 value is {{tag–hash–2}}"


-- type TradeSide << Enum[Int8]
enum TradeSide Int8
   Unknown
   Buy
   Sell


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

for v[i] in [#apa, #katt]: say ": {{i}}: {{v}}"

if true: say ": true"

x = foo a, 2, "3"

a = (a Itr, b Itr) -> (a + b).to–s; end
b = (a Str, _ Itr, b 'Bool; c Real) ->
   "{{a}} {{x}}" -- t"{a} {x}"

say "23.4 def lambda c"
c = (a ~Itr, b 'Str, c 'Itr) -> a.to–s + b + c.to–s

-- *TODO* fix so that lambdas can be called with call syntax! And all instances
-- with a call method! (including Functor trait well formed)
p b.call "23.5 Closured Lambda says", 1, true, 0.47
-- p b("2 Closured Lambda says", 1, true, 0.47)
-- p b "2 Closured Lambda says", 1, true, 0.47
-- Str "47"
-- str "47"

p typeof(b)


class Fn[T1, T2, T3]

def booze1(f1 Fn[I32,Array<*>,Array<Array[Ptr<Int32>]>], f2 Fn[Str, Nil, Array<Bool>]) ->

say "Array[Array<Ptr[Int32]>] => " + Array[Array<Ptr[Int32]>].to–s

booze2(f1 (I32,auto) -> Nil; f2 (Str) -> Nil) ->

def booze3(f1 (I32, * -> Nil); f2 (Str -> Nil)) ->
end


-- -- a–closure–lambda1 = [&i,=v](a, b) -> do–shit(a, b, @i, @v)

-- -- a–closure–lambda2 = ([&i,=v]; a, b) -> do–shit(a, b, @i, @v)

-- -- a–closure–lambda3 = {&i,=v}(a, b) -> do–shit(a, b, @i, @v)


-- Self == "this type"
-- this == "this instance"  -- or:
-- me == "this instance" ?  -- or:
-- my == -""-

-- 3. THE REST HERE
-- - t"str {smoother} interpolation {style}"
-- - r"reg–exp syntax instead of /fd/"
-- - raw"for raw strings"
-- - c"X"  (but this probably already works!)

-- - bar x, y -- semantic lookup of instances of types having .call method

-- for: to_s for onyx and crystal must spit out the for–loop
-- for: while–loops for the 'stepping' case must be generated




list = [#abra, #baba, #cadabra]

say "the list: {{list}}"


-- soft lambdas
-- list.each (v) ->) p v
-- list.each (v) ->} p v
-- list.each (v Tag) ->) p v
-- list.each (v Tag) ->} p v
-- list.each (v) -) p v
-- list.each (v) -} p v

for v in list => p v



list = ["foo", "yaa"]

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
--    say "from til loop {{i}}"


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
-- -- say "Mapped list: {{mapped–list}}"


for val in list
   say val

list.each |val|
  say("do nest" + val.to_s)
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
   say "  {{ix}}"

for val, ix in list
   say "{{val}}, {{ix}}"

for ix: val in list
   say "{{val}}, {{ix}}"

for ix:val in list
   p "{{val}}, {{ix}}"

for ix: in list
   say ix

for val[ix] in list
   say "{{val}}, {{ix}}"

for [ix] in list
   say ix

for val[ix] in ["c", "b", "a"]
   say "{{val}}, {{ix}}"

for val[ix] in {"c", "b", "a"}
   say "{{val}}, {{ix}}"

for val[ix] in {"c", "b", "a"} -- by -1
   say "{{val}}, {{ix}}"

for val[ix] in ["c", "b", "a"] -- by 2
   say "{{val}}, {{ix}}"


trait TheTrait
   is–cool–traited?() -> true
end–trait

trait AnotherTrait[S1]
   -- *NOTE* should we allow member data in traits too?
   -- another–val = 0  -- "can't use instance variables at the top level"

   val() -> @another–val
   valhalla() -> abstract
   -- valhalla2() -> abstract; say 47 -- should fail - and does
   valhalla3() -> abstract
end

type Qwa
   mixin TheTrait
end–type

type Bar << Qwa
   Self.my–foo Int64 = 47i64
   Self.some–other–foo 'Itr = 42
   Self.yet–a-foo = 42

   Type.RedFoo = 5
   Type.GreenFoo = 7

   RedBar = 6
   GreenBar = 8

   foo–a Str = ""
   foo–b Itr = 0
   @foo–c I64 = 0
   foo-ya I32 = 0_i32

   Class.set–foo(v) ->
      Self.my–foo = v

   Type.get–foo() ->
      @@my–foo

Bar.set-foo 4_i64
say "Bar.get-foo = {{Bar.get-foo}}"

say "declare a Foo type"



type Foo[S1] << Bar
   mixin AnotherTrait[S1]

   foo–x I64 = 47_i64  \get \set
   foo–y = 48  \prop         -- better to use `\get \set` then `\prop`
   foo–z = "bongo"  \get

   init(a S1) ->@
      @foo–a = a

   init() ->@

   -- say "Hey in Foo"  -- NOT LEGAL ANYMORE!

   fn–1aa(x) ->>  \pub  nil   -- should this be legal? - looks very confusing!

   fn–1ab(x) Nil -> \pure \pub  nil   -- should this be legal? - looks very confusing!

   \priv \inline
   \pure
   fn–1ba(x) ->>! nil

   fn–1ca(x) ->>!  \pure

   -- will cause conflicts with generic blockstarts:
   -- fn–1ab(x) => nil
   -- fn–1bb(x) =>! nil
   -- fn–1cb(x) =>!

   fn–1da(x) -> nil

   fn–1ea(x) ->! nil

   fn–1fa(x) ->!

   fn–1ga(x) ->!
      say "Hey"
      say "you!"

   -- This should fail on parse because of ret-type + nil-ret flag
   -- fn–1h(x) String ->!
   --    say "Hey"
   --    say "you!"
   --    "fdsa"

   -- Should Error on instantiation, because of mismatching return type
   fn–1i(x) ->!
      say "Yeay"
      return "Foo"

   fn–a(a, b) ->> "a: {{a}}, {{b}}"

   def fn–b(a S1, b Itr) -> -- fdsa
      "b: {{a}}, {{b}}"

   \private
   fn–c(a, b S1) S1 ->>  \redef \inline
      "c: {{a}}, {{b}}"

   end–def

   \private
   -- fn–c(a, b I32) redef private ->
   fn–c(a, b Itr) -> \redef
      "c: {{a}}, {{b}}"
      -- t"c: {a}, {b}"

   fn–d1(a, b) ->
      @foo–a = a
      @foo–b = b
      fn–e
   end

   fn–d2(a S1, b Itr) ->
      @foo–a = a
      @foo–b = b
      fn–e

   -- fn–d3(a S1, b <IntT>) ->
   --    @foo–a = a
   --    c IntT
   --    c = b
   --    @foo–b = c
   --    fn–e

   fn–e() -> fa = @foo–a ; "e: {{fa}}, {{@foo_b}}"

   call() -> fn–e

   [](i) -> @foo–b + i

end–type


say "create a Foo instance"
foo = Foo[Str]()

-- foo.valhalla  -- should fail - abstract

say "done"
say foo.fn–a "24 blargh", 47
say foo.fn–b "25 blargh", 47
say foo.fn–c "26 blargh", 47
say foo.fn–d1 "27 blargh", 47
foo.fn–d2 "28 blargh", 47
say foo.fn–e

bar = Foo<Str>("No Blargh")
bar = Foo("No Blargh")
bar = Foo "No Blargh"
bar = Foo[Str] "No Blargh"
bar = Foo.new "No Blargh"
bar = Foo[Str].new "29 Blargh"
say "done"
say bar.fn–e
bar.fn–d2 "30 blargh", 47
say bar.fn–e
say bar.fn-e
say bar.fn_e
shit-sandwich =  bar.fnE
say shitSandwich

-- say bar.fn-1i(1)  -- should make fn-1i fail because it has mismatching return type

-- say bar()   -- needs to be done in semantics - need to see if bar has 'call' method!
            -- if so - rewrite to `bar.call()`
say typeof(foo)
say foo.class

say "7 .&. 12 == {{ 7 .&. 12 }}"
say "12 .|. 1 == {{ 12 .|. 1 }}"
say "12 .^. 2 == {{ 12 .^. 2 }}"
say ".~. 12 == {{ .~. 12 }}"

say "All DOWN AND OUT"


-- *NOTE* - perhaps it should be supported to set var in cond and it's avail in prefix then-branch
-- say "Yes indeed we got {{if-var}}" if if-var = 47
-- tmp(x) ->
--    return a if (a = x)
--    say "Got a {{a}}"
-- tmp 4747

-- macro ptr(o)
--    pointerof({=o=})
-- end

module AllTheRest begins

type Foo
   foo() ->
      true

xx = 47
yy = 47.47


MyLibGmp.init-set-si out mpz, 47
say "bigint -> i64: {{ MyLibGmp.get-si(pointerof(mpz)) }}"

pp MyLibGmp.FOO_CONST

