# Security boundaries

MoonRecoder is a coding and diagnostic primitive, not an authenticated transport. Do not use CRC, rank, packet sequence or a successful solve as an integrity/security guarantee.

- MRC1/MRF1 CRC32 detects accidental damage only. An attacker can modify equations and recompute CRC.
- Underdetermined polluted equations can be internally consistent and later produce incorrect full-rank data. Contradiction and padding checks are useful diagnostics, not a pollution defense.
- Authenticate the complete generation identity, coefficients, payload, length and sequence BEFORE admitting packets; authenticate feedback separately. Keying/AEAD/signatures are host responsibilities.
- IDs are finite metadata, not unique nonces. Pools permit ID reuse after discard. Maintain freshness and replay windows externally.
- Deterministic xorshift selection is not secret, cryptographically random, or exactly uniform. No any-k/MDS or loss-rate guarantee is made.
- Budgets bound retained field cells and accepted data, not CPU consumed by rejected traffic, exact heap bytes or simultaneous copies. Enforce rate/concurrency limits at ingress.
- Algorithms are not constant-time and no side-channel or adversarial robustness audit has been performed. Mutable state is synchronous.
- FrameReader stops at corrupt input; no resynchronization. Pool admission is separate and can fail after the reader advances.

For non-sensitive correctness issues, open a minimal public GitHub issue with synthetic data and toolchain/target. Do not upload secrets, private traces or personal data. No private vulnerability-reporting address is claimed.
