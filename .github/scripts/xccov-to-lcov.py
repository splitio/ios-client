#!/usr/bin/env python3
"""Convert `xcrun xccov view --archive` text into LCOV."""
import sys

def convert(text):
    records = []
    current = None
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("*"):
            continue
        if line.endswith(":") and not line[0].isdigit():
            if current:
                records.append(current)
            current = [line[:-1], []]
            continue
        if current is None or ":" not in line:
            continue
        number, count = line.split(":", 1)
        number = number.strip()
        count = count.strip()
        if number.isdigit() and count.isdigit():
            current[1].append((number, count))
    if current:
        records.append(current)
    chunks = []
    for path, lines in records:
        if not lines:
            continue
        body = ["SF:%s" % path]
        body.extend("DA:%s,%s" % pair for pair in lines)
        body.append("end_of_record")
        chunks.append("\n".join(body))
    return "\n".join(chunks) + ("\n" if chunks else "")

def main():
    text = sys.stdin.read()
    sys.stdout.write(convert(text))

if __name__ == "__main__":
    main()
