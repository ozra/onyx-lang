
-- Test all possible constructs in one go
say "\n\nBefore requires!\n\n"

require "./crystal-scopes"
require "wild_colors"

'!literal-int = I64


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -


_debug_compiler_start_ = true

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

say "\nLet's ROCK\n".red


list = ["foo", "yaa", "qwö"]


list.each–with–index ~>
   p _1
   break if _2 == 4


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
say "{ "foo".magenta }, { "bar".grey }, { "qwo".white }"
say "{ "foo".magenta2 }, { "bar".grey2 }, { "qwo".white }"
say "All DOWN ".red
say "         AND OUT".red2
