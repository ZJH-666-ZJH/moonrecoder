///|
fn rejected_action(f : () -> Unit raise @moonrecoder.CodeError) -> Bool {
  try {
    f()
    false
  } catch {
    _ => true
  }
}

///|
test "feedback repairs complement all binary equation pairs without changing forks" {
  let input = @moonrecoder.Symbols::new([3, 5, 7, 11])
  let encoder = @moonrecoder.Encoder::new(99, input, 1)
  for left in 0..<16 {
    for right in 0..<16 {
      let decoder = @moonrecoder.Decoder::new(encoder.generation())
      for mask in [left, right] {
        let coefficients = @moonrecoder.Symbols::new(
          Array::makei(4, i => (mask >> i) & 1),
        )
        ignore(decoder.admit(encoder.encode(coefficients, mask)))
      }
      let fork = decoder.fork()
      let before = fork.report().to_json()
      let hint = @moonrecoder.feedback_from_wire(decoder.feedback().to_wire())
      let repairs = encoder.repair(hint, 2147483644)
      assert_eq(repairs.length(), decoder.deficit())
      ignore(decoder.admit_batch(repairs))
      assert_eq(decoder.rank(), 4)
      assert_true(decoder.is_reduced())
      assert_true(decoder.recover().equal(input))
      assert_eq(fork.report().to_json(), before)
    }
  }
}

///|
test "every single bit packet mutation is rejected without decoder batch effects" {
  let encoder = @moonrecoder.Encoder::new(
    2147483647,
    @moonrecoder.Symbols::new([1, 2, 3, 4, 5]),
    3,
  )
  let first = encoder.systematic(0, 0).to_wire()
  let frame = encoder.systematic(1, 2147483647).to_wire()
  let decoder = @moonrecoder.Decoder::new(encoder.generation(), max_packets=2)
  for index in 0..<frame.length() {
    for bit in 0..<8 {
      let values = frame.to_array()
      values[index] = values[index] ^ (1 << bit)
      assert_true(
        rejected_action(() => {
          ignore(
            decoder.admit_wire_batch([first, @moonrecoder.Symbols::new(values)]),
          )
        }),
      )
      assert_eq(decoder.rank(), 0)
      assert_eq(decoder.admitted(), 0)
      assert_eq(decoder.dependent(), 0)
      assert_eq(decoder.remaining_packets(), 2)
    }
  }
  ignore(decoder.admit_wire_batch([first, frame]))
  assert_eq(decoder.recover().to_array(), [1, 2, 3, 4, 5])
}

///|
test "all feedback bit mutations reject and leave existing feedback usable" {
  let encoder = @moonrecoder.Encoder::new(
    18,
    @moonrecoder.Symbols::new([9, 8, 7]),
    1,
  )
  let decoder = @moonrecoder.Decoder::new(encoder.generation())
  ignore(decoder.admit(encoder.systematic(1, 1)))
  let frame = decoder.feedback().to_wire()
  for index in 0..<frame.length() {
    for bit in 0..<8 {
      let values = frame.to_array()
      values[index] = values[index] ^ (1 << bit)
      assert_true(
        rejected_action(() => {
          ignore(
            @moonrecoder.feedback_from_wire(@moonrecoder.Symbols::new(values)),
          )
        }),
      )
    }
  }
  ignore(
    decoder.admit_batch(
      encoder.repair(@moonrecoder.feedback_from_wire(frame), 10),
    ),
  )
  assert_eq(decoder.recover().to_array(), [9, 8, 7])
}

///|
test "coefficient failures do not consume stream state in encoder or relay" {
  let encoder = @moonrecoder.Encoder::new(
    1,
    @moonrecoder.Symbols::new([2, 4, 6]),
    1,
  )
  let stream = @moonrecoder.CoefficientStream::new(123U, max_draws=4)
  let reference = @moonrecoder.CoefficientStream::new(123U, max_draws=4)
  let relay = @moonrecoder.Relay::new(encoder.generation())
  assert_true(rejected_action(() => ignore(encoder.coded(stream, -1))))
  assert_true(rejected_action(() => ignore(relay.coded(stream, 0))))
  assert_true(rejected_action(() => ignore(stream.draw(0))))
  assert_true(rejected_action(() => ignore(stream.draw(5))))
  assert_eq(stream.draws(), 0)
  assert_true(stream.draw(3).equal(reference.draw(3)))
  assert_true(rejected_action(() => ignore(encoder.coded(stream, 0))))
  assert_eq(stream.draws(), 3)
  assert_true(stream.draw(1).equal(reference.draw(1)))
}

///|
test "bytewise framing exact budgets and failed extra input preserve state" {
  let encoder = @moonrecoder.Encoder::new(
    4,
    @moonrecoder.Symbols::new([1, 2, 3]),
    2,
  )
  let wire = encoder
    .systematic(0, 0)
    .to_wire()
    .concat(encoder.systematic(1, 1).to_wire())
  let reader = @moonrecoder.FrameReader::new(
    max_bytes=wire.length(),
    max_frames=2,
  )
  let decoder = @moonrecoder.Decoder::new(encoder.generation())
  for i in 0..<wire.length() {
    ignore(decoder.admit_batch(reader.feed(wire.slice(i, i + 1))))
  }
  reader.finish()
  assert_eq(reader.frames(), 2)
  assert_eq(reader.buffered(), 0)
  assert_eq(reader.received_bytes(), wire.length())
  assert_eq(decoder.recover().to_array(), [1, 2, 3])
  assert_true(
    rejected_action(() => ignore(reader.feed(@moonrecoder.Symbols::new([77])))),
  )
  assert_eq(reader.received_bytes(), wire.length())
  assert_eq(reader.feed(@moonrecoder.Symbols::new([])).length(), 0)
  reader.finish()
}

///|
test "pool failed conflicting generation retains reservation and detached reports" {
  let first = @moonrecoder.Encoder::new(
    17,
    @moonrecoder.Symbols::new([3, 6]),
    1,
  )
  let conflict = @moonrecoder.Encoder::new(
    17,
    @moonrecoder.Symbols::new([1, 2, 3]),
    1,
  )
  let pool = @moonrecoder.SessionPool::new(max_generations=1, max_cells=6)
  ignore(pool.admit(first.systematic(0, 0)))
  let reports = pool.reports()
  reports[0].pivots.clear()
  let ids = pool.ids()
  ids.clear()
  assert_true(
    rejected_action(() => ignore(pool.admit(conflict.systematic(0, 0)))),
  )
  assert_eq(pool.count(), 1)
  assert_eq(pool.reserved_cells(), 6)
  assert_eq(pool.reports()[0].pivots, [0])
  assert_true(rejected_action(() => ignore(pool.take(17))))
  assert_eq(pool.reserved_cells(), 6)
  ignore(pool.admit(first.systematic(1, 1)))
  assert_eq(pool.take(17).to_array(), [3, 6])
  assert_eq(pool.count(), 0)
  assert_eq(pool.reserved_cells(), 0)
  ignore(pool.admit(first.systematic(0, 0)))
  assert_eq(pool.ids(), [17])
}
