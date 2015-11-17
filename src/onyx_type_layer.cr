require "object"
# require "reference"
# require "value"
# require "struct"
# require "proc"
# require "thread"
# require "class"
# require "nil"
# require "bool"
# require "char"
require "number"
require "int"
require "float"
require "pointer"
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


alias Any = Object

alias Seq = Array
alias Tup = Tuple
alias Map = Hash
alias Arr = StaticArray  # This is not _really_ the fixed array we want.. Hmm, the val/ref disconnection from type!

alias Tag = Symbol

alias Str = String

alias I8  = Int8
alias I16 = Int16
alias I32 = Int32
alias I64 = Int64

alias U8  = UInt8
alias U16 = UInt16
alias U32 = UInt32
alias U64 = UInt64

alias F32 = Float32
alias F64 = Float64

alias Ptr = Pointer

alias SomeInt = Int

ifdef x86_64
   alias StdInt     = I64
   alias ArchInt    = I64
   alias StdUInt    = U64
   alias ArchUInt   = U64
   alias StdReal    = F64
else
   alias StdInt     = I32
   alias ArchInt    = I32
   alias StdUInt    = U32
   alias ArchUInt   = U32
   alias StdReal    = F64
end

# alias Nat         = StdInt    # *TODO* Nat needs changes to methods. It's supposed to be positive only, and shifts etc. will be done with unsigned version
# alias Pos         = StdInt
# alias Offs        = StdInt
# alias Size        = StdInt
# alias Index       = StdInt
alias FastInt      = StdInt
alias CompactInt   = I32
