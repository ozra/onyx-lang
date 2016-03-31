say "\n\nBefore requires!\n\n"
require "./crystal-scopes"
require "wild_colors"
'int_literal(I64)

_debug-compiler-start-_ = true
say "\nLet's ROCK\n".red
indent-call(x, y, ...z) ->
   "{x}, {y}, {z}"

say indent-call("a", "b", 47_i64, 23_i64, 11_i64, 12_i64, indent-call "masta", indent-call("blasta", "blaaasta"))
vx = 2_i64
vy = 3_i64
a = 1_i64
b = 3_i64
c = 2_i64
that = "That"
good-ole-set = $.Set {47_i64, "Hey", 3_i64}
say typeof(good-ole-set)
say good-ole-set.class
pp 1_i64 < 2_i64 < 4_i64
do-tup(x Tup) ->
   x

tup1 = (47_i64, 13_i64, "yo")
tup2 = (#exacto, that)
tup3 = (that,)
tup4 = (,)
tup5 = ("ml", "tup", "are", "also", "ok", 5_i64, that, "as", 7_i64, "sual")
tup6 = do-tup ("ml", "tup", "are", "also", "ok", 5_i64, that, "as", 7_i64, "sual")
tup7 = (a < b, b > c)
tup8 = (true, a < b > c, false)
do-tup (1_i64, 2_i64)
do-tup((1_i64, 2_i64))
if do-tup (1_i64,)
   say "tup tup yeay"
end
if true
   bzz = do-tup (that,)
end
fdf = 5_i64 < 7_i64 < 23_i64 && vx > +vy
x = a < b > c
say tup1, tup2, tup3, tup4, tup5, tup6, tup7, tup8
tup1 = (47_i64, 13_i64, "yo")
tup2 = (#exacto, that)
tup3 = (that,)
tup4 = (,)
tup5 = ("ml", "tup", "are", "also", "ok", 5_i64, that, "as", 7_i64, "sual")
tup6 = do-tup ("ml", "tup", "are", "also", "ok", 5_i64, that, "as", 7_i64, "sual")
tup7 = (a < b, b > c)
tup8 = (true, a < b > c, false)
do-tup (1_i64, 2_i64)
do-tup((1_i64, 2_i64))
if do-tup (1_i64,)
   say "tup tup yeay"
end
if true
   bzz = do-tup (that,)
end
fdf = 5_i64 < 7_i64 < 23_i64 && vx > +vy
x = a < b > c
say tup1, tup2, tup3, tup4, tup5, tup6, tup7, tup8
a1 = String
b1 = "fdsaf"
say "a ~~ b == {a1 === b1}"
say "Int !~~ b == {Int !~~ b1}"
say "a !~~ b == {a1 !~~ b1}"
x = /x/
say "x ~~ \\"zxy\\" == {x === "zxy"}"
say "\\"zxy\\" ~~ x == {"zxy" === x}"
say "x !~~ \\"zxy\\" == {x !~~ "zxy"}"
say "\\"zxy\\" !~~ x == {"zxy" !~~ x}"
say "x =~ \\"zxy\\" == {x =~ "zxy"}"
say "\\"zxy\\" =~ x == {"zxy" =~ x}"
match x
when "nilx"
   say "~~ was rex"
when 0.0
   say "~~ was 0.0"
else
   say "was not eq"
end
say "\nfunction(foo) \{ SomeJsCode(foo(\"bar}\")); }\n"
foos = "1. lots asf self_def fds
 f  fsd fsdf asdf
  fasef _debug_compiler_start_ = {_debug-compiler-start-_} here
fasd".upcase.reverse
say foos
foos = "2. lots asf self_def fds\n f  fsd fsdf asdf\n  fasef _debug_compiler_start_ == \{_debug_compiler_start_} here\nfasd"
say foos
foos = "3. lots asf self_def fds
 f  fsd fsdf asdf
  fasef _debug_compiler_start_ = {_debug-compiler-start-_} here
fasd"
say foos
foos = "4. lots asf self_def fds\n f  fsd fsdf asdf\n  fasef _debug_compiler_start_ == \{_debug_compiler_start_} here\nfasd"
say foos
pp 1_i64..2_i64
pp 1_i64..2_i64
fun-a(x) ->
   say "fun-a says: '{x}' and '{x[String]}'"

fun-a {String => String}
say ({String => String}).class
say typeof({String => String})
fun-b(x) ->
   say "fun-b says: '{x}' and '{x.first}'"

fun-b [String]
say "\n    ...\n    asdfaASDF FDSAsd\nFDF\n".downcase
say "\n   ...\n   fasfd FDSAF\nFDSA\n".downcase
the-function(a = nil Int64 | $.Nil, b = nil Int64 | $.Nil) ->
   true

the-function
the-function 1_i64
the-functionb: 2_i64
the-function 1_i64, 2_i64
if the-functiona: 1_i64, b: 2_i64
   say "the-function says yes!"
end
if !the-functiona: 1_i64, b: 2_i64
   say "-"
else
   "the-function says no!"
end
my-foo(x, y, opts Hash<Str, Str | I64 | Nil>) ->
   say "csx {opts["magic_port"]?.class}"
   say "csx {opts["x"]?.class}"
   say "csx {typeof(opts["x"]?)}"

my-foo 1_i64, 2_i64, Map<Str, Str | I64 | Nil> {"my_name_is" => "Totally irrelevant", "host_name" => "da_host.yo"}
type Xoo
   @@my-instance-count = 0_i64
   Type.get-count() ->
      @@my-instance-count
   
   Type.my-new() ->
      say "My own new function"
      @@my-instance-count = @@my-instance-count + 1_i64
      return new()
   
end

say Xoo.get-count
foox = Xoo.my-new
barx = Xoo.my-new
say foox.class
say Xoo.get-count
'int_literal(I64)
'real_literal(Float32)

alias Ints = StdInt
alias MoreInts = Int32 | Int64 | I8
say MoreInts
type SomeFacts < enum U8
   AppleLover
   PearLover
   CoolDude
end
facts = SomeFacts.flags AppleLover, CoolDude
say "facts: {facts}"
say typedecl(facts)
say typedecl facts
say typeof(facts, "blargh", 1_i64)
say (typedecl facts, "blargh", 1_i64)
say typedecl(facts, "blargh", 1_i64)
facts = facts | SomeFacts.PearLover
say "facts: {facts}"
MY_CONST = do
   x = 0_i64
   2_i64.upto(4_i64).each (a)~>
      x = x + a
      say "calculating MY_CONST, {a}"
   
   x
end
pp MY_CONST
pp $.say "blargh"
pp $.MY_CONST
$my-global = 47_i64
$my-typed-global I32
'int_literal(Int32)

$my-typed-and-assigned-global I32
$my-typed-and-assigned-global = 47

$my-global = $my-typed-and-assigned-global
module Djur
   module Boo
      APA = 47
      type Apa < Reference
         @@foo = 1_i64
         @@bar = 2_i64
         @foo Ints
         @bar Ints
         @foo’ Ints
         @foo’ = 47_i64
         @bar’ = 47_i64
         @foo’’ Ints
         @bar’’ Ints
         @foo3 Ints
         @bar3 ^Ints
         @qwo3 ~Ints
         Type.my-def() ->
            say "Hit the spot! {@@foo’}, {@@bar}"
         
         inst-def() ->
            say "Hit the spot! {@foo’}, {@bar}"
         
      end

      type Legs < enum
         NONE
         TWO
         FOUR
         SIX
         EIGHT
         Type.is-six?(v) ->
            v == SIX
         
      end
   end
end
say "1"
Djur.Boo.Apa.my-def
say "Djur.Boo.Legs.TWO = {Djur.Boo.Legs.TWO}"
say "Djur.Boo.Legs.is-six?(EIGHT) = {Djur.Boo.Legs.is-six?(Djur.Boo.Legs.EIGHT)}"
type Blk
   init(x, &block () ->) ->
      yield x + 1
      yield x - 2
   
end

blk = Blk(4, (x)~>
   say "in blk init block: {x}"
)
blk2 = Blk 7, (x)~>
   say "in blk2 init block: {x}"

module Functor
end
type MyFunctor
   include Functor
   @foo = 47
   call() ->
      "call()"
   
   call(a, b) ->
      "call {a}, {b}, {@foo}"
   
   bar() ->
      true
   
end

myfu = MyFunctor()
pp myfu.bar
pp myfu.call "ctest", "cfooo"
say myfu.call "test", "fooo"
say myfu
say myfu.call()
my-fun-fun(f) ->
   f.call "testing", "it"

pp my-fun-fun myfu
my-lambda = (x Str) -> 
   say "x: {x}"

my-lambda.call "47"
my-lambda.call("47")
my-lambda.call "47"
my-lambda.call("47")
type String
   <<(obj) ->
      "{self}{obj}"
   
end

say("fdaf" + "fdsf" << "aaasd" << 47.13_f32 << " - yippie!")
fun-with-various-local-vars(a = 0 I32 | I64 | Real) $.Nil ->
   say "a type = {typeof(a)}"
   zar1 = 1
   say "fun-with-various-local-vars {zar1}"
   nil

fun-with-various-local-vars 47
fun-with-exception-action(x) $.Nil ->
   try
      try
         a = 1 / 0
      rescue e : IndexError | ArgumentError
         say "In fun: Rescued {e}"
      rescue DivisionByZero
         say "In fun: Rescued divizon by zero"
      rescue e
         say "Rescued some kind of shit"
      fulfil
         say "In fun: Nothing to rescue - yippie!"
      ensure
         say "In fun: Oblivious to what happened!"
      end
      a = 1 / x
      nil
   fulfil
      say "eof fun-with-exception-action - ONLY on SUCCESS!"
   ensure
      say "eof fun-with-exception-action - EVEN on RAISE!"
   end
   nil

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
'int_literal(I64)

foo-named(awol, foo = 47_i64, bar = "fds") $.Nil ->
   say "foo-named: (awol): {awol}, foo: {foo}, bar: {bar}"
   nil

foo-named 1_i64, "blarg", "qwö qwö"
foo-named 2_i64, 42_i64, bar: "yo"
foo-named 3_i64, foo: 11_i64, bar: "yo"
list = List<Str>()
list << "foo"
list << "yaa"
v = list.map((x, y)~>
   x + "1"
)
w = list.map (x, y)~>
   "{x} 47"

i = list.map (x, y)~>
   "{x} 13"

j = list.map (1)~>
   "{1} 13"

puts "{v}, {w}"
list = [47_i64, 13_i64, 42_i64, 11_i64]
say " x:"
x = list.each((v)~>
   p v
).map(~.* 2_i64)
say " y:"
y = ((list.each((v)~>
   p v
)).map(~.* 2_i64))
say " z:"
z = list.each((v)~>
   p v
).map ~.* 2_i64
say " u:"
u = list.each((v)~>
   p v
).map ~.* 2_i64
say " v:"
v = ((list.each((v)~>
   p v
)).map ~.* 2_i64)
say " w:"
w = ((list.each((v)~>
   p v
)).map(~.* 2_i64))
say " pw:"
pw = (list.each (1)~>
   p 1
).map ~.* 2_i64
say "All lists should equal [94, 26, 84, 22]"
say x
say y
say z
say u
say v
say w
say pw
'int_literal(I32)

DEBUG–SEPARATOR = 47
f(y () ->) ->
   nil

g(y () ->) ->
   nil

g(y () ->) ->
   nil

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
   ))
