
alias Str = String
alias I32 = Int32
-- type Str = String    -- alias
-- type I32 = Int32
-- type UStr < String   -- "unique" (inherited)
-- type UI32 < Int32

-- first comment
a = 47  --another comment
char = c"a"
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

def zoo(a, b, c I32) Str ->
    qwo = Str.new(a + b) + c.to_s
    (a + b).to_s + c.to_s + qwo
end

reg-ex = /foo ya/i
"fda".match reg-ex

\ foo(a, b, c Str) ->
    Str.new(a + b) + c.to_s
end

x = foo a, 2, 3

\ qwo(a I32, b ~I32) ->
end

def qwo2(a 'I32, b I32~) ->
end

def qwo3(a I32, b mut I32) -> Str
end

def qwo4(a I32; b I32 mut) ->
end

-- a = (a) -> a.to_s
-- b = (a Str) -> a
-- c = (a, b Str, c) -> a.to_s + b + c.to_s

-- def booze1(f1 Fn<I32, *, Nil>, f2 Fn<Str, Nil>) ->
-- end

-- def booze2(f1 (I32, *) -> Nil; f2 (Str) -> Nil) ->
-- end

-- def booze3(f1 (I32, * -> Nil); f2 (Str -> Nil)) ->
-- end

-- def booze4(f1 I32,*->Nil; f2 Str->Nil) ->    -- the "open" crystal style (ambiguities)
-- end


-- a-closure-lambda1 = \[&i,v](a, b) -> do-shit(a, b, @i, @v)

-- a-closure-lambda2 = \([&i,v]; a, b) -> do-shit(a, b, @i, @v)

-- a-closure-lambda3 = \{&i,v}(a, b) -> do-shit(a, b, @i, @v)


-- \ bar() ->
--     foo 47, 42, 13
-- end
