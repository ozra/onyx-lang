require "object"
require "set"

ext Set
   <(other Self) ->  self.proper-subset? other
   <(obj) ->         false

   <=(other Self) -> self.subset? other
   <=(obj) ->        false

   >=(other Self) -> self.superset? other
   >=(obj) ->        self.includes? obj

   >(other Self) ->  self.proper-superset? other
   >(obj) ->         self.size > 1 && self.includes? obj

ext Any
   <(set Set) ->     set > self
   <=(set Set) ->    set >= self
   >(set Set) ->     false
   >=(set Set) ->    false

