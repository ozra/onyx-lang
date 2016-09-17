# Original concept by @bcardiff
# Revised by @ozra

require "../crystal/**"
require "../onyx/**"

macro dump_prop(name)
  io << "\n" << "  " * (depth+1) << {{name.stringify}}[1..-1].cyan << ": "

  case (v = {{name}})
  when Nil   then io << "nil"
  else       v.dump_inspect(io, terse_output, depth + 1)
  end
end

macro dump_location(name)
  if (terse_output &&
      (%v = {{name}}) &&
      %v.responds_to?(:location) &&
      (%loc = %v.location)
  )
    io << "<"
    io << %loc.line_number
    io << ":"
    io << %loc.column_number
    io << "> "
    io << ": "
  end

end

class Object
  def dump_inspect(io, terse_output : Bool, depth) : Nil
    to_s(io)
    io << " '".magenta << self.class.to_s.magenta
  end
end

class Array
  def dump_inspect(io, terse_output : Bool, depth) : Nil
    Array.dump_inspect io, terse_output, depth, self, "- "
  end

  def self.dump_inspect(io : IO, terse_output : Bool, depth, list : Array, prefix : String = "- ") : Nil
    if list.empty?
      io << "[]"
    else
      list.each_with_index do |e, i|
        io << "\n" << "  " * depth << prefix.cyan <<  i.to_s.cyan << ": ".cyan
        e.dump_inspect(io, terse_output, depth)
      end
    end
  end
end

class Crystal::Expressions
  def dump_inspect(io, terse_output : Bool, depth) : Nil
    # return dump_inspect(io, terse_output, depth, true) unless terse_output # use ASTNode's `dump_inspect`
    io << "'".yellow << self.class.to_s.yellow
    dump_location self
    # @expressions.dump_inspect(io, terse_output, depth + 1)
    Array.dump_inspect io, terse_output, depth + 1, @expressions, "exp-"
  end
end

class Crystal::Call
  def dump_inspect(io, terse_output : Bool, depth) : Nil
    return dump_inspect(io, terse_output, depth, true) unless terse_output # use ASTNode's `dump_inspect`
    io << "'".yellow << self.class.to_s.yellow
    dump_location self

    if (has_obj = obj) && has_obj.is_a?(Var | Path | StringLiteral | NumberLiteral)
      obj_printed = true
      io << has_obj.to_s.white << '.'
    else
      obj_printed = false
    end
    io << name.to_s.white
    io << "() "

    if @args.size > 0
      if has_obj && !obj_printed
        dump_prop @obj
        dump_prop @args
      else
        io << ", " << "args".cyan << ": "
        Array.dump_inspect io, terse_output, depth + 2, @args, "arg-"
      end
    end

    dump_prop @named_args if @named_args
    dump_prop @block if @block
  end
end

class Crystal::Assign
  def dump_inspect(io, terse_output : Bool, depth) : Nil
    if terse_output && (targ = target).is_a?(Var) # use ASTNode's `dump_inspect`
      io << "'".yellow << self.class.to_s.yellow
      dump_location self
      io << targ.name.to_s.white
      io << " = "
      @value.dump_inspect io, terse_output, depth
    else
      return dump_inspect(io, terse_output, depth, true)
    end
  end
end

class Crystal::Var
  def dump_inspect(io, terse_output : Bool, depth) : Nil
    return dump_inspect(io, terse_output, depth, true) unless terse_output # use ASTNode's `dump_inspect`
    io << "'".yellow << self.class.to_s.yellow
    dump_location self
    io << '"' << name.to_s.white << '"'
  end
end

class Crystal::Path
  def dump_inspect(io, terse_output : Bool, depth) : Nil
    return dump_inspect(io, terse_output, depth, true) unless terse_output # use ASTNode's `dump_inspect`
    io << "'".yellow << self.class.to_s.yellow
    dump_location self
    io << '"' << names.join("::").white << '"'
  end
end

