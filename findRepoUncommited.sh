
find ~/workspace -name ".git" -type d | while read gitdir; do
  repo=$(dirname "$gitdir")
  cd "$repo" || continue

  if [ -n "$(git status --porcelain)" ]; then
    echo "=== UNCOMMITTED: $repo ==="
  fi
done
