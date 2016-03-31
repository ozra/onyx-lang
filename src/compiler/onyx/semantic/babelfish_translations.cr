
macro babel_type(given, foreign, block_it = true)
  $babelfish_type_dict["{{given.id}}"] = "{{foreign.id}}"
  {% if block_it %}
    $babelfish_type_dict["{{foreign.id}}"] = "{{foreign.id}}__auto_babeled_"
  {% end %}
end

macro babel_func(given, foreign, block_it = true)
  $babelfish_func_dict["{{given.id}}"] = "{{foreign.id}}"
  {% if block_it %}
    $babelfish_func_dict["{{foreign.id}}"] = "{{foreign.id}}__auto_babeled_"
  {% end %}
end

# macro babel_op(given, foreign, block_it = true)
#   $babelfish_op_dict[{{given.id}}] = {{foreign.id}}
#   # {% if block_it %}
#   #   $babelfish_op_dict[{{foreign}}] = {{foreign}}__auto_babeled_
#   # {% end %}
# end

$babelfish_type_dict = Hash(String, String).new
$babelfish_func_dict = Hash(String, String).new
# $babelfish_op_dict = Hash(Symbol, Symbol).new

# *TODO* one for each - OR - simply flag renames, so they can be reversed! Yes.
$babelfish_reverse_dict = Hash(String, String).new


babel_type Any,    Object

babel_type AnyInt, Int,         false

babel_type Int,    StdInt,      false
babel_type Real,   StdReal,     false

babel_type Tag,    Symbol
babel_type Ptr,    Pointer,     true

# babel Str,    String, false
babel_type List,   Array
babel_type Tup,    Tuple,       false
babel_type Map,    Hash
babel_type Arr,    StaticArray  # This is not _really_ the fixed array we want.. Hmm, the val/ref disconnection from type!
babel_type Array,  StaticArray  # This is not _really_ the fixed array we want.. Hmm, the val/ref disconnection from type!

babel_type I8,     Int8
babel_type I16,    Int16
babel_type I32,    Int32
babel_type I64,    Int64

babel_type U8,     UInt8
babel_type U16,    UInt16
babel_type U32,    UInt32
babel_type U64,    UInt64

babel_type F32,    Float32
babel_type F64,    Float64

babel_type F32,    Float32
babel_type F64,    Float64


babel_func init,        initialize,         true
# babel_func "of?",       "is_a?",          true
babel_func :"~~",       :"==="

babel_func each,        each_with_index,  false
babel_func each_,       each,             false



$babelfish_type_dict.each do |k, v|
  $babelfish_reverse_dict[v] = k
end

$babelfish_func_dict.each_with_index do |k, v|
  $babelfish_reverse_dict[v] = k
end


STDERR.puts "BABELFISHING".red
STDERR.puts $babelfish_type_dict.to_s
STDERR.puts $babelfish_func_dict.to_s

STDERR.puts "alles reversed:"
STDERR.puts $babelfish_reverse_dict.to_s
