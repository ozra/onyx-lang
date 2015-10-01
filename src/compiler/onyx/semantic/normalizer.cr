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
      node
    end
  end

  class Normalizer < Transformer
    # def initialize(@program)
    #   @dead_code = false
    #   @current_def = nil
    #   @exp_nest = 0
    # end

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

    def new_temp_var
      program.new_temp_var
    end
  end
end
