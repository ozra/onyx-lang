require "set"
require "../../crystal/syntax/parser"
require "../semantic/babelfish_translations"

require "../../debug_utils/global_pollution"
require "../../debug_utils/ast_dump"

module Crystal

abstract class ASTNode
   macro def tag_onyx(val = true, visited = [] of ASTNode) : Nil
      @is_onyx = val
      {% for ivar, i in @type.instance_vars %}
         _{{ivar}} = @{{ivar}}
         if _{{ivar}}.is_a?(ASTNode)
            if !visited.includes? _{{ivar}}
               visited << _{{ivar}}
               _{{ivar}}.tag_onyx val, visited
               visited.pop
            end
         elsif _{{ivar}}.is_a?(Array(ASTNode))
            _{{ivar}}.each &.tag_onyx(val, visited)
         end
      {% end %}
      nil
   end
end

class WrongParsePathException < SyntaxException
end

macro raise_wrong_parse_path(msg = "Wrong parse path")
   dbgtail_off!
   ::raise WrongParsePathException.new({{msg}}, @token.line_number, @token.column_number, @token.filename, nil)
end

class CallSyntaxException < SyntaxException
end

alias TagLiteral = SymbolLiteral

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

   def dup
      Scope.new @vars
   end

   def dbgstack
      ifdef !release
         STDERR.puts "VARS:".blue
         STDERR.puts @vars
      end
   end

end

class ScopeStack
   @scopes = Array(Scope).new
   @current_scope = Scope.new # ugly way of avoiding null checks


   def initialize
      push_fresh_scope()
   end

   def initialize(vars_scopes_list : Array(Set(String)))
      vars_scopes_list.each do |var_set|
         push_scope Scope.new var_set
      end
   end

   def cur_has?(name)
      @scopes.last.includes? name
   end

   def last
      @current_scope
   end

   def size
      @scopes.size
   end

   def hard_pop(size) : Nil
      while @scopes.size > size
         pop_scope
      end
      nil
   end

   def pop_scope
      @scopes.pop
      @current_scope = @scopes.last
   end

   def push_scope(scope : Scope)
      @scopes.push scope
      @current_scope = scope
   end

   def push_fresh_scope
      push_scope Scope.new
   end

   def push_scope
      push_scope @scopes.last.dup
   end

   def add_var(name : String)
      @current_scope.add name
   end

   def dbgstack
      ifdef !release
         @scopes.each_with_index do |scope, i|
            #@scopes[@scopes.size - 2].dbgstack
            STDERR.puts "#{i}:"
            scope.dbgstack
         end
      end
   end
end


class Nesting
   property nest_kind
   property indent
   property name
   property require_end_token
   @auto_parametrization = false
   #property auto_parametrization
   @block_auto_params : Array(Var)?
   property block_auto_params
   property location
   property single_line

   property int_type_mapping : String
   property real_type_mapping : String

   @@std_int : String
   @@std_int = "StdInt"
   # @@std_int = Token.new
   # @@std_int.type = :CONST
   # @@std_int.value = "StdInt"

   @@std_real : String
   @@std_real = "StdReal"
   # @@std_real = Token.new
   # @@std_real.type = :CONST
   # @@std_real.value = "StdReal"

   @@nesting_keywords = %w(
      program
      module trait
      type enum class struct
      def fun block lambda
      template macro
      lib api
      cfun cstruct cunion cenum
      union ctype calias
      where
      scope scoped contain contained
      if ifdef unless else
      elif elsif
      case when
      while until for each loop
      try rescue catch ensure
      indent_call
   )

   def self.nesting_keywords
      @@nesting_keywords
   end

   def initialize(@nest_kind, @indent, @name, @location, @single_line, @require_end_token)
      @int_type_mapping = @@std_int
      @real_type_mapping = @@std_real

      if !Nesting.nesting_keywords.includes? @nest_kind.to_s
         raise "Shit went down - don't know about nesting kind '#{@nest_kind.to_s}'"
      end
   end

   def message_expected_end_tokens
      case @nest_kind
      when :program then "EOF"
         # when :module then "end or end-module"
         # when :if then "end or end-if"
         # when :try then "catch, end or end-try"
      else
         "\"end\" or \"end-" + @nest_kind.to_s + "\""
      end
   end

   def match_end_token(end_token : Symbol)
      end_token == :end || end_token.to_s == ("end_" + @nest_kind.to_s)
   end
end


class NestingStack
   @stack : Array(Nesting)

   def initialize
      @stack = [Nesting.new(:program, -1, "", Location.new(0, 0, ""), false, false)]
   end

   def add(kind : Symbol, indent : Int32, match_name, location, single_line, require_end_token)
      indent = last.indent   if indent == -1
      nest = Nesting.new kind, indent, match_name, location, single_line, require_end_token
      nest.int_type_mapping = last.int_type_mapping
      nest.real_type_mapping = last.real_type_mapping
      @stack.push nest
   end

   def last
      @stack.last
   end

   def size
      @stack.size
   end

   def hard_pop(size) : Nil
      while @stack.size > size
         @stack.pop
      end
      nil
   end

   def in_auto_paramed?
      @stack.reverse.each do |v|
         if v.nest_kind == :block
            return v.block_auto_params != nil
         end
         false
      end

   end

   private def pop_and_status(indent : Int32, force : Bool) : Symbol
      @stack.pop

      # if indent <= last.indent && (force || !last.require_end_token) # *TODO* "no automatic dedent"
      if indent <= last.indent && size > 1
         # p @stack.to_s
         :more
      else
         :done
      end
   end

   def dedent(indent : Int32, end_token : Symbol, match_name : String, force = false) : Symbol | String
      # while true
      nest = @stack.last

      if indent < nest.indent
         ifdef !release
            STDERR.puts "indents left to match alignment in nesting_stack:"
         end
         (@stack.size - 1..0).each do |i|
            ifdef !release
               STDERR.puts "ind: #{@stack[i].indent}"
            end
            # *TODO*
            # check so that the indent–level EXISTS further up (we don't allow dedent
            # to an "unspecified level" (in between)
         end

         return pop_and_status indent, force

      elsif nest.indent == indent
         case
         when end_token == :""
            return pop_and_status indent, force

         when nest.match_end_token end_token
            case
            when match_name == ""
               return pop_and_status indent, force
            when nest.name == match_name
               return pop_and_status indent, force
            else
            # *TODO* start–row+col för nest ska lagras så den kan returneras med error
            # så att matching start–part kan visas också (extra hjälp)

               return "explicit end-token \"#{(end_token.to_s + " " + match_name).strip}\"" \
               " doesn't match expected" \
               " \"#{(nest.message_expected_end_tokens + " " + nest.name).strip}\""
            end
         else
         # *TODO* start–row+col för nest ska lagras så den kan returneras med error
         # så att matching start–part kan visas också (extra hjälp)

            return "explicit end-token \"#{end_token}\"" \
            " doesn't match expected #{nest.message_expected_end_tokens}"
         end
      else
         return :"false" # NOTE! SYMBOL :false
      end
      # end
   end

   def dbgstack
      ifdef !release
         ret = "NEST-STACK:\n"
         @stack.each do |v|
            ret += "'#{v.nest_kind}', #{v.indent}, #{(v.single_line ? "S" : "m")}, \"#{v.name}\" @ #{v.location.line_number}:#{v.location.column_number}\n"
         end
         ret += "\n"
         ret
      else
         ""
      end
   end
end


#       ########      ###   ########    ######   ######   ########
#       ##       ##   ## ##    ##    ## ##      ## ##          ##    ##
#       ##       ## ##    ##   ##    ## ##          ##          ##    ##
#       ######## ##    ## ########    ######   ######   ########
#       ##          ######### ##    ##          ## ##         ##    ##
#       ##          ##    ## ##   ##   ##       ##   ##         ##   ##
#       ##          ##    ## ##    ##   ######    ########   ##    ##


