class BabelData
  @@stringpool = StringPool.new
  @@type_dict = Hash(String, String).new
  @@func_dict = Hash(String, String).new
  @@reverse_dict = Hash(String, String).new

  def self.get_str(str : String)
    @@stringpool.get str
  end

  def self.types()
    @@type_dict
  end

  def self.funcs()
    @@func_dict
  end

  def self.reverse()
    @@reverse_dict
  end
end

babelfish_type_dict = BabelData.types
babelfish_func_dict = BabelData.funcs
babelfish_reverse_dict = BabelData.reverse

macro babel_type(given, foreign, block_it = true)
  babelfish_type_dict["{{given.id}}"] = "{{foreign.id}}"
  babelfish_reverse_dict["{{foreign.id}}"] = "{{given.id}}"
  {% if block_it %}
    babelfish_type_dict["{{foreign.id}}"] = "{{foreign.id}}__auto_babeled_"
    babelfish_reverse_dict["{{foreign.id}}__auto_babeled_"] = "{{foreign.id}}"
  {% end %}
end

macro babel_func(given, foreign, block_it = true)
  babelfish_func_dict["{{given.id}}"] = "{{foreign.id}}"
  babelfish_reverse_dict["{{foreign.id}}"] = "{{given.id}}"
  {% if block_it %}
    babelfish_func_dict["{{foreign.id}}"] = "{{foreign.id}}__auto_babeled_"
    babelfish_reverse_dict["{{foreign.id}}__auto_babeled_"] = "{{foreign.id}}"
  {% end %}
end


babel_type Any,    Object,      true
babel_type Object, Class,       true
babel_type Record, Struct,      true
babel_type AnyInt, Int,         false


babel_type Int,    StdInt,      false
babel_type Real,   StdReal,     false

babel_type Tag,    Symbol,      true
babel_type Ptr,    Pointer,     true

# babel_type Str,    String,      false  -- added as alias instead currently
babel_type List,   Array,       true
babel_type Tup,    Tuple,       false

babel_type Map,    Hash,        true  # *TODO* Map should be a generic _interface_ choice which uses Hash by default.

babel_type Lambda, Proc,        true

# babel_type Arr,    StaticArray, true  # This is not _really_ the fixed array we want.. Hmm, the val/ref disconnection from type!
# babel_type Array,  StaticArray, true  # This is not _really_ the fixed array we want.. Hmm, the val/ref disconnection from type!

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





# require "../../crystal/semantic/ast"
include Crystal

BABELFISH_TAINT_TOKEN = "__X__"
BABELFISH_CROSSTAINT_TOKEN = "__OX_TAINT__"

ifdef !release
  @[AlwaysInline]
  def babelfish_tainted?(name : String) : Bool
    name.ends_with? BABELFISH_TAINT_TOKEN
  end

  @[AlwaysInline]
  def babelfish_taint(name : String) : String
    BabelData.get_str name + BABELFISH_TAINT_TOKEN
  end

  @[AlwaysInline]
  def babelfish_ensure_taint(name : String) : String
    babelfish_tainted?(name) ? name : babelfish_taint(name)
  end

  @[AlwaysInline]
  def babelfish_detaint(name : String) : String
    # _dbg "- babelfish_detaint - '#{name}"
    babelfish_tainted?(name) ? BabelData.get_str(name[0..-6]) : name
  end

  class String
    def babelfish_tainted?() : Bool
      babelfish_tainted? self
    end
  end

else
  @[AlwaysInline]
  def babelfish_tainted?(name : String) : Bool
    false
  end

  @[AlwaysInline]
  def babelfish_taint(name : String) : String
    name
  end

  @[AlwaysInline]
  def babelfish_ensure_taint(name : String) : String
    name
  end

  @[AlwaysInline]
  def babelfish_detaint(name : String) : String
    name
  end

  class String
    def babelfish_tainted?() : Bool
      false
    end
  end

end


@[AlwaysInline]
def babelfish_croxtainted?(name : String) : Bool
  name.ends_with? BABELFISH_CROSSTAINT_TOKEN
end

@[AlwaysInline]
def babelfish_croxtaint(name : String) : String
  BabelData.get_str name + BABELFISH_CROSSTAINT_TOKEN
end

@[AlwaysInline]
def babelfish_ensure_croxtaint(name : String) : String
  babelfish_croxtaint babelfish_detaint name
end

@[AlwaysInline]
def babelfish_croxdetaint(name : String) : String
  # _dbg "- babelfish_detaint - '#{name}"
  babelfish_croxtainted?(name) ? BabelData.get_str(name[0..-13]) : name
end

class String
  def babelfish_croxtainted?() : Bool
    babelfish_croxtainted? self
  end
end

def babelfish_reverse(name : String) : String
  BabelData.reverse[name]? || name
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

def babelfish_mangling(node : Rescue, scope) : Rescue
  node.types.try &.each { |typ| babelfish_mangling typ, scope }
  node
end

def babelfish_mangling(node : TypeDeclaration, scope) : TypeDeclaration
  _dbg "babelfish_mangling(#{node.class}: #{node}, #{scope} - node.declared_type.class = #{node.declared_type.class}) ->"
  node.declared_type = babelfish_mangling node.declared_type, scope
  node
end

