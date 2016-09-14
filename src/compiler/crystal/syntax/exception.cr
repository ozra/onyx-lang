require "../exception"

module Crystal
  class SyntaxException < Exception
    getter line_number : Int32
    getter column_number : Int32
    getter filename
    getter size : Int32?

    def initialize(message, @line_number, @column_number, @filename, @size = nil)
      super(message)
    end

    def has_location?
      @filename || @line_number
    end

    def json_obj(ar, io)
      ar.push do
        io.json_object do |obj|
          obj.field "file", true_filename
          obj.field "line", @line_number
          obj.field "column", @column_number
          obj.field "size", @size
          obj.field "message", @message
        end
      end
    end

    # def append_to_s(source, io)
    #   if @filename
    #     io << "Syntax error in #{relative_filename(@filename)}:#{@line_number}: #{colorize(@message).bold}"
    #   else
    #     io << "Syntax error in line #{@line_number}: #{colorize(@message).bold}"
    #   end

    #   source = fetch_source(source)

    #   if source
    #     lines = source.lines
    #     if @line_number - 1 < lines.size
    #       line = lines[@line_number - 1]
    #       if line
    #         io << "\n\n"
    #         io << replace_leading_tabs_with_spaces(line.chomp)
    #         io << "\n"
    #         (@column_number - 1).times do
    #           io << " "
    #         end
    #         with_color.green.bold.surround(io) do
    #           io << "^"
    #           if size = @size
    #             io << ("~" * (size - 1))
    #           end
    #         end
    #         io << "\n"
    #       end
    #     end
    #   end
    # end


    def append_to_s(source, io)
      io << "\n"
      # *TODO* Callee file??
      # io << "\n\n * * TEMP COMPILER DEBUG * * :\n"
      # io << "#{__FILE__} : #{__LINE__}"
      # io << "\n\n"
      if @filename
        io << colorize("Syntax error").red.bold.to_s + " in #{relative_filename(@filename)}:#{@line_number}: #{colorize(@message).bold.red}"
      else
        io << colorize("Syntax error").red.bold.to_s + " in line #{@line_number}: #{colorize(@message).bold.red}"
      end

      source = fetch_source(source)

      return unless source
      lines = source.lines
      rowix = @line_number - 1
      return if rowix >= lines.size

      rows_around_count = 3

      io << "\n\n"

      startix = {rowix - rows_around_count, 0}.max
      (startix...rowix).each do |ix|
        line = lines[ix]
        io << (ix + 1).to_s.rjust(5, ' ') + ": " + replace_leading_tabs_with_spaces(line.chomp) + "\n"
      end

      # cursor above error line
      io << " " * ((5 + 2) + @column_number - 1) << "v".green
      io << "\n"

      line = lines[rowix]
      io << colorize((rowix + 1).to_s.rjust(5, ' ') + ": ").red.bold.to_s + replace_leading_tabs_with_spaces(line.chomp) + "\n"

      # cursor below error line
      io << " " * ((5 + 2) + @column_number - 1) << "^".green
      if size = @size
        io << ("~" * (size - 1)).green
      end
      io << "\n"

      endix = {rowix + rows_around_count, lines.size - 1}.min
      (rowix + 1..endix).each do |ix|
        line = lines[ix]
        io << (ix + 1).to_s.rjust(5, ' ') + ": " + replace_leading_tabs_with_spaces(line.chomp) + "\n"
      end

      io << "\n"
    end



    def to_s_with_source(source, io)
      append_to_s fetch_source(source), io
    end

    def fetch_source(source)
      case filename = @filename
      when String
        source = File.read(filename) if File.file?(filename)
      when VirtualFile
        source = filename.source
      end
      source
    end

    def deepest_error_message
      @message
    end
  end
end
