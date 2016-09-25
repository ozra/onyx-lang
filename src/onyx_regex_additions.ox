require "string"
require "regex"

ifdef !disable_ox_libspicing below

ext String
    ~~(regex Regex) ->
        the-match = regex.match this
        $~ = the-match  -- *TODO* this should be expected to _not_ exist for future optimization purposes
        the-match.is?
end

