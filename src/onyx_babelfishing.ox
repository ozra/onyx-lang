
'!babelfish Any     => Object
'!babelfish AnInt   => Int

'!babelfish Int     => StdInt
type        Real    =  StdReal
'!babelfish Tag     => Symbol
'!babelfish Ptr     => Pointer

'!babelfish Str     => String
'!babelfish List    => Array
'!babelfish Tup     => Tuple
'!babelfish Map     => Hash
'!babelfish Arr     => StaticArray  -- This is not _really_ the fixed array we want.. Hmm, the val/ref disconnection from type!




-- Machine Level Types

'!babelfish I8      => Int8
'!babelfish I16     => Int16
'!babelfish I32     => Int32
'!babelfish I64     => Int64

'!babelfish U8      => UInt8
'!babelfish U16     => UInt16
'!babelfish U32     => UInt32
'!babelfish U64     => UInt64

'!babelfish F32     => Float32
'!babelfish F64     => Float64