n = 3
do-something(x) ->
   say "do-something {x}"

match n
when 1
   do-something 1
when  == 5
   do-something 2
when  < 10
   do-something 3
else
   do-something 4
end
char = %"a"
say "char: {char} ({typeof(char)})"
straight-str = "no \{interpolation\t here}\n\tOk!"
say "straight-str: {straight-str} ({typeof(straight-str)})"
say "char: \\"{char}\\" ({typeof(char)})"
the-str = "111kjhgkjh222dfghdfhgd"
yet-a-str = "111kjhgkjh\n   222dfghdfhgd\n   333asdfdf\n"
say "the broken str: {the-str}"
say "the 2nd broken str: {yet-a-str}"
'int_literal(StdInt)

a = 47
if a == 47 && a != 48
   say "0 - a tricky one"
end
if (a == 47 && a != 48)
   say "1"
end
if (a == 48 - 1 && a != 49)
   say "2"
end
if true
   i = 1
   if (a == 48 - 1 && (!(a == 49) || a != 49))
      say "3"
   end
   while i > 0
      i = i - 1
      if true != false
         say "3.1"
      end
      if !(true == false)
         say "3.2"
      end
      if true
         say "3.3"
      end
      if true
         say "3.4"
      end
      if true
         say "4 "
         say "5"
         if true
            say "5.1"
         end
      end
      if false
         say "NO"
      else
         say "5.2a "
         say "5.3a"
         if true
            say "5.4a"
         end
      end
      if false
      else
         say "5.2b "
         say "5.3b"
         if true
            say "5.4b"
         end
      end
      if false
         if 47
            say "NO"
         end
         if 47
            say "NO"
         end
      end
      if true
         if !false
            say "6"
         end
         if 47
            say "7"
         end
      end
   end
