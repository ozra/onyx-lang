module Crystal
  module BabelManagment
    property? foreign : Bool = false
  end

  # Base class for nodes in the grammar.
  abstract class ASTNode
    # The location where this node starts, or `nil`
    # if the location is not known.
    property location : Location?

    # The location where this node ends, or `nil`
    # if the location is not known.
    property end_location : Location?

    property is_onyx : Bool = false
    property parenthesized : Bool = false

    # Updates this node's location and returns `self`
    def at(@location : Location?)
      self
    end

    # Sets this node's location and end location to those
    # of `node`, and returns `self`
    def at(node : ASTNode)
      @location = node.location
      @end_location = node.end_location
      self
    end

    # Updates this node's end location and returns `self`
    def at_end(@end_location : Location?)
      self
    end

    # Sets this node's end location to those of `node` and
    # returns self
    def at_end(node : ASTNode)
      @end_location = node.end_location
      self
    end

    # Returns a deep copy of this node. Copied nodes retain
    # the location and end location of the original nodes.
    def clone
      clone = clone_specific_impl
      clone.location = location
      clone.end_location = end_location
      clone.parenthesized = parenthesized
      clone.is_onyx = is_onyx
      clone
    end

    # Returns the doc comment attached to this node. Not every node
    # supports having doc domments, so by default this returns `nil`.
    def doc
    end

    # Attaches a doc comment to this node. Not every node supports
    # having doc comments, so by default this does nothing and some
    # subclasses implement this.
    def doc=(doc)
    end

    def name_column_number
      @location.try(&.column_number) || 0
    end

    def name_size
      0
    end

    def visibility=(visibility : Visibility)
    end

    def visibility
      Visibility::Public
    end

    def nop?
      self.is_a?(Nop)
    end

    def true_literal?
      self.is_a?(BoolLiteral) && self.value
    end

    def false_literal?
      self.is_a?(BoolLiteral) && !self.value
    end

    def class_desc : String
      {{@type.name.split("::").last.id.stringify}}
    end
  end

  class Nop < ASTNode
    # def nop?
    #   true
    # end

    def clone_specific_impl
      Nop.new
    end

    def_equals_and_hash
  end

  # A container for one or many expressions.
  class Expressions < ASTNode
    property expressions : Array(ASTNode)
    property keyword : Symbol?

    def self.from(obj : Nil)
      Nop.new
    end

    def self.from(obj : Array)
      case obj.size
      when 0
        Nop.new
      when 1
        obj.first
      else
        new obj
      end
    end

    def self.from(obj : ASTNode)
      obj
    end

    def initialize(@expressions = [] of ASTNode)
    end

    def empty?
      @expressions.empty?
    end

    def [](i)
      @expressions[i]
    end

    def last
      @expressions.last
    end

    def end_location
      @end_location || @expressions.last?.try &.end_location
    end

    def accept_children(visitor)
      @expressions.each &.accept visitor
    end

    def clone_specific_impl
      Expressions.new(@expressions.clone)
    end

    def_equals_and_hash expressions
  end

  # The nil literal.
  #
  #     'nil'
  #
  class NilLiteral < ASTNode
    def clone_specific_impl
      NilLiteral.new
    end

    def_equals_and_hash
  end

  # A bool literal.
  #
  #     'true' | 'false'
  #
  class BoolLiteral < ASTNode
    property value : Bool

    def initialize(@value)
    end

    # def false_literal?
    #   !value
    # end

    # def true_literal?
    #   value
    # end

    def clone_specific_impl
      BoolLiteral.new(@value)
    end

    def_equals_and_hash value
  end

  # Any number literal.
  # kind stores a symbol indicating which type is it: i32, u16, f32, f64, etc.
  class NumberLiteral < ASTNode
    property value : String
    # property suffix : String?
    property kind : Symbol

    def initialize(@value : String, @kind = :i32) # , @suffix = nil)
    end

    def initialize(value : Number, @kind = :i32) # , @suffix = nil)
      @value = value.to_s
    end

    def has_sign?
      @value[0] == '+' || @value[0] == '-'
    end

    def clone_specific_impl
      NumberLiteral.new(@value, @kind) # , @suffix)
    end

    def_equals value.to_f64, kind  # *TODO* to_f64? Really??!!
    def_hash value, kind # , suffix
  end

  # A char literal.
  #
  #     "'" \w "'"
  #
  class CharLiteral < ASTNode
    property value : Char

    def initialize(@value : Char)
    end

    def clone_specific_impl
      CharLiteral.new(@value)
    end

    def_equals_and_hash value
  end

  class StringLiteral < ASTNode
    property value : String

    def initialize(@value : String)
    end

    def clone_specific_impl
      StringLiteral.new(@value)
    end

    def_equals_and_hash value
  end

  class StringInterpolation < ASTNode
    property expressions : Array(ASTNode)

    def initialize(@expressions : Array(ASTNode))
    end

    def accept_children(visitor)
      @expressions.each &.accept visitor
    end

    def clone_specific_impl
      StringInterpolation.new(@expressions.clone)
    end

    def_equals_and_hash expressions
  end

  class SymbolLiteral < ASTNode
    property value : String

    def initialize(@value : String)
    end

    def clone_specific_impl
      SymbolLiteral.new(@value)
    end

    def_equals_and_hash value
  end

  # An array literal.
  #
  #  '[' [ expression [ ',' expression ]* ] ']'
  #
  class ArrayLiteral < ASTNode
    property elements : Array(ASTNode)
    property of : ASTNode?
    property name : ASTNode?

    def initialize(@elements = [] of ASTNode, @of = nil, @name = nil)
    end

    def self.map(values)
      new(values.map { |value| (yield value).as(ASTNode) })
    end

    def accept_children(visitor)
      @name.try &.accept visitor
      elements.each &.accept visitor
      @of.try &.accept visitor
    end

    def clone_specific_impl
      ArrayLiteral.new(@elements.clone, @of.clone, @name.clone)
    end

    def_equals_and_hash @elements, @of, @name
  end

  class HashLiteral < ASTNode
    property entries : Array(Entry)
    property of : Entry?
    property name : ASTNode?

    def initialize(@entries = [] of Entry, @of = nil, @name = nil)
    end

    def accept_children(visitor)
      @name.try &.accept visitor
      @entries.each do |entry|
        entry.key.accept visitor
        entry.value.accept visitor
      end
      if of = @of
        of.key.accept visitor
        of.value.accept visitor
      end
    end

    def clone_specific_impl
      HashLiteral.new(@entries.clone, @of.clone, @name.clone)
    end

    def_equals_and_hash @entries, @of, @name

    record Entry, key : ASTNode, value : ASTNode
  end

  class NamedTupleLiteral < ASTNode
    property entries : Array(Entry)

    def initialize(@entries = [] of Entry)
    end

    def accept_children(visitor)
      @entries.each do |entry|
        entry.value.accept visitor
      end
    end

    def clone_specific_impl
      NamedTupleLiteral.new(@entries.clone)
    end

    def_equals_and_hash @entries

    record Entry, key : String, value : ASTNode
  end

  class RangeLiteral < ASTNode
    property from : ASTNode
    property to : ASTNode
    property? exclusive : Bool

    def initialize(@from, @to, @exclusive)
    end

    def accept_children(visitor)
      @from.accept visitor
      @to.accept visitor
    end

    def clone_specific_impl
      RangeLiteral.new(@from.clone, @to.clone, @exclusive.clone)
    end

    def_equals_and_hash @from, @to, @exclusive
  end

  class RegexLiteral < ASTNode
    property value : ASTNode
    property options : Regex::Options

    def initialize(@value, @options = Regex::Options::None)
    end

    def accept_children(visitor)
      @value.accept visitor
    end

    def clone_specific_impl
      RegexLiteral.new(@value.clone, @options)
    end

    def_equals_and_hash @value, @options
  end

  class TupleLiteral < ASTNode
    property elements : Array(ASTNode)

    def initialize(@elements)
    end

    def self.map(values)
      new(values.map { |value| (yield value).as(ASTNode) })
    end

    def accept_children(visitor)
      elements.each &.accept visitor
    end

    def clone_specific_impl
      TupleLiteral.new(elements.clone)
    end

    def_equals_and_hash elements
  end

  module SpecialVar
    def special_var?
      @name.starts_with? '$'
    end
  end

  # A local variable or block argument.
  class Var < ASTNode
    include SpecialVar

    property name : String
    property is_nil_sugared : Bool = false

    def initialize(@name : String, @type = nil, @is_nil_sugared = false)
    end

    def name_size
      name.size
    end

    def clone_specific_impl
      Var.new(@name, is_nil_sugared: @is_nil_sugared)
    end

    def_equals name
    def_hash name
  end

  # A code block.
  #
  #     'do' [ '|' arg [ ',' arg ]* '|' ]
  #       body
  #     'end'
  #   |
  #     '{' [ '|' arg [ ',' arg ]* '|' ] body '}'
  #
  class Block < ASTNode
    property args : Array(Var)
    property body : ASTNode
    property call : Call?
    property splat_index : Int32?

    def initialize(@args = [] of Var, body = nil, @splat_index = nil)
      @body = Expressions.from body
    end

    def accept_children(visitor)
      @args.each &.accept visitor
      @body.accept visitor
    end

    def clone_specific_impl
      Block.new(@args.clone, @body.clone, @splat_index)
    end

    def_equals_and_hash args, body, splat_index
  end

  # A method call.
  #
  #     [ obj '.' ] name '(' ')' [ block ]
  #   |
  #     [ obj '.' ] name '(' arg [ ',' arg ]* ')' [ block ]
  #   |
  #     [ obj '.' ] name arg [ ',' arg ]* [ block ]
  #   |
  #     arg name arg
  #
  # The last syntax is for infix operators, and name will be
  # the symbol of that operator instead of a string.
  #
  class Call < ASTNode
    property obj : ASTNode?
    property name : String
    property args : Array(ASTNode)
    property block : Block?
    property block_arg : ASTNode?
    property named_args : Array(NamedArgument)?
    property name_column_number : Int32
    property name_size = -1
    property doc : String?
    property visibility = Visibility::Public
    property? global : Bool
    property? expansion = false
    property? has_parentheses : Bool

    property? implicit_construction : Bool = false
    property? nil_sugared : Bool = false


    def initialize(@obj, @name, args : Array(ASTNode)? = nil, @block = nil, @block_arg = nil, @named_args = nil, global = false, @name_column_number = 0, has_parentheses = false, @implicit_construction = false, @nil_sugared = false)
      @args = args || [] of ASTNode
      @global = !!global
      @has_parentheses = !!has_parentheses
      if block = @block
        block.call = self
      end
    end

    def self.new(obj, name, arg : ASTNode)
      new obj, name, [arg] of ASTNode
    end

    def self.new(obj, name, arg1 : ASTNode, arg2 : ASTNode)
      new obj, name, [arg1, arg2] of ASTNode
    end

    def self.global(name, arg : ASTNode)
      new nil, name, [arg] of ASTNode, global: true
    end

    def self.global(name, arg1 : ASTNode, arg2 : ASTNode)
      new nil, name, [arg1, arg2] of ASTNode, global: true
    end

    def name_size
      if @name_size == -1
        @name_size = name.to_s.ends_with?('=') || name.to_s.ends_with?('@') ? name.size - 1 : name.size
      end
      @name_size
    end

    def accept_children(visitor)
      @obj.try &.accept visitor
      @args.each &.accept visitor
      @named_args.try &.each &.accept visitor
      @block_arg.try &.accept visitor
      @block.try &.accept visitor
    end

    def clone_specific_impl
      clone = Call.new(@obj.clone, @name, @args.clone, @block.clone, @block_arg.clone, @named_args.clone, @global, @name_column_number, @has_parentheses, @implicit_construction, @nil_sugared)
      clone.name_size = name_size
      clone.expansion = expansion?
      clone
    end

    def name_location
      loc = location.not_nil!
      Location.new(loc.filename, loc.line_number, name_column_number)
    end

    def name_end_location
      loc = location.not_nil!
      Location.new(loc.filename, loc.line_number, name_column_number + name_size)
    end

    def_equals_and_hash obj, name, args, block, block_arg, named_args, global?
  end

  class NamedArgument < ASTNode
    property name : String
    property value : ASTNode

    def initialize(@name : String, @value : ASTNode)
    end

    def accept_children(visitor)
      @value.accept visitor
    end

    def clone_specific_impl
      NamedArgument.new(name, value.clone)
    end

    def_equals_and_hash name, value
  end

  # An if expression.
  #
  #     'if' cond
  #       then
  #     [
  #     'else'
  #       else
  #     ]
  #     'end'
  #
  # An if elsif end is parsed as an If whose
  # else is another If.
  class If < ASTNode
    property cond : ASTNode
    property then : ASTNode
    property else : ASTNode

   # *TODO* possibly remove `binary` - diff cr src...
    property binary : Symbol?

    def initialize(@cond, a_then = nil, a_else = nil)
      @then = Expressions.from a_then
      @else = Expressions.from a_else
    end

    def accept_children(visitor)
      @cond.accept visitor
      @then.accept visitor
      @else.accept visitor
    end

    def clone_specific_impl
      a_if = If.new(@cond.clone, @then.clone, @else.clone)
      a_if.binary = binary
      a_if
    end

    def_equals_and_hash @cond, @then, @else
  end

  class Unless < ASTNode
    property cond : ASTNode
    property then : ASTNode
    property else : ASTNode

    def initialize(@cond, a_then = nil, a_else = nil)
      @then = Expressions.from a_then
      @else = Expressions.from a_else
    end

    def accept_children(visitor)
      @cond.accept visitor
      @then.accept visitor
      @else.accept visitor
    end

    def clone_specific_impl
      Unless.new(@cond.clone, @then.clone, @else.clone)
    end

    def_equals_and_hash @cond, @then, @else
  end

  # An ifdef expression.
  #
  #     'ifdef' cond
  #       then
  #     [
  #     'else'
  #       else
  #     ]
  #     'end'
  #
  # An if elsif end is parsed as an If whose
  # else is another If.
  class IfDef < ASTNode
    property cond : ASTNode
    property then : ASTNode
    property else : ASTNode

    def initialize(@cond, a_then = nil, a_else = nil)
      @then = Expressions.from a_then
      @else = Expressions.from a_else
    end

    def accept_children(visitor)
      @cond.accept visitor
      @then.accept visitor
      @else.accept visitor
    end

    def clone_specific_impl
      IfDef.new(@cond.clone, @then.clone, @else.clone)
    end

    def_equals_and_hash @cond, @then, @else
  end

  # Assign expression.
  #
  #     target '=' value
  #
  class Assign < ASTNode
    property target : ASTNode
    property value : ASTNode
    property doc : String?

    def initialize(@target, @value)
    end

    def accept_children(visitor)
      @target.accept visitor
      @value.accept visitor
    end

    def end_location
      @end_location || value.end_location
    end

    def clone_specific_impl
      Assign.new(@target.clone, @value.clone)
    end

    def_equals_and_hash @target, @value
  end

  # Assign expression.
  #
  #     target [',' target]+ '=' value [',' value]*
  #
  class MultiAssign < ASTNode
    property targets : Array(ASTNode)
    property values : Array(ASTNode)

    def initialize(@targets, @values)
    end

    def accept_children(visitor)
      @targets.each &.accept visitor
      @values.each &.accept visitor
    end

    def end_location
      @end_location || @values.last.end_location
    end

    def ==(other : self)
      other.targets == targets && other.values == values
    end

    def clone_specific_impl
      MultiAssign.new(@targets.clone, @values.clone)
    end

    def_hash @targets, @values
  end

  # An instance variable.
  class InstanceVar < ASTNode
    property name : String

    def initialize(@name)
    end

    def name_size
      name.size
    end

    def clone_specific_impl
      InstanceVar.new(@name)
    end

    def_equals_and_hash name
  end

  class ReadInstanceVar < ASTNode
    property obj : ASTNode
    property name : String

    def initialize(@obj, @name)
    end

    def accept_children(visitor)
      @obj.accept visitor
    end

    def clone_specific_impl
      ReadInstanceVar.new(@obj.clone, @name)
    end

    def_equals_and_hash @obj, @name
  end

  class ClassVar < ASTNode
    property name : String

    def initialize(@name)
    end

    def clone_specific_impl
      ClassVar.new(@name)
    end

    def_equals_and_hash name
  end

  # A global variable.
  class Global < ASTNode
    property name : String

    def initialize(@name)
    end

    def name_size
      name.size
    end

    def clone_specific_impl
      Global.new(@name)
    end

    def_equals_and_hash name
  end

  abstract class BinaryOp < ASTNode
    property left : ASTNode
    property right : ASTNode

    def initialize(@left, @right)
    end

    def accept_children(visitor)
      @left.accept visitor
      @right.accept visitor
    end

    def end_location
      @end_location || @right.end_location
    end

    def_equals_and_hash left, right
  end

  # Expressions and.
  #
  #     expression '&&' expression
  #
  class And < BinaryOp
    def clone_specific_impl
      And.new(@left.clone, @right.clone)
    end
  end

  # Expressions or.
  #
  #     expression '||' expression
  #
  class Or < BinaryOp
    def clone_specific_impl
      Or.new(@left.clone, @right.clone)
    end
  end

  # A def argument.
  class Arg < ASTNode
    include SpecialVar

    # The internal name
    property name : String
    property external_name : String
    property default_value : ASTNode?
    property restriction : ASTNode?
    property doc : String?

    property mutability : Symbol = :auto

    def initialize(@name : String, @default_value : ASTNode? = nil, @restriction : ASTNode? = nil, external_name : String? = nil, @mutability = :auto)
      @external_name = external_name || @name
    end

    def accept_children(visitor)
      @default_value.try &.accept visitor
      @restriction.try &.accept visitor
    end

    def name_size
      name.size
    end

    def clone_specific_impl
      Arg.new @name, @default_value.clone, @restriction.clone, @external_name.clone, @mutability.clone
    end

    def_equals_and_hash name, default_value, restriction, external_name, mutability
  end

  # The Proc notation in the type grammar:
  #
  #    input1, input2, ..., inputN -> output
  class ProcNotation < ASTNode
    property inputs : Array(ASTNode)?
    property output : ASTNode?

    def initialize(@inputs = nil, @output = nil)
    end

    def accept_children(visitor)
      @inputs.try &.each &.accept visitor
      @output.try &.accept visitor
    end

    def clone_specific_impl
      ProcNotation.new(@inputs.clone, @output.clone)
    end

    def_equals_and_hash inputs, output
  end

  # A method definition.
  #
  #     'def' [ receiver '.' ] name
  #       body
  #     'end'
  #   |
  #     'def' [ receiver '.' ] name '(' [ arg [ ',' arg ]* ] ')'
  #       body
  #     'end'
  #   |
  #     'def' [ receiver '.' ] name arg [ ',' arg ]*
  #       body
  #     'end'
  #
  class Def < ASTNode
    property receiver : ASTNode?
    property name : String
    property args : Array(Arg)
    property double_splat : Arg?
    property body : ASTNode
    property block_arg : Arg?
    property return_type : ASTNode?
    property yields : Int32?
    property name_column_number = 0
    property splat_index : Int32?
    property doc : String?
    property visibility = Visibility::Public

    property? macro_def : Bool
    property? calls_super = false
    property? calls_initialize = false
    property? calls_previous_def = false
    property? uses_block_arg = false
    property? assigns_special_var = false
    property? abstract : Bool

    # property attributes : Array(Attribute)?

    def initialize(@name, @args = [] of Arg, body = nil, @receiver = nil, @block_arg = nil, @return_type = nil, @macro_def = false, @yields = nil, @abstract = false, @splat_index = nil, @double_splat = nil)
      @body = Expressions.from body
    end

    def accept_children(visitor)
      @receiver.try &.accept visitor
      @args.each &.accept visitor
      @double_splat.try &.accept visitor
      @block_arg.try &.accept visitor
      @return_type.try &.accept visitor
      @body.accept visitor
    end

    def name_size
      name.size
    end

    def min_max_args_sizes
      max_size = args.size
      default_value_index = args.index(&.default_value)
      min_size = default_value_index || max_size
      splat_index = self.splat_index
      if splat_index
        if args[splat_index].name.empty?
          min_size = {default_value_index || splat_index, splat_index}.min
          max_size = splat_index
        else
          min_size -= 1 unless default_value_index && default_value_index < splat_index
          max_size = Int32::MAX
        end
      end
      {min_size, max_size}
    end

    def has_default_arguments?
      args.size > 0 && args.last.default_value
    end

    def clone_specific_impl
      a_def = Def.new(@name, @args.clone, @body.clone, @receiver.clone, @block_arg.clone, @return_type.clone, @macro_def, @yields, @abstract, @splat_index, @double_splat.clone)
      a_def.calls_super = calls_super?
      a_def.calls_initialize = calls_initialize?
      a_def.calls_previous_def = calls_previous_def?
      a_def.uses_block_arg = uses_block_arg?
      a_def.assigns_special_var = assigns_special_var?
      a_def.name_column_number = name_column_number
      a_def
    end

    def_equals_and_hash @name, @args, @body, @receiver, @block_arg, @return_type, @macro_def, @yields, @abstract, @splat_index, @double_splat
  end

  class Macro < ASTNode
    property name : String
    property args : Array(Arg)
    property body : ASTNode
    property double_splat : Arg?
    property block_arg : Arg?
    property name_column_number = 0
    property splat_index : Int32?
    property doc : String?
    property visibility = Visibility::Public

    def initialize(@name, @args = [] of Arg, @body = Nop.new, @block_arg = nil, @splat_index = nil, @double_splat = nil)
    end

    def accept_children(visitor)
      @args.each &.accept visitor
      @body.accept visitor
      @double_splat.try &.accept visitor
      @block_arg.try &.accept visitor
    end

    def name_size
      name.size
    end

    def clone_specific_impl
      Macro.new(@name, @args.clone, @body.clone, @block_arg.clone, @splat_index, @double_splat.clone)
    end

    def_equals_and_hash @name, @args, @body, @block_arg, @splat_index, @double_splat
  end

  abstract class UnaryExpression < ASTNode
    property exp : ASTNode

    def initialize(@exp)
    end

    def accept_children(visitor)
      @exp.accept visitor
    end

    def_equals_and_hash exp
  end

  # Used only for flags
  class Not < UnaryExpression
    def clone_specific_impl
      Not.new(@exp.clone)
    end
  end

  class PointerOf < UnaryExpression
    def clone_specific_impl
      PointerOf.new(@exp.clone)
    end
  end

  class SizeOf < UnaryExpression
    def clone_specific_impl
      SizeOf.new(@exp.clone)
    end
  end

  class InstanceSizeOf < UnaryExpression
    def clone_specific_impl
      InstanceSizeOf.new(@exp.clone)
    end
  end

  class Out < UnaryExpression
    def clone_specific_impl
      Out.new(@exp.clone)
    end
  end

  class VisibilityModifier < ASTNode
    property modifier : Visibility
    property exp : ASTNode
    property doc : String?

    def initialize(@modifier : Visibility, @exp)
    end

    def accept_children(visitor)
      @exp.accept visitor
    end

    def clone_specific_impl
      VisibilityModifier.new(@modifier, @exp.clone)
    end

    def_equals_and_hash modifier, exp
  end

  class IsA < ASTNode
    property obj : ASTNode
    property const : ASTNode
    property? nil_check : Bool

    def initialize(@obj, @const, @nil_check = false)
    end

    def accept_children(visitor)
      @obj.accept visitor
      @const.accept visitor
    end

    def clone_specific_impl
      IsA.new(@obj.clone, @const.clone, @nil_check)
    end

    def_equals_and_hash @obj, @const, @nil_check
  end

  class RespondsTo < ASTNode
    property obj : ASTNode
    property name : String

    def initialize(@obj, @name)
    end

    def accept_children(visitor)
      obj.accept visitor
    end

    def clone_specific_impl
      RespondsTo.new(@obj.clone, @name)
    end

    def_equals_and_hash @obj, @name
  end

  class Require < ASTNode
    property string : String

    def initialize(@string)
    end

    def clone_specific_impl
      Require.new(@string)
    end

    def_equals_and_hash string
  end

  class When < ASTNode
    property conds : Array(ASTNode)
    property body : ASTNode

    def initialize(@conds, body = nil)
      @body = Expressions.from body
    end

    def accept_children(visitor)
      @conds.each &.accept visitor
      @body.accept visitor
    end

    def clone_specific_impl
      When.new(@conds.clone, @body.clone)
    end

    def_equals_and_hash @conds, @body
  end

  class Case < ASTNode
    property cond : ASTNode?
    property whens : Array(When)
    property else : ASTNode?

    def initialize(@cond, @whens, @else = nil)
    end

    def accept_children(visitor)
      @whens.each &.accept visitor
      @else.try &.accept visitor
    end

    def clone_specific_impl
      Case.new(@cond.clone, @whens.clone, @else.clone)
    end

    def_equals_and_hash @cond, @whens, @else
  end

  # Node that represents an implicit obj in:
  #
  #     case foo
  #     when .bar? # this is a call with an implicit obj
  #     end
  class ImplicitObj < ASTNode
    def ==(other : self)
      true
    end

    def clone_specific_impl
      self
    end

    def hash
      0
    end
  end

  # A qualified identifier.
  #
  #     const [ '::' const ]*
  #
  class Path < ASTNode
    include BabelManagment

    property names : Array(String)
    property? global : Bool
    property name_size = 0

    def initialize(@names : Array, @global = false)
    end

    def self.new(name : String, global = false)
      new [name], global
    end

    def self.global(names)
      new names, true
    end

    # Returns true if this path has a single component
    # with the given name
    def single?(name)
      names.size == 1 && names.first == name
    end

    def clone_specific_impl
      ident = Path.new(@names.clone, @global)
      ident.name_size = name_size
      # ident.tried_as_foreign = @tried_as_foreign
      ident.foreign = @foreign
      ident
    end

    def_equals_and_hash @names, @global, @foreign
  end


  # Type extension - actual type not known until looked up:
  # Onyx-specific node
  #
  #     'ext' name
  #       body
  #     'end'
  #
  class ExtendTypeDef < ASTNode
    property name : Path
    property body : ASTNode?
    property expanded : ASTNode?

    def initialize(@name, body = nil, @expanded = nil)
      # ensure the body is an array of nodes at all times
      if body == nil
        body = [] of ASTNode
      elsif body.is_a? ASTNode
        body = [body] of ASTNode
      end
      @body = Expressions.new body.not_nil!
    end

    def clone_specific_impl
      ExtendTypeDef.new(@name.clone, @body.clone, @expanded.clone)
    end
  end

  # Type definition:
  #
  #     'type' name [ '<' superclass ]
  #       body
  #     'end'
  #
  class ClassDef < ASTNode
    property name : Path
    property body : ASTNode
    property superclass : ASTNode?
    property type_vars : Array(String)?
    property name_column_number : Int32
    property doc : String?
    property splat_index : Int32?
    property? abstract : Bool
    property? struct : Bool

    def initialize(@name, body = nil, @superclass = nil, @type_vars = nil, @abstract = false, @struct = false, @name_column_number = 0, @splat_index = nil)
      @body = Expressions.from body
    end

    def accept_children(visitor)
      @superclass.try &.accept visitor
      @body.accept visitor
    end

    def clone_specific_impl
      ClassDef.new(@name, @body.clone, @superclass.clone, @type_vars.clone, @abstract, @struct, @name_column_number, @splat_index)
    end

    def_equals_and_hash @name, @body, @superclass, @type_vars, @abstract, @struct, @splat_index
  end

  # Module definition:
  #
  #     'module' name
  #       body
  #     'end'
  #
  class ModuleDef < ASTNode
    property name : Path
    property body : ASTNode
    property type_vars : Array(String)?
    property splat_index : Int32?
    property name_column_number : Int32
    property doc : String?

    def initialize(@name, body = nil, @type_vars = nil, @name_column_number = 0, @splat_index = nil)
      @body = Expressions.from body
    end

    def accept_children(visitor)
      @body.accept visitor
    end

    def clone_specific_impl
      ModuleDef.new(@name, @body.clone, @type_vars.clone, @name_column_number, @splat_index)
    end

    def_equals_and_hash @name, @body, @type_vars, @splat_index
  end

  # While expression.
  #
  #     'while' cond
  #       body
  #     'end'
  #
  class While < ASTNode
    property cond : ASTNode
    property body : ASTNode

    def initialize(@cond, body = nil)
      @body = Expressions.from body
    end

    def accept_children(visitor)
      @cond.accept visitor
      @body.accept visitor
    end

    def clone_specific_impl
      While.new(@cond.clone, @body.clone)
    end

    def_equals_and_hash @cond, @body
  end

  # Until expression.
  #
  #     'until' cond
  #       body
  #     'end'
  #
  class Until < ASTNode
    property cond : ASTNode
    property body : ASTNode

    def initialize(@cond, body = nil)
      @body = Expressions.from body
    end

    def accept_children(visitor)
      @cond.accept visitor
      @body.accept visitor
    end

    def clone_specific_impl
      Until.new(@cond.clone, @body.clone)
    end

    def_equals_and_hash @cond, @body
  end

  # For expression.
  # Onyx-specific node
  #
  #     'for' ( id | id[id] | [id] | id:id | id: | id, id | id, ) ('in'|'from') (expr | (expr 'to' expr) | (expr 'til' expr)) (('step'|'by') expr)?
  #       body
  #     ('end')?
  #
  class For < ASTNode
    property value_id : Var?
    property index_id : Var?
    property iterable : ASTNode
    property stepping : ASTNode?
    property body : ASTNode

    def initialize(@value_id, @index_id, @iterable, @stepping, body = nil)
      @body = Expressions.from body
    end

    def accept_children(visitor)
      @value_id.try &.accept visitor
      @index_id.try &.accept visitor
      @iterable.accept visitor
      @stepping.try &.accept visitor
      @body.accept visitor
    end

    def clone_specific_impl
      For.new(@value_id, @index_id, @iterable.clone, @stepping.clone, @body.clone)
    end

    def_equals_and_hash @value_id, @index_id, @iterable, @stepping, @body
  end

  class Generic < ASTNode
    property name : Path
    property type_vars : Array(ASTNode)
    property named_args : Array(NamedArgument)?

    def initialize(@name, @type_vars : Array, @named_args = nil)
    end

    def self.new(name, type_var : ASTNode)
      new name, [type_var] of ASTNode
    end

    def accept_children(visitor)
      @name.accept visitor
      @type_vars.each &.accept visitor
      @named_args.try &.each &.accept visitor
    end

    def clone_specific_impl
      Generic.new(@name.clone, @type_vars.clone, @named_args.clone)
    end

    def_equals_and_hash @name, @type_vars, @named_args
  end

  class TypeDeclaration < ASTNode
    property mutability : Symbol = :auto

    property var : ASTNode
    property declared_type : ASTNode
    property value : ASTNode?

    def initialize(@var, @declared_type, @value = nil, @mutability = :auto)
    end

    def accept_children(visitor)
      var.accept visitor
      declared_type.accept visitor
      value.try &.accept visitor
    end

    def name_size
      var = @var
      case var
      when Var
        var.name.size
      when InstanceVar
        var.name.size
      when ClassVar
        var.name.size
      when Global
        var.name.size
      else
        raise "can't happen"
      end
    end

    def clone_specific_impl
      TypeDeclaration.new(@var.clone, @declared_type.clone, @value.clone, @mutability.clone)
    end

    def_equals_and_hash @var, @declared_type, @value, @mutability
  end

  class UninitializedVar < ASTNode
    property var : ASTNode
    property declared_type : ASTNode

    def initialize(@var, @declared_type)
    end

    def accept_children(visitor)
      var.accept visitor
      declared_type.accept visitor
    end

    def name_size
      var = @var
      case var
      when Var
        var.name.size
      when InstanceVar
        var.name.size
      else
        raise "can't happen"
      end
    end

    def clone_specific_impl
      UninitializedVar.new(@var.clone, @declared_type.clone)
    end

    def_equals_and_hash @var, @declared_type
  end

  class Rescue < ASTNode
    property body : ASTNode
    property types : Array(ASTNode)?
    property name : String?

    def initialize(body = nil, @types = nil, @name = nil)
      @body = Expressions.from body
    end

    def accept_children(visitor)
      @body.accept visitor
      @types.try &.each &.accept visitor
    end

    def clone_specific_impl
      Rescue.new(@body.clone, @types.clone, @name)
    end

    def_equals_and_hash @body, @types, @name
  end

  class ExceptionHandler < ASTNode
    property body : ASTNode
    property rescues : Array(Rescue)?
    property else : ASTNode?
    property ensure : ASTNode?
    property implicit = false
    property suffix = false

    def initialize(body = nil, @rescues = nil, @else = nil, @ensure = nil)
      @body = Expressions.from body
    end

    def accept_children(visitor)
      @body.accept visitor
      @rescues.try &.each &.accept visitor
      @else.try &.accept visitor
      @ensure.try &.accept visitor
    end

    def clone_specific_impl
      ex = ExceptionHandler.new(@body.clone, @rescues.clone, @else.clone, @ensure.clone)
      ex.implicit = implicit
      ex.suffix = suffix
      ex
    end

    def_equals_and_hash @body, @rescues, @else, @ensure
  end

  class ProcLiteral < ASTNode
    property def : Def

    def initialize(@def = Def.new("->"))
    end

    def accept_children(visitor)
      @def.accept visitor
    end

    def clone_specific_impl
      ProcLiteral.new(@def.clone)
    end

    def_equals_and_hash @def
  end

  class ProcPointer < ASTNode
    property obj : ASTNode?
    property name : String
    property args : Array(ASTNode)

    def initialize(@obj, @name, @args = [] of ASTNode)
    end

    def accept_children(visitor)
      @obj.try &.accept visitor
      @args.each &.accept visitor
    end

    def clone_specific_impl
      ProcPointer.new(@obj.clone, @name, @args.clone)
    end

    def_equals_and_hash @obj, @name, @args
  end

  class Union < ASTNode
    property types : Array(ASTNode)

    def initialize(@types)
    end

    def accept_children(visitor)
      @types.each &.accept visitor
    end

    def clone_specific_impl
      Union.new(@types.clone)
    end

    def_equals_and_hash types
  end

  class Self < ASTNode
    def ==(other : self)
      true
    end

    def clone_specific_impl
      Self.new
    end

    def hash
      0
    end
  end

  abstract class ControlExpression < ASTNode
    property exp : ASTNode?

    def initialize(@exp : ASTNode? = nil)
    end

    def accept_children(visitor)
      @exp.try &.accept visitor
    end

    def end_location
      @end_location || @exp.try(&.end_location)
    end

    def_equals_and_hash exp
  end

  class Return < ControlExpression
    def clone_specific_impl
      Return.new(@exp.clone)
    end
  end

  class Break < ControlExpression
    def clone_specific_impl
      Break.new(@exp.clone)
    end
  end

  class Next < ControlExpression
    def clone_specific_impl
      Next.new(@exp.clone)
    end
  end

  class Yield < ASTNode
    property exps : Array(ASTNode)
    property scope : ASTNode?

    def initialize(@exps = [] of ASTNode, @scope = nil)
    end

    def accept_children(visitor)
      @scope.try &.accept visitor
      @exps.each &.accept visitor
    end

    def clone_specific_impl
      Yield.new(@exps.clone, @scope.clone)
    end

    def end_location
      @end_location || @exps.last?.try(&.end_location)
    end

    def_equals_and_hash @exps, @scope
  end

  class Include < ASTNode
    property name : ASTNode

    def initialize(@name)
    end

    def accept_children(visitor)
      @name.accept visitor
    end

    def clone_specific_impl
      Include.new(@name)
    end

    def end_location
      @end_location || @name.end_location
    end

    def_equals_and_hash name
  end

  class Extend < ASTNode
    property name : ASTNode

    def initialize(@name)
    end

    def accept_children(visitor)
      @name.accept visitor
    end

    def clone_specific_impl
      Extend.new(@name)
    end

    def end_location
      @end_location || @name.end_location
    end

    def_equals_and_hash name
  end

  class LibDef < ASTNode
    property name : String
    property body : ASTNode
    property name_column_number : Int32

    def initialize(@name, body = nil, @name_column_number = 0)
      @body = Expressions.from body
    end

    def accept_children(visitor)
      @body.accept visitor
    end

    def clone_specific_impl
      LibDef.new(@name, @body.clone, @name_column_number)
    end

    def_equals_and_hash @name, @body
  end

  class FunDef < ASTNode
    property name : String
    property args : Array(Arg)
    property return_type : ASTNode?
    property body : ASTNode?
    property real_name : String
    property doc : String?
    property? varargs : Bool

    def initialize(@name, @args = [] of Arg, @return_type = nil, @varargs = false, @body = nil, @real_name = name)
    end

    def accept_children(visitor)
      @args.each &.accept visitor
      @return_type.try &.accept visitor
      @body.try &.accept visitor
    end

    def clone_specific_impl
      FunDef.new(@name, @args.clone, @return_type.clone, @varargs, @body.clone, @real_name)
    end

    def_equals_and_hash @name, @args, @return_type, @varargs, @body, @real_name
  end

  class TypeDef < ASTNode
    property name : String
    property type_spec : ASTNode
    property name_column_number : Int32

    def initialize(@name, @type_spec, @name_column_number = 0)
    end

    def accept_children(visitor)
      @type_spec.accept visitor
    end

    def clone_specific_impl
      TypeDef.new(@name, @type_spec.clone, @name_column_number)
    end

    def_equals_and_hash @name, @type_spec
  end

  # A c struct/union definition inside a lib declaration
  class CStructOrUnionDef < ASTNode
    property name : String
    property body : ASTNode
    property? union : Bool

    def initialize(@name, body = nil, @union = false)
      @body = Expressions.from(body)
    end

    def accept_children(visitor)
      @body.accept visitor
    end

    def clone_specific_impl
      CStructOrUnionDef.new(@name, @body.clone, @union)
    end

    def_equals_and_hash @name, @union, @body
  end

  #class StructDef < StructOrUnionDef
  #  property attributes : Array(Attribute)?
  #
  #  def clone_specific_impl
  #    StructDef.new(@name, @body.clone)
  #  end
  #end
  #
  #class UnionDef < StructOrUnionDef
  #  def clone_specific_impl
  #    UnionDef.new(@name, @body.clone)
  #  end
  #end

  class EnumDef < ASTNode
    property name : Path
    property members : Array(ASTNode)
    property base_type : ASTNode?
    property doc : String?

    def initialize(@name, @members = [] of ASTNode, @base_type = nil)
    end

    def accept_children(visitor)
      @members.each &.accept visitor
      @base_type.try &.accept visitor
    end

    def clone_specific_impl
      EnumDef.new(@name, @members.clone, @base_type.clone)
    end

    def_equals_and_hash @name, @members, @base_type
  end

  class ExternalVar < ASTNode
    property name : String
    property type_spec : ASTNode
    property real_name : String?

    def initialize(@name, @type_spec, @real_name = nil)
    end

    def accept_children(visitor)
      @type_spec.accept visitor
    end

    def clone_specific_impl
      ExternalVar.new(@name, @type_spec.clone, @real_name)
    end

    def_equals_and_hash @name, @type_spec, @real_name
  end

  class Alias < ASTNode
    include BabelManagment

    property name : String
    property value : ASTNode
    property doc : String?

    def initialize(@name : String, @value : ASTNode)
    end

    def accept_children(visitor)
      @value.accept visitor
    end

    def clone_specific_impl
      Alias.new(@name, @value.clone)
    end

    def_equals_and_hash @name, @value
  end

  class Metaclass < ASTNode
    property name : ASTNode

    def initialize(@name)
    end

    def accept_children(visitor)
      @name.accept visitor
    end

    def clone_specific_impl
      Metaclass.new(@name.clone)
    end

    def_equals_and_hash name
  end

  # obj as to
  class Cast < ASTNode
    property obj : ASTNode
    property to : ASTNode

    def initialize(@obj : ASTNode, @to : ASTNode)
    end

    def accept_children(visitor)
      @obj.accept visitor
      @to.accept visitor
    end

    def clone_specific_impl
      Cast.new(@obj.clone, @to.clone)
    end

    def end_location
      @end_location || @to.end_location
    end

    def_equals_and_hash @obj, @to
  end

  # obj.as?(to)
  class NilableCast < ASTNode
    property obj
    property to

    def initialize(@obj : ASTNode, @to : ASTNode)
    end

    def accept_children(visitor)
      @obj.accept visitor
      @to.accept visitor
    end

    def clone_specific_impl
      NilableCast.new(@obj.clone, @to.clone)
    end

    def end_location
      @end_location || @to.end_location
    end

    def_equals_and_hash @obj, @to
  end

  # typeof(exp, exp, ...)
  class TypeOf < ASTNode
    property expressions : Array(ASTNode)

    def initialize(@expressions)
    end

    def accept_children(visitor)
      @expressions.each &.accept visitor
    end

    def clone_specific_impl
      TypeOf.new(@expressions.clone)
    end

    def_equals_and_hash expressions
  end

  class Attribute < ASTNode
    property name : String
    property args : Array(ASTNode)
    property named_args : Array(NamedArgument)?
    property doc : String?

    property? processed : Bool = false
    property lex_style : Symbol

    def initialize(@name, @args = [] of ASTNode, @named_args = nil, @lex_style = :call)
    end

    def accept_children(visitor)
      @args.each &.accept visitor
      @named_args.try &.each &.accept visitor
    end

    def clone_specific_impl
      Attribute.new(@name, @args.clone, @named_args.clone, @lex_style)
    end

    def self.any?(attributes, name)
      !!(attributes.try &.any? { |attr| attr.name == name })
    end

    def_equals_and_hash name, args, named_args
  end

  # A macro expression,
  # surrounded by {{ ... }} (output = true)
  # or by {% ... %} (output = false)
  class MacroExpression < ASTNode
    property exp : ASTNode
    property? output : Bool

    def initialize(@exp : ASTNode, @output = true)
    end

    def accept_children(visitor)
      @exp.accept visitor
    end

    def clone_specific_impl
      MacroExpression.new(@exp.clone, @output)
    end

    def_equals_and_hash exp, output?
  end

  # Free text that is part of a macro
  class MacroLiteral < ASTNode
    property value : String

    def initialize(@value : String)
    end

    def clone_specific_impl
      self
    end

    def_equals_and_hash value
  end

  # if inside a macro
  #
  #     {% 'if' cond %}
  #       then
  #     {% 'else' %}
  #       else
  #     {% 'end' %}
  class MacroIf < ASTNode
    property cond : ASTNode
    property then : ASTNode
    property else : ASTNode

    def initialize(@cond, a_then = nil, a_else = nil)
      @then = Expressions.from a_then
      @else = Expressions.from a_else
    end

    def accept_children(visitor)
      @cond.accept visitor
      @then.accept visitor
      @else.accept visitor
    end

    def clone_specific_impl
      MacroIf.new(@cond.clone, @then.clone, @else.clone)
    end

    def_equals_and_hash @cond, @then, @else
  end

  # for inside a macro:
  #
  #    {% for x1, x2, ... , xn in exp %}
  #      body
  #    {% end %}
  class MacroFor < ASTNode
    property vars : Array(Var)
    property exp : ASTNode
    property body : ASTNode

    def initialize(@vars, @exp, @body)
    end

    def accept_children(visitor)
      @vars.each &.accept visitor
      @exp.accept visitor
      @body.accept visitor
    end

    def clone_specific_impl
      MacroFor.new(@vars.clone, @exp.clone, @body.clone)
    end

    def_equals_and_hash @vars, @exp, @body
  end

  # A uniquely named variable inside a macro (like %var)
  class MacroVar < ASTNode
    property name : String
    property exps : Array(ASTNode)?

    def initialize(@name : String, @exps = nil)
    end

    def accept_children(visitor)
      @exps.try &.each &.accept visitor
    end

    def clone_specific_impl
      MacroVar.new(@name, @exps.clone)
    end

    def_equals_and_hash @name, @exps
  end

  # An underscore matches against any type
  class Underscore < ASTNode
    def ==(other : self)
      true
    end

    def clone_specific_impl
      Underscore.new
    end

    def hash
      0
    end
  end

  class Splat < UnaryExpression
    def clone_specific_impl
      Splat.new(@exp.clone)
    end
  end

  class DoubleSplat < UnaryExpression
    def clone_specific_impl
      DoubleSplat.new(@exp.clone)
    end
  end

  class MagicConstant < ASTNode
    property name : Symbol

    def initialize(@name : Symbol)
    end

    def clone_specific_impl
      MagicConstant.new(@name)
    end

    def expand_node(location)
      case name
      when :__LINE__
        MagicConstant.expand_line_node(location)
      when :__FILE__
        MagicConstant.expand_file_node(location)
      when :__DIR__
        MagicConstant.expand_dir_node(location)
      else
        raise "Bug: unknown magic constant: #{name}"
      end
    end

    def self.expand_line_node(location)
      NumberLiteral.new(expand_line(location))
    end

    def self.expand_line(location)
      location.try(&.line_number) || 0
    end

    def self.expand_file_node(location)
      StringLiteral.new(expand_file(location))
    end

    def self.expand_file(location)
      location.try(&.filename.to_s) || "?"
    end

    def self.expand_dir_node(location)
      StringLiteral.new(expand_dir(location))
    end

    def self.expand_dir(location)
      location.try(&.dirname) || "?"
    end

    def_equals_and_hash name
  end

  class Asm < ASTNode
    property text : String
    property output : AsmOperand?
    property inputs : Array(AsmOperand)?
    property clobbers : Array(String)?
    property? volatile : Bool
    property? alignstack : Bool
    property? intel : Bool

    def initialize(@text, @output = nil, @inputs = nil, @clobbers = nil, @volatile = false, @alignstack = false, @intel = false)
    end

    def accept_children(visitor)
      @output.try &.accept visitor
      @inputs.try &.each &.accept visitor
    end

    def clone_specific_impl
      Asm.new(@text, @output.clone, @inputs.clone, @clobbers, @volatile, @alignstack, @intel)
    end

    def_equals_and_hash text, output, inputs, clobbers, volatile?, alignstack?, intel?
  end

  class AsmOperand < ASTNode
    property constraint : String
    property exp : ASTNode

    def initialize(@constraint : String, @exp : ASTNode)
    end

    def accept_children(visitor)
      @exp.accept visitor
    end

    def clone_specific_impl
      AsmOperand.new(@constraint, @exp)
    end

    def_equals_and_hash constraint, exp
  end

  enum Visibility : Int8
    Public
    Protected
    Private
  end
end

require "./to_s"
