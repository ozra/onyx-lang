require "object"

ext Any: !~~(other) -> !(self ~~ other)
ext Any: !~(other) -> !(self ~~ other)


-- Bool comparison additions

ext Any: ~~(other Bool) -> other is true

-- to Nil - move
ext Nil: ~~(other Bool) -> other is false

-- to Bool itself - move
ext Bool: ~~(other Bool) -> other is self

