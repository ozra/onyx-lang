
_debug_compiler_start_=1


-- NEW TUPLE SYNTAX

pp 1 < 2 < 4

that = "That"
tup1 = <47, 13, "yo">
tup2 = <#exacto, that>
tup3 = <that>
tup4 = <>
tup5 = <
   "ml"
   "tup", "are"
   "also", "ok", 5,
   that
   "as"
   7, "sual"
>

do-tup(x) -> say "Tuppelainen: {x}"

do-tup <1, 2>
if do-tup < 1 > => say "tup tup yeay"
bzz = do-tup < that > if true
vx = 2; vy = 3
fdf = 5 < 7 < 23 && vx > vy






-- require "compiler"


-- *todo* - parse the compiler, then again, compared to cloning previous ast - benchmark!
-- p = Parser()

-- p =