///|
test "IEEE CRC32 known check and streaming splits" {
  let bytes = Symbols::new([49, 50, 51, 52, 53, 54, 55, 56, 57])
  assert_eq(crc32(bytes), 0xcbf43926U)
  assert_eq(crc32(Symbols::new([])), 0U)
  for cut in 0..<10 {
    let state = Crc32::new()
    state.update(bytes.slice(0, cut))
    state.update(bytes.slice(cut, bytes.length()))
    assert_eq(state.value(), 0xcbf43926U)
    assert_eq(state.value(), state.value())
  }
}
