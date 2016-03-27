
_debug_compiler_start_ = true


speak(me Int|Str|F64, a) -> say "got: {me} of {me.class} with {a}"
type Any: speak(a) -> speak self, a

speak "Steak", "sauce"
"Burger".speak "sauce"
47.speak "world peace"
3.12.speak "seeming lack of 0.02"
-- [1,2].speak  -- will barf as expected!

