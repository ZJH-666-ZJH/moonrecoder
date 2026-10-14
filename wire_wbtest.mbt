///|
fn refresh_crc(values : Array[Int]) -> Symbols raise CodeError {
  let body : Array[Int] = []
  for i in 0..<(values.length() - 4) {
    body.push(values[i])
  }
  write_u32(body, crc32(Symbols::new(body)))
  Symbols::new(body)
}

///|
test "wire round trip and every single-byte corruption" {
  let enc = Encoder::new(99, Symbols::new([1, 2, 3, 4, 5]), 2)
  let p = enc.encode(Symbols::new([7, 8, 9]), 42)
  let wire = p.to_wire()
  let parsed = packet_from_wire(wire)
  assert_true(parsed.generation().same(p.generation()))
  assert_eq(parsed.sequence(), 42)
  assert_true(parsed.payload().equal(p.payload()))
  assert_true(parsed.coefficients().equal(p.coefficients()))
  for i in 0..<wire.length() {
    let bad = wire.to_array()
    bad[i] = bad[i] ^ 1
    assert_true(rejects(() => packet_from_wire(Symbols::new(bad))))
  }
  for length in 0..<wire.length() {
    assert_true(rejects(() => packet_from_wire(wire.slice(0, length))))
  }
}

///|
test "wire structural failures with valid checksums" {
  let enc = Encoder::new(1, Symbols::new([9]), 1)
  let values = enc.systematic(0, 2).to_wire().to_array()
  assert_eq(values[20], 0)
  assert_eq(values[23], 30)
  values[8] = 128
  assert_true(rejects(() => packet_from_wire(refresh_crc(values))))
  values[8] = 0
  values[4] = 1
  assert_true(rejects(() => packet_from_wire(refresh_crc(values))))
  assert_true(
    rejects(() => packet_from_wire(Symbols::new(Array::make(4189, 0)))),
  )
}
