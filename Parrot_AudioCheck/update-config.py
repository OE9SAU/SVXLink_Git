#!/usr/bin/env python3

import re
import sys
from pathlib import Path

if len(sys.argv) != 3:
    sys.exit("Usage: update-config.py INPUT OUTPUT")

source = Path(sys.argv[1])
target = Path(sys.argv[2])

text = source.read_text(encoding="utf-8")

defaults = {
    "AUDIOCHECK": "1",
    "AUDIOCHECK_TARGET_RMS": "-20",
    "AUDIOCHECK_TOLERANCE": "2",
    "AUDIOCHECK_PEAK_LIMIT": "-6",
    "AUDIOCHECK_MIN_DURATION": "2000",
}

sections = list(re.finditer(
    r"(?m)^\s*\[([^\]\r\n]+)\][ \t]*$",
    text
))

matches = [
    i for i, section in enumerate(sections)
    if section.group(1) == "ModuleParrot"
]

if len(matches) != 1:
    sys.exit("ERROR: Expected exactly one ModuleParrot section")

i = matches[0]
start = sections[i].end()
end = sections[i + 1].start() if i + 1 < len(sections) else len(text)

body = text[start:end]

body = re.sub(
    r"(?m)^# Parrot AudioCheck V[^\r\n]*$",
    "# Parrot AudioCheck V1.02",
    body
)

missing = []

for key, value in defaults.items():
    pattern = rf"(?m)^[ \t]*{re.escape(key)}[ \t]*="
    count = len(re.findall(pattern, body))

    if count > 1:
        sys.exit(f"ERROR: Duplicate parameter: {key}")

    if count == 1:
        print(f"KEEP: {key}")
    else:
        missing.append(f"{key}={value}")
        print(f"ADD:  {key}={value}")

if missing:
    body = body.rstrip("\r\n") + "\n\n"

    if "# Parrot AudioCheck V1.02" not in body:
        body += "# Parrot AudioCheck V1.02\n"

    body += "\n".join(missing) + "\n"

result = text[:start] + body + text[end:]

target.write_text(result, encoding="utf-8")

print("Configuration update: OK")
