require "../crystal/compiler"

# require "../debug_utils/ast_dump"

module Crystal
  class Compiler

    def initialize
      @debug = false
      @dump_ll = false
      @color = true
      @no_codegen = false
      @n_threads = 4.to_i32 # saner default!
      @prelude = "onyx_prelude"
      @release = false
      @single_module = false
      @stats = false
      @verbose = false
      @wants_doc = false
      @flags = [] of String
    end

    private def parse(source)
      if source.filename.ends_with? ".cr"
        parser = Parser.new(source.code)
      else # .ox, .onyx
        parser = OnyxParser.new(source.code)
      end
      parser.filename = source.filename
      parser.wants_doc = wants_doc?

      foo = parser.parse


      # *TODO* - debugga hela programstrukturen
      # puts "\n\n\nAST:\n\n\n"
      # foo.dump_std
      # puts "\n\n\n"


      foo


    rescue ex : InvalidByteSequenceError
      print colorize("Error: ").red.bold
      print colorize("file '#{Crystal.relative_filename(source.filename)}' is not a valid Crystal source file: ").bold
      puts "#{ex.message}"
      exit 1
    end
  end
end
