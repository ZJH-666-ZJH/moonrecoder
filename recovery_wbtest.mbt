///|
test "arbitrary full-rank recovery matches batch matrix inverse" {
  let source = Symbols::new([10, 20, 30, 40, 50])
  let enc = Encoder::new(5, source, 2)
  let dec = Decoder::new(enc.generation())
  let coefficients = [[1, 2, 0], [0, 1, 3], [0, 0, 1]]
  for i in 0..<3 {
    ignore(dec.admit(enc.encode(Symbols::new(coefficients[2 - i]), i)))
  }
  assert_true(dec.recover().equal(source))
  let report = dec.report()
  assert_eq(report.rank, 3)
  assert_eq(report.known, 3)
  report.pivots[0] = 99
  assert_eq(dec.pivots(), [0, 1, 2])
  assert_true(report.to_json().length() > 30)
}

///|
test "full rank does not authorize discarding nonzero padding" {
  let g = Generation::new(1, 1, 2, 1)
  let dec = Decoder::new(g)
  ignore(dec.admit(Packet::new(g, 0, equation([1], [1, 1]))))
  assert_eq(dec.rank(), 1)
  assert_true(rejects(() => dec.recover()))
  let partial = Decoder::new(Generation::new(0, 2, 1, 2))
  assert_true(rejects(() => partial.recover()))
}
