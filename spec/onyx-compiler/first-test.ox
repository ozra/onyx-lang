

def say(s) -> puts s

say "Let's ROCK"

DEBUG-SEPARATOR = 47


— alias Any = Float64 — Any just doesn't work having atm - Object disallowed


alias Tag = Symbol
alias Str = String
alias I8  = Int8
alias I16 = Int16
alias I32 = Int32
alias I64 = Int64
alias U8  = UInt8
alias U16 = UInt16
alias U32 = UInt32
alias U64 = UInt64
alias F32 = Float32
alias F64 = Float64
alias Ptr = Pointer

— type Str = String    — alias
— type I32 = Int32
— type UStr < String   — "unique" (inherited)
— type UI32 < Int32

alias SomeInt = Int

ifdef x86_64
    alias StdInt    = I64
    alias StdUInt   = U64
    alias StdReal   = F64
else
    alias StdInt    = I32
    alias StdUInt   = U32
    alias StdReal   = F64
end

alias Nat           = StdUInt     — *TODO* Nat should have changes to methods. It's supposed to be positive only, and shifts etc. will be done with unsigned version
alias Pos           = StdInt
alias Offs          = StdInt
alias Size          = StdInt
alias Index         = StdInt
alias FastInt       = StdInt
alias CompactInt    = I32


— alias Rope = StringBuilder




— type BoundPtr<T> — << Value
—     @start-addr      Ptr<T>
—     @addr            Ptr<T>
— end-type
— —end


— first comment
a = 47  —another comment
char = c"a"
say "char: " + char.to-s + " (" + typeof(char).to-s + ")"

—| (NO LONGER) weirdly placed comment


— \ foo(a, b, c I32) ->
—     Str(a + b) + c.to-s

the-str = "kjhgkjh" \
    "dfghdfhgd"

if (a == 47 &&
    a != 48
)
    say "1"

if (a == 48 - 1 &&
    a != 49
) =>
    say "2"

if true =>
    i = 1

    if (a == 48 - 1 &&
        a != 49
    ):
        say "3"

    while i > 0
        i -= 1
        say "3.1" if true
        if true
            say "3.2"
        if true => say "3.3"
        if true do say "3.4"
        if true => say "4 "; say "5"; if true then say "5.1"
        if false: say "NO" else do say "5.2a "; say "5.3a"; if true: say "5.4a"
        if false : else do say "5.2b "; say "5.3b"; if true => say "5.4b"
        if false =>
            — comment after indent
            if 47 => say "NO"
            — for i in 0..6 => p i.to-s; say "."
            if 47: say "NO"
        if true
            — comment after indent
            if 47 then say "6"
            — for i in 0..6 => p i.to-s; say "."
            if 47 => say "7"

    end-while — -while
end-if
— if (a == 47
—     && a != 48
— )
—     say "Yeay 47 == 47"


— \zoo( \
—     a, \
—     b, \
—     c I32 \
— ) ->
—     Str.new(a + b) + c.to-s
— end

— def ab=(v)
—     @prog-v = v
— end

[ab, ac] = [3, 2]
[aa, ab, ac, ad] = [1, ac, ab, 4]
say "should be 3: " + ac.to-s

DEBUG-SEPARATOR

— -#pure -#private
def zoo(a, b, ...c I32) Str ->  — #pure#
    if true =>
        i = 1

        if (a == 1 &&
            a != 2
        ) =>
            say "8"

        while i > 0
            i -= 1
            if true => say "9 "; say "10"      — *TODO* THIS ENDLINE IS NOT PARSED AS END!!!!!
            if false =>
                — comment after indent
                if 47 => say "NO"
                — for i in 0..6 => p i.to-s; say "."
                if 47 => say "NO"
            else
                say "11"
                for val[ix] in {"c", "b", "a"} by 2
                    p "{{val}}, {{ix}}"

            if true
                — comment after indent
                if 47 => say "12"
                — for i in 0..6 => p i.to-s; say "."

                if !47 => say "NO" else => say "12"; end; if 1 => say "13"; end;

                if 47 => say "14" else say "NO"; end; if 1 => say "15";

                — new idea for else syntax when symbolic style:

                — if !47 => say "nop2" *> say "yup3"; end; if 1 => say "more yup3";
            —end-while — explicit bug to test errors
        end
        — end-while — -while

    end-if


    qwo = "{{(a + b)}} {{c.to-s}}"
    (a + b).to-s + " " + c.to-s + " == " + qwo
