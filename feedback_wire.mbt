///|
pub fn Feedback::to_wire(self : Feedback) -> Symbols {
  let generation = self.generation()
  let out : Array[Int32] = [
    77,
    82,
    70,
    49,
    generation.count(),
    generation.width() >> 8,
    generation.width() & 255,
    self.rank(),
  ]
  write_u32(out, generation.id().reinterpret_as_uint())
  write_u32(out, generation.length().reinterpret_as_uint())
  write_u32(out, (24 + self.rank()).reinterpret_as_uint())
  for pivot in self.pivot_values {
    out.push(pivot)
  }
  let checksum = crc32({ values: out, })
  write_u32(out, checksum)
  { values: out, }
}

///|
pub fn feedback_from_wire(frame : Symbols) -> Feedback raise CodeError {
  if frame.length() < 24 {
    raise Truncated
  }
  if frame.length() > 88 {
    raise Limit("feedback frame exceeds 88 bytes")
  }
  let values = frame.values
  if values[0] != 77 || values[1] != 82 || values[2] != 70 || values[3] != 49 {
    raise Corrupt("unknown feedback magic/version")
  }
  let count = values[4]
  let width = (values[5] << 8) | values[6]
  let rank = values[7]
  if count < 1 || count > 64 || width < 1 || width > 4096 || rank > count {
    raise Limit("feedback dimensions/rank invalid")
  }
  if read_u31(values, 16) != 24 + rank || frame.length() != 24 + rank {
    raise Shape("feedback frame length mismatch")
  }
  let end = frame.length() - 4
  if read_u32(values, end) != crc32(frame.slice(0, end)) {
    raise Corrupt("feedback CRC32 mismatch")
  }
  let generation = Generation::new(
    read_u31(values, 8),
    count,
    width,
    read_u31(values, 12),
  )
  let pivots : Array[Int32] = []
  for i in 20..<end {
    pivots.push(values[i])
  }
  Feedback::new(generation, pivots)
}
