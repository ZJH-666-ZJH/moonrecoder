///|
pub struct Encoder {
  generation_value : Generation
  source : Array[Symbols]
}

///|
pub fn Encoder::new(
  id : Int,
  input : Symbols,
  width : Int,
) -> Encoder raise CodeError {
  if width < 1 || width > 4096 {
    raise Limit("encoder width must be 1..4096")
  }
  if input.length() == 0 {
    raise Invalid("empty input has no generation")
  }
  let count = (input.length() + width - 1) / width
  let generation = Generation::new(id, count, width, input.length())
  let source : Array[Symbols] = []
  for i in 0..<count {
    let values = Array::make(width, 0)
    for j in 0..<width {
      let offset = i * width + j
      if offset < input.length() {
        values[j] = input.values[offset]
      }
    }
    source.push({ values, })
  }
  { generation_value: generation, source, }
}

///|
pub fn Encoder::from_symbols(
  generation : Generation,
  source : Array[Symbols],
) -> Encoder raise CodeError {
  if source.length() != generation.count() {
    raise Shape("source symbol count mismatch")
  }
  let detached : Array[Symbols] = []
  for symbol in source {
    if symbol.length() != generation.width() {
      raise Shape("source symbol width mismatch")
    }
    detached.push(symbol)
  }
  let last_symbol = source[source.length() - 1]
  let used = generation.length() - (generation.count() - 1) * generation.width()
  for i in used..<generation.width() {
    if last_symbol.values[i] != 0 {
      raise Corrupt("nonzero source padding")
    }
  }
  { generation_value: generation, source: detached, }
}

///|
pub fn Encoder::generation(self : Encoder) -> Generation {
  self.generation_value
}

///|
pub fn Encoder::source_symbols(self : Encoder) -> Array[Symbols] {
  let out : Array[Symbols] = []
  for symbol in self.source {
    out.push(symbol)
  }
  out
}

///|
pub fn Encoder::systematic(
  self : Encoder,
  index : Int,
  sequence : Int,
) -> Packet raise CodeError {
  if index < 0 || index >= self.generation_value.count() {
    raise Invalid("source index out of range")
  }
  let values = Array::make(self.generation_value.count(), 0)
  values[index] = 1
  Packet::new(self.generation_value, sequence, {
    coefficients: { values, },
    payload: self.source[index],
  })
}

///|
pub fn Encoder::encode(
  self : Encoder,
  coefficients : Symbols,
  sequence : Int,
) -> Packet raise CodeError {
  if coefficients.length() != self.generation_value.count() {
    raise Shape("encoder coefficient count mismatch")
  }
  if sequence < 0 {
    raise Invalid("negative packet sequence")
  }
  let values = Array::make(self.generation_value.width(), 0)
  for i in 0..<self.source.length() {
    let factor = coefficients.values[i]
    if factor == 0 {
      continue
    }
    for j in 0..<values.length() {
      values[j] = values[j] ^ mul(factor, self.source[i].values[j])
    }
  }
  Packet::new(self.generation_value, sequence, {
    coefficients,
    payload: { values, },
  })
}
