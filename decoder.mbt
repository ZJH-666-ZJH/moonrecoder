///|
pub struct Decoder {
  generation_value : Generation
  priv mut basis : Basis
  packet_limit : Int32
  mut admitted_count : Int32
  mut dependent_count : Int32
}

///|
pub fn Decoder::new(
  generation : Generation,
  max_packets~ : Int32 = 4096,
) -> Decoder raise CodeError {
  if max_packets < 1 || max_packets > 65536 {
    raise Limit("decoder packet budget must be 1..65536")
  }
  {
    generation_value: generation,
    basis: Basis::new(generation.count(), generation.width()),
    packet_limit: max_packets,
    admitted_count: 0,
    dependent_count: 0,
  }
}

///|
pub fn Decoder::generation(self : Decoder) -> Generation {
  self.generation_value
}

///|
pub fn Decoder::rank(self : Decoder) -> Int32 {
  self.basis.rank()
}

///|
pub fn Decoder::deficit(self : Decoder) -> Int32 {
  self.basis.deficit()
}

///|
pub fn Decoder::admitted(self : Decoder) -> Int32 {
  self.admitted_count
}

///|
pub fn Decoder::dependent(self : Decoder) -> Int32 {
  self.dependent_count
}

///|
pub fn Decoder::remaining_packets(self : Decoder) -> Int32 {
  self.packet_limit - self.admitted_count
}

///|
pub fn Decoder::pivots(self : Decoder) -> Array[Int32] {
  self.basis.pivots()
}

///|
pub fn Decoder::known_symbols(self : Decoder) -> Array[(Int32, Symbols)] {
  self.basis.known()
}

///|
pub fn Decoder::basis_equations(self : Decoder) -> Array[Equation] {
  self.basis.equations()
}

///|
// Sequence numbers are opaque annotations. Algebra, not sequence, detects duplicates.
pub fn Decoder::admit(
  self : Decoder,
  packet : Packet,
) -> Admission raise CodeError {
  if !packet.generation().same(self.generation_value) {
    raise Shape("foreign or conflicting generation")
  }
  if self.remaining_packets() == 0 {
    raise Limit("decoder packet budget exhausted")
  }
  let result = self.basis.admit(packet.equation())
  self.admitted_count = self.admitted_count + 1
  if result is Dependent {
    self.dependent_count = self.dependent_count + 1
  }
  result
}