def babelfish_mangling(node : Union, scope) : Union
  _dbg "babelfish_mangling(#{node.class}: #{node}, #{scope}) ->"
  node.types.each { |typ| babelfish_mangling typ, scope }
  node
end

def babelfish_mangling(node : Fun, scope) : Fun
  _dbg "babelfish_mangling(#{node.class}: #{node}, #{scope}) ->"
  node.inputs.try &.each { |inp| babelfish_mangling inp, scope }
  babelfish_mangling node.output, scope
  node
end

def babelfish_mangling(node : ClassDef, scope) : ClassDef
  _dbg "babelfish_mangling(#{node.class}: #{node}, #{scope}) ->"
  node.name = babelfish_mangling node.name, scope
  (t = node.type_vars) && t.each_with_index {|tvar, ix| _, t[ix] = babelfish_mangling_raw true, node.is_onyx, tvar, scope }
  node
end

def babelfish_mangling(node : ModuleDef, scope) : ModuleDef
  _dbg "babelfish_mangling(#{node.class}: #{node}, #{scope}) ->"
  node.name = babelfish_mangling node.name, scope
  (t = node.type_vars) && t.each_with_index {|tvar, ix| _, t[ix] = babelfish_mangling_raw true, node.is_onyx, tvar, scope }
  node
end

def babelfish_mangling(node : Generic, scope) : Generic
  _dbg "babelfish_mangling(#{node.class}: #{node}, #{scope}) ->"
  node.name = babelfish_mangling node.name, scope
  node.type_vars.each_with_index {|tvar, ix| node.type_vars[ix] = babelfish_mangling tvar, scope }
  node
end

def babelfish_mangling(node : Alias, scope) : Alias
  _dbg "babelfish_mangling(#{node.class}: #{node}, #{scope}) ->"
  node.is_foreign, node.name = babelfish_mangling_raw node.is_foreign, node.is_onyx, node.name, scope
  node.value = babelfish_mangling node.value, scope
  node
end

def babelfish_mangling(node : Path, scope) : Path
  _dbg "babelfish_mangling(#{node.class}: #{node}, #{scope}, is_onyx == #{node.is_onyx}) ->"

  unless node.is_onyx
    ifdef !release
      if node.names.any? {|it| it.babelfish_tainted? || it.babelfish_croxtainted?} # *TODO*
        # node.is_onyx = true
        raise "- babelfish_mangling - '#{node.names}' is_onyx = false, but IT MUST BE ONYX!".cyan
      end
    end

    return node
  end

  # if node.names.any? &.babelfish_tainted? # *TODO*
    #   _dbg "- babelfish_mangling - detaints some of '#{node.names}'"
    #   _dbg "- babelfish_mangling - X X X ".red
    #   _dbg "- babelfish_mangling - X X X ".yellow
    #   _dbg "- babelfish_mangling - SHIT SHIT! first is not tainted - but others are!".cyan
    #   _dbg "- babelfish_mangling - X X X ".yellow
    #   _dbg "- babelfish_mangling - X X X ".red
    node.names.map! { |name| babelfish_detaint name }
  # end

  unless scope.is_a?(Program | Nil)
    _dbg "- babelfish_mangling - returns '#{node}' non-foreigned because scope isn't Prog|Nil (#{scope.class})"
    return node
  end

  if node.is_foreign
    _dbg "- babelfish_mangling - returns '#{node}' because already foreigned"
    return node
  end

  # We could save the tried_as concept as optimization to avoid the hash–lookup
  # But as of now there are retry scenarios with forced foreign/non–foreign
  # node.tried_as_foreign = true. Revisit if `using`-clause is painstakingly
  # implemented

  if (foreign = BabelData.types[node.names.first]?)
    # _dbg "- babelfish_mangling - found foreign name: #{foreign} for #{node}"
    node.is_foreign = true
    node.names[0] = foreign
    return node
  else
    # _dbg "- babelfish_mangling - returns '#{node}' because no foreign translation found"
    return node
  end
end

def babelfish_mangling_raw(is_foreign : Bool, is_onyx : Bool, name : String, scope) : {Bool, String}
  _dbg "babelfish_mangling_raw(#{is_foreign}, #{is_onyx}, #{name}, #{scope}) ->"

  unless is_onyx
    # _dbg "- babelfish_mangling_raw - returns because is_onyx = false"
    ifdef !release
      if name.babelfish_tainted? || name.babelfish_croxtainted? # *TODO*
        raise "- babelfish_mangling_raw - '#{name}' is_onyx = false, but IT MUST BE ONYX!".cyan
      end
    end

    return {is_foreign, name}
  end

  name = babelfish_detaint name

  unless scope.is_a?(Program | Nil)
    # _dbg "- babelfish_mangling_raw - returns '#{name}' un-foreigned because scope isn't Prog|Nil"
    return {is_foreign, name}
  end

  if is_foreign
    # _dbg "- babelfish_mangling_raw - returns '#{name}' because already foreigned"
    return {is_foreign, name}
  end

  is_foreign = true

  if (foreign = BabelData.types[name]?)
    # _dbg "- babelfish_mangling_raw - found foreign name: #{foreign} for #{name}"
    name = foreign
    return {is_foreign, name}
  else
    # _dbg "- babelfish_mangling_raw - returns '#{name}' because no foreign translation found"
    return {is_foreign, name}
  end
end

