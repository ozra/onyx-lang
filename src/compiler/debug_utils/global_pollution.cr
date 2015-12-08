# Some globally polluting ugly helpers
require "wild_colors"

struct Char
  def ord_gt?(v)
    ord > v
  end
end
