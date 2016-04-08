require "number"
require "int"
require "float"
require "pointer"


ifdef x86_64
   type Krax1 = I64
   type StdInt     = I64
   type ArchInt    = I64

   type StdUInt    = U64
   type ArchUInt   = U64

   type StdReal    = F64
else
   type Krax2 = I32
   type StdInt     = I32
   type ArchInt    = I32

   type StdUInt    = U32
   type ArchUInt   = U32

   type StdReal    = F64
end

-- type Nat         = StdInt    # *TODO* Nat needs changes to methods. It's supposed to be positive only, and shifts etc. will be done with unsigned version
-- type Pos         = StdInt
-- type Offs        = StdInt
-- type Size        = StdInt
-- type Index       = StdInt
type FastInt      = StdInt
type CompactInt   = I32


type Str          = String
