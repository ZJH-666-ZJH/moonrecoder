///|
test "incomplete relay recodes without decoding source" {
  let input = Symbols::new([1, 2, 3, 4, 5, 6])
  let enc = Encoder::new(1, input, 2)
  let relay = Relay::new(enc.generation())
  ignore(relay.admit(enc.encode(Symbols::new([1, 1, 0]), 0)))
  ignore(relay.admit(enc.encode(Symbols::new([0, 1, 1]), 1)))
  assert_eq(relay.rank(), 2)
  let downstream = Decoder::new(enc.generation())
  let packet = relay.mix(Symbols::new([7, 9]), 9)
  assert_true(
    packet.payload().equal(enc.encode(packet.coefficients(), 9).payload()),
  )
  ignore(downstream.admit(packet))
  for row in relay.basis_packets(10) {
    ignore(downstream.admit(row))
  }
  assert_eq(downstream.rank(), 2)
  assert_true(rejects(() => downstream.recover()))
  ignore(downstream.admit(enc.systematic(0, 2)))
  assert_true(downstream.recover().equal(input))
}

///|
test "relay rejects empty and degenerate recoding" {
  let enc = Encoder::new(0, Symbols::new([1, 2]), 1)
  let relay = Relay::new(enc.generation())
  let stream = CoefficientStream::new(1U)
  assert_true(rejects(() => relay.coded(stream, 0)))
  assert_eq(stream.draws(), 0)
  ignore(relay.admit(enc.systematic(0, 0)))
  assert_true(rejects(() => relay.mix(Symbols::new([0]), 0)))
  assert_true(rejects(() => relay.mix(Symbols::new([1, 1]), 0)))
  assert_eq(relay.rank(), 1)
}
