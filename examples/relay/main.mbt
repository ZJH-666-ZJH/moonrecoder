///|
fn main {
  try {
    let input = @r.Symbols::from_bytes(b"relay-cannot-yet-decode")
    let source = @r.Encoder::new(23, input, 8)
    let relay = @r.Relay::new(source.generation())
    ignore(relay.admit(source.systematic(0, 0)))
    ignore(relay.admit(source.systematic(2, 2)))
    assert_eq(relay.rank(), 2)
    assert_eq(source.generation().count(), 3)
    // The relay never has full rank. Mix two rows without recovering the source.
    let downstream = @r.Decoder::new(source.generation())
    ignore(
      downstream.admit(
        @r.packet_from_wire(relay.mix(@r.Symbols::new([1, 1]), 20).to_wire()),
      ),
    )
    ignore(
      downstream.admit(
        @r.packet_from_wire(relay.mix(@r.Symbols::new([1, 2]), 21).to_wire()),
      ),
    )
    assert_eq(downstream.rank(), 2)
    assert_eq(relay.rank(), 2)
    ignore(downstream.admit(source.systematic(1, 22)))
    assert_true(downstream.recover().equal(input))
    println(
      "relay: rank-2 incomplete relay recoded; downstream recovered rank-3 generation",
    )
    println(downstream.report().to_json())
  } catch {
    error => {
      println(error.to_string())
      panic()
    }
  }
}
