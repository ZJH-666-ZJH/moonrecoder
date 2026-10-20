///|
pub struct Feedback {
  generation_value : Generation
  priv pivot_values : Array[Int32]
}

///|
pub fn Feedback::new(
  generation : Generation,
  pivots : Array[Int32],
) -> Feedback raise CodeError {
  if pivots.length() > generation.count() {
    raise Shape("feedback rank exceeds source count")
  }
  let mut previous = -1
  for pivot in pivots {
    if pivot <= previous || pivot >= generation.count() {
      raise Invalid("feedback pivots must be sorted, unique and in range")
    }
    previous = pivot
  }
  { generation_value: generation, pivot_values: copy_values(pivots), }
}

///|
pub fn Feedback::generation(self : Feedback) -> Generation {
  self.generation_value
}

///|
pub fn Feedback::pivots(self : Feedback) -> Array[Int32] {
  copy_values(self.pivot_values)
}

///|
pub fn Feedback::rank(self : Feedback) -> Int32 {
  self.pivot_values.length()
}

///|
pub fn Feedback::deficit(self : Feedback) -> Int32 {
  self.generation_value.count() - self.rank()
}

///|
pub fn Feedback::missing_pivots(self : Feedback) -> Array[Int32] {
  let out : Array[Int32] = []
  let mut cursor = 0
  for i in 0..<self.generation_value.count() {
    if cursor < self.pivot_values.length() && self.pivot_values[cursor] == i {
      cursor = cursor + 1
    } else {
      out.push(i)
    }
  }
  out
}

///|
pub fn Decoder::feedback(self : Decoder) -> Feedback {
  { generation_value: self.generation(), pivot_values: self.pivots(), }
}

///|
// e_j for each absent pivot complements the REPORTED row span.
// Feedback is a hint: stale/forged reports cannot guarantee current innovation.
pub fn Encoder::repair(
  self : Encoder,
  feedback : Feedback,
  first_sequence : Int32,
) -> Array[Packet] raise CodeError {
  if !feedback.generation().same(self.generation()) {
    raise Shape("feedback belongs to another generation")
  }
  if first_sequence < 0 {
    raise Invalid("negative repair sequence")
  }
  let missing = feedback.missing_pivots()
  if missing.length() > 0 &&
    first_sequence > 2147483647 - (missing.length() - 1) {
    raise Limit("repair sequence overflow")
  }
  let out : Array[Packet] = []
  for i in 0..<missing.length() {
    out.push(self.systematic(missing[i], first_sequence + i))
  }
  out
}
