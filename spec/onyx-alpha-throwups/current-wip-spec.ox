
_debug_compiler_start_ = 1

FooMod: @@val Int = 0 'get 'set

My.Nested:
   type Foo
      @str Str
      @foo = 47
      @bar 'get 'set

      init(@str Str) ->
         @bar = 1

      action(str) -> say str

   Module:
      extend self -- *TODO* should not be needed!
      foo(obj) ->
         obj.action "hey"


OtherModule:
   bar() ->
      My.Nested.Module.foo My.Nested.Foo("Named")

      -- foo new ("Anon")
      --    init(@str Str) ->
      --    action(str) -> say "{@str}: {str}"

OtherModule:
   extend self

   bar

say FooMod.val
FooMod.val = 47
say FooMod.val
