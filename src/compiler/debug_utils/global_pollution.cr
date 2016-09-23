# Some globally polluting ugly helpers
require "../../wild_colors"


ifdef !release
  class DebuggingData
    @@dbg_output_on = false
    @@dbg_enabled = true
    @@dbgindent = 0

    def self.dbg_enabled=(v : Bool)
      @@dbg_enabled = v
    end

    def self.dbg_enabled?
      @@dbg_enabled
    end

    def self.dbg_on
      @@dbg_output_on = @@dbg_enabled
    end

    def self.dbg_off
      @@dbg_output_on = false
    end

    def self.dbg_output_on?
      @@dbg_output_on
    end

    def self.dbgindent=(v)
      @@dbgindent = v
    end

    def self.dbgindent
      @@dbgindent
    end
  end
end

macro __do_dbg_puts(*objs)
  __do_dbg_print({{*objs}})
  __low_level_print "\n"
end

DEBUG_INDENT_LIMIT = 16

macro __do_dbg_print(*objs)
  ifdef !release
    begin
      __low_level_print (" " * {DebuggingData.dbgindent, DEBUG_INDENT_LIMIT}.min)
      __low_level_print DebuggingData.dbgindent.to_s + ": "
      {% for o in objs %}
        __low_level_print {{o}}.to_s
      {% end %}
    end
  end
end

macro __low_level_print(*objs)
  STDERR.print({{*objs}})
end

macro _dbg_on()
  ifdef !release
    DebuggingData.dbg_on
  end
end

macro _dbg_off()
  ifdef !release
    DebuggingData.dbg_off
  end
end

macro _dbg_will(&block)
  ifdef !release
    if DebuggingData.dbg_output_on?
      {{block.body}}
    end
  end
end

macro _dbg(*objs)
  ifdef !release
    if DebuggingData.dbg_output_on?
      __do_dbg_puts({{*objs}})
    end
  end
end

macro _dbg_overview(*objs)
  ifdef !release
    if DebuggingData.dbg_enabled?
      __do_dbg_puts({{*objs}})
    end
  end
end

macro _dbg_always(*objs)
  STDERR.puts({{*objs}})
end

macro _dbginc
  ifdef !release
    DebuggingData.dbgindent += 1
  end
end

macro _dbgdec
  ifdef !release
    DebuggingData.dbgindent -= 1
  end
end

struct Char
  def ord_gt?(v)
    ord > v
  end
end


# *TODO* move from here
def fatal(msg : String)
  LibC.printf msg
  CallStack.print_backtrace
  LibC.exit(1)
end


# *TODO* make this a more generic macro as part of `Any`(AnyRef/Reference rather) or such
# then the type will of course be inerted automatically
# also `with`, `borrow` and `leave` should be on `TheType::Pool.do–the–thing`
macro reinit_pool(typ, *params)
  class {{typ}}Pool
    @@pool = [] of {{typ}}

    def self.borrow({{*params}}) : {{typ}}

      # *TODO* *TEMP* *DEBUG* onyx
      ifdef use_this_stuff
        if @@pool.size > 0
          obj = @@pool.pop.not_nil!
          obj.re_init {{*params}}
          obj.not_nil!
        else
          {{typ}}.new {{*params}}
        end
      else
        {{typ}}.new {{*params}}
      end

    end

    def self.with({{*params}}, &block)
      obj = borrow {{*params}}
      ret = yield obj
      leave obj
      ret
    end

    def self.leave(obj : {{typ}}) : Nil

      # *TODO* *TEMP* *DEBUG* onyx
      ifdef use_this_stuff
        @@pool << obj
      end

      nil
    end
  end
end