end

p zoo 1, 2, 47, 42

reg-ex = /foo (ya)(.*)/i
m1 = "asdf foo ya fdsa".match reg-ex
m2 = "fda" =~ reg-ex

say "m1 = " + m1.to-s
say "m2 = " + m2.to-s

def foo(a, b, c Str) ->
    (a + b).to-s + c

end


def qwo(a I32, b ~I32) ->
end

def qwo2(a 'I32, b I32~) -> end

def qwo3(a I32, b mut I32) Str -> — Str

def qwo4(a I32; b I32 mut) ->
end

qwo2 1, 2

n = 4747 >> 3
n >>= 1
say "n = " + n.to-s + " from " + 4747.to-s
— say "n = " + $n + " from " + $4747


json-hash = {"apa": "Apa", "katt": "Katt", "panter": "Panter"}
say "json-correct-hash: {{json-hash}}"

-- js-hash = {apa: "Apa", katt: "Katt", panter: "Panter"}
-- say "js-hash: {{js-hash}}"

tag-hash = {#apa: "Apa", #katt: "Katt", #panter: "Panter"}
say "tag-hash: {{tag-hash}}"

tag-hash-2 = {
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
say "tag-hash-2: {{typeof(tag-hash-2)}}, {{tag-hash-2}}"


enum TradeSide Int8
    Unknown
    Buy
    Sell


— crystal style 1 `case ref`
case n
when 1, 2
    say "NOP: is 1|2"
when 2
    say "NOP: is 3"
else
    say "16:  " + n.to-s
end

— crystal style 1 `case`
case
when n == 1
    say "NOP 1"
when n == 47, n == 593
    say "17"
else
    say "NOP " + n.to-s
end

— crystal style 1B `case ref`
case n
when 1, 2
    say "NOP: is 1|2"
when 2
    say "NOP: is 3"
else
    say "17.1:  " + n.to-s

— crystal style 1B `case`
case
when n == 1
    say "NOP 1"
when n == 47, n == 593
    say "17.2"
else
    say "NOP " + n.to-s

— crystal style 2 `case ref`
case n
    when 1, 2
        say "NOP: is 1|2"
    when 2
        say "NOP: is 3"
    else
        say "17.3: " + n.to-s
end

— crystal style 2 `case`
case
    when n == 1
        say "NOP 1"
    when n == 47, n == 593
        say "17.4"
    else
        say "NOP " + n.to-s
end

— onyx style 1 `case ref`
match n
    593
        say "18"
    2 =>
        say "NO is 2"
    *
        say "NO " + n.to-s
end

— onyx style 1 `case`
case
    n == 1 =>
        say "NO is 1"
    n == 593 =>
        if false
        else
            say "19"
    * =>
        say "NO " + n.to-s
end-case

— onyx style 2 `case ref`
branch n
    593
        say "19.1"
    2 =>
        say "NO is 2"
    *
        say "NO " + n.to-s

— onyx style 2 `case`
case
    n == 1
        say "NO is 1"
    n == 593 =>
        if false
        else
            say "19.2"
    *
        say "NO " + n.to-s

— onyx style 3 `case ref`
match n
    1 => say "is 1"
    2 => say "is 2"
    * => if false => say "NO" else say "20: " + n.to-s
end-case

— onyx style 3 `case`
branch
    n == 593    => say "21"
    n == 2      => say "is 2"
    *           => say n.to-s

— onyx style 4 `case ref`
case n
    1 do say "is 1"
    2 then say "is 2"
    * do if false then say "NO" else say "22: " + n.to-s

— onyx style 4 `case`
branch
    n == 593    then say "23"
    n == 2      do say "is 2"
    *           then say n.to-s

— onyx style 5 `case ref`
match n
| 593
    say "23.1"
| 2 =>
    say "NO is 2"
| *
    say "NO " + n.to-s

— onyx style 5 `case`
branch
| n == 1
    say "NO is 1"
| n == 593 =>
    if false
    else
        say "23.2"
| *

    say "NO " + n.to-s

— onyx style 6 `case ref`
match n
    1: say "is 1"
    2: say "is 2"
    *: if false => say "NO" else say "20: " + n.to-s
end-case

— onyx style 6 `case`
branch
    n == 593    : say ": 23.3"
    n == 2      : say "is 2"
    *           : say n.to-s

for v[i] in [#apa, #katt]: say ": {{i}}: {{v}}"

if true: say ": true"

x = foo a, 2, "3"

a = (a Int32, b Int32) -> a.to-s; end
b = (a Str, _ I32, b 'Bool; c F64) ->
    "{{a}} {{x}}" — t"{a} {x}"

say "23.4 def lambda c"
c = (a ~Int32', b 'Str', c 'Int32~) -> a.to-s + b + c.to-s

p b.call "23.5 Closured Lambda says", 1, true, 0.47
— p b("2 Closured Lambda says", 1, true, 0.47)
— p b "2 Closured Lambda says", 1, true, 0.47
— Str "47"
— str "47"

p typeof(b)

class Fn[T1, T2, T3]

def booze1(f1 Fn[I32,Array<*>,Array<Array[Ptr<Int32>]>], f2 Fn[Str, Nil, Array<Bool>]) ->

say "Array[Array<Ptr[Int32]>] => " + Array[Array<Ptr[Int32]>].to-s

def booze2(f1 (I32,auto) -> Nil; f2 (Str) -> Nil) ->
end

def booze3(f1 (I32, * -> Nil); f2 (Str -> Nil)) ->
end


— — a-closure-lambda1 = \[&i,v](a, b) -> do-shit(a, b, @i, @v)

— — a-closure-lambda2 = \([&i,v]; a, b) -> do-shit(a, b, @i, @v)

— — a-closure-lambda3 = \{&i,v}(a, b) -> do-shit(a, b, @i, @v)


— def bar() ->
—     foo 47, 42, 13
— end






— *TODO*



— 0. Take care of the ast_dump util - put it in some compiler-dev-utils module



— 1. SOFT LAMBDA <-> LAMBDA <-> BLOCK MAGIC!
—      breaking return  — or
—      outer return



— 2. TYPEDEF PARSING
— - some-var Type = 47   — instance-var type annotation
— - some-var Type        — instance-var type annotation
— - Self.method(asdf..) -> ...
— - Self.new(foo...) -> ...
— - Self.Constant = 47
— - Self.variable I32 = 4747

-- Self == "this type"
-- this == "this instance" — or:
-- me == "this instance" ?

— 3. THE REST HERE
— - t"str {smoother} interpolation {style}"
— - r"reg-exp syntax instead of /fd/"
— - raw"for raw strings"
— - c"X"  (but this probably already works!)

— - bar x, y — semantic lookup of instances of types having .call method

— for: to_s for onyx and crystal must spit out the for-loop
— for: while-loops for the 'stepping' case must be generated




list = [#abra, #baba, #cadabra]

say "the list: {{list}}"

— soft lambdas
-- list.each (v) ->) p v
-- list.each (v) ->} p v
-- list.each (v Tag) ->) p v
-- list.each (v Tag) ->} p v
-- list.each (v) -) p v
-- list.each (v) -} p v

