say("\n\nBefore requires!\n\n")
require "./crystal-scopes"
require "wild_colors"
say("\nLet's ROCK\n".red)
say("\nfunction(foo) { SomeJsCode(foo(\"bar}\"));}\n")
_debug_start_ = true
alias Ints = StdInt
alias Real = Float64
MY_CONST = begin
   x = 0_i64
   (2_i64.upto(4_i64)).each, |a|
      x = x + a
      say("calculating MY_CONST, {a}")
   
   x
end
pp(MY_CONST)
pp($.say("blargh"))
pp($.MY_CONST)
pp($.MY_CONST)
module Djur
   module Boo
      APA = 47_i64
      type Apa
         @@foo = 1_i64
         @@bar = 2_i64
         @foo 'Ints
         @bar 'Ints
         @foo’ 'Ints
         @foo’ = 47_i64
         @bar’ = 47_i64
         @foo’’ 'Ints
         @bar’’ 'Ints
         @foo3 'Ints
         @bar3 ^Ints
         @qwo3 ~Ints
         self.my_def() ->
            say("Hit the spot! {@@foo’}, {@@bar}")
         
         inst_def() ->
            say("Hit the spot! {@foo’}, {@bar}")
         
      end
      enum Legs
         NONE
         TWO
         FOUR
         SIX
         EIGHT
         self.is_six?(v) ->
            v == SIX
         
      end
   end
