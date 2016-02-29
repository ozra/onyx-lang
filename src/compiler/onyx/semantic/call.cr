require "../../crystal/semantic/call"

class Crystal::Call
  def dbgx(str : String)
    ifdef !release
      if @onyx_node
        STDERR.puts str + " " + @name
      end
    end
  end
end
