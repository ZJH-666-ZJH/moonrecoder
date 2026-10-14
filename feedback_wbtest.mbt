///|
test "pivot-aware sender completes arbitrary deficient row span" {
  let input = Symbols::new([1, 2, 3, 4])
  let enc = Encoder::new(1, input, 1)
  let dec = Decoder::new(enc.generation())
  ignore(dec.admit(enc.encode(Symbols::new([1, 1, 1, 0]), 0)))
  ignore(dec.admit(enc.encode(Symbols::new([0, 0, 1, 1]), 1)))
  let hint = dec.feedback()
  assert_eq(hint.pivots(), [0, 2])
  assert_eq(hint.missing_pivots(), [1, 3])
  let repair = enc.repair(hint, 2)
  assert_eq(repair.length(), 2)
  for packet in repair {
    assert_true(dec.admit(packet) is Innovative(_, _))
  }
  assert_true(dec.recover().equal(input))
  assert_eq(enc.repair(dec.feedback(), 10).length(), 0)
}

///|
test "feedback ownership and validation" {
  let g = Generation::new(1, 3, 1, 3)
  let pivots = [0, 2]
  let hint = Feedback::new(g, pivots)
  pivots[0] = 1
  assert_eq(hint.pivots(), [0, 2])
  assert_true(rejects(() => Feedback::new(g, [2, 1])))
  assert_true(rejects(() => Feedback::new(g, [0, 0])))
  assert_true(rejects(() => Feedback::new(g, [-1])))
  assert_true(rejects(() => Feedback::new(g, [3])))
}
