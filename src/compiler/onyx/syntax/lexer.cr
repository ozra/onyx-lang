require "../../crystal/syntax/token"
require "../../crystal/exception"

struct Char
  struct Reader
    def unsafe_decode_char_at(i)
      return '\0' if i < 0
      return '\0' if i > @string.bytesize
      decode_char_at(i) do |code_point, width|
        code_point.chr
      end
    end
  end
end

ContinuationTokens = [
  :".", :",", :"+", :"-", :"*", :"/", :"%", :".|.", :".&.", :".^.", :"**", :"<<",
  :"<", :"<=", :"==", :"!=", :"=~", :">>", :">=", :"<=>", :"||", :"&&",
  :"===" # :">", - has to be handles contextually - can be generic delimiter
]

module Crystal

  class Lexer
    def scan_ident(start)
      while ident_part?(current_char)
        next_char
      end
      case current_char
      when '!', '?'
        next_char
      end
      @token.type = :IDENT

      str = string_range(start)
      @token.value = canonicalize_identifier str
      @token.raw = str

      @token
    end

    def canonicalize_identifier(idfr_str)
      do_hump_magic = idfr_str.size > 0 && !('A' <= idfr_str[0] <= 'Z')

      ret = String.build idfr_str.size * 3, do |str|
        idfr_str.each_char_with_index do |chr, i|
          if chr == '-'
            str << '_'

          elsif chr == '–'
            str << '_'

          elsif do_hump_magic && ('A' <= chr <= 'Z')
            str << '_'
            str << chr.downcase

          else
            str << chr
          end
        end
      end
      ret
    end
  end

  class OnyxLexer
    property? doc_enabled
    property? comments_enabled
    property? count_whitespace
    property? wants_raw
    property? slash_is_regex
    getter reader
    getter token
    getter line_number

    property prev_token_type

    def initialize(string)
      @reader = Char::Reader.new(string)
      @token = Token.new
      @token.type = :ACTUAL_BOF
      @prev_token_type = :ACTUAL_BOF
      @line_number = 1
      @column_number = 1
      @filename = ""
      @wants_regex = true
      @doc_enabled = false
      @comments_enabled = false
      @count_whitespace = false
      @slash_is_regex = true
      @wants_raw = false

      @dbg–switch = false
      @dbg–tail–switch = false
      @dbgindent__ = 0


      @indent = 0

      @error_stack = [] of Exception  # *TODO*

      @next_token_continuation_state = :AUTO

      skip_shebang

    end

    # DEBUG UTILS #
    def dbginc
      @dbgindent__ += 1
    end

    def dbgdec
      @dbgindent__ -= 1
    end

    def dbg_on
      ifdef !release
        return if @dbg–switch
        @dbg–switch = true
        @dbg–tail–switch = true
        dbg "TURNS DEBUG LOGGING ON".red
      end
    end

    def dbg_off
      ifdef !release
        return if !@dbg–switch
        dbg "TURNS DEBUG LOGGING OFF".red
        @dbg–switch = false
        @dbg–tail–switch = false
      end
    end

    def dbgtail_off!
      ifdef !release
        @dbg–tail–switch = false
      end
    end

    def dbgtail(str : String)
      ifdef !release
      # str = str.gsub /'(.*?):(.*?)'/, "'$1':'$2'"
        return if @dbg–tail–switch == false
        STDERR.puts (" " * (@dbgindent__ * 1)) + @dbgindent__.to_s + ": /" + str +
              "  (now: '" + @token.type.to_s + "' : '" + @token.value.to_s +
              "' [" + @token.line_number.to_s + ":" + @token.column_number.to_s +
              "])"
      end
    end

    def dbg(str : String)
      ifdef !release
      # str = str.gsub /'(.*?):(.*?)'/, "'$1':'$2'"
        return if @dbg–switch == false
        STDERR.puts (" " * (@dbgindent__ * 1)) + @dbgindent__.to_s + ": " + str +
              "  (now: '" + @token.type.to_s + "' : '" + @token.value.to_s +
              "' [" + @token.line_number.to_s + ":" + @token.column_number.to_s +
              "])"
      end
    end

    def dbgXXX(str : String)
        STDERR.puts (" " * (@dbgindent__ * 1)) + @dbgindent__.to_s + ": " + str +
              "  (now: '" + @token.type.to_s + "' : '" + @token.value.to_s +
              "' [" + @token.line_number.to_s + ":" + @token.column_number.to_s +
              "])" + " XXX".red

        # STDOUT.flush
    end

    def dbg_lex(s)
      ifdef !release
        return if @dbg–switch == false
        STDERR.puts "## #{s} @#{@line_number}:#{@column_number - 1}"
      end
    end

    def dbg_ind(s)
      ifdef !release
        return if @dbg–switch == false
        STDERR.puts "## #{s} @#{@line_number}:#{@column_number - 1}"
      end
    end

    def filename=(filename)
      @filename = filename
    end

    def skip_shebang
      return unless curch == '#' && peek_nextch == '!'

      while nextch != '\0'
        if curch == '\n'
          @line_number += 1
          nextch
          return
        end
      end
    end

    def next_token
      dbg_lex "next_token() - curch ='#{curch.ord}'"

      # *TODO* DEBUG HELPER
      # *TODO* skip generating token, and eath below followed by newline and continue!
      ifdef !release
        if (v = @token.value).is_a?(String)
           case v
           when "_debug_compiler_start_"
              dbg_on
           when "_debug_compiler_stop_"
              dbg_off
           end
        end
      end

      prev_token_type = @token.type

      reset_token

      start = cur_pos

      reset_regex_flags = true

      case curch
      when '\0'
        @token.type = :EOF
      when ' ', '\t'
        consume_whitespace
        reset_regex_flags = false

      when '\\'
        dbg_lex "root level backslash"
        backed_type = @token.type

        nextch
        start = cur_pos

        # p "nextch after backslash = " + curch
        if curch == ' ' || curch == '\t'
          dbg_lex "in backslash: got spc or tab - consume_whitespace"
          consume_whitespace
        end
        # p "curch after consume_whitespace = " + curch

        # p "skip comments"
        dbg_lex "in backslash: skip_comment"
        # skip_comment # *TODO* skip / consume / handle_comment ??
        handle_comment

        # p "curch after skip_comment = " + curch
        if curch == '\n'
          dbg_lex "in backslash: got newline '#{curch}'"
          @line_number += 1
          @column_number = 1

          @token.passed_backslash_newline = true
          consume_whitespace
          reset_regex_flags = false
          @token.type = backed_type

        else
          dbg_lex "must be a solo mystic backslash"
          @token.type = :BACKSLASH
        end

      when '\n'
        nextch

        back_line = @line_number
        back_col = @column_number

        @line_number += 1
        @column_number = 1

        dbg_ind  "Got into \\n"

        while true
          indent_start = cur_pos - 1

          while curch == ' ' || curch == '\t'  # *TODO* add check so that BOTH don't occur in the same file!
            nextch
          end

          if curch == '\n'
            @line_number += 1
            @column_number = 1
            nextch

          else
            break
          end
        end

        dbg_lex "Collected pure ws"

        # if curch == '\n'
        #   p "Got a new :NEWLINE - do nothing special"
        #   # newline again = do nothing special - no indent/dedent..
        # #   #p "Got a new :NEWLINE - recurse to next lap"
        # #   #ret = next_token
        # #   # ret.line_number = back_line
        # #   # ret.column_number = back_col
        # #   # return ret
        # #   p "got next newline - now we just handle it like old days"

        if (curch == '-' && peek_nextch == '-') || curch == '—' # a comment
          dbg_lex "Got comment"

          # *TODO* COMMENTS = NOT INDENT FORMING, OR, _ARE_ INDENT FORMING??
          # ONLY DOC–COMMENTS PERHAPS? <-- SEEMS MOST REASONABLE CHOICE!
          # (ALL COMMENTS INDENT FORMING ATM!)

          # *TODO* handle_comment??

          unless @comments_enabled
            # p "comments not enabled, continue"
            skip_comment
            ret = next_token
            ret.line_number = back_line
            ret.column_number = back_col
            return ret
          end

        else
          gotten_indent = cur_pos - indent_start - 1

          is_continuation = @next_token_continuation_state == :CONTINUATION ||
                                    (@next_token_continuation_state == :AUTO &&
                                      ContinuationTokens.includes?(prev_token_type)
                                    )

          dbg_ind "is_continuation == #{is_continuation}, cont_state == #{@next_token_continuation_state}"

          dbg_ind "gotten indent = #{gotten_indent}, current = #{@indent}"
          if gotten_indent != @indent && !is_continuation
            @token.value = gotten_indent
            if gotten_indent > @indent
              @token.type = :INDENT

              # p "made :INDENT token (" + @token.value.to_s + ")"
            else
              @token.type = :DEDENT

              # p "made :DEDENT token (" + @token.value.to_s + ")"
            end
            # @token.location = Location.new @line_number, 1, @filename # *TODO* this one doesn't seem to take!
            @column_number = gotten_indent + 1
            @indent = gotten_indent

            @token.line_number = back_line
            @token.column_number = back_col

            return @token
          end
        end

        @token.line_number = back_line
        @token.column_number = back_col

        @token.type = :NEWLINE
        reset_regex_flags = false
        consume_newlines


      when '\r'
        if nc? '\n'
          dbg_ind "recurse to next lap"
          return next_token # We don't repeat our selves for teleprinter archaic linebreak combos
        else
          raise "expected '\\n' after '\\r'"
        end

      when '='
        case nextch
        when '='
          case nextch
          when '='
            toktype_then_nextch :"==="
          else
            @token.type = :"=="
          end
        when '}'
          toktype_then_nextch :"=}"
        when '>'
          toktype_then_nextch :"=>"
        when '~'
          toktype_then_nextch :"=~"
        else
          @token.type = :"="
        end
      when '!'
        case nextch
        when '='
          toktype_then_nextch :"!="
        else
          @token.type = :"!"
        end
      when '<'
        case nextch
        when '='
          case nextch
          when '>'
            toktype_then_nextch :"<=>"
          else
            @token.type = :"<="
          end
        when '<'
          case nextch
          when '='
            toktype_then_nextch :"<<="
          else
            @token.type = :"<<"
          end
        else
          @token.type = :"<"
        end
      when '>'
        case nextch
        when '='
          toktype_then_nextch :">="
          # when '>'  # needs to be tracked in parser now - generics or operator
          #   case nextch
          #   when '='
          #     toktype_then_nextch :">>="
