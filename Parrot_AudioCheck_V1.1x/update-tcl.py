#!/usr/bin/env python3

import re
import sys
import subprocess
from pathlib import Path

if len(sys.argv) != 4:
    sys.exit("Usage: update-tcl.py INPUT EXTENSION OUTPUT")

source = Path(sys.argv[1])
extension = Path(sys.argv[2])
target = Path(sys.argv[3])

text = source.read_text(encoding="utf-8") if source.exists() else ""
new_block = extension.read_text(encoding="utf-8").strip()

marker = re.compile(
    r"(?m)^# Parrot AudioCheck V(?:1\.0|1\.01|1\.02|1\.10)"
    r" - (?:Testbetrieb|Sprachbewertung)[ \t]*$"
)

matches = list(marker.finditer(text))
def tcl_complete(code):
    result = subprocess.run(
        ["tclsh", "/dev/stdin"],
        input="puts [info complete [binary decode hex "
              + code.encode("utf-8").hex() + "]]\n",
        text=True,
        capture_output=True,
        check=True
    )
    return result.stdout.strip() == "1"


if len(matches) > 1:
    sys.exit("ERROR: Multiple AudioCheck blocks found")

if matches:
    start = matches[0].start()

    prefix = text[:start]

    prefix = re.sub(
        r"(?m)^# =+[ \t]*\n\Z",
        "",
        prefix
    )

    remaining = text[matches[0].end():]

    namespace = re.search(
        r"(?m)^namespace eval Parrot \{[ \t]*$",
        remaining
    )

    if not namespace:
        sys.exit("ERROR: AudioCheck namespace not found")

    header = remaining[:namespace.start()]

    if any(
        line.strip() and not line.lstrip().startswith("#")
        for line in header.splitlines()
    ):
        sys.exit("ERROR: Unexpected content before namespace")

    block = ""
    consumed = 0

    for line in remaining[namespace.start():].splitlines(keepends=True):
        block += line
        consumed += len(line)

        if tcl_complete(block):
            break
    else:
        sys.exit("ERROR: Incomplete AudioCheck namespace")

    suffix = remaining[namespace.start() + consumed:]

    # Only replace known, unmodified AudioCheck extensions.
    reference_dir = Path(__file__).resolve().parent / "compat" / "tcl"

    old_block = text[
        start:matches[0].end() + namespace.start() + consumed
    ].strip()

    known_blocks = [
        (reference_dir / version).read_text(
            encoding="utf-8"
        ).strip()
        for version in ("V1.0.tcl", "V1.01.tcl", "V1.02.tcl", "V1.10.tcl")
    ]

    if old_block not in known_blocks:
        sys.exit(
            "ERROR: Unknown or modified AudioCheck TCL block. "
            "Manual review required."
        )

    print("Existing AudioCheck block verified")
    text = prefix + suffix

    print("REPLACE: Existing AudioCheck extension")

else:
    print("ADD: New AudioCheck extension")

if re.search(
    r"\bproc\s+(?:audiocheck_result|audiocheck_invalid|playAudioLevel)\b",
    text
):
    sys.exit("ERROR: Unmanaged AudioCheck procedures found")

result = text.rstrip() + "\n\n"
result += "# ==================================================\n"
result += new_block + "\n"

if not tcl_complete(result):
    sys.exit("ERROR: Incomplete TCL script")

target.write_text(result, encoding="utf-8")

print("TCL update: OK")
