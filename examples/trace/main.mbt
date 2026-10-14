///|
fn main {
  try {
    let a = @r.Encoder::new(31, @r.Symbols::from_bytes(b"trace-A"), 4)
    let b = @r.Encoder::new(32, @r.Symbols::from_bytes(b"trace-B"), 4)
    let replay = @r.Replay::new(a.generation())
    println(replay.feed_hex("not-hex").to_json())
    let first = a.systematic(0, 0).to_wire().to_hex()
    println(replay.feed_hex(first).to_json())
    println(replay.feed_hex(first).to_json())
    println(replay.feed_hex(a.systematic(1, 1).to_wire().to_hex()).to_json())
    assert_eq(replay.rejected(), 1)
    assert_true(replay.recover().equal(@r.Symbols::from_bytes(b"trace-A")))
    // Stream two interleaved generations in arbitrary network chunks.
    let wire = a
      .systematic(0, 0)
      .to_wire()
      .concat(b.systematic(1, 1).to_wire())
      .concat(a.systematic(1, 1).to_wire())
      .concat(b.systematic(0, 0).to_wire())
    let reader = @r.FrameReader::new()
    let pool = @r.SessionPool::new(max_generations=2, max_cells=24)
    let mut offset = 0
    while offset < wire.length() {
      let end = if offset + 7 < wire.length() {
        offset + 7
      } else {
        wire.length()
      }
      for packet in reader.feed(wire.slice(offset, end)) {
        ignore(pool.admit(packet))
      }
      offset = end
    }
    reader.finish()
    assert_true(pool.take(31).equal(@r.Symbols::from_bytes(b"trace-A")))
    assert_true(pool.take(32).equal(@r.Symbols::from_bytes(b"trace-B")))
    assert_eq(pool.reserved_cells(), 0)
    println(
      "trace: rejected malformed hex, diagnosed duplicate, recovered two interleaved generations",
    )
  } catch {
    error => {
      println(error.to_string())
      panic()
    }
  }
}
