require "object"

ifdef !disable_ox_libspicing below

ext Any: !~~(other) -> !(this ~~ other)
ext Any: !~(other) -> !(this ~~ other)


-- Bool comparison additions

ext Any: ~~(other Bool) -> other is true

-- to Nil - move
ext Nil: ~~(other Bool) -> other is false

-- to Bool itself - move
ext Bool: ~~(other Bool) -> other == this
