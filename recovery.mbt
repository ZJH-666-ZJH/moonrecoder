///|
pub(all) struct DecodeReport {
  generation_id : Int32
  source_count : Int32
  rank : Int32
  deficit : Int32
  admitted : Int32
  dependent : Int32
  known : Int32
  pivots : Array[Int32]
}

///|
pub fn Decoder::report(self : Decoder) -> DecodeReport {
  {
    generation_id: self.generation().id(),
    source_count: self.generation().count(),
    rank: self.rank(),
    deficit: self.deficit(),
    admitted: self.admitted(),
    dependent: self.dependent(),
    known: self.known_symbols().length(),
    pivots: self.pivots(),
  }
}

///|
fn integer_list(values : Array[Int32]) -> String {
  let mut text = "["
  for i in 0..<values.length() {
    if i != 0 {
      text = text + ","
    }
    text = text + values[i].to_string()
  }
  text + "]"
}

///|
pub fn DecodeReport::to_json(self : DecodeReport) -> String {
  "{\"schema\":1,\"generation\":" +
  self.generation_id.to_string() +
  ",\"source_count\":" +
  self.source_count.to_string() +
  ",\"rank\":" +
  self.rank.to_string() +
  ",\"deficit\":" +
  self.deficit.to_string() +
  ",\"admitted\":" +
  self.admitted.to_string() +
  ",\"dependent\":" +
  self.dependent.to_string() +
  ",\"known\":" +
  self.known.to_string() +
  ",\"pivots\":" +
  integer_list(self.pivots) +
  "}"
}

///|
pub fn Decoder::recover_symbols(
  self : Decoder,
) -> Array[Symbols] raise CodeError {
  self.basis.recover()
}

///|
// Full rank is necessary; truncated output must also have canonical zero padding.
pub fn Decoder::recover(self : Decoder) -> Symbols raise CodeError {
  let source = self.basis.recover()
  let generation = self.generation()
  let values : Array[Int32] = []
  for i in 0..<source.length() {
    for j in 0..<generation.width() {
      let offset = i * generation.width() + j
      let value = source[i].values[j]
      if offset < generation.length() {
        values.push(value)
      } else if value != 0 {
        raise Corrupt("recovered padding is not zero")
      }
    }
  }
  { values, }
}
