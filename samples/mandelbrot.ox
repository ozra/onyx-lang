print-plot-density(d) -> print branch d
   .> 8   =>  " "
   .> 6   =>  "."
   .> 4   =>  ":"
   .> 2   =>  "*"
   .> 1   =>  "+"
   *      =>  "x"

mandelconverger(real, imag, iters, creal, cimag) ->
   if iters > 255 or (real * real + imag * imag) >= 4
      iters
   else
      mandelconverger(real * real - imag * imag + creal, 2 * real * imag + cimag, iters + 1, creal, cimag)

mandelconverge(real, imag) -> mandelconverger(real, imag, 0, real, imag)

mandelhelp(xmin, xmax, xstep, ymin, ymax, ystep) ->
   ymin.step(ymax, ystep, (y) ~>
      xmin.step(xmax, xstep, (x) ~>
         print-plot-density(mandelconverge(x, y))
      )
      puts
   )

mandel(realstart, imagstart, realmag, imagmag) ->
   mandelhelp(
      realstart, realstart + realmag * 78, realmag, imagstart,
      imagstart + imagmag * 40, imagmag
   )

mandel(-2.3, -1.3, 0.05, 0.07)
