///|
pub fn Symbols::from_bytes(bytes : Bytes) -> Symbols raise CodeError {
  if bytes.length() > 262144 {
    raise Limit("byte adapter exceeds maximum vector size")
  }
  let values : Array[Int32] = []
  for byte in bytes.to_array() {
    values.push(byte.to_int())
  }
  { values, }
}

///|
pub fn Symbols::to_bytes(self : Symbols) -> Bytes {
  let bytes = self.values.map(value => value.to_byte())
  Bytes::from_array(bytes[:])
}

///|
pub fn Symbols::to_hex(self : Symbols) -> String {
  let digits : Array[Char] = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f',
  ]
  let text : Array[Char] = []
  for value in self.values {
    text.push(digits[value >> 4])
    text.push(digits[value & 15])
  }
  String::from_array(text[:])
}

///|
fn hex_digit(char : Char) -> Int32 {
  match char {
    '0'..<='9' => char.to_int() - 48
    'a'..<='f' => char.to_int() - 87
    'A'..<='F' => char.to_int() - 55
    _ => -1
  }
}

///|
// Only ASCII whitespace is ignored, including between a byte's two nibbles.
pub fn symbols_from_hex(
  text : String,
  max_bytes~ : Int32 = 262144,
) -> Symbols raise CodeError {
  if max_bytes < 0 || max_bytes > 262144 {
    raise Limit("hex byte budget outside 0..262144")
  }
  if text.length() > 1048576 {
    raise Limit("hex text exceeds 1048576 code units")
  }
  let values : Array[Int32] = []
  let mut high = -1
  for char in text.iter() {
    if char == ' ' || char == '\t' || char == '\r' || char == '\n' {
      continue
    }
    let digit = hex_digit(char)
    if digit < 0 {
      raise Invalid("hex input contains a non-ASCII hexadecimal digit")
    }
    if high < 0 {
      high = digit
    } else {
      if values.length() == max_bytes {
        raise Limit("hex output byte budget exhausted")
      }
      values.push((high << 4) | digit)
      high = -1
    }
  }
  if high >= 0 {
    raise Invalid("hex input has an odd number of digits")
  }
  { values, }
}

///|
pub fn packet_from_hex(text : String) -> Packet raise CodeError {
  packet_from_wire(symbols_from_hex(text, max_bytes=4188))
}

///|
pub fn feedback_from_hex(text : String) -> Feedback raise CodeError {
  feedback_from_wire(symbols_from_hex(text, max_bytes=88))
}
