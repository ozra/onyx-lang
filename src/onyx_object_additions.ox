require "object"

ext Object: !~~(other) -> !(this ~~ other)
ext Object: !~(other) -> !(this ~~ other)


-- Bool comparison additions

ext Object: ~~(other Bool) -> other is true

-- to Nil - move
ext Nil: ~~(other Bool) -> other is false

-- to Bool itself - move
ext Bool: ~~(other Bool) -> other == this

