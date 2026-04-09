#!/usr/bin/env bash
#
# Generate index.html for every directory that doesn't already have one.
# Intended to run in a GitHub Actions workflow before deploying to Pages.
#

set -euo pipefail

SITE_ROOT="${1:-.}"
SITE_NAME="${2:-kbabbitt.github.io}"

cd "$SITE_ROOT"

# Find directories that lack an index.html (skip .git and .github)
find . -type d \( -name .git -o -name .github \) -prune -o -type d -print | while read -r dir; do
  if [ -f "$dir/index.html" ]; then
    continue
  fi

  # Build a relative path for display (strip leading ./)
  rel_path="${dir#./}"
  if [ "$rel_path" = "." ] || [ -z "$rel_path" ]; then
    rel_path=""
    title="$SITE_NAME"
    parent_link=""
  else
    title="/$rel_path"
    parent_dir=$(dirname "$rel_path")
    if [ "$parent_dir" = "." ]; then
      parent_link='<li><a href="../">../</a></li>'
    else
      parent_link='<li><a href="../">../</a></li>'
    fi
  fi

  # Collect entries: subdirectories first, then files
  entries=""

  # Subdirectories
  for entry in "$dir"/*/; do
    [ -d "$entry" ] || continue
    name=$(basename "$entry")
    # Skip hidden dirs
    [ "${name:0:1}" = "." ] && continue
    entries="${entries}<li><a href=\"${name}/\">${name}/</a></li>\n"
  done

  # Files (exclude the index.html we're about to create, and hidden files)
  for entry in "$dir"/*; do
    [ -f "$entry" ] || continue
    name=$(basename "$entry")
    [ "${name:0:1}" = "." ] && continue
    entries="${entries}<li><a href=\"${name}\">${name}</a></li>\n"
  done

  cat > "$dir/index.html" <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${title}</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; max-width: 48rem; margin: 2rem auto; padding: 0 1rem; color: #24292f; }
    h1 { font-size: 1.5rem; border-bottom: 1px solid #d0d7de; padding-bottom: .5rem; }
    ul { list-style: none; padding: 0; }
    li { padding: .25rem 0; }
    a { color: #0969da; text-decoration: none; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <h1>Index of ${title}</h1>
  <ul>
    ${parent_link}
$(echo -e "$entries")
  </ul>
</body>
</html>
HTML

  echo "Generated: $dir/index.html"
done
