

def say(s) -> puts s

say "Let's ROCK"

DEBUG-SEPARATOR = 47

alias Any = Float64
alias Str = String
alias I32 = Int32
alias F64 = Float64
-- type Str = String    -- alias
-- type I32 = Int32
-- type UStr < String   -- "unique" (inherited)
-- type UI32 < Int32

alias Ptr = Pointer

-- type BoundPtr<T> -- << Value
--     @start-addr      Ptr<T>
--     @addr            Ptr<T>
-- end-type
-- --end


-- first comment
a = 47  --another comment
char = c"a"
say "char: " + char.to_s + " (" + typeof(char).to_s + ")"

--| (NO LONGER) weirdly placed comment


-- \ foo(a, b, c I32) ->
--     Str(a + b) + c.to_s

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
    ) =>
        say "3"

    while i > 0
        i -= 1
        say "3.1" if true
        if true
            say "3.2"
        if true => say "3.3"
        if true do say "3.4"
        if true => say "4 "; say "5"; if true then say "5.1"
        if false => say "NO" else do say "5.2a "; say "5.3a"; if true => say "5.4a"
        if false => else do say "5.2b "; say "5.3b"; if true => say "5.4b"
        if false =>
            -- comment after indent
            if 47 => say "NO"
            -- for i in 0..6 => p i.to_s; say "."
            if 47 => say "NO"
        if true
            -- comment after indent
            if 47 => say "6"
            -- for i in 0..6 => p i.to_s; say "."
            if 47 => say "7"

    end-while -- -while
end
-- if (a == 47
--     && a != 48
-- )
--     say "Yeay 47 == 47"


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

[ab, ac] = [3, 2]
[aa, ab, ac, ad] = [1, ac, ab, 4]
say "should be 3: " + ac.to_s

DEBUG-SEPARATOR

-- -#pure -#private
def zoo(a, b, ...c I32) Str ->  -- #pure#
    if true =>
        i = 1

        if (a == 1 &&
            a != 2
        ) =>
            say "8"

        while i > 0
            i -= 1
            if true => say "9 "; say "10"      -- *TODO* THIS ENDLINE IS NOT PARSED AS END!!!!!
            if false =>
                -- comment after indent
                if 47 => say "NO"
                -- for i in 0..6 => p i.to_s; say "."
                if 47 => say "NO"
            else
                say "11"

            if true
                -- comment after indent
                if 47 => say "12"
                -- for i in 0..6 => p i.to_s; say "."

                if !47 => say "NO" else => say "12"; end; if 1 => say "13"; end;

                if 47 => say "14" else say "NO"; end; if 1 => say "15";

                -- new idea for else syntax when symbolic style:

                -- if !47 => say "nop2" *> say "yup3"; end; if 1 => say "more yup3";
            --end-while -- explicit bug to test errors
        end
        -- end-while -- -while

    end-if


    qwo = "#{(a + b)} #{c.to_s}"
    (a + b).to_s + " " + c.to_s + " == " + qwo
end

p zoo 1, 2, 47, 42

reg-ex = /foo (ya)(.*)/i
m1 = "asdf foo ya fdsa".match reg-ex
m2 = "fda" =~ reg-ex

say "m1 = " + m1.to_s
say "m2 = " + m2.to_s

def foo(a, b, c Str) ->
    (a + b).to_s + c

end


def qwo(a I32, b ~I32) ->
end

def qwo2(a 'I32, b I32~) ->

def qwo3(a I32, b mut I32) Str -> -- Str

def qwo4(a I32; b I32 mut) ->
end

qwo2 1, 2

n = 4747 >> 3
n >>= 1
say "n = " + n.to_s + " from " + 4747.to_s
-- say "n = " + $n + " from " + $4747


-- crystal style 1 `case ref`
case n
when 1, 2
    say "NOP: is 1|2"
when 2
    say "NOP: is 3"
else
    say "16:  " + n.to_s
end

-- crystal style 1 `case`
case
when n == 1
    say "NOP 1"
when n == 47, n == 593
    say "17"
else
    say "NOP " + n.to_s
end

-- crystal style 1B `case ref`
case n
when 1, 2
    say "NOP: is 1|2"
when 2
    say "NOP: is 3"
else
    say "17.1:  " + n.to_s

-- crystal style 1B `case`
case
when n == 1
    say "NOP 1"
when n == 47, n == 593
    say "17.2"
else
    say "NOP " + n.to_s

-- crystal style 2 `case ref`
case n
    when 1, 2
        say "NOP: is 1|2"
    when 2
        say "NOP: is 3"
    else
        say "17.3: " + n.to_s
end

-- crystal style 2 `case`
case
    when n == 1
        say "NOP 1"
    when n == 47, n == 593
        say "17.4"
    else
        say "NOP " + n.to_s
end

-- onyx style 1 `case ref`
case n
    593
        say "18"
    2 =>
        say "NO is 2"
    *
        say "NO " + n.to_s
end

-- onyx style 1 `case`
case
    n == 1
        say "NO is 1"
    n == 593 =>
        if false
        else
            say "19"
    *
        say "NO " + n.to_s
end-case

-- onyx style 2 `case ref`
case n
    593
        say "19.1"
    2 =>
        say "NO is 2"
    *
        say "NO " + n.to_s

-- onyx style 2 `case`
case
    n == 1
        say "NO is 1"
    n == 593 =>
        if false
        else
            say "19.2"
    *
        say "NO " + n.to_s

-- onyx style 3 `case ref`
case n
    1 => say "is 1"
    2 => say "is 2"
    * => if false => say "NO" else say "20: " + n.to_s
end-case

-- onyx style 3 `case`
case
    n == 593    => say "21"
    n == 2      => say "is 2"
    *           => say n.to_s


x = foo a, 2, "3"

a = (a Any, b Any) -> a.to_s; end
b = (a Str, _ I32, b 'Bool; c F64) ->
    "{a} {x}" -- t"{a} {x}"

say "def lambda c"
c = (a ~Int32', b 'Str', c 'Int32~) -> a.to_s + b + c.to_s; end

p b.call "Closured Lambda says", 1, true, 0.47
-- p b("2 Closured Lambda says", 1, true, 0.47)
-- p b "2 Closured Lambda says", 1, true, 0.47
-- Str "47"
-- str "47"

p typeof(b)

class Fn<T1, T2, T3>

def booze1(f1 Fn< I32,Array<*>,Array<Array<Ptr<Int32>>> >, f2 Fn<Str, Nil, Array<Bool>>) ->

say "Array<Array<Ptr<Int32>>>> => " + Array<Array<Ptr<Int32>>>.to_s

def booze2(f1 (I32,auto) -> Nil; f2 (Str) -> Nil) ->
end

def booze3(f1 (I32, * -> Nil); f2 (Str -> Nil)) ->
end


-- -- a-closure-lambda1 = \[&i,v](a, b) -> do-shit(a, b, @i, @v)

-- -- a-closure-lambda2 = \([&i,v]; a, b) -> do-shit(a, b, @i, @v)

-- -- a-closure-lambda3 = \{&i,v}(a, b) -> do-shit(a, b, @i, @v)


-- def bar() ->
--     foo 47, 42, 13
-- end

say "All DOWN AND OUT"
