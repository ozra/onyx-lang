
# require "slice" - *TODO* should probably be named "View". Sleep on it. A Few times
require "range"
require "char/reader"
require "string"
require "symbol"
require "enum"
require "static_array"
require "array"
require "hash"
require "set"
require "tuple"
# require "box"

alias List = Array
# alias Seq = Array

alias Tup = Tuple
alias Map = Hash
alias Arr = StaticArray  # This is not _really_ the fixed array we want.. Hmm, the val/ref disconnection from type!

alias Tag = Symbol

alias Str = String

