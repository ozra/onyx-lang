require "set"
require "../../crystal/program"
require "../../crystal/syntax/transformer"

module Crystal
  class Program
    def normalize(node, inside_exp = false)
      normalizer = Normalizer.new(self)
      normalizer.exp_nest = 1 if inside_exp
      node = normalizer.normalize(node)
      puts node if ENV["SSA"]? == "1"


      # ifdef !release
      #   if   true  # *TEMP* *DEBUG* *TODO*
      #     puts "NORMALIZED PROGRAM:"
      #     puts node.to_s
      #   end
      # end

      node
    end
  end

  class Normalizer < Transformer

    # Remove pragmas used at parsing stage
    def transform(node : Attribute) : ASTNode
      if ["int_literal", "real_literal"].includes? node.name
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

      p result.to_s
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
#
      #   end
      # else

      # end
      # end
      result
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
              parser = OnyxParser.new File.read(filename)
            else
              parser = Parser.new File.read(filename)
            end

            parser.filename = filename
            parser.wants_doc = @program.wants_doc?
            nodes << parser.parse.transform(self)
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
  end
end

# @[AlwaysInline]
# def for_increasing(begin, end, step)
# end

# @[AlwaysInline]
# def for_increasing(begin, end)
# end

# @[AlwaysInline]
# def for_increasing(begin, end, step)
# end

# @[AlwaysInline]
# def for_increasing(begin, end)
# end

# @[AlwaysInline]
# def for_runtime_direction(begin, end, step)
# end

# @[AlwaysInline]
# def for_runtime_direction(begin, end)
# end
