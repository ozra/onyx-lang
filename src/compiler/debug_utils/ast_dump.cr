# By @bcardiff

require "../crystal/**"
require "../onyx/**"

class Object
  def dump_inspect(io, level)
    #io << "  " * level
    to_s(io)
    io << " :: " << self.class
  end
end

macro dump_prop(name)
  io << "\n" << "  " * (level+1) << {{name.stringify}} << ": "
  if v = {{name}}
    if v.is_a?(Array)
      if v.empty?
        #io << "  " * (level+2) << "[]"
        io << "[]"
      end
      v.each_with_index do |e, i|
        io << "\n" << "  " * (level+2) << "[" << i << "]"
        e.dump_inspect(io, level + 2)
      end
    else
      v.dump_inspect(io, level + 2)
    end
  else
    io << "nil"
  end
  # io << '\n'
end

module Crystal
  abstract class ASTNode
    macro def dump_inspect(io, level) : Int32
      io << "\n" << "  " * level << {{@type.name}} #<< '\n'

      {% for ivar, i in @type.instance_vars %}
        {% unless {
            "call": true, # for recursion in Block..
            "is_expansion": true,
            "has_parenthesis": true,
            "location": true,
            "type": true,
            "dirty": true,
            "uses_with_scope": true,
            "global": true,
            "visited": true,
            "name_column_number": true,
            "name_length": true,
            "doc": true,
          }[ivar.stringify]  %}
        dump_prop @{{ivar}}
        {% end %}
      {% end %}

      0
    end

    def dump_inspect(io)
      dump_inspect(io, 0)
    end

    def dump_std()
      dump_inspect(STDOUT)
    end

  end
end

def dump(code : String)
  parser = Crystal::Parser.new(code)
  parser.parse.dump_inspect(STDOUT)
end

def dump(node : Crystal::ASTNode)
  node.dump_inspect(STDOUT)
end
