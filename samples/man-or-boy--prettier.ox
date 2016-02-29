a(k T, x1, x2, x3, x4, x5) ->
   if k <= 0
      x4() + x5()
   else
      b = raw () -> T
      b = () ->
         k -= 1
         a k, b, x1, x2, x3, x4
      b()

say a 10, ()-> 1, ()-> -1, ()-> -1, ()-> 1, ()-> 0
