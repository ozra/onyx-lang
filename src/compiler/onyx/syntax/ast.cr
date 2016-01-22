module Crystal
  # Base class for nodes in the grammar.
  abstract class ASTNode
    property onyx_node
    @onyx_node = false

  end

  # A def argument.
  class Arg < ASTNode
    property :name
    property :default_value
    property :restriction
    property :mutability
    property :doc
    @mutability :: Symbol
    @mutability = :auto

    def initialize(@name, @default_value = nil, @restriction = nil, @type = nil, @mutability = :auto)
    end

    def accept_children(visitor)
      @default_value.try &.accept visitor
      @restriction.try &.accept visitor
    end

    def clone_without_location
      arg = Arg.new @name, @default_value.clone, @restriction.clone, nil, @mutability.clone

      # An arg's type can sometimes be used as a restriction,
      # and must be preserved when cloned
      arg.set_type @type

      arg
    end

    def_equals_and_hash name, default_value, restriction, mutability
  end

  class DeclareVar < ASTNode
    property :var
    property :declared_type
    property :is_assign_composite

    property :mutability
    @mutability :: Symbol
    @mutability = :auto

    def initialize(@var, @declared_type, @is_assign_composite = false, @mutability = :auto)
    end

    def clone_without_location
      DeclareVar.new(@var.clone, @declared_type.clone, @is_assign_composite.clone, @mutability.clone)
    end

    def_equals_and_hash @var, @declared_type, @is_assign_composite, @mutability
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
    def_equals_and_hash obj, name, args, block, block_arg, named_args, global, onyx_node
  end

  # For expression.
  #
  #     'for' ( id | id[id] | [id] | id:id | id: | id, id | id, ) ('in'|'from') (expr | (expr 'to' expr) | (expr 'til' expr)) (('step'|'by') expr)?
  #       body
  #     ('end')?
  #
  class For < ASTNode
    property value_id
    property index_id
    property iterable
    property stepping
    property body

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

    def clone_without_location
      For.new(@value_id, @index_id, @iterable.clone, @stepping.clone, @body.clone)
    end

    def_equals_and_hash @value_id, @index_id, @iterable, @stepping, @body
  end
end

require "./to_s"
