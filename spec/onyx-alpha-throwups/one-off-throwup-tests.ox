
_debug_compiler_start_ = true


type Any: qwö(x) -> say "Any.qwö: {x}"

type Gimp < value
   foo-bar() -> 1

module Zork
   type Gimp < value
      foo-bar() -> 2

   module Qwaza
      type Gimp < value
         foo-bar() -> 3

      type Int < value
         @val $.Int
         foo-bar() -> 4
         init(v) -> @val = $.Int v

      type $.Int < value
         foo-bar() -> 97


type AnyInt < value
   foo-bar() -> 49

-- type Int < value
--    foo-bar() -> 95

type PzzInt = I32
type PzzInt < value
   -- init(x) ->
   foo-bar() -> 6

a = Gimp()
b = Zork.Gimp()
c = Zork.Qwaza.Gimp()
d = PzzInt 1

i32 = I32 4
iarch = ArchInt 4
istd = StdInt 4

i = Int 5
i2 = Zork.Qwaza.Int 9

say a.foo-bar, a.qwö 1
say b.foo-bar, b.qwö 2
say c.foo-bar, c.qwö 3
say d.foo-bar, d.qwö 4
say i.foo-bar, i.qwö 5
say i2.foo-bar, i2.qwö 6

say i.class, i
say i2.class, i2

zarx(x Zork.Qwaza.Int) -> say "got {x}"
barx(x Int) -> say "got {x}"
foox(x AnyInt) -> say "got {x}"

barx Int 1
foox 23
foox 47u8
-- foox "hey"

type BoogleGoo
