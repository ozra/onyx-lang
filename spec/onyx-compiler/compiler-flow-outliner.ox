require "./compiler-flow-mods/mod-one"
require "./compiler-flow-mods/mod-two"
require "./compiler-flow-mods/mod-three-in-cr"

enum Color
    Red
    Blue
end

def do-foo(a, b) ->
    puts "{{a}} {{b}}"

def do-foo(a, b Color) ->
    puts "{{a}} {{b}}"


puts "Compiler Flow Outliner"

do-foo 47, Color::Blue
