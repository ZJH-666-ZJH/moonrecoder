///|
fn write_u32(out : Array[Int], value : UInt) -> Unit {
  for shift in [24, 16, 8, 0] {
    out.push(((value >> shift) & 255U).reinterpret_as_int())
  }
}

///|
fn read_u32(values : Array[Int], offset : Int) -> UInt {
  let mut value = 0U
  for i in offset..<(offset + 4) {
    value = (value << 8) | values[i].reinterpret_as_uint()
  }
  value
}

///|
fn read_u31(values : Array[Int], offset : Int) -> Int raise CodeError {
  let value = read_u32(values, offset)
  if value > 2147483647U {
    raise Corrupt("unsigned field exceeds signed 31-bit domain")
  }
  value.reinterpret_as_int()
}

///|
pub fn Packet::wire_length(self : Packet) -> Int {
  28 + self.generation().count() + self.generation().width()
}

///|
// MRC1: big-endian bounded header, explicit coefficients, payload, CRC32.
// This is a project format, NOT an RFC 8681 / RaptorQ / Reed-Solomon frame.
pub fn Packet::to_wire(self : Packet) -> Symbols {
  let g = self.generation()
  let values : Array[Int] = [
    77,
    82,
    67,
    49,
    0,
    g.count(),
    g.width() >> 8,
    g.width() & 255,
  ]
  write_u32(values, g.id().reinterpret_as_uint())
  write_u32(values, g.length().reinterpret_as_uint())
  write_u32(values, self.sequence().reinterpret_as_uint())
  write_u32(values, self.wire_length().reinterpret_as_uint())
  for value in self.coefficients().values {
    values.push(value)
  }
  for value in self.payload().values {
    values.push(value)
  }
  let checksum = crc32({ values, })
  write_u32(values, checksum)
  { values, }
}

///|
pub fn packet_from_wire(frame : Symbols) -> Packet raise CodeError {
  if frame.length() < 28 {
    raise Truncated
  }
  if frame.length() > 4188 {
    raise Limit("packet frame exceeds 4188 bytes")
  }
  let values = frame.values
  if values[0] != 77 || values[1] != 82 || values[2] != 67 || values[3] != 49 {
    raise Corrupt("unknown packet magic/version")
  }
  if values[4] != 0 {
    raise Corrupt("reserved packet flags must be zero")
  }
  let count = values[5]
  let width = (values[6] << 8) | values[7]
  if count < 1 || count > 64 || width < 1 || width > 4096 {
    raise Limit("packet dimensions outside supported bounds")
  }
  let expected = 28 + count + width
  let declared = read_u31(values, 20)
  if declared != expected || frame.length() != expected {
    raise Shape("packet length mismatch")
  }
  let end = frame.length() - 4
  if crc32(frame.slice(0, end)) != read_u32(values, end) {
    raise Corrupt("packet CRC32 mismatch")
  }
  let generation = Generation::new(
    read_u31(values, 8),
    count,
    width,
    read_u31(values, 12),
  )
  let sequence = read_u31(values, 16)
  let coefficients = frame.slice(24, 24 + count)
  let payload = frame.slice(24 + count, end)
  Packet::new(generation, sequence, Equation::new(coefficients, payload))
}
