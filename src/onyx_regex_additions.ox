require "string"
require "regex"

ext String
    ~~(regex Regex) ->
        the-match = regex.match this
        $~ = the-match  -- *TODO* this should be expected to _not_ exist for future optimization purposes
        not the-match.none?
