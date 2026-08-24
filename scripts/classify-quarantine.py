#!/usr/bin/env python3

"""Accept only declared failure signatures from one quarantined Bun file."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


ANSI_RE = re.compile(r"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1b\\))")
RESULT_RE = re.compile(r"(?m)^\((pass|fail)\)\s+.*$")
DIAGNOSTIC_RE = re.compile(
    r"^\s*(?:(?:[A-Za-z][A-Za-z0-9_.]*Error)|error|panic|fatal|unhandled|uncaught|"
    r"exception|thread\s+\d+\s+panic|segmentation\s+fault|abort\s+trap|bus\s+error|"
    r"illegal\s+instruction|killed|core\s+dumped)\b",
    re.IGNORECASE,
)


def refuse(message: str) -> None:
    print(f"fxnk quarantine: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--file", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--exit-code", required=True, type=int)
    args = parser.parse_args()

    if args.exit_code == 0:
        refuse("the classifier was called for a passing test process")

    manifest = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    entries = [entry for entry in manifest["entries"] if entry["file"] == args.file]
    if len(entries) != 1:
        refuse(f"{args.file} does not have exactly one quarantine entry")
    entry = entries[0]
    signatures = [
        {**signature, "compiled": re.compile(signature["regex"], re.DOTALL)}
        for signature in entry["allowed_signatures"]
    ]

    output = ANSI_RE.sub("", Path(args.output).read_text(encoding="utf-8", errors="replace"))
    results = list(RESULT_RE.finditer(output))
    failed_results = [result for result in results if result.group(1) == "fail"]
    if not failed_results:
        refuse(f"{args.file} exited {args.exit_code} without a Bun failure block")

    matched_ids: set[str] = set()
    accepted_spans: list[tuple[int, int]] = []
    for index, result in enumerate(results):
        if result.group(1) != "fail":
            continue
        start = results[index - 1].end() if index > 0 else 0
        block = output[start:result.end()]
        accepted_spans.append((start, result.end()))
        matched = [signature for signature in signatures if signature["compiled"].search(block)]
        if not matched:
            title = block.splitlines()[0] if block.splitlines() else args.file
            refuse(f"undeclared failure signature in {title}")

        has_assertion_diff = "Expected:" in block or "Received:" in block
        if has_assertion_diff and not any(signature["kind"] == "assertion" for signature in matched):
            title = block.splitlines()[0] if block.splitlines() else args.file
            refuse(f"undeclared assertion in {title}")

        error_lines = [
            line.strip()
            for line in block.splitlines()
            if DIAGNOSTIC_RE.match(line)
        ]
        for line in error_lines:
            if any(signature["compiled"].search(line) for signature in matched):
                continue
            if line.startswith("error: expect(") and any(
                signature["kind"] == "assertion" for signature in matched
            ):
                continue
            refuse(f"undeclared error line in {block.splitlines()[0]}: {line}")

        matched_ids.update(signature["id"] for signature in matched)

    remainder = list(output)
    for start, end in accepted_spans:
        remainder[start:end] = " " * (end - start)
    for line in "".join(remainder).splitlines():
        if DIAGNOSTIC_RE.match(line):
            refuse(f"undeclared diagnostic outside a failure block: {line.strip()}")

    print(json.dumps({
        "file": args.file,
        "status": "quarantined",
        "failure_count": len(failed_results),
        "signatures": sorted(matched_ids),
    }, separators=(",", ":")))


if __name__ == "__main__":
    main()
