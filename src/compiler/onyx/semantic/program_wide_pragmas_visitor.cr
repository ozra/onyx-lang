require "../../crystal/syntax/visitor"

module Crystal
  class Program
    def visit_program_wide_pragmas(node)
      node.accept ProgramWidePragmasVisitor.new(self)
      node
    end
  end

  # In this pass we traverse the AST nodes to process pragmas relating to
  # program–wide definitions like what standard int type to use.
  class ProgramWidePragmasVisitor < Visitor
    @program : Program

    @std_int_width = 0
    @std_real_width = 0

    def initialize(@program)
    end

    # Will only look in top level!
    def visit(node : ASTNode)
      false
    end

    def visit(node : Expressions)
      true
    end

    def visit(node : Attribute)
      case node.name
      when "std_int_width"
        if @std_int_width != 0 #  && pragmas.args[1]? != ...
          node.raise "pragma `std_int_width` can only be specified once in a program"
        end

        @std_int_width = (node.args[0]?.as Arg).name.to_i

        case @std_int_width
        when 8
          @program.define_stdint @program.int8
          @program.define_stdnat @program.int8   # *TODO*
          @program.define_stduint @program.uint8
        when 16
          @program.define_stdint @program.int16
          @program.define_stdnat @program.int16   # *TODO*
          @program.define_stduint @program.uint16
        when 32
          @program.define_stdint @program.int32
          @program.define_stdnat @program.int32   # *TODO*
          @program.define_stduint @program.uint32
        when 64
          @program.define_stdint @program.int64
          @program.define_stdnat @program.int64   # *TODO*
          @program.define_stduint @program.uint64
        else
          node.raise "#{@std_int_width} bit int type is currently not supported"
        end

        node.processed = true

      when "std_real_width"
        if @std_real_width != 0 #  && pragmas.args[1]? != ...
          node.raise "pragma `std_real_width` or `std_real_type` can only be specified once in a program"
        end

        @std_real_width = (node.args[0]?.as Arg).name.to_i

        case @std_real_width
        when 32
          @program.define_stdreal @program.float32
        when 64
          @program.define_stdreal @program.float64
        else
          node.raise "#{@std_real_width} bit float type is currently not supported"
        end

        node.processed = true

      when "std_real_type"
        if @std_real_width != 0 #  && pragmas.args[1]? != ...
          node.raise "pragma `std_real_width` or `std_real_type` can only be specified once in a program"
        end

        @std_real_width = -1
        real_type = (node.args[0]?.as Arg).name.to_s

        # *TODO* make .real -> TypeAlias ?

        node.processed = true

      end
    end

  end

end
