require "object"

ifdef !disable_ox_libspicing below

-- Try-out of some variations
ext Any: itype() ->        'primitive(#class)
ext Any: i-type() ->       'primitive(#class)
ext Any: inst-type() ->    'primitive(#class)
ext Any: rtype() ->        'primitive(#class)
ext Any: r-type() ->       'primitive(#class)
ext Any: cur-type() ->     'primitive(#class)
ext Any: current-type() -> 'primitive(#class)

ext Any: !~~(other) -> !(this ~~ other)
ext Any: !~(other) -> !(this ~~ other)


-- Bool comparison additions

ext Any: ~~(other Bool) -> other is true

-- to Nil - move
ext Nil: ~~(other Bool) -> other is false

-- to Bool itself - move
ext Bool: ~~(other Bool) -> other == this
