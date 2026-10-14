///|
test "all stream split positions and multiple packets" {
  let enc = Encoder::new(0, Symbols::new([1, 2, 3]), 1)
  let bytes = enc
    .systematic(0, 0)
    .to_wire()
    .concat(enc.systematic(1, 1).to_wire())
  for cut in 0..<(bytes.length() + 1) {
    let reader = FrameReader::new()
    let first = reader.feed(bytes.slice(0, cut))
    let second = reader.feed(bytes.slice(cut, bytes.length()))
    reader.finish()
    assert_eq(first.length() + second.length(), 2)
    assert_eq(reader.frames(), 2)
    assert_eq(reader.received_bytes(), bytes.length())
    assert_eq(reader.buffered(), 0)
  }
}

///|
test "framing rollback on corrupt later frame and limits" {
  let enc = Encoder::new(0, Symbols::new([1]), 1)
  let wire = enc.systematic(0, 0).to_wire()
  let bad = wire.to_array()
  bad[29] = bad[29] ^ 1
  let reader = FrameReader::new(max_frames=2)
  assert_true(rejects(() => reader.feed(wire.concat(Symbols::new(bad)))))
  assert_eq(reader.frames(), 0)
  assert_eq(reader.received_bytes(), 0)
  ignore(reader.feed(wire.slice(0, 3)))
  assert_true(rejects(() => reader.finish()))
  ignore(reader.feed(wire.slice(3, wire.length())))
  reader.finish()
  let limited = FrameReader::new(max_bytes=30)
  ignore(limited.feed(wire))
  assert_true(rejects(() => limited.feed(wire)))
  assert_eq(limited.received_bytes(), 30)
}
