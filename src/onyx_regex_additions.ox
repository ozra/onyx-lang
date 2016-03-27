require "string"
require "regex"

type String
    ~~(regex Regex) ->
        the-match = regex.match self
        $~ = the-match  -- *TODO* this should be expected to _not_ exist for future optimization purposes
        !the-match.nil?
