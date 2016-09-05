
type Any = Object 'official-name
type Kind = Class 'official-name

type Tag = Symbol 'official-name
type Ptr = Pointer

type List = Array 'official-name
type Li = List

type Tup = Tuple

type TaggedTuple = NamedTuple  'official-name
type TTup = NamedTuple

type Map = Hash 'official-name

type Fn = Proc 'official-name

type Str = String

-- This defeats the possibility of the "standard int" pragma. Consider allowing
-- the pragma even though it's defined as "platform int". Iff we define it as
-- "pointer width int" on the other hand - which would be more reasonable - it
-- should not be redefinable.
--
ifdef x86_64
   type Intp = Int64
   type Real = Float64

else
   type Intp = Int32
   type Real = Float64
end


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- (idfr =~ /[A-Z]\d{1,3}/) is now reserved for type parameters/vars only.
--
-- type I8 = Int8 'official-name
-- type I16 = Int16 'official-name
-- type I32 = Int32 'official-name
-- type I64 = Int64 'official-name

-- type U8 = UInt8 'official-name
-- type U16 = UInt16 'official-name
-- type U32 = UInt32 'official-name
-- type U64 = UInt64 'official-name

-- type F32 = Float32 'official-name
-- type F64 = Float64 'official-name
