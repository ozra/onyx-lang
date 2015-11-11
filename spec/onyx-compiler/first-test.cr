
alias Str = String
alias I32 = Int32

# first comment
a = 47  #another comment

    #| weirdly placed comment

# \ foo(a, b, c I32) ->
#     Str(a + b) + c.to_s

def foo(a, b, c : I32)
    (a + b).to_s + c.to_s
end

x = foo a, 2, 3

def bar()
    foo 47, 42, 13
end


class Qwa
end

class Bar < Qwa
    @@RedFoo = 7

    RedBar = 5

    @@self_boo = 47

    @buck :: I32
    @buck = 42
    @qwack :: Array(I32)

    def set_bar(v)
        @my_foo = v
    end

    def self.get_boo()
        @@self_boo
    end

    def self.get_red()
        @@RedFoo
    end
end

puts "1 #{Bar.get_boo}"
puts "2 #{Bar::RedBar}"
puts "3 #{Bar.get_red}"
#puts "4 #{Bar::RedFoo}"
#puts "5 #{Bar.RedFoo}"


def run_code
    yield 3, "Foo"
end

#lambda = ->(a: I32, b: Str) { p 1; return }
lambda = ->(a, b) { p 1; return }
#block = { |a, b| "#{b}: #{a}" }

run_code &lambda
#run_code block
run_code { |a, b| p 1; break }
