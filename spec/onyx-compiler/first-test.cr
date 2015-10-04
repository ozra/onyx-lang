
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
