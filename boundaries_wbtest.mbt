///|
test "maximum generation and frame boundaries roundtrip without byte loss" {
  let source = Symbols::new(Array::makei(262144, i => i % 256))
  let encoder = Encoder::new(2147483647, source, 4096)
  assert_eq(encoder.generation().count(), 64)
  let packet = encoder.systematic(63, 2147483647)
  assert_eq(packet.wire_length(), 4188)
  let parsed = packet_from_wire(packet.to_wire())
  assert_true(parsed.generation().same(encoder.generation()))
  assert_true(parsed.payload().equal(packet.payload()))
  assert_true(rejects(() => Generation::new(0, 65, 1, 65)))
  assert_true(rejects(() => Generation::new(0, 1, 4097, 1)))
  assert_true(rejects(() => Generation::new(0, 2, 4, 4)))
}

///|
test "valid then corrupt frame feed is atomic and can be retried" {
  let encoder = Encoder::new(0, Symbols::new([1, 2]), 1)
  let first = encoder.systematic(0, 0).to_wire()
  let second = encoder.systematic(1, 1).to_wire()
  let damaged = second.to_array()
  damaged[damaged.length() - 1] = damaged[damaged.length() - 1] ^ 1
  let reader = FrameReader::new()
  assert_true(rejects(() => reader.feed(first.concat(Symbols::new(damaged)))))
  assert_eq(reader.frames(), 0)
  assert_eq(reader.received_bytes(), 0)
  assert_eq(reader.buffered(), 0)
  assert_eq(reader.feed(first.concat(second)).length(), 2)
  reader.finish()
}

///|
test "stale feedback is harmless but does not promise current innovation" {
  let encoder = Encoder::new(0, Symbols::new([1, 2, 3]), 1)
  let decoder = Decoder::new(encoder.generation())
  let stale = decoder.feedback()
  ignore(decoder.admit(encoder.systematic(0, 0)))
  let repairs = encoder.repair(stale, 10)
  ignore(decoder.admit_batch(repairs))
  assert_eq(decoder.dependent(), 1)
  assert_eq(decoder.rank(), 3)
  assert_true(rejects(() => encoder.repair(stale, 2147483647)))
}

///|
test "packet budget and malformed wire batch preserve all decoder counters" {
  let encoder = Encoder::new(0, Symbols::new([1, 2]), 1)
  let decoder = Decoder::new(encoder.generation(), max_packets=1)
  assert_true(
    rejects(() => {
      decoder.admit_batch([encoder.systematic(0, 0), encoder.systematic(1, 1)])
    }),
  )
  assert_eq(decoder.admitted(), 0)
  assert_true(rejects(() => decoder.admit_wire_batch([Symbols::new([0])])))
  assert_eq(decoder.rank(), 0)
  ignore(decoder.admit(encoder.systematic(0, 0)))
  assert_true(rejects(() => decoder.admit(encoder.systematic(1, 1))))
  assert_eq(decoder.admitted(), 1)
  assert_eq(decoder.rank(), 1)
}