end
say("1")
Djur.Boo.Apa.my_def
say("Djur::Boo::Legs::TWO = {Djur.Boo.Legs.TWO}")
Djur.Boo.Apa.my_def
say("Djur.Boo.Legs.TWO = {Djur.Boo.Legs.TWO}")
say("Djur.Boo.Legs.is-six?(EIGHT) = {Djur.Boo.Legs.is_six?(Djur.Boo.Legs.EIGHT)}")
type Blk
   initialize(x, &block '() ->) ->
      yield x + 1_i64
      yield x - 2_i64
   
end
blk = Blk.new(4_i64, |x|
   say("in blk init block: {x}")
)
blk2 = Blk.new(7_i64, |x|
   say("in blk2 init block: {x}")
)
module Functor
end
type MyFunctor
   include Functor
   @foo = 47_i64
   call() ->
      "call()"
   
   call(a, b) ->
      "call {a}, {b}, {@foo}"
   
   bar() ->
      true
   
end
myfu = MyFunctor.new
pp(myfu.bar)
pp(myfu.call("ctest", "cfooo"))
say(myfu.call("test", "fooo"))
say(myfu)
say(myfu.call)
my_fun_fun(f) ->
   f.call("testing", "it")

pp(my_fun_fun(myfu))
my_lambda = (x 'Str) -> 
   say("x: {x}")

my_lambda.call("47")
type String
   <<(obj) ->
      "{self}{obj}"
   
end
say(((("fdaf" + "fdsf") << "aaasd") << 47.13) << " - yippie!")
fun_with_various_local_vars(a = 0_i64 'I32 | I64 | Real) $.Nil ->
   say("a type = {typeof(a)}")
   zar1 = 1_i64
   zar2 ^Ints
   zar4 'Real
   zar3 ~Str
   pp(zar2.class, zar4.class, zar3.class)
   say("fun-with-various-local-vars {zar1}")
   nil

fun_with_various_local_vars(47_i64)
fun_with_exception_action(x) $.Nil ->
   try
      try
         a = 1_i64 / 0_i64
      rescue e : IndexError | ArgumentError
         say("In fun: Rescued {e}")
      rescue DivisionByZero
         say("In fun: Rescued divizon by zero")
      rescue e
         say("Rescued some kind of shit")
      fulfil
         say("In fun: Nothing to rescue - yippie!")
      ensure
         say("In fun: Oblivious to what happened!")
      end
      a = 1_i64 / x
      nil
   fulfil
      say("eof fun-with-exception-action - ONLY on SUCCESS!")
   ensure
      say("eof fun-with-exception-action - EVEN on RAISE!")
   end
   nil

say("")
say("call fun-with-exception-action 1")
try
   fun_with_exception_action(1_i64)
   say("after call fun-with-exception-action")
rescue
   say("rescued fun-with-exception-action in Program")
end
say("after try/rescue call fun-with-exception-action")
say("")
say("")
say("call fun-with-exception-action 0")
try
   fun_with_exception_action(0_i64)
   say("after call fun-with-exception-action")
rescue
   say("rescued fun-with-exception-action in Program")
end
say("after try/rescue call fun-with-exception-action")
say("")
foo_named(awol, foo = 47_i64, bar = "fds") $.Nil ->
   say("{awol}, {foo}, {bar}")
   nil

foo_named(1_i64, "blarg", "qwö qwö")
foo_named(2_i64, 42_i64, bar: "yo")
foo_named(3_i64, foo: 11_i64, bar: "yo")
list = List[Str].new
list << "foo"
list << "yaa"
v = list.map, |x, y|
   x + "1"

w = list.map, |x, y|
   "{x} 47"

i = list.map, |x, y|
   "{x} 13"

j = list.map, |_1|
   "{_1} 13"

puts("{v}, {w}")
list = [47_i64, 13_i64, 42_i64, 11_i64]
x = list.each, |v|
   p(v)
.map(&.*(2_i64))
y = ((list.each, |v|
   p(v)
).map(&.*(2_i64)))
z = list.each, |v|
   p(v)
.map(&.*(2_i64))
u = list.each, |v|
   p(v)
.map(&.*(2_i64))
DEBUG–SEPARATOR = 47_i64
f(y '() ->) ->
   nil

g(y '() ->) ->
   nil

f(() -> 
   ([] of Ints).flat_map, ~>
      [] of Ints
   
)
f(() -> 
   ([] of Ints).flat_map, ~>
      [] of Ints
   
)
f(() -> 
   ([] of Ints).flat_map, ~>
      [] of Ints
   
)

char = 'a'
say("char: {char} ({typeof(char)})")
straight_str = "no {interpolation\t here}\n\tOk!"
say("straight-str: {straight_str} ({typeof(straight_str)})")
the_str = "kjhgkjhdfghdfhgd"
a = 47_i64
if a == 47_i64 && a != 48_i64

   say("1")
end
if a == 48_i64 - 1_i64 && a != 49_i64

   say("2")
end
if true
   i = 1_i64
   if    a == 48_i64 - 1_i64 && (!(a == 49_i64) || a != 49_i64)

      say("3")
   end
   while i > 0_i64
      i = i - 1_i64
      if true != false
         say("3.1")
      end
      if !(true == false)
         say("3.2")
      end
      if true
         say("3.3")
      end
      if true
         say("3.4")
      end
      if true
         say("4 ")
         say("5")
         if true
            say("5.1")
         end
      end
      if false
         say("NO")
      else
         say("5.2a ")
         say("5.3a")
         if true
            say("5.4a")
         end
      end
      if false
      else
         say("5.2b ")
         say("5.3b")
         if true
            say("5.4b")
         end
      end
      if false
         if 47_i64
            say("NO")
         end
         if 47_i64
            say("NO")
         end
      end
      if true
         if !false
            say("6")
         end
         if 47_i64
            say("7")
         end
      end
   end
end
[ab, ac] = 3_i64, 2_i64
[aa, ab, ac, ad] = 1_i64, ac, ab, 4_i64
say("should be 3: " + ac.to_s)
DEBUG–SEPARATOR
zoo(a, b, ...c 'Ints) Str ->
   if true
      i = 1_i64
      if       a == 1_i64 && a > 0_i64 && a < 9999_i64 && a != 2_i64

         say("8")
      end
      while i > 0_i64
         i = i - 1_i64
         if true
            say("9 ")
            say("10")
         end
         if false
            if 41_i64
               say("NO")
            else
               if 42_i64
                  say("NO")
               else
                  if 43_i64
                     say("NO")
                  else
                     say("NO")
                  end
               end
            end
            if 47_i64
               say("NO")
            end
         else
            say("11")
            for val, ix in {"c", "b", "a"}
               p("{val}, {ix}")
            end
         end
         if true
            if 47_i64
               say("12")
            end
            if !47_i64
               say("NO")
            else
               say("12")
            end
            if 1_i64
               say("13")
            end
            if 47_i64
               say("14")
            else
               say("NO")
            end
            if 1_i64
               say("15")
            end
         end
      end
   end
   qwo = "{   a + b
} {c.to_s}"
   ((((a + b).to_s + " ") + c.to_s) + " == ") + qwo

p(zoo(1_i64, 2_i64, 47_i64, 42_i64))
reg_ex = /foo (ya)(.*)/i
m1 = "asdf foo ya fdsa".match(reg_ex)
m2 = "fda" =~ reg_ex
say("m1 = " + m1.to_s)
say("m2 = " + m2.to_s)
qwo(a 'Ints, b ~Ints) ->

qwo2(a ^Ints, b 'Ints) ->

qwo3(a 'Ints, b ~Ints) Str ->

qwo4(a 'Ints, b 'Ints) ->

qwo2(1_i64, 2_i64)
n = 4747_i64 >> 3_i64
n >> 1_i64
say((("n = " + n.to_s) + " from ") + 4747_i64.to_s)
json_hash = {"apa" => "Apa", "katt" => "Katt", "panter" => "Panter"}
say("json–correct–hash: {json_hash}")
tag_hash = {#apa => "Apa", #katt => "Katt", #panter => "Panter"}
say("tag–hash: {tag_hash}")
apa = #apa
katt = "katt"
panter = 947735_i64
js_hash = {apa => "Apa", katt => "Katt", panter => "Panter"}
say("perhaps to be js–hash: {js_hash}")
arrow_hash = {apa => "Apa", katt => "Katt", panter => "Panter"}
say("arrow–hash: {arrow_hash}")
tag_hash_2 = {#apa => "Apa", #katt => "Katt", #panter => "Panter", #filurer => ["Filur", "Kappo", "Nugetto"], #tuple => {"47", 13_i64, 3.1415, "yep", #Boo}, #bastard => "Bastard"}
say("tag–hash–2 type is {typeof(tag_hash_2)}")
say("tag–hash–2 value is {tag_hash_2}")
enum TradeSide Int8
   Unknown
   Buy
   Sell
end
match n
when 1_i64, 2_i64
   say("NOP: is 1|2")
when 2_i64
   say("NOP: is 3")
else
   say("16:  " + n.to_s)
end
cond
when n == 1_i64
   say("NOP 1")
when n == 47_i64, n == 593_i64
   say("17")
else
   say("NOP " + n.to_s)
end
match n
when 1_i64, 2_i64
   say("NOP: is 1|2")
when 2_i64
   say("NOP: is 3")
else
   say("17.1:  " + n.to_s)
end
cond
when n == 1_i64
   say("NOP 1")
when n == 47_i64, n == 593_i64
   say("17.2")
else
   say("NOP " + n.to_s)
end
match n
when 1_i64, 2_i64
   say("NOP: is 1|2")
when 2_i64
   say("NOP: is 3")
else
   say("17.3: " + n.to_s)
end
cond
when n == 1_i64
   say("NOP 1")
when n == 47_i64, n == 593_i64
   say("17.4")
else
   say("NOP " + n.to_s)
end
match n
when 593_i64
   say("18")
when 2_i64
   say("NO is 2")
else
   say("NO " + n.to_s)
end
cond
when n == 1_i64
   say("NO is 1")
when n == 593_i64
   if false
   else
      say("19")
   end
else
   say("NO " + n.to_s)
end
match n
when 593_i64
   say("19.1")
when 2_i64
   say("NO is 2")
else
   say("NO " + n.to_s)
end
cond
when n == 1_i64
   say("NO is 1")
when n == 593_i64
   if false
   else
      say("19.2")
   end
else
   say("NO " + n.to_s)
end
match n
when 1_i64
   say("is 1")
when 2_i64
   say("is 2")
else
   if false
      say("NO")
   else
      say("20: " + n.to_s)
   end
end
cond
when n == 593_i64
   say("21")
when n == 2_i64
   say("is 2")
else
   say(n.to_s)
end
match n
when 1_i64
   say("is 1")
when 2_i64
   say("is 2")
else
   if false
      say("NO")
   else
      say("22: " + n.to_s)
   end
end
cond
when n == 593_i64
   say("23")
when n == 2_i64
   say("is 2")
else
   say(n.to_s)
end
match n
when 593_i64
   say("23.1")
when 2_i64
   say("NO is 2")
else
   say("NO " + n.to_s)
end
cond
when n == 1_i64
   say("NO is 1")
when n == 593_i64
   if false
   else
      say("23.2")
   end
else
   say("NO " + n.to_s)
end
match n
when 1_i64
   say("is 1")
when 2_i64
   say("is 2")
else
   if false
      say("NO")
   else
      say("20: " + n.to_s)
   end
end
cond
when n == 593_i64
   say(": 23.3a")
when n == 2_i64
   say("is 2")
else
   say(n.to_s)
end
cond
when n == 593_i64
   say(": 23.3b")
when n == 2_i64
   say("is 2")
else
   say(n.to_s)
end
for v, i in [#apa, #katt]
   say(": {i}: {v}")
end
if true
   say(": true")
end
foo(a, b, c 'Str) ->
   (a + b).to_s + c

x = foo(a, 2_i64, "3")
a = (a 'Ints, b 'Ints) -> 
   (a + b).to_s

b = (a 'Str, tmp_47_ 'Ints, b 'Bool, c 'Real) -> 
   "{a} {x}"

say("23.4 def lambda c")
c = (a ~Ints, b 'Str, c 'Ints) -> 
   (a.to_s + b) + c.to_s

p(b.call("23.5a Closured Lambda says", 0_i64, true, 0.42))
p(b.call("23.5b Closured Lambda says", 1_i64, true, 0.47))
pp(typeof(b), b.class)
alias Fn = Proc
booze1(f1 'Fn[I32, List[_], List[List[Ptr[Int32]]]], f2 'Fn[Str, Nil, List[Bool]]) ->

booze2(f1 '(List[_], List[List[Ptr[Int32]]] ) -> I32, f2 '(Nil, List[Bool] ) -> Str) ->

say("List[List<Ptr[Int32]>] => " + List[List[Ptr[Int32]]].to_s)
booze2(f1 '(I32, _ ) -> Nil, f2 '(Str ) -> Nil) ->

booze3(f1 '(I32, _ ) -> Nil, f2 '(Str ) -> Nil) ->

list = [#abra, #baba, #cadabra]
say("the list ({list.class}): {list}")
list = ["foo", "yaa", "qwö"]
say("the 2nd list ({list.class}): {list}")
y = list.each, |v|
   p(v)
.map(&.*(2_i64))
y = (list.each, |v|
   p(v)
).map(&.*(2_i64))
list.each_with_index, |_1, _2|
   p(_1)
   if _2 == 4_i64
      break
   end

(list.map(&.+("X"))).each_with_index, |_1, _2|
   p(_1)
   if _2 == 4_i64
      break
   end

list.each_with_index, |v, i|
   p(v)
   if i == 4_i64
      break
   end

(list.map(&.+("X"))).each_with_index, |x, y|
   p(x)
   if y == 4_i64
      break
   end

list.each_with_index, |_1, _2|
   p(_1)
   if _2 == 4_i64
      break
   end

for val in list
   say(val)
end
list.each, |val|
   say("implicit nest {val.to_s}")

for val in list
   say(val)
end
for crux in list
   say("do nest" + crux.to_s)
end
for arrowv in list
   say("=> nest" + arrowv.to_s)
end
for spccolonv in list
   say("\\s: nest" + spccolonv.to_s)
end
for colonv in list
   say(": nest" + colonv.to_s)
end
for ,ix in list
   if true
      say("begins-block:")
      say("  {ix}")
   end
end
for val, ix in list
   say("{val}, {ix}")
end
for val, ix in list
   say("{val}, {ix}")
end
for val, ix in list
   p("{val}, {ix}")
end
for ,ix in list
   say(ix)
end
for val, ix in list
   say("{val}, {ix}")
end
for ,ix in list
   say(ix)
end
for val, ix in ["c", "b", "a"]
   say("{val}, {ix}")
end
for val, ix in {"c", "b", "a"}
   say("{val}, {ix}")
end
for val, ix in {"c", "b", "a"}
   say("{val}, {ix}")
end
for val, ix in ["c", "b", "a"]
   say("{val}, {ix}")
end
module TheTrait
   is_cool_traited?() ->
      true
   
end
module AnotherTrait[S1]
   val() ->
      @another_val
   
   valhalla() -> abstract
   valhalla3() -> abstract
end
type Qwa
   include TheTrait
end
type Bar < Qwa
   @@my_foo 'Int64
   @@my_foo = 47_i64
   @@some_other_foo 'Ints
   @@some_other_foo = 42_i64
   @@yet_a_foo = 42_i64
   @@RedFoo = 5_i64
   @@GreenFoo = 7_i64
   RedBar = 6_i64
   GreenBar = 8_i64
   @foo_a 'Str
   @foo_a = ""
   @foo_b 'Ints
   @foo_b = 0_i64
   @foo_c 'I64
   @foo_c = 0_i64
   @foo_ya 'I32
   @foo_ya = 0
   self.set_foo(v) ->
      @@my_foo = v
   
   self.get_foo() ->
      @@my_foo
   
end
Bar.set_foo(4_i64)
say("Bar.get-foo = {Bar.get_foo}")
say("declare a Foo type")
type Foo[S1] < Bar
   include AnotherTrait[S1]
   @foo_x 'I64
   @foo_x = 47_i64
   foo_x() ->
      @foo_x
   
   foo_x=(@foo_x 'I64) ->
   
   @foo_y = 48_i64
   @foo_z = "bongo"
   foo_z() ->
      @foo_z
   
   @foo_u 'Ints
   @foo_u = 47_i64
   foo_u() ->
      @foo_u
   
   foo_u=(@foo_u 'Ints) ->
   
   @foo_w = 47_i64
   foo_w=(@foo_w) ->
   
   ifdef x86_64
      @bar_x 'I64
      @bar_x = 47_i64
      bar_x() ->
         @bar_x
      
      bar_x=(@bar_x 'I64) ->
      
   else
      @bar_x 'I32
      @bar_x = 47
      bar_x() ->
         @bar_x
      
      bar_x=(@bar_x 'I32) ->
      
   end
   @bar_y = 48_i64
   @bar_z = "bongo"
   bar_z() ->
      @bar_z
   
   @bar_u 'Ints
   @bar_u = 47_i64
   bar_u() ->
      @bar_u
   
   bar_u=(@bar_u 'Ints) ->
   
   @bar_w = 47_i64
   bar_w() ->
      @bar_w
   
   ifdef x86_64
      initialize(a 'S1) ->
         @foo_a = a
      
   else
      initialize(b 'S1) ->
         @foo_a = b
      
   end
   initialize() ->
   
   fn_1aa(x) ->
      nil
   
   fn_1ab(x) Nil ->
      nil
   
   fn_1ba(x) $.Nil ->
      nil
   
   fn_1ca(x) $.Nil ->
      nil
   
   fn_1da(x) ->
      nil
   
   fn_1ea(x) $.Nil ->
      nil
   
   fn_1fa(x) $.Nil ->
      nil
   
   fn_1ga(x) $.Nil ->
      ifdef x86_64
         say("Hey")
      else
         say("you!")
      end
      nil
   
   fn_1i(x) $.Nil ->
      say("Yeay")
      return "Foo"
      nil
   
   fn_a(a, b) ->
      "a: {a}, {b}"
   
   fn_b(a 'S1, b 'Ints) ->
      "b: {a}, {b}"
   
   fn_c(a, b 'S1) S1 ->
      "c: {a}, {b}"
   
   fn_c(a, b 'Ints) ->
      "c: {a}, {b}"
   
   fn_d1(a, b) ->
      @foo_a = a
      @foo_b = b
      fn_e
   
   fn_d2(a 'S1, b 'Ints) ->
      @foo_a = a
      @foo_b = b
      fn_e
   
   fn_e() ->
      fa = @foo_a
      "e: {fa}, {@foo_b}"
   
   call() ->
      fn_e
   
   [](i) ->
      @foo_b + i
   
end
say("create a Foo instance")
foo = Foo[Str].new
pp(foo.foo_x)
pp(foo.foo_w = 46_i64)
say("done")
say(foo.fn_a("24 blargh", 47_i64))
say(foo.fn_b("25 blargh", 47_i64))
say(foo.fn_c("26 blargh", 47_i64))
say(foo.fn_d1("27 blargh", 47_i64))
foo.fn_d2("28 blargh", 47_i64)
say(foo.fn_e)
bar = Foo[Str].new("No Blargh")
bar = Foo.new("No Blargh")
bar = Foo.new("No Blargh")
bar = Foo[Str].new("No Blargh")
bar = Foo.new("No Blargh")
bar = Foo[Str].new("29 Blargh")
say("done")
say(bar.fn_e)
say("functor call")
say(bar.call)
bar.fn_d2("30 blargh", 47_i64)
say("varying word-delimiters")
say(bar.fn_e)
say(bar.fn_e)
say(bar.fn_e)
say(bar.fn_e)
say("shit-sandwich")
shit_sandwich = bar.fn_e
say(shit_sandwich)
say(bar.call)
say(bar.call)
say(typeof(foo))
say(foo.class)
say("7 .&. 12 == {7_i64 & 12_i64}")
say("12 .|. 1 == {12_i64 | 1_i64}")
say("12 .^. 2 == {12_i64 ^ 2_i64}")
say(".~. 12 == {~12_i64}")
\Link("gmp")
lib MyLibGmp
   TEST_CONST = 47_i64
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
      _mp_alloc 'Int32
      _mp_size 'Int32
      ifdef x86_64
         _mp_d 'Ptr[ULong]
      else
         _mp_d 'Ptr[ULong]
      end
   end
   alias MpzP = Ptr[Mpz]
   cfun init = __gmpz_init(x : MpzP)
   cfun init_set_si = __gmpz_init_set_si(rop : Ptr[Mpz], op : Long)
   cfun init_set_str = __gmpz_init_set_str(rop : MpzP, str : Ptr[UInt8], base : Int)
   cfun get_si = __gmpz_get_si(op : MpzP) : Long
   cfun get_str = __gmpz_get_str(str : Ptr[UInt8], base : Int, op : MpzP) : Ptr[UInt8]
   cfun add = __gmpz_add(rop : MpzP, op1 : MpzP, op2 : MpzP)
   cfun set_memory_functions = __gmp_set_memory_functions(malloc : (SizeT ) -> Ptr[Void], realloc : (Ptr[Void], SizeT, SizeT ) -> Ptr[Void], free : (Ptr[Void], SizeT ) -> Void)
end
MyLibGmp.set_memory_functions((size) -> 
   GC.malloc(size)
, (ptr, old_size, new_size) -> 
   GC.realloc(ptr, new_size)
, (ptr, size) -> 
   GC.free(ptr)

)
add_as_big_ints(a, b) ->
   bigv1 'MyLibGmp.Mpz
   MyLibGmp.init(out bigret)
   if a.of?(Str)
      MyLibGmp.init_set_str(pointerof(bigv1), a, 10_i64)
   else
      MyLibGmp.init_set_si(pointerof(bigv1), a)
   end
   if b.of?(Str)
      MyLibGmp.init_set_str(out bigv2, b, 10_i64)
   else
      MyLibGmp.init_set_si(pointerof(bigv2), b)
   end
   MyLibGmp.add(pointerof(bigret), pointerof(bigv1), pointerof(bigv2))
   result = Str.new(MyLibGmp.get_str(nil, 10_i64, pointerof(bigret)))
   say("bigint add result: {result}")

pp(MyLibGmp.TEST_CONST)
add_as_big_ints(42_i64, 47_i64)
add_as_big_ints("42", "47")
add_as_big_ints("42", 47_i64)
add_as_big_ints("42543453146456243561345431543513451345245643256257798063244", "47098098432409798761098750982709854959543145346542564256245")
pp(CrystalModule)
pp(CrystalModule.ROOT_CONST)
pp(CrystalModule.CrystalClass)
pp(CrystalModule.CrystalClass.CLASS_ROOT_CONST)
pp(CrystalModule.self_def)
pp(CrystalModule.CrystalClass.class_func)
pp(CrystalModule2)
pp(CrystalModule2.ROOT_CONST)
pp(CrystalModule2.CrystalClass)
pp(CrystalModule2.CrystalClass.CLASS_ROOT_CONST)
pp(CrystalModule2.self_def)
pp(CrystalModule2.CrystalClass.class_func)
pp(CrystalModule2.root_def)
module AllTheRest
   type RestFoo
      rest_foo() ->
         true
      
   end
   xx = 47_i64
   yy = 47.47
   say("{"foo".magenta}, {"bar".grey}, {"qwo".white}")
   say("{"foo".magenta2}, {"bar".grey2}, {"qwo".white}")
   say("All DOWN ".red)
   say("         AND OUT".red2)
end

