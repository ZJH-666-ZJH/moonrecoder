///|
test "every nonzero field element has an inverse" {
  for a in 1..<256 {
    assert_eq(gf_mul(a, gf_inverse(a)), 1)
    assert_eq(gf_pow(a, 255), 1)
  }
}

///|
test "field reduction and invalid input" {
  assert_eq(gf_mul(128, 2), 29)
  assert_eq(gf_mul(83, 202), 143)
  assert_true(rejects(() => gf_inverse(0)))
  assert_true(rejects(() => gf_add(256, 0)))
  assert_true(rejects(() => gf_pow(1, -1)))
}

///|
fn[T] rejects(f : () -> T raise CodeError) -> Bool {
  try {
    ignore(f())
    false
  } catch {
    _ => true
  }
}
