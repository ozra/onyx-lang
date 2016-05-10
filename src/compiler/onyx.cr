# *TODO* make minimal error report on module alias vs macro defs
# module Onyx
# end

# alias Crystal = Onyx

require "./crystal/**"
require "./onyx/**"

Crystal::OnyxCommand.run
