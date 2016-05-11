
_debug_compiler_start_ = 1

type Ohm
   init(@value Real) ->
   to-s() -> "{@value}Ω"


-- *TODO* suffix specific syntax - doesn't get prettier :-/ the important thing
-- we want to get at is additional checks for non-ok suffix-identifiers
-- (clashing with number literal syntax: e3, e-1, etc...)

suffix (val IntLiteral) =
   {=val=}_int

suffix (val RealLiteral) =
   {=val=}_real

suffix (val)g1 =
   {= val =}_real

suffix (val NumberLiteral)g2 =
   {= val =}_real

suffix (val IntLiteral)g3 =
   {=val=}_real

suffix (val RealLiteral)g4 =
   {=val=}_real



suffix (val)g =
    -- *TODO* val.id fucks up because `to_macro_id` doesn't have target-language as
    -- param and thus acts on either specific-node.to_s or abstract-node.to_s(:auto)
   {=val=}_real

suffix (val)kg =
   {=val=}g * 1000_real

suffix (val)Ω =
   Ohm {=val=}_real


-- is (foo = Foo.new).@value legal crystal code!!??



-- template _suffix-number--g(val) =
--     -- *TODO* val.id fucks up because `to_macro_id` doesn't have target-language as
--     -- param and thus acts on either specific-node.to_s or abstract-node.to_s(:auto)
--    {=val=}_real

-- template _suffix-number--kg(val) =
--    {=val=}g * 1000_real

-- template _suffix-number--Ω(val) =
--    Ohm {=val=}_real



say "create code via inline macro expr"

{% for x in ["a", "b", "c"] %}
   say "macroed {=x.id=} + " + {=x=}
{% end %}

say "Try each suffix, no crystal macro surrounds"
9g
0.47g
0.47kg
0.47Ω

say "Try each suffix, crystal macro wrapped"
pp 11g
pp 0.47g
pp 0.47kg
pp 0.47Ω

say "First run through, no crystal macro surrounds"

a1 = 1
a2 = 1i8
a3 = 1_i8
a4 = 1.to-s
a5 = 1kg
a6 = 1_kg

typeof(a1)
typeof(1)

b1 = 0
b2 = 0i8
b3 = 0_i8
b4 = 0.to-s
b5 = 0kg
b6 = 0_kg

d1 = 0x0
d2 = 0x0i8
d3 = 0x0_i8
d4 = 0x0.to-s
-- d5 = 0x0kg
-- d6 = 0x0_kg

e1 = 0xff
e2 = 0xffu8
e3 = 0xff_u8
e4 = 0xff.to-s
-- e5 = 0xffkg
-- e6 = 0xff_kg

f = 1.0
g = 1e+1
h = 1e-1
i = 1.13e+1
j = 1.to-s
k = 1kg
l = 1.3kg
m = 0o1345

-- *TODO* these are not realistic exponent uses!
o1 = 0e+1
o2 = 0e+1f32

p1 = 0e-1
p2 = 0e-1f32


say "Once again, going through Crystal-macro:"

pp a1 = 1
pp a2 = 1i8
pp a3 = 1_i8
pp a4 = 1.to-s
pp a5 = 1kg
pp a6 = 1_kg

pp typeof(a1)
pp typeof(1)

pp b1 = 0
pp b2 = 0i8
pp b3 = 0_i8
pp b4 = 0.to-s
pp b5 = 0kg
pp b6 = 0_kg

pp d1 = 0x0
pp d2 = 0x0i8
pp d3 = 0x0_i8
pp d4 = 0x0.to-s
-- d5 = 0x0kg
-- d6 = 0x0_kg

pp e1 = 0xff
pp e2 = 0xffu8
pp e3 = 0xff_u8
pp e4 = 0xff.to-s
-- e5 = 0xffkg
-- e6 = 0xff_kg

pp f = 1.0
pp g = 1e+1
pp h = 1e-1
pp i = 1.13e+1
pp j = 1.to-s
pp k = 1kg
pp l = 1.3kg
pp m = 0o1345

pp o1 = 0e+1
pp o2 = 0e+1f32

pp p1 = 0e-1
pp p2 = 0e-1f32


say "Non user-suffix test:"

template fooo() =
    %f = {% if true %}
        47
    {% end %}
    %s = "a string with a %s in { %f } it"

say fooo

say "Should fail for various reasons:"
-- f-a = 0b012
-- f-b = 0o1234823
-- f-e = 123-kg
-- f-f = 123–kg
-- pp f-e = 123-kg
-- pp f-f = 123–kg

-- *TODO* this should be caught earlier!
-- f-c = 0xffi8
-- f-d = 0xff_i8

