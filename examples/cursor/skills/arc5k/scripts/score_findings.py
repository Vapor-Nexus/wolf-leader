#!/usr/bin/env python3
"""Arc5K finding scorer — pure stdlib, read-only.

Reads findings as JSON and prints them ranked worst-first, grouped into
"Fix now / Plan soon / Later". See ../scoring.md for the model.

Input: a JSON array (file path arg or stdin) of objects like:
  {"title": "...", "impact": 5, "effort": 2, "where": "...", "recommendation": "..."}
  impact: 1-5 (how much it hurts)   effort: 1-5 (how hard to fix)

Usage:
  score_findings.py findings.json
  cat findings.json | score_findings.py
"""
import json
import sys


def clamp(value, lo=1, hi=5):
    try:
        value = int(value)
    except (TypeError, ValueError):
        return lo
    return max(lo, min(hi, value))


def priority(finding):
    impact = clamp(finding.get("impact"))
    effort = clamp(finding.get("effort"))
    # High impact + low effort floats to the top.
    return impact * (6 - effort)


def bucket(p):
    if p >= 16:
        return "Fix now"
    if p >= 8:
        return "Plan soon"
    return "Later"


def main():
    raw = open(sys.argv[1]).read() if len(sys.argv) > 1 else sys.stdin.read()
    try:
        findings = json.loads(raw)
    except json.JSONDecodeError as exc:
        sys.exit(f"Could not parse JSON: {exc}")
    if not isinstance(findings, list):
        sys.exit("Expected a JSON array of findings.")

    for f in findings:
        f["priority"] = priority(f)
        f["bucket"] = bucket(f["priority"])

    findings.sort(key=lambda f: f["priority"], reverse=True)

    last = None
    for f in findings:
        if f["bucket"] != last:
            print(f"\n## {f['bucket']}")
            last = f["bucket"]
        title = f.get("title", "(untitled)")
        print(f"- [P{f['priority']}] {title}")
        where = f.get("where")
        rec = f.get("recommendation")
        if where:
            print(f"    where: {where}")
        if rec:
            print(f"    fix:   {rec}")

    if not findings:
        print("No findings.")


if __name__ == "__main__":
    main()
