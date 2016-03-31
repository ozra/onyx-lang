# Some globally polluting ugly helpers
require "wild_colors"

$dbg_output_on = false

def _dbg_on()
    $dbg_output_on = true
end

def _dbg_off()
    $dbg_output_on = false
end

def _dbg(*objs)
  ifdef !release
    if $dbg_output_on
      STDERR.puts objs.join ", "
    end
  end
end

struct Char
  def ord_gt?(v)
    ord > v
  end
end