end
[ab, ac] = 3, 2
[aa, ab, ac, ad] = 1, ac, ab, 4
say "should be 3: " + ac.to-s
DEBUG–SEPARATOR
zoo**(a, b, ...c Ints) Str ->
   if true
      i = 1
      if (a == 1 && a >= 0 && a <= 9999 && a != 2)
         say "8"
      end
      while i > 0
         i = i - 1
         if true
            say "9 "
            say "10"
         end
         if false
            if 41
               say "NO"
            else
               if 42
                  say "NO"
               else
                  if 43
                     say "NO"
                  else
                     say "NO"
                  end
               end
            end
            if 47
               say "NO"
            end
         else
            say "11"
            for val, ix in ("c", "b", "a")
               p "{val}, {ix}"
            end
         end
         if true
            if 47
               say "12"
            end
            if !47
               say "NO"
            else
               say "12"
            end
            if 1
               say "13"
            end
            if 47
               say "14"
            else
               say "NO"
            end
            if 1
               say "15"
            end
         end
      end
   end
   qwo = "{(a + b)} {c.to-s}"
   (a + b).to-s + " " + c.to-s + " == " + qwo

'int_literal(Ints)

p zoo $.Ints 1, $.Ints 2, $.Ints 47, $.Ints 42
reg-ex = /foo (ya)(.*)/i
m1 = "asdf foo ya fdsa".match reg-ex
m2 = "fda" =~ reg-ex
say "m1 = " + m1.to-s
say "m2 = " + m2.to-s
qwo(a Ints, b ~Ints) ->

