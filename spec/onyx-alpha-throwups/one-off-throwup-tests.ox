
_debug_compiler_start_ = true


vx = 2; vy = 3
a = 1
b = 3
c = 2
that = "That"


good-ole-set = {47, "Hey", 3}

say typeof(good-ole-set)
say good-ole-set.class


pp 1 < 2 < 4


-- tup1 = [47, 13, "yo",]
-- tup2 = [#exacto, that,]
-- tup3 = [that,]
-- tup4 = [,]

-- tup5 = [
--    "ml"
--    "tup", "are"
--    "also", "ok", 5,
--    that
--    "as"
--    7, "sual"
-- ,]

-- tup6 = [true, a < b > c, false,]

-- do-tup(x) -> say "Tuppelainen: {x}"

-- do-tup [1, 2,]
-- do-tup[(1, 2,])
-- if do-tup [1,] => say "tup tup yeay"
-- bzz = do-tup [that,] if true
-- fdf = 5 < 7 < 23 && vx > + vy

-- x = a < b > c


-- tup1 = (47, 13, "yo",)
-- tup2 = (#exacto, that,)
-- tup3 = (that,)
-- tup4 = (,)

-- tup5 = (
--    "ml"
--    "tup", "are"
--    "also", "ok", 5,
--    that
--    "as"
--    7, "sual"
-- ,)

-- tup6 = (true, a < b > c, false,)

-- do-tup(x) -> say "Tuppelainen: {x}"

-- do-tup (1, 2,)
-- do-tup((1, 2,))
-- if do-tup (1,) => say "tup tup yeay"
-- bzz = do-tup (that,) if true
-- fdf = 5 < 7 < 23 && vx > + vy

-- x = a < b > c


do-tup(x Tup) -> x

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

tup6 = do-tup <
   "ml"
   "tup", "are"
   "also", "ok", 5,
   that
   "as"
   7, "sual"
>

tup7 = <a < b, b > c>
tup8 = <true, a < b > c, false>


do-tup <1, 2>
do-tup(<1, 2>)

if do-tup <1> => say "tup tup yeay"

bzz = do-tup <that> if true
fdf = 5 < 7 < 23 && vx > + vy

x = a < b > c

say tup1
say tup2
say tup3
say tup4
say tup5
say tup6
say tup7
say tup8

