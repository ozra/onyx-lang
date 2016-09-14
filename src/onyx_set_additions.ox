require "object"
require "set"

ext Set
   <(other Self) ->  this.proper-subset? other
   <(obj) ->         false

   <=(other Self) -> this.subset? other
   <=(obj) ->        false

   >=(other Self) -> this.superset? other
   >=(obj) ->        this.includes? obj

   >(other Self) ->  this.proper-superset? other
   >(obj) ->         this.size > 1 && this.includes? obj

ext Object
   <(set Set) ->     set > this
   <=(set Set) ->    set >= this
   >(set Set) ->     false
   >=(set Set) ->    false

