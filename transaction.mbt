///|
fn Basis::fork(self : Basis) -> Basis {
  let rows : Array[Equation?] = []
  for row in self.rows {
    rows.push(row)
  }
  {
    columns: self.columns,
    width: self.width,
    rows,
    rank_value: self.rank_value,
  }
}

///|
// The copied row containers share only immutable-by-API Symbols.
pub fn Decoder::fork(self : Decoder) -> Decoder {
  {
    generation_value: self.generation_value,
    basis: self.basis.fork(),
    packet_limit: self.packet_limit,
    admitted_count: self.admitted_count,
    dependent_count: self.dependent_count,
  }
}

///|
pub fn Decoder::admit_batch(
  self : Decoder,
  packets : Array[Packet],
) -> Array[Admission] raise CodeError {
  if packets.length() > self.remaining_packets() {
    raise Limit("batch exceeds remaining decoder packet budget")
  }
  let staged = self.fork()
  let out : Array[Admission] = []
  for packet in packets {
    out.push(staged.admit(packet))
  }
  self.basis = staged.basis
  self.admitted_count = staged.admitted_count
  self.dependent_count = staged.dependent_count
  out
}

///|
pub fn Decoder::admit_wire_batch(
  self : Decoder,
  frames : Array[Symbols],
) -> Array[Admission] raise CodeError {
  if frames.length() > self.remaining_packets() {
    raise Limit("wire batch exceeds remaining decoder budget")
  }
  let packets : Array[Packet] = []
  for frame in frames {
    packets.push(packet_from_wire(frame))
  }
  self.admit_batch(packets)
}

///|
// Diagnostic invariant check, including normalized pivots and cross-row zeros.
pub fn Decoder::is_reduced(self : Decoder) -> Bool {
  let rows = self.basis.rows
  let mut count = 0
  for i in 0..<rows.length() {
    if rows[i] is Some(row) {
      count = count + 1
      if row.coefficients.values[i] != 1 {
        return false
      }
      for j in 0..<i {
        if row.coefficients.values[j] != 0 {
          return false
        }
      }
      for j in 0..<rows.length() {
        if j != i && rows[j] is Some(_) && row.coefficients.values[j] != 0 {
          return false
        }
      }
    }
  }
  count == self.rank()
}
