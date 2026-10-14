# Engineering evidence — tested release baseline

Date: 2026-10-14. This file records checks already run, not intended outcomes. Public CI/release and exact-version consumer evidence are added only after they exist. No registration is claimed.

- Independent repository and canonical GitHub commit identity are bound to ZJH-666-ZJH. MoonCakes server account matched the same login. Cross-site equal names do not establish a real-world identity assertion.
- Original pure MoonBit runtime: root production .mbt files only. Reproduce inventory using python3 scripts/audit.py; tests, examples, interfaces, documentation and generated build files are excluded.
- Local toolchain: moon 0.1.20261012 (748b63c), moonc v0.10.15+943464bfa, Windows. CI installs the current official stable snapshot and records the actual version in logs; the stable channel is not an immutable compiler pin.
- moon info followed by moon fmt completed. Generated interfaces were inspected: expected public field/vector/matrix, packet, basis, encoder/decoder/relay, feedback, framing, pool and replay APIs; mutable implementation fields remain inaccessible to downstream packages.
- Local wasm-gc, wasm and js: strict check, build, all 43 tests and all three executable workflows passed. Native strict check passed; local native build could not execute because cc/gcc/clang are absent. Native build/test/examples subsequently passed on clean Ubuntu CI; see the actual run below.
- Tests include 65536 exhaustive GF products against independent polynomial long division, rank cross-checks for 16 generated sizes, 255 relay weight cases, every single stream split point, maximum 64x4096 frame, stale feedback, contradiction and budget rollback. These are correctness cases, not benchmark or security audit results.
- Public source includes MIT license, AI disclosure, provenance, architecture, exact wire specification, changelog and bounded semantic duplication findings.
- Private competition application is outside this checkout. Release/privacy checks must scan both working files and all reachable history before any upload. Package ZIP must also be inspected; ignoring a file is not sufficient.

## Commit evidence

The first 22 commits independently introduced complete implementation or verification slices; no empty/format-only commits are counted. Full SHA, subject, touched files and verification are generated in commit-audit.json. Documentation, generated-interface and delivery commits are not needed to reach the conservative threshold.

## Stable toolchain compatibility

The first real CI run (38555598508) failed the clean-format gate because the 2026-10-12 stable formatter canonicalizes Int/UInt spellings to Int32/UInt32 and optional defaults to the new syntax. The fix was produced with a separate official 2026-10-12 toolchain, without changing shared tools or weakening the gate. All three locally executable targets were rebuilt, retested (43/43 each) and all three workflows rerun. Native strict check passed. `moon info` produced no public interface changes after formatting; integer widths and behavior are unchanged. Refreshed inventory: 2114 physical / 1752 nonblank noncomment production lines.

## Actual clean-runner CI

Implementation commit `29d40ae73ff6e6ae79988beec360b769e3c81724` passed [GitHub Actions run 38556469289](https://github.com/ZJH-666-ZJH/moonrecoder/actions/runs/38556469289) on 2026-10-14. All four matrix jobs (wasm-gc, wasm, js, native) completed successfully: clean interface/format gate, strict check/build, 43/43 tests, all three executable workflows, and production inventory guard. This includes actual native build and execution with Ubuntu GCC, not only a type-check. The CI environment used moon 0.1.20261012 (748b63c), moonc v0.10.15+943464bfa, Node 22; the full version output is retained in the run logs.

This audit update changes documentation only. The final tag may contain this update, and its own complete CI run must also be green before publication. GitHub Release, public exact-version metadata and a fresh no-credential consumer remain separate delivery gates; the existence of this baseline does not claim they have already happened.
