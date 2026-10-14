# Provenance and license boundaries

MoonRecoder 0.1.0 is an original implementation under MIT, copyright ZJH-666-ZJH. It is not a port of MoonErasure, reed_solomon, RFC 8681 or another implementation. Runtime dependencies are only MoonBit core. No third-party code, vendor payloads or copied test fixtures are included.

## Algorithm/format references

- GF(256), polynomial reduction, Gaussian elimination and random linear coding are mathematical techniques, not claims of original mathematics. The modulus is 0x11d, not AES's 0x11b. Tests independently compute every byte product by carry-less multiplication and polynomial division.
- [RFC 8681](https://www.rfc-editor.org/rfc/rfc8681.html) describes sliding-window random linear coding and informs terminology only. This project is generation-bounded with explicit coefficients and a custom frame; it does NOT implement that RFC or claim interoperability.
- CRC-32/ISO-HDLC uses the conventional ASCII 123456789 check value 0xcbf43926. That standard check string is the only external fixed test vector. Other packets, bytes, traces and equations are original synthetic fixtures.

## Inspected adjacent implementations, NOT dependencies or copied code

| Project | Inspected version / license | Comparison boundary |
|---|---|---|
| [oyjh0381/MoonErasure](https://github.com/oyjh0381/MoonErasure) | oyjh0381/moonerasure 0.2.0, Apache-2.0 | Fixed indexed Reed–Solomon shards, catalog/bundle repair. Not arbitrary incremental equations or incomplete relay span recoding. |
| [CAIMEOX/reed_solomon](https://mooncakes.io/docs/CAIMEOX/reed_solomon@0.1.0/) | 0.1.0, Apache-2.0 | Polynomial error correction, not an incremental recoding session. |
| [oyjh0381/moonbdd](https://mooncakes.io/docs/oyjh0381/moonbdd@0.1.0/) | 0.1.0, Apache-2.0 | ROBDD/symbolic analysis; adjacent reliability candidate rejected. |
| [okMambaOut/moonpetri](https://mooncakes.io/docs/okMambaOut/moonpetri@0.1.4/) | 0.1.4, MIT | Petri reachability/invariants; candidate rejected. |
| [FrozenLemonTee/LunarUnits](https://mooncakes.io/docs/FrozenLemonTee/LunarUnits@0.1.9/) | 0.1.9, Apache-2.0 | Dimensional quantities/affine units; candidate rejected. |
| [wcx789ll/moon-reliability](https://mooncakes.io/docs/wcx789ll/moon-reliability@0.3.3/) | 0.3.3, Apache-2.0 | Reliability/distribution/lifetime analysis; candidate rejected. |

Their licenses remain their own. Inspecting APIs does not imply endorsement or place those projects under this license. No upstream performance comparison is claimed. Search limits are documented separately.
