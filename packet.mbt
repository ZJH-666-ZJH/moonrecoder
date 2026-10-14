///|
pub struct Generation {
  id_value : Int32
  count_value : Int32
  width_value : Int32
  length_value : Int32
}

///|
pub fn Generation::new(
  id : Int32,
  count : Int32,
  width : Int32,
  length : Int32,
) -> Generation raise CodeError {
  if id < 0 {
    raise Invalid("generation ID must be a nonnegative signed 31-bit integer")
  }
  if count < 1 || count > 64 {
    raise Limit("generation source count must be 1..64")
  }
  if width < 1 || width > 4096 {
    raise Limit("generation symbol width must be 1..4096")
  }
  if length <= (count - 1) * width || length > count * width {
    raise Shape("original length must fill all but the final source symbol")
  }
  {
    id_value: id,
    count_value: count,
    width_value: width,
    length_value: length,
  }
}

///|
pub fn Generation::id(self : Generation) -> Int32 {
  self.id_value
}

///|
pub fn Generation::count(self : Generation) -> Int32 {
  self.count_value
}

///|
pub fn Generation::width(self : Generation) -> Int32 {
  self.width_value
}

///|
pub fn Generation::length(self : Generation) -> Int32 {
  self.length_value
}

///|
pub fn Generation::padded_length(self : Generation) -> Int32 {
  self.count_value * self.width_value
}

///|
pub fn Generation::same(self : Generation, other : Generation) -> Bool {
  self.id_value == other.id_value &&
  self.count_value == other.count_value &&
  self.width_value == other.width_value &&
  self.length_value == other.length_value
}

///|
pub struct Packet {
  generation_value : Generation
  sequence_value : Int32
  equation_value : Equation
}

///|
pub fn Packet::new(
  generation : Generation,
  sequence : Int32,
  equation : Equation,
) -> Packet raise CodeError {
  if sequence < 0 {
    raise Invalid("packet sequence must be nonnegative")
  }
  if equation.coefficients.length() != generation.count() ||
    equation.payload.length() != generation.width() {
    raise Shape("packet equation differs from generation dimensions")
  }
  {
    generation_value: generation,
    sequence_value: sequence,
    equation_value: equation,
  }
}

///|
pub fn Packet::generation(self : Packet) -> Generation {
  self.generation_value
}

///|
pub fn Packet::sequence(self : Packet) -> Int32 {
  self.sequence_value
}

///|
pub fn Packet::equation(self : Packet) -> Equation {
  self.equation_value
}

///|
pub fn Packet::coefficients(self : Packet) -> Symbols {
  self.equation_value.coefficients
}

///|
pub fn Packet::payload(self : Packet) -> Symbols {
  self.equation_value.payload
}

///|
pub fn Packet::with_sequence(
  self : Packet,
  sequence : Int32,
) -> Packet raise CodeError {
  Packet::new(self.generation_value, sequence, self.equation_value)
}

///|
// Only exact unit vectors are systematic packets; one nonzero scalar is not.
pub fn Packet::systematic_index(self : Packet) -> Int32? {
  let mut index : Int32? = None
  for i in 0..<self.generation_value.count() {
    let value = self.equation_value.coefficients.values[i]
    if value == 0 {
      continue
    }
    if value != 1 {
      return None
    }
    if index is Some(_) {
      return None
    }
    index = Some(i)
  }
  index
}
