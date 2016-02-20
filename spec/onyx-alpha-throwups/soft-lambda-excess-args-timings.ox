
v1t = Time.Span(0)
v2t = Time.Span(0)

10000.times ~>
   t = Time.now
   x = 0
   (0...9999999999999).each-with-index (i) ~>
      x += i * 2

   v1t += Time.now - t

   t = Time.now
   z = 0
   (0...9999999999999).each (i) ~>
      z += i * 2

   v2t += Time.now - t

end

say "each_with_index: {v1t}"
say "each: {v2t}"
say "ewi-e: {v1t - v2t}"
