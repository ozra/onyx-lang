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

-- Some variations for "not-nil else throw" for try-out
ext Any: must!() -> this
ext Any: is!() ->   this
ext Any: its!() ->  this

ifdef release
 -- Raises an exception. See `Any#must!`.
   ext Nil: must!() -> raise "Run-time Nil assertion failed"
   ext Nil: is!() ->   raise "Run-time Nil assertion failed"
   ext Nil: its!() ->  raise "Run-time Nil assertion failed"
else
 -- :nodoc: Raises an exception implicitly grabbing (file, line) params added
 -- for *DEBUG* TEMP* *TODO* until traces are human friendlier
   ext Nil: must!(file = __FILE__, line = __LINE__) ->
      raise "Run-time Nil assertion failed at {file}:{line}"

   ext Nil: is!(file = __FILE__, line = __LINE__) ->
      raise "Run-time Nil assertion failed at {file}:{line}"

   ext Nil: its!(file = __FILE__, line = __LINE__) ->
      raise "Run-time Nil assertion failed at {file}:{line}"
end

ext Any: !~~(other) -> !(this ~~ other)
ext Any: !~(other) -> !(this ~~ other)


-- Bool comparison additions

ext Any: ~~(other Bool) -> other is true

-- to Nil - move
ext Nil: ~~(other Bool) -> other is false

-- to Bool itself - move
ext Bool: ~~(other Bool) -> other == this
