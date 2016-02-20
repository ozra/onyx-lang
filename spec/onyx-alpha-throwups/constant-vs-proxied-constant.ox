require "benchmark"

MY_PI = 3.1415

my-pi1() -> MY_PI

'inline
my-pi2() -> MY_PI


Benchmark.ips 4, 10, (x) ~> begins

x.report ~>
    z1 = 1.0
    for x in 1..100000
        z1 = z1 * MY_PI + MY_PI

x.report ~>
    z2 = 1.0
    for x in 1..100000
        z2 = z2 * my-pi1 + my-pi1

x.report ~>
    z3 = 1.0
    for x in 1..100000
        z3 = z3 * my-pi2 + my-pi2

