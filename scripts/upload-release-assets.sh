#!/usr/bin/env bash
set -euo pipefail

repo="maku2903/plasma-ups-monitor"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="$(sed -n 's/.*"Version": "\(.*\)".*/\1/p' "$repo_root/package/metadata.json" | head -n1)"
tag="v$version"

"$repo_root/scripts/build-release-archives.sh"

gh release upload "$tag" \
  --repo "$repo" \
  --clobber \
  "$repo_root/dist/plasma-ups-monitor-$version.zip" \
  "$repo_root/dist/plasma-ups-monitor-latest.zip"

echo "Stable URL:"
echo "  https://github.com/$repo/releases/latest/download/plasma-ups-monitor-latest.zip"
