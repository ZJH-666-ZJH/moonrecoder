///|
fn equation(c : Array[Int], p : Array[Int]) -> Equation raise CodeError {
  Equation::new(Symbols::new(c), Symbols::new(p))
}

///|
test "incremental RREF rejects contradictions transactionally" {
  let basis = Basis::new(2, 2)
  assert_true(basis.admit(equation([1, 1], [2, 6])) is Innovative(0, 1))
  assert_true(basis.admit(equation([1, 1], [2, 6])) is Dependent)
  assert_true(rejects(() => basis.admit(equation([1, 1], [2, 7]))))
  assert_eq(basis.rank(), 1)
  assert_true(rejects(() => basis.recover()))
  assert_true(basis.admit(equation([0, 1], [3, 4])) is Innovative(1, 2))
  let result = basis.recover()
  assert_eq(result[0].to_array(), [1, 2])
  assert_eq(result[1].to_array(), [3, 4])
  assert_eq(basis.known().length(), 2)
}

///|
test "zero equations, reverse pivots, partial recovery and shape" {
  let b = Basis::new(3, 1)
  assert_true(b.admit(equation([0, 0, 0], [0])) is Dependent)
  assert_true(rejects(() => b.admit(equation([0, 0, 0], [1]))))
  ignore(b.admit(equation([0, 0, 2], [8])))
  assert_eq(b.pivots(), [2])
  assert_eq(b.known()[0].1.to_array(), [4])
  assert_true(rejects(() => b.admit(equation([1, 0], [0]))))
  assert_eq(b.rank(), 1)
}
