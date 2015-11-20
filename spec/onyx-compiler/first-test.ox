_debug_start_ = true

-- $.foo = 47
-- say Program.foo

module Djur
   module Boo =>
      APA = 47

      type Apa:
         Type.my-def() -> say "Hit the spot!"
      end

      enum Legs:
         NONE
         TWO
         FOUR
         SIX
         EIGHT

         Type.is-six?(v) ->
            v == SIX
      end
   end
end

Djur::Boo::Apa.my-def
say "Djur::Boo::Legs::TWO = {{Djur::Boo::Legs::TWO}}"

Djur.Boo.Apa.my-def
say "Djur.Boo.Legs.TWO = {{Djur.Boo.Legs.TWO}}"
say "Djur.Boo.Legs.is-six?(EIGHT) = {{Djur.Boo.Legs.is-six?(Djur.Boo.Legs.EIGHT)}}"

list_maps() ->
   -- cmd = "cat /proc/{{Process.pid}}/maps"
   cmd = "cat"
   args = ["/proc/{{Process.pid}}/maps"]

   Process.run cmd, args, |ret|
      say "Ran {{cmd}}"
      -- say ret.output.gets_to_end
      while r = ret.output.gets
         say r.gsub /\s[-r].*\s\s\s*(\/.*\/)?/, "  "
      say "."

list_maps
