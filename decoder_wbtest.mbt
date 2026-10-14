///|
test "decoder separates generations and counts dependence algebraically" {
  let enc = Encoder::new(10, Symbols::new([1, 2, 3, 4]), 2)
  let dec = Decoder::new(enc.generation(), max_packets=3)
  assert_true(dec.admit(enc.systematic(1, 0)) is Innovative(1, 1))
  assert_true(dec.admit(enc.systematic(1, 99)) is Dependent)
  let foreign = Encoder::new(11, Symbols::new([1, 2, 3, 4]), 2)
  assert_true(rejects(() => dec.admit(foreign.systematic(0, 1))))
  assert_eq(dec.admitted(), 2)
  assert_eq(dec.dependent(), 1)
  ignore(dec.admit(enc.systematic(0, 0)))
  assert_eq(dec.deficit(), 0)
  assert_true(rejects(() => dec.admit(enc.systematic(0, 7))))
  assert_eq(dec.rank(), 2)
}

///|
test "same ID with incompatible shape is not admitted" {
  let one = Encoder::new(1, Symbols::new([1, 2]), 1)
  let two = Encoder::new(1, Symbols::new([1, 2]), 2)
  let dec = Decoder::new(one.generation())
  assert_true(rejects(() => dec.admit(two.systematic(0, 0))))
  assert_eq(dec.rank(), 0)
  assert_true(rejects(() => Decoder::new(one.generation(), max_packets=0)))
}
