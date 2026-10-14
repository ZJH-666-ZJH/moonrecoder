///|
test "feedback wire roundtrip including empty and complete ranks" {
  let g = Generation::new(11, 4, 2, 7)
  for pivots in [[], [0, 2], [0, 1, 2, 3]] {
    let hint = Feedback::new(g, pivots)
    let wire = hint.to_wire()
    let parsed = feedback_from_wire(wire)
    assert_true(parsed.generation().same(g))
    assert_eq(parsed.pivots(), pivots)
    for i in 0..<wire.length() {
      let bad = wire.to_array()
      bad[i] = bad[i] ^ 1
      assert_true(rejects(() => feedback_from_wire(Symbols::new(bad))))
    }
  }
}

///|
test "feedback rejects checksum-valid unsorted and out-of-range pivots" {
  let g = Generation::new(0, 3, 1, 3)
  let bytes = Feedback::new(g, [0, 2]).to_wire().to_array()
  bytes[20] = 2
  bytes[21] = 1
  assert_true(rejects(() => feedback_from_wire(refresh_crc(bytes))))
  bytes[20] = 0
  bytes[21] = 3
  assert_true(rejects(() => feedback_from_wire(refresh_crc(bytes))))
}
