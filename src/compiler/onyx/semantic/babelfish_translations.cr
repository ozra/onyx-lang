
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

$babelfish_type_dict = Hash(String, String).new
$babelfish_func_dict = Hash(String, String).new

# *TODO* one for each - OR - simply flag renames, so they can be reversed! Yes.
$babelfish_reverse_dict = Hash(String, String).new


babel_type Any,    Object,      true

babel_type AnyInt, CrystalInt,  true

babel_type Int,    StdInt,      false
babel_type Real,   StdReal,     false

babel_type Tag,    Symbol,      true
babel_type Ptr,    Pointer,     true

# babel Str,    String, false
babel_type List,   Array,       true
babel_type Tup,    Tuple,       false

babel_type Map,    Hash,        true  # *TODO* Map should be a generic _interface_ choice which uses Hash by default.

babel_type Arr,    StaticArray, true  # This is not _really_ the fixed array we want.. Hmm, the val/ref disconnection from type!
babel_type Array,  StaticArray, true  # This is not _really_ the fixed array we want.. Hmm, the val/ref disconnection from type!

babel_type I8,     Int8,        true
babel_type I16,    Int16,       true
babel_type I32,    Int32,       true
babel_type I64,    Int64,       true

babel_type U8,     UInt8,       true
babel_type U16,    UInt16,      true
babel_type U32,    UInt32,      true
babel_type U64,    UInt64,      true

babel_type F32,    Float32,     true
babel_type F64,    Float64,     true


babel_func init,        initialize,         true

babel_func :"~~",       :"==="

babel_func each,        each_with_index,  false
babel_func each_,       each,             false



$babelfish_type_dict.each do |k, v|
  $babelfish_reverse_dict[v] = k
end

$babelfish_func_dict.each_with_index do |k, v|
  $babelfish_reverse_dict[v] = k
end


# STDERR.puts "BABELFISHING".red
# STDERR.puts $babelfish_type_dict.to_s
# STDERR.puts $babelfish_func_dict.to_s

# STDERR.puts "alles reversed:"
# STDERR.puts $babelfish_reverse_dict.to_s








# require "../../crystal/semantic/ast"
include Crystal

def babelfish_taint(name : String) : String
  name + "__X_"
end

def babelfish_detaint(name : String) : String
  # _dbg "- babelfish_detaint - '#{name}"
  if name.ends_with? "__X_"
    name[0..-5]
  else
    name
  end
end

def babelfish_mangling(node : ASTNode, scope) : ASTNode

  # msg = "babelfish_mangling(ASTNode) -> for node.class = #{node} not implemented."
  # _dbg "*TODO*".red
  # _dbg msg.cyan
  # _dbg "*TODO*".yellow

  # # raise msg

  node
end

def babelfish_mangling(node : NumberLiteral, scope) : NumberLiteral; node; end
def babelfish_mangling(node : Nil, scope) : Nil; node; end
def babelfish_mangling(node : Self, scope) : Self; node; end
def babelfish_mangling(node : Underscore, scope) : Underscore; node; end
def babelfish_mangling(node : Metaclass, scope) : Metaclass; node; end

def babelfish_mangling(node : TypeDeclaration, scope) : TypeDeclaration
  # _dbg "babelfish_mangling(#{node.class}: #{node}, #{scope}) ->"
  node.declared_type = babelfish_mangling node.declared_type, scope
  node
end

def babelfish_mangling(node : Union, scope) : Union
  # _dbg "babelfish_mangling(#{node.class}: #{node}, #{scope}) ->"
  node.types.each { |typ| babelfish_mangling typ, scope }
  node
end

def babelfish_mangling(node : Fun, scope) : Fun
  # _dbg "babelfish_mangling(#{node.class}: #{node}, #{scope}) ->"
  node.inputs.try &.each { |inp| babelfish_mangling inp, scope }
  babelfish_mangling node.output, scope
  node
end

def babelfish_mangling(node : ClassDef, scope) : ClassDef
  # _dbg "babelfish_mangling(#{node.class}: #{node}, #{scope}) ->"
  node.name = babelfish_mangling node.name, scope
  (t = node.type_vars) && t.each_with_index {|tvar, ix| _, t[ix] = babelfish_mangling_raw true, node.is_onyx, tvar, scope }
  node
end

