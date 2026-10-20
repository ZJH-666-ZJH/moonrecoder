#!/usr/bin/env python3
"""Prove internal mutable references are inaccessible from an independent package.

Only a disposable source copy is compiled. No publication, credentials, Git
mutation, or project manifest changes occur. A reverted visibility fix must make
this regression guard fail even though ordinary accessor tests still pass.
"""
import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

CASES = [
    ("Symbols", "values", "@r.Symbols::new([1])"),
    ("FieldMatrix", "cells", "@r.FieldMatrix::identity(1)"),
    ("Basis", "rows", "@r.Basis::new(1, 1)"),
    ("Decoder", "basis", "@r.Decoder::new(@r.Generation::new(0, 1, 1, 1))"),
    ("Encoder", "source", "@r.Encoder::new(0, @r.Symbols::new([1]), 1)"),
    ("Feedback", "pivot_values", "@r.Feedback::new(@r.Generation::new(0, 1, 1, 1), [0])"),
    ("FrameReader", "pending", "@r.FrameReader::new()"),
    ("SessionPool", "sessions", "@r.SessionPool::new()"),
    ("Relay", "decoder", "@r.Relay::new(@r.Generation::new(0, 1, 1, 1))"),
    ("Replay", "decoder", "@r.Replay::new(@r.Generation::new(0, 1, 1, 1))"),
    ("Replay", "event_values", "@r.Replay::new(@r.Generation::new(0, 1, 1, 1))"),
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--moon", default="moon")
    parser.add_argument("--target", default="wasm-gc")
    args = parser.parse_args()
    project = args.project.resolve()
    with tempfile.TemporaryDirectory(prefix="moonrecoder-encapsulation-") as temp:
        root = Path(temp)
        # The engine has no external module dependency. Do not copy caches,
        # tests, private files, .git, scripts or arbitrary build hooks.
        for source in project.glob("*.mbt"):
            if source.name.endswith(("_test.mbt", "_wbtest.mbt")):
                continue
            shutil.copyfile(str(source), str(root / source.name))
        for name in ("moon.mod", "moon.pkg"):
            shutil.copyfile(str(project / name), str(root / name))
        consumer = root / "visibility_consumer"
        consumer.mkdir()
        (consumer / "moon.pkg").write_text(
            'import { "ZJH-666-ZJH/moonrecoder" @r, } for "test"\n', encoding="utf-8"
        )
        for type_name, field, constructor in CASES:
            probe = consumer / "leak_test.mbt"
            probe.write_text(
                '///|\ntest "no mutable state leak" {\n'
                + "  let value = " + constructor + "\n"
                + "  ignore(value." + field + ")\n}\n", encoding="utf-8"
            )
            command = [args.moon, "test", "visibility_consumer", "--build-only", "--deny-warn", "--target", args.target]
            result = subprocess.run(command, cwd=str(root), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
            output = result.stdout.decode("utf-8", errors="replace")
            # A random compilation error is not proof of field privacy.
            diagnostic = "has no field " + field + "."
            if result.returncode != 1 or diagnostic not in output or type_name not in output:
                print("FAIL: " + type_name + "." + field + " did not produce its expected privacy diagnostic")
                print(output)
                return 1
            print("PASS: " + type_name + "." + field + " is not publicly accessible")
    print("11/11 mutable-reference visibility regressions passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
