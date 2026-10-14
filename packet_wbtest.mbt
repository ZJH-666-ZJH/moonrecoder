///|
test "generation shape and packet ownership" {
  let g = Generation::new(7, 2, 3, 5)
  let p = Packet::new(g, 10, equation([0, 1], [2, 3, 0]))
  assert_eq(g.padded_length(), 6)
  assert_true(p.systematic_index() is Some(1))
  assert_eq(p.with_sequence(11).sequence(), 11)
  assert_true(p.generation().same(g))
  assert_true(rejects(() => Generation::new(1, 2, 3, 3)))
  assert_true(rejects(() => Generation::new(-1, 1, 1, 1)))
  assert_true(rejects(() => Packet::new(g, -1, p.equation())))
  assert_true(rejects(() => Packet::new(g, 0, equation([1], [1]))))
  assert_true(
    Packet::new(g, 1, equation([0, 2], [2, 4, 6])).systematic_index() is None,
  )
}