def babelfish_mangling(node : ModuleDef, scope) : ModuleDef
  # _dbg "babelfish_mangling(#{node.class}: #{node}, #{scope}) ->"
  node.name = babelfish_mangling node.name, scope
  (t = node.type_vars) && t.each_with_index {|tvar, ix| _, t[ix] = babelfish_mangling_raw true, node.is_onyx, tvar, scope }
  node
end

def babelfish_mangling(node : Generic, scope) : Generic
  # _dbg "babelfish_mangling(#{node.class}: #{node}, #{scope}) ->"
  node.name = babelfish_mangling node.name, scope
  node.type_vars.each_with_index {|tvar, ix| node.type_vars[ix] = babelfish_mangling tvar, scope }
  node
end

def babelfish_mangling(node : Alias, scope) : Alias
  # _dbg "babelfish_mangling(#{node.class}: #{node}, #{scope}) ->"
  node.tried_as_foreign, node.name = babelfish_mangling_raw node.tried_as_foreign, node.is_onyx, node.name, scope
  node.value = babelfish_mangling node.value, scope
  node
end

def babelfish_mangling(node : Path, scope) : Path
  # _dbg "babelfish_mangling(#{node.class}: #{node}, #{scope}) ->"

  unless node.is_onyx
    if node.names.any? &.ends_with? "__X_" # *TODO*
      node.is_onyx = true
      # _dbg "- babelfish_mangling - X X X ".red
      # _dbg "- babelfish_mangling - X X X ".yellow
      # _dbg "- babelfish_mangling - FUCK SHIT! is_onyx = false, but IT MUST BE ONYX!".cyan
      # _dbg "- babelfish_mangling - X X X ".yellow
      # _dbg "- babelfish_mangling - X X X ".red

    else
      # _dbg "- babelfish_mangling - returns because is_onyx = false"
      return node
    end
  end

  if node.names.any? &.ends_with? "__X_" # *TODO*
    # if !node.names.first.ends_with? "__X_"
    #   _dbg "- babelfish_mangling - detaints some of '#{node.names}'"
    #   _dbg "- babelfish_mangling - X X X ".red
    #   _dbg "- babelfish_mangling - X X X ".yellow
    #   _dbg "- babelfish_mangling - SHIT SHIT! first is not tainted - but others are!".cyan
    #   _dbg "- babelfish_mangling - X X X ".yellow
    #   _dbg "- babelfish_mangling - X X X ".red
    # else
    #   _dbg "- babelfish_mangling - detaints all '#{node.names}'"
    # end

    node.names = node.names.map { |name| name.ends_with?("__X_") ? name.[0..-5] : name }

  end

  unless scope.is_a?(Program | Nil)
    # _dbg "- babelfish_mangling - returns '#{node}' non-foreigned because scope isn't Prog|Nil (#{scope.class})"
    return node
  end

  if node.tried_as_foreign
    # _dbg "- babelfish_mangling - returns '#{node}' because already foreigned"
    return node
  end

  node.tried_as_foreign = true

  if (foreign = $babelfish_type_dict[node.names.first]?)
    # _dbg "- babelfish_mangling - found foreign name: #{foreign} for #{node}"
    node.names[0] = foreign
    return node
  else
    # _dbg "- babelfish_mangling - returns '#{node}' because no foreign translation found"
    return node
  end
end

def babelfish_mangling_raw(tried_as_foreign : Bool, is_onyx : Bool, name : String, scope) : {Bool, String}
  # _dbg "babelfish_mangling_raw(#{tried_as_foreign}, #{is_onyx}, #{name}, #{scope}) ->"

  unless is_onyx
    # _dbg "- babelfish_mangling_raw - returns because is_onyx = false"
    return {tried_as_foreign, name}
  end

  name = babelfish_detaint name

  unless scope.is_a?(Program | Nil)
    # _dbg "- babelfish_mangling_raw - returns '#{name}' un-foreigned because scope isn't Prog|Nil"
    return {tried_as_foreign, name}
  end

  if tried_as_foreign
    # _dbg "- babelfish_mangling_raw - returns '#{name}' because already foreigned"
    return {tried_as_foreign, name}
  end

  tried_as_foreign = true

  if (foreign = $babelfish_type_dict[name]?)
    # _dbg "- babelfish_mangling_raw - found foreign name: #{foreign} for #{name}"
    name = foreign
    return {tried_as_foreign, name}
  else
    # _dbg "- babelfish_mangling_raw - returns '#{name}' because no foreign translation found"
    return {tried_as_foreign, name}
  end
end

