
puts "Let's ROCK"

DBG–SPACE = 47

alias Ptr = Pointer
alias Any = Bool
alias Str = String
alias I32 = Int32
alias F64 = Float64
-- type Str = String    -- alias
-- type I32 = Int32
-- type UStr < String   -- "unique" (inherited)
-- type UI32 < Int32

-- first comment
a = 47  --another comment
char = c"a"
p "char: " + char.to_s + " (" + typeof(char).to_s + ")"
    --| weirdly placed comment

-- \ foo(a, b, c I32) ->
--     Str(a + b) + c.to_s

the-str = "kjhgkjh" \
    "dfghdfhgd"

-- \zoo( \
--     a, \
--     b, \
--     c I32 \
-- ) ->
--     Str.new(a + b) + c.to_s
-- end

-- def ab=(v)
--     @prog-v = v
-- end

[aa, ab, ac, ad] = [1, 2, 3, 4]
p "should be 3: " + ac.to_s

DBG–SPACE

-- #pure#
def zoo(a, b, c I32) Str ->  -- #pure#
    qwo = Str.new(a + b) + c.to_s
    (a + b).to_s + c.to_s + qwo
end

reg-ex = /foo (ya)(.*)/i
m1 = ("asdf foo ya fdsa".match reg-ex)
m2 = ("fda" =~ reg-ex)

p "m1 = " + m1.to_s
p "m2 = " + m2.to_s

def foo(a, b, c Str) ->
    (a + b).to_s + c
end

def qwo(a I32, b ~I32) ->
end

def qwo2(a 'I32, b I32~) ->
end

def qwo3(a I32, b mut I32) -> Str
end

def qwo4(a I32; b I32 mut) ->
end

n = 4747 >> 3
n >>= 1
p "n = " + n.to_s

x = foo a, 2, "3"

a = (a Any, b Any) -> a.to_s; end
b = (a Str, _ I32, b 'Bool; c F64) -> a + " " + x; end
p "def lambda c"
c = (a ~Int32', b 'Str', c 'Int32~) -> a.to_s + b + c.to_s; end

p b.call "Closured Lambda says", 1, true, 0.47


class Fn<T1, T2, T3>
end

def booze1(f1 Fn< I32,Array<*>,Array<Array<Ptr<Int32>>> >, f2 Fn<Str, Nil, Array<Bool>>) ->
end

p "Array<Array<Ptr<Int32>>>> => " + Array<Array<Ptr<Int32>>>.to_s

def booze2(f1 (I32,auto) -> Nil; f2 (Str) -> Nil) ->
end

def booze3(f1 (I32, * -> Nil); f2 (Str -> Nil)) ->
end


-- a-closure-lambda1 = \[&i,v](a, b) -> do-shit(a, b, @i, @v)

-- a-closure-lambda2 = \([&i,v]; a, b) -> do-shit(a, b, @i, @v)

-- a-closure-lambda3 = \{&i,v}(a, b) -> do-shit(a, b, @i, @v)


def bar() ->
    foo 47, 42, 13
end

puts "All DOWN AND OUT"
