# Changelog

## 0.1.1 — 2026-10-20

- Made 11 mutable internal reference fields private across Symbols, matrices, bases,
  encoder/decoder, feedback, framing, session pools, relay and replay. Previously a
  consumer could mutate the referenced arrays/objects despite read-only fields,
  bypassing validation, transactional state and resource counters.
- Kept documented constructors/methods, coding algorithms and MRC1/MRF1 wire bytes
  unchanged. The generated interface intentionally no longer exposes those fields;
  consumers using undocumented direct field access must use the existing accessors.
- Added three public-API regression tests and an independent-package compile guard
  for all 11 fields, including a CI step. Added six further adversarial public-API tests: all
  256 binary equation pairs plus feedback repair/fork isolation, every single-bit
  packet and feedback mutation, RNG failure rollback, bytewise framing budgets,
  and conflicting-generation pool reservations. Release synchronization is gated
  on the exact commit's four-target CI; historical 0.1.0 is not overwritten.

- Refreshed the generated interface using the official 2026-10-16 compiler
  (canonical `Int32`/`UInt32` names), matching the four-target CI toolchain.
  This is a generated-type spelling update, not an arithmetic or wire change.

## 0.1.0 — 2026-10-14

Initial release: bounded GF(256) vectors and matrices, transactional incremental augmented RREF, systematic/explicit/seeded encoding, rank-aware decoding and canonical recovery, incomplete relay recoding, pivot feedback repair, CRC-protected MRC1/MRF1 wire formats, incremental framing, multi-generation budget reservations, atomic batch/fork operations, Bytes/hex adapters and structured offline replay.

Includes three complete workflows, independent arithmetic and rank/reference tests, boundary/rollback tests, generated public interface, security/provenance notes and four-target CI. No standardized FEC wire interoperability, network stack or authentication.
