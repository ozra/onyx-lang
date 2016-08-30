require "html"
require "uri"
require "./item"

class Crystal::Doc::Method
  include Item

  getter type : Type
  getter def : Def

  def initialize(@generator : Generator, @type : Type, @def : Def, @class_method : Bool)
  end

  def name
    @def.name.gsub(/_/, '-') # + "__M" # *TODO* reverse-babeling if needed!
  end

  def args
    @def.args
  end

  def doc
    @def.doc
  end

  def source_link
    @generator.source_link(@def)
  end

  def prefix
    case
    when @type.program?
      ""
    when @class_method
      "."
    else
      ""
    end
  end

  def abstract?
    @def.abstract?
  end

  def kind
    case
    when @type.program?
      :program_method
    when @class_method
      :class_method
    else
      :instance_method
    end
  end

  def id
    String.build do |io|
      io << to_s.gsub(/<.+?>/, "").gsub(' ', "")
      if @class_method
        io << "-class-method"
      else
        io << "-instance-method"
      end
    end
  end

  def html_id
    HTML.escape(id)
  end

  def anchor
    "#" + URI.escape(id)
  end

  def to_s(io)
    io << name
    args_to_s io
  end

  def args_to_s
    String.build { |io| args_to_s io }
  end

  def args_to_s(io)
    args_to_html(io, links: false)
  end

  def args_to_html
    String.build { |io| args_to_html io }
  end

  def args_to_html(io, links = true)
    return_type = @def.return_type

    # If the def's body is a single instance variable, we include
    # a return type since instance vars must have a fixed/guessed type,
    # so docs will be better and easier to navigate.
    if !return_type && (body = @def.body).is_a?(InstanceVar)
      owner = type.type
      if owner.is_a?(NonGenericClassType)
        ivar = owner.lookup_instance_var?(body.name)
        return_type = ivar.try &.type?
      end
    end

    # return unless has_args? || return_type

    if has_args?
      io << '('

      printed = false
      @def.args.each_with_index do |arg, i|
        html_comma_if printed, links, io
        if @def.splat_index == i
          html_class_if links, "separator", "...", io
        end
        arg_to_html arg, io, links: links
        printed = true
      end
      if double_splat = @def.double_splat
        html_comma_if printed, links, io
        html_class_if links, "separator", "..:", io
        io << double_splat
        printed = true
      end

      if block_arg = @def.block_arg
        html_comma_if printed, links, io
        html_class_if links, "separator", "\\", io
        arg_to_html block_arg, io, links: links

      elsif @def.yields
        html_comma_if printed, links, io
        html_class_if links, "separator", "\\", io
        html_class_if links, "arg-name", "fragment", io
      end

      io << ')'

    else
      io << "()"
    end

    io << "&nbsp;-&gt;"

    case return_type
    when ASTNode
      io << "&nbsp;"
      io << "<span class=\"type-name\">" if links
      node_to_html return_type, io, links: links
      io << "</span>" if links
    when Crystal::Type
      io << "&nbsp;"
      io << "<span class=\"type-name\">" if links
      @type.type_to_html return_type, io, links: links
      io << "</span>" if links
    end

    io
  end

  def html_class_if(cond, cls, text, io)
    if cond
      io << "<span class=\""
      io << cls
      io << "\">"
    end
    io << text
    if cond
      io << "</span>"
    end
    nil
  end

  def html_comma_if(cond, decorate, io)
    if cond
      io << "<span class=\"separator\">" if decorate
      io << ", "
      io << "</span>" if decorate
    end
    nil
  end

  def arg_to_html(arg : Arg, io, links = true)
    if arg.external_name != arg.name
      io << (arg.external_name.empty? ? "_" : arg.external_name.gsub(/_/, "-"))
      io << " "
    end

    io << "<span class=\"arg-name\">"
    io << arg.name.gsub(/_/, "-")
    io << "</span>"

    if restriction = arg.restriction
      io << " "
      io << "<span class=\"type-name\">"
      node_to_html restriction, io, links: links
      io << "</span>"
    elsif type = arg.type?
      io << " "
      io << "<span class=\"type-name\">"
      @type.type_to_html type, io, links: links
      io << "</span>"
    end
    if default_value = arg.default_value
      io << "<span class=\"default-value\">"
      io << " = "
      # io << Highlighter.highlight(default_value.to_s)
      io << default_value.to_oxs
      io << "</span>"
    end
  end

  def node_to_html(node, io, links = true)
    @type.node_to_html node, io, links: links
  end

  def must_be_included?
    @generator.must_include? @def
  end

  def has_args?
    !@def.args.empty? || @def.block_arg || @def.yields
  end
end
