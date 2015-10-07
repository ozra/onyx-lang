require "set"
require "../../crystal/syntax/parser"

module Crystal

# This to_s is part of code generation - messes shit up!
# class Token
#     def to_s(io)
#       if @value
#         @type.to_s(io)
#         ":".to_s(io)
#         @value.to_s(io)
#       else
#         @type.to_s(io)
#       end
#     end
# end

class Scope
  property :name

  def initialize(@vars = Set(String).new)
  end

  def includes?(name)
    @vars.includes? name
  end

  def add(name)
    @vars.add name
  end

  def dup()
    Scope.new @vars
  end
end

class ScopeStack
  @scopes = Array(Scope).new
  @current_scope = Scope.new # ugly way of avoiding null checks

  def initialize()
    push_fresh_scope()
  end

  def cur_has?(name)
    @scopes.last.includes? name
  end

  def last()
    @current_scope
  end

  def pop_scope()
    @scopes.pop()
    @current_scope = @scopes.last
  end

  def push_scope(scope : Scope)
    @scopes.push scope
    @current_scope = scope
  end

  def push_fresh_scope()
    push_scope Scope.new
  end

  def push_scope()
    push_scope @scopes.last.dup
  end

  def add_var(name : String)
    @current_scope.add name
  end

end

class Nesting
  property nest_kind
  property indent
  property name
  property require_end_token

  # CURRENTLY _47_ DIFFERENT NESTING CONTROL KEYWORDS (MANY BEING REDUNDANT
  # BECAUSE OF SYNTAX EXPERIMENT) - that's a lot. But.. they will be reduced by
  # public opinion.
  @@nesting_keywords = %w(
    program module
    type enum class struct
    alias
    def fun block lambda
    template macro

    lib api
    apidef cfun cstruct cunion cenum
    union ctype calias

    => do then
    where
    scope scoped contain contained

    if ifdef unless else
    elif elsif
    case when

    while until for each loop

    try rescue catch ensure
    begin
  )

  def self.nesting_keywords
    @@nesting_keywords
  end

  def initialize(@nest_kind, @indent, @name, @require_end_token)
    if ! Nesting.nesting_keywords.includes? @nest_kind.to_s
      raise "Shit went down - don't know about nesting kind '#{@nest_kind.to_s}'"
    end
  end

  def message_expected_end_tokens()
    case @nest_kind
    when :program then "EOF"
    when :module then "end or end-module"
    when :if then "end or end-if"
    when :try then "catch, end or end-try"
    else "end or end-" + @nest_kind.to_s
    end
  end

  def match_end_token(end_token)
    case @nest_kind
    when :program
      end_token == :EOF
    when :if
      end_token == "else" || end_token == "end" || end_token == "end-if"
    when :try
      end_token == "catch" || end_token == "ensure" || end_token == "end" || end_token == "end-try"
    else
      end_token == "end" || end_token.to_s == ("end-" + @nest_kind.to_s) # *TODO* (-|–|_)
    end
  end
end

class NestingStack
  @stack :: Array(Nesting)

  def initialize()
    @stack = [Nesting.new(:program, -1, "", false)]
  end

  def add(kind, indent, match_name, require_end_token)
    @stack.push Nesting.new kind, indent, match_name, require_end_token
  end

  def last
    @stack.last
  end

  def pop_and_status(indent)
    @stack.pop

    if indent <= @stack.last.indent
      #p @stack.to_s
      :more
    else
      :done
    end
  end

  def dedent(indent : Int32, end_token : String, match_name : String) : Symbol
    # while true
    nest = @stack.last
    if indent < nest.indent
      p "indents left to match alignment in nest_stack:"
      (@stack.size - 1 .. 0).each do |i|

        p @stack[i].indent
        # *TODO*
        # check so that the indent–level EXISTS further up (we don't allow dedent
        # to an "unspecified level" (in between)
      end

      return pop_and_status indent

    elsif nest.indent == indent

      case
      when end_token == ""
        return pop_and_status indent

      when nest.match_end_token end_token
        if match_name == ""
          return pop_and_status indent
        elsif nest.name == match_name
          return pop_and_status indent
        else
          raise "explicit end-token \"#{ (end_token.to_s + " " + match_name).strip }\"" \
                " doesn't match expected" \
                " \"#{ (nest.message_expected_end_tokens + " " + nest.name).strip }\""
        end

      else
        raise "explicit end-token name \"#{ match_name }\"" \
              " doesn't match expected \"#{ nest.name }\""
      end

    else
      return :"false"   # NOTE! SYMBOL :false
    end
    # end
  end

  def dbgstack
    ret = "NEST-STACK:\n"
    @stack.each do |v|
      ret += "'" + v.nest_kind.to_s + "', " + v.indent.to_s + " " + v.name.to_s + "\n"
    end
    ret += "\n"
    ret
  end

end

