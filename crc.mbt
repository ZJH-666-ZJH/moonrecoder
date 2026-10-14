///|
// Reflected IEEE CRC-32. Detects accidental damage, not malicious modification.
pub struct Crc32 {
  mut accumulator : UInt32
}

///|
pub fn Crc32::new() -> Crc32 {
  { accumulator: 0xffffffffU, }
}

///|
pub fn Crc32::update(self : Crc32, bytes : Symbols) -> Unit {
  let mut crc = self.accumulator
  for byte in bytes.values {
    crc = crc ^ byte.reinterpret_as_uint()
    for _ in 0..<8 {
      if (crc & 1U) != 0U {
        crc = (crc >> 1) ^ 0xedb88320U
      } else {
        crc = crc >> 1
      }
    }
  }
  self.accumulator = crc
}

///|
pub fn Crc32::value(self : Crc32) -> UInt32 {
  self.accumulator ^ 0xffffffffU
}

///|
pub fn crc32(bytes : Symbols) -> UInt32 {
  let checksum = Crc32::new()
  checksum.update(bytes)
  checksum.value()
}
