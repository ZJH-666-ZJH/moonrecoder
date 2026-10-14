///|
pub struct CoefficientStream {
  mut state : UInt
  mut draw_count : Int
  draw_limit : Int
}

///|
pub fn CoefficientStream::new(
  seed : UInt,
  max_draws? : Int = 1048576,
) -> CoefficientStream raise CodeError {
  if seed == 0U {
    raise Invalid("xorshift seed must be nonzero")
  }
  if max_draws < 1 || max_draws > 1048576 {
    raise Limit("coefficient draw limit must be 1..1048576")
  }
  { state: seed, draw_count: 0, draw_limit: max_draws, }
}

///|
fn rng_step(state : UInt) -> UInt {
  let x = state ^ (state << 13)
  let y = x ^ (x >> 17)
  y ^ (y << 5)
}

///|
pub fn CoefficientStream::draws(self : CoefficientStream) -> Int {
  self.draw_count
}

///|
pub fn CoefficientStream::remaining(self : CoefficientStream) -> Int {
  self.draw_limit - self.draw_count
}

///|
// Reproducible coefficient selection, NOT a cryptographic RNG or MDS code.
// The all-zero vector is replaced by e_0; this is deliberately not uniform.
pub fn CoefficientStream::draw(
  self : CoefficientStream,
  count : Int,
) -> Symbols raise CodeError {
  if count < 1 || count > 64 {
    raise Limit("coefficient count must be 1..64")
  }
  if count > self.remaining() {
    raise Limit("coefficient stream exhausted")
  }
  let mut state = self.state
  let values : Array[Int] = []
  let mut any = false
  for _ in 0..<count {
    state = rng_step(state)
    let value = state.reinterpret_as_int() & 255
    values.push(value)
    if value != 0 {
      any = true
    }
  }
  if !any {
    values[0] = 1
  }
  self.state = state
  self.draw_count = self.draw_count + count
  { values, }
}

///|
pub fn Encoder::coded(
  self : Encoder,
  stream : CoefficientStream,
  sequence : Int,
) -> Packet raise CodeError {
  if sequence < 0 {
    raise Invalid("negative packet sequence")
  }
  let coefficients = stream.draw(self.generation().count())
  self.encode(coefficients, sequence)
}
