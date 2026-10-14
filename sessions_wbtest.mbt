///|
test "pool multiplexes interleaved generations and reclaims reservations" {
  let a = Encoder::new(1, Symbols::new([1, 2]), 1)
  let b = Encoder::new(2, Symbols::new([3, 4]), 1)
  let pool = SessionPool::new(max_generations=2, max_cells=12)
  ignore(pool.admit(a.systematic(0, 0)))
  ignore(pool.admit(b.systematic(1, 1)))
  assert_eq(pool.reserved_cells(), 12)
  assert_true(rejects(() => pool.take(1)))
  assert_eq(pool.count(), 2)
  ignore(pool.admit(a.systematic(1, 2)))
  assert_eq(pool.take(1).to_array(), [1, 2])
  assert_eq(pool.reserved_cells(), 6)
  assert_eq(pool.ids(), [2])
  ignore(pool.admit(b.systematic(0, 0)))
  assert_eq(pool.take(2).to_array(), [3, 4])
  assert_eq(pool.count(), 0)
}

///|
test "pool budget and conflicting ID failures leave reservations intact" {
  let a = Encoder::new(1, Symbols::new([1, 2]), 1)
  let pool = SessionPool::new(max_cells=5)
  assert_true(rejects(() => pool.admit(a.systematic(0, 0))))
  assert_eq(pool.count(), 0)
  let one = SessionPool::new(max_generations=1)
  ignore(one.admit(a.systematic(0, 0)))
  let conflict = Encoder::new(1, Symbols::new([1, 2]), 2)
  assert_true(rejects(() => one.admit(conflict.systematic(0, 1))))
  let foreign = Encoder::new(2, Symbols::new([1]), 1)
  assert_true(rejects(() => one.admit(foreign.systematic(0, 1))))
  assert_eq(one.count(), 1)
  assert_true(!one.discard(99))
}
