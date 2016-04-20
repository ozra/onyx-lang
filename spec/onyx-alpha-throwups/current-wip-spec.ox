
_debug_compiler_start_ = 1

foo(obj) ->
    obj.action "hey"

type Foo
    init(@str Str) ->
    action(str) -> say str

foo Foo("Named")

foo ("Anon") <:
    init(@str Str) ->
    action(str) -> say "{@str}: {str}"