-- list.each_with_index ~>)
--     p _1
--     breaking return if _2 == 4
-- list.each ~>} p _1
-- list.each ~) p _1
-- list.each ~} p _1


for ix: val in list
    say "{{val}}, {{ix}}"

for ix:val in list
    p "{{val}}, {{ix}}"

for ix: in list
    say ix

for val, ix in list
    say "{{val}}, {{ix}}"

for val in list
    say val

for val in list =>
    say val

for ,ix in list
    say ix

for val[ix] in list
    say "{{val}}, {{ix}}"

for [ix] in list
    say ix

for val[ix] in ["c", "b", "a"]
    say "{{val}}, {{ix}}"

for val[ix] in {"c", "b", "a"}
    say "{{val}}, {{ix}}"

for val[ix] in {"c", "b", "a"} by -1
    say "{{val}}, {{ix}}"

for val[ix] in ["c", "b", "a"] by 2
    say "{{val}}, {{ix}}"



type Qwa
end-type

type Bar << Qwa
    @bar ::     I32

say "declare a Foo type"



— *TODO*! Make a specific parse-loop for type declaration - don't use
— "parse_expressions"


type Foo[S1] << Bar
    Self.my-foo = 47

    — static
    — Type
    Self
        some-other-foo = 42

        set-foo(v) -> Self.my-foo = v

        RedFoo = 5
        GreenFoo = 7
    end-Self

    foo-a Str = ""
    foo-b I32 = 0

    say "Hey in Foo"

    init(a S1) ->@
        @foo-a = a

    init() ->@

    fn-1aa(x) ->> nil

    fn-1ba(x) ->>! nil

    fn-1ca(x) ->>!

    -- fn-1ab(x) => nil

    -- fn-1bb(x) =>! nil  - will cause conflicts with generic blockstarts

    -- fn-1cb(x) =>!

    fn-1da(x) -> nil

    fn-1ea(x) ->! nil

    fn-1fa(x) ->!

    fn-1ga(x) ->!
        say "Hey"
        say "you!"

    — *TODO* this errors as it should - however the message position is wrong!
    — fn-1h(x) String ->!
    —     say "Hey"
    —     say "you!"
    —     "fdsa"

    — Errors on instantiation, else is untouched
    — fn-1i(x) ->!
    —     say "Yeay"
    —     return "Foo"

    fn-a(a, b) ->> "a: {{a}}, {{b}}"

    def fn-b(a S1, b I32) -> — fdsa
        "b: {{a}}, {{b}}"

    — -#private
    fn-c(a, b S1) S1 ->> — -#redef -#inline
        "c: {{a}}, {{b}}"

    — private
    — fn-c(a, b I32) redef private ->
    fn-c(a, b I32) -> — redef
        "c: {{a}}, {{b}}"
        — t"c: {a}, {b}"

    fn-d1(a, b) ->
        @foo-a = a
        @foo-b = b
        fn-e
    end

    fn-d2(a S1, b I32) ->
        @foo-a = a
        @foo-b = b
        fn-e

    — fn-d3(a S1, b <IntT>) ->
    —     @foo-a = a
    —     c IntT
    —     c = b
    —     @foo-b = c
    —     fn-e

    fn-e() -> fa = @foo-a ; "e: {{fa}}, {{@foo_b}}"

    call() -> fn-e

end-type

say "create a Foo instance"
foo = Foo<Str>()
say "done"
say foo.fn-a "24 blargh", 47
say foo.fn-b "25 blargh", 47
say foo.fn-c "26 blargh", 47
say foo.fn-d1 "27 blargh", 47
foo.fn-d2 "28 blargh", 47
say foo.fn-e

bar = Foo<Str>("No Blargh")
bar = Foo("No Blargh")
bar = Foo "No Blargh"
bar = Foo<Str> "29 Blargh"
say "done"
say bar.fn-e
bar.fn-d2 "30 blargh", 47
say bar.fn-e

— say bar()    — needs to be done in semantics - need to see if bar has 'call' method!
                — if so - rewrite to `bar.call()`
say typeof(foo)

say "All DOWN AND OUT"