qwo2(a ^Ints, b Ints) ->

qwo3(a Ints, b ~Ints) Str ->

qwo4(a Ints, b Ints) ->

qwo2 $.Ints 1, $.Ints 2
foo-list = List<List<List<String>>> $.Ints 1
n = $.Ints 4747 >> $.Ints 3
n = n >> $.Ints 1
m = $.Ints 4747 << $.Ints 3
m = m << $.Ints 1
say "n = " + n.to-s + " from " + $.Ints 4747.to-s
tag-hash = {#apa => "Apa", #katt => "Katt", #panter => "Panter"}
say "tag–hash: {tag-hash}"
json-hash = {"apa" => "Apa", "katt" => "Katt", "panter" => "Panter"}
say "json–correct–hash: {json-hash}"
js-hash = {"apa" => "Apa", "katt" => "Katt", "panter" => "Panter"}
say "perhaps to be js–hash: {js-hash}"
apa = #apa
katt = "katt"
panter = $.Ints 947735
arrow-hash = {apa => "Apa", katt => "Katt", panter => "Panter"}
say "arrow–hash: {arrow-hash}"
tag-hash-2 = {#apa => "Apa", #katt => "Katt", #panter => "Panter", #filurer => ["Filur", "Kappo", "Nugetto"], #tuple => ("47", $.Ints 13, 3.1415_f32, "yep", #Boo), #tuple2 => ("47", $.Ints 13, 3.1415_f32, "yep", #Boo), #bastard => "Bastard"}
say "tag–hash–2 type is {typeof(tag-hash-2)}"
say "tag–hash–2 value is {tag-hash-2}"
tuple1 = ($.Ints 13, $.Ints 32, $.Ints 47, $.Ints 2)
tuple2 = ("foo", $.Ints 1, $.Set {$.Ints 1, $.Ints 2, $.Ints 3})
set1 = $.Set {$.Ints 1, $.Ints 2, $.Ints 3, $.Ints 5}
set2 = $.Set {"foo", $.Ints 47, "mine", $.Ints 13}
list = [$.Ints 47, $.Ints 13, $.Ints 42, $.Ints 11]
say "- - ACCESS TERSECUTS! - -".yellow
say list[1], list[2]?, list[4]?
say tag-hash-2[#katt]
say json-hash["katt"], json-hash["panter"]
if json-hash["katt"]
   say "Yeeeaaaah"
end
say json-hash["neat_literal?"]?
json-hash["neat_literal"] = "47777777"
say json-hash["neat_literal"]
type TradeSide < enum Int8
   Unknown
   Buy
   Sell
end
match n
when $.Ints 1, $.Ints 2
   say "NOP: is 1|2"
when $.Ints 2
   say "NOP: is 3"
else
   say "16:  " + n.to-s
end
cond
when n == $.Ints 1
   say "NOP 1"
when n == $.Ints 47, n == $.Ints 593
   say "17"
else
   say "NOP " + n.to-s
end
match n
when $.Ints 1, $.Ints 2
   say "NOP: is 1|2"
when $.Ints 2
   say "NOP: is 3"
else
   say "17.1:  " + n.to-s
end
cond
when n == $.Ints 1
   say "NOP 1"
when n == $.Ints 47, n == $.Ints 593
   say "17.2"
else
   say "NOP " + n.to-s
end
match n
when $.Ints 1, $.Ints 2
   say "NOP: is 1|2"
when $.Ints 2
   say "NOP: is 3"
else
   say "17.3: " + n.to-s
end
cond
when n == $.Ints 1
   say "NOP 1"
when n == $.Ints 47, n == $.Ints 593
   say "17.4"
else
   say "NOP " + n.to-s
end
match n
when $.Ints 593
   say "18"
when $.Ints 2
   say "NO is 2"
else
   say "NO " + n.to-s
end
cond
when n == $.Ints 1
   say "NO is 1"
when n == $.Ints 593
   if false
   else
      say "19"
   end
else
   say "NO " + n.to-s
end
match n
when $.Ints 593
   say "19.1"
when $.Ints 2
   say "NO is 2"
else
   say "NO " + n.to-s
end
cond
when n == $.Ints 1
   say "NO is 1"
when n == $.Ints 593
   if false
   else
      say "19.2"
   end
else
   say "NO " + n.to-s
end
match n
when $.Ints 1
   say "is 1"
when $.Ints 2
   say "is 2"
else
   if false
      say "NO"
   else
      say "20: " + n.to-s
   end
end
cond
when n == $.Ints 593
   say "21"
when n == $.Ints 2
   say "is 2"
else
   say n.to-s
end
match n
when $.Ints 1
   say "is 1"
when $.Ints 2
   say "is 2"
else
   if false
      say "NO"
   else
      say "22: " + n.to-s
   end
end
cond
when n == $.Ints 593
   say "23"
when n == $.Ints 2
   say "is 2"
else
   say n.to-s
end
match n
when $.Ints 593
   say "23.1"
when $.Ints 2
   say "NO is 2"
else
   say "NO " + n.to-s
end
cond
when n == $.Ints 1
   say "NO is 1"
when n == $.Ints 593
   if false
   else
      say "23.2"
   end
else
   say "NO " + n.to-s
end
match n
when $.Ints 1
   say "is 1"
when $.Ints 2
   say "is 2"
else
   if false
      say "NO"
   else
      say "20: " + n.to-s
   end
end
cond
when n == $.Ints 593
   say ": 23.3a"
when n == $.Ints 2
   say "is 2"
else
   say n.to-s
end
cond
when n == $.Ints 593
   say ": 23.3b"
when n == $.Ints 2
   say "is 2"
else
   say n.to-s
end
for v, i in [#apa, #katt]
   say ": {i}: {v}"
end
if true
   say ": true"
end
foo(a, b, c Str) ->
   (a + b).to-s + c

x = foo a, $.Ints 2, "3"
a = (a Ints, b Ints) -> 
   (a + b).to-s

b = (a Str, tmp-47-_ Ints, b Bool, c Real) -> 
   "{a} {x}"

say "23.4 def lambda c"
c = (a ~Ints, b Str, c Ints) -> 
   a.to-s + b + c.to-s

'real_literal(Float64)

p b.call "23.5a Closured Lambda says", $.Ints 0, true, 0.42
p b.call "23.5b Closured Lambda says", $.Ints 1, true, 0.47
pp typeof(b), b.class
alias Fn = Proc
booze1(f1 Fn<I32, List<_>, List<List<Ptr<Int32>>>>, f2 Fn<Str, Nil, List<Bool>>) ->

booze2(f1 (List<_>, List<List<Ptr<Int32>>> ) -> I32, f2 (Nil, List<Bool> ) -> Str) ->

say "List[List<Ptr[Int32]>] => " + List<List<Ptr<Int32>>>.to-s
booze2(f1 (I32, _ ) -> Nil, f2 (Str ) -> Nil) ->

booze3(f1 (I32, _ ) -> Nil, f2 (Str ) -> Nil) ->

list = [#abra, #baba, #cadabra]
say "the list ({list.class}): {list}"
list = ["foo", "yaa", "qwö"]
say "the 2nd list ({list.class}): {list}"
y = list.each((v)~>
   p v
).map ~.* $.Ints 2
y = (list.each (v)~>
   p v
).map ~.* $.Ints 2
y = list.each (1)~>
   p 1
.map ~.* $.Ints 2
say "mega fettma y = {y}"
list.each-with-index (1, 2)~>
   p 1
   if 2 == $.Ints 4
      break
   end

(list.map ~.+ "X").each-with-index (1, 2)~>
   p 1
   if 2 == $.Ints 4
      break
   end

list.each-with-index (v, i)~>
   p v
   if i == $.Ints 4
      break
   end

(list.map ~.+ "X").each-with-index (x, y)~>
   p x
   if y == $.Ints 4
      break
   end

list.each-with-index (1, 2)~>
   p 1
   if 2 == $.Ints 4
      break
   end

for val in list
   say val
end
list.each (val)~>
   say("implicit nest {val.to-s}")

for val in list
   say val
end
for crux in list
   say "do nest" + crux.to-s
end
for arrowv in list
   say "=> nest" + arrowv.to-s
end
for spccolonv in list
   say "\\s: nest" + spccolonv.to-s
end
for colonv in list
   say ": nest" + colonv.to-s
end
for ,ix in list
   if true
      say "begins-block:"
      say "  {ix}"
   end
end
for val, ix in list
   say "{val}, {ix}"
end
for val, ix in list
   say "{val}, {ix}"
end
for val, ix in list
   p "{val}, {ix}"
end
for ,ix in list
   say ix
end
for val, ix in list
   say "{val}, {ix}"
end
for ,ix in list
   say ix
end
for val, ix in ["c", "b", "a"]
   say "{val}, {ix}"
end
for val, ix in $.Set {"c", "b", "a"}
   say "{val}, {ix}"
end
for val, ix in $.Set {"c", "b", "a"}
   say "{val}, {ix}"
end
for val, ix in ["c", "b", "a"]
   say "{val}, {ix}"
end
module TheTrait
   is-cool-traited?() ->
      true
   
end
module AnotherTrait<S1>
   val() ->
      @another-val
   
   valhalla() -> abstract
   valhalla3() -> abstract
end
type Qwa < abstract
   include TheTrait
end

type Bar < Qwa
   @@my-foo Int64
   @@my-foo = 47_i64
   @@some-other-foo Ints
   @@some-other-foo = $.Ints 42
   @@yet-a-foo = $.Ints 42
   @@RedFoo = 5
   @@GreenFoo = 7
   RedBar = 6
   GreenBar = 8
   @foo-a Str
   @foo-a = ""
   @foo-b Ints
   @foo-b = 0_i64
   @foo-c I64
   @foo-c = 0_i64
   @foo-ya I32
   @foo-ya = 0
   Type.set-foo(v) ->
      @@my-foo = v
   
   Type.get-foo() ->
      @@my-foo
   
end

Bar.set-foo $.Ints 4
say "Bar.get-foo = {Bar.get-foo}"
say "declare a Foo type"
type Foo<S1> < Bar
   include AnotherTrait<S1>
   @foo-x I64
   @foo-x = 47_i64
   foo-x() ->
      @foo-x
   
   foo-x=(@foo-x I64) ->
   
   @foo-y = $.Ints 48
   @foo-z = "bongo"
   foo-z() ->
      @foo-z
   
   @foo-u Ints
   @foo-u = $.Ints 47
   foo-u() ->
      @foo-u
   
   foo-u=(@foo-u Ints) ->
   
   @foo-w = $.Ints 47
   foo-w=(@foo-w) ->
   
   ifdef x86-64
      @bar-x I64
      @bar-x = 47_i64
      bar-x() ->
         @bar-x
      
      bar-x=(@bar-x I64) ->
      
   else
      @bar-x I32
      @bar-x = 47
      bar-x() ->
         @bar-x
      
      bar-x=(@bar-x I32) ->
      
   end
   @bar-y = $.Ints 48
   @bar-z = "bongo"
   bar-z() ->
      @bar-z
   
   @bar-u Ints
   @bar-u = $.Ints 47
   bar-u() ->
      @bar-u
   
   bar-u=(@bar-u Ints) ->
   
   @bar-w = $.Ints 47
   bar-w() ->
      @bar-w
   
   ifdef x86-64
      init(a S1) ->
         @foo-a = a
      
   else
      init(b S1) ->
         @foo-a = b
      
   end
   init() ->
   
   fn-1aa(x) ->
      nil
   
   fn-1ab(x) Nil ->
      nil
   
   fn-1ba**(x) $.Nil ->
      nil
   
   fn-1ca(x) $.Nil ->
      nil
   
   fn-1da(x) ->
      nil
   
   fn-1ea(x) $.Nil ->
      nil
   
   fn-1fa(x) $.Nil ->
      nil
   
   fn-1ga(x) $.Nil ->
      ifdef x86-64
         say "Hey"
      else
         say "you!"
      end
      nil
   
   fn-1i(x) $.Nil ->
      say "Yeay"
      return "Foo"
      nil
   
   fn-a(a, b) ->
      "a: {a}, {b}"
   
   fn-b(a S1, b Ints) ->
      "b: {a}, {b}"
   
   fn-c**(a, b S1) S1 ->
      "c: {a}, {b}"
   
   fn-c*(a, b Ints) ->
      "c: {a}, {b}"
   
   fn-d1(a, b) ->
      @foo-a = a
      @foo-b = b
      fn-e
   
   fn-d2(a S1, b Ints) ->
      @foo-a = a
      @foo-b = b
      fn-e
   
   fn-e() ->
      fa = @foo-a
      "e: {fa}, {@foo-b}"
   
   call() ->
      fn-e
   
   [](i) ->
      @foo-b + i
   
end

type FooStyle2<S1> < Bar
   include AnotherTrait<S1>
   @foo-x I64
   @foo-x = 47_i64
   foo-x() ->
      @foo-x
   
   foo-x=(@foo-x I64) ->
   
   @foo-y = $.Ints 48
   @foo-z = "bongo"
   foo-z() ->
      @foo-z
   
   @foo-u Ints
   @foo-u = $.Ints 47
   foo-u() ->
      @foo-u
   
   foo-u=(@foo-u Ints) ->
   
   @foo-w = $.Ints 47
   foo-w=(@foo-w) ->
   
   ifdef x86-64
      @bar-x I64
      @bar-x = 47_i64
      bar-x() ->
         @bar-x
      
      bar-x=(@bar-x I64) ->
      
   else
      @bar-x I32
      @bar-x = 47
      bar-x() ->
         @bar-x
      
      bar-x=(@bar-x I32) ->
      
   end
   @bar-y = $.Ints 48
   @bar-z = "bongo"
   bar-z() ->
      @bar-z
   
   @bar-u Ints
   @bar-u = $.Ints 47
   bar-u() ->
      @bar-u
   
   bar-u=(@bar-u Ints) ->
   
   @bar-w = $.Ints 47
   bar-w() ->
      @bar-w
   
   ifdef x86-64
      init(a S1) ->
         @foo-a = a
      
   else
      init(b S1) ->
         @foo-a = b
      
   end
   init() ->
   
   fn-1aa(x) ->
      nil
   
   fn-1ab(x) Nil ->
      nil
   
   fn-1ba**(x) $.Nil ->
      nil
   
   fn-1ca(x) $.Nil ->
      nil
   
   fn-1da(x) ->
      nil
   
   fn-1ea(x) $.Nil ->
      nil
   
   fn-1fa(x) $.Nil ->
      nil
   
   fn-1ga(x) $.Nil ->
      ifdef x86-64
         say "Hey"
      else
         say "you!"
      end
      nil
   
   fn-1i(x) $.Nil ->
      say "Yeay"
      return "Foo"
      nil
   
   fn-a(a, b) ->
      "a: {a}, {b}"
   
   fn-b(a S1, b Ints) ->
      "b: {a}, {b}"
   
   fn-c**(a, b S1) S1 ->
      "c: {a}, {b}"
   
   fn-c*(a, b Ints) ->
      "c: {a}, {b}"
   
   fn-d1(a, b) ->
      @foo-a = a
      @foo-b = b
      fn-e
   
   fn-d2(a S1, b Ints) ->
      @foo-a = a
      @foo-b = b
      fn-e
   
   fn-e() ->
      fa = @foo-a
      "e: {fa}, {@foo-b}"
   
   call() ->
      fn-e
   
   [](i) ->
      @foo-b + i
   
end

say "create a Foo instance"
foo = Foo<Str>()
pp foo.foo-x
pp foo.foo-w = $.Ints 46
say "done"
say foo.fn-a "24 blargh", $.Ints 47
say foo.fn-b "25 blargh", $.Ints 47
say foo.fn-d1 "27 blargh", $.Ints 47
foo.fn-d2 "28 blargh", $.Ints 47
say foo.fn-e
boo = Foo<Str>()
boo = Foo<Str> 
boo = Foo<Str>()
boo = Foo<Str>()
boo = Foo<Str> 
boo = Foo<Str>()
bar = Foo<Str>("No Blargh")
bar = Foo("No Blargh")
bar = Foo "No Blargh"
bar = Foo<Str> "No Blargh"
bar = Foo "No Blargh"
bar = Foo<Str> "29 Blargh"
say "done"
say bar.fn-e
say "functor call"
say bar.call()
bar.fn-d2 "30 blargh", $.Ints 47
say "varying word-delimiters"
say bar.fn-e
say bar.fn-e
say bar.fn-e
say bar.fn-e
say "shit-sandwich"
shit-sandwich = bar.fn-e
shit-sandwich = "arghh"
say shit-sandwich
say bar.call()
say bar.call()
say typeof(foo)
say foo.class
say "7 .&. 12 == {$.Ints 7 & $.Ints 12}"
say "12 .|. 1 == {$.Ints 12 | $.Ints 1}"
say "12 .^. 2 == {$.Ints 12 ^ $.Ints 2}"
say ".~. 12 == {~$.Ints 12}"
'link("gmp")

lib MyLibGmp
   TEST_CONST = $.Ints 47
   alias Int = LibC.Int
   alias Long = LibC.Long
   alias ULong = LibC.ULong
   alias SizeT = LibC.SizeT
   alias Double = LibC.Double
   ifdef x86-64
      alias TestT = UInt64
   else
      alias TestT = UInt32
   end
   struct Mpz
      _mp-alloc Int32
      _mp-size Int32
      ifdef x86-64
         _mp-d Ptr<ULong>
      else
         _mp-d Ptr<ULong>
      end
   end
   alias MpzP = Ptr<Mpz>
   cfun init = __gmpz_init(x : MpzP)
   cfun init_set_si = __gmpz_init_set_si(rop : Ptr<Mpz>, op : Long)
   cfun init_set_str = __gmpz_init_set_str(rop : MpzP, str : Ptr<UInt8>, base : Int)
   cfun get_si = __gmpz_get_si(op : MpzP) : Long
   cfun get_str = __gmpz_get_str(str : Ptr<UInt8>, base : Int, op : MpzP) : Ptr<UInt8>
   cfun add = __gmpz_add(rop : MpzP, op1 : MpzP, op2 : MpzP)
   cfun set_memory_functions = __gmp_set_memory_functions(malloc : (SizeT ) -> Ptr<Void>, realloc : (Ptr<Void>, SizeT, SizeT ) -> Ptr<Void>, free : (Ptr<Void>, SizeT ) -> Void)
end
MyLibGmp.set-memory-functions((size) -> 
   GC.malloc(size)
, (ptr, old-size, new-size) -> 
   GC.realloc(ptr, new-size)
, ((ptr, size) -> 
   GC.free(ptr)
))
MyLibGmp.set-memory-functions((size) -> 
   GC.malloc(size)
, (ptr, old-size, new-size) -> 
   GC.realloc(ptr, new-size)
, (ptr, size) -> 
   GC.free(ptr)
)
x = $.Ints 7
add-as-big-ints(a, b) ->
   bigv1 = raw MyLibGmp.Mpz
   MyLibGmp.init out bigret
   if a.of?(Str)
      MyLibGmp.init-set-str pointerof(bigv1), a, $.Ints 10
   else
      MyLibGmp.init-set-si pointerof(bigv1), a
   end
   if b.of?(Str)
      MyLibGmp.init-set-str out bigv2, b, $.Ints 10
   else
      MyLibGmp.init-set-si pointerof(bigv2), b
   end
   MyLibGmp.add pointerof(bigret), pointerof(bigv1), pointerof(bigv2)
   result = Str MyLibGmp.get-str nil, $.Ints 10, pointerof(bigret)
   say "bigint add result: {result}"

pp MyLibGmp.TEST_CONST
add-as-big-ints $.Ints 42, $.Ints 47
add-as-big-ints "42", "47"
add-as-big-ints "42", $.Ints 47
add-as-big-ints("42543453146456243561345431543513451345245643256257798063244", "47098098432409798761098750982709854959543145346542564256245")
say "Non self-extended:".white
p "CrystalModule", CrystalModule
p "CrystalModule.ROOT_CONST", CrystalModule.ROOT_CONST
p "CrystalModule.CrystalClass", CrystalModule.CrystalClass
p "CrystalModule.CrystalClass.CLASS_ROOT_CONST", CrystalModule.CrystalClass.CLASS_ROOT_CONST
p "CrystalModule.self_def", CrystalModule.self-def
p "CrystalModule.CrystalClass.class_func", CrystalModule.CrystalClass.class-func
say "self-extended (includes root_def):".white
p "CrystalModule2", CrystalModule2
p "CrystalModule2.ROOT_CONST", CrystalModule2.ROOT_CONST
p "CrystalModule2.CrystalClass", CrystalModule2.CrystalClass
p "CrystalModule2.CrystalClass.CLASS_ROOT_CONST", CrystalModule2.CrystalClass.CLASS_ROOT_CONST
p "CrystalModule2.self_def", CrystalModule2.self-def
p "CrystalModule2.CrystalClass.class_func", CrystalModule2.CrystalClass.class-func
p "CrystalModule2.root_def", CrystalModule2.root-def
module AllTheRest
   type RestFoo < value
      rest-foo() ->
         true
      
   end

   xx = $.Ints 47
   yy = 47.47
   say "{"foo".magenta}, {"bar".grey}, {"qwo".white}"
   say "{"foo".magenta2}, {"bar".grey2}, {"qwo".white}"
   say "All DOWN ".red
   say "         AND OUT".red2
end
