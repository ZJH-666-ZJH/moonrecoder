///|
test "public symbol and matrix accessors detach mutable arrays" {
  let raw = [1, 2]
  let symbols = @moonrecoder.Symbols::new(raw)
  raw[0] = 256
  let values = symbols.to_array()
  values[1] = -1
  assert_eq(symbols.to_array(), [1, 2])
  let rows = [[1, 0], [0, 1]]
  let matrix = @moonrecoder.FieldMatrix::new(rows)
  rows[0][0] = 0
  let copy = matrix.to_arrays()
  copy[1].clear()
  assert_eq(matrix.rank(), 2)
  assert_eq(matrix.to_arrays(), [[1, 0], [0, 1]])
}

///|
test "public decoder views and forks do not bypass admission state" {
  let encoder = @moonrecoder.Encoder::new(
    7,
    @moonrecoder.Symbols::new([7, 9]),
    1,
  )
  let decoder = @moonrecoder.Decoder::new(encoder.generation(), max_packets=2)
  ignore(decoder.admit(encoder.systematic(0, 0)))
  let equations = decoder.basis_equations()
  let coefficients = equations[0].coefficients().to_array()
  coefficients[0] = 0
  equations.clear()
  let pivots = decoder.pivots()
  pivots.clear()
  let report = decoder.report()
  report.pivots.clear()
  let hint = decoder.feedback()
  let hint_pivots = hint.pivots()
  hint_pivots[0] = 99
  let fork = decoder.fork()
  ignore(fork.admit(encoder.systematic(1, 1)))
  assert_eq(fork.rank(), 2)
  assert_eq(decoder.rank(), 1)
  assert_eq(decoder.admitted(), 1)
  assert_eq(decoder.remaining_packets(), 1)
  assert_eq(decoder.pivots(), [0])
  assert_eq(hint.pivots(), [0])
  assert_true(decoder.is_reduced())
}

///|
test "public encoder and replay views do not mutate owned containers" {
  let encoder = @moonrecoder.Encoder::new(
    8,
    @moonrecoder.Symbols::new([3, 4]),
    1,
  )
  let source = encoder.source_symbols()
  source.clear()
  assert_eq(encoder.systematic(0, 0).payload().to_array(), [3])
  let replay = @moonrecoder.Replay::new(encoder.generation())
  ignore(replay.feed_hex(encoder.systematic(0, 0).to_wire().to_hex()))
  let events = replay.events()
  events.clear()
  assert_eq(replay.events().length(), 1)
  assert_eq(replay.report().rank, 1)
}
