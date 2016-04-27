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
end

def _dbg_on()
  ifdef !release
    DebuggingData.dbg_on
  end
end

def _dbg_off()
  ifdef !release
    DebuggingData.dbg_off
  end
end

# *TODO* *TEMP* until the globals orderings and deps are resolved in Crystal
class StderrWrapperTemp
  @@maybe_stderr : IO::FileDescriptor?
  def self.set_stderr(io)
    @@maybe_stderr = io
  end
  def self.maybe_stderr?
    @@maybe_stderr
  end
end

StderrWrapperTemp.set_stderr STDERR

def _dbg(*objs)
  ifdef !release
    # if $dbg_output_on
    if DebuggingData.dbg_output_on?
      StderrWrapperTemp.maybe_stderr?.try &.puts objs.join ", "
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
