require "set"
require "../program"
require "../syntax/transformer"

module Crystal
  class Program
    def normalize(node, inside_exp = false)
      # _dbg_overview "\nCompiler stage: Program.normalize\n\n".white
      # *TODO* add "normalize_count" to nodes, to keep track of (lack of) efficiency

      normalizer = Normalizer.new(self)
      normalizer.exp_nest = 1 if inside_exp
      node = normalizer.normalize(node)
      puts node if ENV["SSA"]? == "1"
      node
    end
  end

  class Normalizer < Transformer
    getter program : Program
    property exp_nest : Int32

    @dead_code : Bool
    @current_def : Def?

    def initialize(@program)
      @dead_code = false
      @current_def = nil
      @exp_nest = 0
    end

    def normalize(node)
      _dbg "Normalizer.normalize(#{node.class}) -> where node.is_onyx = #{node.is_onyx}:\nnode: (#{node})"
      node.transform(self)
    end

    def before_transform(node)
      @dead_code = false
      @exp_nest += 1 if nesting_exp?(node)
      nil
    end

    def after_transform(node)
      @exp_nest -= 1 if nesting_exp?(node)

      case node
      when Return, Break, Next
        @dead_code = true
      when If, Unless, Expressions, Block, Assign
        # Skip
      else
        @dead_code = false
      end
      nil
    end

    def nesting_exp?(node)
      case node
      when Expressions, VisibilityModifier, MacroFor, MacroIf, MacroExpression, Require, IfDef
        false
      else
        true
      end
    end

    def transform(node : Expressions)
      exps = [] of ASTNode
      node.expressions.each do |exp|
        new_exp = exp.transform(self)
        if new_exp
          if new_exp.is_a?(Expressions)
            exps.concat new_exp.expressions
          else
            exps << new_exp
          end
        end
        break if @dead_code
      end
      case exps.size
      when 0
        Nop.new
      when 1
        exps[0]
      else
        node.expressions = exps
        node
      end
    end

    def transform(node : Call)
      # Copy enclosing def's args to super/previous_def without parenthesis
      case node.name
      when "super", "previous_def"
        if node.args.empty? && !node.has_parentheses
          if current_def = @current_def
            current_def.args.each_with_index do |arg, i|
              arg = Var.new(arg.name)
              arg = Splat.new(arg) if i == current_def.splat_index
              node.args.push arg
            end
          end
          node.has_parentheses = true
        end
      end

      # Convert 'a <= b <= c' to 'a <= b && b <= c'
      if comparison?(node.name) && (obj = node.obj) && obj.is_a?(Call) && comparison?(obj.name)
        case middle = obj.args.first
        when NumberLiteral, Var, InstanceVar
          transform_many node.args
          left = obj
          right = Call.new(middle.clone, node.name, node.args)
        else
          temp_var = new_temp_var
          temp_assign = Assign.new(temp_var.clone, middle)
          left = Call.new(obj.obj, obj.name, temp_assign)
          right = Call.new(temp_var.clone, node.name, node.args)
        end
        node = And.new(left, right)
        node = node.transform self
      else
        node = super
      end

      node
    end

    def comparison?(name)
      case name
      when "<=", "<", "!=", "==", "===", ">", ">="
        true
      else
        false
      end
    end

    def transform(node : Def)
      @current_def = node
      node = super
      @current_def = nil

      # If the def has a block argument without a specification
      # and it doesn't use it, we remove it because it's useless
      # and the semantic code won't have to bother checking it
      block_arg = node.block_arg
      if !node.uses_block_arg && block_arg
        block_arg_restriction = block_arg.restriction
        if block_arg_restriction.is_a?(ProcNotation) && !block_arg_restriction.inputs && !block_arg_restriction.output
          node.block_arg = nil
        elsif !block_arg_restriction
          node.block_arg = nil
        end
      end

      node
    end

    def transform(node : Macro)
      node
    end

    def transform(node : If)
      node.cond = node.cond.transform(self)

      node.then = node.then.transform(self)
      then_dead_code = @dead_code

      node.else = node.else.transform(self)
      else_dead_code = @dead_code

      @dead_code = then_dead_code && else_dead_code
      node
    end

    # Convert unless to if:
    #
    # From:
    #
    #     unless foo
    #       bar
    #     else
    #       baz
    #     end
    #
    # To:
    #
    #     if foo
    #       baz
    #     else
    #       bar
    #     end
    def transform(node : Unless)
      If.new(node.cond, node.else, node.then).transform(self).at(node)
    end

    # Convert until to while:
    #
    # From:
    #
    #    until foo
    #      bar
    #    end
    #
    # To:
    #
    #    while !foo
    #      bar
    #    end
    def transform(node : Until)
      node = super
      not_exp = Not.new(node.cond).at(node.cond)
      While.new(not_exp, node.body).at(node)
    end


    # Convert For to expr.each*:
    #
    # From:
    #
    #     for val in list
    #       p val
    #     end
    #
    #     for val, ix in list
    #       p val, ", ", ix
    #     end
    #
    # To:
    #
    #     list.each do |val]
    #       p val
    #     end
    #
    #     list.each_with_index do |val, ix]
    #       p val, ", ", ix
    #     end
    def transform(node : For) : ASTNode

      # *TODO* - after macros is fixed
      # unless node.is_onyx
      #   raise "There shouldn't be any For-nodes from Crystal sources!"
      # end

      # method_name uninitialized String
      # if !(node.stepping && node.stepping != 1)
      if (v = node.value_id) && (i = node.index_id)
        method_name = "each_with_index"
        block_args = [v, i]
      elsif (v = node.value_id)
        method_name = "each"
        block_args = [v]
      else
        method_name = "each_index"
        block_args = [node.index_id.not_nil!]
      end

      block = Block.new(
                block_args,
                node.body.transform(self).at(node.body)
              )

      result = Call.new(
                 node.iterable.transform(self),
                 method_name,
                 [] of ASTNode,
                 block
               ).at(node)
      # p result.to_s
      # dump foo.to_s
      # else
      # *TODO* create a while construct
      # create it in a block
      # if stepping
      #   if stepping.is_a? NumberLiteral
      #     if stepping.value.to_i64 > 0

      #     elsif stepping.value.to_i64 < 0

      #     else
      #       raise "can't have a loop iteration step of 0!"
      #     end
      #   else
      #     dynamic step
      #   end
      # else
      # end
      result
    end



    # Evaluate the ifdef's flags.
    # If they hold, keep the "then" part.
    # If they don't, keep the "else" part.
    def transform(node : IfDef)
      cond_value = program.eval_flags(node.cond)
      if cond_value
        node.then.transform(self)
      else
        node.else.transform(self)
      end
    end

    # Transform require to its source code.
    # The source code can be a Nop if the file was already required.
    def transform(node : Require)
      if @exp_nest > 0
        node.raise "can't require dynamically"
      end

      location = node.location
      filenames = @program.find_in_path(node.string, location.try &.filename)
      if filenames
        nodes = Array(ASTNode).new(filenames.size)
        filenames.each do |filename|
          if @program.add_to_requires(filename)
            if filename.ends_with? ".ox"
            #   parser = OnyxParser.new File.read(filename), @program.string_pool
            # else
            #   parser = Parser.new File.read(filename), @program.string_pool
            # end
              parser = OnyxParserPool.borrow(File.read(filename), @program.string_pool, nil)
            else
              parser = ParserPool.borrow(File.read(filename), @program.string_pool, nil)
            end

            _dbg_overview "\nCompiler stage: Normalizer.transform(#{node} #{node.class})"
            _dbg_overview " parses \"#{filename}\"\n\n".white

            parser.filename = filename
            parser.wants_doc = @program.wants_doc?
            nodes << FileNode.new(parser.parse.transform(self), filename)

            if parser.is_a? OnyxParser
              OnyxParserPool.leave parser
            else
              ParserPool.leave parser
            end

          else
            _dbg_overview "\nCompiler stage: Normalizer.transform(#{node} #{node.class})"
            _dbg_overview " ALREADY PROCESSED \"#{filename}\"\n\n".white
          end
        end
        Expressions.from(nodes)
      else
        Nop.new
      end
    rescue ex : Crystal::Exception
      node.raise "while requiring \"#{node.string}\"", ex
    rescue ex
      node.raise "while requiring \"#{node.string}\": #{ex.message}"
    end


    # Remove pragmas used at parsing stage
    def transform(node : Attribute) : ASTNode

      # *TODO* when macros are fixed
      # return node unless node.is_onyx

      if ["!int_literal", "!real_literal"].includes? node.name
        Nop.new
      else
        node.name =
        case node.name.downcase.gsub(/_/, "")
        when "link"
          "Link"

        when "pure"
          "TODO_take_care_of_this!" # *TODO*
        when "flatten"
          "TODO_flatten_is_not_in_llvm_arsenal" # *TODO*
        when "inline"
          "AlwaysInline"
        when "noinline"
          "NoInline"
        when "raises"
          "Raises"
        when "returnstwice"
          "ReturnsTwice"
        when "naked"
          "Naked"

        when "threadbound"
          "ThreadLocal"
        when "programbound"
          "TODO_This_should_just_be_noped" # *TODO*

        else
          node.name
        end

        node
      end
    end


    # Check if the right hand side is dead code
    def transform(node : Assign)
      super

      if @dead_code
        node.value
      else
        node
      end
    end

    def new_temp_var
      program.new_temp_var
    end
  end
end
