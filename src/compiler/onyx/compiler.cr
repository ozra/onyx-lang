require "../crystal/compiler"

module Crystal
  class Compiler
    private def parse(source)
      #parser :: OnyxParser | Parser

      if source.filename.ends_with? ".cr"
        parser = Parser.new(source.code)
      else  # .ox, .onyx
        parser = OnyxParser.new(source.code)
      end
      parser.filename = source.filename
      parser.wants_doc = wants_doc?
      parser.parse
    rescue ex : InvalidByteSequenceError
      print colorize("Error: ").red.bold
      print colorize("file '#{Crystal.relative_filename(source.filename)}' is not a valid Crystal source file: ").bold
      puts "#{ex.message}"
      exit 1
    end
  end
end