#
          #   else
          #     @token.type = :">>"
#
          #   end
        else
          @token.type = :">"
        end
      when '+'
        @token.start = start
        case nextch
        when '='
          toktype_then_nextch :"+="
        when '0'
          scan_zero_number(start)
        when '1', '2', '3', '4', '5', '6', '7', '8', '9'
          scan_number(start)
        when '+'
          raise "postfix increment is not supported, use `exp += 1`"
        else
          @token.type = :"+"
        end
      when '-'
        # @token.start = start  *TODO* look over this later addition for comment compat
        start = cur_pos
        case nextch
        when '='
          toktype_then_nextch :"-="
        when '>'
          toktype_then_nextch :"->"
        when '0'
          scan_zero_number start, negative: true
        when '1', '2', '3', '4', '5', '6', '7', '8', '9'
          scan_number start, negative: true
        when '-'
          # p "Got '-'"
          set_pos start # for handle_comment
          if (ret = handle_comment) == false
            raise "postfix decrement is not supported, use `exp -= 1`. Comments need a space before '--'"
          elsif ret.is_a? Token
            return ret
          else
            return next_token
          end
        else
          @token.type = :"-"
        end
      when '—' # em–dash!
        # p "got EMDASH"
        if (ret = handle_comment) == false
          raise "unexpected EMDASH!"
        elsif ret.is_a? Token
          return ret
        else
          return next_token
        end
      when '*'
        case nextch
        when '='
          toktype_then_nextch :"*="
        when '*'
          case nextch
          when '='
            toktype_then_nextch :"**="
          else
            @token.type = :"**"
          end
        else
          @token.type = :"*"
        end
      when '/'
        line = @line_number
        column = @column_number
        char = nextch
        if char == '='
          toktype_then_nextch :"/="
          # *TODO* change syntax for regex? `regex = //regex–contents/i`
        elsif @slash_is_regex
          @token.type = :DELIMITER_START
          @token.delimiter_state = Token::DelimiterState.new(:regex, '/', '/', 0)
          @token.raw = "/"
        elsif char.whitespace? || char == '\0' || char == ';'
          @token.type = :"/"
        elsif @wants_regex
          @token.type = :DELIMITER_START
          @token.delimiter_state = Token::DelimiterState.new(:regex, '/', '/', 0)
          @token.raw = "/"
        else
          @token.type = :"/"
        end
      when '%'
        case nextch
        when '='
          toktype_then_nextch :"%="
        when '(', '[', '{', '<'
          delimited_pair :string, curch, closing_char, start

        when ':'
          here = scan_heredoc_delimiter
          dbg_lex "heredoc idfr found: '#{here}'"
          delimited_pair :heredoc, here, here, start

        when '"'
          line = @line_number
          column = @column_number
          @token.type = :CHAR
          case char1 = nextch
          when '\\'
            case char2 = nextch
            when 'b'
              @token.value = '\b'
            when 'e'
              @token.value = '\e'
            when 'f'
              @token.value = '\f'
            when 'n'
              @token.value = '\n'
            when 'r'
              @token.value = '\r'
            when 't'
              @token.value = '\t'
            when 'v'
              @token.value = '\v'
            when 'u'
              value = consume_char_unicode_escape
              @token.value = value.chr
            when '0', '1', '2', '3', '4', '5', '6', '7'
              char_value = consume_octal_escape(char2)
              @token.value = char_value.chr
            else
              @token.value = char2
            end
          else
            @token.value = char1
          end
          if nextch != '"'
            raise "unterminated char literal, use double quotes for strings", line, column
          end
          nextch

        when 'i'
          case peek_nextch
          when '(', '{', '[', '<'
            start_char = nextch
            toktype_then_nextch :SYMBOL_ARRAY_START
            @token.delimiter_state = Token::DelimiterState.new(:symbol_array, start_char, closing_char(start_char), 0)
          else
            @token.type = :"%"
          end
        when 'r'
          case nextch
          when '(', '[', '{', '<'
            delimited_pair :regex, curch, closing_char, start
          else
            raise "unknown %r char"
          end

        when 's'
          case nextch
          when '(', '[', '{', '<'
            delimited_pair :straight_string, curch, closing_char, start
          when ':'
            here = scan_heredoc_delimiter
          dbg_lex "heredoc idfr found for straigt: '#{here}'"
            delimited_pair :straight_heredoc, here, here, start
          else
            raise "unknown %s char"
          end

        when 'x'
          case nextch
          when '(', '[', '{', '<'
            delimited_pair :command, curch, closing_char, start
          else
            raise "unknown %x char"
          end
        when 'w'
          case peek_nextch
          when '(', '{', '[', '<'
            start_char = nextch
            toktype_then_nextch :STRING_ARRAY_START
            @token.delimiter_state = Token::DelimiterState.new(:string_array, start_char, closing_char(start_char), 0)
          else
            @token.type = :"%"
          end
        when '}'
          toktype_then_nextch :"%}"
        else
          @token.type = :"%"
        end
      when '(' then toktype_then_nextch :"("
      when ')' then toktype_then_nextch :")"
      when '{'
        char = nextch
        case char
        when '%'
          toktype_then_nextch :"{%"
        when '{'
          toktype_then_nextch :"{{"
        when '='
          toktype_then_nextch :"{="
        else
          @token.type = :"{"
        end
      when '}' then toktype_then_nextch :"}"
      when '['
        case nextch
        when ']'
          case nextch
          when '='
            toktype_then_nextch :"[]="
          when '?'
            toktype_then_nextch :"[]?"
          else
            @token.type = :"[]"
          end
        else
          @token.type = :"["
        end
      when ']' then toktype_then_nextch :"]"
      when ',' then toktype_then_nextch :","
      when '?' then toktype_then_nextch :"?"
      when ';'
        reset_regex_flags = false
        toktype_then_nextch :";"
      when ':'
        # dbg_lex "Got colon"
        char = nextch
        case char
        when ':'
          # dbg_lex "Got colon 2"
          toktype_then_nextch :"::"
        else
          @token.type = :":"
        end
      when '~'
        case nextch
        when '.'
          toktype_then_nextch :"~."
        when '>'
          toktype_then_nextch :"~>"
        when '='
          toktype_then_nextch :"~="
        else
          @token.type = :"~"
        end

      when '.'
        case nextch
        when '.'
          case nextch
          when '.'
            toktype_then_nextch :"..."
          else
            @token.type = :".."
          end

        when '~'
          if nextch == '.'
            toktype_then_nextch :".~."
          else
            raise "Was expecting `.~.` ('bitwise complement')"
          end

        when '^'
          if nextch == '.'
            case nextch
            when '='
              toktype_then_nextch :".^.="
            else
              @token.type = :".^."
            end
          else
            raise "Was expecting `.^.` ('bitwise xor')"
          end

        when '|'
          if nextch == '.'
            if nextch == '='
              toktype_then_nextch :".|.="
            else
              @token.type = :".|."
            end
          else
            raise "Was expecting `.|.` ('bitwise or')"
          end

        when '&'
          if nextch == '.'
            if nextch == '='
              toktype_then_nextch :".&.="
            else
              @token.type = :".&."
            end
          else
            raise "Was expecting `.&.` ('bitwise and')"
          end

        else
          @token.type = :"."
        end


      when '&'
        case nextch
        when '&'
          case nextch
          when '='
            toktype_then_nextch :"&&="
          else
            @token.type = :"&&"
          end
        else
          @token.type = :"&"
        end


      when '|'
        case nextch
        when '|'
          case nextch
          when '='
            toktype_then_nextch :"||="
          else
            @token.type = :"||"
          end
        else
          @token.type = :"|"
        end


      when '^'
        toktype_then_nextch :"^"

      when '\'' # NOT char anymore!
        toktype_then_nextch :"'"
        set_token_raw_from_start(start) # *TODO* validate
      when '"', '`'
        delimiter = curch
        nextch
        @token.type = :DELIMITER_START
        @token.delimiter_state = Token::DelimiterState.new(delimiter == '`' ? :command : :string, delimiter, delimiter, 0)
        set_token_raw_from_start(start)
      when '0'
        scan_zero_number(start)
      when '1', '2', '3', '4', '5', '6', '7', '8', '9'
        scan_number cur_pos
      when '@'
        start = cur_pos
        case nextch
        when '['
          toktype_then_nextch :"@["
        when ' ', '\n', '!' # callable (function) modifier symbol
          @token.type = :"@"
        else
          class_var = false
          if curch == '@'
            class_var = true
            nextch
          end
          if idfr_start?(curch)
            while idfr_part?(nextch)
              # Nothing to do
            end
            @token.type = class_var ? :CLASS_VAR : :INSTANCE_VAR
            @token.value = string_range(start).tr("-–", "__")
          else
            unknown_token
          end
        end
      when '#'
        char = nextch
        case char
        when '+'
          symbol_then_nextch "+"
        when '-'
          symbol_then_nextch "-"
        when '*'
          if nc?('*')
            symbol_then_nextch "**"
          else
            symbol "*"
          end
        when '/'
          symbol_then_nextch "/"
        when '='
          case nextch
          when '='
            if nc?('=')
              symbol_then_nextch "==="
            else
              symbol "=="
            end
          when '~'
            symbol_then_nextch "=~"
          else
            unknown_token
          end
        when '!'
          case nextch
          when '='
            symbol_then_nextch "!="
          when '~'
            symbol_then_nextch "!~"
          else
            symbol "!"
          end
        when '<'
          case nextch
          when '='
            if nc?('>')
              symbol_then_nextch "<=>"
            else
              symbol "<="
            end
          when '<'
            symbol_then_nextch "<<"
          else
            symbol "<"
          end
        when '>'
          case nextch
          when '='
            symbol_then_nextch ">="
          when '>'
            symbol_then_nextch ">>"
          else
            symbol ">"
          end
        when '&'
          symbol_then_nextch "&"
        when '|'
          symbol_then_nextch "|"
        when '^'
          symbol_then_nextch "^"
        when '~'
          symbol_then_nextch "~"
        when '%'
          symbol_then_nextch "%"
        when '['
          if nc?(']')
            case nextch
            when '='
              symbol_then_nextch "[]="
            when '?'
              symbol_then_nextch "[]?"
            else
              symbol "[]"
            end
          else
            unknown_token
          end
        when '"'
          line = @line_number
          column = @column_number
          start = cur_pos + 1
          count = 0

          while true
            char = nextch
            case char
            when '\\'
              if peek_nextch == '"'
                nextch
                count += 1
              end
            when '"'
              break
            when '\0'
              raise "unterminated quoted symbol", line, column
            else
              count += 1
            end
          end

          @token.type = :SYMBOL
          @token.value = string_range(start)
          nextch
          set_token_raw_from_start(start - 2)
        else
          if idfr_start?(char)
            start = cur_pos
            while idfr_part?(nextch)
              # Nothing to do
            end
            if curch == '!' || curch == '?'
              nextch
            end
            @token.type = :SYMBOL
            @token.value = string_range(start)
            set_token_raw_from_start(start - 1)
          else
            @token.type = :"#"
          end
        end
      when '$'
        start = cur_pos
        nextch
        case curch
        when '.'
          nextch
          @token.type = :"$." # "global" prefix, instead of `::`
        when '~'
          nextch
          @token.type = :"$~"
        when '?'
          nextch
          @token.type = :"$?"
        when .digit?
          start = cur_pos
          char = nextch
          if char == '0'
            char = nextch
          else
            while char.digit?
              char = nextch
            end
            char = nextch if char == '?'
          end
          @token.type = :GLOBAL_MATCH_DATA_INDEX
          @token.value = string_range(start)
        else
          if idfr_start?(curch)
            while idfr_part?(nextch)
              # Nothing to do
            end
            @token.type = :GLOBAL
            @token.value = string_range(start)
          else
            unknown_token
          end
        end
      when 'a'
        case nextch
        when 'b'
          if nc?('s') && nc?('t') && nc?('r') && nc?('a') && nc?('c') && nc?('t')
            return check_idfr_or_keyword(:abstract, start)
          end
        when 'l'
          if nc?('i') && nc?('a') && nc?('s')
            return check_idfr_or_keyword(:alias, start)
          end
        when 'n'
          if nc?('d')
            return check_idfr_or_token(:and, "", start)
          end
        when 'p'
          if nc?('i')
            return check_idfr_or_keyword(:api, start)
          end
        when 's'
          if peek_nextch == 'm'
            nextch
            return check_idfr_or_keyword(:asm, start)
          else
            return check_idfr_or_keyword(:as, start)
          end
        when 'u'
          if nc?('t') && nc?('o')
            return check_idfr_or_keyword(:auto, start)
          end
        end
        scan_idfr(start)
      when 'b'
        case nextch
        when 'y'
          return check_idfr_or_keyword(:by, start)
        when 'e'
          if nc?('g') && nc?('i') && nc?('n')
            if peek_nextch == 's'
              next_char
              return check_idfr_or_keyword(:begins, start)
            else
              return check_idfr_or_keyword(:begin, start)
            end
          end
        when 'r'
          case nextch
          when 'e'
            if nc?('a') && nc?('k')
              return check_idfr_or_keyword(:break, start)
            end
          when 'a'
            if nc?('n') && nc?('c') && nc?('h')
              return check_idfr_or_keyword(:branch, start)
            end
          end
        end
        scan_idfr(start)
      when 'c'
        case nextch
        when 'a'
          if nc?('s') && nc?('e')
            return check_idfr_or_keyword(:case, start)
          end
          scan_idfr(start)
        when 'f'
          if nc?('u') && nc?('n')
            return check_idfr_or_keyword(:cfun, start)
          end
          scan_idfr(start)
        when 'l'
          if nc?('a') && nc?('s') && nc?('s')
            return check_idfr_or_keyword(:class, start)
          end
          scan_idfr(start)
        when 'o'
          if nc?('n')
            case nextch
            when 's'
              if nc?('t')
                return check_idfr_or_keyword(:const, start)
              end
            when 'd'
              return check_idfr_or_keyword(:cond, start)
            end
          end
          scan_idfr(start)
        else
          scan_idfr(start)
        end
      when 'd'
        case nextch
        when 'e'
          if nc?('f')
            # p "Got 'def', check if not ident"
            return check_idfr_or_keyword(:def, start)
          end
        when 'o' then return check_idfr_or_keyword(:do, start)
        end
        scan_idfr(start)
      when 'e'
        case nextch
        when 'a'
          if nc?('c') && nc?('h')
            return check_idfr_or_keyword(:each, start)
          end
        when 'l'
          case nextch
          when 'i'
            if nc?('f')
              return check_idfr_or_keyword(:elif, start)
            end
          when 's'
            case nextch
            when 'e' then return check_idfr_or_keyword(:else, start)
            when 'i'
              if nc?('f')
                return check_idfr_or_keyword(:elsif, start)
              end
            end
          end
        when 'n'
          case nextch
          when 'd'
            back_end_pos = cur_pos

            end_token =
            case nextch
            when '-', '_', '–'
              # KVAR:
              #   cfun cstruct cunion cenum
              #   ctype
              # struct
              # lambda
              # macro
              # lib union
              # where
              # scope scoped contain contained
              # unless
              # until loop

              case nextch
              when 'a'
                if nc?('p') && nc?('i')
                  :end_api
                end
              when 'b'
                if nc?('l') && nc?('o') && nc?('c') && nc?('k')
                  :end_block
                end
              when 'c'
                case nextch
                when 'a'
                  case nextch
                  when 't'
                    if nc?('c') && nc?('h')
                      :end_catch
                    end
                  when 's'
                    if nc?('e')
                      :end_case
                    end
                  end
                when 'l'
                  if nc?('a') && nc?('s') && nc?('s')
                    :end_class
                  end
                end
              when 'd'
                if nc?('e') && nc?('f')
                  :end_def
                end
              when 'e'
                case nextch
                when 'a'
                  if nc?('c') && nc?('h')
                    :end_each
                  end
                when 'n'
                  if nc?('u') && nc?('m')
                    :end_enum
                  end
                end
              when 'f'
                case nextch
                when 'o'
                  if nc?('r')
                    :end_for
                  end
                when 'u'
                  if nc?('n')
                    :end_fun
                  end
                end
              when 'i'
                if nc?('f')
                  back_end_pos = cur_pos
                  if nc?('d') && nc?('e') && nc?('f')
                    :end_ifdef
                  else
                    set_pos back_end_pos
                    :end_if
                  end
                end
              when 'm'
                if nc?('o') && nc?('d') && nc?('u') && nc?('l') && nc?('e')
                  :end_module
                end
              when 't'
                case nextch
                when 'r'
                  case nextch
                  when 'a'
                    if nc?('i') && nc?('t')
                      :end_trait
                    end
                  when 'y'
                    :end_try
                  end
                when 'e'
                  if nc?('m') && nc?('p') && nc?('l') && nc?('a') && nc?('t') && nc?('e')
                    :end_template
                  end
                when 'y'
                  if nc?('p') && nc?('e')
                    :end_type
                  end
                end
              when 'w'
                if nc?('h') && nc?('i') && nc?('l') && nc?('e')
                  :end_while
                end
              end
            else
              set_pos back_end_pos
              :end
            end

            if end_token
              # p "ETOK: " + typeof(end_token).to_s + ", " + end_token.to_s
              return check_idfr_or_token(:END, end_token, start)
            end
          when 's'
            if nc?('u') && nc?('r') && nc?('e')
              return check_idfr_or_keyword(:ensure, start)
            end
          when 'u'
            if nc?('m')
              return check_idfr_or_keyword(:enum, start)
            end
          end
        when 'x'
          case nextch
          when 't'
            if nc?('e') && nc?('n') && nc?('d')
              return check_idfr_or_keyword(:extend, start)
            end
          when 'p'
            if nc?('o') && nc?('r') && nc?('t')
              return check_idfr_or_keyword(:export, start)
            end
          end
        end
        scan_idfr(start)
      when 'f'
        case nextch
        when 'a'
          if nc?('l') && nc?('s') && nc?('e')
            return check_idfr_or_keyword(:false, start)
          end
        when 'l'
          if nc?('a') && nc?('g') && nc?('s')
            return check_idfr_or_keyword(:flags, start)
          end
        when 'n'
          return check_idfr_or_keyword(:fn, start)
        when 'o'
          if nc?('r')
            return check_idfr_or_keyword(:for, start)
          end
        when 'r'
          if nc?('o') && nc?('m')
            return check_idfr_or_keyword(:from, start)
          end
        when 'u'
          case nextch
          when 'n'
            return check_idfr_or_keyword(:fun, start)
          when 'l'
            if nc?('f') && nc?('i') && nc?('l')
              return check_idfr_or_keyword(:fulfil, start)
            end
          # else
          #   return check_idfr_or_keyword(:fu, start)
          end
        end
        scan_idfr(start)
      when 'i'
        case nextch
        when 'f'
          if peek_nextch == 'd'
            nextch
            if nc?('e') && nc?('f')
              return check_idfr_or_keyword(:ifdef, start)
            end
          else
            return check_idfr_or_keyword(:if, start)
          end
        when 'n'
          if idfr_part_or_end?(peek_nextch)
            case nextch
            when 'c'
              if nc?('l') && nc?('u') && nc?('d') && nc?('e')
                return check_idfr_or_keyword(:include, start)
              end
            when 's'
              if nc?('t') && nc?('a') && nc?('n') && nc?('c') && nc?('e') && nc?('_') && nc?('s') && nc?('i') && nc?('z') && nc?('e') && nc?('o') && nc?('f')
                return check_idfr_or_keyword(:instance_sizeof, start)
              end
            end
          else
            nextch
            @token.type = :IDFR
            @token.value = :in
            return @token
          end
        when 's'
          case nextch
          when '_'
            if nc?('a') && nc?('?')
              return check_idfr_or_keyword(:is_a?, start)
            end
          when 'n'
            if nc?('t')
              return check_idfr_or_token(:isnt, "", start)
            end
          else
            set_pos cur_pos - 1
            return check_idfr_or_token(:is, "", start)
          end
        end
        scan_idfr(start)
      when 'l'
        case nextch
        when 'e'
          if nc?('t')
            return check_idfr_or_keyword(:let, start)
          end
        when 'i'
          case nextch
          when 'b'
            return check_idfr_or_keyword(:lib, start)
          when 'k'
            if nc?('e') && nc?('l') && nc?('y')
              return check_idfr_or_keyword(:likely, start)
            end
          end
        end
        scan_idfr(start)
      when 'm'
        case nextch
        when 'a'
          case nextch
          when 'c'
            if nc?('r') && nc?('o')
              return check_idfr_or_keyword(:macro, start)
            end
          when 't'
            if nc?('c') && nc?('h')
              return check_idfr_or_keyword(:match, start)
            end
          end
        when 'i'
          if nc?('x') && nc?('i') && nc?('n')
            return check_idfr_or_keyword(:mixin, start)
          end
        when 'o'
          case nextch
          when 'd'
            if nc?('u') && nc?('l') && nc?('e')
              return check_idfr_or_keyword(:module, start)
            end
          end
        end
        scan_idfr(start)
      when 'n'
        case nextch
        when 'e'
          if nc?('x') && nc?('t')
            return check_idfr_or_keyword(:next, start)
          end
        when 'i'
          case nextch
          when 'l' then return check_idfr_or_keyword(:nil, start)
          end
        when 'o'
          if nc?('t')
            return check_idfr_or_token(:not, "", start)
          end
        end
        scan_idfr(start)
      when 'o'
        case nextch
        when 'b'
          if nc?('j') && nc?('e') && nc?('c') && nc?('t')
            return check_idfr_or_keyword(:object, start)
          end
        when 'f'
          return check_idfr_or_keyword(:of, start)
        when 'r'
          return check_idfr_or_token(:or, "", start)
        when 'u'
          if nc?('t')
            return check_idfr_or_keyword(:out, start)
          end
        end
        scan_idfr(start)
      when 'p'
        case nextch
        when 'o'
          if nc?('i') && nc?('n') && nc?('t') && nc?('e') && nc?('r') && nc?('o') && nc?('f')
            return check_idfr_or_keyword(:pointerof, start)
          end
        when 'r'
          case nextch
          when 'i'
            if nc?('v') && nc?('a') && nc?('t') && nc?('e')
              return check_idfr_or_keyword(:private, start)
            end
          when 'o'
            if nc?('t') && nc?('e') && nc?('c') && nc?('t') && nc?('e') && nc?('d')
              return check_idfr_or_keyword(:protected, start)
            end
          end
        end
        scan_idfr(start)
      when 'r'
        case nextch
        when 'a'
          if nc?('w')
            return check_idfr_or_keyword(:raw, start)
          end
        when 'e'
          case nextch
          when 'f'
            return check_idfr_or_keyword(:ref, start)
          when 's'
            case nextch
            when 'c'
              if nc?('u') && nc?('e')
                return check_idfr_or_keyword(:rescue, start)
              end
            when 'p'
              if nc?('o') && nc?('n') && nc?('d') && nc?('s') && nc?('_') && nc?('t') && nc?('o') && nc?('?')
                return check_idfr_or_keyword(:responds_to?, start)
              end
            end
          when 't'
            if nc?('u') && nc?('r') && nc?('n')
              return check_idfr_or_keyword(:return, start)
            end
          when 'q'
            if nc?('u') && nc?('i') && nc?('r') && nc?('e')
              return check_idfr_or_keyword(:require, start)
            end
          end
        end
        scan_idfr(start)
      when 's'
        case nextch
        when 'e'
          if nc?('l') && nc?('f')
            return check_idfr_or_keyword(:self, start)
          end
        when 'i'
          if nc?('z') && nc?('e') && nc?('o') && nc?('f')
            return check_idfr_or_keyword(:sizeof, start)
          end
        when 't'
          case nextch
          when 'r'
            if nc?('u') && nc?('c') && nc?('t')
              return check_idfr_or_keyword(:struct, start)
            end
          when 'e'
            if nc?('p')
              return check_idfr_or_keyword(:step, start)
            end
          end
        when 'u'
          case nextch
          when 'p'
            if  nc?('e') && nc?('r')
              return check_idfr_or_keyword(:super, start)
            end
          when 'm'
            return check_idfr_or_keyword(:sum, start)
          end
        end
        scan_idfr(start)
      when 't'
        case nextch
        when 'h'
          case nextch
          when 'e'
            if nc?('n')
              return check_idfr_or_keyword(:then, start)
            end
          when 'i'
            if nc?('s')
              return check_idfr_or_keyword(:this, start)
            end
          end
        when 'i'
          if nc?('l')
            return check_idfr_or_keyword(:til, start)
          end
        when 'o'
          return check_idfr_or_keyword(:to, start)
        when 'r'
          case nextch
          when 'a'
            if nc?('i') && nc?('t')
              return check_idfr_or_keyword(:trait, start)
            end
          when 'u'
            if nc?('e')
              return check_idfr_or_keyword(:true, start)
            end
          when 'y'
            return check_idfr_or_keyword(:try, start)
          end
        when 'y'
          if nc?('p') && nc?('e')
            if peek_nextch == 'o'
              nextch
              if nc?('f')
                return check_idfr_or_keyword(:typeof, start)
              end
            else
              return check_idfr_or_keyword(:type, start)
            end
          end
        end
        scan_idfr(start)
      when 'u'
        if nc?('n')
          case nextch
          when 'i'
            if nc?('o') && nc?('n')
              return check_idfr_or_keyword(:union, start)
            end
          when 'l'
            case nextch
            when 'i'
              if nc?('k') && nc?('e') && nc?('l') && nc?('y')
                return check_idfr_or_keyword(:unlikely, start)
              end
            when 'e'
              if nc?('s') && nc?('s')
                return check_idfr_or_keyword(:unless, start)
              end
            end
          when 't'
            if nc?('i') && nc?('l')
              return check_idfr_or_keyword(:until, start)
            end
          end
        end
        scan_idfr(start)
      when 'v'
        if nc?('a') && nc?('l')
          if (peek_next_char == 'u') && nc?('u') && nc?('e')
            return check_idfr_or_keyword(:value, start)
          else
            return check_idfr_or_keyword(:val, start)
          end
        end
        scan_idfr(start)
      when 'w'
        case nextch
        when 'h'
          case nextch
          when 'e'
            if nc?('n')
              return check_idfr_or_keyword(:when, start)
            end
          when 'i'
            if nc?('l') && nc?('e')
              return check_idfr_or_keyword(:while, start)
            end
          end
        when 'i'
          if nc?('t') && nc?('h')
            return check_idfr_or_keyword(:with, start)
          end
        end
        scan_idfr(start)
      when 'y'
        if nc?('i') && nc?('e') && nc?('l') && nc?('d')
          return check_idfr_or_keyword(:yield, start)
        end
        scan_idfr(start)
      when '_'
        case nextch
        when '_'
          case nextch
          when 'D'
            if nc?('I') && nc?('R') && nc?('_') && nc?('_')
              if idfr_part_or_end?(peek_nextch)
                scan_idfr(start)
              else
                nextch
                @token.type = :__DIR__
                return @token
              end
            end
          when 'F'
            if nc?('I') && nc?('L') && nc?('E') && nc?('_') && nc?('_')
              if idfr_part_or_end?(peek_nextch)
                scan_idfr(start)
              else
                nextch
                @token.type = :__FILE__
                return @token
              end
            end
          when 'L'
            if nc?('I') && nc?('N') && nc?('E') && nc?('_') && nc?('_')
              if idfr_part_or_end?(peek_nextch)
                scan_idfr(start)
              else
                nextch
                @token.type = :__LINE__
                return @token
              end
            end
          end
        else
          unless idfr_part?(curch)
            @token.type = :UNDERSCORE
            return @token
          end
        end

        scan_idfr(start)
      else
        if 'A' <= curch <= 'Z'
          start = cur_pos


          # *TODO* Int, Real, Class should be removed again

          case curch
          when 'C'
            if nc?('l') && nc?('a') && nc?('s') && nc?('s')
              return check_const_or_token(:Class, start)
            end
          when 'I'
            if nc?('n') && nc?('t')
              return check_const_or_token(:Int, start)
            end
          when 'R'
            if nc?('e') && nc?('a') && nc?('l')
              return check_const_or_token(:Real, start)
            end
          when 'S'
            if nc?('e') && nc?('l') && nc?('f')
              return check_const_or_token(:Self, start)
            end
          when 'T'
            if nc?('y') && nc?('p') && nc?('e')
              return check_const_or_token(:Type, start)
            end

          else
            nextch

          end

          while idfr_part?(curch)
            nextch
            # Nothing to do
          end
          @token.type = :CONST
          @token.value = string_range(start)
        elsif ('a' <= curch <= 'z') || curch == '_' || curch == '-' || curch.ord > 0x9F
          nextch
          scan_idfr(start)
        else
          unknown_token
        end
      end

      if reset_regex_flags
        @wants_regex = true
        @slash_is_regex = false
      end

      @token

    ensure
      unless @token.type == :SPACE || @token.type == :NEWLINE || @token_type == :INDENT
        #p "resets continuation state"
        @next_token_continuation_state = :AUTO
      end
      dbg_lex ("(" + @token.line_number.to_s + ":" + @token.column_number.to_s +
              "  (#{@line_number}:#{@column_number}): '" + @token.type.to_s +
              "' : '" + @token.value.to_s + "' )").blue
    end


    def token_end_location
      @token_end_location ||= Location.new(@line_number, @column_number - 1, @filename)
    end

    def slash_is_regex!
      @slash_is_regex = true
    end

    def slash_is_not_regex!
      @slash_is_regex = false
    end

    def scan_heredoc_delimiter
      here = MemoryIO.new(20)

      while peek_next_char == ' '
        nextch
      end

      while true
        case char = nextch
        when '\n'
          @line_number += 1
          @column_number = 0
          break
        when '\\'
          if peek_nextch == 'n'
            nextch
            raise "invalid delimiter identifier"
          end
        when ' '
          case peek_nextch
          when ' '
            nextch
          when '\n'
            nextch
            break
          else
            raise "invalid delimiter identifier"
          end
        else
          here << char
        end
      end

      here.to_s
    end

    def handle_comment
      # Comments to skip or consume?
      dbg_lex "Is it '-'?"
      return false if !(curch == '-' || curch == '—')
      dbg_lex "Is it 2nd '-'?"
      return false if !(peek_nextch == '-' || curch == '—')
      dbg_lex "Was prev SPC?"
      if cur_pos > 1
        prevc = unsafe_char_at(cur_pos - 1)
        dbg_lex "It is '" + prevc + "'"
        return false if !(prevc == ' ' || prevc == '\n' || prevc == '\t') # We know '-' and ' ' are one byte each...
      end
      dbg_lex "Yep - comment!"

      # possible_comment_start = cur_pos
      # nextch

      # if nextc_noinc != '-'
      #   cur_pos= possible_comment_start
      #   set_pos possible_comment_start
      #   return false
      # end

      # *TODO* look over this so position is precise!
      nextc_noinc
      start = cur_pos
      char = nextc_noinc

      # Check #<loc:"file",line,column> pragma comment
      if char == '<' &&
         nextc_noinc == 'l' &&
         nextc_noinc == 'o' &&
         nextc_noinc == 'c' &&
         nextc_noinc == ':' &&
         nextc_noinc == '"'
        nextc_noinc
        consume_loc_pragma
        start = cur_pos

        return true
      else # elsif char == ' ' || char == '|'
        if @doc_enabled
          consume_doc
        elsif @comments_enabled
          return consume_comment(start)
        else
          skip_comment
        end

        return true
      end
    end

    def consume_comment(start_pos)
      skip_comment
      @token.type = :COMMENT
      @token.value = string_range(start_pos)
      @token
    end

    def consume_doc
      char = curch
      start_pos = cur_pos

      # Ignore first whitespace after comment, like in `# some doc`
      if char == ' '
        char = nextch
        start_pos = cur_pos
      end

      while char != '\n' && char != '\0'
        char = nextc_noinc
      end

      if doc_buffer = @token.doc_buffer
        doc_buffer << '\n'
      else
        @token.doc_buffer = doc_buffer = MemoryIO.new
      end

      doc_buffer.write slice_range(start_pos)
    end

    def skip_comment
      char = curch
      while char != '\n' && char != '\0'
        char = nextc_noinc
      end
    end

    def consume_whitespace(start_pos = cur_pos)
      # p "consume_whitespace"

      # start_pos = cur_pos
      @token.type = :SPACE
      nextch
      while true
        case curch
        when ' ', '\t'
          # p "consume_whitespace: got ' '|'\\t'"
          nextch
          # *TODO* verify - REALLY?? Leave it to top level parse??
        when '\\'
          dbg_ind  "consume_whitespace: got backslash '\\'"
          if peek_nextch == '\n'
            dbg_ind "consume_whitespace: got '\\n'"
            nextch
            nextch
            @line_number += 1
            @column_number = 1
            @token.passed_backslash_newline = true
          else
            break
            #scan_pragma cur_pos - 1
          end
        else
        # p "consume_whitespace: done"
          break
        end
      end
      if @count_whitespace
        # p "consume_whitespace: counts spaces"
        @token.value = string_range(start_pos)
      end
      # p "consume_whitespace: all done"

    end

    def consume_newlines
      if @count_whitespace
        return
      end

      while true
        case curch
        when '\n'
          nextc_noinc
          @line_number += 1
          @token.doc_buffer = nil
        when '\r'
          if nextc_noinc != '\n'
            raise "expected '\\n' after '\\r'"
          end
          nextc_noinc
          @line_number += 1
          @token.doc_buffer = nil
        else
          break
        end
      end
    end

    def check_const_or_token(symbol, start)
      if idfr_part_or_end?(peek_nextch)
        scan_idfr(start, false, false)
        @token.type = :CONST
      else
        nextch
        @token.type = :CONST
        @token.value = symbol
      end
      @token
    end

    def check_idfr_or_keyword(symbol, start)
      if idfr_part_or_end?(peek_nextch)
        scan_idfr(start)
      else
        nextch
        @token.type = :IDFR
        @token.value = symbol
      end
      @token
    end

    def check_idfr_or_token(type, symbol, start)
      # p "check_idfr_or_token, peek: '" + peek_nextch + "'"
      if idfr_part_or_end?(peek_nextch)
        scan_idfr(start, true, false)
      else
        nextch
        @token.type = type
        @token.value = symbol
      end
      @token
    end

    def scan_idfr(start, special_end_chars = true, do_magic = true, special_start_char = false) : Nil
      if special_start_char && curch == '!'
        nextch
      end

      while idfr_part?(curch)
        nextch
      end
      if special_end_chars
        case curch
        when '!', '?'
          nextch
        end
      end
      @token.type = :IDFR

      idfr_str = string_range start

      @token.value = String.build idfr_str.size * 2, do |str|
        idfr_str.each_char_with_index do |chr, i|
          if chr == '-'
            str << '_'

          elsif chr == '–'
            str << '_'

          elsif do_magic &&
                  'A' <= chr <= 'Z' &&
                  (i != 0 && !(['\\', '!'].includes?(idfr_str[i - 1])))
            str << '_'
            str << chr.downcase
          else
            str << chr
          end
        end
      end

      # p "scanned idfr: '#{@token.value}'"
      nil
    end

    # def scan_pragma(start)
    #   start += 1
    #   # p "scan_pragma for '#{string_range(start)}'"
    #   scan_idfr start, false, special_start_char: true
    #   @token.type = :PRAGMA
    #   @token
    # end

    def symbol_then_nextch(value)
      nextch
      symbol value
    end

    def symbol(value)
      @token.type = :SYMBOL
      @token.value = value
      @token.raw = ":#{value}" if @wants_raw
    end

    def scan_number(start, negative = false)
      @token.type = :NUMBER

      has_underscore = false
      is_integer = true
      has_suffix = true
      suffix_size = 0

      while true
        char = nextch
        if char.digit?
          # Nothing to do
        elsif char == '_'
          has_underscore = true
        else
          break
        end
      end

      case curch
      when '.'
        if peek_nextch.digit?
          is_integer = false

          while true
            char = nextch
            if char.digit?
              # Nothing to do
            elsif char == '_'
              has_underscore = true
            else
              break
            end
          end

          if curch == 'e' || curch == 'E'
            nextch

            if curch == '+' || curch == '-'
              nextch
            end

            while true
              if curch.digit?
                # Nothing to do
              elsif curch == '_'
                has_underscore = true
              else
                break
              end
              nextch
            end
          end

          if curch == 'f' || curch == 'F'
            suffix_size = consume_float_suffix
          else
            @token.number_kind = :real
          end
        else
          @token.number_kind = :int
          has_suffix = false
        end
      when 'e', 'E'
        is_integer = false
        nextch

        if curch == '+' || curch == '-'
          nextch
        end

        while true
          if curch.digit?
            # Nothing to do
          elsif curch == '_'
            has_underscore = true
          else
            break
          end
          nextch
        end

        if curch == 'f' || curch == 'F'
          suffix_size = consume_float_suffix
        else
          @token.number_kind = :real
        end
      when 'f', 'F'
        is_integer = false
        suffix_size = consume_float_suffix
      when 'i'
        suffix_size = consume_int_suffix
      when 'u'
        suffix_size = consume_uint_suffix
      else
        has_suffix = false
        @token.number_kind = :int
      end

      end_pos = cur_pos - suffix_size

      string_value = string_range(start, end_pos)
      string_value = string_value.delete('_') if has_underscore

      if is_integer
        num_size = string_value.size
        num_size -= 1 if negative

        if has_suffix
          check_integer_literal_fits_in_size string_value, num_size, negative, start
        else
          deduce_integer_kind string_value, num_size, negative, start
        end
      end

      @token.value = string_value
      set_token_raw_from_start(start)
    end

    macro gen_check_int_fits_in_size(type, method, size)
      if num_size >= {{size}}
        int_value = absolute_integer_value(string_value, negative)
        max = {{type}}::MAX.{{method}}
        max += 1 if negative

        if int_value > max
          raise "#{string_value} doesn't fit in an {{type}}", @token, (cur_pos - start)
        end
      end
    end

    macro gen_check_uint_fits_in_size(type, size)
      if negative
        raise "Invalid negative value #{string_value} for {{type}}"
      end

      if num_size >= {{size}}
        int_value = absolute_integer_value(string_value, negative)
        if int_value > {{type}}::MAX
          raise "#{string_value} doesn't fit in an {{type}}", @token, (cur_pos - start)
        end
      end
    end

    def check_integer_literal_fits_in_size(string_value, num_size, negative, start)
      case @token.number_kind
      when :i8
        gen_check_int_fits_in_size Int8, to_u8, 3
      when :u8
        gen_check_uint_fits_in_size UInt8, 3
      when :i16
        gen_check_int_fits_in_size Int16, to_u16, 5
      when :u16
        gen_check_uint_fits_in_size UInt16, 5
      when :i32
        gen_check_int_fits_in_size Int32, to_u32, 10
      when :u32
        gen_check_uint_fits_in_size UInt32, 10
      when :i64
        gen_check_int_fits_in_size Int64, to_u64, 19
      when :u64
        if negative
          raise "Invalid negative value #{string_value} for UInt64"
        end

        check_value_fits_in_uint64 string_value, num_size, start
      end
    end

    def deduce_integer_kind(string_value, num_size, negative, start)
      check_value_fits_in_uint64 string_value, num_size, start

      if num_size >= 10
        int_value = absolute_integer_value(string_value, negative)

        int64max = Int64::MAX.to_u64
        int64max += 1 if negative

        int32max = Int32::MAX.to_u32
        int32max += 1 if negative

        if int_value > int64max
          @token.number_kind = :u64
        elsif int_value > int32max
          @token.number_kind = :i64
        end
      end
    end

    def absolute_integer_value(string_value, negative)
      if negative
        string_value[1..-1].to_u64
      else
        string_value.to_u64
      end
    end

    def check_value_fits_in_uint64(string_value, num_size, start)
      if num_size > 20
        raise_value_doesnt_fit_in_uint64 string_value, start
      end

      if num_size == 20
        i = 0
        "18446744073709551615".each_byte do |byte|
          string_byte = string_value.byte_at(i)
          if string_byte > byte
            raise_value_doesnt_fit_in_uint64 string_value, start
          elsif string_byte < byte
            break
          end
          i += 1
        end
      end
    end

    def raise_value_doesnt_fit_in_uint64(string_value, start)
      raise "#{string_value} doesn't fit in an UInt64", @token, (cur_pos - start)
    end

    def scan_zero_number(start, negative = false)
      case peek_nextch
      when 'x'
        scan_hex_number(start, negative)
      when 'o'
        scan_octal_number(start, negative)
      when 'b'
        scan_bin_number(start, negative)
      when '.'
        scan_number(start)
      when 'i'
        @token.type = :NUMBER
        @token.value = "0"
        nextch
        consume_int_suffix
        set_token_raw_from_start(start)
      when 'f'
        @token.type = :NUMBER
        @token.value = "0"
        nextch
        consume_float_suffix
        set_token_raw_from_start(start)
      when 'u'
        @token.type = :NUMBER
        @token.value = "0"
        nextch
        consume_uint_suffix
        set_token_raw_from_start(start)
      when '_'
        case peek_nextch
        when 'i'
          @token.type = :NUMBER
          @token.value = "0"
          nextch
          consume_int_suffix
          set_token_raw_from_start(start)
        when 'f'
          @token.type = :NUMBER
          @token.value = "0"
          nextch
          consume_float_suffix
        when 'u'
          @token.type = :NUMBER
          @token.value = "0"
          nextch
          consume_uint_suffix
        else
          scan_number(start)
        end
      else
        if nextch.digit?
          raise "octal constants should be prefixed with 0o"
        else
          finish_scan_prefixed_number 0_u64, false, start
        end
      end
    end

    def scan_bin_number(start, negative)
      nextch

      num = 0_u64
      while true
        case nextch
        when '0'
          num *= 2
        when '1'
          num = num * 2 + 1
        when '_'
          # Nothing
        else
          break
        end
      end

      finish_scan_prefixed_number num, negative, start
    end

    def scan_octal_number(start, negative)
      nextch

      num = 0_u64

      while true
        char = nextch
        if '0' <= char <= '7'
          num = num * 8 + (char - '0')
        elsif char == '_'
        else
          break
        end
      end

      finish_scan_prefixed_number num, negative, start
    end

    def scan_hex_number(start, negative = false)
      nextch

      num = 0_u64
      while true
        char = nextch
        if char == '_'
        else
          hex_value = char_to_hex(char) { nil }
          if hex_value
            num = num * 16 + hex_value
          else
            break
          end
        end
      end

      finish_scan_prefixed_number num, negative, start
    end

    def finish_scan_prefixed_number(num, negative, start)
      if negative
        string_value = (-1 * num.to_i64).to_s
      else
        string_value = num.to_s
      end

      name_size = string_value.size
      name_size -= 1 if negative

      case curch
      when 'i'
        consume_int_suffix
        check_integer_literal_fits_in_size string_value, name_size, negative, start
      when 'u'
        consume_uint_suffix
        check_integer_literal_fits_in_size string_value, name_size, negative, start
      else
        @token.number_kind = :int
        deduce_integer_kind string_value, name_size, negative, start
      end

      first_byte = @reader.string.byte_at(start)
      if first_byte === '+'
        string_value = "+#{string_value}"
      elsif first_byte === '-' && num == 0
        string_value = "-0"
      end

      @token.type = :NUMBER
      @token.value = string_value
      set_token_raw_from_start(start)
    end

    def consume_int_suffix
      case nextch
      when '8'
        nextch
        @token.number_kind = :i8
        2
      when '1'
        if nc?('6')
          nextch
          @token.number_kind = :i16
          3
        else
          raise "invalid int suffix"
        end
      when '3'
        if nc?('2')
          nextch
          @token.number_kind = :i32
          3
        else
          raise "invalid int suffix"
        end
      when '6'
        if nc?('4')
          nextch
          @token.number_kind = :i64
          3
        else
          raise "invalid int suffix"
        end
      else
        raise "invalid int suffix"
      end
    end

    def consume_uint_suffix
      case nextch
      when '8'
        nextch
        @token.number_kind = :u8
        2
      when '1'
        if nc?('6')
          nextch
          @token.number_kind = :u16
          3
        else
          raise "invalid uint suffix"
        end
      when '3'
        if nc?('2')
          nextch
          @token.number_kind = :u32
          3
        else
          raise "invalid uint suffix"
        end
      when '6'
        if nc?('4')
          nextch
          @token.number_kind = :u64
          3
        else
          raise "invalid uint suffix"
        end
      else
        raise "invalid uint suffix"
      end
    end

    def consume_float_suffix
      case nextch
      when '3'
        if nc?('2')
          nextch
          @token.number_kind = :f32
          3
        else
          raise "invalid float suffix"
        end
      when '6'
        if nc?('4')
          nextch
          @token.number_kind = :f64
          3
        else
          raise "invalid float suffix"
        end
      else
        raise "invalid float suffix"
      end
    end

    def next_string_token(delimiter_state)
      start = current_pos
      string_end = delimiter_state.end
      string_nest = delimiter_state.nest
      string_open_count = delimiter_state.open_count

      case curch
      when '\0'
        raise_unterminated_quoted string_end
      when string_end
        nextch
        if string_open_count == 0
          @token.type = :DELIMITER_END
        else
          @token.type = :STRING
          # @token.literal_style = (delimiter_state.kind == :straight_string ? :straight : :interpolated)
          @token.value = string_end.to_s
          @token.delimiter_state = @token.delimiter_state.with_open_count_delta(-1)
        end
      when string_nest
        nextch
        @token.type = :STRING
        # @token.literal_style = (delimiter_state.kind == :straight_string ? :straight : :interpolated)
        @token.value = string_nest.to_s
        @token.delimiter_state = @token.delimiter_state.with_open_count_delta(+1)
      when '\\'
        if delimiter_state.kind == :regex
          char = nextch
          nextch
          @token.type = :STRING
          # @token.literal_style = (delimiter_state.kind == :straight_string ? :straight : :interpolated)
          @token.value = "\\#{char}"
        else
          case char = nextch
          when 'b'
            string_token_escape_value "\u{8}"
          when 'n'
            string_token_escape_value "\n"
          when 'r'
            string_token_escape_value "\r"
          when 't'
            string_token_escape_value "\t"
          when 'v'
            string_token_escape_value "\v"
          when 'f'
            string_token_escape_value "\f"
          when 'e'
            string_token_escape_value "\e"
          when 'u'
            value = consume_string_unicode_escape
            nextch
            @token.type = :STRING
            # @token.literal_style = (delimiter_state.kind == :straight_string ? :straight : :interpolated)
            @token.value = value
          when '0', '1', '2', '3', '4', '5', '6', '7'
            char_value = consume_octal_escape(char)
            nextch
            @token.type = :STRING
            # @token.literal_style = (delimiter_state.kind == :straight_string ? :straight : :interpolated)
            @token.value = char_value.chr.to_s
          when '\n'
            @line_number += 1

            # Skip until the next non-whitespace char
            while true
              char = nextch
              case char
              when '\0'
                raise_unterminated_quoted string_end
              when '\n'
                @line_number += 1
              when .whitespace?
                # Continue
              else
                break
              end
            end
            next_string_token delimiter_state
          else
            @token.type = :STRING
            # @token.literal_style = (delimiter_state.kind == :straight_string ? :straight : :interpolated)
            @token.value = curch.to_s
            nextch
          end
        end

      when '{'
        if delimiter_state.kind != :straight_string && delimiter_state.kind != :straight_heredoc
          nextch
          @token.type = :INTERPOLATION_START
        else
          nextch
          @token.type = :STRING
          # @token.literal_style = (delimiter_state.kind == :straight_string ? :straight : :interpolated)
          @token.value = "{"
        end

      when '\n'
        nextch
        @column_number = 1
        @line_number += 1

        if delimiter_state.kind == :heredoc || delimiter_state.kind == :straight_heredoc
          string_end = string_end.to_s
          old_pos = cur_pos
          old_column = @column_number

          while curch == ' '
            nextch
          end

          if string_end.starts_with?(curch)
            reached_end = false

            string_end.each_char do |c|
              unless c == curch
                reached_end = false
                break
              end
              nextch
              reached_end = true
            end

            if reached_end &&
               (curch == '\n' || curch == '\0' || curch == '.')
              @token.type = :DELIMITER_END
            else
              @reader.pos = old_pos
              @column_number = old_column
              next_string_token delimiter_state
            end
          else
            @reader.pos = old_pos
            @column_number = old_column
            @token.type = :STRING
            # @token.literal_style = (delimiter_state.kind == :straight_string ? :straight : :interpolated)
            @token.value = "\n"
          end
        else
          @token.type = :STRING
          # @token.literal_style = (delimiter_state.kind == :straight_string ? :straight : :interpolated)
          @token.value = "\n"
        end
      else
        start = cur_pos
        count = 0
        while curch != string_end &&
              curch != string_nest &&
              curch != '\0' &&
              curch != '\\' &&
              !(curch == '{' && delimiter_state.kind != :straight_string) &&
              curch != '\n'
          nextch
        end

        @token.type = :STRING
        # @token.literal_style = (delimiter_state.kind == :straight_string ? :straight : :interpolated)
        @token.value = string_range(start)
      end

      @token
    end

    def raise_unterminated_quoted(string_end)
      msg = case string_end
            when '`'    then "unterminated command"
            when '/'    then "unterminated regular expression"
            when String then "unterminated heredoc"
            else             "unterminated string literal"
            end
      raise msg, @line_number, @column_number
    end

    def next_macro_token(macro_state, skip_whitespace)
      nest = macro_state.nest
      whitespace = macro_state.whitespace
      delimiter_state = macro_state.delimiter_state
      beginning_of_line = macro_state.beginning_of_line
      comment = macro_state.comment
      yields = false

      if skip_whitespace
        while curch.whitespace?
          whitespace = true
          if curch == '\n'
            @line_number += 1
            @column_number = 0
            beginning_of_line = true
          end
          nextch
        end
      end

      @token.location = nil
      @token.line_number = @line_number
      @token.column_number = @column_number

      start = cur_pos

      if curch == '\0'
        @token.type = :EOF
        return @token
      end

      if curch == '\\' && peek_nextch == '{'
        beginning_of_line = false
        nextch
        start = cur_pos
        if nc?('%')
          while (char = nextch).whitespace?
          end

          case char
          when 'e'
            if nc?('n') && nc?('d') && !idfr_part_or_end?(peek_nextch)
              nextch
              nest -= 1
            end
          when 'f'
            if nc?('o') && nc?('r') && !idfr_part_or_end?(peek_nextch)
              nextch
              nest += 1
            end
          when 'i'
            if nc?('f') && !idfr_part_or_end?(peek_nextch)
              nextch
              nest += 1
            end
          end
        end

        @token.type = :MACRO_LITERAL
        @token.value = string_range(start)
        @token.macro_state = Token::MacroState.new(whitespace, nest, delimiter_state, beginning_of_line, yields, comment)
        return @token
      end

      if curch == '\\' && peek_nextch == '%'
        beginning_of_line = false
        nextch
        nextch
        @token.type = :MACRO_LITERAL
        @token.value = "%"
        @token.macro_state = Token::MacroState.new(whitespace, nest, delimiter_state, beginning_of_line, yields, comment)
        return @token
      end

      if curch == '{'
        case nextch
        when '{'
          beginning_of_line = false
          nextch
          @token.type = :MACRO_EXPRESSION_START
          @token.macro_state = Token::MacroState.new(whitespace, nest, delimiter_state, beginning_of_line, yields, comment)
          return @token
        when '%'
          beginning_of_line = false
          nextch
          @token.type = :MACRO_CONTROL_START
          @token.macro_state = Token::MacroState.new(whitespace, nest, delimiter_state, beginning_of_line, yields, comment)
          return @token
        end
      end

      if comment || (!delimiter_state && curch == '-' && peek_nextch == '-')
        comment = true
        char = curch
        char = nextch if curch == '-'
        char = nextch if curch == '-'
        while true
          case char
          when '\n'
            comment = false
            beginning_of_line = true
            whitespace = true
            nextch
            @line_number += 1
            @column_number = 1
            @token.line_number = @line_number
            @token.column_number = @column_number
            break
          when '{'
            break
          when '\0'
            raise "unterminated macro"
          end
          char = nextch
        end
        @token.type = :MACRO_LITERAL
        @token.value = string_range(start)
        @token.macro_state = Token::MacroState.new(whitespace, nest, delimiter_state, beginning_of_line, yields, comment)
        return @token
      end

      if curch == '%' && idfr_start?(peek_nextch)
        char = nextch
        start = cur_pos
        while idfr_part?(char)
          char = nextch
        end
        @token.type = :MACRO_VAR
        @token.value = string_range(start)
        @token.macro_state = Token::MacroState.new(whitespace, nest, delimiter_state, beginning_of_line, yields, comment)
        return @token
      end

      if !delimiter_state && curch == 'e' && nc?('n')
        beginning_of_line = false
        case nextch
        when 'd'
          if whitespace && !idfr_part_or_end?(peek_nextch)
            if nest == 0
              nextch
              @token.type = :MACRO_END
              @token.macro_state = Token::MacroState.default
              return @token
            else
              nest -= 1
              whitespace = curch.whitespace?
              nextch
            end
          end
        when 'u'
          if !delimiter_state && whitespace && nc?('m') && !idfr_part_or_end?(nextch)
            char = curch
            nest += 1
            whitespace = true
          end
        end
      end

      char = curch

      until char == '{' || char == '\0' || (char == '\\' && ((peek = peek_nextch) == '{' || peek == '%')) || (whitespace && !delimiter_state && char == 'e')
        case char
        when '\n'
          @line_number += 1
          @column_number = 0
          whitespace = true
          beginning_of_line = true
        when '\\'
          char = nextch
          if delimiter_state
            if char == '"'
              char = nextch
            end
            whitespace = false
          else
            whitespace = false
          end
          next
        when '\'', '"'
          if delimiter_state
            delimiter_state = nil if delimiter_state.end == char
          else
            delimiter_state = Token::DelimiterState.new(:string, char, char, 0)
          end
          whitespace = false
        when '%'
          if delimiter_state
            whitespace = false
            break if idfr_start?(peek_nextch)
          else
            case char = peek_nextch
            when '(', '[', '<', '{'
              nextch
              delimiter_state = Token::DelimiterState.new(:string, char, closing_char, 1)
            else
              whitespace = false
              break if idfr_start?(char)
            end
          end
        when '#'
          if delimiter_state
            whitespace = false
          else
            break
          end
        else
          if !delimiter_state && whitespace && char == 'y' && nc?('i') && nc?('e') && nc?('l') && nc?('d') && !idfr_part_or_end?(peek_nextch)
            yields = true
            char = curch
            whitespace = true
            beginning_of_line = false
          elsif !delimiter_state && whitespace && (keyword = check_macro_opening_keyword(beginning_of_line))
            char = curch

            if keyword == :macro && char.whitespace?
              old_pos = @reader.pos
              if nc?('d') && nc?('e') && nc?('f') && !idfr_part_or_end?(peek_nextch)
                char = nextch
              else
                @reader.pos = old_pos
              end
            end

            nest += 1 unless keyword == :abstract_def
            whitespace = true
            beginning_of_line = false
          else
            char = curch

            if delimiter_state
              case char
              when delimiter_state.nest
                delimiter_state = delimiter_state.with_open_count_delta(+1)
              when delimiter_state.end
                delimiter_state = delimiter_state.with_open_count_delta(-1)
                if delimiter_state.open_count == 0
                  delimiter_state = nil
                end
              end
            end

            # If an assignment comes, we accept if/unless/while/until as nesting
            if char == '=' && peek_nextch.whitespace?
              whitespace = false
              beginning_of_line = true
            else
              whitespace = char.whitespace? || char == ';' || char == '(' || char == '[' || char == '{'
              if beginning_of_line && !whitespace
                beginning_of_line = false
              end
            end
          end
        end
        char = nextch
      end

      @token.type = :MACRO_LITERAL
      @token.value = string_range(start)
      @token.macro_state = Token::MacroState.new(whitespace, nest, delimiter_state, beginning_of_line, yields, comment)

      @token
    end

    def check_macro_opening_keyword(beginning_of_line)
      case char = curch
      when 'a'
        if nc?('b') && nc?('s') && nc?('t') && nc?('r') && nc?('a') && nc?('c') && nc?('t') && nextch.whitespace?
          case nextch
          when 'd'
            nc?('e') && nc?('f') && peek_not_idfr_part_or_end_nextch && :abstract_def
          when 'c'
            nc?('l') && nc?('a') && nc?('s') && nc?('s') && peek_not_idfr_part_or_end_nextch && :abstract_class
          when 's'
            nc?('t') && nc?('r') && nc?('u') && nc?('c') && nc?('t') && peek_not_idfr_part_or_end_nextch && :abstract_struct
          end
        end
      when 'b'
        nc?('e') && nc?('g') && nc?('i') && nc?('n') && peek_not_idfr_part_or_end_nextch && :begin
      when 'c'
        (char = nextch) && (
          (char == 'a' && nc?('s') && nc?('e') && peek_not_idfr_part_or_end_nextch && :case) ||
            (char == 'l' && nc?('a') && nc?('s') && nc?('s') && peek_not_idfr_part_or_end_nextch && :class)
        )
      when 'd'
        (char = nextch) &&
          ((char == 'o' && peek_not_idfr_part_or_end_nextch && :do) ||
            (char == 'e' && nc?('f') && peek_not_idfr_part_or_end_nextch && :def))
      when 'f'
        nc?('u') && nc?('n') && peek_not_idfr_part_or_end_nextch && :fun
      when 'i'
        beginning_of_line && nc?('f') &&
          (char = nextch) && (
          (!idfr_part_or_end?(char) && :if) ||
            (char == 'd' && nc?('e') && nc?('f') && peek_not_idfr_part_or_end_nextch && :ifdef)
        )
      when 'l'
        nc?('i') && nc?('b') && peek_not_idfr_part_or_end_nextch && :lib
      when 'm'
        (char = nextch) && (
          (char == 'a' && nc?('c') && nc?('r') && nc?('o') && peek_not_idfr_part_or_end_nextch && :macro) ||
            (char == 'o' && nc?('d') && nc?('u') && nc?('l') && nc?('e') && peek_not_idfr_part_or_end_nextch && :module)
        )
      when 's'
        nc?('t') && nc?('r') && nc?('u') && nc?('c') && nc?('t') && !idfr_part_or_end?(peek_nextch) && nextch && :struct
      when 'u'
        nc?('n') && (char = nextch) && (
          (char == 'i' && nc?('o') && nc?('n') && peek_not_idfr_part_or_end_nextch && :union) ||
            (beginning_of_line && char == 'l' && nc?('e') && nc?('s') && nc?('s') && peek_not_idfr_part_or_end_nextch && :unless) ||
            (beginning_of_line && char == 't' && nc?('i') && nc?('l') && peek_not_idfr_part_or_end_nextch && :until)
        )
      when 'w'
        beginning_of_line && nc?('h') && nc?('i') && nc?('l') && nc?('e') && peek_not_idfr_part_or_end_nextch && :while
      else
        false
      end
    end

    def consume_octal_escape(char)
      char_value = char - '0'
      count = 1
      while count <= 3 && '0' <= peek_nextch < '8'
        nextch
        char_value = char_value * 8 + (curch - '0')
        count += 1
      end
      char_value
    end

    def consume_char_unicode_escape
      char = peek_nextch
      if char == '{'
        nextch
        consume_braced_unicode_escape
      else
        consume_non_braced_unicode_escape
      end
    end

    def consume_string_unicode_escape
      char = peek_nextch
      if char == '{'
        nextch
        consume_string_unicode_brace_escape
      else
        consume_non_braced_unicode_escape.chr.to_s
      end
    end

    def consume_string_unicode_brace_escape
      String.build do |str|
        while true
          str << consume_braced_unicode_escape(allow_spaces: true).chr
          break unless curch == ' '
        end
      end
    end

    def consume_non_braced_unicode_escape
      codepoint = 0
      4.times do
        hex_value = char_to_hex(nextch) { expected_hexacimal_character_in_unicode_escape }
        codepoint = 16 * codepoint + hex_value
      end
      codepoint
    end

    def consume_braced_unicode_escape(allow_spaces = false)
      codepoint = 0
      found_curly = false
      found_space = false
      found_digit = false
      char = '\0'

      6.times do
        char = nextch
        case char
        when '}'
          found_curly = true
          break
        when ' '
          if allow_spaces
            found_space = true
            break
          else
            expected_hexacimal_character_in_unicode_escape
          end
        else
          hex_value = char_to_hex(char) { expected_hexacimal_character_in_unicode_escape }
          codepoint = 16 * codepoint + hex_value
          found_digit = true
        end
      end

      if !found_digit
        expected_hexacimal_character_in_unicode_escape
      elsif codepoint > 0x10FFFF
        raise "invalid unicode codepoint (too large)"
      end

      unless found_space
        unless found_curly
          char = nextch
        end

        unless char == '}'
          raise "expected '}' to close unicode escape"
        end
      end

      codepoint
    end

    def expected_hexacimal_character_in_unicode_escape
      raise "expected hexadecimal character in unicode escape"
    end

    def string_token_escape_value(value)
      nextch
      @token.type = :STRING
      @token.value = value
    end

    def delimited_pair(kind, string_nest, string_end, start)
      next_char
      @token.type = :DELIMITER_START
      @token.delimiter_state = Token::DelimiterState.new(kind, string_nest, string_end, 0)
      set_token_raw_from_start(start)
    end

    def next_string_array_token
      while true
        if curch == '\n'
          nextch
          @column_number = 1
          @line_number += 1
        elsif curch.whitespace?
          nextch
        else
          break
        end
      end

      if curch == @token.delimiter_state.end
        nextch
        @token.type = :STRING_ARRAY_END
        return @token
      end

      start = cur_pos
      while !curch.whitespace? && curch != '\0' && curch != @token.delimiter_state.end
        nextch
      end

      @token.type = :STRING
      @token.value = string_range(start)

      @token
    end

    def char_to_hex(char)
      if '0' <= char <= '9'
        char - '0'
      elsif 'a' <= char <= 'f'
        10 + (char - 'a')
      elsif 'A' <= char <= 'F'
        10 + (char - 'A')
      else
        yield
      end
    end

    def consume_loc_pragma
      filename_pos = cur_pos

      while true
        case curch
        when '"'
          break
        when '\0'
          raise "unexpected end of file in loc pragma"
        else
          nextc_noinc
        end
      end

      filename = string_range(filename_pos)

      # skip '"'
      nextch

      unless curch == ','
        raise "expected ',' in loc pragma after filename"
      end
      nextch

      line_number = 0
      while true
        case curch
        when '0'..'9'
          line_number = 10 * line_number + (curch - '0').to_i
        when ','
          nextch
          break
        else
          raise "expected digit or ',' in loc pragma for line number"
        end
        nextch
      end

      column_number = 0
      while true
        case curch
        when '0'..'9'
          column_number = 10 * column_number + (curch - '0').to_i
        when '>'
          nextch
          break
        else
          raise "expected digit or '>' in loc pragma for column_number number"
        end
        nextch
      end

      @token.filename = @filename = filename
      @token.line_number = @line_number = line_number
      @token.column_number = @column_number = column_number
    end

    def nextc_noinc
      @reader.next_char
    end

    def nextch
      @column_number += 1
      nextc_noinc
    end

    def next_char # *TODO* alias
      @column_number += 1
      nextc_noinc
    end

    def nc?(char)
      nextch == char
    end

    def nextc_check_line
      @column_number += 1
      char = nextc_noinc
      if char == '\n'
        @line_number += 1
        @column_number = 1
      end
      char
    end

    def toktype_then_nextch(token_type)
      nextch
      @token.type = token_type
    end

    def reset_token
      @token.value = nil
      @token.line_number = @line_number
      @token.column_number = @column_number
      @token.filename = @filename
      @token.location = nil
      @token.passed_backslash_newline = false
      @token.doc_buffer = nil unless @token.type == :SPACE || @token.type == :NEWLINE
      @token_end_location = nil
    end

    def next_token_skip_space
      next_token
      skip_space
    end

    def next_token_skip_space_or_indent
      next_token
      skip_space_or_indent
    end

    def next_token_skip_space_or_newline
      next_token
      skip_space_or_newline
    end

    # def next_token_skip_space_newline_or_indent
    #   next_token
    #   skip_space_newline_or_indent
    # end

    def next_token_skip_statement_end
      next_token
      skip_statement_end
    end

    def curch
      @reader.current_char
    end

    def current_char # *TODO* alias
      @reader.current_char
    end

    def peek_nextch
      @reader.peek_next_char
    end

    def peek_next_char # *TODO* alias
      @reader.peek_next_char
    end

    def cur_pos
      @reader.pos
    end

    def current_pos # *TODO* alias
      @reader.pos
    end

    def set_pos(pos)
      @reader.pos = pos
    end

    def cur_pos=(pos)
      @reader.pos = pos
    end

    def current_pos=(pos) # *TODO* alias
      @reader.pos = pos
    end

    def string
      @reader.string
    end

    def string_range(start_pos)
      string_range(start_pos, cur_pos)
    end

    def string_range(start_pos, end_pos)
      @reader.string.byte_slice(start_pos, end_pos - start_pos)
    end

    def slice_range(start_pos)
      Slice.new(@reader.string.to_unsafe + start_pos, cur_pos - start_pos)
    end

    def unsafe_char_at(i)
      @reader.unsafe_decode_char_at(i)
    end

    def idfr_start?(char)
      char.alpha? || char == '_' || char.ord > 0x9F
    end

    def idfr_part?(char)
      idfr_start?(char) || char.digit? || char == '-'
    end

    def idfr_part_or_end?(char)
      idfr_part?(char) || char == '?' || char == '!'
    end

    def peek_not_idfr_part_or_end_nextch
      !idfr_part_or_end?(peek_nextch) && nextch
    end

    def closing_char(char = curch)
      case char
      when '<' then '>'
      when '(' then ')'
      when '[' then ']'
      when '{' then '}'
      else          char
      end
    end

    def skip_space
      while @token.type == :SPACE
        next_token
      end
    end

    def skip_space_or_indent
      while (@token.type == :SPACE || @token.type == :INDENT)
        next_token
      end
    end

    def skip_space_or_newline
      while (@token.type == :SPACE || @token.type == :NEWLINE)
        next_token
      end
    end

    # def skip_space_newline_semi
    #   while (@token.type == :SPACE  || @token.type == :";" || @token.type == :NEWLINE)
    #     next_token
#
    #   end
    # end

    # def skip_space_newline_or_indent
    #   while (@token.type == :SPACE || @token.type == :NEWLINE || @token.type == :INDENT)
    #     next_token
#
    #   end
    # end

    # def skip_space_semi
    #   while (@token.type == :SPACE || @token.type == :";")
    #     next_token
#
    #   end
    # end

    def skip_statement_end
      while (@token.type == :SPACE || @token.type == :NEWLINE || @token.type == :";")
        next_token
      end
    end

    def unknown_token
      raise "unknown token: #{curch.inspect}", @line_number, @column_number
    end

    def set_token_raw_from_start(start)
      @token.raw = string_range(start) if @wants_raw
    end

    def raise(message, line_number = @line_number, column_number = @column_number, filename = @filename)
      ex = Crystal::SyntaxException.new(message, line_number, column_number, filename)
      @error_stack << ex
      ::raise ex
    end

    def raise(message, token : Token, size = nil)
      ex = Crystal::SyntaxException.new(message, token.line_number, token.column_number, token.filename, size)
      @error_stack << ex
      ::raise ex
    end

    def raise(message, location : Location)
      raise message, location.line_number, location.column_number, location.filename
    end
  end
end
