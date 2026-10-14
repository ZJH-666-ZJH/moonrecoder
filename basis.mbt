///|
pub struct Equation {
  coefficients : Symbols
  payload : Symbols
}

///|
pub fn Equation::new(
  coefficients : Symbols,
  payload : Symbols,
) -> Equation raise CodeError {
  if coefficients.length() < 1 || coefficients.length() > 64 {
    raise Limit("equation coefficient count must be 1..64")
  }
  if payload.length() < 1 || payload.length() > 4096 {
    raise Limit("equation payload width must be 1..4096")
  }
  { coefficients, payload, }
}

///|
pub fn Equation::coefficients(self : Equation) -> Symbols {
  self.coefficients
}

///|
pub fn Equation::payload(self : Equation) -> Symbols {
  self.payload
}

///|
pub enum Admission {
  Innovative(Int, Int)
  Dependent
}

///|
pub struct Basis {
  columns : Int
  width : Int
  rows : Array[Equation?]
  mut rank_value : Int
}

///|
pub fn Basis::new(columns : Int, width : Int) -> Basis raise CodeError {
  if columns < 1 || columns > 64 {
    raise Limit("basis columns must be 1..64")
  }
  if width < 1 || width > 4096 {
    raise Limit("basis payload width must be 1..4096")
  }
  { columns, width, rows: Array::make(columns, None), rank_value: 0, }
}

///|
pub fn Basis::rank(self : Basis) -> Int {
  self.rank_value
}

///|
pub fn Basis::deficit(self : Basis) -> Int {
  self.columns - self.rank_value
}

///|
pub fn Basis::pivots(self : Basis) -> Array[Int] {
  let out : Array[Int] = []
  for i in 0..<self.columns {
    if self.rows[i] is Some(_) {
      out.push(i)
    }
  }
  out
}

///|
pub fn Basis::equations(self : Basis) -> Array[Equation] {
  let out : Array[Equation] = []
  for row in self.rows {
    if row is Some(equation) {
      out.push(equation)
    }
  }
  out
}

///|
// Compute everything privately, then publish the new RREF state atomically.
// A dependent nonzero residual is a contradiction, never an innovation.
pub fn Basis::admit(
  self : Basis,
  equation : Equation,
) -> Admission raise CodeError {
  if equation.coefficients.length() != self.columns ||
    equation.payload.length() != self.width {
    raise Shape("equation does not match basis dimensions")
  }
  let coefficients = equation.coefficients.to_array()
  let payload = equation.payload.to_array()
  for i in 0..<self.columns {
    if self.rows[i] is Some(row) {
      let factor = coefficients[i]
      if factor == 0 {
        continue
      }
      for j in i..<self.columns {
        coefficients[j] = coefficients[j] ^
          mul(factor, row.coefficients.values[j])
      }
      for j in 0..<self.width {
        payload[j] = payload[j] ^ mul(factor, row.payload.values[j])
      }
    }
  }
  let mut pivot = 0
  while pivot < self.columns && coefficients[pivot] == 0 {
    pivot = pivot + 1
  }
  if pivot == self.columns {
    for value in payload {
      if value != 0 {
        raise Inconsistent
      }
    }
    return Dependent
  }
  let inverse = power(coefficients[pivot], 254)
  for i in pivot..<self.columns {
    coefficients[i] = mul(coefficients[i], inverse)
  }
  for i in 0..<self.width {
    payload[i] = mul(payload[i], inverse)
  }
  let fresh : Equation = {
    coefficients: { values: coefficients, },
    payload: { values: payload, },
  }
  let updates : Array[(Int, Equation)] = []
  for i in 0..<self.columns {
    if self.rows[i] is Some(row) {
      let factor = row.coefficients.values[pivot]
      if factor == 0 {
        continue
      }
      let c = row.coefficients.to_array()
      let p = row.payload.to_array()
      for j in pivot..<self.columns {
        c[j] = c[j] ^ mul(factor, coefficients[j])
      }
      for j in 0..<self.width {
        p[j] = p[j] ^ mul(factor, payload[j])
      }
      updates.push(
        (i, { coefficients: { values: c, }, payload: { values: p, }, }),
      )
    }
  }
  for update in updates {
    self.rows[update.0] = Some(update.1)
  }
  self.rows[pivot] = Some(fresh)
  self.rank_value = self.rank_value + 1
  Innovative(pivot, self.rank_value)
}

///|
pub fn Basis::recover(self : Basis) -> Array[Symbols] raise CodeError {
  if self.deficit() != 0 {
    raise Incomplete(self.deficit())
  }
  let out : Array[Symbols] = []
  for row in self.rows {
    match row {
      Some(equation) => out.push(equation.payload)
      None => raise Incomplete(self.deficit())
    }
  }
  out
}

///|
// Rows containing just one coefficient already determine a source symbol.
pub fn Basis::known(self : Basis) -> Array[(Int, Symbols)] {
  let out : Array[(Int, Symbols)] = []
  for i in 0..<self.columns {
    if self.rows[i] is Some(row) {
      let mut isolated = true
      for j in 0..<self.columns {
        if j != i && row.coefficients.values[j] != 0 {
          isolated = false
        }
      }
      if isolated {
        out.push((i, row.payload))
      }
    }
  }
  out
}
