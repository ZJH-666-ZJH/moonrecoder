///|
pub struct Relay {
  priv decoder : Decoder
}

///|
pub fn Relay::new(
  generation : Generation,
  max_packets~ : Int32 = 4096,
) -> Relay raise CodeError {
  { decoder: Decoder::new(generation, max_packets~), }
}

///|
pub fn Relay::generation(self : Relay) -> Generation {
  self.decoder.generation()
}

///|
pub fn Relay::rank(self : Relay) -> Int32 {
  self.decoder.rank()
}

///|
pub fn Relay::admit(self : Relay, packet : Packet) -> Admission raise CodeError {
  self.decoder.admit(packet)
}

///|
pub fn Relay::report(self : Relay) -> DecodeReport {
  self.decoder.report()
}

///|
// Weights index the CURRENT pivot-ordered basis. No source recovery is required.
// Recoding can redistribute information but can never increase the relay's rank.
pub fn Relay::mix(
  self : Relay,
  weights : Symbols,
  sequence : Int32,
) -> Packet raise CodeError {
  if sequence < 0 {
    raise Invalid("negative recoded sequence")
  }
  let basis = self.decoder.basis_equations()
  if basis.length() == 0 {
    raise Incomplete(self.generation().count())
  }
  if weights.length() != basis.length() {
    raise Shape("one weight is required per current basis row")
  }
  let coefficients = Array::make(self.generation().count(), 0)
  let payload = Array::make(self.generation().width(), 0)
  for i in 0..<basis.length() {
    let factor = weights.values[i]
    for j in 0..<coefficients.length() {
      coefficients[j] = coefficients[j] ^
        mul(factor, basis[i].coefficients.values[j])
    }
    for j in 0..<payload.length() {
      payload[j] = payload[j] ^ mul(factor, basis[i].payload.values[j])
    }
  }
  let c : Symbols = { values: coefficients, }
  if c.is_zero() {
    raise Invalid("zero recoding weights carry no information")
  }
  Packet::new(self.generation(), sequence, {
    coefficients: c,
    payload: { values: payload, },
  })
}

///|
pub fn Relay::coded(
  self : Relay,
  stream : CoefficientStream,
  sequence : Int32,
) -> Packet raise CodeError {
  if sequence < 0 {
    raise Invalid("negative recoded sequence")
  }
  if self.rank() == 0 {
    raise Incomplete(self.generation().count())
  }
  self.mix(stream.draw(self.rank()), sequence)
}

///|
// Export independent relay rows rather than promising random packet independence.
pub fn Relay::basis_packets(
  self : Relay,
  first_sequence : Int32,
) -> Array[Packet] raise CodeError {
  if first_sequence < 0 {
    raise Invalid("negative first sequence")
  }
  let basis = self.decoder.basis_equations()
  if basis.length() > 0 && first_sequence > 2147483647 - (basis.length() - 1) {
    raise Limit("basis packet sequence overflow")
  }
  let out : Array[Packet] = []
  for i in 0..<basis.length() {
    out.push(Packet::new(self.generation(), first_sequence + i, basis[i]))
  }
  out
}
