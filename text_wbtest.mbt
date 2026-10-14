///|
test "all byte values hex and byte adapters roundtrip" {
  let values : Array[Int32] = []
  for i in 0..<256 {
    values.push(i)
  }
  let symbols = Symbols::new(values)
  assert_true(symbols_from_hex(symbols.to_hex()).equal(symbols))
  assert_true(Symbols::from_bytes(symbols.to_bytes()).equal(symbols))
  assert_eq(symbols_from_hex("0A ff \t1 2\r\n").to_array(), [10, 255, 18])
  assert_eq(Symbols::from_bytes(b"abc").to_hex(), "616263")
}

///|
test "hex rejects ambiguous and excessive input" {
  for text in ["0", "0x01", "zz", "０１", "ab-cd"] {
    assert_true(rejects(() => symbols_from_hex(text)))
  }
  assert_true(rejects(() => symbols_from_hex("abcd", max_bytes=1)))
  assert_eq(symbols_from_hex(" ", max_bytes=0).length(), 0)
  let e = Encoder::new(0, Symbols::new([1, 2]), 1)
  let p = e.systematic(0, 0)
  assert_true(
    packet_from_hex(p.to_wire().to_hex()).payload().equal(p.payload()),
  )
}
