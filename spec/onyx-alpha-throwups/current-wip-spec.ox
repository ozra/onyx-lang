
_debug_compiler_start_ = 1


My.Nested:
    type Foo
        init(@str Str) ->
        action(str) -> say str

    Module:
        extend self
        foo(obj) ->
            obj.action "hey"


OtherModule:
    bar() ->
        My.Nested.Module.foo My.Nested.Foo("Named")

        -- foo new ("Anon")
        --     init(@str Str) ->
        --     action(str) -> say "{@str}: {str}"

OtherModule:
    extend self

    bar
