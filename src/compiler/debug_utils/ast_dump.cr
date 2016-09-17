# By @bcardiff

require "../crystal/**"
require "../onyx/**"

macro dump_prop(name)
  io << "\n" << "  " * (level+1) << {{name.stringify}}[1..-1].cyan << ": "

  case (v = {{name}})
  when Nil
    io << "nil"

  when Array
    io << " ["
    v.each_with_index do |e, i|
      io << "\n" << "  " * (level + 2) <<  i.to_s.cyan << ": "
      e.dump_inspect(io, level + 1)
    end
    io << "\n" << ("  " * (level + 1)) << "]"

  else
    v.dump_inspect(io, level + 1)
  end
end

class Object
  def dump_inspect(io, level)
    to_s(io)
    io << " '".magenta << self.class.to_s.magenta
  end
end

abstract class Crystal::ASTNode
  macro def dump_inspect(io, level) : Int32
    io << "\n" << "  " * (level + 1) << "'".magenta << {{@type.name}}.to_s.yellow #<< '\n'

    nils = [] of String

    # primitives first, for more readable visual structure
    {% for ivar, i in @type.instance_vars %}
      {% if Set{"name", "names"}.includes?(ivar.stringify) %}
          case @{{ivar}}
          when String, Path
            io << "\n" << "  " * (level+1) << {{ivar.stringify}}.cyan << ": "
            io << '"' << @{{ivar}}.to_s.white << '"'
          else
            dump_prop @{{ivar}}
          end
      {% end %}

      {% unless Set{
          "name", # handled especially
          "names",
          "call", # for recursion in Block..
          "is_expansion",
          "location",
          "type",
          "dirty",
          "uses_with_scope",
          "global",
          "visited",
          "name_column_number",
          "name_length",
          "doc"
        }.includes?(ivar.stringify) %}
          case @{{ivar}}
          when Nil
            nils << {{ivar.stringify}}
          when String, Symbol, Bool, Number, Char, Enum
            dump_prop @{{ivar}}
          else
            nil
          end
      {% end %}
    {% end %}

    while nils.size > 0
      io << "\n"
      buf = ("  " * (level + 1)) + "[*=nil]: "
      print_width = buf.size
      io << buf
      compare_size = nils.size
      while print_width < 100 && nils.size > 0
        v = nils.shift
        print_width += (v.size + 1)
        io << v.cyan << " "
      end

      if compare_size != 0 && compare_size == nils.size # just skip items if we're indented to deep
        nils.shift
      end
    end

    # then structural types
    {% for ivar, i in @type.instance_vars %}
      {% unless Set{
          "name", # handled especially above
          "names",
          "call", # for recursion in Block..
          "is_expansion",
          "location",
          "type",
          "dirty",
          "uses_with_scope",
          "global",
          "visited",
          "name_column_number",
          "name_length",
          "doc"
        }.includes?(ivar.stringify) %}
          case @{{ivar}}
          when Nil
            nil
          when String, Symbol, Bool, Number, Char, Enum
          else
            dump_prop @{{ivar}}
          end
      {% end %}
    {% end %}

    0
  end

  def dump_inspect(io)
    dump_inspect(io, 0)
    io << "\n"
  end

  def dump_std()
    dump_inspect(STDOUT)
  end

end

def dump(code : String)
  parser = Crystal::Parser.new(code)
  parser.parse.dump_inspect(STDOUT)
end

def dump(node : Crystal::ASTNode)
  node.dump_inspect(STDOUT)
end
