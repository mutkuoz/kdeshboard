#!/usr/bin/env python3
"""Validate a Plasma 6 .colors file has all mandatory keys.

Usage: validate_colors.py <path-to-.colors>
Exit code 0 on success, 1 on missing keys, 2 on parse error.
"""
from __future__ import annotations

import configparser
import re
import sys
from pathlib import Path

REQUIRED_COLOR_KEYS = {
    "BackgroundNormal",
    "BackgroundAlternate",
    "ForegroundNormal",
    "ForegroundInactive",
    "ForegroundActive",
    "ForegroundLink",
    "ForegroundVisited",
    "ForegroundNegative",
    "ForegroundNeutral",
    "ForegroundPositive",
    "DecorationFocus",
    "DecorationHover",
}
REQUIRED_SECTIONS = {"General", "Colors:Window", "Colors:View", "Colors:Button"}
RGB_PATTERN = re.compile(r"^\d{1,3},\d{1,3},\d{1,3}$")


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(f"usage: {argv[0]} <path-to-.colors>", file=sys.stderr)
        return 2
    path = Path(argv[1])
    if not path.is_file():
        print(f"not a file: {path}", file=sys.stderr)
        return 2

    parser = configparser.ConfigParser()
    parser.optionxform = str  # preserve case; .colors keys are PascalCase
    try:
        parser.read(path)
    except configparser.Error as exc:
        print(f"parse error: {exc}", file=sys.stderr)
        return 2

    errors: list[str] = []
    for section in REQUIRED_SECTIONS:
        if section not in parser:
            errors.append(f"missing section: [{section}]")

    for section in parser.sections():
        if not section.startswith("Colors:"):
            continue
        missing = REQUIRED_COLOR_KEYS - set(parser[section].keys())
        for key in sorted(missing):
            errors.append(f"[{section}] missing key: {key}")
        for key, value in parser[section].items():
            if key in REQUIRED_COLOR_KEYS and not RGB_PATTERN.match(value.strip()):
                errors.append(f"[{section}] {key}: not R,G,B: {value!r}")

    if errors:
        for line in errors:
            print(line, file=sys.stderr)
        return 1
    print(f"ok: {path} — {len(parser.sections())} sections")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