class Crystal::NumberLiteral
  def dump_inspect(io, terse_output : Bool, depth) : Nil
    return dump_inspect(io, terse_output, depth, true) unless terse_output # use ASTNode's `dump_inspect`
    io << "'".yellow << self.class.to_s.yellow
    dump_location self
    io << " "
    io << '"' << value.to_s << '"'
  end
end

class Crystal::ASTNode
  macro def dump_inspect(io, terse_output : Bool, depth, force_ast_method : Bool = false) : Nil
    io << "'".yellow << {{@type.name}}.to_s.yellow << " "
    dump_location self

    nils = [] of String

    # Spit out possible names first, for more readable visual structure - they
    # always show nils too
    {% for ivar, i in @type.instance_vars %}
      {% if Set{"name", "names"}.includes?(ivar.stringify) %}
        case @{{ivar}}
        when String then
          io << "\n" << "  " * (depth+1) << {{ivar.stringify}}.cyan << ": "
          io << @{{ivar}}.to_s.white
        else
          dump_prop @{{ivar}}
        end
      {% end %}
    {% end %}

    # Spit out all primitive val props and collect all props with nil values
    # for later output
    {% for ivar, i in @type.instance_vars %}
      if terse_output
        {% if Set{"target", "targets", "values", "value", "obj", "arg", "args", "expressions", "body", "block", "block_arg", "named_args"}.includes?(ivar.stringify) %}
          case @{{ivar}}
          when Nil then
          when String, Symbol, Bool, Number, Char, Enum then dump_prop @{{ivar}}
          else
          end
        {% end %}
      else
        {% if ! Set{"name", "names",  "call", "is_expansion", "location", "type", "dirty", "uses_with_scope", "global", "visited", "name_column_number", "name_length", "doc"}.includes?(ivar.stringify) %}
          case @{{ivar}}
          when Nil then nils << {{ivar.stringify}}
          when String, Symbol, Bool, Number, Char, Enum then dump_prop @{{ivar}}
          else
          end
        {% end %}
      end
    {% end %}

    # Now spit out the collected nil–value properties in a concentrated list
    while nils.size > 0
      io << "\n"
      buf = ("  " * (depth + 1)) + "[*=nil]: "
      print_width = buf.size
      io << buf
      compare_size = nils.size

      while print_width < 100 && nils.size > 0
        nil_prop = nils.shift
        print_width += (nil_prop.size + 1)
        io << nil_prop.cyan << " "
      end

      # just skip items if we're indented to deep, avoid eternal loop and noise
      if compare_size != 0 && compare_size == nils.size
        nils.shift
      end
    end

    # Then spit out structural types
    {% for ivar, i in @type.instance_vars %}
      if terse_output
        {% if Set{"target", "targets", "values", "value", "obj", "arg", "args", "expressions", "body", "block", "block_arg", "named_args"}.includes?(ivar.stringify) %}
          case (%ivar = @{{ivar}})
          when Nil then
          when String, Symbol, Bool, Number, Char, Enum then
          else dump_prop @{{ivar}}
          end
        {% end %}
      else
        {% if ! Set{"name", "names",  "call", "is_expansion", "location", "type", "dirty", "uses_with_scope", "global", "visited", "name_column_number", "name_length", "doc"}.includes?(ivar.stringify) %}
          case (%ivar = @{{ivar}})
          when Nil then
          when String, Symbol, Bool, Number, Char, Enum then
          else dump_prop @{{ivar}}
          end
        {% end %}
      end
    {% end %}
  end

  def dump_inspect(io, terse_output : Bool = false) : Nil
    dump_inspect(io, terse_output, 0)
    io << "\n"
  end

  def dump_std(terse_output : Bool = false)
    dump_inspect(STDOUT, terse_output)
  end

end

def dump(code : String, terse_output : Bool = false)
  parser = Crystal::Parser.new(code)
  parser.parse.dump_inspect(STDOUT, terse_output)
end

def dump(node : Crystal::ASTNode, terse_output : Bool = false)
  node.dump_inspect(STDOUT, terse_output)
end
