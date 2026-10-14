///|
test "systematic padding and arbitrary source equation" {
  let enc = Encoder::new(9, Symbols::new([1, 2, 3, 4, 5]), 2)
  assert_eq(enc.generation().count(), 3)
  assert_eq(enc.systematic(2, 2).payload().to_array(), [5, 0])
  assert_eq(enc.encode(Symbols::new([1, 1, 1]), 8).payload().to_array(), [7, 6])
  assert_true(enc.encode(Symbols::new([0, 0, 0]), 9).payload().is_zero())
  let sources = enc.source_symbols()
  sources[0] = Symbols::new([99, 99])
  assert_eq(enc.systematic(0, 0).payload().to_array(), [1, 2])
  assert_true(rejects(() => enc.systematic(3, 0)))
  assert_true(rejects(() => Encoder::new(0, Symbols::new([]), 1)))
  assert_true(rejects(() => Encoder::new(0, Symbols::zeros(65), 1)))
}

///|
test "external source symbols require canonical padding" {
  let g = Generation::new(1, 2, 2, 3)
  assert_true(
    rejects(() => {
      Encoder::from_symbols(g, [Symbols::new([1, 2]), Symbols::new([3, 4])])
    }),
  )
  let enc = Encoder::from_symbols(g, [
    Symbols::new([1, 2]),
    Symbols::new([3, 0]),
  ])
  assert_eq(enc.systematic(1, 0).payload().to_array(), [3, 0])
}