class OnyxParser < OnyxLexer
   record Unclosed, name, location

   property visibility  # *TODO* must be handled for macros

   property def_nest
   property type_nest
   getter? wants_doc

   def self.parse(str, scope_stack = ScopeStack.new)
      new(str, scope_stack).parse
   end

   def initialize(str, deffed_vars_list = [Set(String).new])
      super(str)

      @scope_stack = ScopeStack.new deffed_vars_list

      @temp_token = Token.new
      @calls_super = false
      @calls_initialize = false
      @uses_explicit_block_param = false
      @assigns_special_var = false

      # *TODO* clean these three up - similar chores
      @def_nest = 0
      @certain_def_count = 0
      @def_parsing = 0

      @control_construct_parsing = 0 # *TODO* this could probably be just a flag, huh!

      @type_nest = 0

      @anon_param_counter = 1

      @explicit_block_param_count = 0
      @in_macro_expression = false
      @stop_on_yield = 0
      @inside_c_struct = false
      @wants_doc = false

      @one_line_nest = 0
      @was_just_nest_end = false
      @significant_newline = false

      @unclosed_stack = [] of Unclosed
      @nesting_stack = NestingStack.new

   end

   def wants_doc=(@wants_doc)
      @doc_enabled = @wants_doc
   end


   # *TODO* RETHINK THESE GLOBAL PARSING STATES!!!!!

   def skip_statement_end # redefined for parser
      if @significant_newline
         dbg "skip_statement_end true"
         while (@token.type == :SPACE || @token.type == :";")
            next_token
         end
      else
         dbg "skip_statement_end false"
         while (@token.type == :SPACE || @token.type == :NEWLINE || @token.type == :";")
            next_token
         end
      end
   end

   def skip_space_or_newline
      if @significant_newline
         dbg "skip_space_or_newline true"
         while (@token.type == :SPACE)
            next_token
         end
      else
         dbg "skip_space_or_newline false"
         while (@token.type == :SPACE || @token.type == :NEWLINE)
            next_token
         end
      end
   end

   def unsignificantify_newline
      if @significant_newline && @one_line_nest == 0
         @significant_newline = false
      end
   end

   def skip_tokens(*tokens : Symbol)
      while tokens.includes?(@token.type)
         next_token
      end
   end


   # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
   #             ########     ###    ########   ######  ########
   #             ##     ##   ## ##   ##     ## ##    ## ##
   #             ##     ##  ##   ##  ##     ## ##       ##
   #             ########  ##     ## ########   ######  ######
   #             ##        ######### ##   ##         ## ##
   #             ##        ##     ## ##    ##  ##    ## ##
   #             ##        ##     ## ##     ##  ######  ########
   # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
   def parse
      next_token_skip_statement_end

      if end_token? # "stop tokens" - not _nest_end tokens_ - unless explicit
         dbg "An empty file!?".red
         expressions = Nop.new
      else
         expressions = parse_expressions # .tap { check :EOF }
      end

      expressions.tag_onyx true  # *TODO* after macros is fixed!
      #expressions.is_onyx = true


      dbg "/parse - after program body parse_expressions"

      if ! tok? :EOF
         dbgtail_off!
         raise "Expected end of program, EOF, but got `#{@token}`"
      end

      # ifdef !release
      #    # *TODO* - debugga hela programstrukturen - gör med parse --ast nu
      #    STDERR.puts "\n\n\nAST:\n\n\n"
      #    expressions.dump_std
      #    STDERR.puts "\n\n\n"

      #    STDERR.puts "\n\n\nPROGRAM:\n\n\n" + expressions.to_s + "\n\n\n"

      # end

      STDERR.flush

      expressions
   end

   def parse_expressions
      dbg "parse_expressions ->".yellow
      dbginc

      # Nil–blocks should be taken care of BEFORE calling parse_expressions

      # *TODO* continue watching this
      # happened one time: EMPTY FILE
      # now added to "top parse"
      if end_token? # "stop tokens" - not _nest_end tokens_ - unless explicit
         dbgtail_off!
         raise "parse_expressions - Does this happen?"
         return Nop.new
      end

      slash_is_regex!

      exps = [] of ASTNode

      while true
         dbg "- parse_expressions() >>> LOOP TOP >>>"

         # *TODO*
         if tok?(:EOF)
            dbg "- parse_expressions() - break loop because of EOF"
            break
         end

         exps << parse_expression # parse_multi_assign

         dbg "- parse_expressions() - after parse_expression"

         if handle_nest_end
            dbg "- parse_expressions() break after handle_nest_end"
            break

         # elsif end_token?
         #    dbg "- parse_expressions() break after end_token?"
         #    break

         # elsif @one_line_nest > 0 && tok? :NEWLINE
         #    dbg "- parse_expressions() break after online-nest newline"
         #    @was_just_nest_end = true
         #    de_nest @indent, :"", ""
         #    next_token_skip_statement_end
         #    break
         end

         dbg "- parse_expressions - before skip_statement_end"
         skip_statement_end

      end

      Expressions.from exps
   ensure
      dbgdec
      dbgtail "/parse_expressions".yellow
   end

   def last_was_newline_or_dedent
      (prev_token_type == :NEWLINE || prev_token_type == :DEDENT || prev_token_type == :ACTUAL_BOF)
   end

   def parse_expression
      dbg "parse_expression ->"
      dbginc
      location = @token.location

      # *TODO* this methodology ain't good - anyway - it's now put inside "parse_op_assign"
      #@was_just_nest_end = false # is for catching the suffix part..

      # when explicit keyword fun - then it's better to parse via the usual
      # expression route
      possible_def_context = last_was_newline_or_dedent
      can_be_arrow_func_def = possible_def_context && (
         # kwd?(:def, :fn, :fu, :mf, :fun, :own, :me, :func, :meth, :pure, :proc) ||
         (
            tok?(DefOrMacroCheck1) &&
            (curch == '(' || (curch == '*' && peek_next_char == '('))
         )
      )

      chars_snap_pos = current_pos
      def_chars = 0
      expr_chars = 0

      if can_be_arrow_func_def
         dbg "- parse_expression - tries pre-emptive def parse".white

         # *TODO* the chars count can be dropped now!
         if (ret = try_parse_def).is_a? Int32
            def_chars = ret - chars_snap_pos
         else
            return ret as ASTNode
         end

         backed = backup_full

         dbg "- parse_expression - after pre-emptive def parse, tries expr".white
         atomic = parse_op_assign

      else
         dbg "- parse_expression - plain expr parsing".white
         atomic = parse_op_assign
      end

      atomic = atomic.not_nil! # Crystal doesn't handle above rescue mess well in inference

      dbg "- parse_expression - after atomic - before suffix - @was_just_nest_end = #{@was_just_nest_end}"

      if @was_just_nest_end == false
         parse_expression_suffix atomic, location
      else
         @was_just_nest_end = false
         if tok? :SPACE
            next_token_skip_space
         end
         atomic
      end
   ensure
      dbgdec
      dbgtail "/parse_expression"

   end

   def parse_expression_suffix(atomic, location)
      # *TODO* this is called after all kinds of things
      # after def -> end for instance - where of course ENSURE and RESCUE are ok,
      # Look over the entire concept!

      dbg "parse_expression_suffix ->"
      # dbginc
      while true
         case @token.type

         when :SPACE
            next_token

         when :IDFR
            case @token.value
            when :if
               atomic = parse_expression_suffix(location) { |exp| If.new(exp, atomic) }

            when :unless
               atomic = parse_expression_suffix(location) { |exp| Unless.new(exp, atomic) }

            when :for
               dbgtail_off!
               raise "suffix `for` is not supported - discuss on IRC or in issues if you disagree", @token

            when :while
               dbgtail_off!
               raise "suffix `while` is not supported", @token

            when :until
               dbgtail_off!
               raise "suffix `until` is not supported", @token

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
               dbg "parse_ifdef in expr-suffix"
               next_token_skip_statement_end
               exp = parse_flags_or
               atomic = IfDef.new(exp, atomic).at(location)

            else
               break
            end

         # *TODO* :"}}" is no longer produced in lexing
         # :">" is when it is _not_ spaced, and thus Tuple–literal–ending
         when :">", :")", :",", :":", :";", MACRO_CTRL_END_DELIMITER, MACRO_VAR_EXPRS_END_DELIMITER, :"}}", :NEWLINE, :EOF, :DEDENT  # :":" is solely for "ternary-if"
            # *TODO* skip explicit end token
            break

         else
            # _just_ Pragmas (being the atomic part)
            if (atomic.is_a?(Expressions) && atomic.expressions.first.is_a?(Attribute))
               break

            # Suffic Pragmas?
            elsif pragmas?
               pragmas = parse_pragma_grouping
               # *TODO* use the maddafaggas

            elsif end_token? || tok? :INDENT
               break

            else
               unexpected_token "while parsing expression suffix"
            end
         end
      end
      atomic
   ensure
      # dbgdec
      dbg "/parse_expression_suffix"
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

   def maybe_mutate_gt_op_to_bigger_op
      # Check if we're gonna mutate the token to a "larger one"
      if tok? :">"
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
      dbg "parse_op_assign ->"

      @was_just_nest_end = false   # *TODO* even deeper in then this? (was parse_expression)

      doc = @token.doc
      location = @token.location

      # atomic = parse_question_colon
      atomic = parse_range
      dbg "- parse_op_assign after parse_range"

      while true
         maybe_mutate_gt_op_to_bigger_op

         case @token.type

         when :SPACE
            dbg "- parse_op_assign - got SPACE - next!"
            next_token
            next

         when :IDFR
            break if kwd? :then, :do, :by, :step, :begins # *TODO* is_end_keyword???

            unexpected_token "suffix not allowed in the context" unless allow_suffix
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
                  dbgtail_off!
                  raise "dynamic constant assignment"
               end

               if atomic.is_a?(Var) && atomic.name == "self"
                  dbgtail_off!
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

               if kwd?(:raw) && (atomic.is_a?(Var) || atomic.is_a?(InstanceVar))
                  pop_scope if needs_new_scope
                  add_var atomic
                  next_token_skip_space
                  type = parse_single_type
                  atomic = UninitializedVar.new(atomic, type).at(location)
                  return atomic
               else
                  value = parse_op_assign_no_control
                  pop_scope if needs_new_scope
                  add_var atomic

                  dbg "creates Assign"
                  atomic = Assign.new(atomic, value).at(location)
                  atomic.doc = doc
               end

               atomic

            end

         when :"+=", :"-=", :"*=", :"/=", :"%=", :".|.=", :".&.=", :".^.=",
                :"**=", :"<<=", :">>=", :"||=", :"&&="
            # Rewrite 'a += b' as 'a = a + b'

            unexpected_token "operators not allowed in this context" unless allow_ops

            break unless can_be_assigned?(atomic)

            if atomic.is_a?(Path)
               dbgtail_off!
               raise "can't reassign to constant"
            end

            if atomic.is_a?(Var) && atomic.name == "self"
               dbgtail_off!
               raise "can't change the value of self", location
            end

            if atomic.is_a?(Call) && atomic.name != "[]" && !@scope_stack.cur_has?(atomic.name)
               dbgtail_off!
               raise "'#{@token.type}' before definition of '#{atomic.name}'"

               atomic = Var.new(atomic.name)
            end

            add_var atomic

            method = @token.type.to_s.byte_slice(0, @token.to_s.bytesize - 1)
            method_column_number = @token.column_number

            case method
            when ".|."
               method = "|"
            when ".&."
               method = "&"
            when ".^."
               method = "^"
            when ".~."
               method = "~"
            end

            token_type = @token.type
            # tok_location = location

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
   ensure
      dbgtail "/parse_op_assign"
   end

   def parse_range
      location = @token.location

      # dbg "parse_range ->"
      exp = parse_or
      # dbg "- parse_range - after parse_or"

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
         # dbg "now parse: {{next_operator.id}}"
         # dbg %(will compare: {{operators.id}})

         left = parse_{{next_operator.id}}

         while true
            case @token.type
            when :SPACE
               next_token
            when {{operators.id}}
               unless prev_tok? :SPACE
                  return left
               end

               scan_next_as_continuation
               check_void_value left, location

               method = @token.type.to_s
               method_column_number = @token.column_number


               dbg "op-method == #{method}".red

               foometh = method
               method = case method
               when "is"
                  "=="
               when "isnt"
                  "!="
               when "and"
                  "&&"
               when "or"
                  "||"

               when ".|."
                  "|"
               when ".&."
                  "&"
               when ".^."
                  "^"
               when ".~."
                  "~"

               when "~~"
                  "==="

               else
                  method
               end


               dbg "OPERATOR MUTATED".red if foometh != method
               # ensure that operatorish behaviour is followed for the
               # alphanumeric operator aliases too
               if foometh != method
                  scan_next_as_continuation
               end

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



   parse_operator :or, :and, "Or.new left, right", ":\"||\", :or"
   parse_operator :and, :possible_angular_tuple, "And.new left, right", ":\"&&\", :and"

   def parse_possible_angular_tuple
      # dbg "parse_possible_angular_tuple ->".yellow
      # dbg "- parse_possible_angular_tuple - ret if not '<'".cyan
      return parse_equality unless tok?(:"<")

      dbg "- parse_possible_angular_tuple - ret if spaced ' < '".cyan
      return parse_equality if surrounded_by_space?

      return parse_angular_tuple
      # try_parse parse_tuple, parse_equality
   end

   def parse_paren_tuple
      dbg "parse_paren_tuple".white
      location = @token.location

      next_token; skip_space

      if tok? :INDENT, :NEWLINE
         skip_tokens :INDENT, :NEWLINE, :SPACE
      end

      exps = [] of ASTNode
      end_location = nil

      until tok?(:")")
         dbg "- parse_paren_tuple - parse an element as expr"
         exps << parse_expression unless tok? :","

         if tok? :",", :NEWLINE, :INDENT, :DEDENT
            dbg "- parse_paren_tuple - parse separator"
            parse_item_separator
         end
      end

      if exps.size < 2 && !(prev_tok?(:","))
         Crystal.raise_wrong_parse_path "Less than two elements and no trailing \"is–a-tuple\" comma. Indicates expression grouping"
      end

      end_location = token_end_location
      next_token_skip_space

      if tok? :"->"
         Crystal.raise_wrong_parse_path "Found parentheses suffix indicating lambda"
      end
      if tok? :"~>", :"\\"
         Crystal.raise_wrong_parse_path "Found parentheses suffix indicating soft-lambda"
      end

      TupleLiteral.new(exps).at_end(end_location)

   ensure
      dbgtail "parse_tuple"
   end

   def parse_angular_tuple
      dbg "parse_tuple".white
      location = @token.location
      next_token

      if tok? :INDENT, :NEWLINE
         skip_tokens :INDENT, :NEWLINE, :SPACE
      end

      exps = [] of ASTNode
      end_location = nil

      until tok?(:">") && !surrounded_by_space?
         dbg "- parse_tuple - parse an element as expr"
         exps << parse_expression # unless tok? :","

         if tok? :",", :NEWLINE, :INDENT, :DEDENT
            dbg "- parse_tuple - parse separator"
            parse_item_separator
         end
      end

      end_location = token_end_location
      next_token_skip_space

      TupleLiteral.new(exps).at_end(end_location)

   ensure
      dbgtail "parse_angular_tuple"
   end


   parse_operator :equality, :cmp, "Call.new left, method, [right] of ASTNode, name_column_number: method_column_number", ":\"<\", :\"<=\", :\">\", :\">=\", :\"<=>\""
   parse_operator :cmp, :logical_or, "Call.new left, method, [right] of ASTNode, name_column_number: method_column_number", ":\"==\", :is, :\"!=\", :isnt, :\"=~\", :\".~.=\", :\"~~\", :\"!~~\", :\"!~\""
   parse_operator :logical_or, :logical_and, "Call.new left, method, [right] of ASTNode, name_column_number: method_column_number", ":\".|.\", :\".^.\""
   parse_operator :logical_and, :shift, "Call.new left, method, [right] of ASTNode, name_column_number: method_column_number", ":\".&.\""
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
               left = Call.new(left, char.to_s, [new_num_lit(@token.value.to_s.byte_slice(1), @token.number_kind)] of ASTNode, name_column_number: @token.column_number).at(location)
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
      when :"!", :not, :"+", :"-", :".~."
         token_type = :"!" if token_type == :not
         token_type = :"~" if token_type == :".~."

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

   AtomicWithMethodCheck = [:NUMBER, :IDFR, :"+", :"-", :"*", :"/", :"%", :"|", :"&", :"^", :"**", :"<<", :"<", :"<=", :"==", :"is", :"!=", :"isnt", :"=~", :">>", :">", :">=", :"<=>", :"||", :"or", :"&&", :"and", :"~~", :"!~~", :"!~", :"[]", :"[]=", :"[]?", :"!", :"not"]

   def parse_atomic_with_method
      dbg "parse_atomic_with_method"
      location = @token.location
      atomic = parse_atomic

      if @was_just_nest_end == false
         dbg "parse_atomic_with_method -> parse_atomic_method_suffix"
         parse_atomic_method_suffix atomic, location
      else
         dbg "parse_atomic_with_method -> NO suffix - was nest_end before"
         atomic
      end
   end

   def parse_atomic_method_suffix(atomic, location)
      dbg "parse_atomic_method_suffix"

      # Must not be spaced:
      if tok?(:"#", :":", :TAG)
         return parse_atomic_method_suffix_terse_literal_subscript atomic, location
      end

      while true
         maybe_mutate_gt_op_to_bigger_op

         case @token.type
         when :SPACE
            next_token
         # when :"\""
         #    # *TODO* string–literal–type–creation
         #    # etc. user implemented (?)
         #    raise "Specific literal - not implemented yet"

         when :IDFR
            if kwd?(:as)
               check_void_value atomic, location

               next_token_skip_space
               to = parse_single_type
               atomic = Cast.new(atomic, to).at(location)
            else
               break
            end

         when :NEWLINE
            # If one_line nest, this means quits
            if @one_line_nest != 0
               break
            end
            # In these cases we don't want to chain a call
            case atomic
            when ClassDef, ModuleDef, EnumDef, FunDef, Def
               break
            end

            if parser_peek_non_ws_char == '.'
               next_token_skip_space
               atomic = parse_atomic_method_suffix_dot atomic, location
            else
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
            atomic.name_size = 0
            atomic

         when :"["
            check_void_value atomic, location

            column_number = @token.column_number
            next_token_skip_space_or_newline
            args = [] of ASTNode
            while true
               args << parse_single_arg
               skip_statement_end
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
            atomic.name_size = 0
            atomic

         else
            break
         end
      end

      atomic
   end

   def parse_atomic_method_suffix_terse_literal_subscript(atomic, location)
      if tok? :TAG
         klass = TagLiteral
      else
         return atomic if current_char == ' '
         return atomic if current_char == '-'
         return atomic if current_char == '\n'

         klass = tok?(:":") ? StringLiteral : TagLiteral
         next_token

         if !tok? :IDFR
            dbgtail_off!
            raise "Expected identifer!"
         end
      end

      # check_void_value atomic, location
      column_number = @token.column_number
      key = @token.value.to_s

      if key[-1] == '?'
         key = key[0..-1]
         is_nilly = true
      else
         is_nilly = false
      end

      args = [] of ASTNode
      # args << klass.new @token.value.to_s   -- not working cause of 'Nop' - think above klass becomas ASTNode+...
      if klass == TagLiteral
         args << TagLiteral.new key
      else
         args << StringLiteral.new key
      end
      next_token

      if @token.type == :"?"
         is_nilly = true
         next_token_skip_space
      else
         skip_space
      end

      method_name = is_nilly ? "[]?" : "[]"

      atomic = Call.new(atomic, method_name, args,
                                              name_column_number: column_number
                                             ).at(location)
      atomic.name_size = 0

      return atomic
   end

   def parse_atomic_method_suffix_dot(atomic, location)
      dbg "parse_atomic_method_suffix_dot".green
      check_void_value atomic, location

      @wants_regex = false

      if current_char == '%'
         next_char
         @token.type = :"%"
         @token.column_number += 1
         skip_statement_end
      else
         next_token_skip_space_or_newline

         if @token.type == :INSTANCE_VAR
            dbg "parse_atomic_method_suffix_dot instance var"
            ivar_name = @token.value.to_s
            end_location = token_end_location
            next_token_skip_space

            atomic = ReadInstanceVar.new(atomic, ivar_name).at(location)
            atomic.end_location = end_location
            return atomic
         end
      end

      dbg "parse_atomic_method_suffix_dot check AtomicWithMethodCheck"
      check AtomicWithMethodCheck
      name_column_number = @token.column_number

      if @token.value == "of?"
         atomic = parse_is_a(atomic).at(location)

      elsif @token.value == :responds_to?
         atomic = parse_responds_to(atomic).at(location)

      # dot–index : foo.1 => foo[1]
      elsif tok? :NUMBER
         args = [] of ASTNode
         args << NumberLiteral.new(@token.value.to_s, :i32)
         next_token

         if @token.type == :"?"
            method_name = "[]?"
            next_token_skip_space
         else
            method_name = "[]"
            skip_space
         end

         atomic = Call.new(atomic, method_name, args,
                            name_column_number: name_column_number
                           ).at(location)

      else
         dbg "parse_atomic_method_suffix_dot else"

         name = @token.type == :IDFR ? @token.value.to_s : @token.type.to_s

         if foreign = $babelfish_func_dict[name]?
            dbg "Got foreign '#{foreign}' for function #{name}".magenta
            name = foreign
         end

         name_indent = @indent
         end_location = token_end_location
         next_token

         # *TODO* indented cal
         if @token.type == :SPACE
            next_token
            space_consumed = true
            @wants_regex = true
         else
            space_consumed = false
            @wants_regex = false
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
               # *TODO* verify skip_statement_end...
               skip_statement_end
               arg = parse_single_arg
            end
            return Call.new(atomic, "#{name}=", [arg] of ASTNode, name_column_number: name_column_number).at(location)

         when :"+=", :"-=", :"*=", :"/=", :"%=", :".|.=", :".&.=", :"^=", :"**=", :"<<=", :">>="
            # Rewrite 'f.x += value' as 'f.x=(f.x + value)'
            method = @token.type.to_s.byte_slice(0, @token.type.to_s.size - 1)
            next_token_skip_space
            value = parse_op_assign
            return Call.new(atomic, "#{name}=", [Call.new((Call.new(atomic.clone, name, name_column_number: name_column_number)), method, [value] of ASTNode, name_column_number: name_column_number)] of ASTNode, name_column_number: name_column_number).at(location)

         when :"||="
            # Rewrite 'f.x ||= value' as 'f.x || f.x=(value)'
            next_token_skip_space
            value = parse_op_assign
            return Or.new(
               (Call.new(atomic, name)).at(location),
               (Call.new(atomic.clone, "#{name}=", value)).at(location)
            ).at(location)

         when :"&&="
            # Rewrite 'f.x &&= value' as 'f.x && f.x=(value)'
            next_token_skip_space
            value = parse_op_assign
            return And.new(
               (Call.new(atomic, name)).at(location),
               (Call.new(atomic.clone, "#{name}=", value)).at(location)
            ).at(location)

         else
            if space_consumed
               call_args = parse_call_args_spaced

            # *TODO* indented call
            else
               has_parens, call_args = parse_call_args true, name_indent
            end

            if call_args
               args = call_args.args
               block = call_args.block
               explicit_block_param = call_args.explicit_block_param
               named_args = call_args.named_args
            else
               args = block = explicit_block_param = nil
            end
         end

         if block || explicit_block_param
            atomic = Call.new(
               atomic,
               name,
               (args || [] of ASTNode),
               block,
               explicit_block_param, named_args,
               name_column_number: name_column_number,
               has_parenthesis: has_parens
            )
         else
            atomic = args ?
               (Call.new atomic, name, args, named_args: named_args, name_column_number: name_column_number, has_parenthesis: has_parens)
            :
               (Call.new atomic, name, name_column_number: name_column_number, has_parenthesis: has_parens)
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
      dbg "parse_is_a ->".red

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

      else
         dbgtail_off!
         raise "unexpected token when parsing is-a? / of?"
      end

      RespondsTo.new(atomic, name)
   end

   def parse_responds_to_name
      if !tok? :TAG, :IDFR
         unexpected_token "expected name or symbol"
      end

      @token.value.to_s
   end

   def parse_atomic
      dbg "parse_atomic"
      location = @token.location
      atomic = parse_atomic_without_location
      atomic.location ||= location
      atomic
   ensure
      dbgtail "/parse_atomic"
   end

   def parse_atomic_without_location
      dbg "parse_atomic_without_location"


      # *TODO* *9* LEXICAL LEVEL REWRITE - REALLY MOVE THIS PoC *TODO*!
      # While the lang is in volatile state this is OK
      # Could actually be done already in the Lexer! (for to_s / formatting -
      # always use source as reference for construct kind
      if @token.type == :CONST && ([:Self, :Type, :Class].includes? @token.value)
         dbg "Found CONST with value Self, Type or Class"
         if current_char == '.'
            dbg "AND curch == '.'"

            next_token # to the :"." TOKEN
            next_token # to next token

            # rewrite token in–place - *UGLY*!
            @token.type = :CLASS_VAR
            @token.value = ensure_atat_prefix @token.value.to_s
         else
            dbg "curch == '#{current_char}'"
         end
      end
      # *TODO*


      if pragmas?
         pragmas = parse_pragma_cluster
         dbg "Got pragma in parse_atomic_without_location - apply to next item! #{pragmas}"
         return Expressions.new pragmas
      end

      ret = case @token.type
      when :"("
         parse_parenthetical_unknown

      when :"[]"
         parse_empty_array_literal

      when :"["
         parse_array_literal_or_multi_assign

      when :"{"
         # parse_hash_or_set_literal
         parse_hash_or_set_literal

      when MACRO_VAR_EXPRS_START_DELIMITER # *TODO* ONLY IN MACRO CONTEXT!
         macro_exp = parse_tplmacro_expression
         check_macro_expression_end
         next_token
         MacroExpression.new(macro_exp)

      when MACRO_CTRL_START_DELIMITER
         macro_control = parse_tplmacro_control(@line_number, @column_number)
         if macro_control
            check MACRO_CTRL_END_DELIMITER
            next_token_skip_space
            macro_control
         else
            unexpected_token_in_atomic
         end

      when :"$"
         dbg "got '$' branch".red
         parse_constish_or_global_call

      # when :"->"
      #   parse_fun_literal

      when :NUMBER
         dbg "when :NUMBER"
         @wants_regex = false
         node_and_next_token new_num_lit(@token.value.to_s, @token.number_kind)

      when :CHAR
         node_and_next_token CharLiteral.new(@token.value as Char)

      when :STRING, :DELIMITER_START
         parse_delimiter

      when :STRING_ARRAY_START
         parse_string_array

      when :TAG_ARRAY_START
         parse_symbol_array

      when :TAG
         node_and_next_token TagLiteral.new(@token.value.to_s)

      when :GLOBAL
         dbg "GLOBAL!"
         new_node_check_type_declaration Global, true
         # @wants_regex = false
         # node_and_next_token Global.new(@token.value.to_s)

      # Magic vars for last regexp match and process return status respectively
      when :"$~", :"$?"
         location = @token.location
         var = Var.new(@token.to_s).at(location)

         backed = backup_tok

         next_token_skip_space

         if @token.type == :"="
            restore_tok backed
            add_var var
            node_and_next_token var
         else
            restore_tok backed
            node_and_next_token Call.new(var, "not_nil!").at(location)
         end

      # Magic vars for specific regexp match group index
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
            node_and_next_token Call.new((Call.new(Var.new("$~").at(location), "not_nil!")).at(location), method, new_num_lit(value.to_i))
         end

      when :__LINE__
         node_and_next_token MagicConstant.expand_line_node(@token.location)

      when :__FILE__
         node_and_next_token MagicConstant.expand_file_node(@token.location)

      when :__DIR__
         node_and_next_token MagicConstant.expand_dir_node(@token.location)

      when :IDFR

         dbg "took IDFR branch"
         # when :"|" # *TODO* *TEST*
         #    parse_var_or_call

         case @token.value
         when :try, :do # :begin
            parse_try
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
            unexpected_token "abstract can only be used in place of of a func body, or as modifer on types."
            # check_not_inside_def("can't use abstract inside def") do
            #    doc = @token.doc

            #    next_token_skip_space_or_newline
            #    case @token.type
            #    when :IDFR
            #       case @token.value
            #       when :def
            #          parse_def is_abstract: true, doc: doc
            #       when :type
            #          parse_type_def is_abstract: true, doc: doc
            #       when :class
            #          parse_type_def is_abstract: true, doc: doc
            #       when :struct
            #          parse_type_def is_abstract: true, is_struct: true, doc: doc
            #       else
            #          unexpected_token "after finding identifer after abstract"
            #       end
            #    else
            #       unexpected_token "after finding abstract"
            #    end
            # end
         when :def, :fun, :own, :fn, :fu, :mf
            # *TODO* create "owningdefname__private_def__thisdefname"
            # - do this for the whole hierarchy of defs ofc. (if more)
            check_not_inside_def("can't define def inside def") do
               parse_def
            end
         when :macro
            # *TODO* create "owningdefname__private_macro__thisdefname"
            # - do this for the whole hierarchy of defs ofc. (if more)
            check_not_inside_def("can't define macro inside def") do
               parse_tplmacro
            end
         when :require
            parse_require
         when :case, :match, :branch, :cond
            parse_case
         when :if
            ret = parse_if
            dbg "after parse_if in parse_atomic_without_location"
            ret
         when :ifdef
            parse_ifdef
         when :unless
            parse_unless
         when :include, :mixin
            check_not_inside_def("can't include inside def") do
               parse_include
            end
         when :extend
            check_not_inside_def("can't extend inside def") do
               parse_extend
            end
         when :type
            check_not_inside_def("can't define type inside def") do
               parse_type_def
            end
         # when :babel
         #    check_not_inside_def("can't define type inside def") do
         #       parse_babel_def
         #    end
         when :module
            check_not_inside_def("can't define module inside def") do
               parse_module_def
            end
         when :trait
            dbg "trait!"
            check_not_inside_def("can't define trait inside def") do
               parse_trait_def
            end
         when :for
            parse_for
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
         when :lib, :api
            check_not_inside_def("can't define lib inside def") do
               parse_lib
            end
         when :cfun, :export # , :fun
            check_not_inside_def("can't define fun inside def") do
               parse_fun_def require_body: true
            end
         when :pointerof
            parse_pointerof
         when :sizeof
            parse_sizeof
         when :instance_sizeof
            parse_instance_sizeof
         when :typeof, :typedecl
            parse_typedecl
         # when :private
         #    parse_visibility_modifier :private
         # when :protected
         #    parse_visibility_modifier :protected
         when :asm
            parse_asm

         else
            # set_visibility parse_var_or_call   # *TODO* this _can_ be a def
            parse_var_or_call   # *TODO* this _can_ be a def
         end

      when :CONST
         parse_constish_or_type_tied_literal

      when :INSTANCE_VAR
         dbg "found reference to instance var"
         name = @token.value.to_s
         add_instance_var name
         ivar = InstanceVar.new(name).at(@token.location)
         ivar.end_location = token_end_location
         @wants_regex = false
         next_token_skip_space

         # *TODO* we need to parse this whole thing differently depending on if
         # "declarative context" or "use context"
         # if !tok?(:NEWLINE, :DEDENT, :";", :"=") && !end_token?
         #    dbg "found type declaration"
         #    ivar_type = parse_single_type
         #    TypeDeclaration.new(ivar, ivar_type).at(ivar.location)
         # else
         ivar
         # end

      when :CLASS_VAR
         @wants_regex = false
         node_and_next_token ClassVar.new(@token.value.to_s)

      when :UNDERSCORE
         node_and_next_token Underscore.new

      when :"~.", :"~>", :"\\", :"\\."
         parse_softlambda

      else
         unexpected_token_in_atomic
      end

   ensure
      dbgtail "/parse_atomic_without_location"
      ret
   end

   def new_node_check_type_declaration(klass, check_assign)
      new_node_check_type_declaration(klass, check_assign) { }
   end

   def new_node_check_type_declaration(klass, check_assign)
      name = @token.value.to_s
      yield name
      var = klass.new(name).at(@token.location)
      var.end_location = token_end_location
      @wants_regex = false
      next_token_skip_space

      # if  check if we need qualifier symbol in this context (boolean arg to us) else check immediately for single–type alike to determine if we have a typing or not
      if next_is_any_type_modifier?
         dbg "found type declaration"
         # *TODO* we must take care of the type qualifiers
         mutability, storage, var_type = parse_qualifer_and_type
      else
         mutability = :auto
         var_type = nil
         dbg "found NO type"
      end

      # if check_assign && tok? :"="
      if tok? :"="
         dbg "found assign to idfr"
         next_token_skip_space_or_newline
         assign_value = parse_op_assign
         dbg "/found assign to idfr"
      else
         assign_value = nil
      end

      if var_type
         dbg "add type declaration"
         is_assign_composite = assign_value != nil
         type_decl = TypeDeclaration.new(var, var_type, is_assign_composite, mutability: mutability).at(var.location)
      end

      if assign_value
         if var_type
            var = var.clone
         end
         assign = Assign.new(var, assign_value).at(var)
      end

      if type_decl && assign
         Expressions.new [type_decl, assign] of ASTNode

      elsif type_decl
         type_decl

      elsif assign
         assign

      else
         var
      end
   end

   def parse_constish_or_type_tied_literal
      constish = parse_constish allow_call_parsing: true

      dbg "parse_constish_or_type_tied_literal ->"

      if @token.type == :"{"
         return parse_constish_tied_listish_literal constish
      end

      dbg "/parse_constish_or_type_tied_literal - found nothing special - pass along"

      return constish
   end

   def parse_constish_or_global_call
      location = @token.location

      next_token_skip_space            # `$`
      next_token_skip_space_or_newline # `.`

      case @token.type
      when :IDFR
         # set_visibility parse_var_or_call global: true
         parse_var_or_call global: true
      when :CONST
         parse_constish_after_colons(location, true, true, true)
      else
         unexpected_token "while parsing identifer or global call"
      end
   end

   def parse_constish(allow_type_vars = true, allow_call_parsing = false)
      location = @token.location

      dbg "parse_constish"

      # *TODO* clean up global<>is_global
      global = false

      case @token.type

      when :"$", :"Program" # , :"App" # *TODO* App not implemented yet
         if current_char == '.'
            next_token_skip_space
            is_global = true
         else
            is_global = false
         end

         if is_global
            global = true
            next_token_skip_space_or_newline
         end

      when :UNDERSCORE
         return node_and_next_token Underscore.new.at(location)
      end

      check :CONST
      parse_constish_after_colons(location, global, allow_type_vars, allow_call_parsing)

   end

   def parse_constish_after_colons(location, global, allow_type_vars, allow_call_parsing)
      dbg "parse_constish_after_colons ->"

      start_line = location.line_number
      start_column = location.column_number
      name_indent = @indent

      names = [] of String
      names << check_const # @token.value.to_s
      end_location = token_end_location

      next_token

      while tok? :"."
         dbg "- parse_constish_after_colons - got `::` or `.`"

         if 'A' <= current_char <= 'Z'   # next is const
            dbg "- parse_constish_after_colons - next is constish: `#{current_char}"
            next_token_skip_space_or_newline
            names << check_const

         else # possible identifier, T() or T arg, juxtaposition call
            dbg "- parse_constish_after_colons - next is NOT constish: `#{current_char}"
            break
         end

         end_location = token_end_location
         next_token
      end

      # The "magic" renaming of Int and Real to their current default
      # *TODO* just keep literals!?
      # names.each_with_index do |name, ix|
      #    if name == "Int"
      #       names[ix] = @nesting_stack.last.int_type_mapping.value.to_s

      #    elsif name == "Real"
      #       names[ix] = @nesting_stack.last.real_type_mapping.value.to_s
      #    end
      # end

      const = Path.new(names, global).at(location)
      const.end_location = end_location

      token_location = @token.location
      if token_location && token_location.line_number == start_line
         const.name_size = token_location.column_number - start_column
      end

      if allow_type_vars && tok? :"<", :"["
         generic_end = tok?(:"<") ? :">" : :"]"
         next_token_skip_space

         types = parse_types allow_primitives: true
         if types.empty?
            dbgtail_off!
            raise "must specify at least one type var"
         end

         raise "expected `>` or `]` ending type params" if !tok? generic_end
         const = Generic.new(const, types).at(location)
         const.end_location = token_end_location
         next_token
      end

      dbg "- parse_constish_after_colons - check if juxtaposition call style on constish"

      if allow_call_parsing
         case
         when tok? :"("
            return parse_constish_type_new_call_sugar const, name_indent

         # *TODO* indent calls here too!

         when tok? :SPACE
            # *TODO* we should probably pre–parse and just make sure it's not a
            # binary operator or assign
            # *TODO* - RE–USE CODE FROM PARSE_PAREN_CALL_ARGS!!!
            case current_char #   peek_next_char
            when .alpha?, '_', '"', '%',.ord_gt?(0x9F), .digit?, '(', '[', '{', '$'
               return parse_constish_type_new_call_sugar const, name_indent
            when '!'
               if (p = peek_next_char) != '=' && p != '~'
                  return parse_constish_type_new_call_sugar const, name_indent
               end
            end
         end
      end

      const
   ensure
      dbgtail "/parse_constish_after_colons"
   end

   def parse_constish_tied_listish_literal(idfr)
      # usertype literal
      tuple_or_hash = parse_hash_or_set_literal allow_of: false

      skip_space

      if kwd?(:"of")
         unexpected_token "got `of` keyword in an unexpected place when parsing user-typed collection literal"
      end

      case tuple_or_hash
      when TupleLiteral
         ary = ArrayLiteral.new(tuple_or_hash.elements, name: idfr).at(tuple_or_hash.location)
         return ary
      when HashLiteral
         tuple_or_hash.name = idfr
         return tuple_or_hash
      else
         dbgtail_off!
         raise "Bug: tuple_or_hash should be tuple or hash, not #{tuple_or_hash}"
      end
   end

   def parse_constish_type_new_call_sugar(idfr, curr_indent)
      dbg "parse_constish_type_new_call_sugar ->".yellow
      has_parens, arg_node = parse_call_args true, curr_indent

      if arg_node
         args = arg_node.args || [] of ASTNode
         block = arg_node.block
         explicit_block_param = arg_node.explicit_block_param
         named_args = arg_node.named_args
      else
         dbgtail_off!
         raise "bug in onyx when trying to parse Type.new() sugar!"
      end

      return Call.new(idfr, "new", args, block, explicit_block_param, named_args, false, 0, has_parens)

   ensure
      dbgtail "/parse_constish_type_new_call_sugar".yellow
   end


   def check_not_inside_def(message)
      if @def_nest == 0
         yield
      else
         dbgtail_off!
         raise message, @token.line_number, @token.column_number
      end
   end

   def inside_def?()
      @def_nest > 0
   end



   # *TODO* pragmas makes a difference in affinity depending on newlines before
   # or after!
   # We should produce PRAGMA–nodes - since we want to be able to reproduce
   # source from AST–tree.
   # Therefore the pragma–nodes gets affinity flag too.
   # The correct receiver also gets the pragmas associated immediately too!
   # (nodes are only for source generation, the info is connected directly)

   def parse_pragma_cluster() : Array(ASTNode)
      dbg "parse_pragma_cluster_style1 ->"
      pragmas = [] of ASTNode

      while pragma_starter?
         pragmas.concat parse_pragma_grouping
         skip_space_or_newline
      end

      next_token if tok? :";"
      skip_space_or_newline

      pragmas
   end

   def parse_pragma_grouping() : Array(ASTNode)
      dbg "parse_pragma_grouping_style1 ->"
      pragmas = [] of ASTNode

      while pragma_starter?
         pragmas << parse_pragma
      end

      next_token if tok? :";"
      skip_space

      pragmas
   end

   def parse_pragma()
      dbg "parse_pragma ->"
      doc = @token.doc

      next_token # skip the pragma symbol `'`
      skip_tokens :"!"

      name = @token.value.to_s
      next_token_skip_space

      args = [] of ASTNode
      named_args = nil # [] of ASTNode

      if tok? :"="
         lex_style = :assign
         next_token_skip_space
         args << Arg.new @token.value.to_s
         next_token_skip_space

      elsif tok? :"("
         lex_style = :call
         open("attribute") do
            next_token_skip_space_or_newline

            while @token.type != :")"
               if @token.type == :IDFR && current_char == ':'
                  named_args = parse_named_args(allow_newline: true)
                  check :")"
                  break
               else
                  args << parse_call_arg
               end

               skip_statement_end

               if @token.type == :","
                  next_token_skip_space_or_newline
               end
            end

            next_token_skip_space
         end

      else
         # backed = backup_full

         # begin
         #    dbg "parse_pragma -> lex_style = :transform".yellow
         #    lex_style = :transform

         #    args << parse_call_arg

         #    if !tok? :"=>"
         #       Crystal.raise_wrong_parse_path
         #    end
         #    next_token_skip_space

         #    args << parse_call_arg

         # rescue
         #    restore_full backed
            lex_style = :statement
         # end
      end

      skip_space # _or_newline

      dbg "- parse_pragma #{name}, #{args}"


      pragma = Attribute.new(name, args, named_args, lex_style: lex_style)
      pragma.doc = doc

      case pragma.name
      when "lit_int", "int_lit", "literal_int", "int_literal"
         pragma.name = "!int_literal"
         dbg "sets int type mapping to: #{(pragma.args.first as Arg).name.to_s}"
         @nesting_stack.last.int_type_mapping = (pragma.args.first as Arg).name.to_s

      when "lit_real", "real_lit", "literal_real", "real_literal"
         pragma.name = "!real_literal"
         dbg "sets real type mapping to: #{(pragma.args.first as Arg).name.to_s}"
         @nesting_stack.last.real_type_mapping = (pragma.args.first as Arg).name.to_s

      end

      pragma

   ensure
      dbgtail "/parse_pragma"
   end



   # def parse_pragma_cluster() : Array(ASTNode)
   #    if pragma_starter?
   #       parse_pragma_cluster_style2
   #    else
   #       parse_pragma_cluster_style1
   #    end
   # end

   # def parse_pragma_grouping() : Array(ASTNode)
   #    if pragma_starter?
   #       parse_pragma_grouping_style2
   #    else
   #       parse_pragma_grouping_style1
   #    end
   # end


   # def parse_pragma_cluster_style1() : Array(ASTNode)
   #    dbg "parse_pragma_cluster_style1 ->"
   #    pragmas = [] of ASTNode

   #    while tok? :PRAGMA
   #       pragmas.concat parse_pragma_grouping_style1
   #       skip_space_or_newline
   #    end
   #    pragmas
   # end

   # def parse_pragma_grouping_style1() : Array(ASTNode)
   #    dbg "parse_pragma_grouping_style1 ->"
   #    pragmas = [] of ASTNode

   #    # while tok? :PRAGMA
   #    while tok? :PRAGMA
   #       pragmas << parse_pragma
   #    end

   #    pragmas
   # end


   # def parse_pragma_cluster_style2() : Array(ASTNode)
   #    dbg "parse_pragma_cluster_style2 ->"
   #    pragmas = [] of ASTNode

   #    #while ! tok? :";", :NEWLINE, :INDENT, :DEDENT # :PRAGMA
   #    while pragma_starter?
   #       next_token
   #       skip_space

   #       while ! tok? :";", :NEWLINE, :INDENT, :DEDENT # :PRAGMA
   #          pragmas << parse_pragma
   #       end

   #       if tok? :DEDENT
   #          return pragmas
   #       elsif tok? :INDENT
   #          raise "indented pragmas blocks not implemented yet! /ozra"
   #       end

   #       next_token if tok? :";"
   #       skip_space_or_newline
   #    end
   #    pragmas
   # end

   # def parse_pragma_grouping_style2() : Array(ASTNode)
   #    dbg "parse_pragma_grouping_style2 ->"
   #    pragmas = [] of ASTNode

   #    next_token
   #    skip_space

   #    # while tok? :PRAGMA
   #    while ! tok? :";", :NEWLINE, :INDENT, :DEDENT # :PRAGMA
   #       pragmas << parse_pragma
   #    end

   #    next_token if tok? :";"
   #    skip_space
   #    # skip_space_or_newline

   #    pragmas
   # end


   # def parse_pragma()
   #    dbg "parse_pragma ->"
   #    doc = @token.doc

   #    name = @token.value.to_s
   #    next_token #_skip_space

   #    args = [] of ASTNode
   #    named_args = nil # [] of ASTNode

   #    if tok? :"="
   #       next_token #_skip_space
   #       args << Arg.new @token.value.to_s
   #       next_token_skip_space

   #    elsif tok? :"("
   #       open("attribute") do
   #          next_token_skip_space_or_newline

   #          while @token.type != :")"
   #             if @token.type == :IDFR && current_char == ':'
   #                named_args = parse_named_args(allow_newline: true)
   #                check :")"
   #                break
   #             else
   #                args << parse_call_arg
   #             end

   #             skip_statement_end

   #             if @token.type == :","
   #                next_token_skip_space_or_newline
   #             end
   #          end

   #          next_token_skip_space
   #       end
   #    end

   #    skip_space # _or_newline

   #    dbg "- parse_pragma #{name}, #{args}"


   #    pragma = Attribute.new(name, args, named_args)
   #    pragma.doc = doc

   #    case pragma.name
   #    when "lit_int", "int_lit", "literal_int", "int_literal"
   #       dbg "sets int type mapping to: #{(pragma.args.first as Arg).name.to_s}"
   #       @nesting_stack.last.int_type_mapping = (pragma.args.first as Arg).name.to_s

   #    when "lit_real", "real_lit", "literal_real", "real_literal"
   #       dbg "sets real type mapping to: #{(pragma.args.first as Arg).name.to_s}"
   #       @nesting_stack.last.real_type_mapping = (pragma.args.first as Arg).name.to_s
   #    end

   #    pragma

   # ensure
   #    dbg "/parse_pragma"
   # end

   def parse_try
      slash_is_regex!
      indent_level = @indent
      next_token_skip_space # statement_end

      nest_kind, dedent_level = parse_nest_start(:try, indent_level)

      if nest_kind == :NIL_NEST
         dbgtail_off!
         raise "empty try block!"
      end

      add_nest :try, dedent_level, "", (nest_kind == :LINE_NEST), false

      exps = parse_expressions
      exps2 = Expressions.new([exps] of ASTNode).at(exps)
      node, end_location = parse_exception_handler exps
      node.end_location = end_location
      node
   end

   def parse_exception_handler(exp)
      rescues = nil
      a_fulfil = nil
      a_ensure = nil

      if kwd?(:rescue)
         rescues = [] of Rescue
         found_catch_all = false

         while true
            location = @token.location
            a_rescue = parse_rescue

            if a_rescue.types
               if found_catch_all
                  dbgtail_off!
                  raise "specific rescue must come before catch-all rescue", location
               end
            else
               if found_catch_all
                  dbgtail_off!
                  raise "catch-all rescue can only be specified once", location
               end
               found_catch_all = true
            end
            rescues << a_rescue
            break unless kwd?(:rescue)
         end
      end

      if kwd?(:else, :fulfil)
         # unless rescues
         #    raise "'else' is useless without 'rescue'", @token, 4
         # end
         next_token_skip_space
         nest_kind, dedent_level = parse_nest_start(:generic, @indent)

         if nest_kind == :NIL_NEST
            dbgtail_off!
            raise "empty else clause!"
         end

         add_nest :else, dedent_level, "", (nest_kind == :LINE_NEST), false # *TODO* flag WHAT kind of else it is (try)

         a_fulfil = parse_expressions
         skip_statement_end
      end

      if kwd?(:ensure)
         next_token_skip_space
         nest_kind, dedent_level = parse_nest_start(:generic, @indent)
         if nest_kind == :NIL_NEST
            dbgtail_off!
            raise "empty ensure clause!"
         end

         add_nest :ensure, dedent_level, "", (nest_kind == :LINE_NEST), false

         a_ensure = parse_expressions
         skip_statement_end
      end

      end_location = token_end_location

      if rescues || a_fulfil || a_ensure
         {ExceptionHandler.new(exp, rescues, a_fulfil, a_ensure).at_end(end_location), end_location}
      else
         exp
         {exp, end_location}
      end
   end

   # SemicolonOrNewLine = [:";", :NEWLINE]

   def parse_rescue
      next_token_skip_space

      if tok? :IDFR
         name = @token.value.to_s
         add_var name
         next_token_skip_space
      end

      if tok? :CONST #, :"(" # should possibly support grouping the "sumtype" with parens.. minor detail. And not recommended practise. So...
         types = parse_rescue_types
      end

      nest_kind, dedent_level = parse_nest_start :generic, @indent
      add_nest :rescue, dedent_level, "", (nest_kind == :LINE_NEST), false

      if nest_kind == :NIL_NEST # kwd?("end")
         body = nil
         handle_nest_end true
      else
         body = parse_expressions
         # skip_statement_end
      end

      Rescue.new(body, types, name)
   end

   def parse_rescue_types
      types = [] of ASTNode

      while true
         types << parse_constish
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

   def parse_for
      # for k, v in some–range
      # for k: v in some–range
      # for v in some–range
      # for k: in some-range
      # for k:_ in some-range
      # for k, in some–range
      # for k,_ in some–range
      # for v[k] in some–range
      # for [k] in some–range
      # for v in 0...10
      # for v in 1..10

      # range syntax ONLY available in for–construct
      # for v til 10
      # for v to 10
      # for v from 1 to 10
      # for v from 0 til 10
      # for v in 0 til 10
      # for v in 1 to 10

      @control_construct_parsing += 1  # for "indent is call" syntax excemption

      # we should push a new scope huh?
      slash_is_regex!
      for_indent = @indent
      push_scope

      next_token_skip_space

      dbg "check if index only `[` | `,`"

      if tok? :"[", :","
         val_var = nil

      else
         val_var = Var.new(check_idfr).at(@token.location)
         next_token_skip_space
      end

      key_var = nil

      dbg "check for `:` | `,` | `[`"

      if tok? :":" # the special "for-colon"
         next_token_skip_space
         key_var = val_var
         if kwd? :in, :from, :to, :til
            val_var = nil

         else
            val_var = Var.new(check_idfr).at(@token.location)
            next_token_skip_space
         end

      elsif tok? :","
         next_token_skip_space
         key_var = Var.new(check_idfr).at(@token.location)
         next_token_skip_space

      elsif tok? :"["
         next_token_skip_space
         key_var = Var.new(check_idfr).at(@token.location)
         next_token_skip_space
         raise "Expected `]` in `for`-expression" unless tok? :"]"
         next_token_skip_space
      end

      add_var key_var if key_var
      add_var val_var if val_var

      dbg "check for in|from|to|til"

      # *TODO*
      case @token.value
      when :in
         next_token_skip_space
         dbg "parse iterable expression"
         iterable = parse_op_assign_no_control allow_suffix: false
         dbg "got iterable expression"

      when :to
         next_token_skip_space
         dbg "parse range end expression"
         range_end_expr = parse_op_assign_no_control allow_suffix: false
         iterable = RangeLiteral.new new_num_lit(0), range_end_expr, false

      when :til
         next_token_skip_space
         dbg "parse range end expression"
         range_end_expr = parse_op_assign_no_control allow_suffix: false
         iterable = RangeLiteral.new new_num_lit(0), range_end_expr, true

      when :from
         next_token_skip_space
         dbg "parse range begin expression"
         range_begin_expr = parse_op_assign_no_control allow_suffix: false
         kwd = @token.value
         # *TODO* should get tokens position for the possible raise also
         next_token_skip_space
         dbg "parse range end expression"
         range_end_expr = parse_op_assign_no_control allow_suffix: false
         if kwd == :til
            iterable = RangeLiteral.new range_begin_expr, range_end_expr, true
         elsif kwd == :to
            iterable = RangeLiteral.new range_begin_expr, range_end_expr, false
         else
            dbgtail_off!
            raise "expected `to` or `til` in `for .. from ..`-expression"
         end

      else
      # *TODO* also here: save the position above
         dbgtail_off!
         raise "expected `in`, `from`, `to` or `til` in `for`-expression"
      end

      dbg "check for step|by"

      if kwd? :step, :by
         next_token_skip_space
         stepping = parse_op_assign_no_control allow_suffix: false
      else
         stepping = nil
      end

      dbg "check block start"

      @control_construct_parsing -= 1  # for "indent is call" syntax excemption

      nest_kind, dedent_level = parse_nest_start(:generic, for_indent)
      add_nest :for, dedent_level, "", (nest_kind == :LINE_NEST), false

      if nest_kind == :NIL_NEST
         body = NilLiteral.new
         handle_nest_end true
      else
         body = parse_expressions
      end

      dbg "after for body"

      pop_scope

      For.new(val_var, key_var, iterable, stepping, body)
   end

   def parse_while
      parse_while_or_until While
   end

   def parse_until
      parse_while_or_until Until
   end

   def parse_while_or_until(klass)
      @control_construct_parsing += 1  # for "indent is call" syntax excemption
      while_indent = @indent
      slash_is_regex!
      next_token_skip_space_or_newline

      cond = parse_op_assign_no_control allow_suffix: false

      @control_construct_parsing -= 1  # for "indent is call" syntax excemption

      slash_is_regex!
      # skip_statement_end
      nest_kind, dedent_level = parse_nest_start :generic, while_indent
      add_nest (klass == While ? :while : :until), dedent_level, "", (nest_kind == :LINE_NEST), false

      if nest_kind == :NIL_NEST
         body = NilLiteral.new
         handle_nest_end true
      else
         body = parse_expressions
      end

      dbg "after while body parse"
      skip_statement_end

      end_location = token_end_location

      dbg "after while body parse before next_token_skip_space"

      # next_token_skip_space

      dbg "/while parse"

      klass.new(cond, body).at_end(end_location)
   end




   # def parse_babel_def() : ASTNode
   #    check :babel
   #    next_token_skip_space

   #    given_name_type = @token.type
   #    if ! tok? :IDFR, :CONST
   #       raise "expected an identifier like `ident` or `Ident`"
   #    end

   #    given = @token.value.to_s

   #    check :"<=="
   #    next_token_skip_space

   #    if ! tok? given_name_type
   #       raise "foreign name must be of same type as given name. Slipped on the shift-key?"
   #    end

   #    foreign = @token.value.to_s
   #    end_location = @token.end_location
   #    next_token_skip_space

   #    # *TODO* for better errors : test that the construct is finished! (new–line, dedent, ; or end)

   #    BabelDef.new(given, foreign).at_end(end_location)

   # end

   def parse_type_def() : ASTNode
      dbg "parse_type_def ->"
      @type_nest += 1


      # *TODO* former params
      is_abstract = false
      is_struct = false
      # *TODO* former params

      base_type = nil


      doc = @token.doc

      indent_level = @indent

      next_token_skip_space_or_newline
      name_column_number = @token.column_number

      name = parse_constish allow_type_vars: false

      # *TODO* below was in "parse_alias" - COMPARE!!!
      # name = check_const


      # *TODO* add scope???

      dbg "- parse_type_def - parse_type_vars"

      type_vars = parse_type_vars
      skip_space


      unless tok? :"=", :"<"
         base_type = nil #Path-or-something "Reference" # class
         builder = :object

      else
         if tok? :"="
            relation = :"="
         elsif tok? :"<="
            next_token
            if tok? :"="
               relation = :"<=="
            else
               raise "Expected `<==` for type renaming"
            end
         else
            relation = :"<"
         end

         next_token_skip_space

         if kwd? :abstract
            # builder_modifier = :abstract
            is_abstract = true
            next_token_skip_space
         end

         if tok? :IDFR
            case @token.value
            when :reference
               explicit_builder = :object
            when :object, :value, :enum, :flags, :sum, :alias
               explicit_builder = @token.value

            when :typeof, :typedecl
               # do nothing

            else
               dbgtail_off!
               raise "unexpected token - expected type-builder-name or base_type"
            end

            next_token_skip_space
         end

         if tok? :typeof, :typedecl
            base_type = parse_typedecl

         elsif tok? :CONST, :"'", :"(" # most likely a type!
            base_type = parse_type false # parse_type_union-or-single-type-(fun-type-also-then)
            # *NOTE* - BEFORE 'supertype' was parsed with `parse_constish`

         else
            base_type = nil
         end

         if base_type == nil
            raise "sum types and aliases needs right hand side types " if (explicit_builder == :sum || explicit_builder == :alias)
            builder = explicit_builder || :object

         elsif base_type.is_a? Union
            raise "A sum type is assigned to name from type builder, not inherited " if relation != :"="
            raise "Can't declare sum type for an explictly non sum type!" if (explicit_builder != nil && explicit_builder != :sum)
            builder = :sum

         else # if base_type == SomeSimpleType
            if relation == :"="
               raise "only works for a type alias" if (explicit_builder != nil && explicit_builder != :alias)
               builder = :alias

            else
               raise "can't mark inheritance for sum or alias types - they're associated with '=' " if (explicit_builder == :sum || explicit_builder == :alias)
               builder = explicit_builder || :object
            end
         end

      end

      if type_vars
         raise "alias name can't have typevars" if builder == :alias
         raise "sum type name can't have typevars" if builder == :sum
      end

      skip_space

      dbg "- parse_type_def - check for type suffix-pragmas"
      if pragmas?
         pragmas = parse_pragma_grouping
      else
         pragmas = [] of Attribute
      end

      case builder
      when :alias, :sum
         alias_node = Alias.new(name.to_s, base_type.not_nil!)
         alias_node.doc = doc
         return alias_node
      end

      dbg "- parse_type_def - before body"
      # skip_statement_end
      nest_kind, dedent_level = parse_nest_start(:type, indent_level)
      add_nest :type, dedent_level, name.to_s, (nest_kind == :LINE_NEST), false

      if nest_kind == :NIL_NEST
         raise "can't have empty enum! '#{name}'" if builder == :enum
         raise "can't have empty flags! '#{name}'" if builder == :flags
         body = nil
         handle_nest_end true

      else
         case builder
         when :enum, :flags
            body = parse_type_def_body :ENUM_DEF

         else
            body = parse_type_def_body :TYPE_DEF
         end

         body = case
         when body.is_a? Expressions
            body.expressions
         when body.is_a? Array(ASTNode+)
            body
         else
            [body]
         end

      end

      dbg "- parse_type_def - after body"

      end_location = @token.location # body.end_location # token_end_location
      # check_idfr "end"
      # next_token_skip_space

      raise "Bug: ClassDef name can only be a Path" unless name.is_a?(Path)

      @type_nest -= 1

      case builder
      when :enum
         raise "Bug: `enum` name can only be a Path" unless name.is_a?(Path)
         type_def = EnumDef.new name, body.not_nil!, base_type

      when :flags
         raise "Bug: `flags` name can only be a Path" unless name.is_a?(Path)
         type_def = EnumDef.new name, body.not_nil!, base_type
         type_def.attributes = [Attribute.new "Flags", [] of ASTNode, nil]

      when :value
         is_struct = true
         type_def = ClassDef.new name, body || NilLiteral.new, base_type, type_vars, is_abstract, is_struct, name_column_number

      when :object
         type_def = ClassDef.new name, body || NilLiteral.new, base_type, type_vars, is_abstract, is_struct, name_column_number

      else
         dbgtail_off!
         raise "internal error - type builder == '#{builder}'"
      end

      type_def.doc = doc
      type_def.end_location = end_location
      type_def
   ensure
      dbgtail "/parse_type_def"
   end


   # *TODO* used only by C–Lib now
   def parse_enum_def
      doc = @token.doc

      enum_indent = @indent

      next_token_skip_space # _or_newline

      name = parse_constish allow_type_vars: false
      skip_space

      if tok? :CONST, :"'" # most likely a type!
         base_type = parse_single_type
      end

      nest_kind, dedent_level = parse_nest_start(:type, enum_indent)
      add_nest :enum, dedent_level, name.to_s, (nest_kind == :LINE_NEST), false

      if nest_kind == :NIL_NEST
         dbgtail_off!
         raise "can't have an empty enum!"
      end

      members = parse_type_def_body :ENUM_DEF

      raise "Bug: EnumDef name can only be a Path" unless name.is_a?(Path)

      the_members = case
      when members.is_a? Expressions
         members.expressions
      when members.is_a? Array(ASTNode+)
         members
      else
         [members]
      end

      enum_def = EnumDef.new name, the_members, base_type
      enum_def.doc = doc
      enum_def
   end

   def parse_trait_def
      @type_nest += 1

      trait_indent = @indent

      location = @token.location
      doc = @token.doc

      next_token_skip_space_or_newline

      name_column_number = @token.column_number
      name = parse_constish allow_type_vars: false
      skip_space

      type_vars = parse_type_vars
      skip_statement_end

      nest_kind, dedent_level = parse_nest_start(:type, trait_indent)
      add_nest :trait, dedent_level, name.to_s, (nest_kind == :LINE_NEST), false

      if nest_kind == :NIL_NEST
         body = Nop.new
         handle_nest_end true
      else
         body = parse_type_def_body :TRAIT_DEF
      end

      end_location = token_end_location

      raise "Bug: TraitDef name can only be a Path" unless name.is_a?(Path)

      @type_nest -= 1

      # *TODO* ModuelDef will do for now unti we know if we go with the trait notation
      module_def = ModuleDef.new name, body, type_vars, name_column_number
      module_def.doc = doc
      module_def.end_location = end_location
      module_def
   end

   def parse_module_def
      dbg "parse_module_def ->"

      @type_nest += 1

      mod_indent = @indent

      location = @token.location
      doc = @token.doc

      next_token_skip_space_or_newline

      name_column_number = @token.column_number
      name = parse_constish allow_type_vars: false
      skip_space

      type_vars = parse_type_vars
      skip_statement_end

      nest_kind, dedent_level = parse_nest_start(:generic, mod_indent)
      add_nest :module, dedent_level, name.to_s, (nest_kind == :LINE_NEST), false

      if nest_kind == :NIL_NEST
         body = Nop.new
         handle_nest_end true
      else
         body = parse_expressions
      end

      end_location = token_end_location

      raise "Bug: ModuleDef name can only be a Path" unless name.is_a?(Path)

      @type_nest -= 1

      module_def = ModuleDef.new name, body, type_vars, name_column_number
      module_def.doc = doc
      module_def.end_location = end_location
      module_def

   ensure
      dbgtail "/parse_module_def"
   end


   def parse_type_def_body(def_kind) : ASTNode # Expressions
      dbg "parse_type_def_body ->"

      members = [] of ASTNode

      if pragmas?
         # *TODO* use the pragmas
         pragmas = parse_pragma_cluster
         dbg "Got PRIMARY pragmas in type-def root level - apply to the type defined. #{pragmas}"
      end

      until handle_nest_end # tok?(:END)
         dbg "in parse_type_def body loop: #{@token}"

         # case @token.type
         # when :NEWLINE
         if tok? :NEWLINE
            next_token_skip_space

         # *TODO* moved this check down to "else" and re–structure this as case again!
         elsif pragmas? # when :PRAGMA
            # *TODO* use the pragmas
            # *TODO*
            # \public               - pub
            # \private|family       - rel | fam
            # \protected|internal   - mine
            pragmas = parse_pragma_grouping
            dbg "Got pragma in type-def root level - apply to next item! #{pragmas}"

         elsif tok? :IDFR # when :IDFR
            dbg "in parse_type_def body loop: in IDFR branch"

            case @token.value
            when :mixin
               dbg "in parse_type_def body loop: in IDFR :mixin branch"
               check_not_inside_def("can't mixin inside def") do
                  members << parse_include
               end
            when :extend
               check_not_inside_def("can't extend inside def") do
                  members << parse_extend
               end
            when :template
               # *TODO*
               check_not_inside_def("can't define macro inside def") do
                  members << parse_tplmacro # *TODO* parse_tpl_macro
               end
            when :macro
               # *TODO*
               check_not_inside_def("can't define macro inside def") do
                  members << parse_tplmacro # *TODO* parse_run_macro
               end
            when :ifdef
               members << parse_ifdef def_kind
            else
               members.concat parse_typedef_body_var_or_const on_self: false
            end


            # *TODO* handle type/class/struct/enum etc. here also???


         elsif tok? :CONST # #when :CONST
            dbg "is const - check for Self, Class or Type"
            if const? :Self, :Class, :Type
               variant = @token.value
               dbg "is #{variant}"
               next_token_skip_space

               if !tok? :"."
                  dbgtail_off!
                  raise "unexpected `#{variant}` in type definition. Expected following `.`"
               end
               next_token_skip_space

               members.concat parse_typedef_body_var_or_const on_self: true

            else
               if def_kind == :ENUM_DEF
                  dbg "is \"generic enum const\""

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

                  if tok? :",", :";"
                     next_token_skip_statement_end
                  end

                  arg = Arg.new(constant_name, constant_value).at(location)
                  arg.doc = member_doc

                  members << arg

               else
                  dbg "is \"generic\" const"
                  members.concat parse_typedef_body_var_or_const on_self: false
               end
            end
         elsif tok? :INSTANCE_VAR  # when :INSTANCE_VAR
            members.concat parse_typedef_body_var_or_const on_self: false

         elsif tok? :CLASS_VAR # when :CLASS_VAR
            members.concat parse_typedef_body_var_or_const on_self: true

         else
            # we try method parse on most things simplt ( [](), +(), etc!!)
            members.concat parse_typedef_body_var_or_const on_self: false
            #raise "Wtf, etc. mm. and so on.: unexpected #{@token}"

         end

         dbg "- parse_type_def_body - eof loop - time for handle_nest_end"

      end

      # if def_kind == :ENUM_DEF
      #    members
      # else
      #    body = Expressions.from(members) # *TODO* .at(members)
      # end
      body = Expressions.from(members) # *TODO* .at(members)

   ensure
      dbgtail "/parse_type_def_body"
   end

   def ensure_at_prefix(s)
      return s if s.starts_with? "@"
      return "@#{s}"
   end

   def ensure_atat_prefix(s)
      return s if s.starts_with? "@@"
      return "@@#{s}"
   end

   def parse_typedef_body_var_or_const(on_self = false) : Array(ASTNode)
      rets = [] of ASTNode

      case
      when tok? :CONST
         # constvar = parse_constish_or_type_tied_literal
         # skip_space
         name = @token.value.to_s

         # *TODO* *VERIFY* instance const??

         if on_self
            name = ensure_atat_prefix name
            constvar = ClassVar.new(name).at(@token.location)
         else
            # constvar = InstanceVar.new(name).at(@token.location)
            constvar = Path.new([name]).at(@token.location)
         end

         next_token_skip_space

         # *TODO* handle type (!!??)
         # o.restriction = ...

         if tok? :"="
            dbg "found assign to const"
            next_token_skip_space_or_newline
            value = parse_op_assign
            rets << Assign.new(constvar, value).at(constvar)

         else
            rets << constvar
         end

      when tok?(:CLASS_VAR) || tok?(:INSTANCE_VAR) || tok?(:IDFR)
         dbg "(maybe) found instance var"
         name = @token.value.to_s
         name_loc = token_end_location

         if tok?(:IDFR)
            if (name == "def" || name == "fn" || name == "own" || name == "fun")   # *TODO* old–school def's supported for now
               next_token_skip_space
               name = @token.value.to_s
            end

            # method def?
            if (current_char == '(' ||
               (
                  current_char == '*' &&
                  (peek_next_char == '(' || peek_next_char == '*')
               ) ||
               (
                  current_char == '=' &&
                  (peek_next_char == '(' || peek_next_char == '*')
               )
            )
               dbg "Found def"


               # *TODO* def_kind == :TRAIT_DEF => disallow 'init'
               # *TODO* handle class vs instance method

               rets << (ret = parse_def)
               if on_self
                  ret.receiver = Var.new "self"
               else
                  # Funky name haxoring done early
                  if ret.name == "init"
                    ret.name = "initialize"
                  end
               end

               return rets
            end
         end

         dbg "did so!"

         if (foo = name[-1]) == '!' || foo == '?'
            dbgtail_off!
            raise "only functions and methods may end with '!' or '?'", name_loc
         end

         if tok?(:CLASS_VAR) || on_self
            name = ensure_atat_prefix name

         else # if tok?(:INSTANCE_VAR)
            name = ensure_at_prefix name
         end

         if ! on_self
            # *TODO*
            add_instance_var name
         end

         if tok?(:CLASS_VAR) || on_self
            var = ClassVar.new(name).at(@token.location)
         else
            var = InstanceVar.new(name).at(@token.location)
         end

         var.end_location = token_end_location
         @wants_regex = false
         next_token_skip_space

         # *TODO* change check to `possible_type?` ( paren, const, typeof, auto, '~^ )
         if !tok?(:NEWLINE, :DEDENT, :";", :"=", :PRAGMA) && !end_token?
            dbg "found type declaration"
            # *TODO* we must take care of the type qualifiers
            mutability, storage, var_type = parse_qualifer_and_type
         else
            mutability = :auto
            var_type = nil
            dbg "found NO type"
         end

         if tok? :"="
            dbg "found assign to idfr"
            next_token_skip_space_or_newline
            assign_value = parse_op_assign
            dbg "/found assign to idfr"
         else
            assign_value = nil
         end

         if var_type
            dbg "add type declaration"
            is_assign_composite = assign_value != nil
            rets << TypeDeclaration.new(var, var_type, is_assign_composite, mutability: mutability).at(var.location)
         end

         if assign_value
            if var_type
               var = var.clone
            end
            rets << Assign.new(var, assign_value).at(var) # var | var.location!? *TODO*
         end


         dbg "after possible assign to idfr"

         skip_space

         dbg "parse_typedef_body_var_or_const() - check for pragmas"
         if pragmas? # tok? :PRAGMA
            pragmas = parse_pragma_grouping

            if pragmas.size
               dbg "found pragmas for .. whatever..: #{pragmas}"
            end

            naked_name = name[((name.rindex('@')||-1)+1)..-1]

            pragmas.select! do |pragma|
               raise "Non pragma in pragma list!? #{pragma}" unless pragma.is_a? Attribute

               case pragma.name
               when "get"
                  rets << Def.new naked_name, [] of Arg, var.clone
                  false
               when "set"
                  if var_type
                     rets << Def.new "#{naked_name}=", [Arg.new(name, restriction: var_type.not_nil!.clone)] #, Nop.new
                  else
                     rets << Def.new "#{naked_name}=", [Arg.new(name)] #, Nop.new
                  end
                  false
               else
                  true
               end
            end

         end

         rets

      else
         # Try parse_def ELSE do some error!
         begin
            rets << (ret = parse_def)
            if on_self
               ret.receiver = Var.new "self"
            end
            return rets
         rescue e : WrongParsePathException
            dbgtail_off!
            dbg "What happened in `parse_typedef_body_var_or_const` when parsing def? #{e}"
            raise "What happened in `parse_typedef_body_var_or_const` when parsing def? #{e}"
         end
      end

      rets

   ensure
      dbgtail "/parse_typedef_body_var_or_const"
   end






   def parse_type_vars
      type_vars = nil
      if tok? :"<", :"["
         type_vars = [] of String

         next_token_skip_space_or_newline
         while !tok? :">", :"]"
            type_var_name = check_const
            unless OnyxParser.free_var_name?(type_var_name)
               dbgtail_off!
               raise "type variables can only be single letters optionally followed by a digit", @token
            end

            if type_vars.includes? type_var_name
               dbgtail_off!
               raise "duplicated type var name: #{type_var_name}", @token
            end
            type_vars.push type_var_name

            next_token_skip_space_or_newline
            if @token.type == :","
               next_token_skip_space_or_newline
            end
         end

         if type_vars.empty?
            dbgtail_off!
            raise "must specify at least one type var"
         end

         next_token_skip_space
      end
      type_vars
   end



   def parse_parenthetical_unknown
      dbg "parse_parenthetical_unknown"

      # candidate = heuristic_scan_parenthetical_unknown

      backed = backup_tok()

      # soft lambdas are likely most common - let's try it first!
      # Note - parametrized s–lambdas might _not_ be most common! *TODO*

      # Current order of testing:
      #
      #  - parametrized soft–lambda
      #  - grouped expression
      #  - regular lambda
      #  - tuple

      # - It should be re–written to sequentially figure out if one or the other
      # can be dismissed, the only pass–over node requirement would likely be
      # the first param/element for `~λ`, `λ` and `T`.
      # - Then the final possibility is the grouping



      # PSEUDO - HEURISTIC
      # return if not paren

      # any–of = Set{:tuple, :grouping, :lambda, :softlambda}
      # possibles = any–of

      # next_token; skip_space

      # possibles.=intersect (
      #    if literal  => Set{:tuple, :grouping}
      #    elif idfr   => any–of
      #    elif ')'    => Set{:lambda, :softlambda}
      #    else        => any–of
      # )

      # next_token; skip_space

      # possibles.=intersect (
      #    if ','      => Set{:tuple, :softlambda}
      #    elif Typish => Set{:grouping | :lambda}
      #    elif ')'    =>
      #    else        => any–of
      # )

      # next_token; skip_space

      # possibles.=intersect (
      #    if ',' => Set{:grouping | :lambda}
      #    elif ')'
      # )

      # Nooo... this naive way without real node–parsing doesn't help - an element
      # of a tuple can be an expression.




      begin
         dbg "parse_parenthetical_unknown - TRY parse_softlambda".magenta
         ret = parse_softlambda
         dbg "parse_parenthetical_unknown - parse_parenthesized_expression try worked".magenta

      rescue e : WrongParsePathException
         restore_tok backed

         begin
            dbg "parse_parenthetical_unknown - TRY parse_parenthesized_expression".magenta
            ret = parse_parenthesized_expression
            dbg "parse_parenthetical_unknown - parse_parenthesized_expression try worked".magenta

         # Not that either? Let's go for parentheses–tuple–literal
         rescue e
            restore_tok backed

            begin
               dbg "parse_parenthetical_unknown - TRY parse_paren_tuple".magenta
               ret = parse_paren_tuple
               return ret

            # Not that either? Let's go for (common) Lambda
            rescue e # : WrongParsePathException
               restore_tok backed

               begin
                  dbg "parse_parenthetical_unknown - TRY parse_lambda".magenta
                  ret = parse_lambda
                  return ret

               rescue e : WrongParsePathException
                  restore_tok backed

                  dbg "parse_parenthetical_unknown".magenta + " - parse_parenthesized_expression TO FAIL!".red
                  # Parse again and _let it fail this time_
                  parse_parenthesized_expression
                  dbgtail_off!
                  raise "This shouldn't be reached ever (above should fail) 3546!".red

               end
            end
         else
            dbg "parse_parenthetical_unknown - else after par-expr worked".magenta

            skip_space

            # It's a lambda even though an expression could be parsed - REDO!
            if tok? :"->"
               dbg "parse_parenthetical_unknown - got PAR_EXPR - but it is a lambda anyway: re-parse".magenta
               restore_tok backed
               return parse_lambda

            # *TODO* - YES IT CAN! If it is softlambda with errors in it!
            # Can't happen here, since we try it first
            # elsif tok? :"~>"
            #    dbg "parse_parenthetical_unknown - got PAR_EXPR - but it is a soft-lambda anyway: re-parse".magenta
            #    restore_tok backed
            #    return parse_softlambda

            elsif ret == nil
               dbgtail_off!
               raise "UNEXPECTED ERROR 2372! FIXME!"

            else
               return ret
            end
         end
      end
      return ret
   end

   # def heuristic_scan_parenthetical_unknown
   #    backed_pos = @current_pos
   #    # *TODO* - this will allow for much better error messages (and faster
   #    # parsing for most cases)
   # end

   def parse_parenthesized_expression
      dbg "parse_parenthesized_expression"
      dbginc

      # *TODO* this should open a nest where CONTINUATION is norm, if other
      # nests are opened inside, they re–introduce INDENT–sense, etc.

      location = @token.location
      next_token_skip_statement_end

      if tok? :INDENT, :DEDENT, :NEWLINE   # for `(\n      expr–begins–here...`
         next_token
      end

      # *TODO* should probably support `(\n      )` etc. constructs (for commented out stuff)
      if @token.type == :")"
         ret = NilLiteral.new
         ret.parenthesized = true
         return node_and_next_token ret
      end

      exps = [] of ASTNode

      while true
         dbg "parse_parenthesized_expression - before 'parse_expression'"
         exps << parse_expression
         dbg "parse_parenthesized_expression - after 'parse_expression'"

         # *TODO* this (`)` vs `\n    )`) should be handled with a better LPAR|(DEDENT+LPAR) checking..
         case @token.type
         when :")"
            dbg "parse_parenthesized_expression: got ')'"
            @wants_regex = false
            next_token_skip_space
            break

         when :NEWLINE, :";", :INDENT, :DEDENT # (shouldn't be generated: lexer!!)
            dbg "parse_parenthesized_expression: got ;|\\n"
            next_token_skip_space_or_indent

            if @token.type == :")"
               dbg "parse_parenthesized_expression: got ')' after stop"
               @wants_regex = false
               next_token_skip_space
               break
            end

         else
            dbgtail_off!
            raise "unterminated parenthesized expression", location

         end
      end

      ret = Expressions.new exps
      ret.parenthesized = true

      # Check if a call is being made directly upon the grouped expression
      if tok? :"("
         dbg "CALL DIRECTLY ON PARENTHESIZED EXPR - INTENTIONAL?".red
         name_column_number = @token.column_number
         has_parens, call_args = parse_call_args true, -47
         call_args = call_args.not_nil!
         args = call_args.args
         block = call_args.block
         explicit_block_param = call_args.explicit_block_param
         named_args = call_args.named_args

         Call.new(ret, "call", args, block, explicit_block_param, named_args, false, name_column_number, has_parenthesis: has_parens)
      else
         ret
      end

   ensure
      dbgdec
   end

   def parse_lambda
      dbg "parse_lambda"
      check :"("

      lambda_indent = @indent

      begin
         next_token_skip_space_or_newline

         args = [] of Arg

         while @token.type != :")"
            location = @token.location
            arg = parse_lambda_arg.at(location)
            if args.any? &.name.==(arg.name)
               dbgtail_off!
               raise "duplicated argument name: #{arg.name}", location
            end

            args << arg
         end

      rescue e
         dbg "parse_lambda: rescue e: #{e.message}"
         Crystal.raise_wrong_parse_path "parsing lambda failed"

      end

      next_token_skip_space_or_newline

      end_location = nil

      nest_kind, callable_kind, returns_nothing, _ = parse_def_nest_start
      add_nest :lambda, lambda_indent, "", (nest_kind == :LINE_NEST), false
      # *TODO* use callable_kind and set on Def–node

      @scope_stack.push_scope
      add_vars args

      if nest_kind == :NIL_NEST
         body = Nop.new
         handle_nest_end true
      else
         # parse possible "first of body" pragmas
         if pragmas? # tok? :PRAGMA
            dbgtail_off!
            raise "TODO   aight!"
         end

         body = parse_expressions
      end
      end_location = token_end_location

      pop_scope

      # next_token_skip_space

      FunLiteral.new(Def.new("->", args, body)).at_end(end_location)
   end

   def parse_lambda_arg
      dbg "parse_lambda_arg, at"

      # *TODO* generate new tmp name per arg. if several...
      if tok? :UNDERSCORE
         name = "tmp_47_"
      else
         name = check_idfr
      end
      next_token_skip_space_or_newline

      dbg "parse_lambda_arg: name = " + name.to_s

      if @token.type != :"," && @token.type != :";" && @token.type != :")"
         dbg "parse_lambda_arg: parse a type"

         mutability, storage, type = parse_qualifer_and_type()
      else
         mutability = :auto
         dbg "parse_lambda_arg: no type"
      end

      if @token.type == :"," || @token.type == :";"
         next_token_skip_space_or_newline
      end

      Arg.new name, restriction: type, mutability: mutability
   end


   def parse_softlambda : Block
      dbg "parse_softlambda ->"

      block_auto_params = [] of Var
      block_body = nil
      auto_parametrization = false

      block_indent = @indent

      if tok? :"~.", :"\\."
         return parse_oneletter_softlambda

      elsif tok? :"~>", :"\\"
         dbg "parse_softlambda - auto-paramed arrow"
         auto_parametrization = true

      elsif @token.type == :"("
         begin
            next_token_skip_space

            while @token.type != :")"
               case @token.type
               when :IDFR
                  arg_name = @token.value.to_s

               when :UNDERSCORE
                  arg_name = "_"

               else
                  dbgtail_off!
                  raise "expecting block argument name, not #{@token.type}", @token
               end

               var = Var.new(arg_name).at(@token.location)
               block_auto_params << var

               next_token_skip_space_or_newline
               if tok? :",", :";" # these are PARAMS so semis allowed.
                  next_token_skip_space_or_newline
               end
            end

            dbg "parse_softlambda - done parsing block parameters"

            next_token_skip_space
            raise "expected `~>` or `\\`" if !tok? :"~>", :"\\"

         rescue e
            dbg "parse_softlambda - rescue e: #{e.message}".red
            Crystal.raise_wrong_parse_path "Parsing soft lambda failed"

         end

      else
         dbgtail_off!
         raise "parse_softlambda - Expected block start!"
      end

      #next_token_skip_statement_end
      next_token_skip_space

      push_scope

      nest_kind, dedent_level = parse_nest_start(:block_start, block_indent)
      add_nest :block, dedent_level, "", (nest_kind == :LINE_NEST), false

      if auto_parametrization
         dbg "auto_parametrization - so we add to nesting_stack. block_auto_params == nil? : #{block_auto_params == nil}".red
         @nesting_stack.last.block_auto_params = block_auto_params
      else
         add_vars block_auto_params
      end

      if nest_kind == :NIL_NEST
         dbgtail_off!
         raise "can't have an empty block!"   # *TODO* we probably should be able to!
      end

      dbg "parse_softlambda - before parse_expressions"

      # auto–params are extracted in var_or_call parsing when above nest_stack
      # has block_auto_params and name ~= /_\d/
      block_body = parse_expressions

      dbg "parse_softlambda - AFTER parse_expressions"

      pop_scope

      end_location = token_end_location

      Block.new(block_auto_params, block_body).at_end(end_location)
   end




   def parse_fun_pointer
      location = @token.location

      case @token.type
      when :IDFR
         name = @token.value.to_s
         next_token_skip_space
         if @token.type == :"."
            next_token_skip_space
            second_name = check_idfr
            if name != "self" && !@scope_stack.cur_has?(name)
               dbgtail_off!
               raise "undefined variable '#{name}'", location.line_number, location.column_number
            end
            obj = Var.new(name)
            name = second_name
            next_token_skip_space
         end
      when :CONST
         obj = parse_constish
         check :"."
         next_token_skip_space
         name = check_idfr
         next_token_skip_space
      else
         unexpected_token "while parsing lambda-pointer operator"
      end

      if @token.type == :"."
         unexpected_token "while parsing lambda-pointer operator"
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


      # *TODO* handle straight–string vs interpolated...
      # + all other string–styles - must flag literal–style


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
            dbgtail_off!
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
               dbgtail_off!
               raise "Unterminated command"
            when :regex
               dbgtail_off!
               raise "Unterminated regular expression"
            when :heredoc
               dbgtail_off!
               raise "Unterminated heredoc"
            else
               dbgtail_off!
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
               dbgtail_off!
               raise "Unterminated string interpolation"
            end
            #next_token
            # if @token.type != :"}"
            #    raise "Unterminated string interpolation"
            # end

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
               dbgtail_off!
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
      parse_string_or_symbol_array TagLiteral, "Symbol"
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
            dbgtail_off!
            raise "Unterminated symbol array literal"
         end
      end

      ArrayLiteral.new strings, Path.global(elements_type)
   end

   def parse_empty_array_literal
      dbg "parse_empty_array_literal"
      line = @line_number
      column = @token.column_number

      next_token_skip_space

      dbg "parse_empty_array_literal - check for 'of', #{kwd?(:of)}"

      if kwd?(:of)
         next_token_skip_space_or_newline
         of = parse_single_type
         ArrayLiteral.new(of: of).at_end(of)
      else
         dbgtail_off!
         raise "for empty arrays use '[] of ElementType'", line, column
      end
   end

   def parse_array_literal_or_multi_assign
      dbg "parse_array_literal_or_multi_assign"
      node = parse_array_literal

      dbg "after parse_array_literal"
      if tok? :"="
         dbg "got '='"
         if node.of
            dbgtail_off!
            raise "Multi assign or array literal? Can't figure out."
         end
         parse_multi_assign node
      else
         dbg "didn't get '='"
         node
      end
   end

   def parse_multi_assign(assignees)
      dbg "parse_multi_assign - get location"
      location = assignees.location.not_nil!

      # *TODO*
      # - extend with [a, _, _, b, ..., c, d] notation
      # (- optimize away temps for literals by assigning immediately)
      # optimally it should be a deconstructor - pattern matching style!
      # (thn half of pattern matching is solved too!)

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
         dbgtail_off!
         raise "Multiple assignment count mismatch", location
      end

      multi = MultiAssign.new(targets, values).at(location)

      dbg "Multi to_s: " + multi.to_s

      parse_expression_suffix multi, @token.location
   end

   def to_lhs(exp)
      if exp.is_a?(Path) && inside_def?
         dbgtail_off!
         raise "dynamic constant assignment"
      end

      if exp.is_a?(Call) && !exp.obj && exp.args.empty?
         exp = Var.new(exp.name).at(exp)
      end
      if exp.is_a?(Var)
         if exp.name == "self"
            dbgtail_off!
            raise "can't change the value of self", exp.location.not_nil!
         end
         add_var exp
      end
      exp
   end

   def parse_array_literal
      slash_is_regex!

      location = @token.location

      exps = [] of ASTNode
      end_location = nil

      open("array literal") do
         next_token
         skip_tokens :NEWLINE, :INDENT, :DEDENT, :SPACE
         while @token.type != :"]"
            exps << parse_expression
            end_location = token_end_location
            # skip_statement_end *TODO* verify
            if tok? :",", :NEWLINE, :INDENT, :DEDENT
               skip_tokens :NEWLINE, :INDENT, :DEDENT, :SPACE
               next_token if tok? :","
               skip_tokens :NEWLINE, :INDENT, :DEDENT, :SPACE
               if tok? :","
                  dbgtail_off!
                  raise "got one comma too much!"
               end
               # *TODO* two commas during the separation should raise!!!
               slash_is_regex!
            end
         end
         next_token_skip_space
      end

      of = nil
      if kwd?(:of)
         next_token_skip_space_or_newline
         of = parse_single_type
         end_location = of.end_location
      end

      ArrayLiteral.new(exps, of).at(location).at_end(end_location)
   end

   def parse_hash_or_set_literal(allow_of = true)
      dbg "parse_hash_or_set_literal"

      location = @token.location
      line = @line_number
      column = @token.column_number

      slash_is_regex!
      next_token
      skip_tokens :NEWLINE, :INDENT, :DEDENT, :SPACE

      if @token.type == :"}"
         end_location = token_end_location
         next_token_skip_space
         new_hash_literal([] of HashLiteral::Entry, line, column, end_location)
      else
         if tok?(:IDFR) && (parser_peek_non_ws_char == ':')
            first_key = StringLiteral.new @token.value.to_s
            next_token_skip_space_or_newline
            slash_is_regex!
            next_token_skip_space_or_newline  # skips :":"
            return parse_hash_literal first_key, location, allow_of

         else
            first_key = parse_op_assign
            case @token.type
            when :":", :"=>"
               slash_is_regex!
               next_token_skip_space_or_newline
               return parse_hash_literal first_key, location, allow_of

            when :",", :NEWLINE, :INDENT, :DEDENT
               parse_item_separator
               slash_is_regex!
               # next_token_skip_space_or_newline
               return parse_set first_key, location

            when :"}"
               return parse_set first_key, location
            else
               raise "expected to parse hash or tuple literal - but now I'm lost"
               # check :":"
            end
         end
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

         skip_statement_end

         if tok? :",", :NEWLINE, :INDENT, :DEDENT
            parse_item_separator
            slash_is_regex!
            # next_token_skip_space_or_newline
         end

         while @token.type != :"}"
            dbg "HASH: key token is?"

            if tok?(:IDFR) && (parser_peek_non_ws_char == ':')
               key = StringLiteral.new @token.value.to_s
               next_token_skip_space_or_newline
            else
               key = parse_op_assign
            end

            slash_is_regex!

            dbg "HASH: value token is?"

            next_token_skip_space_or_newline  # skips :":" | :"=>"

            entries << HashLiteral::Entry.new(key, parse_op_assign)

            # Not parsing as continuation works fine since the braces regulate it
            if tok? :",", :NEWLINE, :INDENT, :DEDENT
               parse_item_separator
               slash_is_regex!
               # next_token_skip_space_or_newline
            end
         end
         end_location = token_end_location
         next_token_skip_space
      end

      new_hash_literal entries, line, column, end_location, allow_of: allow_of
   end

   # def hash_symbol_key?
   #    (@token.type == :IDFR || @token.type == :CONST) && current_char == '#'
   # end

   def parse_set(first_exp, location)
      exps = [] of ASTNode
      end_location = nil

      open("tuple literal", location) do
         exps << first_exp
         while @token.type != :"}"
            exps << parse_expression
            # skip_statement_end

            # if @token.type == :","
            #    next_token_skip_space_or_newline
            # end

            if tok? :",", :NEWLINE, :INDENT, :DEDENT
               parse_item_separator
            end
         end
         end_location = token_end_location
         next_token_skip_space
      end

      tupish_pre_set = TupleLiteral.new(exps).at_end(end_location)
      ary = ArrayLiteral.new(exps, name: Path.global("Set")).at(tupish_pre_set.location)
      ary
   end

   def new_hash_literal(entries, line, column, end_location, allow_of = true)
      of = nil

      if allow_of
         if kwd?(:of)
            next_token_skip_space_or_newline
            of_key = parse_single_type
            # *TODO* syntax for typing the hash–literal!??
            check :"=>", "new_hash_literal"
            # check :":", "new_hash_literal"
            next_token_skip_space_or_newline
            of_value = parse_single_type
            of = HashLiteral::Entry.new(of_key, of_value)
            end_location = of_value.end_location
         end

         if entries.empty? && !of
            dbgtail_off!
            raise "for empty hashes use '{} of KeyType => ValueType'", line, column
         end
      end

      HashLiteral.new(entries, of).at_end(end_location)
   end

   def parse_item_separator
      skip_tokens :NEWLINE, :INDENT, :DEDENT, :SPACE
      if tok? :","
         next_token
         skip_tokens :NEWLINE, :INDENT, :DEDENT, :SPACE
         if tok? :","
            dbgtail_off!
            raise "got one comma too much!"
         end
      end
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
      dbg "parse_case"

      @control_construct_parsing += 1  # for "indent is call" syntax excemption

      # *TODO* depending on (match|branch|case) - the end–token should match
      case_indent_level = @indent

      slash_is_regex!
      next_token_skip_space

      unless tok?(:NEWLINE, :INDENT, :DEDENT)
         @significant_newline = true
         cond = parse_op_assign_no_control
         skip_statement_end
      end

      @control_construct_parsing -= 1  # for "indent is call" syntax excemption

      dbg "parse_case - check block start"
      nest_kind, dedent_level = parse_nest_start(:case, case_indent_level)
      if nest_kind == :NIL_NEST
         dbgtail_off!
         raise "Can't have an empty \"case\" expression. What's the point?"
      end

      free_style = nest_kind == :FREE_WHEN_NEST
      branch_indent_level = @indent

      add_nest :case, dedent_level, "", false, free_style == false # *TODO*          add_nest :lambda, lambda_indent, "", (nest_kind == :LINE_NEST), false


      whens = [] of When
      a_else = nil

      dbg "parse_case - before whens-loop - " + "free_style == #{free_style}".yellow

      while true
         what = :unknown

         if branch_indent_level == @indent
            if (free_style && tok?(:"*")) || kwd?(:else)
               what = :default
               @next_token_continuation_state = :NO_CONTINUATION
               next_token_skip_space
            elsif tok?(:"|")
               next_token_skip_space
               if tok?(:"*", :NEWLINE, :DEDENT, :INDENT, :"=>", :":") || kwd?(:then, :do)
                  what = :default
                  @next_token_continuation_state = :NO_CONTINUATION
                  next_token_skip_space
               else
                  what = :when
               end
            elsif kwd?(:when)
               what = :when
               next_token_skip_space
            elsif free_style
               what = :when
            end
         elsif free_style && tok? :DEDENT
            what = :dedent
         elsif !free_style
            what = :non_when
         end

         case what
         when :default
            nest_kind, dedent_level = parse_nest_start(:else, @indent)
            add_nest :when, dedent_level, "", false, false # *TODO*          add_nest :lambda, lambda_indent, "", (nest_kind == :LINE_NEST), false

            if nest_kind   == :NIL_NEST
               a_else = Expressions.new([Nop.new] of ASTNode)
            else
               if whens.size == 0
                  unexpected_token "expecting when, not catch all"
               end
               slash_is_regex!

               @significant_newline = false
               # next_token_skip_statement_end
               a_else = parse_expressions

               if branch_indent_level == case_indent_level
                  if tok? :DEDENT
                     # next_token_skip_space
                  end
               end

               # skip_statement_end
               dbg "parse_case - finished with an ELSE - break out"
               break
            end
         when :when
            slash_is_regex!
            when_indent = @indent
            # next_token_skip_space_or_newline
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

               dbg "parse_case - parsed when_conds"

               skip_space

               if kwd?(:then, :do)
                  # next_token_skip_space_or_newline
                  break
               else
                  slash_is_regex!
                  case @token.type
                  when :","
                     next_token_skip_space_or_newline
                  when :INDENT, :"=>", :":"
                     # skip_statement_end
                     break
                  when :";"
                     skip_statement_end
                     break
                  else
                     unexpected_token "expecting ',', ';' or '\n'"
                  end
               end
            end

            nest_kind, dedent_level = parse_nest_start(:when, when_indent)
            add_nest :when, dedent_level, "", false, false # *TODO*          add_nest :lambda, lambda_indent, "", (nest_kind == :LINE_NEST), false

            if nest_kind == :NIL_NEST
               whens << When.new(when_conds, Expressions.new([Nop.new] of ASTNode))
            else
               slash_is_regex!
               when_body = parse_expressions # "case" is nested with "require–explicit–end–pop"

               if branch_indent_level == case_indent_level
                  if tok? :DEDENT
                     next_token_skip_space
                  end
               end

               skip_statement_end
               whens << When.new(when_conds, when_body)
            end
         when :dedent
            dbg "parse_case - got free_style and DEDENT token - break out"
            break
         when :non_when
            dbg "parse_case - got NON free_style and non 'when'-token - break out"
            break
            # *TODO* when 'WHEN'-mode, a non–when token at when–indent–level is considered dedent

         else
         # can this happen?
            unexpected_token "expecting when, else or end"
         end
      end

      handle_definite_nest_end_ force: true # *TODO* force can be purged from the codebase

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

      if kwd?(:self)
         name = Self.new.at(@token.location)
         name.end_location = token_end_location
         next_token_skip_space
      else
         name = parse_constish
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
      a_def.uses_block_arg = @uses_explicit_block_param
      a_def.assigns_special_var = @assigns_special_var

      result
   end

   def try_parse_def(is_abstract = false, is_macro_def = false, doc = nil)
      dbg "try_parse_def ->".white

      backed = backup_full

      certain_def_count = @certain_def_count

      begin
         ret = parse_def(is_abstract, is_macro_def, doc)
         return ret # as ASTNode

      rescue
      # rescue e : WrongParsePathException
         if certain_def_count != @certain_def_count   # *TODO* should be removed in favour of specific exception...
            dbgtail_off!
            ::raise @error_stack.last
         end

         dbg "failed try_parse_def".white

         # Rollback parsing a bit - once the language settles we'll implement all
         # this in a neater way that's more performant. For now - low intrusion
         # is better.

         chars_end_pos = current_pos
         restore_full backed

         return chars_end_pos
      end

   ensure
      dbgtail "/try_parse_def".white
   end

   def parse_def(is_abstract = false, is_macro_def = false, doc = nil)
      @def_parsing += 1
      doc ||= @token.doc

      instance_vars = prepare_parse_def
      a_def = parse_def_helper is_abstract: is_abstract, is_macro_def: is_macro_def

      # Small memory optimization: don't keep the Set in the Def if it's empty
      instance_vars = nil if instance_vars.empty?

      a_def.instance_vars = instance_vars
      a_def.calls_super = @calls_super
      a_def.calls_initialize = @calls_initialize
      a_def.uses_block_arg = @uses_explicit_block_param
      a_def.assigns_special_var = @assigns_special_var
      a_def.doc = doc
      @instance_vars = nil
      @calls_super = false
      @calls_initialize = false
      @uses_explicit_block_param = false
      @assigns_special_var = false
      @explicit_block_param_name = nil

      dbg "parse_def done"
      @def_parsing -= 1

      a_def
   end

   def prepare_parse_def
      @calls_super = false
      @calls_initialize = false
      @uses_explicit_block_param = false
      @explicit_block_param_name = nil
      @assigns_special_var = false
      @instance_vars = Set(String).new
   end

   MACRO_CTRL_START_DELIMITER = :"{%"
   MACRO_CTRL_END_DELIMITER = :"%}"
   # MACRO_CTRL_END_DELIMITER = :"}"

   MACRO_VAR_EXPRS_START_DELIMITER = :"{{"
   # MACRO_VAR_EXPRS_START_DELIMITER = :"{"  -- needs tighter checks (if IN_MACRO && content < `}` is in params, THEN it's an interpolation!
   # MACRO_VAR_EXPRS_END_DELIMITER = :"%}"
   MACRO_VAR_EXPRS_END_DELIMITER = :"}"

   def parse_tplmacro
      dbg "parse_tplmacro ->".red

      doc = @token.doc
      indent_level = @indent

      next_token_skip_space_or_newline

      # *TODO* turn this into it's own keyword completely!? "tpldef"
      if kwd?(:def)
         a_def = parse_def_helper is_macro_def: true
         a_def.doc = doc
         return a_def
      end

      push_fresh_scope

      check DefOrMacroCheck1

      name_line_number = @token.line_number
      name_column_number = @token.column_number

      name = check_idfr
      next_token

      args = [] of Arg

      found_default_value = false
      found_splat = false

      splat_index = nil
      index = 0

      # case @token.type
      # when :"("
      check :"("
      next_token_skip_space_or_newline
      while @token.type != :")"
         extras = parse_param(args, nil, true, found_default_value, found_splat, allow_restrictions: false)
         if !found_default_value && extras.default_value
            found_default_value = true
         end
         if !splat_index && extras.splat
            splat_index = index
            found_splat = true
         end
         if explicit_block_param = extras.explicit_block_param
            check :")"
            break
         elsif @token.type == :","
            next_token_skip_space_or_newline
         else
            skip_space
            if @token.type != :")"
               unexpected_token "expected ',' or ')'"
            end
         end
         index += 1
      end
      next_token
      # when :IDFR, :"..." # *TODO* verify - was "*"
      #    while @token.type != :NEWLINE && @token.type != :";"
      #       extras = parse_param(args, nil, false, found_default_value, found_splat, allow_restrictions: false)
      #       if !found_default_value && extras.default_value
      #          found_default_value = true
      #       end
      #       if !splat_index && extras.splat
      #          splat_index = index
      #          found_splat = true
      #       end
      #       if explicit_block_param = extras.explicit_block_param
      #          break
      #       elsif @token.type == :","
      #          next_token_skip_space_or_newline
      #       else
      #          skip_space
      #          if @token.type != :NEWLINE && @token.type != :";"
      #             unexpected_token "expected ';' or newline"
      #          end
      #       end
      #       index += 1
      #    end
      # end

      end_location = nil

      while tok? :SPACE
         next_token
      end

      # nest_kind, callable_kind, returns_nothing, suffix_pragmas = parse_def_nest_start
      # *TODO* possibly :template instead below
      add_nest :macro, indent_level, name.to_s, false, false

      check :"="
      next_token # go to indent/newline - let macro–body take that...

      if kwd? :END # nest_kind == :NIL_NEST
         end_location = token_end_location
         body = Expressions.new
         next_token_skip_space # *TODO* depends on how to handle indents, req'ed end–toks etc.
      else
         body, end_location = parse_tplmacro_body(name_line_number, name_column_number)
      end

      pop_scope

      node = Macro.new name, args, body, explicit_block_param, splat_index
      node.name_column_number = name_column_number
      node.doc = doc
      node.end_location = end_location
      node

   ensure
      dbgtail "/parse_tplmacro".red
   end

   def parse_tplmacro_body(start_line, start_column, macro_state = Token::MacroState.default)
      dbg "parse_tplmacro_body ->"
      skip_whitespace = check_macro_skip_whitespace

      pieces = [] of ASTNode

      while true # !handle_nest_end
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
            pieces << MacroExpression.new(parse_tplmacro_expression)
            check_macro_expression_end
            skip_whitespace = check_macro_skip_whitespace

         when :MACRO_CONTROL_START
            macro_control = parse_tplmacro_control(start_line, start_column, macro_state)
            if macro_control
               pieces << macro_control
               skip_whitespace = check_macro_skip_whitespace
            else
               return Expressions.from(pieces), nil
            end

         when :MACRO_VAR
            macro_var_name = @token.value.to_s
            if current_char == '{'
               macro_var_exps = parse_tplmacro_var_exps
            else
               macro_var_exps = nil
            end
            pieces << MacroVar.new(macro_var_name, macro_var_exps)

         when :MACRO_END
            break

         when :EOF
            dbgtail_off!
            raise "unterminated macro", start_line, start_column
         else
            unexpected_token "while parsing macro body"
         end
      end

      end_location = token_end_location

      #next_token

      {Expressions.from(pieces), end_location}
   end

   def parse_tplmacro_var_exps
      next_token # '{='
      #next_token

      exps = [] of ASTNode
      while true
         exps << parse_expression_inside_macro
         skip_space
         case @token.type
         when :","
            next_token_skip_space
            if @token.type == MACRO_VAR_EXPRS_END_DELIMITER
               break
            end
         when MACRO_VAR_EXPRS_END_DELIMITER
            break
         else
            unexpected_token "expecting ',' or '=}'"
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

   def parse_tplmacro_expression
      dbg "parse_tplmacro_expression ->".red
      next_token_skip_space_or_newline
      parse_expression_inside_macro

   ensure
      dbgtail "/parse_tplmacro_expression".red
   end

   def check_macro_expression_end
      check MACRO_VAR_EXPRS_END_DELIMITER

      # next_token
      # check :"}"
   end

   def parse_tplmacro_control(
      start_line,
      start_column,
      macro_state = Token::MacroState.default
   )
      dbg "parse_tplmacro_control ->".red
      next_token_skip_space_or_newline

      case @token.type
      when :END
         return nil
      when :IDFR
         case @token.value
         when :for
            dbg "- parse_tplmacro_control - for"
            next_token_skip_space

            vars = [] of Var

            while true
               vars << Var.new(check_idfr).at(@token.location)

               next_token_skip_space
               if @token.type == :","
                  next_token_skip_space
               else
                  break
               end
            end

            check_idfr :in
            next_token_skip_space

            exp = parse_expression_inside_macro

            check MACRO_CTRL_END_DELIMITER

            body, end_location = parse_tplmacro_body(start_line, start_column, macro_state)

            check :END
            next_token_skip_space
            check MACRO_CTRL_END_DELIMITER

            return MacroFor.new(vars, exp, body)

         when :if
            dbg "- parse_tplmacro_control - if"
            return parse_tplmacro_if(start_line, start_column, macro_state)

         when :unless
            dbg "- parse_tplmacro_control - unless"
            macro_if = parse_tplmacro_if(start_line, start_column, macro_state)
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
            dbg "- parse_tplmacro_control - begin"
            next_token_skip_space
            check MACRO_CTRL_END_DELIMITER

            body, end_location = parse_tplmacro_body(start_line, start_column, macro_state)

            check :END
            next_token_skip_space
            check MACRO_CTRL_END_DELIMITER

            return MacroIf.new(BoolLiteral.new(true), body)

         when :else, :elsif, :elif
            dbg "- parse_tplmacro_control - else, elsif, elif"
            return nil
         end
      end

      @in_macro_expression = true
      exps = parse_expressions
      @in_macro_expression = false

      MacroExpression.new(exps, output: false)
   ensure
      dbgtail "/parse_tplmacro_control".red
   end

   def parse_tplmacro_if(start_line, start_column, macro_state, check_end = true)
      next_token_skip_space

      macro_if_indent = @indent

      @in_macro_expression = true
      cond = parse_op_assign
      @in_macro_expression = false

      if @token.type != MACRO_CTRL_END_DELIMITER && check_end
         an_if = parse_if_after_condition If, macro_if_indent, cond #, true
         return MacroExpression.new(an_if, output: false)
      end

      check MACRO_CTRL_END_DELIMITER

      a_then, end_location = parse_tplmacro_body(start_line, start_column, macro_state)

      dbg "- parse_tplmacro_if - after then-macro-body"

      if @token.type == :END
         if check_end
            next_token_skip_space
            check MACRO_CTRL_END_DELIMITER
         end
      elsif @token.type == :IDFR
         case @token.value
         when :else
            next_token_skip_space
            check MACRO_CTRL_END_DELIMITER

            a_else, end_location = parse_tplmacro_body(start_line, start_column, macro_state)

            if check_end
               check :END
               next_token_skip_space
               check MACRO_CTRL_END_DELIMITER
            end
         when :elsif, :elif
            a_else = parse_tplmacro_if(start_line, start_column, macro_state, false)

            if check_end
               check :END
               next_token_skip_space
               check MACRO_CTRL_END_DELIMITER
            end
         else
            unexpected_token "while parsing macro if"
         end
      else
         unexpected_token "while parsing macro if"
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

      dbg "- parse_expression_inside_macro - after main code".red

      skip_statement_end

      @in_macro_expression = false
      exp
   end

   DefOrMacroCheck1 = [:IDFR, :CONST, :"<<", :"<", :"<=", :"==", :"is", :"!~~", :"!~", :"~~", :"!=", :"isnt", :"=~", :">>", :">", :">=", :"+", :"-", :"*", :"/", :"!", :"not", :".~.", :"%", :".&.", :".|.", :"^", :"**", :"[]", :"[]=", :"<=>", :"[]?"]
   DefOrMacroCheck2 = [:"<<", :"<", :"<=", :"==", :"is", :"!~~", :"!~", :"~~", :"!=", :"isnt", :"=~", :">>", :">", :">=", :"+", :"-", :"*", :"/", :"!", :"not", :".~.", :"%", :".&.", :".|.", :".^.", :"**", :"[]", :"[]?", :"[]=", :"<=>"]

   # *TODO* remove is_abstract - prefix version _when_ it seems like it's fine
   # using only the "abstract-body–notation"
   def parse_def_helper(is_abstract = false, is_macro_def = false)
      push_fresh_scope
      @doc_enabled = false
      @def_nest += 1

      def_indent = @indent

      # *TODO* remove!!!
      if (v = @token.value).is_a?(Symbol) && kwd?(:fn, :fu, :mf, :def, :fun, :own)
         dbg "got explicit fun-keyword prefix: #{v}"
         literal_prefix_style = v
         next_token_skip_space
      end

      maybe_mutate_gt_op_to_bigger_op

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
         skip_statement_end
         check DefOrMacroCheck1
      end

      receiver = nil
      @yields = nil
      name_line_number = @token.line_number
      name_column_number = @token.column_number
      receiver_location = @token.location
      end_location = token_end_location

      if @token.type == :CONST
         receiver = parse_constish

      elsif @token.type == :IDFR
         name = @token.value.to_s
         # name_literal_style = @token.literal_style
         next_token
         if tok?(:"=")
            name = "#{name}="
            next_token_skip_space
         else
            skip_space
         end
      else
         name = @token.type.to_s
         next_token_skip_space
      end


      if foreign = $babelfish_func_dict[@token.value.to_s]?
         dbg "Got foreign name '#{foreign}' for function #{@token.value}".magenta
         name = foreign
      end

      # #
      # # DEFFED FUNCTION NAME PRE–MANGLING!
      # # *TODO* error message column is fucked up! Points to first param!!!
      # case name
      # when "init" # Onyx uses "init", but promotes it to "initialize" for Crystal compatibility
      #    name = "initialize"

      # when "~~"
      #    name = "==="

      # when "initialize"
      #    dbgtail_off!
      #    raise "initialize is a reserved internal method name. Use 'init' for constructor code.", name_line_number, name_column_number
      # end

      # #
      # #

      marked_visibility =  if tok? :"*"
                              next_token
                              Visibility::Protected
                           elsif tok? :"**"
                              next_token
                              Visibility::Private
                           else
                              Visibility::Public
                           end

      if tok?(:".")
         unless receiver
            if name
               receiver = Var.new(name).at(receiver_location)
            else
               dbgtail_off!
               raise "shouldn't reach this line"
            end
         end
         next_token_skip_space

         if @token.type == :IDFR
            name = @token.value.to_s
            name_column_number = @token.column_number
            next_token
            if tok?(:"=")
               name = "#{name}="
               next_token_skip_space
            else
               skip_space
            end
         else
            maybe_mutate_gt_op_to_bigger_op
            check DefOrMacroCheck2
            name = @token.type.to_s
            name_column_number = @token.column_number
            next_token_skip_space
         end
      else
         if receiver
            unexpected_token "somewhere in parsing def"
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

      dbg "Got with parens arg_list"
      next_token_skip_space_or_newline

      while @token.type != :")"
         dbg "!=)"

         extras = parse_param(arg_list, extra_assigns, true, found_default_value, found_splat)

         if !found_default_value && extras.default_value
            found_default_value = true
         end
         if !splat_index && extras.splat
            splat_index = index
            found_splat = true
         end
         if explicit_block_param = extras.explicit_block_param
            compute_explicit_block_param_yields explicit_block_param
            check :")"
            break
         elsif tok?(:",") || tok?(:";") || @token.type == :"NEWLINE"
            next_token_skip_space_or_newline
         else
            skip_statement_end
            if @token.type != :")"
               unexpected_token "expected ',' or ')'"
            end
         end
         index += 1
      end
      next_token_skip_space
      # when :";", :"NEWLINE"
      #    # Skip
      # when :":"
      #    # Skip
      # when :"&"
      #    next_token_skip_space_or_newline
      #    explicit_block_param = parse_explicitly_declared_block_param(extra_assigns)
      #    compute_explicit_block_param_yields explicit_block_param
      # else
      #    if is_abstract && @token.type == :EOF   # for prefixed `abstract`, the suffix–vers is below
      #       # OK
      #    else
      #       unexpected_token "while parsing def"
      #    end
      # end

      dbg "before is_macro_def"

      if is_macro_def
         check :":", "before is_macro_def"
         next_token_skip_space
         return_type = parse_single_type
         end_location = return_type.end_location

         if is_abstract   # for prefixed `abstract`, the suffix–vers is below
            body = Nop.new
         else
            # if kwd?("end")   # *TODO*
            if is_explicit_end_tok? # *TODO* all kinds of endings

               body = Expressions.new
               next_token_skip_space
            else
               body, end_location = parse_tplmacro_body(name_line_number, name_column_number)
            end
         end
      else
         # The part below should be cleaned up


         # *todo* depending on style!! token or arrow
         #
         # fn my–func(a, b Int) -> do–shit
         # fn my–func(a, b Int) Foo -> do–shit
         # fn my–func(a, b Int) \n
         # fn my–func(a, b Int) Foo
         # fn my–func(a, b Int)! -> do–shit
         # fn my–func(a, b Int)! \n
         # my–func(a, b Int) -> do–shit
         # my–func(a, b Int) ->! do–shit
         # my–func(a, b Int) Foo -> do–shit
         # my–func(a, b Int) -> \n


         if @token.type != :"->"
            dbg "No ->, type?"
            # next_token_skip_space
            if @token.type != :"NEWLINE" # *TODO* we don't accept newline here
               dbg "Tries TYPE PARSE"
               return_type = parse_single_type
               end_location = return_type.end_location
            else
               dbg "GOT NEWLINE"
               return_type = nil
            end
            dbg "tok:" + @token.to_s

            if @token.type != :"->" # this is checked in parse_nest_start too!!
               unexpected_token "expected '->' or return type"
            end
            dbg "Got ->"
            # Done with header..

         else
            dbg "Got -> - so no return type given"
         end

         end_location = token_end_location

         @certain_def_count += 1

         dbg "body time"

         nest_kind, callable_kind, returns_nothing, suffix_pragmas = parse_def_nest_start
         # *TODO* use callable_kind and set on Def–node
         # *TODO* use add_def_nest!
         add_nest (is_macro_def ? :macro : :def), def_indent, name.to_s, (nest_kind == :LINE_NEST), false

         pragmas = [] of ASTNode
         pragmas.concat suffix_pragmas

         dbg "found pragmas for def: #{pragmas}"



         if returns_nothing
            if return_type
               # *NOTE* wrong position on error message!
               dbgtail_off!
               raise "Callable declared with both return type and \"returns nothing\" notation. Which is it?", end_location
            else
               return_type = Path.global("Nil") # *TODO* Nothing / Void if it gets introduced
            end
         end

         if nest_kind == :NIL_NEST
            dbg "got nil block"

            if extra_assigns
               body = Expressions.from(extra_assigns)
            else
               body = Nop.new
            end

            handle_nest_end true

         elsif is_abstract   # for prefixed `abstract`, the suffix–vers is below
            # *TODO* remove! this is foul
            dbg "is_abstract - sets nil block"
            dbgtail_off!
            raise "remove prefix abstract! deprecated"
            body = Nop.new
            handle_nest_end true

         else
            dbg "got a body"

            # parse possible "first of body" pragmas
            if pragmas? # tok? :PRAGMA
               dbg "got body primary pragmas"
               pragmas = parse_pragma_cluster
               # *TODO* use the pragmas
               if handle_nest_end false
                  body = Nop.new
               end
            end

            slash_is_regex!
            # dbg "before skip_statement_end"
            # skip_statement_end
            # dbg "after skip_statement_end"

            end_location = token_end_location

            if body
               # nothing to do

            elsif kwd? :abstract   # if the only thing in the body is "abstract"... you get it!
               next_token_skip_space
               dbg "Got astract keyword as 'body'"
               is_abstract = true
               body = Nop.new

               if ! handle_nest_end true
                  dbgtail_off!
                  raise "unexpected token \"#{@token}\". Expected def to be done after 'abstract' keyword.", @token.location
               end

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
         @certain_def_count -= 1    # *TODO* replace with throwing DefSyntaxException
      end

      if returns_nothing
         if body.is_a? Expressions # *TODO* should be `nop` - or nothing at all if Nothing/Void gets introduced
            dbg "It's a returns_nothing callable and body.last == #{body.last}"

            if body.last && body.last.is_a? NilLiteral
               dbg "Already got a 'nil'"
            else
               dbg "it's not 'nil'"
               body.expressions.push NilLiteral.new
            end

         elsif body.is_a? NilLiteral
            # do nothing

         elsif body.is_a? ASTNode
            body = Expressions.from [body, NilLiteral.new]
         end
      else
         dbg "returns_nothing == #{returns_nothing}, typeof(body) == #{typeof(body)}, #{body.class}, of Expressions? == #{body.is_a? Expressions}"
      end

      @def_nest -= 1
      @doc_enabled = @wants_doc
      pop_scope

      node = Def.new name, arg_list, body, receiver, explicit_block_param, return_type, is_macro_def, @yields, is_abstract, splat_index
      node.name_column_number = name_column_number
      node.visibility = marked_visibility # @visibility
      node.end_location = end_location

      # dbg "set node.literal_style to #{name_literal_style}"
      # node.literal_style = name_literal_style
      # node.literal_prefix_keyword = literal_prefix_style || :none

      dbg "parse_def_helper done"
      node
   end

   def compute_explicit_block_param_yields(explicit_block_param)
      explicit_block_param_restriction = explicit_block_param.restriction
      if explicit_block_param_restriction.is_a?(Fun)
         @yields = explicit_block_param_restriction.inputs.try(&.size) || 0
      else
         @yields = 0
      end
   end

   record ArgExtras, explicit_block_param, default_value, splat

   def parse_param(arg_list, extra_assigns, parenthesis, found_default_value, found_splat, allow_restrictions = true)
      if @token.type == :"&"
         dbg "found '&' - exlicitly declared block-parameter?"
         next_token_skip_space_or_newline
         explicit_block_param = parse_explicitly_declared_block_param(extra_assigns)
         return ArgExtras.new(explicit_block_param, false, false)
      end

      splat = false
      if @token.type == :"..."
         if found_splat
            # *TODO* Should say that it's a duplicate splat!
            unexpected_token "duplicate splat while parsing args?"
         end

         splat = true
         next_token_skip_space
      end

      arg_location = @token.location
      arg_name, uses_arg = parse_param_name(arg_location, extra_assigns)

      if arg_list.any? &.name == arg_name
         dbgtail_off!
         raise "duplicated argument name: #{arg_name}", @token
      end

      default_value = nil
      restriction = nil

      if parenthesis
         next_token_skip_space_or_newline
      else
         next_token_skip_space
      end

      if tok? :":"
         dbg "\nWARNING!".red + " `:` after param-name - did you mean to annotate type? Ditch the colon!\n".yellow
      end



      # *TODO* this needs to go more places!!!

      if (allow_restrictions &&
            !tok?(:"=", :",", :";", :"<", :")")
            )
         # next_token_skip_space_or_newline
         location = @token.location
         mutability, storage, type = parse_qualifer_and_type()
         dbg "type parts: #{mutability}, #{storage}, #{type}"
         restriction = type

      else
         mutability = :auto
      end

      unless splat
         if @token.type == :"="
            if found_splat
               unexpected_token "because we found a splat earlier - default params don't work out after"
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
               dbgtail_off!
               raise "argument must have a default value", arg_location
            end
         end
      end

      raise "Bug: arg_name is nil" unless arg_name

      arg = Arg.new(arg_name, default_value, restriction, mutability: mutability).at(arg_location)
      arg_list << arg
      add_var arg

      ArgExtras.new(nil, !!default_value, splat)
   end

   def parse_explicitly_declared_block_param(extra_assigns)
      name_location = @token.location
      arg_name, uses_arg = parse_param_name(name_location, extra_assigns)
      @uses_explicit_block_param = true if uses_arg

      next_token_skip_space_or_newline

      inputs = nil
      output = nil

      location = @token.location

      if tok? :"("
         next_token_skip_space_or_newline
         type_spec = parse_type_lambdatype_or_sumtype location, false # parse_single_type   # *TODO* parse_type or parse_qualifer_and_type (!)

      else
         type_spec = Fun.new
      end

      #explicit_block_param = BlockArg.new(arg_name, type_spec).at(name_location)
      explicit_block_param = Arg.new(arg_name, restriction: type_spec).at(name_location)

      add_var explicit_block_param

      @explicit_block_param_name = explicit_block_param.name

      explicit_block_param
   end

   def parse_param_name(location, extra_assigns)
      # *TODO* also consider symbol style (#name) for
      # named fields here in def too

      case @token.type
      when :UNDERSCORE
         arg_name = "_tmp_par_#{@anon_param_counter}"
         @anon_param_counter += 1
         uses_arg = false

      when :IDFR
         arg_name = @token.value.to_s
         uses_arg = false
      when :INSTANCE_VAR
         arg_name = @token.value.to_s[1..-1]
         ivar = InstanceVar.new(@token.value.to_s).at(location)
         var = Var.new(arg_name).at(location)
         assign = Assign.new(ivar, var).at(location)
         if extra_assigns
            extra_assigns.push assign
         else
            dbgtail_off!
            raise "can't use @instance_variable here"
         end
         add_instance_var ivar.name
         uses_arg = true
      when :CLASS_VAR
         arg_name = @token.value.to_s[2..-1]
         cvar = ClassVar.new(@token.value.to_s).at(location)
         var = Var.new(arg_name).at(location)
         assign = Assign.new(cvar, var).at(location)
         if extra_assigns
            extra_assigns.push assign
         else
            dbgtail_off!
            raise "can't use @@class_var here"
         end
         uses_arg = true
      else
         dbgtail_off!
         raise "unexpected token: #{@token}"
      end

      {arg_name, uses_arg}
   end

   def parse_if #(check_end = true)
      dbg "parse_if"
      # dbginc
      if_indent = @indent
      slash_is_regex!
      next_token_skip_space_or_newline

      if kwd? :likely, :unlikely
         dbg "\n\nGot likely/unlikely keyword in if-expression! GHOST IMPLEMENTATION ATM. NO IR-GENERATION!\n\n".red
         next_token_skip_space_or_newline
      end

      dbg "parse_if condition"
      @control_construct_parsing += 1  # for "indent is call" syntax excemption
      cond = parse_op_assign_no_control allow_suffix: false
      @control_construct_parsing -= 1
      dbg "parse_if code block"
      parse_if_after_condition If, if_indent, cond #, check_end
   ensure
      # dbgdec
   end

   def parse_if_after_condition(klass, initial_indent, cond) #, check_end)
      dbg "parse_if_after_condition ->"
      slash_is_regex!

      # skip_statement_end

      # "then" || "=>" || "\n"+:INDENT
      nest_kind, dedent_level = parse_nest_start :if, initial_indent
      add_nest :if, dedent_level, "", (nest_kind == :LINE_NEST), false

      if nest_kind == :NIL_NEST
         dbg "parse_if_after_condition: was nilblock"
         a_then = nil # NilLiteral.new    ?
         handle_nest_end true
      else
         dbg "parse_if_after_condition: parse then block"
         a_then = parse_expressions
         dbg "parse_if_after_condition: after then-block - before skip_statement_end, @one_line_nest = " + @one_line_nest.to_s
         skip_statement_end
         dbg "parse_if_after_condition: after skip_statement_end"
      end

      dbg "TIME FOR ELSE".white

      a_else = nil
      if tok?(:IDFR) || (nest_kind == :TERNARY && tok?(:":"))
         dbg "parse_if_after_condition: idfr - is it else or elsif?"

         if kwd?(:else) || tok?(:":")
            dbg "parse_if_after_condition: was else"
            # next_token_skip_statement_end
            else_indent = @indent
            next_token_skip_space

            nest_kind, dedent_level = parse_nest_start :else, else_indent
            add_nest :if, dedent_level, "", (nest_kind == :LINE_NEST), false # *TODO* -> :else   - we use :if now for :end–if matching...

            if nest_kind == :NIL_NEST
               a_else = nil # NilLiteral.new    ?
               handle_nest_end true
            else
               a_else = parse_expressions
            end

         elsif kwd? :elsif, :elif
            dbg "parse_if_after_condition: was elsif"
            a_else = parse_if #check_end: false
         end
      end

      end_location = token_end_location

      klass.new(cond, a_then, a_else).at_end(end_location)
   end

   def parse_unless
      dbg "parse_unless"

      if_indent = @indent
      slash_is_regex!
      next_token_skip_space_or_newline

      if kwd? :likely, :unlikely
         dbg "\n\nGot likely/unlikely keyword in if-expression! GHOST IMPLEMENTATION ATM. NO IR-GENERATION!\n\n".red
         next_token_skip_space_or_newline
      end

      dbg "parse_if condition"
      cond = parse_op_assign_no_control allow_suffix: false
      dbg "parse_if code block"
      parse_if_after_condition Unless, if_indent, cond #, check_end

   end

   def parse_ifdef(mode = :normal)
      dbg "parse_ifdef"
      next_token_skip_space_or_newline

      # *TODO* add_nest/pop_nest!? YES! BUT NOT SCOPE!

      ifdef_indent = @indent
      cond = parse_flags_or

      # skip_statement_end
      nest_kind, dedent_level = parse_nest_start(:if, ifdef_indent)
      if nest_kind == :NIL_NEST
         dbgtail_off!
         raise "expected a body for the `ifdef` statement"
      end

      add_nest :ifdef, dedent_level, "", (nest_kind == :LINE_NEST), false
      a_then = parse_ifdef_body(mode)

      # *9*
      # *TODO* else / continuation parsing MUST MATCH PREVIOUS INDENT - ELSE
      # IT'S A LOWER CONSTRUCTION!!!!

      a_else = nil

      if @token.type == :IDFR
         case @token.value
         when :else

            # *TODO* verify shouldn't happen!
            if @indent != ifdef_indent
               dbgtail_off!
               raise "internal muddafuckin error in ifdef: ifdef and else doesn't match in indent level"
            end

            next_token_skip_space


            # *TODO*
            nest_kind, dedent_level = parse_nest_start(:else, ifdef_indent)

            if nest_kind == :NIL_NEST
               dbgtail_off!
               raise "expected a body for the `ifdef else` statement"
            end

            add_nest :ifdef, dedent_level, "", (nest_kind == :LINE_NEST), false
            a_else = parse_ifdef_body(mode)

         when :elsif, :elif
            a_else = parse_ifdef mode: mode
         end
      end

      end_location = token_end_location

      IfDef.new(cond, a_then, a_else).at_end(end_location)
   end

   # *TODO* *9* - this is wrong!
   def parse_ifdef_body(mode)
      case mode
      when :lib
         parse_lib_body
      when :struct_or_union
         parse_struct_or_union_body
      when :TYPE_DEF, :ENUM_DEF, :TRAIT_DEF
         parse_type_def_body mode
      else
         parse_expressions
      end
   end

   parse_operator :flags_or, :flags_and, "Or.new left, right", ":\"||\", :\"or\""
   parse_operator :flags_and, :flags_atomic, "And.new left, right", ":\"&&\", :\"and\""

   def parse_flags_atomic
      dbg "parse_flags_atomic #{@token.type}, #{@token.value}"

      case @token.type
      when :"("
         next_token_skip_space
         if @token.type == :")"
            dbgtail_off!
            raise "unexpected token: #{@token}"
         end

         atomic = parse_flags_or
         skip_space

         check :")"
         next_token_skip_space

         atomic

      when :"!", :not
         next_token_skip_space
         Not.new(parse_flags_atomic)

      when :IDFR, :CONST
         str = @token.to_s
         next_token_skip_space
         Var.new(str)
      else
         dbgtail_off!
         raise "unexpected token: #{@token}"
      end
   end

   # def set_visibility(node)
   #    if visibility = @visibility
   #       node.visibility = visibility
   #    end
   #    node
   # end



   #                  ######       ###      ##             ##               #####
   #             ##      ##       ## ##       ##             ##          ##      ##
   #             ##            ##       ##      ##             ##          ##
   #             ##             ##       ## ##             ##             #####
   #             ##             ######### ##             ##                   ##
   #             ##      ## ##       ## ##             ##             ##    ##
   #                  ######      ##       ## ######## ########    ######

   def parse_var_or_call(global = false, force_call = false)
      dbg "parse_var_or_call(#{global}, #{force_call})"

      location = @token.location
      end_location = token_end_location
      doc = @token.doc
      curr_indent = @indent

      if foreign = $babelfish_func_dict[@token.value.to_s]?
         dbg "Got foreign '#{foreign}' for function #{@token.value}".magenta
         token.value = foreign
      end

      if token.value == "of?"
         obj = Var.new("self").at(location)
         return parse_is_a(obj)

      elsif @token.value == :responds_to?
         obj = Var.new("self").at(location)
         return parse_responds_to(obj)
      end

      name = @token.value.to_s
      name_column_number = @token.column_number
      # name_literal_style = @token.literal_style

      if force_call && !@token.value
         name = @token.type.to_s
      end

      is_var = is_var?(name)

      dbg "identifier `#{name}`, is_var == #{is_var}" # , literal_style = #{name_literal_style}"

      # *TODO* add support for implicitly numbered magic params too!

      if name[0] == '_' && name.size == 2 && name[1] >= '0' && name[1] <= '9'    # magic param?
         is_var = true
         #name = "tmp_par" + name
         if in_auto_paramed?
            add_magic_param name
         else
            dbgtail_off!
            raise "The identifier \"#{name}\" is reserved for auto-magic parametrization of blocks (used via `~>`/`\\`)", location
         end
      end

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

      when "init" # Onyx uses "init", but promotes it to "initialize" for Crystal compatibility
         @calls_initialize = true
         name = "initialize"

      when "initialize"
         dbgtail_off!
         raise "initialize is a reserved internal method name. Use 'init' for 'constructor'-code."
      end



      # *TODO*
      # *TODO*
      # if any of these muddafuckas   :"'", :"~", :"^" or curch is any of them
      #    we got a typing situation on our hands

      #    then we need to be prepared for assign also
      # else
      #    parse args and that

      @temp_temp__curr_namish = name # *TODO* remove after test!

      has_parens, call_args = parse_call_args true, curr_indent

      instance = nil

      if call_args
         args = call_args.args
         block = call_args.block
         explicit_block_param = call_args.explicit_block_param
         named_args = call_args.named_args

         # check if functor–ish
         if is_var
            instance = Var.new(name)
            name = "call"
         end
      end

      node =
         if block || explicit_block_param || global
            dbg "parse_var_or_call - got some kinda block"
            Call.new instance, name, (args || [] of ASTNode), block, explicit_block_param, named_args, global, name_column_number, has_parenthesis: has_parens
         else
            if args
               dbg "parse_var_or_call - got some kinda args"
               if (!force_call && is_var) && args.size == 1 && (num = args[0]) && (num.is_a?(NumberLiteral) && num.has_sign?)
                  sign = num.value[0].to_s
                  num.value = num.value.byte_slice(1)
                  Call.new(Var.new(name), sign, args, has_parenthesis: has_parens)
               else
                  Call.new(instance, name, args, nil, explicit_block_param, named_args, global, name_column_number, has_parenthesis: has_parens)
               end
            else
               dbg "check for type annotation prefixes"
               # *NOTE* if ':' is wished to be used for this - either block-: or something else has to be ditched
               if tok? :"'", :"~", :"^"
                  dbg "got var declare type prefix for var_or_call".yellow
                  # next_token_skip_space_or_newline
                  # declared_type = # parse_single_type
                  mutability, storage, declared_type = parse_qualifer_and_type
                  declare_var = TypeDeclaration.new(Var.new(name).at(location), declared_type, mutability: mutability).at(location)
                  add_var declare_var
                  declare_var
               elsif (!force_call && is_var)
                  if @explicit_block_param_name && !@uses_explicit_block_param && name == @explicit_block_param_name
                     @uses_explicit_block_param = true
                  end
                  Var.new name
               else
                  dbg "parse_var_or_call - got call as default else case"
                  Call.new instance, name, [] of ASTNode, nil, explicit_block_param, named_args, global, name_column_number, has_parenthesis: has_parens
               end
            end
         end

      if tok? :"->"
         dbgtail_off!
         #raise "Internal throw: likely func-def - not call!"
         ::raise CallSyntaxException.new("Internal throw: likely func-def - not call!", token.line_number, token.column_number, token.filename, 2)
      end

      node.doc = doc
      node.end_location = block.try(&.end_location) || call_args.try(&.end_location) || end_location
      # node.literal_style = name_literal_style
      node

   ensure
      dbgtail "/parse_var_or_call"
   end

   record CallArgs, args, block, explicit_block_param, named_args, stopped_on_do_after_space, end_location

   def parse_call_args(allow_curly, curr_indent)
      dbg "parse_call_args ->"

      case @token.type

      # *TODO* *verify*! remove ka? ( `foo{...` )
      when :"{"
         {false, nil}

      when :"("
         dbg "- parse_call_args -> '('"
         {true, parse_call_args_parenthesized}

      # *TODO* PERHAPS indent should also be allowed!? Looks quite confusing though...
      when :SPACE
         dbg "- parse_call_args -> SPACE"
         slash_is_not_regex!
         end_location = token_end_location
         next_token
         {false, parse_call_args_spaced check_plus_and_minus: true, allow_curly: allow_curly}

      when :INDENT
         return {false, nil} if @control_construct_parsing != 0

         dbg "- parse_call_args -> INDENT"
         end_location = token_end_location
         next_token
         {true, parse_call_args_indented curr_indent, check_plus_and_minus: true, allow_curly: allow_curly}

      else
         {false, nil}
      end

   ensure
      dbgtail "/parse_call_args"
   end

   def looks_like_named_arg?
      tok?(:IDFR) &&
         parser_peek_non_ws_char == ':' &&
         parser_peek_non_ws_char(2) == ' ' # if no space after, it's string–property–indexing!
   end

   def parse_call_args_parenthesized
      dbg "parse_call_args_parenthesized"
      slash_is_regex!

      args = [] of ASTNode
      end_location = nil
      block = nil
      named_args = nil

      open("call") do
         next_token_skip_space_or_newline

         while tok? :INDENT, :DEDENT, :NEWLINE
            next_token_skip_space
         end

         while @token.type != :")"
            if looks_like_named_arg?
               named_args = parse_named_args(allow_newline: true)
            end

            if @token.type != :")"
               arg = parse_call_arg

               if arg.is_a? Block
                  block = arg
                  dbg "parse_call_args_parenthesized after block arg - check for ')'"

               elsif named_args
                  dbg "named_args: #{named_args}, arg: #{arg}, #{arg.class}, args: #{args}"
                  dbgtail_off!
                  raise "sorry, regular arguments after named arguments doesn't work out"

               else
                  args << arg
               end
            end
            # skip_statement_end

            if @token.type == :","
               dbg "got ',' skips space + newline as continuation"
               scan_next_as_continuation
               slash_is_regex!
               next_token_skip_space_or_newline

            else
               dbg "- parse_call_args_parenthesized - found non ',' in loop - check for ')'"
               check_closing_paren
               break
            end
         end

         dbg "- parse_call_args_parenthesized - after 'while' - do next_token_skip_space"
         end_location = token_end_location
         next_token_skip_space

      end

      CallArgs.new args, block, nil, named_args, false, end_location
   end

   def parse_call_args_spaced(block = nil, check_plus_and_minus = true, allow_curly = false)
      dbg "parse_call_args_spaced ->"
      return nil if parse_call_args_spaced_any_non_call_hints?(check_plus_and_minus, allow_curly)
      args = [] of ASTNode
      end_location = nil

      dbg "- parse_call_args_spaced - starts while loop"

      until tok?(:NEWLINE, :";", :EOF, :")") || end_token?
         dbg "- parse_call_args_spaced - TOP of WHILE"

         if looks_like_named_arg?
            named_args = parse_named_args(allow_newline: true)
         end

         dbg "- parse_call_args_spaced - AFTER parse_named_args: #{named_args}"

         unless nest_start_token? || tok?(:NEWLINE, :";", :EOF, :")") || end_token?
            arg = parse_call_arg

            if arg.is_a? Block
               block = arg
               dbg "parse_call_args_spaced after block arg - check for ')'"

            elsif named_args
               dbg "named_args: #{named_args}, arg: #{arg}, #{arg.class}, args: #{args}"
               dbgtail_off!
               raise "sorry, regular arguments after named arguments doesn't work out"

            else
               args << arg
            end
         end

         end_location = token_end_location
         skip_space

         if @token.type == :","
            dbg "got ',' skips space + newline as continuation"
            scan_next_as_continuation
            slash_is_regex!
            next_token_skip_space_or_newline

         else
            dbg "- parse_call_args_spaced - found non ',' in loop - check for ')'"
            break
         end
      end

      dbg "- parse_call_args_spaced - after 'while' - do next_token_skip_space"

      CallArgs.new args, block, nil, named_args, false, end_location

   ensure
      dbgtail "/parse_call_args_spaced"
   end

   def parse_call_args_spaced_any_non_call_hints?(check_plus_and_minus, allow_curly)
      dbg "parse_call_args_spaced_any_non_call_hints? ->"
      if kwd?(:as) || tok?(:END) # *TODO* end–tok? check instead - old code
         return true
      end

      dbg "- parse_call_args_spaced_any_non_call_hints? - check token.type"

      case @token.type
      when :CHAR, :STRING, :DELIMITER_START, :STRING_ARRAY_START,
            :TAG_ARRAY_START, :NUMBER, :IDFR, :TAG, :INSTANCE_VAR,
            :CLASS_VAR, :CONST, :GLOBAL, :"$", :"$~", :"$?", :GLOBAL_MATCH_DATA_INDEX,
            :REGEX, :"(", :"!", :not, :"[", :"[]", :".~.", :"&", :"->",
            :"{{", :__LINE__, :__FILE__, :__DIR__, :UNDERSCORE,   :"~>", :"~.", :"\\", :"\\."
            # *TODO* these conflicts with when below (which normally has precedance - both routes can never take:   :"+", :"-",
         dbg "- parse_call_args_spaced_any_non_call_hints? - one of the WANTED token.types "
         # Nothing - because these are the ones we WANT to handle

      when :"&"
         dbg "- parse_call_args_spaced_any_non_call_hints? - token.type '&'"
         return true if current_char.whitespace?

      when :"+", :"-"
         dbg "- parse_call_args_spaced_any_non_call_hints? - token.type '+/-' - current_char == '#{current_char}'"
         return true if check_plus_and_minus && current_char.whitespace?

      when :"{"
         dbg "- parse_call_args_spaced_any_non_call_hints? - token.type '{'"
         return true unless allow_curly # *TODO* *9* search allow_curly

      # *TODO* free the operators again, check for type–ish after?
      # Though... they should never occur here without idfr before! *9*
      when :"'", :"~", :"^"
         dbg "- parse_call_args_spaced_any_non_call_hints? - type annotation prefix '#{@token.type}'"
         return true

      when :"*", :"..." # *TODO* verify - was :"*" - so it doesn't clash with `range–til`
         dbg "- parse_call_args_spaced_any_non_call_hints? - token.type '*' or '...'"
         return true if current_char.whitespace?

      when :"<"
         dbg "- parse_call_args_spaced_any_non_call_hints? - token.type '<' check if it's a tuple or it's the operator"
         return surrounded_by_space? # test_parse parse_tuple

      else
         dbg "- parse_call_args_spaced_any_non_call_hints? - token.type OTHER - return true".red
         return true
      end

      # *TODO* this fails when using `if x ? y : z`, since below assumes suffix if!
      # can be worked around by user with paren–call, but...
      case @token.value
      when :if, :unless, :while, :until, :rescue, :ensure, :do, :then
         dbg "returns since if|unless|..."
         return true

      when :yield
         dbg "returns since yield"
         return true if @stop_on_yield > 0
      end

      false
   end

   def parse_call_args_indented(indent_level, block = nil, check_plus_and_minus = true, allow_curly = false)
      dbg "parse_call_args_indented ->"
      return nil if parse_call_args_spaced_any_non_call_hints?(check_plus_and_minus, allow_curly)

      call_indent_level = indent_level # @indent
      da_name_muddafuckas = @temp_temp__curr_namish.to_s

      dbg_prev_nest_is = @nesting_stack.last

      add_nest :indent_call, call_indent_level, da_name_muddafuckas, false, false

      args = [] of ASTNode
      end_location = nil

      dbg "- parse_call_args_indented - starts while loop"

      while true # until (got_dedent = handle_nest_end) # tok?(:DEDENT, :";", :EOF, :")") || end_token?
         dbg "- parse_call_args_indented - TOP of WHILE"

         if looks_like_named_arg?
            named_args = parse_named_args(allow_newline: true)
         end

         dbg "- parse_call_args_indented - AFTER parse_named_args: #{named_args}"

         if !tok?(:DEDENT) # , :";", :EOF, :")") || end_token?
            arg = parse_call_arg

            if arg.is_a? Block
               block = arg
               dbg "parse_call_args_indented after block arg - check for ')'"

            elsif named_args
               dbg "named_args: #{named_args}, arg: #{arg}, #{arg.class}, args: #{args}"
               dbgtail_off!
               raise "sorry, regular arguments after named arguments doesn't work out"

            else
               args << arg
            end
         end

         end_location = token_end_location
         skip_space

         if handle_nest_end
            dbg "- parse_call_args_indented - handled active dedent for '#{da_name_muddafuckas}'!!!".red
            break

         elsif tok?(:",", :NEWLINE) || tok?(:DEDENT) || @indent > call_indent_level
            dbg "- parse_call_args_indented - got ','|'\\n'|DEDENT - go for next arg".red

            # scan_next_as_continuation
            slash_is_regex!

            skip_tokens :SPACE, :NEWLINE, :DEDENT, :","

         else
            dbg "- parse_call_args_indented - seems we're done collecting args for '#{da_name_muddafuckas}'!".red
            break
         end
      end

      dbg "- parse_call_args_indented - after 'while' - do next_token_skip_space".red

      if dbg_prev_nest_is != @nesting_stack.last
         raise "dbg_prev_nest_is != @nesting_stack.last doesn't match - de-nest missed for #{da_name_muddafuckas}!"
      end

      CallArgs.new args, block, nil, named_args, false, end_location

   ensure
      dbgtail "/parse_call_args_indented"
   end


   def parse_named_args(allow_newline = false)
      named_args = [] of NamedArgument
      dbg "parse_named_args ->"

      loop do
         location = @token.location
         name = @token.value.to_s

         if named_args.any? { |arg| arg.name == name }
            raise "hey, you used the same named argument again: #{name}", @token
         end

         next_token_skip_space

         dbg "- parse_named_args - we have named-arg, check for `= value`"

         check :":", "parse_named_args"

         # *TODO* default valued and named args should be separated

         next_token_skip_space_or_newline

         dbg "- parse_named_args - parse the value"

         value = parse_op_assign

         dbg "- parse_named_args - after parse_op_assign"

         named_args << NamedArgument.new(name, value).at(location)

         dbg "- parse_named_args - allow_newline == #{allow_newline}"
         # *TODO* *WTF*?
         # skip_statement_end if allow_newline

         if @token.type == :","
            dbg "- parse_named_args - got comma"

            next_token_skip_space_or_newline
            if tok? :")", :"&", :"~>", :"~.", :"\\", :"\\.", :"("
               dbg "- parse_named_args - got ender"
               break
            end
         else
            break
         end
      end

      named_args

   ensure
      dbgtail "/parse_named_args"
   end

   def parse_call_arg
      if kwd?(:out)
         parse_out
      else
         splat = false
         if @token.type == :"..."
            unless current_char.whitespace? # *TODO* really? not necessary, but good form
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
      when :IDFR
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




   #       ########   ##         #####       ######   ##   ##    ######
   #       ##      ##   ##       ##    ##      ##   ## ##    ##   ##   ##
   #       ##       ## ##       ##    ##    ##         #   ##    ##
   #       ########   ##       ##    ##    ##         ####      #####
   #       ##       ##   ##       ##    ##      ##       ##   ##       ##
   #       ##         ## ##       ##    ##      ##   ## ##    ##    #   ##
   #       ########    ########   #######    ######   ##   ##   ######

   def oneletter_softlambda_follows?
      @token.type == :"~." # && !current_char.whitespace?
   end

   # def parse_oneletter_softlambda_for_args(args, check_paren, named_args = nil)
   #    location = @token.location

   #    # Always the dot–version atm!
   #    # if @token.type == :"."
   #       block = parse_oneletter_softlambda
   #    # atm. we can't handle this because '~' will be handle as the operator then. so we might have to either use '.~.' for operator (again!) or change the notation for one–char-softlambda
   #    # else
   #    #    explicit_block_param = parse_op_assign - carried out with `&block_name` *TODO* revisit this
   #    # end

   #    end_location = token_end_location

   #    if check_paren
   #       check_closing_paren
   #       next_token_skip_space
   #    else
   #       skip_space
   #    end

   #    explicit_block_param = nil
   #    CallArgs.new args, block, explicit_block_param, named_args, false, end_location
   # end

   def parse_oneletter_softlambda()
      # next_token_skip_space # the dot is part of the composite token

      explicit_block_param_name = "__arg#{@explicit_block_param_count}"
      @explicit_block_param_count += 1

      obj = Var.new(explicit_block_param_name)
      @wants_regex = false
      next_token_skip_space

      location = @token.location

      if @token.value == "is_a?" || @token.value == "of?" # :is_a?
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
               check_closing_paren
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

      Block.new([Var.new(explicit_block_param_name)], call).at(location)
   end

   def add_magic_param(name)
      dbg "add_magic_param #{name}"
      add_var name
      var = Var.new(name).at(@token.location)
      if bp = @nesting_stack.last.block_auto_params
         bp << var
      else
         raise "Internal error: tried to add_magic_param() when par-stack == nil [4953]"
      end
   end

   def in_auto_paramed?
      #ret = @nesting_stack.last.block_auto_params != nil
      ret = @nesting_stack.in_auto_paramed?
      dbg "in_auto_paramed? = #{ret}"
      ret
   end

   #          ######### ##   ## ########   ########    ######
   #               ##      ##   ##   ##    ## ##             ##   ##
   #               ##      ####    ##    ## ##            ##
   #               ##       ##   ########   ######         ######
   #             ##       ##   ##            ##                     ##
   #             ##       ##   ##          ##       ##          ##
   #            ##       ##   ##             ########   ######
   def parse_qualifer_and_type(allow_primitives = false)
      dbg "parse_qualifer_and_type ->"

      mutability = :auto # | :mut | :let
      storage = :auto # | :val | :ref

      if next_is_generic_type_annotator?()
         # Do nothing

      elsif next_is_mut_type_modifier?()
         mutability = :mut

      elsif next_is_immut_type_modifier?()
         mutability = :let
      end

      type = parse_single_type allow_primitives

      dbg "/parse_qualifer_and_type"

      {mutability, storage, type}
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

      if tok?(:"(")
         dbg "is '('"
         next_token_skip_space_or_newline
         return parse_type_lambdatype_or_sumtype(location, allow_primitives) as ASTNode # needed to not muck up inference
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

   def parse_type_lambdatype_or_sumtype(location, allow_primitives)
      dbg "parse_type_lambdatype_or_sumtype"

      # *TODO* rethink the "paren–internalized" syntax. It's not used now.
      if tok?(:"->")
         param_type_list = nil

      elsif tok?(:")")
         # nothing - handled next
      else
         dbg "parse_type_lambdatype_or_sumtype - before parse_type"

         param_type_list = splat parse_type(allow_primitives)
         # param_type_list = splat parse_type_union(allow_primitives)

         dbg "parse_type_lambdatype_or_sumtype - before while ',;'"

         while tok?(:",") || tok?(:";")
            next_token_skip_space_or_newline

            dbg "next param_type_list"

            if tok?(:"->")
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
               # type_union = parse_type_union(allow_primitives)
               type = parse_type(allow_primitives)
               # if type.is_a?(Array)
               #   param_type_list.concat type
               # else
               param_type_list << type
               # end
            end
         end
      end

      lambda_end_paren = false

      dbg "parse_type_lambdatype_or_sumtype - before ')' check"

      if tok? :")"
         lambda_end_paren = true
         next_token_skip_space
      end

      dbg "parse_type_lambdatype_or_sumtype - before '->'? branch"

      if tok? :"->"
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

         if !lambda_end_paren && tok? :")"
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
            # return param_type_list
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
      if const? :Self
         dbg "was 'Self'"
         type = Self.new
         next_token_skip_space

      elsif kwd?(:auto) || tok?(:"*")
         dbg "was 'auto'"
         type = Underscore.new # *TODO* - we want a specific "Auto" node!
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
            if allow_primitives && tok? :NUMBER
               num = new_num_lit(@token.value.to_s, @token.number_kind).at(@token.location)
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
      if kwd?(:typeof, :typedecl) # this is here because type–suffixes can be added
         type = parse_typedecl
      else
         dbg "parse_simple_type, before parse_constish"
         type = parse_constish
         dbg "parse_simple_type, after parse_constish"
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
            #    type = make_pointer_type(type)
            #    next_token_skip_space
            # when :"**"
            #    type = make_pointer_type(make_pointer_type(type))
            #    next_token_skip_space

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
            check_idfr :type  # *TODO* `oftype` | `curtype` | `typenow` (vs `typedecl`/`decltype`) or similar
            type = Metaclass.new(type)
            next_token_skip_space
         else
            break
         end
      end
      type
   end

   def parse_typedecl
      next_token #_skip_space

      if tok? :SPACE
         is_spaced = true
         skip_tokens :SPACE
      elsif tok? :"("
         is_spaced = false
         next_token
         skip_tokens :SPACE
      else
         raise "expected space or `(` after `type-decl`!"
      end

      # *TODO* this must be so extremely unusual that the check is kinda...
      if !is_spaced && tok? :")"
         raise "missing type-decl argument!"
      end

      exps = [] of ASTNode

      end_location = token_end_location

      loop do
         exps << parse_op_assign
         end_location = token_end_location

         if @token.type == :","
            next_token_skip_space_or_newline
         else
            break
         end
      end

      if !is_spaced
         check :")"
         next_token_skip_space
      end

      TypeOf.new(exps).at_end(end_location)
   end

   def next_is_any_type_modifier?
      next_is_generic_type_annotator? ||
      next_is_mut_type_modifier? ||
      next_is_immut_type_modifier?
   end

   def next_is_generic_type_annotator?
      dbg "next_is_generic_type_annotator? ->"

      # is_annotation = @token.type == :IDFR && @token.value == "var"
      is_annotation = @token.type == :"'"
      next_token_skip_space if is_annotation
      is_annotation
   end

   def next_is_mut_type_modifier?
      dbg "next_is_mut_type_modifier? ->"

      is_mut = @token.type == :IDFR && @token.value == "mut"
      is_mut ||= @token.type == :"~"
      next_token_skip_space if is_mut
      is_mut
   end

   def next_is_immut_type_modifier?
      #is_immut = @token.type == :IDFR && @token.value == "const"
      is_immut = @token.type == :IDFR && @token.value == "let"
      is_immut ||= @token.type == :"^"
      next_token_skip_space if is_immut
      is_immut
   end

