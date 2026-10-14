///|
// Independent schoolbook carry-less product, then long division by x^8+x^4+x^3+x^2+1.
fn oracle_product(a : Int, b : Int) -> Int {
  let mut product = 0
  for bit in 0..<8 {
    if (b & (1 << bit)) != 0 {
      product = product ^ (a << bit)
    }
  }
  for bit = 14; bit >= 8; bit = bit - 1 {
    if (product & (1 << bit)) != 0 {
      product = product ^ (285 << (bit - 8))
    }
  }
  product
}

///|
test "all 65536 byte products match independent polynomial long division" {
  for a in 0..<256 {
    for b in 0..<256 {
      assert_eq(gf_mul(a, b), oracle_product(a, b))
    }
  }
}

///|
test "streaming augmented rank agrees with batch elimination across prefixes" {
  let stream = CoefficientStream::new(0x8a76b5U)
  for size in 1..<17 {
    let source = Symbols::new(
      Array::makei(size * 3 - 1, i => (i * 37 + size) % 256),
    )
    let encoder = Encoder::new(size, source, 3)
    let decoder = Decoder::new(encoder.generation())
    let rows : Array[Array[Int]] = []
    for sequence in 0..<(size * 2) {
      let coefficients = stream.draw(size)
      rows.push(coefficients.to_array())
      ignore(decoder.admit(encoder.encode(coefficients, sequence)))
      assert_eq(decoder.rank(), FieldMatrix::new(rows).rank())
      assert_true(decoder.is_reduced())
    }
    // Feedback completes even if a particular deterministic stream is rank deficient.
    for packet in encoder.repair(decoder.feedback(), size * 2) {
      ignore(decoder.admit(packet))
    }
    assert_true(decoder.recover().equal(source))
  }
}

///|
test "every nonzero two-row relay mix lies in the source span" {
  let encoder = Encoder::new(42, Symbols::new([10, 20, 30, 40, 50, 60]), 2)
  let relay = Relay::new(encoder.generation())
  ignore(relay.admit(encoder.systematic(0, 0)))
  ignore(relay.admit(encoder.systematic(2, 2)))
  for weight in 1..<256 {
    let packet = relay.mix(Symbols::new([weight, 1]), weight)
    let direct = encoder.encode(packet.equation().coefficients(), weight)
    assert_true(packet.equation().payload().equal(direct.equation().payload()))
  }
  assert_eq(relay.rank(), 2)
}

///|
test "all single split points preserve wire stream and receiver state" {
  let encoder = Encoder::new(7, Symbols::new([1, 2, 3, 4, 5]), 2)
  let a = encoder.systematic(2, 10).to_wire()
  let b = encoder.systematic(0, 11).to_wire()
  let c = encoder.systematic(1, 12).to_wire()
  let wire = a.concat(b).concat(c)
  for split in 0..<(wire.length() + 1) {
    let reader = FrameReader::new()
    let decoder = Decoder::new(encoder.generation())
    for packet in reader.feed(wire.slice(0, split)) {
      ignore(decoder.admit(packet))
    }
    for packet in reader.feed(wire.slice(split, wire.length())) {
      ignore(decoder.admit(packet))
    }
    reader.finish()
    assert_eq(reader.frames(), 3)
    assert_true(decoder.recover().equal(Symbols::new([1, 2, 3, 4, 5])))
  }
}
