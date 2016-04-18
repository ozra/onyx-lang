# Some globally polluting ugly helpers
require "../../wild_colors"


ifdef !release
  class DebuggingData
    @@dbg_output_on = false

    def self.dbg_on
      @@dbg_output_on = true
    end

    def self.dbg_off
      @@dbg_output_on = false
    end

    def self.dbg_output_on?
      @@dbg_output_on
    end
  end
  # foo = DebuggingData.new
end

# $dbg_output_on : Bool
# $dbg_output_on = false

def _dbg_on()
  ifdef !release
    # $dbg_output_on = true
    DebuggingData.dbg_on
  end
end

def _dbg_off()
  ifdef !release
    # $dbg_output_on = false
    DebuggingData.dbg_off
  end
end

def _dbg(*objs)
  ifdef !release
    # if $dbg_output_on
    if DebuggingData.dbg_output_on?
      STDERR.puts objs.join ", "
    end
  end
end

def _dbg_overview(*objs)
  ifdef !release
    STDERR.puts objs.join ", "
  end
end

struct Char
  def ord_gt?(v)
    ord > v
  end
end
