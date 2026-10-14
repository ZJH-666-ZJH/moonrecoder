///|
test "offline replay records damage duplicates and contradictions without state pollution" {
  let enc = Encoder::new(8, Symbols::new([5, 6]), 1)
  let replay = Replay::new(enc.generation(), max_events=6)
  assert_eq(replay.feed_hex("zz").status(), "rejected")
  assert_true(replay.events()[0].error_kind() is Some("invalid"))
  assert_eq(
    replay.feed_wire(enc.systematic(0, 1).to_wire()).status(),
    "innovative",
  )
  assert_eq(
    replay.feed_wire(enc.systematic(0, 1).to_wire()).status(),
    "dependent",
  )
  let bad = Packet::new(enc.generation(), 99, equation([1, 0], [4]))
  assert_true(
    replay.feed_wire(bad.to_wire()).error_kind() is Some("inconsistent"),
  )
  assert_eq(replay.report().rank, 1)
  assert_eq(
    replay.feed_hex(enc.systematic(1, 2).to_wire().to_hex()).status(),
    "innovative",
  )
  assert_eq(replay.recover().to_array(), [5, 6])
  assert_eq(replay.rejected(), 2)
  assert_true(replay.events()[3].to_json().length() > 30)
  ignore(replay.feed_hex(""))
  assert_true(rejects(() => replay.feed_hex("")))
  assert_eq(replay.events().length(), 6)
}
