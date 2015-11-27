require "./compiler-flow-mods/mod-one"
require "./compiler-flow-mods/mod-two"
require "./compiler-flow-mods/mod-three-in-cr"

enum Color
   Red
   Blue
end

def do-foo(val, color) ->
   puts "{{val}} {{color}}"

def do-foo(val = 47, color = Color) ->
   puts "{{val}} {{color}}"


puts "Compiler Flow Outliner"

do-foo 42, Color.Blue
do-foo #color = Color.Red
