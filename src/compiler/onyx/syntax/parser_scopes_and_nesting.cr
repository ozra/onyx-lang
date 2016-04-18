module Crystal

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
         @scopes.pop
      end
      @current_scope = @scopes.last
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
   property nest_kind : Symbol
   property indent : Int32
   property name : String
   property location : Location
   property single_line : Bool


   property require_end_token : Bool

   property block_auto_params : Array(Var)?

   # property int_type_mapping : String
   # property real_type_mapping : String
   # @@std_int : String
   # @@std_int = "StdInt"
   # @@std_real : String
   # @@std_real = "StdReal"

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

   def initialize(@nest_kind, @indent, @name, @location, @single_line, @require_end_token, @block_auto_params = nil) # , @int_type_mapping = @@std_int, @real_type_mapping = @@std_real)
      if !Nesting.nesting_keywords.includes? @nest_kind.to_s
         raise "Shit went down - don't know about nesting kind '#{@nest_kind.to_s}'"
      end
   end

   def dup
      Nesting.new @nest_kind, @indent, @name, @location, @single_line, @require_end_token, @block_auto_params.dup #, @int_type_mapping, @real_type_mapping
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
      # nest.int_type_mapping = last.int_type_mapping
      # nest.real_type_mapping = last.real_type_mapping
      @stack.push nest
   end

   def last
      @stack.last
   end

   def replace_last(nest : Nesting)
      @stack[-1] = nest
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
      if indent != MACRO_INDENT_FLAG && indent <= last.indent && size > 1
         # p @stack.to_s
         :more
      else
         :done
      end
   end

   def dedent(indent : Int32, end_token : Symbol, match_name : String, force = false) : Symbol | String
      # while true
      nest = @stack.last

      if force
         return pop_and_status indent, force

      elsif indent < nest.indent
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

end