///|
// Immutable-by-API byte symbols. All accessors return detached copies.
pub struct Symbols {
  priv values : Array[Int32]
}

///|
fn copy_values(values : Array[Int32]) -> Array[Int32] {
  let out : Array[Int32] = []
  for value in values {
    out.push(value)
  }
  out
}

///|
pub fn Symbols::new(values : Array[Int32]) -> Symbols raise CodeError {
  if values.length() > 262144 {
    raise Limit("symbol vector exceeds 262144 bytes")
  }
  for value in values {
    check_symbol(value)
  }
  { values: copy_values(values), }
}

///|
pub fn Symbols::zeros(length : Int32) -> Symbols raise CodeError {
  if length < 0 || length > 262144 {
    raise Limit("invalid symbol vector length")
  }
  { values: Array::make(length, 0), }
}

///|
pub fn Symbols::length(self : Symbols) -> Int32 {
  self.values.length()
}

///|
pub fn Symbols::to_array(self : Symbols) -> Array[Int32] {
  copy_values(self.values)
}

///|
pub fn Symbols::at(self : Symbols, index : Int32) -> Int32 raise CodeError {
  if index < 0 || index >= self.length() {
    raise Invalid("symbol index out of range")
  }
  self.values[index]
}

///|
pub fn Symbols::is_zero(self : Symbols) -> Bool {
  for value in self.values {
    if value != 0 {
      return false
    }
  }
  true
}

///|
pub fn Symbols::equal(self : Symbols, other : Symbols) -> Bool {
  if self.length() != other.length() {
    return false
  }
  for i in 0..<self.length() {
    if self.values[i] != other.values[i] {
      return false
    }
  }
  true
}

///|
pub fn Symbols::scale(
  self : Symbols,
  factor : Int32,
) -> Symbols raise CodeError {
  check_symbol(factor)
  { values: self.values.map(v => mul(v, factor)), }
}

///|
pub fn Symbols::axpy(
  self : Symbols,
  factor : Int32,
  other : Symbols,
) -> Symbols raise CodeError {
  check_symbol(factor)
  if self.length() != other.length() {
    raise Shape("vector lengths differ")
  }
  let out = self.to_array()
  for i in 0..<out.length() {
    out[i] = out[i] ^ mul(factor, other.values[i])
  }
  { values: out, }
}

///|
pub fn Symbols::dot(self : Symbols, other : Symbols) -> Int32 raise CodeError {
  if self.length() != other.length() {
    raise Shape("dot product lengths differ")
  }
  let mut result = 0
  for i in 0..<self.length() {
    result = result ^ mul(self.values[i], other.values[i])
  }
  result
}

///|
pub fn Symbols::slice(
  self : Symbols,
  start : Int32,
  end : Int32,
) -> Symbols raise CodeError {
  if start < 0 || end < start || end > self.length() {
    raise Invalid("invalid symbol slice")
  }
  let out : Array[Int32] = []
  for i in start..<end {
    out.push(self.values[i])
  }
  { values: out, }
}

///|
pub fn Symbols::concat(
  self : Symbols,
  other : Symbols,
) -> Symbols raise CodeError {
  if other.length() > 262144 - self.length() {
    raise Limit("concatenated vector too large")
  }
  let out = self.to_array()
  for value in other.values {
    out.push(value)
  }
  { values: out, }
}
