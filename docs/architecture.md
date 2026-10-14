# Architecture and invariants

## Model

An equation represents y = sum(c[i] * source[i]) in GF(256). Addition is XOR; multiplication uses reduction by 0x11d. All values supplied through the public Symbols constructor are bytes. Symbols owns a detached Int array; callers never receive an internal mutable container. Encoder source arrays, matrix rows, basis exports and feedback pivots follow the same rule. Decoder, Basis, Relay, SessionPool, FrameReader, Replay and CoefficientStream are mutable synchronous objects, not thread-safe shared services.

Generation identity is the complete tuple (id, source count, width, original length). Only the last source symbol may have padding. Nonempty source bytes and canonical zero padding remove length ambiguity. Packet sequence is diagnostic metadata; there is no sequence cache or replay window.

## Incremental admission

Basis maintains one optional augmented row per pivot index. Admit copies the incoming equation, eliminates existing normalized pivots, and finds its first nonzero coefficient. A zero coefficient residual with zero payload is Dependent; a nonzero payload residual raises Inconsistent. A new pivot is normalized, then eliminated from all old rows. Replacements are staged and only installed after all validation succeeds. Shape errors and contradictions do not change rank, basis or decoder counters. Accepted dependent packets consume the packet budget; rejected packets do not.

Full rank permits source recovery. recover() additionally validates zero padding before returning exact original bytes. recover_symbols() returns full padded source symbols and deliberately does not perform original-length trimming. known_symbols() returns only rows whose coefficients isolate one source symbol. Full-rank recovery is not a proof of authenticity.

FieldMatrix.rank uses separate batch forward elimination rather than the incremental Basis code path. The test-only polynomial multiplier oracle uses schoolbook carry-less multiplication plus polynomial long division, not the production shift/reduce loop.

## Recoding and feedback

Relay weights refer to the CURRENT pivot-ordered basis, which may change after admission. Mixing coefficients and payload by the same weights preserves the source equation. A relay can operate below full rank; it cannot manufacture new independent information. Zero recoding weights are rejected. basis_packets exports independent rows without probabilistic promises.

Feedback reports sorted pivot columns. Unit vectors at absent pivots complement the REPORTED row space: existing pivot coordinates fix the coefficients of any combination, so no nonzero combination of those missing unit vectors can lie in that space. A fresh accurate hint therefore gives deterministic completion. Stale hints can yield dependent repairs; forged hints can omit necessary repairs. The sender checks shape and sequence-range overflow but does not authenticate hints.

## Transaction boundaries

- Basis.admit / Decoder.admit: one equation, no mutation on error.
- Decoder.admit_batch / admit_wire_batch: fork state, validate every item, install all or none. fork shares only immutable-by-API symbols.
- FrameReader.feed: buffer/counters and returned packet list are published only if every complete frame in that feed validates. Failed chunks can be corrected and retried; no scanning past damage.
- SessionPool.admit: routes one packet; allocation is reserved only after first admission succeeds. It is NOT atomic across a caller's entire array of packets.
- SessionPool.take: recovery first, discard only on success. discard deliberately permits ID reuse, so the host must enforce freshness externally.
- Replay.feed_*: records accepted/dependent/rejected events. Bad input is a normal event; only event-capacity exhaustion raises. Event histories and report pivot arrays are detached.

A successful FrameReader.feed followed by a failed downstream pool admission does not roll back the reader. Use Decoder.admit_batch for application transactions and decide how to journal or retry accepted frames.

## Resource ceilings

| Resource | Default | Permitted ceiling / meaning |
|---|---:|---|
| Source count / width | caller-selected | 64 / 4096 |
| Symbols length | caller-selected | 262144 Int cells |
| Matrix dimensions | caller-selected | each 1..64 |
| Decoder packets | 4096 | 65536, valid admissions including dependent |
| Coefficient draw budget | 1048576 | 1048576 coefficient bytes |
| FrameReader bytes / frames | 1048576 / 4096 | 16777216 / 65536 lifetime totals |
| Pool generations / cells | 16 / 1048576 | 32 / 4194304 |
| Hex input text | caller-provided | 1048576 code units; ASCII hex and SP/TAB/CR/LF only |
| Wire data / feedback | derived | 4188 / 88 bytes |

Pool reservation for one generation is k*(k+width) FIELD CELLS, not resident bytes. It bounds retained augmented row capacity, not array-object overhead or transient copies. Dense admission is O(k*(k+width)) field operations per innovative packet; a full solve is O(k^2*(k+width)). GF multiplication is a fixed eight-step scalar loop. These are complexity estimates, not performance measurements. Callers should choose smaller practical generations and impose input-rate budgets even on rejected traffic.

JSON output contains numeric state and fixed ASCII status/error categories. No payload bytes or arbitrary input text are echoed by reports. CodeError categories are Invalid, Shape, Limit, Inconsistent, Incomplete, Corrupt and Truncated.
