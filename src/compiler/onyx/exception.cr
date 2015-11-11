require "../crystal/exception"

module Crystal
  class SyntaxException < Exception
    def append_to_s(source, io)
      io << "\n"

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

      # with_color.green.bold.surround(io) do
      # cursor below error line
      io << " " * ((5 + 2) + @column_number - 1) << "^".green
      if size = @size
        io << ("~" * (size - 1)).green
      end
      io << "\n"
      # end

      endix = {rowix + rows_around_count, lines.size - 1}.min
      (rowix + 1..endix).each do |ix|
        line = lines[ix]
        io << (ix + 1).to_s.rjust(5, ' ') + ": " + replace_leading_tabs_with_spaces(line.chomp) + "\n"
      end

      io << "\n"
    end
  end
end
