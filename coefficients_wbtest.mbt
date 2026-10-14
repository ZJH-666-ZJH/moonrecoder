///|
test "seeded coefficient stream is deterministic and bounded" {
  let a = CoefficientStream::new(1U, max_draws=6)
  let b = CoefficientStream::new(1U, max_draws=6)
  assert_eq(a.draw(3).to_array(), [33, 1, 197])
  assert_eq(b.draw(3).to_array(), [33, 1, 197])
  assert_true(a.draw(3).equal(b.draw(3)))
  assert_eq(a.remaining(), 0)
  assert_true(rejects(() => a.draw(1)))
  assert_eq(a.draws(), 6)
  assert_true(rejects(() => CoefficientStream::new(0U)))
}

///|
test "invalid packet sequence does not consume RNG" {
  let stream = CoefficientStream::new(7U)
  let e = Encoder::new(0, Symbols::new([1, 2, 3]), 1)
  assert_true(rejects(() => e.coded(stream, -1)))
  assert_eq(stream.draws(), 0)
  assert_eq(e.coded(stream, 1).coefficients().length(), 3)
}