########   #######   ########   ######## ##   ## ########   ########   ######
##       ##    ## ##          ##    ##   ##   ##    ## ##       ##   ##
##       ##    ## ##          ##      ####    ##    ## ##       ##
######    ##    ## ######       ##       ##   ########   ######   ######
##       ##    ## ##          ##       ##   ##      ##          ##
##       ##    ## ##          ##       ##   ##      ##       ##   ##
########   #######   ##          ##       ##   ##      ########   ######

   def make_pointer_type(node)
      Generic.new(Path.global("Pointer").at(node), [node] of ASTNode).at(node)
   end

   def make_static_array_type(type, size)
      Generic.new(Path.global("StaticArray").at(type), [type, size] of ASTNode).at(type.location).at(type)
   end

   def make_tuple_type(types)
      Generic.new(Path.global("Tuple"), types)
   end

   # def parse_visibility_modifier(modifier)
   #    doc = @token.doc

   #    next_token_skip_space
   #    exp = parse_op_assign

   #    modifier = VisibilityModifier.new(modifier, exp)
   #    modifier.doc = doc
   #    exp.doc = doc
   #    modifier
   # end

   def parse_asm
      next_token_skip_space
      check :"("
      next_token_skip_space_or_newline
      text = parse_string_without_interpolation { "interpolation not allowed in asm" }
      skip_statement_end

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
            check :":", "parse_asm"
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
         skip_statement_end
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
         skip_statement_end
         case option
         when "volatile"
            volatile = true
         when "alignstack"
            alignstack = true
         when "intel"
            intel = true
         else
            raise "unknown asm option: #{option}", location
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
      check_idfr :yield
      parse_yield scope, location
   end

   def parse_yield(scope = nil, location = @token.location)
      end_location = token_end_location
      next_token

      has_parens, call_args = parse_call_args true, -47

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

      has_parens, call_args = parse_call_args true, -47
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
      dbg "parse_lib ->"
      indent_level = @indent
      next_token_skip_space_or_newline

      name = check_const
      name_column_number = @token.column_number
      next_token_skip_space

      nest_kind, dedent_level = parse_nest_start :lib, indent_level
      if nest_kind == :NIL_NEST
         body = Nop.new
      else
         add_nest :lib, dedent_level, "", (nest_kind == :LINE_NEST), false
         body = parse_lib_body
      end

      LibDef.new name, body, name_column_number

   ensure
      dbgtail "/parse_lib"
   end

   def parse_lib_body
      dbg "parse_lib_body ->"
      expressions = [] of ASTNode
      while !handle_nest_end
         skip_statement_end
         #break if end_token?
         expressions << parse_lib_body_exp
      end
      expressions
   ensure
      dbgtail "/parse_lib_body"
   end

   def parse_lib_body_exp
      dbg "parse_lib_body_exp ->"
      location = @token.location
      parse_lib_body_exp_without_location.at(location)

   ensure
      dbgtail "/parse_lib_body_exp"
   end

   def parse_lib_body_exp_without_location
      if pragmas?
         return parse_pragma
      end

      case @token.type

      # when :"@["
      #    parse_attribute

      # when :PRAGMA
      #    parse_pragma

      when :IDFR
         case @token.value
         when :alias
            parse_alias

         when :cfun, :fun
            parse_fun_def

         when :type
            parse_api_type_def

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
            parse_ifdef mode: :lib

         else
            unexpected_token "while parsing identifer-token in lib body expression"
         end

      when :CONST
         idfr = parse_constish
         next_token_skip_space
         check :"="
         next_token_skip_space_or_newline
         value = parse_expression
         skip_statement_end
         Assign.new(idfr, value)

      when :GLOBAL
         location = @token.location
         name = @token.value.to_s[1..-1]
         next_token_skip_space_or_newline
         if @token.type == :"="
            next_token_skip_space
            check IdentOrConst
            real_name = @token.value.to_s
            next_token_skip_space
         end
         check :":", "parse_lib_body_exp_without_location"
         next_token_skip_space_or_newline
         type = parse_single_type

         if 'A' <= name[0] <= 'Z'
            raise "external variables must start with lowercase, use for example `$#{name.underscore} = #{name} : #{type}`", location
         end

         skip_statement_end
         ExternalVar.new(name, type, real_name)

      else
         unexpected_token "while parsing lib body expression"
      end
   end

   IdentOrConst = [:IDFR, :CONST]

   def parse_fun_def(require_body = false)
      dbg "parse_fun_def ->".red

      doc = @token.doc
      indent_level = @indent

      push_fresh_scope if require_body

      next_token_skip_space_or_newline
      name = check_idfr
      next_token_skip_space_or_newline

      if @token.type == :"="
         next_token_skip_space_or_newline
         case @token.type
         when :IDFR, :CONST
            real_name = @token.value.to_s
            next_token_skip_space_or_newline
         when :DELIMITER_START
            real_name = parse_string_without_interpolation { "interpolation not allowed in fun name" }
            skip_space
         else
            unexpected_token "while parsing fun, after `=`"
         end
      else
         real_name = name
      end

      args = [] of Arg
      varargs = false

      raise "expected `(`" if @token.type != :"("
      next_token_skip_space_or_newline

      while @token.type != :")"
         if @token.type == :"..."
            varargs = true
            next_token_skip_space_or_newline
            check :")"
            break
         end

         if @token.type == :IDFR
            arg_name = @token.value.to_s
            arg_location = @token.location

            next_token_skip_space_or_newline
            # check :":", "parse_fun_def"
            # next_token_skip_space_or_newline
            arg_type = parse_single_type
            skip_statement_end

            args << Arg.new(arg_name, nil, arg_type).at(arg_location)

            add_var arg_name if require_body
         else
            arg_types = parse_types
            arg_types.each do |arg_type_2|
               args << Arg.new("", nil, arg_type_2).at(arg_type_2.location)
            end
         end

         if tok? :",", :";"
            next_token_skip_space_or_newline
         end
      end

      next_token_skip_space

      dbg "- parse_fun_def - before return type check".red

      if ! tok? :NEWLINE, :DEDENT, :"->"
      #    next_token_skip_space_or_newline
         return_type = parse_single_type
      end

      if require_body
         nest_kind, callable_kind, returns_nothing, suffix_pragmas =
            parse_def_nest_start

         # *TODO* suffix_pragmas

         add_nest :def, indent_level, name.to_s, (nest_kind == :LINE_NEST), false

         if nest_kind == :NIL_NEST
            body = Nop.new
            handle_nest_end true
         else
            body = parse_expressions
            body, end_location = parse_exception_handler body
         end
      else
         # *TODO* how does this play with subsequent nest_ends?
         skip_statement_end
         body = nil
      end

      pop_scope if require_body

      fun_def = FunDef.new name, args, return_type, varargs, body, real_name
      fun_def.doc = doc
      fun_def

   ensure
      dbgtail "/parse_fun_def".red
   end

   # *TODO* just used by C-Lib now
   def parse_alias
      doc = @token.doc

      next_token_skip_space_or_newline
      name = check_const
      next_token_skip_space_or_newline
      check :"="
      next_token_skip_space_or_newline

      value = parse_single_type
      # end_location = token_end_location

      skip_space

      alias_node = Alias.new(name, value) #.at_end(end_location)
      alias_node.doc = doc
      alias_node
   end

   def parse_pointerof
      next_token_skip_space

      check :"("
      next_token_skip_space_or_newline

      if kwd?(:self)
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

   def parse_api_type_def
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
      indent_level = @indent
      kind = (klass == StructDef ? :struct : :union)

      next_token_skip_space_or_newline
      name = check_const
      next_token_skip_space

      nest_kind, dedent_level = parse_nest_start :struct_or_union, indent_level
      if nest_kind == :NIL_NEST
         #body = Nop.new
         raise "An empty #{kind} doesn't make any sense!"
      else
         add_nest kind, dedent_level, "", (nest_kind == :LINE_NEST), false
         body = parse_struct_or_union_body
      end

      # check :END
      # next_token_skip_space

      klass.new name, Expressions.from(body)
   end

   def parse_struct_or_union_body
      dbg "parse_struct_or_union_body ->"
      exps = [] of ASTNode

      while !handle_nest_end
         skip_space_or_newline
         break if !@token.type == :IDFR

         case @token.value
         when :ifdef
            exps << parse_ifdef(mode: :struct_or_union)

         when :include, :mixin
            if @inside_c_struct
               location = @token.location
               exps << parse_include.at(location)
            else
               parse_struct_or_union_fields exps
            end

         else
            parse_struct_or_union_fields exps
         end
      end

      exps
   ensure
      dbgtail "/parse_struct_or_union_body"
   end

   def parse_struct_or_union_fields(exps)
      dbg "parse_struct_or_union_fields ->"
      args = [Arg.new(@token.value.to_s).at(@token.location)]

      next_token_skip_space_or_newline

      # *TODO* possibly dump this possibility!
      while @token.type == :","
         next_token_skip_space_or_newline
         args << Arg.new(check_idfr).at(@token.location)
         next_token_skip_space_or_newline
      end

      type = parse_single_type

      # skip_statement_end

      args.each do |an_arg|
         an_arg.restriction = type
         exps << an_arg
      end

   ensure
      dbgtail "/parse_struct_or_union_fields"
   end


   def node_and_next_token(node)
      dbg "node_and_next_token"
      node.end_location = token_end_location
      next_token
      dbg "after next_token()"
      node
   end

   def const?(token : Symbol) : Bool
      @token.value == token && @token.type == :CONST
   end

   def const?(*tokens : Symbol) : Bool
      return false if @token.type != :CONST
      v = @token.value
      tokens.any? {|t| v == t }
   end

   def kwd?(token : Symbol) : Bool
      @token.value == token && @token.type == :IDFR
   end

   def kwd?(*tokens : Symbol) : Bool
      return false if @token.type != :IDFR
      return false if ! (@token.value.is_a? Symbol)
      v = @token.value
      tokens.any? {|t| v == t }
   end

   def nest_start_token?
      tok?(:"=>", :":") || kwd?(:do, :then, :begins)
   end

   def end_token? : Bool
      case @token.type
      when :"}", :"]", MACRO_CTRL_END_DELIMITER, MACRO_VAR_EXPRS_END_DELIMITER, :EOF, :DEDENT # , :NEWLINE, :INDENT #,   :"=>"
         return true
      when :IDFR
         case @token.value
         when :else, :elsif, :elif, :when, :rescue, :ensure, :fulfil, :do, :then, :begins
            return true
         end

         if is_explicit_end_tok?
            return true
         end
      end

      false
   end

   def pragmas?()
      tok?(:"'") && !('A' <= current_char <= 'Z') # (:BACKSLASH, :"|", :"#", :"'")
      # tok?(:BACKSLASH, :"|", :"#", :"'")
   end

   def pragma_starter?()
      tok?(:"'") && !('A' <= current_char <= 'Z') # (:BACKSLASH, :"|", :"#", :"'")
   end

   def can_be_assigned?(node) : Bool
      case node
      when Var, InstanceVar, ClassVar, Path, Global, Underscore
         true
      when Call
         (node.obj.nil? && node.args.size == 0 && node.block.nil?) || node.name == "[]"
      else
         false
      end
   end

   def push_fresh_scope : Nil
      @scope_stack.push_scope(Scope.new) # push(Set(String).new)
      nil
   end

   def push_scope(args)
      push_scope(Scope.new(args.map &.name))
      ret = yield
      pop_scope
      ret
   end

   def push_scope(scope) : Nil
      @scope_stack.push_scope(scope)
      nil
   end

   def push_scope : Nil
      @scope_stack.push_scope
      nil
   end

   def pop_scope : Nil
      @scope_stack.pop_scope
      nil
   end

   def add_vars(vars) : Nil
      vars.each do |var|
         add_var var
      end
      nil
   end

   def add_var(var : Var | Arg) : Nil
      add_var var.name.to_s
      nil
   end

   def add_var(var : TypeDeclaration) : Nil
      var_var = var.var
      case var_var
      when Var
         add_var var_var.name
      when InstanceVar
         add_var var_var.name
      else
         raise "can't happen"
      end
      nil
   end

   def add_var(name : String) : Nil

      dbg "add_var(\"#{name}\")"

      @scope_stack.add_var name

      # *TODO* *DEBUG*
      # @scope_stack.dbgstack

      nil
   end

   def add_var(node) : Nil
      # Nothing

      dbg "add_var(node) - skipped ?: '#{node}'"

      nil
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

   def parse_def_nest_start() : {Symbol, Symbol, Bool, Array(ASTNode)}
      # *TODO* we don't pass the syntax used, so a stylizer would have to look
      # at the source via "location"

      dbg "parse_def_nest_start"

      if !tok?(:"->")
         Crystal.raise_wrong_parse_path "unexpected token. Expected `->`, or a variation of it"
      end

      dbg "we got the mandatory '->'"

      next_token

      dbg "check for callable variations"

      # *TODO* these variations look like shit - ditch. replace with pragmas and
      # grouping pragmas
      case
      when tok? :"@"
         callable_type = :strict_method
         next_token_skip_space

      when tok? :">"
         callable_type = :pure_callable
         next_token_skip_space
      # when tok? :")", :"}"
      #    callable_type = :softlambda
      #    next_token_skip_space
      else
         callable_type = :standard_callable
      end



      if tok? :"!"
         dbg "got returns-nothing modifier!"

         returns_nothing = true
         next_token_skip_space

      else
         dbg "expl or auto return type"
         returns_nothing = false
      end

      skip_space

      dbg "check for def suffix-pragmas"
      if pragmas? # tok? :PRAGMA
         pragmas = parse_pragma_grouping
      else
         pragmas = [] of ASTNode
      end

      # handle one–line vs multi–line vs nil–nest etc.
      nest_kind = case
      when tok? :INDENT
         dbg "parse_def_nest_start - :INDENT"
         next_token
         unsignificantify_newline
         :NEST

      when tok?(:DEDENT, :NEWLINE, :END)
         dbg "parse_def_nest_start - :DEDENT, :NEWLINE, :END"
         :NIL_NEST

      else
         dbg "parse_def_nest_start - explicit_starter"
         @one_line_nest += 1
         @significant_newline = true
         :LINE_NEST

      end

      {nest_kind, callable_type, returns_nothing, pragmas}

   end

   def parse_nest_start(kind : Symbol, indent : Int32) : {Symbol, Int32} #   = :generic
      # *TODO* we don't pass the syntax used, so a stylizer would have to look at
      # the source via "location"

      dbg "parse_nest_start".yellow


      dedent_level = kwd?(:begins) ? -1 : indent
      #compare_dedent_level = dedent_level == -1 ? indent - 1 : indent

      # *TODO* om `~>` block starter is kept, then an additional start-token
      # should be illegal - looks crazy!
      explicit_starter = parse_explicit_nest_start_token

      case
      when kind == :case
         if tok?(:NEWLINE)
            dbg "parse_nest_start - :case :NEWLINE"
            next_token_skip_space
            if kwd?(:when) || tok?(:"|")
               {:WHEN_NEST, dedent_level}
            else
               raise "Does this happen. Is an error right? *TODO*"
            end
         elsif tok?(:INDENT)
            dbg "parse_nest_start - :case :INDENT"
            next_token_skip_space
            if kwd?(:when) || tok?(:"|")
               {:WHEN_NEST, dedent_level}
            else
               {:FREE_WHEN_NEST, dedent_level}
            end
         elsif explicit_starter
            dbg "parse_nest_start - :case explicit_starter"
            @one_line_nest += 1
            @significant_newline = true
            {:LINE_NEST, dedent_level}
         else
            dbg "parse_nest_start - :case unknown"
            raise "unexpected token, expected code-block to start"
         end

      when kind == :if && tok?(:"?")
         dbg "parse_nest_start - :? -> TERNARY"
         next_token_skip_statement_end

         {:TERNARY, dedent_level}

      when tok? :INDENT
         dbg "parse_nest_start - :INDENT"
         next_token
         unsignificantify_newline
         {:NEST, dedent_level}

      when tok?(:DEDENT, :END)
         dbg "parse_nest_start - :DEDENT, :END"
         # next_token_skip_space
         {:NIL_NEST, dedent_level}

      when tok?(:NEWLINE)
         if dedent_level == -1
            dbg "parse_nest_start - :NEWLINE when begins-block"
            next_token
            unsignificantify_newline
            {:NEST, dedent_level}
         else
            dbg "parse_nest_start - :NEWLINE when regular block"
            # next_token_skip_space
            {:NIL_NEST, dedent_level}
         end

      when explicit_starter && kwd?(:else, :elsif, :elif)
         dbg "parse_nest_start - explicit_starter + :else|:elsif|:elif"
         {:NIL_NEST, dedent_level}

      when explicit_starter, kind == :else, kind == :block_start
         dbg "parse_nest_start - explicit_starter | KIND == :else | KIND == :block_start"
         @one_line_nest += 1
         @significant_newline = true
         {:LINE_NEST, dedent_level}
      else
         raise "unexpected token, expected code-block to start"
      end
   end

   def parse_explicit_nest_start_token
      if (tok?(:"=>", :":") || kwd?(:do, :then, :begins))
         dbg "parse_explicit_nest_start_token - found explicit_starter"
         next_token_skip_space
         true
      else
         false
      end
   end

   def handle_nest_end(known_nil_nest : Bool = false) : Bool
      dbg "handle_nest".yellow + "_end".red
      if tok? :";"
         next_token_skip_space
      end

      # *TODO*
      if tok?(:EOF)
         return true

      elsif @one_line_nest == 0 # *TODO* this is semi–defunct!!

         if tok?(:DEDENT) || (known_nil_nest && tok?(:NEWLINE)) || tok?(:END)   # || tok?(:")") # *TODO* *TEST*
            dbg "handle_nest_end - multiline - dedent | nil-blk+nl"
            handle_definite_nest_end_
            @was_just_nest_end = true
            return true

         # *TODO* *9* single–line function–def was flagged as multiline, and didn't
         # close when "ternary"-if was only body. This is a temporary quick–fix!
         # Fix proper when refactoring indent/dedent–handling!
         elsif tok?(:NEWLINE) && @indent == @nesting_stack.last.indent
            dbg "handle_nest_end - dirty quick fix - newline+same-indent explicit check"
            handle_definite_nest_end_
            @was_just_nest_end = true
            return true

         elsif handle_transition_tokens
            return true
         end

         dbg "handle_nest_end - multiline - no nest_end"

         return false
      else
         if handle_transition_tokens
            return true
         end

         dbg "handle_nest_end - try handle_one_line_nest_end - one_line_nest = #{@one_line_nest}"
         if handle_one_line_nest_end
            @was_just_nest_end = true
            return true
         end

         dbg "handle_nest_end - one_line - no nest_end"

         return false
      end
   end

   def handle_transition_tokens
      dbg "handle_transition_tokens - one_line_nest = #{@one_line_nest}"
      # *TODO* add more reasonable ones here - possibly strengthen up with
      # "expectation" (based on nesting context)
      if tok?(:":") || kwd?(:else, :elsif, :elif, :ensure, :fulfil, :rescue)
      # if kwd?(:else, :elsif, :elif, :ensure, :fulfil, :rescue)
         dbg "- handle_transition_tokens - DE-NESTS".red
         # @was_just_nest_end = true
         de_nest @indent, :"", ""
         return true
      end

      return false
   end

   def handle_one_line_nest_end : Bool
      case
      # *TODO* clean up belows when refactoring indent–parsing

      # `,` was added so `foo( ()->1, ()->2; 3, ()->4) - ie lambdas as args can be used smoothly
      when tok? :","
         dbg "handle_one_line_nest_end COMMA ','"
         handle_definite_nest_end_
         unsignificantify_newline
         return true

      when tok? :")"
         dbg "handle_one_line_nest_end LPAREN ')'"
         handle_definite_nest_end_
         unsignificantify_newline
         return true

      when tok? :NEWLINE
         dbg "handle_one_line_nest_end NEWLINE"
         handle_definite_nest_end_
         unsignificantify_newline
         return true

      when tok? :DEDENT
         dbg "handle_one_line_nest_end DEDENT"
         unsignificantify_newline
         return handle_definite_nest_end_

      when is_explicit_end_tok?
         dbg "handle_one_line_nest_end explicit END-*"
         # handle_definite_nest_end_
         indent_level = @indent
         line, col = @token.line_number, @token.column_number
         end_token, match_name = parse_explicit_end_statement

         dbg "- handle_one_line_nest_end - DE-NESTS".red

         de_nest indent_level, end_token, match_name, line, col
         return true

      else
         dbg "handle_one_line_nest_end - no nest_end in sight"
         return false
      end

   end

   def handle_definite_nest_end_(force = false) : Bool
      dbg "handle_definite_nest_end_".yellow

      backed = backup_tok
      next_token if ! tok?(:")", :",")  # `,` was added so `foo( ()->1, ()->2; 3, ()->4) - ie lambdas as args can be used smoothly

      indent_level = @indent

      if tok?(:NEWLINE, :DEDENT)
         dbg "handle_definite_nest_end_: consumed NEWLINE|DEDENT - @significant_newline = #{@significant_newline}"
         # last_backed = backup_pos
         next_token_skip_space_or_newline
      end

      line, col = @token.line_number, @token.column_number

      if is_explicit_end_tok?
         # last_backed = backup_pos
         end_token, match_name = parse_explicit_end_statement
         dbg "handle_definite_nest_end_ is DEDENT: explicit end-token '#{end_token}'"

      else
         dbg "handle_definite_nest_end_ is DEDENT: implicit end"
         end_token = :""
         match_name = ""
      end

      dbg "- handle_definite_nest_end_ - DE-NESTS".red

      case de_nest indent_level, end_token, match_name, line, col, force
      when :false
         # raise "Nothing to pop on the nesting stack! Wtf?"
         dbg "de_nest returned :false - this was just a post-usage check then (to avoid suffix parse)"
         return false

      when :more
         dbg "there's apparently MORE NESTINGS to pop, so we REPEAT the dedent-token in queue".magenta
         restore_tok backed
         dbg "token after restore"
         return true

      when :done
         dbg "all NESTINGS are DONE"
         while tok? :NEWLINE
            next_token
         end

         return true
      else
         raise "internal error in handle_definite_nest_end_ after de_nest"
      end
   end

   def parse_explicit_end_statement : {Symbol, String}
      dbg "parse_explicit_end_statement"

      end_token = @token.value as Symbol
      next_token

      # is there a name–matching?
      if tok? :"="
         next_token
         match_name = parse_constish.to_s # *TODO* WRONG!
         dbg "parse_explicit_end_statement - got match name '" + match_name + "'"
         next_token_skip_space

         if !tok?(:NEWLINE, :";") # *TODO* can be comment, etc. muddafuckin shit
            raise "expect newline or ';' after name-matched end-token, got '" + @token.to_s + "'"
         end
      else
         match_name = ""
      end

      # *TODO* possibly eat ";" + " " here
      skip_statement_end

      {end_token, match_name}
   end

   def is_explicit_end_tok? : Bool
      tok? :END
   end

   def add_nest(nest_kind : Symbol, indent : Int32, match_name : String, line_block : Bool, require_end_token : Bool) : Nil
      dbg ">> ADD NESTING:    ".white + nest_kind.to_s.quot.yellow + "   at " + indent.to_s
      location = @token.location # *TODO* must be able to pass
      @nesting_stack.add nest_kind, indent, match_name, location, line_block, require_end_token
      dbg @nesting_stack.dbgstack.yellow
      nil
   end

   def de_nest(indent : Int32, end_token : Symbol, match_name : String,
                     line = @token.line_number, col = @token.column_number,
                     force = false) : Symbol
      dbg "de_nest ->".red

      tmp_dbg_nest_indent = @nesting_stack.last.indent.to_s
      tmp_dbg_nest_kind = @nesting_stack.last.nest_kind.to_s

      ret = @nesting_stack.dedent indent, end_token, match_name, force

      if ret.is_a? String
         raise ret, line, col
      end

      if @one_line_nest > 0
         @one_line_nest -= 1
      end

      unsignificantify_newline

      dbg ">> POPPED NEST >> ".red + tmp_dbg_nest_kind.quot.yellow + ":" + tmp_dbg_nest_indent.yellow + " on " + indent.to_s.yellow
      dbg @nesting_stack.dbgstack.red

      ret
   end

   def hard_pop_nest(count : Int32)
      @nesting_stack.hard_pop count
      dbg ">> HARD POPPED NEST >> ".red
      dbg @nesting_stack.dbgstack.red
   end

   def hard_pop_scope(count : Int32)
      @scope_stack.hard_pop count
      dbg ">> HARD POPPED SCOPE >> ".red
      @scope_stack.dbgstack
   end

   def current_nest_indent : Int32
      @nesting_stack.last.indent
   end

   def check_closing_paren
      return true if tok? :")"

      # *TODO* when dedent/indent, they shouldn't _be_ that if it's paren
      # because then they've changed the "last ind val" in lexer - and thus
      # one can goof up the whole block nesting by punching out several levels!
      # *TODO* *VERIFY*

      if tok?(:DEDENT, :NEWLINE, :INDENT) && current_char == ')'
         next_token
         return true
      end

      raise "expecting token ')', not '#{@token.type.to_s}':'#{@token.value.to_s}'", @token
      false
   end

   def check_void_value(exp, location)
      if exp.is_a?(ControlExpression)
         raise "void value expression", location
      end
   end

   def check_void_expression_keyword
      # dbg "check_void_expression_keyword"
      case @token.type
      when :IDFR
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

   def check(token_type, when_what : String)
      raise "expecting token '#{token_type}', not '#{@token.to_s}', when '#{when_what}", @token unless token_type == @token.type
   end

   def check_token(value)
      raise "expecting token '#{value}', not '#{@token.to_s}'", @token unless @token.type == :TOKEN && @token.value == value
   end

   def check_idfr(value)
      raise "expecting identifier '#{value}', not '#{@token.to_s}'", @token unless kwd?(value)
   end

   def check_idfr
      check :IDFR
      @token.value.to_s
   end

   def surrounded_by_space?
      current_char == ' ' && prev_tok?(:SPACE)
   end

   def surrounded_by_space?(*tokens)
      surrounded_by_space? && tok?(tokens)
   end

   def scan_next_as_continuation
      dbg "sets scan_next_as_continuation"
      @next_token_continuation_state = :CONTINUATION
   end

   def parser_peek_non_ws_char(n = 1) : Char
      # *TODO* should skip comments too, and newlines - MAKE ANOTHER FOR THAT
      cur_pos = current_pos || 1

      while current_char == ' '
         next_char
      end

      while n > 1
         next_char
         n -= 1
      end

      ch = current_char
      set_pos cur_pos
      return ch
   end

   def new_num_lit(value, kind = :int)
      dbg "new_num_lit ->"


      # *TODO* this should _probably_ be done in a semantic stage
      # (not absolutely necessarily though)

      if kind == :int
         confed_type = @nesting_stack.last.int_type_mapping #.value.to_s

         dbg "- new_num_lit - int -> #{confed_type}"

         case confed_type

         # # *TODO*
         # when "StdInt",  "Int"
         #    look up int–width defined for StdInt
         #    kind = :i32 | :i64    # *TODO* *9* look up CHOSEN architecture int width


         when "I32", "Int32"
            kind = :i32
         when "I64", "Int64"
            kind = :i64
         else
            # confed_type = "StdInt" if confed_type == "Int"  # *TODO*

            return Call.new(
               Path.new([confed_type], true), # .at(location)
               "new",
               [NumberLiteral.new(value, :i64)] of ASTNode+,
               nil,
               nil,
               nil,
               false,
               0,
               true,
               true
            )
         end

      elsif kind == :real
         confed_type = @nesting_stack.last.real_type_mapping #.value.to_s

         dbg "- new_num_lit - real -> #{confed_type}"

         case confed_type
         when "StdReal"
            kind = :f64    # *TODO* Lookup from type–chain
         when "F32", "Float32"
            kind = :f32
         when "F64", "Float64"
            kind = :f64
         else
            return Call.new(
               Path.new([confed_type], true), # .at(location)
               "new",
               [NumberLiteral.new(value, :f64)] of ASTNode+,
               nil,
               nil,
               nil,
               false,
               0,
               true,
               true
            )
         end

      else
         dbg "- new_num_lit - #{kind}"
      end

      NumberLiteral.new(value, kind)

   ensure
      dbgtail "/new_num_lit"
   end

   def check_const
      check :CONST
      babelfish_taint @token.value.to_s  # *TODO* *DEBUG* *TEMP*
   end

   def unexpected_token(msg, token = @token.to_s)
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

      unexpected_token "while parsing atomic"
   end

   def is_var?(name)
      return true if @in_macro_expression

      name = name.to_s
      ret = name == "self" || @scope_stack.cur_has?(name)

      # *TODO* *DEBUG*
      if !ret
         if name == "failed_count"
            dbg "failed_count 'NOT A VAR'!"
            @scope_stack.dbgstack
         end
      end

      ret
   end

   def add_instance_var(name)
      return if @in_macro_expression

      @instance_vars.try &.add name
   end

   def self.free_var_name?(name)
      # *TODO* - this should be changed in Onyx - any length free var names possible!
      # *TODO* where does it fuck up atm? Must we make a lookup–table back and forth?

      # name.size == 1 || (name.size == 2 && name[1].digit?)
      true
   end


   # *TODO* order data in alphabetical order!
   # token+position state backing/restoring (stacked via function–call scopes)
   def backup_full
      token = Token.new
      token.copy_from @token

      {
         current_pos,
         @line_number,
         @column_number,
         @indent,
         token,
         @prev_token_type,
         @slash_is_regex,

         @nesting_stack.size,
         @scope_stack.size,
         @control_construct_parsing
         @def_parsing,
         @def_nest,
         @certain_def_count,
         @one_line_nest,
         @was_just_nest_end,
         @significant_newline,
         @next_token_continuation_state
      }
   end

   def restore_full(backup)
      self.current_pos,
      @line_number,
      @column_number,
      @indent,
      token,
      @prev_token_type,
      @slash_is_regex,

      nest_count,
      scope_count,
      @control_construct_parsing,
      @def_parsing,
      @def_nest,
      @certain_def_count,
      @one_line_nest,
      @was_just_nest_end,
      @significant_newline,
      @next_token_continuation_state =
            backup

      @token.copy_from token
      hard_pop_nest nest_count
      hard_pop_scope scope_count
      nil
   end

   def backup_tok
      token = Token.new
      token.copy_from @token
      {current_pos, @line_number, @column_number, @indent, token}
   end

   def restore_tok(backup : {Int32, Int32, Int32, Int32, Token})
      self.current_pos, @line_number, @column_number, @indent, token = backup
      @token.copy_from token
   end

   def backup_pos
      {current_pos, @line_number, @column_number, @indent}
   end

   def restore_pos(backup : {Int32, Int32, Int32, Int32})
      self.current_pos, @line_number, @column_number, @indent = backup
   end

   macro test_parse(test_path)
      (
      state_backup = backup_full

      begin
         dbg "tries a test parse of {{test_path.id}}"
         {{test_path.id}}
         test =  true

      rescue WrongParsePathException
         test = false
      end

      restore_full state_backup

      test
      )

   end

   macro try_parse(first_path, second_path = "nil")
      (
      state_backup = backup_full

      begin
         dbg "try to parse {{first_path.id}}"
         node = {{first_path.id}}

      rescue WrongParsePathException
         dbg "rescues failed attempt to parse {{first_path.id}}, parses {{second_path.id}}"
         restore_full state_backup
         node = {{second_path.id}}
      end

      node
      )

   end

end

end # module
