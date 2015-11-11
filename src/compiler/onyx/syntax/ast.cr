module Crystal
  # Base class for nodes in the grammar.
  abstract class ASTNode
    property onyx_node # perhaps this should go only on specific nodes?
    @onyx_node = false
  end

  # Assign expression.
  #
  #     target '=' value
  #
  class Assign < ASTNode
    @declare_composite = false
    property :declare_composite

    def initialize(@target, @value, @declare_composite = false)
    end

    def_equals_and_hash @target, @value, @declare_composite
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
