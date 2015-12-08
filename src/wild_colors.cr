require "colorize"

class String
  def quot
    "\"" + self + "\""
  end

  def gray
    self.colorize(:light_gray).to_s
  end

  def grey
    self.colorize(:light_gray).to_s
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


  def red2
    self.colorize(:red).to_s
  end

  def yellow2
    self.colorize(:yellow).to_s
  end

  def blue2
    self.colorize(:blue).to_s
  end

  def magenta2
    self.colorize(:magenta).to_s
  end

  def cyan2
    self.colorize(:cyan).to_s
  end

  def green2
    self.colorize(:green).to_s
  end

  def gray2
    self.colorize(:dark_gray).to_s
  end

  def grey2
    self.colorize(:dark_gray).to_s
  end

end
