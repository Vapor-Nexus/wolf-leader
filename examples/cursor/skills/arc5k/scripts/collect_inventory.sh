#!/usr/bin/env bash
# Arc5K inventory collector — READ-ONLY.
# Summarizes a repo so the reviewer knows the shape of the app: languages,
# layer folders, endpoint-ish files, SQL/migrations, and Vue components.
# Reads files only; writes nothing to the repo.
#
# Usage: collect_inventory.sh [repo_path]   (defaults to current dir)

set -euo pipefail
ROOT="${1:-.}"
cd "$ROOT"

section() { printf '\n== %s ==\n' "$1"; }

section "Repo"
echo "Path: $(pwd)"
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Git remote: $(git remote get-url origin 2>/dev/null || echo 'n/a')"
  echo "Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'n/a')"
fi

# Prefer ripgrep/fd if present; degrade gracefully.
have_rg() { command -v rg >/dev/null 2>&1; }

section "File counts by extension (top 25)"
find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*' \
  -not -path '*/.venv/*' -not -path '*/dist/*' 2>/dev/null \
  | sed -n 's/.*\.//p' | sort | uniq -c | sort -rn | head -25 || true

section "Likely layer folders"
for d in db database migrations sql etl pipelines services backend api routes \
         controllers app web frontend src components views models; do
  [ -d "$d" ] && echo "  $d/"
done
echo "(also check nested: */migrations, */components, etc.)"

section "SQL & migration files (top 40)"
find . -type f \( -name '*.sql' -o -path '*migrations*' \) \
  -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null | head -40 || true

section "Vue components (count + sample)"
VUE_COUNT=$(find . -type f -name '*.vue' -not -path '*/node_modules/*' 2>/dev/null | wc -l | tr -d ' ')
echo "Vue files: ${VUE_COUNT}"
find . -type f -name '*.vue' -not -path '*/node_modules/*' 2>/dev/null | head -20 || true

section "Possible API endpoints (route/path decorators)"
if have_rg; then
  rg -n --no-heading -S \
    -e '@(app|router|api)\.(get|post|put|patch|delete)\(' \
    -e '@(Get|Post|Put|Patch|Delete)Mapping' \
    -e 'router\.(get|post|put|patch|delete)\(' \
    --glob '!node_modules' --glob '!.git' . 2>/dev/null | head -60 || echo "  (none found)"
else
  echo "  ripgrep not installed — skipping endpoint scan"
fi

section "Done"
echo "Use this as a map; then run the per-layer prompts and tools (see tools.md)."
