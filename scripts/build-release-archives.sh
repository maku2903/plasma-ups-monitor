#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="$(sed -n 's/.*"Version": "\(.*\)".*/\1/p' "$repo_root/package/metadata.json" | head -n1)"

if [[ -z "$version" ]]; then
  echo "Could not read version from package/metadata.json" >&2
  exit 1
fi

mkdir -p "$repo_root/dist"
rm -f "$repo_root/dist/plasma-ups-monitor-$version.zip"
rm -f "$repo_root/dist/plasma-ups-monitor-latest.zip"

(
  cd "$repo_root/package"
  zip -rq "../dist/plasma-ups-monitor-$version.zip" .
)

cp "$repo_root/dist/plasma-ups-monitor-$version.zip" "$repo_root/dist/plasma-ups-monitor-latest.zip"

echo "Built:"
echo "  $repo_root/dist/plasma-ups-monitor-$version.zip"
echo "  $repo_root/dist/plasma-ups-monitor-latest.zip"

