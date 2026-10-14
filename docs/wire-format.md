# MRC1 and MRF1 version 1 wire formats

Offsets are zero-based bytes; multibyte integers are big-endian. IDs, original length, sequences and total lengths must fit 0..2147483647 despite four-byte wire slots. Values with the top bit set are rejected. CRC is IEEE reflected CRC-32: polynomial 0xedb88320, initial state 0xffffffff, final XOR 0xffffffff. CRC covers every preceding byte and is stored big-endian.

## MRC1 data packet

| Offset | Bytes | Meaning |
|---:|---:|---|
| 0 | 4 | ASCII MRC1 |
| 4 | 1 | Reserved flags, must be 0 |
| 5 | 1 | k source count, 1..64 |
| 6 | 2 | w symbol width, 1..4096 |
| 8 | 4 | Generation ID |
| 12 | 4 | Original length, (k-1)*w < length <= k*w |
| 16 | 4 | Packet sequence metadata |
| 20 | 4 | Total length, exactly 28+k+w |
| 24 | k | Explicit GF(256) coefficients, source order |
| 24+k | w | Coded payload |
| 24+k+w | 4 | CRC32 |

Total length 30..4188. Zero coefficient vectors are legal equations: zero payload is dependent and nonzero payload is contradictory. Reserved flags, unsupported dimensions, wrong shape/CRC, truncation or trailing bytes are rejected. No implicit reconstruction of coefficients from sequence exists.

## MRF1 feedback

| Offset | Bytes | Meaning |
|---:|---:|---|
| 0 | 4 | ASCII MRF1 |
| 4 | 1 | k source count |
| 5 | 2 | w symbol width |
| 7 | 1 | r reported rank, 0..k |
| 8 | 4 | Generation ID |
| 12 | 4 | Original length |
| 16 | 4 | Total length, exactly 24+r |
| 20 | r | Strictly increasing unique pivot indices, each < k |
| 20+r | 4 | CRC32 |

Total length 24..88. Feedback has no sequence/freshness/authentication field. It reports pivots, not actual rows or proof of receipt.

## Framing

Concatenate MRC1 packets without separators. FrameReader waits for a full 24-byte header before interpreting declared length. finish() requires no pending bytes. feed() is transactional across all complete frames in that call and has lifetime total byte/frame budgets. It does not accept MRF1, silently skip bytes or auto-resync.

Hex ignores ASCII space, tab, CR and LF even between nibbles. Other characters, odd digit counts and oversized input fail. It is a convenience trace encoding, not a streaming text parser.
