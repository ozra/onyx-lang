

ifdef !dont_reform_types
   -- -- _replacing babeling_ by staying on Onyx naming ball court side -- --
   ifdef typicide

      -- Crystal compatibility aliases:

      type Object = Any
      type Class = Kind
      type Symbol = Tag
      type Pointer = Ptr
      type Array = List
      type NamedTuple = TTup
      type Hash = Map
      type Proc = Fn

      -- Full name alias for String
      type String = Str

      -- Full name alias for Tup
      type Tuple = Tup

      -- Short alias that is natural to use in everyday code
      type Li = List
      -- type Li<T> = List<T>

      -- Full name alias for TTup
      type TaggedTuple = TTup
      -- type TaggedTuple<..:T> = TTup<..:T>

   -- -- The pre babeling way, staying on Crystal naming ball court side -- --
   else
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
   end
end
-- {% end %}


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- This defeats the possibility of the "standard int" pragma. Consider allowing
-- the pragma even though it's defined as "platform int". Iff we define it as
-- "pointer width int" on the other hand - which would be more reasonable - it
-- should not be redefinable.
ifdef x86_64
   type Intp = Int64
   type Real = Float64

else
   type Intp = Int32
   type Real = Float64
end


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Note: (idfr =~ /[A-Z]\d{1,3}/) is now reserved for type parameters/vars only.
-- Will change.
-- Reconsider!
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
