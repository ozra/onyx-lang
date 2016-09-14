# Some globally polluting ugly helpers
require "../../wild_colors"


ifdef !release
  class DebuggingData
    @@dbg_output_on = false
    @@dbg_enabled = true

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
  end
end

macro do_puts(*objs)
  STDERR.puts({{*objs}})
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
      do_puts({{*objs}})
    end
  end
end

macro _dbg_overview(*objs)
  ifdef !release
    if DebuggingData.dbg_enabled?
      do_puts({{*objs}})
    end
  end
end

macro _dbg_always(*objs)
  do_puts({{*objs}})
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
macro reinit_pool(typ, *params)
   class {{typ}}Pool
      @@pool = [] of {{typ}}

      def self.borrow({{*params}}) : {{typ}}
         if @@pool.size > 0
            obj = @@pool.pop.not_nil!
            obj.re_init {{*params}}
            obj.not_nil!
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
         @@pool << obj
         nil
      end
   end
end
