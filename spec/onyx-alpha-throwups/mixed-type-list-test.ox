values = ["woo", 3, false, 7]

fn2(n Int) -> say "{n}"
fn2(..._ *) -> raise "I wasn't prepared for that type!"

fn2 values.1
fn2 values.3
fn2 values.0
