
_debug_compiler_start_ = 1

-- @@glob-val Int = 0 'get 'set

FooMod: @@val Int = 0 'get 'set
FooMod: set-v(v Int) -> @@val = v
FooMod:
   set-v2(@@val Int) ->
   v=(@@val Int) ->
   v = (val Int) -> say "lambda: {val}"
   v 13

My.Nested:
   type Foo
      @@t-var Int = 11 'get 'set
      @str Str
      @foo = 47
      @bar 'get 'set

      init(@str Str = "") ->
         @bar = 1

      foo() -> My.Nested.Foo.t-var
      -- foo() -> Self.t-var  -- *TODO*

      action(str) -> say str

   Module:
      foo(obj) ->
         obj.action "hey"

OtherModule:
   bar() ->
      My.Nested.Module.foo My.Nested.Foo("Named")

      -- foo new ("Anon")
      --    init(@str Str) ->
      --    action(str) -> say "{@str}: {str}"

My:
   Nested:
      ext Foo
         @xoo = 46
         xoo() -> @xoo + 1

OtherModule:
   -- include Self on Self
   bar

pp My.Nested.Foo.t-var
pp My.Nested.Foo().foo
fuu = My.Nested.Foo "Foul"
pp fuu.xoo

say FooMod.val
FooMod.val = 47
say FooMod.val
FooMod.val=(42)
say FooMod.val
FooMod.set-v
   3
say FooMod.val
FooMod.set-v2 7
say FooMod.val
FooMod.v = 23
say FooMod.val

-- pp glob-val
-- glob-val = 43
-- pp glob-val
