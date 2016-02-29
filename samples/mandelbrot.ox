print-plot-density(d) -> print branch d
   .> 8   =>  " "
   .> 6   =>  "."
   .> 4   =>  ":"
   .> 2   =>  "*"
   .> 1   =>  "+"
   *      =>  "x"

mandel-converger(real, imag, iters, creal, cimag) ->
   if iters > 255 or (real * real + imag * imag) >= 4
      iters
   else
      mandel-converger(real * real - imag * imag + creal, 2 * real * imag + cimag, iters + 1, creal, cimag)

mandel-converge(real, imag) -> mandel-converger(real, imag, 0, real, imag)

mandel-help(xmin, xmax, xstep, ymin, ymax, ystep) ->
   ymin.step(ymax, ystep, (y) ~>
      xmin.step(xmax, xstep, (x) ~>
         print-plot-density(mandel-converge(x, y))
      )
      say
   )

mandel(realstart, imagstart, realmag, imagmag) ->
   mandel-help(
      realstart, realstart + realmag * 78, realmag, imagstart,
      imagstart + imagmag * 40, imagmag
   )

mandel(-2.3, -1.3, 0.05, 0.07)
