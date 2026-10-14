///|
test "symbols ownership and linear combinations" {
  let a = [1, 2, 3]
  let v = Symbols::new(a)
  a[0] = 255
  let returned = v.to_array()
  returned[1] = 255
  assert_eq(v.to_array(), [1, 2, 3])
  assert_true(v.axpy(1, v).is_zero())
  assert_true(v.scale(1).equal(v))
  assert_eq(v.dot(Symbols::new([0, 1, 0])), 2)
  assert_eq(v.slice(1, 3).concat(Symbols::new([4])).to_array(), [2, 3, 4])
}

///|
test "vector failures preserve operands" {
  let v = Symbols::new([2])
  assert_true(rejects(() => Symbols::new([-1])))
  assert_true(rejects(() => v.axpy(1, Symbols::new([1, 2]))))
  assert_true(rejects(() => v.at(-1)))
  assert_true(rejects(() => v.slice(0, 2)))
  assert_true(rejects(() => Symbols::zeros(-1)))
  assert_eq(v.to_array(), [2])
}
