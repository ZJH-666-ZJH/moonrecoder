///|
fn main {
  try {
    let input = @r.Symbols::from_bytes(b"sensor=23.75;unit=C;seq=17")
    let source = @r.Encoder::new(17, input, 6)
    let receiver = @r.Decoder::new(source.generation())
    // Simulate two dropped systematic packets and one network duplicate.
    for index in 0..<source.generation().count() {
      if index != 1 && index != 3 {
        let packet = @r.packet_from_wire(
          source.systematic(index, index).to_wire(),
        )
        ignore(receiver.admit(packet))
        if index == 0 {
          ignore(receiver.admit(packet))
        }
      }
    }
    assert_eq(receiver.deficit(), 2)
    let hint = @r.feedback_from_wire(receiver.feedback().to_wire())
    let repairs = source.repair(hint, 100)
    assert_eq(repairs.length(), 2)
    ignore(receiver.admit_batch(repairs))
    assert_true(receiver.recover().equal(input))
    assert_eq(receiver.dependent(), 1)
    println(
      "telemetry: two losses repaired, duplicate detected, exact bytes recovered",
    )
    println(receiver.report().to_json())
  } catch {
    error => {
      println(error.to_string())
      panic()
    }
  }
}
