///|
test "matrix inversion, rank and nonmutation" {
  let m = FieldMatrix::new([[1, 2, 0], [0, 1, 3], [0, 0, 1]])
  assert_eq(m.rank(), 3)
  assert_eq(
    m.multiply(m.inverse()).to_arrays(),
    FieldMatrix::identity(3).to_arrays(),
  )
  assert_eq(m.transpose().transpose().to_arrays(), m.to_arrays())
  assert_eq(FieldMatrix::new([[0, 1], [1, 0]]).inverse().to_arrays(), [
    [0, 1],
    [1, 0],
  ])
  let singular = FieldMatrix::new([[1, 1], [1, 1]])
  assert_eq(singular.rank(), 1)
  assert_true(rejects(() => singular.inverse()))
  assert_eq(singular.to_arrays(), [[1, 1], [1, 1]])
}

///|
test "matrix shape validation" {
  assert_true(rejects(() => FieldMatrix::new([[1], [1, 2]])))
  assert_true(rejects(() => FieldMatrix::new([])))
  assert_true(rejects(() => FieldMatrix::new([[0, 1]]).inverse()))
  assert_true(
    rejects(() => FieldMatrix::identity(2).multiply(FieldMatrix::identity(3))),
  )
}
