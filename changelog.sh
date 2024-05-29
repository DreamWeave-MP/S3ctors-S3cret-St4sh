#!/usr/bin/env sh

set -euo pipefail

# Check if the current commit is associated with a tag


# current_commit=$(git rev-parse HEAD)
# tag_name=$(git describe --exact-match --tags $current_commit 2>/dev/null || true)

# # If no tags are found, exit
# if [ -z "$tag_name" ]; then
#   echo "No tags found for: $current_commit"
#   exit 0
# fi

# Get the name of the mod
tag_prefix="$1"
# tag_prefix=$(echo "$tag_name" | cut -d '-' -f 1)

# Get all tagged releases for it, sorted by date
tags=$(git tag --list "${tag_prefix}-*" --sort=-creatordate)

# If no tags are found, exit
if [ -z "$tags" ]; then
  echo "There are no releases for $tag_prefix!"
  exit 0
fi

# Initialize previous tag as the first tag in the list
previous_tag=""
GITLAB_REPO_URL="https://gitlab.com/$(git remote get-url origin | cut -d ':' -f 2 | cut -d '.' -f 1)"

# Iterate through the tags
for tag in $tags; do
  if [ -n "$previous_tag" ]; then
    # List all commits between the previous tag and the current tag
    version=$(echo "$previous_tag" | cut -d '-' -f 2)
    echo -e "#### Version $version:\n  "
    git log --pretty=format:"%h %s" "$tag".."$previous_tag" | while read -r commit_hash commit_message; do
      echo "- [$commit_hash]($GITLAB_REPO_URL/commit/$commit_hash) - $commit_message  "
    done
    echo
  fi
  previous_tag=$tag
done
