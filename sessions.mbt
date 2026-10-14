///|
pub struct SessionPool {
  mut sessions : Array[Decoder]
  generation_limit : Int
  cell_limit : Int
  packet_limit : Int
  mut cells_used : Int
}

///|
pub fn SessionPool::new(
  max_generations? : Int = 16,
  max_cells? : Int = 1048576,
  max_packets_per_generation? : Int = 4096,
) -> SessionPool raise CodeError {
  if max_generations < 1 || max_generations > 32 {
    raise Limit("pool generation budget must be 1..32")
  }
  if max_cells < 2 || max_cells > 4194304 {
    raise Limit("pool field-cell budget must be 2..4194304")
  }
  if max_packets_per_generation < 1 || max_packets_per_generation > 65536 {
    raise Limit("pool packet budget must be 1..65536")
  }
  {
    sessions: [],
    generation_limit: max_generations,
    cell_limit: max_cells,
    packet_limit: max_packets_per_generation,
    cells_used: 0,
  }
}

///|
fn generation_cells(generation : Generation) -> Int {
  generation.count() * (generation.count() + generation.width())
}

///|
fn SessionPool::find(self : SessionPool, id : Int) -> Int? {
  for i in 0..<self.sessions.length() {
    if self.sessions[i].generation().id() == id {
      return Some(i)
    }
  }
  None
}

///|
pub fn SessionPool::count(self : SessionPool) -> Int {
  self.sessions.length()
}

///|
pub fn SessionPool::reserved_cells(self : SessionPool) -> Int {
  self.cells_used
}

///|
pub fn SessionPool::ids(self : SessionPool) -> Array[Int] {
  self.sessions.map(d => d.generation().id())
}

///|
pub fn SessionPool::reports(self : SessionPool) -> Array[DecodeReport] {
  self.sessions.map(d => d.report())
}

///|
pub fn SessionPool::admit(
  self : SessionPool,
  packet : Packet,
) -> Admission raise CodeError {
  if self.find(packet.generation().id()) is Some(index) {
    return self.sessions[index].admit(packet)
  }
  if self.sessions.length() == self.generation_limit {
    raise Limit("active generation budget exhausted")
  }
  let required = generation_cells(packet.generation())
  if required > self.cell_limit - self.cells_used {
    raise Limit("active field-cell budget exhausted")
  }
  let decoder = Decoder::new(packet.generation(), max_packets=self.packet_limit)
  let admission = decoder.admit(packet)
  self.sessions.push(decoder)
  self.cells_used = self.cells_used + required
  admission
}

///|
pub fn SessionPool::recover(
  self : SessionPool,
  id : Int,
) -> Symbols raise CodeError {
  match self.find(id) {
    Some(index) => self.sessions[index].recover()
    None => raise Invalid("unknown active generation")
  }
}

///|
// Explicit forgetting permits ID reuse; applications must impose replay windows.
pub fn SessionPool::discard(self : SessionPool, id : Int) -> Bool {
  match self.find(id) {
    None => false
    Some(index) => {
      let retained : Array[Decoder] = []
      let released = generation_cells(self.sessions[index].generation())
      for i in 0..<self.sessions.length() {
        if i != index {
          retained.push(self.sessions[i])
        }
      }
      self.sessions = retained
      self.cells_used = self.cells_used - released
      true
    }
  }
}

///|
// Recovery failure keeps the incomplete/invalid session available for inspection.
pub fn SessionPool::take(
  self : SessionPool,
  id : Int,
) -> Symbols raise CodeError {
  let output = self.recover(id)
  ignore(self.discard(id))
  output
}
