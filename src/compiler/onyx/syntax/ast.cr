module Crystal
  # Base class for nodes in the grammar.
  abstract class ASTNode
    @onyx_node = false
    property onyx_node
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

end

require "./to_s"
