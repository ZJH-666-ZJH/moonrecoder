///|
pub(all) suberror CodeError {
  Invalid(String)
  Shape(String)
  Limit(String)
  Inconsistent
  Incomplete(Int32)
  Corrupt(String)
  Truncated
}

///|
fn check_symbol(value : Int32) -> Unit raise CodeError {
  if value < 0 || value > 255 {
    raise Invalid("field element must be in 0..255")
  }
}

///|
// Polynomial basis; the ninth bit is reduced by x^8+x^4+x^3+x^2+1.
fn mul(left : Int32, right : Int32) -> Int32 {
  let mut a = left
  let mut b = right
  let mut product = 0
  for _ in 0..<8 {
    if (b & 1) != 0 {
      product = product ^ a
    }
    b = b >> 1
    a = a << 1
    if (a & 256) != 0 {
      a = a ^ 285
    }
  }
  product
}

///|
fn power(value : Int32, exponent : Int32) -> Int32 {
  let mut base = value
  let mut n = exponent
  let mut result = 1
  while n > 0 {
    if (n & 1) != 0 {
      result = mul(result, base)
    }
    base = mul(base, base)
    n = n >> 1
  }
  result
}

///|
pub fn gf_add(left : Int32, right : Int32) -> Int32 raise CodeError {
  check_symbol(left)
  check_symbol(right)
  left ^ right
}

///|
pub fn gf_mul(left : Int32, right : Int32) -> Int32 raise CodeError {
  check_symbol(left)
  check_symbol(right)
  mul(left, right)
}

///|
pub fn gf_inverse(value : Int32) -> Int32 raise CodeError {
  check_symbol(value)
  if value == 0 {
    raise Invalid("zero has no multiplicative inverse")
  }
  power(value, 254)
}

///|
pub fn gf_div(left : Int32, right : Int32) -> Int32 raise CodeError {
  check_symbol(left)
  mul(left, gf_inverse(right))
}

///|
pub fn gf_pow(value : Int32, exponent : Int32) -> Int32 raise CodeError {
  check_symbol(value)
  if exponent < 0 {
    raise Invalid("negative field exponent")
  }
  power(value, exponent)
}

///|
pub fn field_polynomial() -> Int32 {
  285
}
