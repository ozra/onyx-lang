require "object"

type Object: !~~(other) -> !(self ~~ other)
type Object: !~(other) -> !(self ~~ other)


-- Bool comparison additions

type Object: ~~(other Bool) -> other is true

-- to Nil - move
type Nil < value: ~~(other Bool) -> other is false

-- to Bool itself - move
type Bool < value: ~~(other Bool) -> other is self