class OnyxParser < OnyxLexer
  record Unclosed, name, location

  property visibility
  property def_nest
  property type_nest
  getter? wants_doc

  def self.parse(str, scope_stack = ScopeStack.new)
    new(str, scope_stack).parse
  end

  def initialize(str, @scope_stack = ScopeStack.new)
    super(str)
    @last_call_has_parenthesis = true
    @temp_token = Token.new
    @calls_super = false
    @calls_initialize = false
    @uses_block_arg = false
    @assigns_special_var = false
    @def_nest = 0
    @type_nest = 0

    @oneline_nest = 0
    #@paren_nest = 0 *TODO* *TEST* in lexer now

    @block_arg_count = 0
    @in_macro_expression = false
    @stop_on_yield = 0
    @inside_c_struct = false
    @wants_doc = false

    @unclosed_stack = [] of Unclosed
    @nesting_stack = NestingStack.new

    @dbgindent__ = 0

  end

  def wants_doc=(@wants_doc)
    @doc_enabled = @wants_doc
  end

  def parse
    next_token_skip_statement_end

    expressions = parse_expressions.tap { check :EOF }

    check :EOF

    expressions
  end



  def parse_expressions
    dbg "parse_expressions"
    dbginc
    if is_end_token   # "stop tokens" - not _blockend tokens_ - unless explicit
      return Nop.new
    end

    # *TODO* refactor loop vs before
    # *TODO* new lines should probably be handled at _end_ of parsings, leaving
    # clean slate for next
    # Just do a specific newline skip at BOF!

    if @oneline_nest == 0
      skip_space_newline_semi
    else
      skip_space_semi
    end

    exp = parse_expression

    slash_is_regex!

    exps = [] of ASTNode
    exps.push exp

    loop do
      dbg "parse_expressions() >>> LOOP TOP >>>"

      if @oneline_nest == 0
        skip_space_newline_semi
      else
        skip_space_semi
      end

      #if !got_updent
      #  got_updent = handle_updent

      if handle_blockend
        dbg "handled dedent in parse_expressions:loop"


        # *TODO* we must still have end–token here so parse_expression doesn't parse suffix!

        break

      elsif is_end_token
        dbg "break on is_end_token in parse_expressions:loop"
        break
      end


      if @oneline_nest == 0
        skip_space_newline_semi
      else
        skip_space_semi
      end



      exps << parse_expression # parse_multi_assign
      skip_statement_end
    end

    Expressions.from exps

  ensure
    dbgdec

  end



  def parse_multi_assign(assignees)
    dbg "parse_multi_assign - get location"
    location = assignees.location.not_nil!


    # *TODO*
    # - extend with [a, _, _, b, ..., c, d] notation
    # (- optimize away temps for literals by assigning immediately)


    dbg "parse_multi_assign - check assign"
    check :"="
    next_token_skip_space_or_newline

    exps = assignees.elements

    if (source = parse_expression).is_a? ArrayLiteral
      values = source.elements
    else
      values = [source]
    end

    targets = exps.map { |exp| to_lhs(exp) }
    if ivars = @instance_vars
      targets.each do |target|
        ivars.add target.name if target.is_a?(InstanceVar)
      end
    end

    if values.size != 1 && targets.size != 1 && targets.size != values.size
      raise "Multiple assignment count mismatch", location
    end

    multi = MultiAssign.new(targets, values).at(location)

    dbg "Multi to_s: " + multi.to_s

    parse_expression_suffix multi, @token.location
  end

  def to_lhs(exp)
    if exp.is_a?(Path) && inside_def?
      raise "dynamic constant assignment"
    end

    if exp.is_a?(Call) && !exp.obj && exp.args.empty?
      exp = Var.new(exp.name).at(exp)
    end
    if exp.is_a?(Var)
      if exp.name == "self"
        raise "can't change the value of self", exp.location.not_nil!
      end
      add_var exp
    end
    exp
  end

  def parse_expression
    dbg "parse_expression"
    dbginc

    location = @token.location

    # *TODO* not in AST yet...
    # if token? :COMMENT
    #   # *TODO* this is needed for formatting tools using the AST!
    #   next_token_skip_space_or_newline
    # end

    # *TODO* *TEST*
    skip_space_newline_semi


    atomic = parse_op_assign
    dbg "parse_expression - after atomic - before suffix"
    parse_expression_suffix atomic, location

  ensure
    dbgdec

  end

  def parse_expression_suffix(atomic, location)
    dbg "parse_expression_suffix"
    dbginc
    while true
      case @token.type
      when :SPACE
        next_token
      when :IDENT
        case @token.value
        when :if
          atomic = parse_expression_suffix(location) { |exp| If.new(exp, atomic) }
        when :unless
          atomic = parse_expression_suffix(location) { |exp| Unless.new(exp, atomic) }
        when :while
          raise "trailing `while` is not supported", @token
        when :until
          raise "trailing `until` is not supported", @token
        when :rescue
          next_token_skip_space
          rescue_body = parse_expression
          rescues = [Rescue.new(rescue_body)] of Rescue
          if atomic.is_a?(Assign)
            atomic.value = ExceptionHandler.new(atomic.value, rescues).at(location)
          else
            atomic = ExceptionHandler.new(atomic, rescues).at(location)
          end
        when :ensure
          next_token_skip_space
          ensure_body = parse_expression
          if atomic.is_a?(Assign)
            atomic.value = ExceptionHandler.new(atomic.value, ensure: ensure_body).at(location)
          else
            atomic = ExceptionHandler.new(atomic, ensure: ensure_body).at(location)
          end
        when :ifdef
          next_token_skip_statement_end
          exp = parse_flags_or
          atomic = IfDef.new(exp, atomic).at(location)
        else
          break
        end
      when :")", :",", :";", :"%}", :"}}", :NEWLINE, :EOF, :DEDENT
        # *TODO* skip explicit end token
        break
      else
        if is_end_token
          break
        else
          unexpected_token
        end
      end
    end
    atomic
  ensure
    dbgdec
  end

  def parse_expression_suffix(location)
    next_token_skip_statement_end
    exp = parse_op_assign_no_control
    (yield exp).at(location).at_end(exp)
  end

  def parse_op_assign_no_control(allow_ops = true, allow_suffix = true)
    check_void_expression_keyword
    parse_op_assign(allow_ops, allow_suffix)
  end

  def mutate_gt_op_to_bigger_op?
    # Check if we're gonna mutate the token to a "larger one"
    if token? :">"
      if current_char == '>'
        next_token
        if current_char == '='
          next_token
          @token.type = :">>="
        else
          @token.type = :">>"
        end
      end
    end
  end

  def parse_op_assign(allow_ops = true, allow_suffix = true)
    dbg "parse_op_assign"
    doc = @token.doc
    location = @token.location

    dbg "before maybe_skip_anydents"
    maybe_skip_anydents
    dbg "after maybe_skip_anydents"

    #atomic = parse_question_colon
    atomic = parse_range

    while true
      maybe_skip_anydents
      mutate_gt_op_to_bigger_op?

      case @token.type
      when :SPACE
        next_token
        next
      when :IDENT
        unexpected_token unless allow_suffix
        break
      when :"="
        slash_is_regex!

        if atomic.is_a?(Call) && atomic.name == "[]"
          next_token_skip_space_or_newline

          atomic.name = "[]="
          atomic.name_size = 0
          atomic.args << parse_op_assign_no_control
        else
          break unless can_be_assigned?(atomic)

          if atomic.is_a?(Path) && inside_def?
            raise "dynamic constant assignment"
          end

          if atomic.is_a?(Var) && atomic.name == "self"
            raise "can't change the value of self", location
          end

          atomic = Var.new(atomic.name) if atomic.is_a?(Call)

          next_token_skip_space_or_newline

          # Constants need a new scope for their value
          case atomic
          when Path
            needs_new_scope = true
          when InstanceVar
            needs_new_scope = @def_nest == 0
          when Var
            @assigns_special_var = true if atomic.special_var?
          else
            needs_new_scope = false
          end

          push_fresh_scope if needs_new_scope
          value = parse_op_assign_no_control
          pop_scope if needs_new_scope

          add_var atomic

          atomic = Assign.new(atomic, value).at(location)
          atomic.doc = doc
          atomic
        end
      when :"+=", :"-=", :"*=", :"/=", :"%=", :"|=", :"&=", :"^=", :"**=", :"<<=", :">>=", :"||=", :"&&="
        # Rewrite 'a += b' as 'a = a + b'

        unexpected_token unless allow_ops

        break unless can_be_assigned?(atomic)

        if atomic.is_a?(Path)
          raise "can't reassign to constant"
        end

        if atomic.is_a?(Var) && atomic.name == "self"
          raise "can't change the value of self", location
        end

        if atomic.is_a?(Call) && atomic.name != "[]" && !@scope_stack.cur_has?(atomic.name)
          raise "'#{@token.type}' before definition of '#{atomic.name}'"

          atomic = Var.new(atomic.name)
        end

        add_var atomic

        method = @token.type.to_s.byte_slice(0, @token.to_s.bytesize - 1)
        method_column_number = @token.column_number

        token_type = @token.type

        next_token_skip_space_or_newline

        value = parse_op_assign_no_control

        if atomic.is_a?(Call) && atomic.name == "[]"
          obj = atomic.obj
          atomic_clone = atomic.clone

          case token_type
          when :"&&="
            atomic.args.push value
            assign = Call.new(obj, "[]=", atomic.args, name_column_number: method_column_number).at(location)
            fetch = atomic_clone
            fetch.name = "[]?"
            atomic = And.new(fetch, assign).at(location)
          when :"||="
            atomic.args.push value
            assign = Call.new(obj, "[]=", atomic.args, name_column_number: method_column_number).at(location)
            fetch = atomic_clone
            fetch.name = "[]?"
            atomic = Or.new(fetch, assign).at(location)
          else
            call = Call.new(atomic_clone, method, [value] of ASTNode, name_column_number: method_column_number).at(location)
            atomic.args.push call
            atomic = Call.new(obj, "[]=", atomic.args, name_column_number: method_column_number).at(location)
          end
        else
          case token_type
          when :"&&="
            if (ivars = @instance_vars) && atomic.is_a?(InstanceVar)
              ivars.add atomic.name
            end

            assign = Assign.new(atomic, value).at(location)
            atomic = And.new(atomic.clone, assign).at(location)
          when :"||="
            if (ivars = @instance_vars) && atomic.is_a?(InstanceVar)
              ivars.add atomic.name
            end

            assign = Assign.new(atomic, value).at(location)
            atomic = Or.new(atomic.clone, assign).at(location)
          else
            call = Call.new(atomic, method, [value] of ASTNode, name_column_number: method_column_number).at(location)
            atomic = Assign.new(atomic.clone, call).at(location)
          end
        end
      else
        break
      end
      allow_ops = true
    end

    atomic
  end



  # *TODO* - remove ternary!!!

  # ColonOrNewline = [:":", :NEWLINE]

  # def parse_question_colon
  #   cond = parse_range

  #   while @token.type == :"?"
  #     location = @token.location

  #     check_void_value cond, location

  #     next_token_skip_space_or_newline
  #     next_token_skip_space_or_newline if @token.type == :":"
  #     true_val = parse_question_colon

  #     check ColonOrNewline

  #     next_token_skip_space_or_newline
  #     next_token_skip_space_or_newline if @token.type == :":"
  #     false_val = parse_question_colon

  #     cond = If.new(cond, true_val, false_val)
  #   end
  #   cond
  # end



  def parse_range
    location = @token.location
    exp = parse_or
    while true
      case @token.type
      when :".."
        exp = new_range(exp, location, false)
      when :"..."
        exp = new_range(exp, location, true)
      else
        return exp
      end
    end
  end

  def new_range(exp, location, exclusive)
    check_void_value exp, location
    next_token_skip_space_or_newline
    check_void_expression_keyword
    right = parse_or
    RangeLiteral.new(exp, right, exclusive).at(location).at_end(right)
  end

  macro parse_operator(name, next_operator, node, operators)
    def parse_{{name.id}}
      location = @token.location

      left = parse_{{next_operator.id}}
      while true
        case @token.type
        when :SPACE
          next_token
        when {{operators.id}}
          check_void_value left, location

          method = @token.type.to_s
          method_column_number = @token.column_number

          slash_is_regex!
          next_token_skip_space_or_newline
          right = parse_{{next_operator.id}}
          left = ({{node.id}}).at(location)
        else
          return left
        end
      end
    end
  end

  parse_operator :or, :and, "Or.new left, right", ":\"||\""
  parse_operator :and, :equality, "And.new left, right", ":\"&&\""
  parse_operator :equality, :cmp, "Call.new left, method, [right] of ASTNode, name_column_number: method_column_number", ":\"<\", :\"<=\", :\">\", :\">=\", :\"<=>\""
  parse_operator :cmp, :logical_or, "Call.new left, method, [right] of ASTNode, name_column_number: method_column_number", ":\"==\", :\"!=\", :\"=~\", :\"===\""
  parse_operator :logical_or, :logical_and, "Call.new left, method, [right] of ASTNode, name_column_number: method_column_number", ":\"|\", :\"^\""
  parse_operator :logical_and, :shift, "Call.new left, method, [right] of ASTNode, name_column_number: method_column_number", ":\"&\""
  parse_operator :shift, :add_or_sub, "Call.new left, method, [right] of ASTNode, name_column_number: method_column_number", ":\"<<\", :\">>\""

  def parse_add_or_sub
    location = @token.location

    left = parse_mul_or_div
    while true
      case @token.type
      when :SPACE
        next_token
      when :"+", :"-"
        check_void_value left, location

        method = @token.type.to_s
        method_column_number = @token.column_number
        next_token_skip_space_or_newline
        right = parse_mul_or_div
        left = Call.new(left, method, [right] of ASTNode, name_column_number: method_column_number).at(location)
      when :NUMBER
        case char = @token.value.to_s[0]
        when '+', '-'
          left = Call.new(left, char.to_s, [NumberLiteral.new(@token.value.to_s.byte_slice(1), @token.number_kind)] of ASTNode, name_column_number: @token.column_number).at(location)
          next_token_skip_space
        else
          return left
        end
      else
        return left
      end
    end
  end

  parse_operator :mul_or_div, :prefix, "Call.new left, method, [right] of ASTNode, name_column_number: method_column_number", ":\"*\", :\"/\", :\"%\""

  def parse_prefix
    column_number = @token.column_number
    case token_type = @token.type
    when :"!", :"+", :"-", :"~"
      location = @token.location
      next_token_skip_space_or_newline
      check_void_expression_keyword
      arg = parse_prefix
      Call.new(arg, token_type.to_s, name_column_number: column_number).at(location).at_end(arg)
    else
      parse_pow
    end
  end

  parse_operator :pow, :atomic_with_method, "Call.new left, method, [right] of ASTNode, name_column_number: method_column_number", ":\"**\""

  AtomicWithMethodCheck = [:IDENT, :"+", :"-", :"*", :"/", :"%", :"|", :"&", :"^", :"**", :"<<", :"<", :"<=", :"==", :"!=", :"=~", :">>", :">", :">=", :"<=>", :"||", :"&&", :"===", :"[]", :"[]=", :"[]?", :"!"]

  def parse_atomic_with_method
    location = @token.location
    atomic = parse_atomic
    parse_atomic_method_suffix atomic, location
  end

  def parse_atomic_method_suffix(atomic, location)
    while true
      mutate_gt_op_to_bigger_op?

      case @token.type
      when :SPACE
        next_token
      when :IDENT
        if @token.keyword?(:as)
          check_void_value atomic, location

          next_token_skip_space
          to = parse_single_type
          atomic = Cast.new(atomic, to).at(location)
        else
          break
        end
      when :NEWLINE
        # In these cases we don't want to chain a call
        case atomic
        when ClassDef, ModuleDef, EnumDef, FunDef, Def
          break
        end

        # Allow '.' after newline for chaining calls
        old_pos, old_line, old_column = current_pos, @line_number, @column_number
        @temp_token.copy_from @token
        next_token_skip_space_or_newline
        unless @token.type == :"."
          self.current_pos, @line_number, @column_number =
                                                  old_pos, old_line, old_column
          @token.copy_from @temp_token
          break
        end
      when :"."
        atomic = parse_atomic_method_suffix_dot atomic, location
      when :"[]"
        check_void_value atomic, location

        column_number = @token.column_number
        next_token_skip_space
        atomic = Call.new(atomic, "[]",
                          name_column_number: column_number
                         ).at(location)
        atomic.name_size = 0 if atomic.is_a?(Call)
        atomic
      when :"["
        check_void_value atomic, location

        column_number = @token.column_number
        next_token_skip_space_or_newline
        args = [] of ASTNode
        while true
          args << parse_single_arg
          skip_space_newline_or_indent
          case @token.type
          when :","
            next_token_skip_space_or_newline
            if @token.type == :"]"
              next_token
              break
            end
          when :"]"
            next_token
            break
          end
        end

        if @token.type == :"?"
          method_name = "[]?"
          next_token_skip_space
        else
          method_name = "[]"
          skip_space
        end

        atomic = Call.new(atomic, method_name, args,
                          name_column_number: column_number
                         ).at(location)
        atomic.name_size = 0 if atomic.is_a?(Call)
        atomic
      else
        break
      end
    end

    atomic
  end

  def parse_atomic_method_suffix_dot(atomic, location)
    check_void_value atomic, location

    @wants_regex = false

    if current_char == '%'
      next_char
      @token.type = :"%"
      @token.column_number += 1
      skip_space_newline_or_indent
    else
      next_token_skip_space_or_newline

      if @token.type == :INSTANCE_VAR
        ivar_name = @token.value.to_s
        end_location = token_end_location
        next_token_skip_space

        atomic = ReadInstanceVar.new(atomic, ivar_name).at(location)
        atomic.end_location = end_location
        return atomic
      end
    end

    check AtomicWithMethodCheck
    name_column_number = @token.column_number

    if @token.value == :is_a?
      atomic = parse_is_a(atomic).at(location)
    elsif @token.value == :responds_to?
      atomic = parse_responds_to(atomic).at(location)
    else
      name = @token.type == :IDENT ? @token.value.to_s : @token.type.to_s
      end_location = token_end_location

      @wants_regex = false
      next_token

      space_consumed = false
      if @token.type == :SPACE
        @wants_regex = true
        next_token
        space_consumed = true
      end

      case @token.type
      when :"="
        # Rewrite 'f.x = arg' as f.x=(arg)
        next_token
        if @token.type == :"("
          next_token_skip_space
          arg = parse_single_arg
          check :")"
          next_token
        else
          skip_space_newline_or_indent
          arg = parse_single_arg
        end
        return Call.new(atomic, "#{name}=", [arg] of ASTNode, name_column_number: name_column_number).at(location)

      when :"+=", :"-=", :"*=", :"/=", :"%=", :"|=", :"&=", :"^=", :"**=", :"<<=", :">>="
        # Rewrite 'f.x += value' as 'f.x=(f.x + value)'
        method = @token.type.to_s.byte_slice(0, @token.type.to_s.size - 1)
        next_token_skip_space
        value = parse_op_assign
        return Call.new(atomic, "#{name}=", [Call.new(Call.new(atomic.clone, name, name_column_number: name_column_number), method, [value] of ASTNode, name_column_number: name_column_number)] of ASTNode, name_column_number: name_column_number).at(location)
      when :"||="
        # Rewrite 'f.x ||= value' as 'f.x || f.x=(value)'
        next_token_skip_space
        value = parse_op_assign
        return Or.new(
            Call.new(atomic, name).at(location),
            Call.new(atomic.clone, "#{name}=", value).at(location)
          ).at(location)
      when :"&&="
        # Rewrite 'f.x &&= value' as 'f.x && f.x=(value)'
        next_token_skip_space
        value = parse_op_assign
        return And.new(
            Call.new(atomic, name).at(location),
            Call.new(atomic.clone, "#{name}=", value).at(location)
          ).at(location)
      else
        call_args, last_call_has_parenthesis = (
          preserve_last_call_has_parenthesis {
            space_consumed ?
              parse_call_args_space_consumed :
              parse_call_args
          }
        )
        if call_args
          args = call_args.args
          block = call_args.block
          block_arg = call_args.block_arg
          named_args = call_args.named_args
        else
          args = block = block_arg = nil
        end
      end

      block = parse_block(block)
      if block || block_arg
        atomic = Call.new(atomic, name, (args || [] of ASTNode), block,
                          block_arg, named_args,
                          name_column_number: name_column_number
                         )
      else
        atomic = args ? (Call.new atomic, name, args, named_args: named_args, name_column_number: name_column_number) : (Call.new atomic, name, name_column_number: name_column_number)
      end
      atomic.end_location = call_args.try(&.end_location) || block.try(&.end_location) || end_location
      atomic.at(location)
      return atomic
    end
    return atomic
  end

  def parse_single_arg
    if @token.type == :"..."
      next_token_skip_space
      arg = parse_op_assign_no_control
      Splat.new(arg)
    else
      parse_op_assign_no_control
    end
  end

  def parse_is_a(atomic)
    next_token_skip_space

    if @token.type == :"("
      next_token_skip_space_or_newline
      type = parse_single_type
      skip_space
      check :")"
      next_token_skip_space
    else
      type = parse_single_type
    end

    IsA.new(atomic, type)
  end

  def parse_responds_to(atomic)
    next_token

    if @token.type == :"("
      next_token_skip_space_or_newline
      name = parse_responds_to_name
      next_token_skip_space_or_newline
      check :")"
      next_token_skip_space
    elsif @token.type == :SPACE
      next_token
      name = parse_responds_to_name
      next_token_skip_space
    end

    RespondsTo.new(atomic, name)
  end

  def parse_responds_to_name
    if @token.type != :SYMBOL
      unexpected_token msg: "expected name or symbol"
    end

    @token.value.to_s
  end

  def parse_atomic
    location = @token.location
    atomic = parse_atomic_without_location
    atomic.location ||= location
    atomic
  end

  def parse_atomic_without_location
    case @token.type
    when :"("
      parse_parenthesized_expression
    when :"[]"
      parse_empty_array_literal
    when :"["
      parse_array_literal_or_multi_assign
    when :"{"
      parse_hash_or_tuple_literal
    when :"{{"
      macro_exp = parse_macro_expression
      check_macro_expression_end
      next_token
      MacroExpression.new(macro_exp)
    when :"{%"
      macro_control = parse_macro_control(@line_number, @column_number)
      if macro_control
        check :"%}"
        next_token_skip_space
        macro_control
      else
        unexpected_token_in_atomic
      end
    when :"::"
      parse_ident_or_global_call

    #when :"->"
    #  parse_fun_literal

    when :"@["
      parse_attribute
    when :NUMBER
      @wants_regex = false
      node_and_next_token NumberLiteral.new(@token.value.to_s, @token.number_kind)
    when :CHAR
      node_and_next_token CharLiteral.new(@token.value as Char)
    when :STRING, :DELIMITER_START
      parse_delimiter
    when :STRING_ARRAY_START
      parse_string_array
    when :SYMBOL_ARRAY_START
      parse_symbol_array
    when :SYMBOL
      node_and_next_token SymbolLiteral.new(@token.value.to_s)
    when :GLOBAL
      @wants_regex = false
      node_and_next_token Global.new(@token.value.to_s)
    when :"$~", :"$?"
      location = @token.location
      var = Var.new(@token.to_s).at(location)

      old_pos, old_line, old_column = current_pos, @line_number, @column_number
      @temp_token.copy_from(@token)

      next_token_skip_space

      if @token.type == :"="
        @token.copy_from(@temp_token)
        self.current_pos, @line_number, @column_number = old_pos, old_line, old_column

        add_var var
        node_and_next_token var
      else
        @token.copy_from(@temp_token)
        self.current_pos, @line_number, @column_number = old_pos, old_line, old_column

        node_and_next_token Call.new(var, "not_nil!").at(location)
      end
    when :GLOBAL_MATCH_DATA_INDEX
      value = @token.value.to_s
      if value == "0"
        node_and_next_token Path.global("PROGRAM_NAME")
      else
        if value.ends_with? '?'
          method = "[]?"
          value = value.chop
        else
          method = "[]"
        end
        location = @token.location
        node_and_next_token Call.new(Call.new(Var.new("$~").at(location), "not_nil!").at(location), method, NumberLiteral.new(value.to_i))
      end
    when :__LINE__
      node_and_next_token MagicConstant.expand_line_node(@token.location)
    when :__FILE__
      node_and_next_token MagicConstant.expand_file_node(@token.location)
    when :__DIR__
      node_and_next_token MagicConstant.expand_dir_node(@token.location)
    when :IDENT
      case @token.value
      when :begin
        parse_begin
      when :nil
        node_and_next_token NilLiteral.new
      when :true
        node_and_next_token BoolLiteral.new(true)
      when :false
        node_and_next_token BoolLiteral.new(false)
      when :yield
        parse_yield
      when :with
        parse_yield_with_scope
      when :abstract
        check_not_inside_def("can't use abstract inside def") do
          doc = @token.doc

          next_token_skip_space_or_newline
          case @token.type
          when :IDENT
            case @token.value
            when :def
              parse_def is_abstract: true, doc: doc
            when :type
              parse_class_def is_abstract: true, doc: doc
            when :class
              parse_class_def is_abstract: true, doc: doc
            when :struct
              parse_class_def is_abstract: true, is_struct: true, doc: doc
            else
              unexpected_token
            end
          else
            unexpected_token
          end
        end
      when :def
        # *TODO* create "owningdefname__private_def__thisdefname"
        # - do this for the whole hierarchy of defs ofc. (if more)
        check_not_inside_def("can't define def inside def") do
          parse_def
        end
      when :macro
        # *TODO* create "owningdefname__private_macro__thisdefname"
        # - do this for the whole hierarchy of defs ofc. (if more)
        check_not_inside_def("can't define macro inside def") do
          parse_macro
        end
      when :require
        parse_require
      when :case
        parse_case
      when :if
        parse_if
      when :ifdef
        parse_ifdef
      when :unless
        parse_unless
      when :include
        check_not_inside_def("can't include inside def") do
          parse_include
        end
      when :extend
        check_not_inside_def("can't extend inside def") do
          parse_extend
        end
      when :type
        check_not_inside_def("can't define class inside def") do
          parse_class_def
        end
      when :class
        check_not_inside_def("can't define class inside def") do
          parse_class_def
        end
      when :struct
        check_not_inside_def("can't define struct inside def") do
          parse_class_def is_struct: true
        end
      when :module
        check_not_inside_def("can't define module inside def") do
          parse_module_def
        end
      when :enum
        check_not_inside_def("can't define enum inside def") do
          parse_enum_def
        end
      when :while
        parse_while
      when :until
        parse_until
      when :return
        parse_return
      when :next
        parse_next
      when :break
        parse_break
      when :lib
        check_not_inside_def("can't define lib inside def") do
          parse_lib
        end
      when :fun
        check_not_inside_def("can't define fun inside def") do
          parse_fun_def require_body: true
        end
      when :alias
        check_not_inside_def("can't define alias inside def") do
          parse_alias
        end
      when :pointerof
        parse_pointerof
      when :sizeof
        parse_sizeof
      when :instance_sizeof
        parse_instance_sizeof
      when :typeof
        parse_typeof
      when :private
        parse_visibility_modifier :private
      when :protected
        parse_visibility_modifier :protected
      when :asm
        parse_asm
      else
        set_visibility parse_var_or_call
      end
    when :CONST
      parse_ident_or_literal
    when :INSTANCE_VAR
      name = @token.value.to_s
      add_instance_var name
      ivar = InstanceVar.new(name).at(@token.location)
      ivar.end_location = token_end_location
      @wants_regex = false
      next_token_skip_space

      if @token.type == :"::"
        next_token_skip_space
        ivar_type = parse_single_type
        DeclareVar.new(ivar, ivar_type).at(ivar.location)
      else
        ivar
      end
    when :CLASS_VAR
      @wants_regex = false
      node_and_next_token ClassVar.new(@token.value.to_s)
    when :UNDERSCORE
      node_and_next_token Underscore.new
    else
      unexpected_token_in_atomic
    end
  end

  def parse_ident_or_literal
    ident = parse_ident
    skip_space

    if @token.type == :"{"
      tuple_or_hash = parse_hash_or_tuple_literal allow_of: false

      skip_space

      if @token.keyword?(:"of")
        unexpected_token
      end

      case tuple_or_hash
      when TupleLiteral
        ary = ArrayLiteral.new(tuple_or_hash.elements, name: ident).at(tuple_or_hash.location)
        return ary
      when HashLiteral
        tuple_or_hash.name = ident
        return tuple_or_hash
      else
        raise "Bug: tuple_or_hash should be tuple or hash, not #{tuple_or_hash}"
      end
    end
    ident
  end

  def check_not_inside_def(message)
    if @def_nest == 0
      yield
    else
      raise message, @token.line_number, @token.column_number
    end
  end

  def inside_def?
    @def_nest > 0
  end

  def parse_attribute
    doc = @token.doc

    next_token_skip_space
    name = check_const
    next_token_skip_space

    args = [] of ASTNode
    named_args = nil

    if @token.type == :"("
      open("attribute") do
        next_token_skip_space_or_newline
        while @token.type != :")"
          if @token.type == :IDENT && current_char == ':'
            named_args = parse_named_args(allow_newline: true)
            check :")"
            break
          else
            args << parse_call_arg
          end

          skip_space_newline_or_indent
          if @token.type == :","
            next_token_skip_space_or_newline
          end
        end
        next_token_skip_space
      end
    end
    check :"]"
    next_token_skip_space

    attr = Attribute.new(name, args, named_args)
    attr.doc = doc
    attr
  end

  def parse_begin
    slash_is_regex!
    next_token_skip_statement_end
    exps = parse_expressions
    exps2 = Expressions.new([exps] of ASTNode).at(exps)
    node, end_location = parse_exception_handler exps
    node.end_location = end_location
    node
  end



  def parse_exception_handler(exp)
    rescues = nil
    a_else = nil
    a_ensure = nil

    if @token.keyword?(:rescue)
      rescues = [] of Rescue
      found_catch_all = false
      while true
        location = @token.location
        a_rescue = parse_rescue
        if a_rescue.types
          if found_catch_all
            raise "specific rescue must come before catch-all rescue", location
          end
        else
          if found_catch_all
            raise "catch-all rescue can only be specified once", location
          end
          found_catch_all = true
        end
        rescues << a_rescue
        break unless @token.keyword?(:rescue)
      end
    end

    if @token.keyword?(:else)
      unless rescues
        raise "'else' is useless without 'rescue'", @token, 4
      end

      add_nest :else, @indent, "", false  # *TODO* flag WHAT kind of else it is (try)

      #next_token_skip_statement_end
      block_kind = handle_block_start
      if block_kind == :NIL_BLOCK
        raise "empty else clause!"
      end

      a_else = parse_expressions
      skip_statement_end
    end

    if @token.keyword?(:ensure)
      add_nest :ensure, @indent, "", false

      #next_token_skip_statement_end
      block_kind = handle_block_start
      if block_kind == :NIL_BLOCK
        raise "empty ensure clause!"
      end

      a_ensure = parse_expressions
      skip_statement_end
    end

    end_location = token_end_location

    #check_ident "end"
    #next_token_skip_space

    if rescues || a_ensure
      {ExceptionHandler.new(exp, rescues, a_else, a_ensure).at_end(end_location), end_location}
    else
      exp
      {exp, end_location}
    end
  end

  #SemicolonOrNewLine = [:";", :NEWLINE]

  def parse_rescue
    next_token_skip_space

    case @token.type
    when :IDENT
      name = @token.value.to_s
      add_var name
      next_token_skip_space

      if @token.type == :":"
        next_token_skip_space_or_newline
        check :CONST
        types = parse_rescue_types
      end
    when :CONST
      types = parse_rescue_types
    end

    add_nest :rescue, @indent, "", false

    #check SemicolonOrNewLine
    block_kind = handle_block_start

    next_token_skip_space_or_newline

    if block_kind == :NIL_BLOCK # @token.keyword?("end")
      body = nil
      handle_blockend
    else
      body = parse_expressions
      skip_statement_end
    end

    Rescue.new(body, types, name)
  end

  def parse_rescue_types
    types = [] of ASTNode
    while true
      types << parse_ident
      skip_space
      if @token.type == :"|"
        next_token_skip_space
      else
        skip_space
        break
      end
    end
    types
  end

  def parse_while
    parse_while_or_until While
  end

  def parse_until
    parse_while_or_until Until
  end

  def parse_while_or_until(klass)
    add_nest (klass == While ? :while : :until), @indent, "", false

    slash_is_regex!
    next_token_skip_space_or_newline

    cond = parse_op_assign_no_control allow_suffix: false

    slash_is_regex!
    #skip_statement_end
    block_kind = handle_block_start
    if block_kind == :NIL_BLOCK
      body = NilLiteral.new
      handle_blockend
    else
      body = parse_expressions
    end
    skip_statement_end

    end_location = token_end_location
    #check_ident "end"
    next_token_skip_space

    klass.new(cond, body).at_end(end_location)
  end

  def call_block_arg_follows?
    @token.type == :"&" && !current_char.whitespace?
  end

  def parse_call_block_arg(args, check_paren, named_args = nil)
    location = @token.location

    next_token_skip_space

    if @token.type == :"."
      block_arg_name = "__arg#{@block_arg_count}"
      @block_arg_count += 1

      obj = Var.new(block_arg_name)
      @wants_regex = false
      next_token_skip_space

      location = @token.location

      if @token.value == :is_a?
        call = parse_is_a(obj).at(location)
      elsif @token.value == :responds_to?
        call = parse_responds_to(obj).at(location)
      elsif @token.type == :"["
        call = parse_atomic_method_suffix obj, location

        if @token.type == :"=" && call.is_a?(Call)
          next_token_skip_space
          exp = parse_op_assign
          call.name = "#{call.name}="
          call.args << exp
        end
      else
        # At this point we want to attach the "do" to the next call,
        # so we set this var to true to make the parser think the call
        # has parenthesis and so a "do" must be attached to it
        @last_call_has_parenthesis = true
        call = parse_var_or_call(force_call: true).at(location)

        if call.is_a?(Call)
          call.obj = obj
        else
          raise "Bug: #{call} should be a call"
        end

        call = call as Call

        if @token.type == :"="
          next_token_skip_space
          if @token.type == :"("
            next_token_skip_space
            exp = parse_op_assign
            check :")"
            next_token_skip_space
            call.name = "#{call.name}="
            call.args = [exp] of ASTNode
            call = parse_atomic_method_suffix call, location
          else
            exp = parse_op_assign
            call.name = "#{call.name}="
            call.args = [exp] of ASTNode
          end
        else
          call = parse_atomic_method_suffix call, location

          if @token.type == :"=" && call.is_a?(Call) && call.name == "[]"
            next_token_skip_space
            exp = parse_op_assign
            call.name = "#{call.name}="
            call.args << exp
          end
        end
      end

      block = Block.new([Var.new(block_arg_name)], call).at(location)
    else
      block_arg = parse_op_assign
    end

    end_location = token_end_location

    if check_paren
      check :")"
      next_token_skip_space
    else
      skip_space
    end

    CallArgs.new args, block, block_arg, named_args, false, end_location
  end

  def parse_class_def(is_abstract = false, is_struct = false, doc = nil)
    @type_nest += 1

    doc ||= @token.doc

    next_token_skip_space_or_newline
    name_column_number = @token.column_number

    name = parse_ident allow_type_vars: false
    #skip_space

    add_nest :type, @indent, name.to_s, false

    type_vars = parse_type_vars
    skip_space

    superclass = nil

    if @token.type == :"<<"
      next_token_skip_space_or_newline
      superclass = parse_ident
    end


    dbg "parse_class_def - before body"


    #skip_statement_end

    block_kind = handle_block_start :type
    if block_kind == :NIL_BLOCK
      body = NilLiteral.new
      handle_blockend
    else
      @prioritize_fun_def = true
      body = parse_expressions
      @prioritize_fun_def = false
    end

    dbg "parse_class_def - after body"

    end_location = body.end_location # token_end_location
    #check_ident "end"
    #next_token_skip_space

    raise "Bug: ClassDef name can only be a Path" unless name.is_a?(Path)

    @type_nest -= 1

    class_def = ClassDef.new name, body, superclass, type_vars, is_abstract, is_struct, name_column_number
    class_def.doc = doc
    class_def.end_location = end_location
    class_def
  end

  def parse_type_vars
    type_vars = nil
    if @token.type == :"<"
      type_vars = [] of String

      next_token_skip_space_or_newline
      while @token.type != :">"
        type_var_name = check_const
        unless OnyxParser.free_var_name?(type_var_name)
          raise "type variables can only be single letters optionally followed by a digit", @token
        end

        if type_vars.includes? type_var_name
          raise "duplicated type var name: #{type_var_name}", @token
        end
        type_vars.push type_var_name

        next_token_skip_space_or_newline
        if @token.type == :","
          next_token_skip_space_or_newline
        end
      end

      if type_vars.empty?
        raise "must specify at least one type var"
      end

      next_token_skip_space
    end
    type_vars
  end

  def parse_module_def
    @type_nest += 1

    location = @token.location
    doc = @token.doc

    next_token_skip_space_or_newline

    name_column_number = @token.column_number
    name = parse_ident allow_type_vars: false
    skip_space

    type_vars = parse_type_vars
    skip_statement_end

    body = parse_expressions

    end_location = token_end_location
    check_ident "end"
    next_token_skip_space

    raise "Bug: ModuleDef name can only be a Path" unless name.is_a?(Path)

    @type_nest -= 1

    module_def = ModuleDef.new name, body, type_vars, name_column_number
    module_def.doc = doc
    module_def.end_location = end_location
    module_def
  end


  # *TODO* REPOSITION IN FILE:

  def backup_tok
    @temp_token.copy_from @token
    {current_pos, @line_number, @column_number}
  end

  def restore_tok(backup: {Int32, Int32, Int32})
    @token.copy_from @temp_token
    self.current_pos, @line_number, @column_number = backup
  end

  def backup_pos
    {current_pos, @line_number, @column_number}
  end

  def restore_pos(backup: {Int32, Int32, Int32})
    self.current_pos, @line_number, @column_number = backup
  end



  def parse_parenthesized_expression
    dbg "parse_parenthesized_expression"
    dbginc

    @paren_nest += 1

    backed = backup_tok()
    expression_failed = false

    begin
      location = @token.location
      next_token_skip_space_newline_or_indent

      if @token.type == :")"
        @paren_nest -= 1
        return node_and_next_token NilLiteral.new
      end

      exps = [] of ASTNode

      while true
        exps << parse_expression

        case @token.type
        when :")"
          dbg "parse_parenthesized_expression: got ')'"
          @paren_nest -= 1
          @wants_regex = false
          next_token_skip_space
          break
        when :NEWLINE, :";"   # *TODO* add INDENT, DEDENT? (shouldn't be generated: lexer!!)
          dbg "parse_parenthesized_expression: got ;|\\n"
          next_token_skip_space_or_indent
          if @token.type == :")"
            dbg "parse_parenthesized_expression: got ')' after stop"
            @paren_nest -= 1
            @wants_regex = false
            next_token_skip_space
            break
          end
        else
          raise "unterminated parenthesized expression", location
        end
      end

    rescue e
      dbg "Happened while parsing paranthesized expression:" + e.message.to_s
      expression_failed = true
      @paren_nest -= 1
      restore_tok backed
      return parse_lambda_literal
    end


    # It's a lambda even though an expression could be parsed - REDO!
    if token? :"->"
      restore_tok backed
      return parse_lambda_literal

    else
      unexpected_token "(" if @token.type == :"("
      Expressions.new exps
    end

  ensure
    dbgdec
  end



  def parse_lambda_literal
    dbg "parse_lambda_literal"
    check :"("
    next_token_skip_space_or_newline


    # *TODO* the func pointer thing separately - probably change syn on it too

    # unless @token.type == :"{" || @token.type == :"(" || @token.keyword?(:do)
    #   return parse_fun_pointer
    # end

    args = [] of Arg

    while @token.type != :")"
      location = @token.location
      arg = parse_lambda_literal_arg.at(location)
      if args.any? &.name.==(arg.name)
        raise "duplicated argument name: #{arg.name}", location
      end

      args << arg
    end

    next_token_skip_space_or_newline

    # current_vars = @scope_stack.last.dup
    # push_scope current_vars
    @scope_stack.push_scope
    add_vars args

    end_location = nil

    check :"->"
    next_token_skip_space_or_newline

    if @token.type == :"{"
      next_token_skip_statement_end
      check_not_pipe_before_proc_literal_body
      body = parse_expressions
      end_location = token_end_location
      check :"}"

    else #if @token.keyword?(:do)
      #next_token_skip_statement_end
      check_not_pipe_before_proc_literal_body
      body = parse_expressions
      end_location = token_end_location
      check_ident :"end"

    # else
    #   unexpected_token

    end

    pop_scope

    next_token_skip_space

    FunLiteral.new(Def.new("->", args, body)).at_end(end_location)
  end







  # def parse_fun_literal
  #   next_token_skip_space_or_newline

  #   unless @token.type == :"{" || @token.type == :"(" || @token.keyword?(:do)
  #     return parse_fun_pointer
  #   end

  #   args = [] of Arg
  #   if @token.type == :"("
  #     next_token_skip_space_or_newline
  #     while @token.type != :")"
  #       location = @token.location
  #       arg = parse_lambda_literal_arg.at(location)
  #       if args.any? &.name.==(arg.name)
  #         raise "duplicated argument name: #{arg.name}", location
  #       end

  #       args << arg
  #     end
  #     next_token_skip_space_or_newline
  #   end

  #   # current_vars = @scope_stack.last.dup
  #   # push_scope current_vars
  #   @scope_stack.push_dup_scope()
  #   add_vars args

  #   end_location = nil

  #   if @token.keyword?(:do)
  #     next_token_skip_statement_end
  #     check_not_pipe_before_proc_literal_body
  #     body = parse_expressions
  #     end_location = token_end_location
  #     check_ident :"end"
  #   elsif @token.type == :"{"
  #     next_token_skip_statement_end
  #     check_not_pipe_before_proc_literal_body
  #     body = parse_expressions
  #     end_location = token_end_location
  #     check :"}"
  #   else
  #     unexpected_token
  #   end

  #   pop_scope

  #   next_token_skip_space

  #   FunLiteral.new(Def.new("->", args, body)).at_end(end_location)
  # end

  def check_not_pipe_before_proc_literal_body
    if @token.type == :"|"
      location = @token.location
      next_token_skip_space

      msg = String.build do |msg|
        msg << "unexpected token '|', proc literals specify their arguments like this: ->("
        if @token.type == :IDENT
          msg << @token.value.to_s << " : Type"
          next_token_skip_space_or_newline
          msg << ", ..." if @token.type == :","
        else
          msg << "arg : Type"
        end
        msg << ") { ... }"
      end

      raise msg, location
    end
  end

  def parse_lambda_literal_arg
    dbg "parse_lambda_literal_ARG, at"

    # *TODO* generate new tmp name per arg. if several...
    if token? :UNDERSCORE
      name = "tmp_47_"
    else
      name = check_ident
    end
    next_token_skip_space_or_newline

    dbg "parse_lambda_literal_ARG: name = " + name.to_s

    if @token.type != :"," && @token.type != :";" && @token.type != :")"
      dbg "parse_lambda_literal: parse a type"

      is_mod_const, is_mod_mut, type, is_val_const, is_val_mut =
        parse_arg_type()

    else
      dbg "parse_lambda_literal: no type"
    end

    if @token.type == :"," || @token.type == :";"
      next_token_skip_space_or_newline
    end

    Arg.new name, restriction: type
  end

  def parse_fun_pointer
    location = @token.location

    case @token.type
    when :IDENT
      name = @token.value.to_s
      next_token_skip_space
      if @token.type == :"."
        next_token_skip_space
        second_name = check_ident
        if name != "self" && !@scope_stack.cur_has?(name)
          raise "undefined variable '#{name}'", location.line_number, location.column_number
        end
        obj = Var.new(name)
        name = second_name
        next_token_skip_space
      end
    when :CONST
      obj = parse_ident
      check :"."
      next_token_skip_space
      name = check_ident
      next_token_skip_space
    else
      unexpected_token
    end

    if @token.type == :"."
      unexpected_token
    end

    if @token.type == :"("
      next_token_skip_space
      types = parse_types
      check :")"
      next_token_skip_space
    else
      types = [] of ASTNode
    end

    FunPointer.new(obj, name, types)
  end

  def parse_delimiter
    if @token.type == :STRING
      return node_and_next_token StringLiteral.new(@token.value.to_s)
    end

    location = @token.location
    delimiter_state = @token.delimiter_state

    check :DELIMITER_START

    next_string_token(delimiter_state)
    delimiter_state = @token.delimiter_state

    pieces = [] of ASTNode | String
    has_interpolation = false

    delimiter_state, has_interpolation, options, token_end_location = consume_delimiter pieces, delimiter_state, has_interpolation

    if delimiter_state.kind == :string
      while true
        passed_backslash_newline = @token.passed_backslash_newline
        skip_space

        if passed_backslash_newline && @token.type == :DELIMITER_START && @token.delimiter_state.kind == :string
          next_string_token(delimiter_state)
          delimiter_state = @token.delimiter_state
          delimiter_state, has_interpolation, options, token_end_location = consume_delimiter pieces, delimiter_state, has_interpolation
        else
          break
        end
      end
    end

    if has_interpolation
      pieces = pieces.map do |piece|
        piece.is_a?(String) ? StringLiteral.new(piece) : piece
      end
      result = StringInterpolation.new(pieces)
    else
      result = StringLiteral.new pieces.join
    end

    case delimiter_state.kind
    when :command
      result = Call.new(nil, "`", result)
    when :regex
      if result.is_a?(StringLiteral) && (regex_error = Regex.error?(result.value))
        raise "invalid regex: #{regex_error}", location
      end

      result = RegexLiteral.new(result, options)
    end

    result.end_location = token_end_location

    result
  end

  def consume_delimiter(pieces, delimiter_state, has_interpolation)
    options = Regex::Options::None
    token_end_location = nil
    while true
      case @token.type
      when :STRING
        pieces << @token.value.to_s

        next_string_token(delimiter_state)
        delimiter_state = @token.delimiter_state
      when :DELIMITER_END
        if delimiter_state.kind == :regex
          options = consume_regex_options
        end
        token_end_location = token_end_location()
        next_token
        break
      when :EOF
        case delimiter_state.kind
        when :command
          raise "Unterminated command"
        when :regex
          raise "Unterminated regular expression"
        when :heredoc
          raise "Unterminated heredoc"
        else
          raise "Unterminated string literal"
        end
      else
        delimiter_state = @token.delimiter_state
        next_token_skip_space_or_newline
        exp = parse_expression

        if exp.is_a?(StringLiteral)
          pieces << exp.value
        else
          pieces << exp
          has_interpolation = true
        end

        if @token.type != :"}"
          raise "Unterminated string interpolation"
        end

        @token.delimiter_state = delimiter_state
        next_string_token(delimiter_state)
        delimiter_state = @token.delimiter_state
      end
    end

    {delimiter_state, has_interpolation, options, token_end_location}
  end

  def consume_regex_options
    options = Regex::Options::None
    while true
      case current_char
      when 'i'
        options |= Regex::Options::IGNORE_CASE
        next_char
      when 'm'
        options |= Regex::Options::MULTILINE
        next_char
      when 'x'
        options |= Regex::Options::EXTENDED
        next_char
      else
        if 'a' <= current_char.downcase <= 'z'
          raise "unknown regex option: #{current_char}"
        end
        break
      end
    end
    options
  end

  def parse_string_without_interpolation
    string = parse_delimiter
    if string.is_a?(StringLiteral)
      string.value
    else
      yield
    end
  end

  def parse_string_array
    parse_string_or_symbol_array StringLiteral, "String"
  end

  def parse_symbol_array
    parse_string_or_symbol_array SymbolLiteral, "Symbol"
  end

  def parse_string_or_symbol_array(klass, elements_type)
    strings = [] of ASTNode

    next_string_array_token
    while true
      case @token.type
      when :STRING
        strings << klass.new(@token.value.to_s)
        next_string_array_token
      when :STRING_ARRAY_END
        next_token
        break
      when :EOF
        raise "Unterminated symbol array literal"
      end
    end

    ArrayLiteral.new strings, Path.global(elements_type)
  end

  def parse_empty_array_literal
    line = @line_number
    column = @token.column_number

    next_token_skip_space
    if @token.keyword?(:of)
      next_token_skip_space_or_newline
      of = parse_single_type
      ArrayLiteral.new(of: of).at_end(of)
    else
      raise "for empty arrays use '[] of ElementType'", line, column
    end
  end

  def parse_array_literal_or_multi_assign
    dbg "parse_array_literal_or_multi_assign"
    node = parse_array_literal

    dbg "after parse_array_literal"
    if token? :"="
      dbg "got '='"
      if node.of
        raise "Multi assign or array literal? Can't figure out."
      end
      parse_multi_assign node
    else
      dbg "didn't get '='"
      node
    end
  end

  def parse_array_literal
    slash_is_regex!

    location = @token.location

    exps = [] of ASTNode
    end_location = nil

    open("array literal") do
      next_token_skip_space_or_newline
      while @token.type != :"]"
        exps << parse_expression
        end_location = token_end_location
        skip_space_newline_or_indent
        if @token.type == :"," || @token.type == :NEWLINE
          slash_is_regex!
          next_token_skip_space_or_newline
        end
      end
      next_token_skip_space
    end

    of = nil
    if @token.keyword?(:of)
      next_token_skip_space_or_newline
      of = parse_single_type
      end_location = of.end_location
    end

    ArrayLiteral.new(exps, of).at(location).at_end(end_location)
  end

  def parse_hash_or_tuple_literal(allow_of = true)
    location = @token.location
    line = @line_number
    column = @token.column_number

    slash_is_regex!
    next_token_skip_space_or_newline

    if @token.type == :"}"
      end_location = token_end_location
      next_token_skip_space
      new_hash_literal([] of HashLiteral::Entry, line, column, end_location)
    else
      if hash_symbol_key?
        first_key = SymbolLiteral.new(@token.value.to_s)
        next_token
      else
        first_key = parse_op_assign
        case @token.type
        when :":"
          if first_key.is_a?(StringLiteral)
            # Nothing: it's a string key
          else
            check :"=>"
          end
        when :","
          slash_is_regex!
          next_token_skip_space_or_newline
          return parse_tuple first_key, location
        when :"}"
          return parse_tuple first_key, location
        else
          check :"=>"
        end
      end
      slash_is_regex!
      next_token_skip_space_or_newline
      parse_hash_literal first_key, location, allow_of
    end
  end

  def parse_hash_literal(first_key, location, allow_of)
    slash_is_regex!

    line = @line_number
    column = @token.column_number
    end_location = nil

    entries = [] of HashLiteral::Entry

    open("hash literal", location) do
      entries << HashLiteral::Entry.new(first_key, parse_op_assign)
      skip_space_newline_or_indent
      if @token.type == :","
        slash_is_regex!
        next_token_skip_space_or_newline
      end

      while @token.type != :"}"
        if hash_symbol_key?
          key = SymbolLiteral.new(@token.value.to_s)
          next_token
        else
          key = parse_op_assign
          skip_space_newline_or_indent
          if @token.type == :":" && key.is_a?(StringLiteral)
            # Nothing: it's a string key
          else
            check :"=>"
          end
        end
        slash_is_regex!
        next_token_skip_space_or_newline
        entries << HashLiteral::Entry.new(key, parse_op_assign)
        skip_space_newline_or_indent
        if @token.type == :","
          slash_is_regex!
          next_token_skip_space_or_newline
        end
      end
      end_location = token_end_location
      next_token_skip_space
    end

    new_hash_literal entries, line, column, end_location, allow_of: allow_of
  end

  def hash_symbol_key?
    (@token.type == :IDENT || @token.type == :CONST) && current_char == ':' && peek_next_char != ':'
  end

  def parse_tuple(first_exp, location)
    exps = [] of ASTNode
    end_location = nil

    open("tuple literal", location) do
      exps << first_exp
      while @token.type != :"}"
        exps << parse_expression
        skip_space_newline_or_indent
        if @token.type == :","
          next_token_skip_space_or_newline
        end
      end
      end_location = token_end_location
      next_token_skip_space
    end

    TupleLiteral.new(exps).at_end(end_location)
  end

  def new_hash_literal(entries, line, column, end_location, allow_of = true)
    of = nil

    if allow_of
      if @token.keyword?(:of)
        next_token_skip_space_or_newline
        of_key = parse_single_type
        check :"=>"
        next_token_skip_space_or_newline
        of_value = parse_single_type
        of = HashLiteral::Entry.new(of_key, of_value)
        end_location = of_value.end_location
      end

      if entries.empty? && !of
        raise "for empty hashes use '{} of KeyType => ValueType'", line, column
      end
    end

    HashLiteral.new(entries, of).at_end(end_location)
  end

  def parse_require
    raise "can't require inside def", @token if @def_nest > 0
    raise "can't require inside type declarations", @token if @type_nest > 0

    next_token_skip_space
    check :DELIMITER_START
    string = parse_string_without_interpolation { "interpolation not allowed in require" }

    skip_space

    Require.new string
  end

  def parse_case
    slash_is_regex!
    next_token_skip_space_or_newline
    unless @token.keyword?(:when)
      cond = parse_op_assign_no_control
      skip_statement_end
    end

    whens = [] of When
    a_else = nil

    while true
      case @token.type
      when :IDENT
        case @token.value
        when :when
          slash_is_regex!
          next_token_skip_space_or_newline
          when_conds = [] of ASTNode
          while true
            if cond && @token.type == :"."
              next_token
              call = parse_var_or_call(force_call: true) as Call
              call.obj = ImplicitObj.new
              when_conds << call
            else
              when_conds << parse_op_assign_no_control
            end
            skip_space
            if @token.keyword?(:then)
              next_token_skip_space_or_newline
              break
            else
              slash_is_regex!
              case @token.type
              when :","
                next_token_skip_space_or_newline
              when :NEWLINE
                skip_space_newline_or_indent
                break
              when :";"
                skip_statement_end
                break
              else
                unexpected_token @token.to_s, "expecting ',', ';' or '\n'"
              end
            end
          end

          slash_is_regex!
          when_body = parse_expressions
          skip_space_newline_or_indent
          whens << When.new(when_conds, when_body)
        when :else
          if whens.size == 0
            unexpected_token @token.to_s, "expecting when"
          end
          slash_is_regex!
          next_token_skip_statement_end
          a_else = parse_expressions
          skip_statement_end
          check_ident "end"
          next_token
          break
        when "end"
          if whens.empty?
            unexpected_token @token.to_s, "expecting when, else or end"
          end
          next_token
          break
        else
          unexpected_token @token.to_s, "expecting when, else or end"
        end
      else
        unexpected_token @token.to_s, "expecting when, else or end"
      end
    end

    Case.new(cond, whens, a_else)
  end

  def parse_include
    parse_include_or_extend Include
  end

  def parse_extend
    parse_include_or_extend Extend
  end

  def parse_include_or_extend(klass)
    location = @token.location

    next_token_skip_space_or_newline

    if @token.keyword?(:self)
      name = Self.new.at(@token.location)
      name.end_location = token_end_location
      next_token_skip_space
    else
      name = parse_ident
    end

    klass.new name
  end

  def parse_to_def(a_def)
    instance_vars = prepare_parse_def
    @def_nest += 1

    # Small memory optimization: don't keep the Set in the Def if it's empty
    instance_vars = nil if instance_vars.empty?

    result = parse

    a_def.instance_vars = instance_vars
    a_def.calls_super = @calls_super
    a_def.calls_initialize = @calls_initialize
    a_def.uses_block_arg = @uses_block_arg
    a_def.assigns_special_var = @assigns_special_var

    result
  end

  def parse_def(is_abstract = false, is_macro_def = false, doc = nil)
    doc ||= @token.doc

    instance_vars = prepare_parse_def
    a_def = parse_def_helper is_abstract: is_abstract, is_macro_def: is_macro_def

    # Small memory optimization: don't keep the Set in the Def if it's empty
    instance_vars = nil if instance_vars.empty?

    a_def.instance_vars = instance_vars
    a_def.calls_super = @calls_super
    a_def.calls_initialize = @calls_initialize
    a_def.uses_block_arg = @uses_block_arg
    a_def.assigns_special_var = @assigns_special_var
    a_def.doc = doc
    @instance_vars = nil
    @calls_super = false
    @calls_initialize = false
    @uses_block_arg = false
    @assigns_special_var = false
    @block_arg_name = nil

    dbg "parse_def done"

    a_def
  end

  def prepare_parse_def
    @calls_super = false
    @calls_initialize = false
    @uses_block_arg = false
    @block_arg_name = nil
    @assigns_special_var = false
    @instance_vars = Set(String).new
  end

  def parse_macro
    doc = @token.doc

    next_token_skip_space_or_newline

    if @token.keyword?(:def)
      a_def = parse_def_helper is_macro_def: true
      a_def.doc = doc
      return a_def
    end

    push_fresh_scope

    check DefOrMacroCheck1

    name_line_number = @token.line_number
    name_column_number = @token.column_number

    name = check_ident
    next_token_skip_space

    args = [] of Arg

    found_default_value = false
    found_splat = false

    splat_index = nil
    index = 0

    case @token.type
    when :"("
      next_token_skip_space_or_newline
      while @token.type != :")"
        extras = parse_arg(args, nil, true, found_default_value, found_splat, allow_restrictions: false)
        if !found_default_value && extras.default_value
          found_default_value = true
        end
        if !splat_index && extras.splat
          splat_index = index
          found_splat = true
        end
        if block_arg = extras.block_arg
          check :")"
          break
        elsif @token.type == :","
          next_token_skip_space_or_newline
        else
          skip_space
          if @token.type != :")"
            unexpected_token @token.to_s, "expected ',' or ')'"
          end
        end
        index += 1
      end
      next_token
    when :IDENT, :"..." # *TODO* verify - was "*"
      while @token.type != :NEWLINE && @token.type != :";"
        extras = parse_arg(args, nil, false, found_default_value, found_splat, allow_restrictions: false)
        if !found_default_value && extras.default_value
          found_default_value = true
        end
        if !splat_index && extras.splat
          splat_index = index
          found_splat = true
        end
        if block_arg = extras.block_arg
          break
        elsif @token.type == :","
          next_token_skip_space_or_newline
        else
          skip_space
          if @token.type != :NEWLINE && @token.type != :";"
            unexpected_token @token.to_s, "expected ';' or newline"
          end
        end
        index += 1
      end
    end

    end_location = nil

    if @token.keyword?("end")
      end_location = token_end_location
      body = Expressions.new
      next_token_skip_space
    else
      body, end_location = parse_macro_body(name_line_number, name_column_number)
    end

    pop_scope

    node = Macro.new name, args, body, block_arg, splat_index
    node.name_column_number = name_column_number
    node.doc = doc
    node.end_location = end_location
    node
  end

  def parse_macro_body(start_line, start_column, macro_state = Token::MacroState.default)
    skip_whitespace = check_macro_skip_whitespace

    pieces = [] of ASTNode

    while true
      next_macro_token macro_state, skip_whitespace
      macro_state = @token.macro_state
      if macro_state.yields
        @yields = 0
      end

      skip_whitespace = false

      case @token.type
      when :MACRO_LITERAL
        pieces << MacroLiteral.new(@token.value.to_s)
      when :MACRO_EXPRESSION_START
        pieces << MacroExpression.new(parse_macro_expression)
        check_macro_expression_end
        skip_whitespace = check_macro_skip_whitespace
      when :MACRO_CONTROL_START
        macro_control = parse_macro_control(start_line, start_column, macro_state)
        if macro_control
          pieces << macro_control
          skip_whitespace = check_macro_skip_whitespace
        else
          return Expressions.from(pieces), nil
        end
      when :MACRO_VAR
        macro_var_name = @token.value.to_s
        if current_char == '{'
          macro_var_exps = parse_macro_var_exps
        else
          macro_var_exps = nil
        end
        pieces << MacroVar.new(macro_var_name, macro_var_exps)
      when :MACRO_END
        break
      when :EOF
        raise "unterminated macro", start_line, start_column
      else
        unexpected_token
      end
    end

    end_location = token_end_location

    next_token

    {Expressions.from(pieces), end_location}
  end

  def parse_macro_var_exps
    next_token # '{'
    next_token

    exps = [] of ASTNode
    while true
      exps << parse_expression_inside_macro
      skip_space
      case @token.type
      when :","
        next_token_skip_space
        if @token.type == :"}"
          break
        end
      when :"}"
        break
      else
        unexpected_token @token, "expecting ',' or '}'"
      end
    end
    exps
  end

  def check_macro_skip_whitespace
    if current_char == '\\' && peek_next_char.whitespace?
      next_char
      true
    else
      false
    end
  end

  def parse_macro_expression
    next_token_skip_space_or_newline
    parse_expression_inside_macro
  end

  def check_macro_expression_end
    check :"}"

    next_token
    check :"}"
  end

  def parse_macro_control(start_line, start_column, macro_state = Token::MacroState.default)
    next_token_skip_space_or_newline

    case @token.type
    when :IDENT
      case @token.value
      when :for
        next_token_skip_space

        vars = [] of Var

        while true
          vars << Var.new(check_ident).at(@token.location)

          next_token_skip_space
          if @token.type == :","
            next_token_skip_space
          else
            break
          end
        end

        check_ident :in
        next_token_skip_space

        exp = parse_expression_inside_macro

        check :"%}"

        body, end_location = parse_macro_body(start_line, start_column, macro_state)

        check_ident "end"
        next_token_skip_space
        check :"%}"

        return MacroFor.new(vars, exp, body)
      when :if
        return parse_macro_if(start_line, start_column, macro_state)
      when :unless
        macro_if = parse_macro_if(start_line, start_column, macro_state)
        case macro_if
        when MacroIf
          macro_if.then, macro_if.else = macro_if.else, macro_if.then
        when MacroExpression
          if (exp = macro_if.exp).is_a?(If)
            exp.then, exp.else = exp.else, exp.then
          end
        end
        return macro_if
      when :begin
        next_token_skip_space
        check :"%}"

        body, end_location = parse_macro_body(start_line, start_column, macro_state)

        check_ident "end"
        next_token_skip_space
        check :"%}"

        return MacroIf.new(BoolLiteral.new(true), body)
      when :else, :elsif, "end"
        return nil
      end
    end

    @in_macro_expression = true
    exps = parse_expressions
    @in_macro_expression = false

    MacroExpression.new(exps, output: false)
  end

  def parse_macro_if(start_line, start_column, macro_state, check_end = true)
    next_token_skip_space

    @in_macro_expression = true
    cond = parse_op_assign
    @in_macro_expression = false

    if @token.type != :"%}" && check_end
      an_if = parse_if_after_condition cond, true
      return MacroExpression.new(an_if, output: false)
    end

    check :"%}"

    a_then, end_location = parse_macro_body(start_line, start_column, macro_state)

    if @token.type == :IDENT
      case @token.value
      when :else
        next_token_skip_space
        check :"%}"

        a_else, end_location = parse_macro_body(start_line, start_column, macro_state)

        if check_end
          check_ident "end"
          next_token_skip_space
          check :"%}"
        end
      when :elsif
        a_else = parse_macro_if(start_line, start_column, macro_state, false)

        if check_end
          check_ident "end"
          next_token_skip_space
          check :"%}"
        end
      when "end"
        if check_end
          next_token_skip_space
          check :"%}"
        end
      else
        unexpected_token
      end
    else
      unexpected_token
    end

    return MacroIf.new(cond, a_then, a_else)
  end

  def parse_expression_inside_macro
    @in_macro_expression = true

    if @token.type == :"..."
      next_token_skip_space
      exp = parse_expression
      exp = Splat.new(exp).at(exp.location)
    else
      exp = parse_expression
    end

    skip_space_newline_or_indent

    @in_macro_expression = false
    exp
  end

  DefOrMacroCheck1 = [:IDENT, :CONST, :"<<", :"<", :"<=", :"==", :"===", :"!=", :"=~", :">>", :">", :">=", :"+", :"-", :"*", :"/", :"!", :"~", :"%", :"&", :"|", :"^", :"**", :"[]", :"[]=", :"<=>", :"[]?"]
  DefOrMacroCheck2 = [:"<<", :"<", :"<=", :"==", :"===", :"!=", :"=~", :">>", :">", :">=", :"+", :"-", :"*", :"/", :"!", :"~", :"%", :"&", :"|", :"^", :"**", :"[]", :"[]?", :"[]=", :"<=>"]

  def parse_def_helper(is_abstract = false, is_macro_def = false)
    push_fresh_scope
    @doc_enabled = false
    @def_nest += 1

    # At this point we want to attach the "do" to calls inside the def,
    # not to calls that might have this def as a macro argument.
    @last_call_has_parenthesis = true

    next_token

    mutate_gt_op_to_bigger_op?

    case current_char
    when '%'
      next_char
      @token.type = :"%"
      @token.column_number += 1
    when '/'
      next_char
      @token.type = :"/"
      @token.column_number += 1
    when '`'
      next_char
      @token.type = :"`"
      @token.column_number += 1
    else
      skip_space_newline_or_indent
      check DefOrMacroCheck1
    end

    receiver = nil
    @yields = nil
    name_line_number = @token.line_number
    name_column_number = @token.column_number
    receiver_location = @token.location
    end_location = token_end_location

    if @token.type == :CONST
      receiver = parse_ident
    elsif @token.type == :IDENT
      name = @token.value.to_s
      next_token
      if token?(:"=")
        name = "#{name}="
        next_token_skip_space
      else
        skip_space
      end
    else
      name = @token.type.to_s
      next_token_skip_space
    end


    add_nest (is_macro_def ? :macro : :def), @indent, name.to_s, false


    if token?(:".")
      unless receiver
        if name
          receiver = Var.new(name).at(receiver_location)
        else
          raise "shouldn't reach this line"
        end
      end
      next_token_skip_space

      if @token.type == :IDENT
        name = @token.value.to_s
        name_column_number = @token.column_number
        next_token
        if token?(:"=")
          name = "#{name}="
          next_token_skip_space
        else
          skip_space
        end
      else
        mutate_gt_op_to_bigger_op?
        check DefOrMacroCheck2
        name = @token.type.to_s
        name_column_number = @token.column_number
        next_token_skip_space
      end
    else
      if receiver
        unexpected_token
      else
        raise "shouldn't reach this line" unless name
      end
      name = name.not_nil!
    end


    arg_list = [] of Arg
    extra_assigns = [] of ASTNode

    found_default_value = false
    found_splat = false

    index = 0
    splat_index = nil

    # *TODO* It should ALWAYS be `(` at this point! required!

    dbg ""

    case @token.type
    when :"("
      dbg "Got with parens arg_list"
      next_token_skip_space_or_newline

      while @token.type != :")"
        dbg "!=)"

        extras = parse_arg(arg_list, extra_assigns, true, found_default_value, found_splat)

        if !found_default_value && extras.default_value
          found_default_value = true
        end
        if !splat_index && extras.splat
          splat_index = index
          found_splat = true
        end
        if block_arg = extras.block_arg
          compute_block_arg_yields block_arg
          check :")"
          break

        elsif token?(:",") || token?(:";") || @token.type == :"NEWLINE"
          next_token_skip_space_or_newline

        else
          skip_space_newline_or_indent
          if @token.type != :")"
            unexpected_token @token.to_s, "expected ',' or ')'"
          end
        end
        index += 1
      end
      next_token_skip_space

    when :";", :"NEWLINE"
       # Skip
    when :":"
      # Skip
    when :"&"
      next_token_skip_space_or_newline
      block_arg = parse_block_arg(extra_assigns)
      compute_block_arg_yields block_arg
    else
      if is_abstract && @token.type == :EOF
        # OK
      else
        unexpected_token
      end
    end

    dbg "before is_macro_def"

    if is_macro_def
      check :":"
      next_token_skip_space
      return_type = parse_single_type
      end_location = return_type.end_location

      if is_abstract
        body = Nop.new
      else


        #if @token.keyword?("end")  # *TODO*
        if is_explicit_end_token? # *TODO* all kinds of endings

          body = Expressions.new
          next_token_skip_space
        else
          body, end_location = parse_macro_body(name_line_number, name_column_number)
        end
      end

    else

      # The part below should be cleaned up

      if @token.type == :"->"  # this is checked in handle_block_start too!!
        dbg "Got ->"
        end_location = token_end_location
        #next_token_skip_space_or_newline
        # Done with header..
      else
        dbg "No ->, type?"
        #next_token_skip_space
        if @token.type != :"NEWLINE"    # *TODO* we don't accept newline here
          dbg "Tries TYPE PARSE"
          return_type = parse_single_type
          end_location = return_type.end_location
        else
          dbg "GOT NEWLINE"
          return_type = nil
        end
        dbg "tok:" + @token.to_s

        if @token.type == :"->" # this is checked in handle_block_start too!!
          #next_token_skip_space_or_newline
        else
          unexpected_token @token.to_s, "expected '->' or return type"
        end
        dbg "Got ->"
        end_location = token_end_location
        # Done with header..
      end

      dbg "body time"

      block_kind = handle_block_start :def

      if block_kind == :NIL_BLOCK
        dbg "got nil block"
        body = Nop.new
        handle_blockend
      elsif is_abstract
        dbg "is_abstract - sets nil block"
        body = Nop.new
        handle_blockend
      else
        dbg "got a body"
        slash_is_regex!
        dbg "before skip_statement_end"
        skip_statement_end
        dbg "after skip_statement_end"

        end_location = token_end_location

        if is_explicit_end_token? # *TODO* all kinds of endings
          body = Expressions.from(extra_assigns)
          next_token_skip_space
        else
          dbg "before body=parse_expressions"
          body = parse_expressions
          dbg "after body=parse_expressions"
          if extra_assigns.size > 0
            exps = [] of ASTNode
            exps.concat extra_assigns
            if body.is_a?(Expressions)
              exps.concat body.expressions
            else
              exps.push body
            end
            body = Expressions.from exps
          end

          body, end_location = parse_exception_handler body

        end
      end
    end

    @def_nest -= 1
    @doc_enabled = @wants_doc
    pop_scope

    node = Def.new name, arg_list, body, receiver, block_arg, return_type, is_macro_def, @yields, is_abstract, splat_index
    node.name_column_number = name_column_number
    node.visibility = @visibility
    node.end_location = end_location

    dbg "parse_def_helper done"
    node
  end

  def compute_block_arg_yields(block_arg)
    block_arg_fun = block_arg.fun
    if block_arg_fun.is_a?(Fun)
      @yields = block_arg_fun.inputs.try(&.size) || 0
    else
      @yields = 0
    end
  end



  record ArgExtras, block_arg, default_value, splat

  def parse_arg(arg_list, extra_assigns, parenthesis, found_default_value, found_splat, allow_restrictions = true)
    if @token.type == :"&"
      next_token_skip_space_or_newline
      block_arg = parse_block_arg(extra_assigns)
      return ArgExtras.new(block_arg, false, false)
    end

    splat = false
    if @token.type == :"..."
      if found_splat
        # *TODO* Should say that it's a duplicate splat!
        unexpected_token
      end

      splat = true
      next_token_skip_space
    end

    arg_location = @token.location
    arg_name, uses_arg = parse_arg_name(arg_location, extra_assigns)

    if arg_list.any? { |arg| arg.name == arg_name }
      raise "duplicated argument name: #{arg_name}", @token
    end

    default_value = nil
    restriction = nil

    if parenthesis
      next_token_skip_space_or_newline
    else
      next_token_skip_space
    end


    if (allow_restrictions && # && @token.type == :":"
        !(
          token?(:"=") || token?(:",") || token?(:";") ||
          token?(:"<")
        )
    )
      #next_token_skip_space_or_newline
      location = @token.location
      is_mod_const, is_mod_mut, type, is_val_const, is_val_mut =
        parse_arg_type()
      dbg is_mod_const.to_s + ", " + is_mod_mut.to_s + ", " + type.to_s + ", " + is_val_const.to_s + ", " + is_val_mut.to_s

      restriction = type
    end



    unless splat
      if @token.type == :"="
        if found_splat
          unexpected_token
        end

        next_token_skip_space_or_newline

        case @token.type
        when :__LINE__, :__FILE__, :__DIR__
          default_value = MagicConstant.new(@token.type).at(@token.location)
          next_token
        else
          default_value = parse_op_assign
        end

        skip_space
      else
        if found_default_value
          raise "argument must have a default value", arg_location
        end
      end
    end

    raise "Bug: arg_name is nil" unless arg_name

    arg = Arg.new(arg_name, default_value, restriction).at(arg_location)
    arg_list << arg
    add_var arg

    ArgExtras.new(nil, !!default_value, splat)
  end



  def parse_block_arg(extra_assigns)
    name_location = @token.location
    arg_name, uses_arg = parse_arg_name(name_location, extra_assigns)
    @uses_block_arg = true if uses_arg

    next_token_skip_space_or_newline

    inputs = nil
    output = nil

    if @token.type == :":"  # *TODO*
      next_token_skip_space_or_newline

      location = @token.location

      type_spec = parse_single_type
    else
      type_spec = Fun.new
    end

    block_arg = BlockArg.new(arg_name, type_spec).at(name_location)

    add_var block_arg

    @block_arg_name = block_arg.name

    block_arg
  end

  def parse_arg_name(location, extra_assigns)
    # *TODO* also consider symbol style (#name) for
    # named fields

    case @token.type
    when :IDENT
      arg_name = @token.value.to_s
      uses_arg = false
    when :INSTANCE_VAR
      arg_name = @token.value.to_s[1 .. -1]
      ivar = InstanceVar.new(@token.value.to_s).at(location)
      var = Var.new(arg_name).at(location)
      assign = Assign.new(ivar, var).at(location)
      if extra_assigns
        extra_assigns.push assign
      else
        raise "can't use @instance_variable here"
      end
      add_instance_var ivar.name
      uses_arg = true
    when :CLASS_VAR
      arg_name = @token.value.to_s[2 .. -1]
      cvar = ClassVar.new(@token.value.to_s).at(location)
      var = Var.new(arg_name).at(location)
      assign = Assign.new(cvar, var).at(location)
      if extra_assigns
        extra_assigns.push assign
      else
        raise "can't use @@class_var here"
      end
      uses_arg = true
    else
      raise "unexpected token: #{@token}"
    end

    {arg_name, uses_arg}
  end

  def parse_if(check_end = true)
    dbg "parse_if"
    dbginc

    add_nest :if, @indent, "", false

    slash_is_regex!
    next_token_skip_space_or_newline

    cond = parse_op_assign_no_control allow_suffix: false
    parse_if_after_condition cond, check_end

  ensure
    dbgdec
  end

  def parse_if_after_condition(cond, check_end)
    dbg "parse_if_after_condition, at"
    slash_is_regex!


    #skip_statement_end


    # "then" || "=>" || "\n"+:INDENT
    block_kind = handle_block_start

    if block_kind == :NIL_BLOCK
      a_then = nil # NilLiteral.new   ?
      handle_blockend
    else
      a_then = parse_expressions
      skip_statement_end
    end

    a_else = nil
    if @token.type == :IDENT
      case @token.value
      when :else
        next_token_skip_statement_end
        block_kind = handle_block_start
        if block_kind == :NIL_BLOCK
          a_else = nil # NilLiteral.new   ?
          handle_blockend
        else
          a_else = parse_expressions
        end
      when :elsif
        a_else = parse_if check_end: false
      end
    end

    end_location = token_end_location

    # *TODO*
    # if check_end
    #   check_ident "end"
    #   next_token_skip_space
    # end

    If.new(cond, a_then, a_else).at_end(end_location)
  end

  def parse_unless
    next_token_skip_space_or_newline

    cond = parse_op_assign_no_control allow_suffix: false
    skip_statement_end

    a_then = parse_expressions
    skip_statement_end

    a_else = nil
    if @token.keyword?(:else)
      next_token_skip_statement_end
      a_else = parse_expressions
    end

    check_ident "end"
    end_location = token_end_location
    next_token_skip_space

    Unless.new(cond, a_then, a_else).at_end(end_location)
  end

  def parse_ifdef(check_end = true, mode = :normal)
    next_token_skip_space_or_newline

    cond = parse_flags_or
    skip_statement_end

    a_then = parse_ifdef_body(mode)
    skip_statement_end


    a_else = nil
    if @token.type == :IDENT
      case @token.value
      when :else
        next_token_skip_statement_end
        a_else = parse_ifdef_body(mode)
      when :elsif
        a_else = parse_ifdef check_end: false, mode: mode
      end
    end

    end_location = token_end_location

    if check_end
      check_ident "end"
      next_token_skip_space
    end

    IfDef.new(cond, a_then, a_else).at_end(end_location)
  end

  def parse_ifdef_body(mode)
    case mode
    when :lib
      parse_lib_body
    when :struct_or_union
      parse_struct_or_union_body
    else
      parse_expressions
    end
  end

  parse_operator :flags_or, :flags_and, "Or.new left, right", ":\"||\""
  parse_operator :flags_and, :flags_atomic, "And.new left, right", ":\"&&\""

  def parse_flags_atomic
    case @token.type
    when :"("
      next_token_skip_space
      if @token.type == :")"
        raise "unexpected token: #{@token}"
      end

      atomic = parse_flags_or
      skip_space

      check :")"
      next_token_skip_space

      atomic
    when :"!"
      next_token_skip_space
      Not.new(parse_flags_atomic)
    when :IDENT
      str = @token.to_s
      next_token_skip_space
      Var.new(str)
    else
      raise "unexpected token: #{@token}"
    end
  end

  def set_visibility(node)
    if visibility = @visibility
      node.visibility = visibility
    end
    node
  end

  def parse_var_or_call(global = false, force_call = false)
    location = @token.location
    end_location = token_end_location
    doc = @token.doc

    case @token.value
    when :is_a?
      obj = Var.new("self").at(location)
      return parse_is_a(obj)
    when :responds_to?
      obj = Var.new("self").at(location)
      return parse_responds_to(obj)
    end

    name = @token.value.to_s
    name_column_number = @token.column_number

    if force_call && !@token.value
      name = @token.type.to_s
    end

    is_var = is_var?(name)

    @wants_regex = false
    next_token

    if @token.type == :SPACE
      # We don't want the next token to be a regex literal if the call's name is
      # a variable in the current scope (it's unlikely that there will be a method
      # with that name that accepts a regex as a first argument).
      # This allows us to write: a = 1; b = 2; a /b
      @wants_regex = !is_var
    end

    case name
    when "super"
      @calls_super = true
    when "initialize"
      @calls_initialize = true
    end

    call_args, last_call_has_parenthesis = preserve_last_call_has_parenthesis do
      parse_call_args stop_on_do_after_space: (is_var || !@last_call_has_parenthesis)
    end
    if call_args
      args = call_args.args
      block = call_args.block
      block_arg = call_args.block_arg
      named_args = call_args.named_args
    end

    if call_args && call_args.stopped_on_do_after_space
      # This is the case when we have:
      #
      #     x = 1
      #     foo x do
      #     end
      #
      # In this case, since x is a variable and the previous call (foo)
      # doesn't have parenthesis, we don't parse "x do end" as an invocation
      # to a method x with a block. Instead, we just stop on x and we don't
      # consume the block, leaving the block for 'foo' to consume.
    else
      block = parse_block(block)
    end

    node =
      if block || block_arg || global
        Call.new nil, name, (args || [] of ASTNode), block, block_arg, named_args, global, name_column_number, last_call_has_parenthesis
      else
        if args
          if (!force_call && is_var) && args.size == 1 && (num = args[0]) && (num.is_a?(NumberLiteral) && num.has_sign?)
            sign = num.value[0].to_s
            num.value = num.value.byte_slice(1)
            Call.new(Var.new(name), sign, args)
          else
            Call.new(nil, name, args, nil, block_arg, named_args, global, name_column_number, last_call_has_parenthesis)
          end
        else
          if @token.type == :"::"
            next_token_skip_space_or_newline
            declared_type = parse_single_type
            declare_var = DeclareVar.new(Var.new(name).at(location), declared_type).at(location)
            add_var declare_var
            declare_var
          elsif (!force_call && is_var)
            if @block_arg_name && !@uses_block_arg && name == @block_arg_name
              @uses_block_arg = true
            end
            Var.new name
          else
            Call.new nil, name, [] of ASTNode, nil, block_arg, named_args, global, name_column_number, last_call_has_parenthesis
          end
        end
      end
    node.doc = doc
    node.end_location = block.try(&.end_location) || call_args.try(&.end_location) || end_location
    node
  end

  def preserve_last_call_has_parenthesis
    old_last_call_has_parenthesis = @last_call_has_parenthesis
    value = yield
    last_call_has_parenthesis = @last_call_has_parenthesis
    @last_call_has_parenthesis = old_last_call_has_parenthesis
    {value, last_call_has_parenthesis}
  end

  def parse_block(block)
    if @token.keyword?(:do)
      raise "block already specified with &" if block
      parse_block2 { check_ident "end" }
    elsif @token.type == :"{"
      raise "block already specified with &" if block
      parse_block2 { check :"}" }
    else
      block
    end
  end

  def parse_block2
    block_args = [] of Var
    block_body = nil

    next_token_skip_space
    if @token.type == :"|"
      next_token_skip_space_or_newline
      while @token.type != :"|"
        case @token.type
        when :IDENT
          arg_name = @token.value.to_s
        when :UNDERSCORE
          arg_name = "_"
        else
          raise "expecting block argument name, not #{@token.type}", @token
        end

        var = Var.new(arg_name).at(@token.location)
        block_args << var

        next_token_skip_space_or_newline
        if @token.type == :","
          next_token_skip_space_or_newline
        end
      end
      next_token_skip_statement_end
    else
      skip_statement_end
    end

    # current_vars = @scope_stack.last.dup
    # push_scope current_vars
    push_scope
    add_vars block_args

    block_body = parse_expressions

    pop_scope

    yield

    end_location = token_end_location
    next_token_skip_space

    Block.new(block_args, block_body).at_end(end_location)
  end

  record CallArgs, args, block, block_arg, named_args, stopped_on_do_after_space, end_location

  def parse_call_args(stop_on_do_after_space = false, allow_curly = false)
    case @token.type
    when :"{"
      @last_call_has_parenthesis = false
      nil
    when :"("
      slash_is_regex!

      args = [] of ASTNode
      end_location = nil

      open("call") do
        next_token_skip_space_or_newline
        while @token.type != :")"
          if call_block_arg_follows?
            return parse_call_block_arg(args, true)
          end

          if @token.type == :IDENT && current_char == ':'
            named_args = parse_named_args(allow_newline: true)

            if call_block_arg_follows?
              return parse_call_block_arg(args, true, named_args)
            end

            check :")"
            end_location = token_end_location

            next_token_skip_space
            return CallArgs.new args, nil, nil, named_args, false, end_location
          else
            args << parse_call_arg
          end

          skip_space_newline_or_indent
          if @token.type == :","
            slash_is_regex!
            next_token_skip_space_or_newline
          else
            check :")"
            break
          end
        end
        end_location = token_end_location
        next_token_skip_space
        @last_call_has_parenthesis = true
      end

      CallArgs.new args, nil, nil, nil, false, end_location
    when :SPACE
      slash_is_not_regex!
      end_location = token_end_location
      next_token
      @last_call_has_parenthesis = false

      if stop_on_do_after_space && @token.keyword?(:do)
        return CallArgs.new nil, nil, nil, nil, true, end_location
      end

      parse_call_args_space_consumed check_plus_and_minus: true, allow_curly: allow_curly
    else
      @last_call_has_parenthesis = false
      nil
    end
  end

  def parse_call_args_space_consumed(check_plus_and_minus = true, allow_curly = false)
    if @token.keyword?(:as) || @token.keyword?("end")
      return nil
    end

    case @token.type
    when :"&"
      return nil if current_char.whitespace?
    when :"+", :"-"
      if check_plus_and_minus
        return nil if current_char.whitespace?
      end
    when :"{"
      return nil unless allow_curly
    when :CHAR, :STRING, :DELIMITER_START, :STRING_ARRAY_START, :SYMBOL_ARRAY_START, :NUMBER, :IDENT, :SYMBOL, :INSTANCE_VAR, :CLASS_VAR, :CONST, :GLOBAL, :"$~", :"$?", :GLOBAL_MATCH_DATA_INDEX, :REGEX, :"(", :"!", :"[", :"[]", :"+", :"-", :"~", :"&", :"->", :"{{", :__LINE__, :__FILE__, :__DIR__, :UNDERSCORE
      # Nothing
    when :"..." # *TODO* verify - was :"*"
      if current_char.whitespace?
        return nil
      end
    when :"::"
      if current_char.whitespace?
        return nil
      end
    else
      return nil
    end

    case @token.value
    when :if, :unless, :while, :until, :rescue, :ensure
      return nil
    when :yield
      return nil if @stop_on_yield > 0
    end

    args = [] of ASTNode
    end_location = nil

    while @token.type != :NEWLINE && @token.type != :";" && @token.type != :EOF && @token.type != :")" && @token.type != :":" && !is_end_token
      if call_block_arg_follows?
        return parse_call_block_arg(args, false)
      end

      if @token.type == :IDENT && current_char == ':'
        named_args = parse_named_args

        if call_block_arg_follows?
          return parse_call_block_arg(args, false, named_args: named_args)
        end

        end_location = token_end_location

        skip_space
        return CallArgs.new args, nil, nil, named_args, false, end_location
      else
        arg = parse_call_arg
        args << arg
        end_location = arg.end_location
      end

      skip_space

      if @token.type == :","
        slash_is_regex!
        next_token_skip_space_or_newline
      else
        break
      end
    end

    CallArgs.new args, nil, nil, nil, false, end_location
  end

  def parse_named_args(allow_newline = false)
    named_args = [] of NamedArgument
    while true
      location = @token.location
      name = @token.value.to_s

      if named_args.any? { |arg| arg.name == name }
        raise "duplicated named argument: #{name}", @token
      end

      next_token
      check :":"
      next_token_skip_space_or_newline
      value = parse_op_assign
      named_args << NamedArgument.new(name, value).at(location)
      skip_space_newline_or_indent if allow_newline
      if @token.type == :","
        next_token_skip_space_or_newline
        if @token.type == :")" || @token.type == :"&"
          break
        end
      else
        break
      end
    end
    named_args
  end

  def parse_call_arg
    if @token.keyword?(:out)
      parse_out
    else
      splat = false
      if @token.type == :"..."
        unless current_char.whitespace?
          splat = true
          next_token
        end
      end
      arg = parse_op_assign_no_control
      arg = Splat.new(arg).at(arg.location) if splat
      arg
    end
  end

  def parse_out
    next_token_skip_space_or_newline
    location = @token.location
    name = @token.value.to_s

    case @token.type
    when :IDENT
      var = Var.new(name).at(location)
      var_out = Out.new(var).at(location)
      add_var var

      next_token
      var_out
    when :INSTANCE_VAR
      ivar = InstanceVar.new(name).at(location)
      ivar_out = Out.new(ivar).at(location)

      add_instance_var name

      next_token
      ivar_out
    when :UNDERSCORE
      underscore = Underscore.new.at(location)
      var_out = Out.new(underscore).at(location)
      next_token
      var_out
    else
      raise "expecting variable or instance variable after out"
    end
  end

  def parse_ident_or_global_call
    location = @token.location
    next_token_skip_space_or_newline

    case @token.type
    when :IDENT
      set_visibility parse_var_or_call global: true
    when :CONST
      parse_ident_after_colons(location, true, true)
    else
      unexpected_token
    end
  end

  def parse_ident(allow_type_vars = true)
    location = @token.location

    dbg "parse_ident"

    global = false

    case @token.type
    when :"::"
      global = true
      next_token_skip_space_or_newline
    when :UNDERSCORE
      return node_and_next_token Underscore.new.at(location)
    end

    check :CONST
    parse_ident_after_colons(location, global, allow_type_vars)
  end

  def parse_ident_after_colons(location, global, allow_type_vars)
    start_line = location.line_number
    start_column = location.column_number

    dbg "parse_ident_after_colons"

    names = [] of String
    names << @token.value.to_s
    end_location = token_end_location

    next_token
    while @token.type == :"::"
      next_token_skip_space_or_newline
      names << check_const
      end_location = token_end_location
      next_token
    end

    const = Path.new(names, global).at(location)
    const.end_location = end_location

    token_location = @token.location
    if token_location && token_location.line_number == start_line
      const.name_size = token_location.column_number - start_column
    end

    if allow_type_vars && @token.type == :"<"
      next_token_skip_space

      types = parse_types allow_primitives: true
      if types.empty?
        raise "must specify at least one type var"
      end

      check :">"
      const = Generic.new(const, types).at(location)
      const.end_location = token_end_location

      next_token_skip_space
    end

    dbg "eof parse_ident_after_colons"

    const
  end



  ######## ##    ## ########  ########  ######
     ##     ##  ##  ##     ## ##       ##    ##
     ##      ####   ##     ## ##       ##
     ##       ##    ########  ######    ######
     ##       ##    ##        ##             ##
     ##       ##    ##        ##       ##    ##
     ##       ##    ##        ########  ######

  def parse_arg_type()
    dbg "parse_arg_type - check pre mods"

    if (is_mod_mut = next_is_mut_modifier?())
      is_mod_const = false
    else
      is_mod_const = next_is_const_modifier?()
    end

    type = parse_single_type false

    dbg "parse_arg_type - after parse_simple_type"

    if (is_val_mut = next_is_mut_modifier?())
      is_val_const = false
    else
      is_val_const = next_is_const_modifier?()
    end

    dbg "parse_arg_type - checks done"

    {is_mod_const, is_mod_mut, type, is_val_const, is_val_mut}

  end

  def parse_types(allow_primitives = false)
    type_list = [] of ASTNode
    type_list << parse_type allow_primitives

    while @token.type == :"," || @token.type == :";"
      next_token_skip_space_or_newline
      type_list << parse_type allow_primitives
    end

    type_list
  end

  def parse_single_type(allow_primitives = false)
    location = @token.location
    type = parse_type allow_primitives
    case type
    when Array
      raise "unexpected ',' in type (use parenthesis to disambiguate)", location
    when ASTNode
      type
    else
      raise "Bug"
    end
  end

  def parse_type(allow_primitives)
    location = @token.location

    dbg "parse_type"

    if token?(:"(")
      dbg "is '('"
      next_token_skip_space_or_newline
      return parse_type_lambda_or_group(location, allow_primitives) as ASTNode  # needed to not muck up inference
    else
      dbg "is not '('"
      ret = parse_type_union allow_primitives
      dbg "parse_type got type from type_union()"
      return ret
    end
  end

  def splat(val)
    val.is_a?(Array) ? val : [val]
  end

  def parse_type_lambda_or_group(location, allow_primitives)
    dbg "parse_type_lambda_or_group"

    if token?(:"->")
      param_type_list = nil
    else
      param_type_list = splat parse_type(allow_primitives)
      #param_type_list = splat parse_type_union(allow_primitives)

      while token?(:",") || token?(:";")
        next_token_skip_space_or_newline

        dbg "next param_type_list"

        if token?(:"->")
          raise "Does this even happen? '->' and then some - [remove me when known] (inside paren ret-type syntax style!?)"
          next_types = parse_type(false)
          case next_types
          when Array
            param_type_list.concat next_types
          when ASTNode
            param_type_list << next_types
          end
          next
        else
          #type_union = parse_type_union(allow_primitives)
          type = parse_type(allow_primitives)
          #if type.is_a?(Array)
          #  param_type_list.concat type
          #else
          param_type_list << type
          #end
        end
      end
    end

    lambda_end_paren = false

    if token? :")"
      lambda_end_paren = true
      next_token_skip_space
    end

    if token? :"->"
      next_token_skip_space

      case @token.type
      when :",", :")", :"}", :";", :NEWLINE
        return_type = nil
      else
        return_type = parse_type(allow_primitives)
        if return_type.is_a?(Array)
          raise "can't return more than one type", location.line_number, location.column_number
        end
      end

      if !lambda_end_paren && token? :")"
        lambda_end_paren = true
        next_token_skip_space
      end

      if !lambda_end_paren
        raise "unterminated lambda type", location.line_number, location.column_number
      end

      return Fun.new(param_type_list, return_type).at(location)

    else
      if !lambda_end_paren
          # *TODO* if try_parse return nil else raise...
        raise "unterminated parenthesis or lambda type", location.line_number, location.column_number
      end

      param_type_list = param_type_list.not_nil!
      if param_type_list.size == 1
        return param_type_list.first
      else
        #return param_type_list
        raise "expected one type - found a list"
      end
    end
  end

  def parse_type_union(allow_primitives)
    types = [] of ASTNode

    dbg "parse_type_union"

    types << parse_typeunit_with_suffix allow_primitives

    dbg "after parse_typeunit_with_suffix"

    if @token.type == :"|"
      while @token.type == :"|"
        next_token_skip_space_or_newline
        types << parse_typeunit_with_suffix allow_primitives
      end

      if types.size == 1
        dbg "after '|' loop, one type: " + types.first.to_s
        return types.first
      else
        dbg "after '|' loop, got union: " + types.to_s
        return Union.new types
      end

    elsif types.size == 1
      dbg "after '|' CHECK, got single type: " + types.first.to_s
      return types.first

    else
      raise "expected one type (or type union) - found a list"
      # dbg "!!? after '|' CHECK, got multiple types (!?): " + types.to_s + " at"
      # return types
    end
  end

  def parse_typeunit_with_suffix(allow_primitives) : ASTNode
    dbg "parse_typeunit_with_suffix"
    # *TODO* *TYPE*
    if @token.keyword? :SelfType
      dbg "was 'Self'"
      type = Self.new
      next_token_skip_space

    elsif @token.keyword?(:auto) || token?(:"*")
      dbg "was 'auto'"
      type = Underscore.new       # *TODO* - we want a specific "Auto" node!
      next_token_skip_space

    else
      case @token.type
      when :"("
        next_token_skip_space_or_newline
        type = parse_type(allow_primitives)
        check :")"
        next_token_skip_space
        case type
        when ASTNode
          # skip
        when Array
          raise "expected one type - got a list"
        else
          raise "Bug"
        end
      else
        if allow_primitives && token? :NUMBER
          num = NumberLiteral.new(@token.value.to_s, @token.number_kind).at(@token.location)
          type = node_and_next_token(num)
          skip_space
          return type
        end

        dbg "parse_typeunit_with_suffix, before parse_simple_type"
        type = parse_simple_type
        dbg "parse_typeunit_with_suffix, after parse_simple_type"

      end
    end

    parse_type_suffix type

  end

  def parse_simple_type : ASTNode
    if @token.keyword?(:typeof) # this is here because type–suffixes can be added
      type = parse_typeof

    else
      dbg "parse_simple_type, before parse_ident"
      type = parse_ident
      dbg "parse_simple_type, after parse_ident"
    end
    skip_space
    dbg "parse_simple_type, after skip_space"
    type
  end

  def parse_type_suffix(type)
    while true
      case @token.type
      when :"?"
        type = Union.new([type, Path.global("Nil")] of ASTNode)
        next_token_skip_space
      # *TODO* *TYPE* remove pointer shortcuts!?
      # when :"*"
      #   type = make_pointer_type(type)
      #   next_token_skip_space
      # when :"**"
      #   type = make_pointer_type(make_pointer_type(type))
      #   next_token_skip_space

      # For sizing a static array..
      when :"["
        next_token_skip_space
        size = parse_single_type allow_primitives: true
        check :"]"
        next_token_skip_space
        type = make_static_array_type(type, size)
      when :"+"
        type = Virtual.new(type)
        next_token_skip_space
      when :"."
        next_token
        check_ident :type
        type = Metaclass.new(type)
        next_token_skip_space
      else
        break
      end
    end
    type
  end

  def parse_typeof
    next_token_skip_space
    check :"("
    next_token_skip_space_or_newline
    if @token.type == :")"
      raise "missing typeof argument"
    end

    exps = [] of ASTNode
    while @token.type != :")"
      exps << parse_op_assign
      if @token.type == :","
        next_token_skip_space_or_newline
      end
    end

    end_location = token_end_location
    next_token_skip_space

    TypeOf.new(exps).at_end(end_location)
  end

  def next_is_mut_modifier?()
    dbg "next_is_mut_modifier?"

    #is_mut = @token.type == :"mut"
    is_mut = @token.type == :IDENT && @token.value == "mut"
    is_mut ||= @token.type == :"~"

    if is_mut
      next_token_skip_space
      true
    else
      false
    end
  end

  def next_is_const_modifier?()
    is_const = @token.type == :IDENT && @token.value == "const"
    #is_const = @token.type == :"const"
    is_const ||= @token.type == :"'"

    if is_const
      next_token_skip_space
      true
    else
      false
    end
  end



  ########  #######     ######## ##    ## ########  ########  ######
  ##       ##     ##       ##     ##  ##  ##     ## ##       ##    ##
  ##       ##     ##       ##      ####   ##     ## ##       ##
  ######   ##     ##       ##       ##    ########  ######    ######
  ##       ##     ##       ##       ##    ##        ##             ##
  ##       ##     ##       ##       ##    ##        ##       ##    ##
  ########  #######        ##       ##    ##        ########  ######


  def make_pointer_type(node)
    Generic.new(Path.global("Pointer").at(node), [node] of ASTNode).at(node)
  end

  def make_static_array_type(type, size)
    Generic.new(Path.global("StaticArray").at(type), [type, size] of ASTNode).at(type.location).at(type)
  end

  def make_tuple_type(types)
    Generic.new(Path.global("Tuple"), types)
  end



  def parse_visibility_modifier(modifier)
    doc = @token.doc

    next_token_skip_space
    exp = parse_op_assign

    modifier = VisibilityModifier.new(modifier, exp)
    modifier.doc = doc
    exp.doc = doc
    modifier
  end

  def parse_asm
    next_token_skip_space
    check :"("
    next_token_skip_space_or_newline
    text = parse_string_without_interpolation { "interpolation not allowed in asm" }
    skip_space_newline_or_indent

    volatile = false
    alignstack = false
    intel = false

    unless @token.type == :")"
      if @token.type == :"::"
        # No output operands
        next_token_skip_space_or_newline

        if @token.type == :DELIMITER_START
          inputs = parse_asm_operands
        end
      else
        check :":"
        next_token_skip_space_or_newline

        if @token.type == :DELIMITER_START
          output = parse_asm_operand
        end

        if @token.type == :":"
          next_token_skip_space_or_newline

          if @token.type == :DELIMITER_START
            inputs = parse_asm_operands
          end
        end
      end

      if @token.type == :"::"
        next_token_skip_space_or_newline
        volatile, alignstack, intel = parse_asm_options
      else
        if @token.type == :":"
          next_token_skip_space_or_newline
          clobbers = parse_asm_clobbers
        end

        if @token.type == :":"
          next_token_skip_space_or_newline
          volatile, alignstack, intel = parse_asm_options
        end
      end

      check :")"
    end

    next_token_skip_space

    Asm.new(text, output, inputs, clobbers, volatile, alignstack, intel)
  end

  def parse_asm_operands
    operands = [] of AsmOperand
    while true
      operands << parse_asm_operand
      if @token.type == :","
        next_token_skip_space_or_newline
      end
      break unless @token.type == :DELIMITER_START
    end
    operands
  end

  def parse_asm_operand
    text = parse_string_without_interpolation { "interpolation not allowed in constraint" }
    check :"("
    next_token_skip_space_or_newline
    exp = parse_expression
    check :")"
    next_token_skip_space_or_newline
    AsmOperand.new(text, exp)
  end

  def parse_asm_clobbers
    clobbers = [] of String
    while true
      clobbers << parse_string_without_interpolation { "interpolation not allowed in asm clobber" }
      skip_space_newline_or_indent
      if @token.type == :","
        next_token_skip_space_or_newline
      end
      break unless @token.type == :DELIMITER_START
    end
    clobbers
  end

  def parse_asm_options
    volatile = false
    alignstack = false
    intel = false
    while true
      location = @token.location
      option = parse_string_without_interpolation { "interpolation not allowed in asm clobber" }
      skip_space_newline_or_indent
      case option
      when "volatile"
        volatile = true
      when "alignstack"
        alignstack = true
      when "intel"
        intel = true
      else
        raise "unkown asm option: #{option}", location
      end

      if @token.type == :","
        next_token_skip_space_or_newline
      end
      break unless @token.type == :DELIMITER_START
    end
    {volatile, alignstack, intel}
  end

  def parse_yield_with_scope
    location = @token.location
    next_token_skip_space
    @stop_on_yield += 1
    @yields ||= 1
    scope = parse_op_assign
    @stop_on_yield -= 1
    skip_space
    check_ident :yield
    parse_yield scope, location
  end

  def parse_yield(scope = nil, location = @token.location)
    end_location = token_end_location
    next_token

    call_args, last_call_has_parenthesis = preserve_last_call_has_parenthesis { parse_call_args }

    if call_args
      args = call_args.args
      end_location = nil
    end

    yields = (@yields ||= 0)
    if args && args.size > yields
      @yields = args.size
    end

    Yield.new(args || [] of ASTNode, scope).at(location).at_end(end_location)
  end

  def parse_break
    parse_control_expression Break
  end

  def parse_return
    parse_control_expression Return
  end

  def parse_next
    parse_control_expression Next
  end

  def parse_control_expression(klass)
    end_location = token_end_location
    next_token

    call_args, last_call_has_parenthesis = preserve_last_call_has_parenthesis { parse_call_args allow_curly: true }
    args = call_args.args if call_args

    if args
      if args.size == 1
        node = klass.new(args.first)
      else
        tuple = TupleLiteral.new(args).at(args.last)
        node = klass.new(tuple)
      end
    else
      node = klass.new.at_end(end_location)
    end

    node
  end

  def parse_lib
    next_token_skip_space_or_newline

    name = check_const
    name_column_number = @token.column_number
    next_token_skip_statement_end

    body = parse_lib_body

    check_ident "end"
    next_token_skip_space

    LibDef.new name, body, name_column_number
  end

  def parse_lib_body
    expressions = [] of ASTNode
    while true
      skip_statement_end
      break if is_end_token
      expressions << parse_lib_body_exp
    end
    expressions
  end

  def parse_lib_body_exp
    location = @token.location
    parse_lib_body_exp_without_location.at(location)
  end

  def parse_lib_body_exp_without_location
    case @token.type
    when :"@["
      parse_attribute
    when :IDENT
      case @token.value
      when :alias
        parse_alias
      when :fun
        parse_fun_def
      when :type
        parse_type_def
      when :struct
        @inside_c_struct = true
        node = parse_struct_or_union StructDef
        @inside_c_struct = false
        node
      when :union
        parse_struct_or_union UnionDef
      when :enum
        parse_enum_def
      when :ifdef
        parse_ifdef check_end: true, mode: :lib
      else
        unexpected_token
      end
    when :CONST
      ident = parse_ident
      next_token_skip_space
      check :"="
      next_token_skip_space_or_newline
      value = parse_expression
      skip_statement_end
      Assign.new(ident, value)
    when :GLOBAL
      location = @token.location
      name = @token.value.to_s[1 .. -1]
      next_token_skip_space_or_newline
      if @token.type == :"="
        next_token_skip_space
        check IdentOrConst
        real_name = @token.value.to_s
        next_token_skip_space
      end
      check :":"
      next_token_skip_space_or_newline
      type = parse_single_type

      if 'A' <= name[0] <= 'Z'
        raise "external variables must start with lowercase, use for example `$#{name.underscore} = #{name} : #{type}`", location
      end

      skip_statement_end
      ExternalVar.new(name, type, real_name)
    else
      unexpected_token
    end
  end

  IdentOrConst = [:IDENT, :CONST]

  def parse_fun_def(require_body = false)
    doc = @token.doc

    push_fresh_scope if require_body

    next_token_skip_space_or_newline
    name = check_ident
    next_token_skip_space_or_newline

    if @token.type == :"="
      next_token_skip_space_or_newline
      case @token.type
      when :IDENT, :CONST
        real_name = @token.value.to_s
        next_token_skip_space_or_newline
      when :DELIMITER_START
        real_name = parse_string_without_interpolation { "interpolation not allowed in fun name" }
        skip_space
      else
        unexpected_token
      end
    else
      real_name = name
    end

    args = [] of Arg
    varargs = false

    if @token.type == :"("
      next_token_skip_space_or_newline
      while @token.type != :")"
        if @token.type == :"..."
          varargs = true
          next_token_skip_space_or_newline
          check :")"
          break
        end

        if @token.type == :IDENT
          arg_name = @token.value.to_s
          arg_location = @token.location

          next_token_skip_space_or_newline
          check :":"
          next_token_skip_space_or_newline
          arg_type = parse_single_type
          skip_space_newline_or_indent

          args << Arg.new(arg_name, nil, arg_type).at(arg_location)

          add_var arg_name if require_body
        else
          arg_types = parse_types
          arg_types.each do |arg_type_2|
            args << Arg.new("", nil, arg_type_2).at(arg_type_2.location)
          end
        end

        if @token.type == :","
          next_token_skip_space_or_newline
        end
      end
      next_token_skip_statement_end
    end

    if @token.type == :":"
      next_token_skip_space_or_newline
      return_type = parse_single_type
    end

    skip_statement_end

    if require_body
      if @token.keyword?("end")
        body = Nop.new
        next_token
      else
        body = parse_expressions
        body, end_location = parse_exception_handler body
      end
    else
      body = nil
    end

    pop_scope if require_body

    fun_def = FunDef.new name, args, return_type, varargs, body, real_name
    fun_def.doc = doc
    fun_def
  end

  def parse_alias
    doc = @token.doc

    next_token_skip_space_or_newline
    name = check_const
    next_token_skip_space_or_newline
    check :"="
    next_token_skip_space_or_newline

    value = parse_single_type
    skip_space

    alias_node = Alias.new(name, value)
    alias_node.doc = doc
    alias_node
  end

  def parse_pointerof
    next_token_skip_space

    check :"("
    next_token_skip_space_or_newline

    if @token.keyword?(:self)
      raise "can't take pointerof(self)", @token.line_number, @token.column_number
    end

    exp = parse_op_assign
    skip_space

    end_location = token_end_location
    check :")"
    next_token_skip_space

    PointerOf.new(exp).at_end(end_location)
  end

  def parse_sizeof
    parse_sizeof SizeOf
  end

  def parse_instance_sizeof
    parse_sizeof InstanceSizeOf
  end

  def parse_sizeof(klass)
    next_token_skip_space

    check :"("
    next_token_skip_space_or_newline

    location = @token.location
    exp = parse_single_type.at(location)

    skip_space

    end_location = token_end_location
    check :")"
    next_token_skip_space

    klass.new(exp).at_end(end_location)
  end

  def parse_type_def
    next_token_skip_space_or_newline
    name = check_const
    name_column_number = @token.column_number
    next_token_skip_space_or_newline
    check :"="
    next_token_skip_space_or_newline

    type = parse_single_type
    skip_space

    TypeDef.new name, type, name_column_number
  end

  def parse_struct_or_union(klass)
    next_token_skip_space_or_newline
    name = check_const
    next_token_skip_statement_end
    body = parse_struct_or_union_body
    check_ident "end"
    next_token_skip_space

    klass.new name, Expressions.from(body)
  end

  def parse_struct_or_union_body
    exps = [] of ASTNode

    while true
      case @token.type
      when :IDENT
        case @token.value
        when :ifdef
          exps << parse_ifdef(mode: :struct_or_union)
        when :include
          if @inside_c_struct
            location = @token.location
            exps << parse_include.at(location)
          else
            parse_struct_or_union_fields exps
          end
        when :else
          break
        when "end"
          break
        else
          parse_struct_or_union_fields exps
        end
      when :";", :NEWLINE
        skip_statement_end
      else
        break
      end
    end

    exps
  end

  def parse_struct_or_union_fields(exps)
    args = [Arg.new(@token.value.to_s).at(@token.location)]

    next_token_skip_space_or_newline

    while @token.type == :","
      next_token_skip_space_or_newline
      args << Arg.new(check_ident).at(@token.location)
      next_token_skip_space_or_newline
    end

    check :":"
    next_token_skip_space_or_newline

    type = parse_single_type

    skip_statement_end

    args.each do |an_arg|
      an_arg.restriction = type
      exps << an_arg
    end
  end

  def parse_enum_def
    doc = @token.doc

    next_token_skip_space_or_newline

    name = parse_ident allow_type_vars: false
    skip_space

    case @token.type
    when :":"
      next_token_skip_space_or_newline
      base_type = parse_single_type
      skip_statement_end
    when :";", :NEWLINE
      skip_statement_end
    else
      unexpected_token
    end

    members = [] of ASTNode
    until @token.keyword?("end")
      case @token.type
      when :CONST
        location = @token.location
        constant_name = @token.value.to_s
        member_doc = @token.doc

        next_token_skip_space
        if @token.type == :"="
          next_token_skip_space_or_newline

          constant_value = parse_logical_or
          next_token_skip_statement_end
        else
          constant_value = nil
          skip_statement_end
        end

        case @token.type
        when :",", :";"
          next_token_skip_statement_end
        end

        arg = Arg.new(constant_name, constant_value).at(location)
        arg.doc = member_doc

        members << arg
      when :IDENT
        visibility = nil

        case @token.value
        when :private
          visibility = :private
          next_token_skip_space
        when :protected
          visibility = :protected
          next_token_skip_space
        end

        if @token.value == :def
          member = parse_def
          member = VisibilityModifier.new(visibility, member) if visibility
          members << member
        else
          unexpected_token
        end
      when :CLASS_VAR
        class_var = ClassVar.new(@token.value.to_s).at(@token.location)

        next_token_skip_space
        check :"="
        next_token_skip_space_or_newline
        value = parse_op_assign

        members << Assign.new(class_var, value).at(class_var)
      when :";", :NEWLINE
        skip_statement_end
      else
        unexpected_token
      end
    end

    check_ident "end"
    next_token_skip_space

    raise "Bug: EnumDef name can only be a Path" unless name.is_a?(Path)

    enum_def = EnumDef.new name, members, base_type
    enum_def.doc = doc
    enum_def
  end

  def node_and_next_token(node)
    node.end_location = token_end_location
    next_token
    node
  end

  def token?(token : Symbol|String)
    @token.type == token
  end

  def token?(tokens : Array(T))
    tokens.each do |t|
      return true if @token.type == t
    end
    false
  end

  def is_end_token
    case @token.type
    when :"}", :"]", :"%}", :EOF, :DEDENT
      return true
    end

    if @token.type == :IDENT
      case @token.value
      when :do, :else, :elsif, :when, :rescue, :ensure
        return true
      end

      if is_explicit_end_token?
        return true
      end

    end

    false
  end

  def can_be_assigned?(node)
    case node
    when Var, InstanceVar, ClassVar, Path, Global, Underscore
      true
    when Call
      (node.obj.nil? && node.args.size == 0 && node.block.nil?) || node.name == "[]"
    else
      false
    end
  end

  def push_fresh_scope
    @scope_stack.push_scope(Scope.new)  # push(Set(String).new)
  end

  def push_scope(args)
    push_scope(Scope.new(args.map &.name))
    ret = yield
    pop_scope
    ret
  end

  def push_scope(scope)
    @scope_stack.push_scope(scope)
  end

  def push_scope
    @scope_stack.push_scope
  end

  def pop_scope
    @scope_stack.pop_scope()
  end

  def add_vars(vars)
    vars.each do |var|
      add_var var
    end
  end

  def add_var(var : Var | Arg | BlockArg)
    add_var var.name.to_s
  end

  def add_var(var : DeclareVar)
    var_var = var.var
    case var_var
    when Var
      add_var var_var.name
    when InstanceVar
      add_var var_var.name
    else
      raise "can't happen"
    end
  end

  def add_var(name : String)
    @scope_stack.add_var name
  end

  def add_var(node)
    # Nothing
  end

  def open(symbol, location = @token.location)
    @unclosed_stack.push Unclosed.new(symbol, location)
    begin
      value = yield
    ensure
      @unclosed_stack.pop
    end
    value
  end





  def maybe_skip_anydents
    return if @paren_nest == 0
    if token?(:INDENT) || token?(:DEDENT)  || token?(:NEWLINE)
      next_token_skip_space_or_newline
    end
  end



  # *TODO* - we could let handle_block_start take care of :if, name, etc. also

  def handle_block_start(kind = :generic : Symbol)
    # *TODO* we don't pass the syntax used, so a stylizer would have to look at
    # the source via "location"

    ret = if (token?([:"=>", :"do", :"then"]) ||
        (kind == :def && token?(:"->"))
    )
      next_token_skip_space

      if token? :INDENT
        next_token
        :BLOCK
      elsif token? [:DEDENT, :NEWLINE]
        :NIL_BLOCK
      else
        @oneline_nest += 1
        :LINE_BLOCK
      end

    elsif kind == :if && token?(:"?")
      next_token_skip_space_newline_or_indent
      :TERNARY

    else
      if token? :INDENT
        next_token
        :BLOCK
      elsif token? :NEWLINE
        :NIL_BLOCK
      else
        raise "unexpected token, expected code-block to start"
      end
    end


    # This has to be handled the "correct way"
    # if ret == :NIL_BLOCK
    #   de_nest @indent, end_token, match_name
    # end

    ret

  end


  # *TODO* current_nest_indent - but also wacked jump from @indent that be

  def is_explicit_end_token?
    dbg "is_explicit_end_token?"
    return false unless token? :IDENT
    val = @token.value
    #dbg "is_explicit_end_token? is identifier"
    return false  unless val.is_a? String
    #dbg "is_explicit_end_token? was a string?"
    return false if val.size < 3
    #dbg "is_explicit_end_token? size >= 3"
    return false unless val[0..2] == "end"
    dbg "is_explicit_end_token? 0..3 == 'end'?"
    return true  if val.size == 3
    dbg "is_explicit_end_token? len > 3, check more"

    sep = val[3]
    #dbg "is_explicit_end_token? sep == '" + sep + "'"
    return false unless sep == '-' || sep  == '_' || sep == '–'

    last_part = val[4..-1]
    #dbg "is_explicit_end_token? last part = '" + last_part + "'"

    #p Nesting.nesting_keywords

    if Nesting.nesting_keywords.includes? (last_part).to_s
      dbg "is_explicit_end_token? part found in kwd list"
      true
    else # just some identifier with similar name
      dbg "is_explicit_end_token? part NOT found in kwd list"
      false
    end
  end

  def add_nest(nest_kind : Symbol, indent : Int32, match_name : String, require_end_token : Bool)
    dbg "ADD NESTING:   '" + nest_kind.to_s + "'  at " + indent.to_s
    @nesting_stack.add nest_kind, indent, match_name, require_end_token
    dbg @nesting_stack.dbgstack
  end

  def de_nest(indent, end_token, match_name)
    @nesting_stack.dedent indent, end_token, match_name
  end

  def current_nest_indent : Int32
    @nesting_stack.last.indent
  end

  def handle_updent
    dbg "handle_updent at " + @token.to_s
    return false  unless token?(:INDENT)

    if @token.value as Int32 > current_nest_indent
      #if @indent > current_nest_indent
      #  raise "unexpected indent"
      #else
      #  @indent = @token.value as Int32
      #end
      next_token
      return true

    elsif @token.value == @indent
      next_token
      return false
    else
      return false
    end
  end


  def handle_blockend
    dbg "handle_blockend"

    if @oneline_nest == 0
      handle_dedent_blockend

    else
      handle_oneline_blockend
    end

  end

  def handle_oneline_blockend
    dbg "handle_oneline_blockend"
    case
    when token? :NEWLINE
      @oneline_nest = 0
      handle_definite_blockend_
      return true

    when token? :DEDENT
      @oneline_nest = 0
      return handle_dedent_blockend

    when is_explicit_end_token?
      @oneline_nest -= 1
      handle_definite_blockend_
      return true

    else
      return false
    end
  end

  def handle_dedent_blockend
    dbg "handle_dedent_blockend"
    return false  unless token?([:DEDENT, :NEWLINE])  # should newline be an option, called from NILBLOCK situation?

    # val = @token.value
    # return false  unless val.is_a? Int32
    # if val > current_nest_indent
    # #else #if @token.value == @indent
    #   dbg "handle_blockend: NO DEDENT, nest=" + current_nest_indent.to_s + ", current=" + val.to_s
    #   return false
    # end

    handle_definite_blockend_

  end

  def handle_definite_blockend_
    dbg "handle_definite_blockend_"

    @temp_token.copy_from @token # the dedent–token only
    last_backed = backed = backup_pos
    next_token

    if token? [:NEWLINE, :DEDENT]
      dbg "handle_definite_blockend_: consumed NEWLINE|DEDENT"
      last_backed = backup_pos
      next_token_skip_space_or_newline
    end

    if is_explicit_end_token?
      end_token = @token.value.to_s
      dbg "handle_definite_blockend_ is DEDENT: explicit end-token '" + end_token + "'"
      last_backed = backup_pos
      next_token

      # is there a name–matching?
      if token? :"="
        next_token
        match_name = parse_ident.to_s
        dbg "handle_definite_blockend_ got match name '" + match_name + "'"
        last_backed = backup_pos
        next_token_skip_space
        if ! @token? [:NEWLINE, :";"]
          raise "expect newline or ';' after name-matched end-token, got '" + @token.to_s + "'"
        end
      else
        match_name = ""
      end
    else
      dbg "handle_definite_blockend_ is DEDENT: implicit end"
      end_token = ""
      match_name = ""
    end

    tmp_dbg_nest_kind = @nesting_stack.last.nest_kind.to_s

    case de_nest @indent, end_token, match_name
    when :"false"
      dbg @nesting_stack.dbgstack
      #raise "Nothing to pop on the nesting stack! Wtf?"
      dbg "de_nest returned :false - this was just a post-usage check then (to avoid suffix parse)"
      return false
    when :"more"
      dbg "POPPED NEST '" + tmp_dbg_nest_kind + "'"
      dbg "there's apparently MORE NESTINGS to pop, so we put back the dedent-token in queue"
      dbg @nesting_stack.dbgstack
      restore_pos backed
      @token.copy_from @temp_token
      return true
    when :"done"
      dbg "POPPED NEST '" + tmp_dbg_nest_kind + "'"
      dbg "all NESTINGS are DONE"

      restore_pos last_backed
      # Fake a "stop" token for suffix parsers etc.
      @token.type = :"NEWLINE"
      @token.line_number = @line_number
      @token.column_number = @column_number - 1

      #next_token_skip_space_or_newline
      return true
    else
      raise "internal error in handle_definite_blockend_ after de_nest"
    end

  end





  def check_void_value(exp, location)
    if exp.is_a?(ControlExpression)
      raise "void value expression", location
    end
  end

  def check_void_expression_keyword
    case @token.type
    when :IDENT
      case @token.value
      when :break, :next, :return
        raise "void value expression", @token, @token.value.to_s.size
      end
    end
  end

  def check(token_types : Array)
    raise "expecting any of these tokens: #{token_types.join ", "} (not '#{@token.type.to_s}')", @token unless token_types.any? { |type| @token.type == type }
  end

  def check(token_type)
    raise "expecting token '#{token_type}', not '#{@token.to_s}'", @token unless token_type == @token.type
  end

  def check_token(value)
    raise "expecting token '#{value}', not '#{@token.to_s}'", @token unless @token.type == :TOKEN && @token.value == value
  end

  def check_ident(value)
    raise "expecting identifier '#{value}', not '#{@token.to_s}'", @token unless @token.keyword?(value)
  end

  def check_ident
    check :IDENT
    @token.value.to_s
  end

  def check_const
    check :CONST
    @token.value.to_s
  end

  def unexpected_token(token = @token.to_s, msg = nil)
    if msg
      raise "unexpected token: #{token} (#{msg})", @token
    else
      raise "unexpected token: #{token}", @token
    end
  end

  def unexpected_token_in_atomic
    if unclosed = @unclosed_stack.last?
      raise "unterminated #{unclosed.name}", unclosed.location
    end

    unexpected_token
  end

  def is_var?(name)
    return true if @in_macro_expression

    name = name.to_s
    name == "self" || @scope_stack.cur_has?(name)
  end

  def add_instance_var(name)
    return if @in_macro_expression

    @instance_vars.try &.add name
  end

  def self.free_var_name?(name)
    # *TODO* - this should be changed in Onyx - any length free var names possible!
    name.size == 1 || (name.size == 2 && name[1].digit?)
  end


  # DEBUG UTILS #
  def dbginc
    @dbgindent__ += 2
  end

  def dbgdec
    @dbgindent__ -= 2
  end

  def dbg(str : String)
    puts (" " * @dbgindent__) + str + ", at: '" + @token.to_s +
      "' (" + @token.line_number.to_s + ":" + @token.column_number.to_s + ")"
  end

end

end # module
