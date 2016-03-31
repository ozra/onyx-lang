require "object"

type Any: !~~(other) -> !(self ~~ other)
type Any: !~(other) -> !(self ~~ other)


-- Bool comparison additions

type Any: ~~(other Bool) -> other is true

-- to Nil - move
type Nil < value: ~~(other Bool) -> other is false

-- to Bool itself - move
type Bool < value: ~~(other Bool) -> other is self

