# Some globally polluting ugly helpers
require "colorize"

struct Char
  def ord_gt?(v)
    ord > v
  end
end


class String
  def quot
    "\"" + self + "\""
  end

  def red
    self.colorize(:light_red).to_s
  end

  def yellow
    self.colorize(:light_yellow).to_s
  end

  def blue
    self.colorize(:light_blue).to_s
  end

  def white
    self.colorize(:white).to_s
  end

  def magenta
    self.colorize(:light_magenta).to_s
  end

  def cyan
    self.colorize(:light_cyan).to_s
  end

  def green
    self.colorize(:light_green).to_s
  end
end
