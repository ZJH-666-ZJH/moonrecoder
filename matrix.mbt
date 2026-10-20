///|
pub struct FieldMatrix {
  priv cells : Array[Symbols]
  columns : Int32
}

///|
pub fn FieldMatrix::new(
  rows : Array[Array[Int32]],
) -> FieldMatrix raise CodeError {
  if rows.length() == 0 || rows.length() > 64 {
    raise Limit("matrix row count must be 1..64")
  }
  let columns = rows[0].length()
  if columns == 0 || columns > 64 {
    raise Limit("matrix column count must be 1..64")
  }
  let cells : Array[Symbols] = []
  for row in rows {
    if row.length() != columns {
      raise Shape("ragged matrix")
    }
    cells.push(Symbols::new(row))
  }
  { cells, columns, }
}

///|
pub fn FieldMatrix::identity(size : Int32) -> FieldMatrix raise CodeError {
  if size < 1 || size > 64 {
    raise Limit("identity size must be 1..64")
  }
  let rows : Array[Array[Int32]] = []
  for i in 0..<size {
    let row = Array::make(size, 0)
    row[i] = 1
    rows.push(row)
  }
  FieldMatrix::new(rows)
}

///|
pub fn FieldMatrix::rows(self : FieldMatrix) -> Int32 {
  self.cells.length()
}

///|
pub fn FieldMatrix::cols(self : FieldMatrix) -> Int32 {
  self.columns
}

///|
pub fn FieldMatrix::to_arrays(self : FieldMatrix) -> Array[Array[Int32]] {
  self.cells.map(row => row.to_array())
}

///|
pub fn FieldMatrix::transpose(self : FieldMatrix) -> FieldMatrix {
  let cells : Array[Symbols] = []
  for col in 0..<self.cols() {
    let values : Array[Int32] = []
    for row in 0..<self.rows() {
      values.push(self.cells[row].values[col])
    }
    cells.push({ values, })
  }
  { cells, columns: self.rows(), }
}

///|
pub fn FieldMatrix::multiply(
  self : FieldMatrix,
  other : FieldMatrix,
) -> FieldMatrix raise CodeError {
  if self.cols() != other.rows() {
    raise Shape("matrix multiplication dimension mismatch")
  }
  let right = other.transpose()
  let cells : Array[Symbols] = []
  for row in self.cells {
    let values : Array[Int32] = []
    for col in right.cells {
      values.push(row.dot(col))
    }
    cells.push({ values, })
  }
  { cells, columns: other.cols(), }
}

///|
// This independent batch elimination is also a reference for streaming rank.
pub fn FieldMatrix::rank(self : FieldMatrix) -> Int32 {
  let rows = self.to_arrays()
  let mut pivot = 0
  for col in 0..<self.cols() {
    let mut found = pivot
    while found < self.rows() && rows[found][col] == 0 {
      found = found + 1
    }
    if found == self.rows() {
      continue
    }
    let tmp = rows[pivot]
    rows[pivot] = rows[found]
    rows[found] = tmp
    let inverse = power(rows[pivot][col], 254)
    for j in col..<self.cols() {
      rows[pivot][j] = mul(rows[pivot][j], inverse)
    }
    for i in (pivot + 1)..<self.rows() {
      let factor = rows[i][col]
      for j in col..<self.cols() {
        rows[i][j] = rows[i][j] ^ mul(factor, rows[pivot][j])
      }
    }
    pivot = pivot + 1
    if pivot == self.rows() {
      break
    }
  }
  pivot
}

///|
pub fn FieldMatrix::inverse(self : FieldMatrix) -> FieldMatrix raise CodeError {
  if self.rows() != self.cols() {
    raise Shape("inverse requires a square matrix")
  }
  let n = self.rows()
  let rows = self.to_arrays()
  let result = FieldMatrix::identity(n).to_arrays()
  for col in 0..<n {
    let mut found = col
    while found < n && rows[found][col] == 0 {
      found = found + 1
    }
    if found == n {
      raise Invalid("matrix is singular")
    }
    let tmp = rows[col]
    rows[col] = rows[found]
    rows[found] = tmp
    let swap = result[col]
    result[col] = result[found]
    result[found] = swap
    let inverse = power(rows[col][col], 254)
    for j in 0..<n {
      rows[col][j] = mul(rows[col][j], inverse)
      result[col][j] = mul(result[col][j], inverse)
    }
    for i in 0..<n {
      if i == col {
        continue
      }
      let factor = rows[i][col]
      for j in 0..<n {
        rows[i][j] = rows[i][j] ^ mul(factor, rows[col][j])
        result[i][j] = result[i][j] ^ mul(factor, result[col][j])
      }
    }
  }
  FieldMatrix::new(result)
}
