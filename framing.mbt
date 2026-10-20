///|
pub struct FrameReader {
  priv mut pending : Array[Int32]
  mut byte_count : Int32
  mut frame_count : Int32
  byte_limit : Int32
  frame_limit : Int32
}

///|
pub fn FrameReader::new(
  max_bytes~ : Int32 = 1048576,
  max_frames~ : Int32 = 4096,
) -> FrameReader raise CodeError {
  if max_bytes < 30 || max_bytes > 16777216 {
    raise Limit("stream byte budget must be 30..16777216")
  }
  if max_frames < 1 || max_frames > 65536 {
    raise Limit("stream frame budget must be 1..65536")
  }
  {
    pending: [],
    byte_count: 0,
    frame_count: 0,
    byte_limit: max_bytes,
    frame_limit: max_frames,
  }
}

///|
pub fn FrameReader::buffered(self : FrameReader) -> Int32 {
  self.pending.length()
}

///|
pub fn FrameReader::received_bytes(self : FrameReader) -> Int32 {
  self.byte_count
}

///|
pub fn FrameReader::frames(self : FrameReader) -> Int32 {
  self.frame_count
}

///|
fn header_length(
  values : Array[Int32],
  offset : Int32,
) -> Int32 raise CodeError {
  if values[offset] != 77 ||
    values[offset + 1] != 82 ||
    values[offset + 2] != 67 ||
    values[offset + 3] != 49 {
    raise Corrupt("stream packet magic/version mismatch")
  }
  if values[offset + 4] != 0 {
    raise Corrupt("reserved stream packet flags")
  }
  let count = values[offset + 5]
  let width = (values[offset + 6] << 8) | values[offset + 7]
  if count < 1 || count > 64 || width < 1 || width > 4096 {
    raise Limit("stream packet dimensions")
  }
  let length = read_u31(values, offset + 20)
  if length != 28 + count + width {
    raise Shape("stream declared length mismatch")
  }
  length
}

///|
// A failed feed changes neither pending bytes nor counters. There is no resync.
// Each feed validates ALL complete frames before publishing any of them.
pub fn FrameReader::feed(
  self : FrameReader,
  chunk : Symbols,
) -> Array[Packet] raise CodeError {
  if chunk.length() > self.byte_limit - self.byte_count {
    raise Limit("stream byte budget exhausted")
  }
  let values = copy_values(self.pending)
  for byte in chunk.values {
    values.push(byte)
  }
  let out : Array[Packet] = []
  let mut offset = 0
  while values.length() - offset >= 24 {
    let length = header_length(values, offset)
    if values.length() - offset < length {
      break
    }
    if out.length() >= self.frame_limit - self.frame_count {
      raise Limit("stream frame budget exhausted")
    }
    let frame : Array[Int32] = []
    for i in offset..<(offset + length) {
      frame.push(values[i])
    }
    out.push(packet_from_wire({ values: frame, }))
    offset = offset + length
  }
  let pending : Array[Int32] = []
  for i in offset..<values.length() {
    pending.push(values[i])
  }
  if pending.length() > 4188 {
    raise Limit("pending frame exceeds maximum frame length")
  }
  if pending.length() >= 4 &&
    (
      pending[0] != 77 ||
      pending[1] != 82 ||
      pending[2] != 67 ||
      pending[3] != 49
    ) {
    raise Corrupt("partial frame magic/version mismatch")
  }
  self.pending = pending
  self.byte_count = self.byte_count + chunk.length()
  self.frame_count = self.frame_count + out.length()
  out
}

///|
pub fn FrameReader::finish(self : FrameReader) -> Unit raise CodeError {
  if self.pending.length() != 0 {
    raise Truncated
  }
}
