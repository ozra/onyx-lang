-- fib_improver = ->(partial : Proc(Int32)) {
--     ->(n : Int32) { n < 2 ? n : partial.call(n-1) + partial.call(n-2) }
-- }

-- y = ->(f : Int32) {
--     ->(x) { x.call(x) }.call(
--           ->(x) { f.call(->(v) { x.call(x).call(v)}) }
--             )
-- }

-- fib = fib_improver.call(y.call(fib_improver))

-- p fib.call(1)
-- p fib.call(100)


-- *TODO* I'm confuzed by above B-)


fib_improver = (partial (Int32)->Int32) ->
    (n Int32) -> n < 2 ? n : partial.call(n-1) + partial.call(n-2)

y = (f (Int32)->Int32) ->
    ((x) -> x.call(x)).call(
        (x) -> f.call((v) -> x.call(x).call(v))
    )

fib = fib_improver.call(y.call(fib_improver))

p fib.call(1)
p fib.call(100)