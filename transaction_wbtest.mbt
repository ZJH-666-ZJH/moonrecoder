///|
test "batch contradiction rolls back all earlier innovations" {
  let enc = Encoder::new(1, Symbols::new([5, 6]), 1)
  let d = Decoder::new(enc.generation())
  let bad = Packet::new(enc.generation(), 9, equation([1, 0], [99]))
  assert_true(rejects(() => d.admit_batch([enc.systematic(0, 0), bad])))
  assert_eq(d.rank(), 0)
  assert_eq(d.admitted(), 0)
  ignore(d.admit_batch([enc.systematic(0, 0), enc.systematic(1, 1)]))
  assert_true(d.is_reduced())
  assert_eq(d.recover().to_array(), [5, 6])
}

///|
test "fork independence and wire-batch parse rollback" {
  let enc = Encoder::new(0, Symbols::new([1, 2]), 1)
  let d = Decoder::new(enc.generation())
  ignore(d.admit(enc.systematic(0, 0)))
  let fork = d.fork()
  ignore(fork.admit(enc.systematic(1, 1)))
  assert_eq(fork.rank(), 2)
  assert_eq(d.rank(), 1)
  assert_true(d.is_reduced())
  let wire = enc.systematic(1, 1).to_wire()
  assert_true(rejects(() => d.admit_wire_batch([wire, Symbols::new([0])])))
  assert_eq(d.rank(), 1)
  assert_eq(d.admitted(), 1)
}
