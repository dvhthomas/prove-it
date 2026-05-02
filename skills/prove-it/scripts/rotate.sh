#!/usr/bin/env bash
# Rotate the prove-it evidence directories.
#
# Usage: rotate.sh <prove-it-dir> [archive-limit]
#   <prove-it-dir>   Path to the project's prove-it/ directory.
#   [archive-limit]  How many archived runs to keep. Default 2.
#
# Behavior:
#   - If <prove-it-dir>/current/ exists, move it to archive/<YYYY-MM-DD-HHMM>/.
#   - Trim archive/ to the newest <archive-limit> entries.
#   - HUMAN_EVIDENCE.md is never touched.
#
# This script is intentionally conservative: it refuses to operate on a path
# whose basename is not "prove-it", so an accidental wrong argument cannot
# delete the wrong directory.

set -euo pipefail

PROVE_DIR="${1:-}"
ARCHIVE_LIMIT="${2:-2}"

if [[ -z "$PROVE_DIR" ]]; then
  echo "usage: rotate.sh <prove-it-dir> [archive-limit]" >&2
  exit 2
fi

if [[ "$(basename "$PROVE_DIR")" != "prove-it" ]]; then
  echo "refusing to operate on a directory not named 'prove-it': $PROVE_DIR" >&2
  exit 2
fi

if [[ ! -d "$PROVE_DIR" ]]; then
  mkdir -p "$PROVE_DIR"
fi

mkdir -p "$PROVE_DIR/archive"

if [[ -d "$PROVE_DIR/current" ]]; then
  ts="$(date +%Y-%m-%d-%H%M)"
  dest="$PROVE_DIR/archive/$ts"
  # If a same-minute archive already exists (re-running quickly), append a counter.
  i=1
  while [[ -e "$dest" ]]; do
    dest="$PROVE_DIR/archive/${ts}-$i"
    i=$((i + 1))
  done
  mv "$PROVE_DIR/current" "$dest"
  echo "archived: $dest"
fi

# Trim archive to the newest ARCHIVE_LIMIT entries (by name, which is timestamp-prefixed).
shopt -s nullglob
mapfile -t entries < <(ls -1 "$PROVE_DIR/archive" | sort -r)
shopt -u nullglob

if (( ${#entries[@]} > ARCHIVE_LIMIT )); then
  for old in "${entries[@]:ARCHIVE_LIMIT}"; do
    target="$PROVE_DIR/archive/$old"
    if [[ -d "$target" ]]; then
      rm -rf "$target"
      echo "pruned: $target"
    fi
  done
fi

echo "rotation complete. archive contents:"
ls -1 "$PROVE_DIR/archive" 2>/dev/null || true
