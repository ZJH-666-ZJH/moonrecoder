///|
pub struct ReplayEvent {
  index_value : Int
  sequence_value : Int?
  rank_value : Int
  status_value : String
  error_value : String?
}

///|
pub fn ReplayEvent::index(self : ReplayEvent) -> Int {
  self.index_value
}

///|
pub fn ReplayEvent::sequence(self : ReplayEvent) -> Int? {
  self.sequence_value
}

///|
pub fn ReplayEvent::rank(self : ReplayEvent) -> Int {
  self.rank_value
}

///|
pub fn ReplayEvent::status(self : ReplayEvent) -> String {
  self.status_value
}

///|
pub fn ReplayEvent::error_kind(self : ReplayEvent) -> String? {
  self.error_value
}

///|
fn error_kind(error : CodeError) -> String {
  match error {
    Invalid(_) => "invalid"
    Shape(_) => "shape"
    Limit(_) => "limit"
    Inconsistent => "inconsistent"
    Incomplete(_) => "incomplete"
    Corrupt(_) => "corrupt"
    Truncated => "truncated"
  }
}

///|
pub fn ReplayEvent::to_json(self : ReplayEvent) -> String {
  let sequence = match self.sequence_value {
    Some(value) => value.to_string()
    None => "null"
  }
  // Both status/error names are produced internally from fixed enumerations.
  let error = match self.error_value {
    Some(value) => "\"" + value + "\""
    None => "null"
  }
  "{\"index\":" +
  self.index_value.to_string() +
  ",\"sequence\":" +
  sequence +
  ",\"rank\":" +
  self.rank_value.to_string() +
  ",\"status\":\"" +
  self.status_value +
  "\",\"error\":" +
  error +
  "}"
}

///|
pub struct Replay {
  decoder : Decoder
  event_limit : Int
  event_values : Array[ReplayEvent]
  mut rejection_count : Int
}

///|
pub fn Replay::new(
  generation : Generation,
  max_events? : Int = 4096,
) -> Replay raise CodeError {
  {
    decoder: Decoder::new(generation, max_packets=max_events),
    event_limit: max_events,
    event_values: [],
    rejection_count: 0,
  }
}

///|
fn Replay::record(
  self : Replay,
  parse : () -> Packet raise CodeError,
) -> ReplayEvent raise CodeError {
  if self.event_values.length() == self.event_limit {
    raise Limit("replay event budget exhausted")
  }
  let mut sequence : Int? = None
  let mut status = "rejected"
  let mut error : String? = None
  try {
    let packet = parse()
    sequence = Some(packet.sequence())
    match self.decoder.admit(packet) {
      Innovative(_, _) => status = "innovative"
      Dependent => status = "dependent"
    }
  } catch {
    failure => {
      error = Some(error_kind(failure))
      self.rejection_count = self.rejection_count + 1
    }
  }
  let event : ReplayEvent = {
    index_value: self.event_values.length(),
    sequence_value: sequence,
    rank_value: self.decoder.rank(),
    status_value: status,
    error_value: error,
  }
  self.event_values.push(event)
  event
}

///|
pub fn Replay::feed_wire(
  self : Replay,
  frame : Symbols,
) -> ReplayEvent raise CodeError {
  self.record(() => packet_from_wire(frame))
}

///|
pub fn Replay::feed_hex(
  self : Replay,
  text : String,
) -> ReplayEvent raise CodeError {
  self.record(() => packet_from_hex(text))
}

///|
pub fn Replay::events(self : Replay) -> Array[ReplayEvent] {
  let out : Array[ReplayEvent] = []
  for event in self.event_values {
    out.push(event)
  }
  out
}

///|
pub fn Replay::rejected(self : Replay) -> Int {
  self.rejection_count
}

///|
pub fn Replay::report(self : Replay) -> DecodeReport {
  self.decoder.report()
}

///|
pub fn Replay::recover(self : Replay) -> Symbols raise CodeError {
  self.decoder.recover()
}
