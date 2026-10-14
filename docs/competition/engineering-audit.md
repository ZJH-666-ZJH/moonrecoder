# Engineering evidence — pre-publication baseline

Date: 2026-10-14. This file records checks already run, not intended outcomes. Public CI/release and exact-version consumer evidence are added only after they exist. No registration is claimed.

- Independent repository and canonical GitHub commit identity are bound to ZJH-666-ZJH. MoonCakes server account matched the same login. Cross-site equal names do not establish a real-world identity assertion.
- Original pure MoonBit runtime: root production .mbt files only. Reproduce inventory using python3 scripts/audit.py; tests, examples, interfaces, documentation and generated build files are excluded.
- Local toolchain: moon 0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9, Windows. CI installs the current official stable snapshot and records the actual version in logs; the stable channel is not an immutable compiler pin.
- moon info followed by moon fmt completed. Generated interfaces were inspected: expected public field/vector/matrix, packet, basis, encoder/decoder/relay, feedback, framing, pool and replay APIs; mutable implementation fields remain inaccessible to downstream packages.
- Local wasm-gc, wasm and js: strict check, build, all 43 tests and all three executable workflows passed. Native strict check passed; local native build could not execute because cc/gcc/clang are absent. Native build/test/examples must pass on clean Ubuntu CI before release.
- Tests include 65536 exhaustive GF products against independent polynomial long division, rank cross-checks for 16 generated sizes, 255 relay weight cases, every single stream split point, maximum 64x4096 frame, stale feedback, contradiction and budget rollback. These are correctness cases, not benchmark or security audit results.
- Public source includes MIT license, AI disclosure, provenance, architecture, exact wire specification, changelog and bounded semantic duplication findings.
- Private competition application is outside this checkout. Release/privacy checks must scan both working files and all reachable history before any upload. Package ZIP must also be inspected; ignoring a file is not sufficient.

## Commit evidence

The first 22 commits independently introduced complete implementation or verification slices; no empty/format-only commits are counted. Full SHA, subject, touched files and verification are generated in commit-audit.json. Documentation, generated-interface and delivery commits are not needed to reach the conservative threshold.
