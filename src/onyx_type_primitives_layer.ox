-- require "number"
-- require "int"
-- require "float"
-- require "pointer"


-- ifdef x86_64
--  type Krax1 = I64
--  type StdInt   = I64
--  type ArchInt  = I64

--  type StdUInt  = U64
--  type ArchUInt  = U64

--  type StdReal  = F64
-- else
--  type Krax2 = I32
--  type StdInt   = I32
--  type ArchInt  = I32

--  type StdUInt  = U32
--  type ArchUInt  = U32

--  type StdReal  = F64
-- end

-- -- type Nat     = StdInt  # *TODO* Nat needs changes to methods. It's supposed to be positive only, and shifts etc. will be done with unsigned version
-- -- type Pos     = StdInt
-- -- type Offs    = StdInt
-- -- type Size    = StdInt
-- -- type Index    = StdInt
-- type FastInt   = StdInt
-- type CompactInt  = I32


type Any = Object 'official-name
type Kind = Class 'official-name
-- type Record = Struct
-- type AnyInt = Int

type Ind = StdInt
type Real = StdReal

type Tag = Symbol 'official-name
type Ptr = Pointer

type List = Array 'official-name
type Li = List

type Tup = Tuple

type TaggedTuple = NamedTuple  'official-name
type TTup = NamedTuple

type Map = Hash 'official-name

-- type Lambda = Proc
type Fn = Proc 'official-name

type Str = String

type I8 = Int8 'official-name
type I16 = Int16 'official-name
type I32 = Int32 'official-name
type I64 = Int64 'official-name

type U8 = UInt8 'official-name
type U16 = UInt16 'official-name
type U32 = UInt32 'official-name
type U64 = UInt64 'official-name

type F32 = Float32 'official-name
type F64 = Float64 'official-name
