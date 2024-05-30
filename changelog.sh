#!/usr/bin/env sh

set -euo pipefail

GITLAB_REPO_URL="https://gitlab.com/modding-openmw/s3ctors-s3cret-st4sh"
previous_tag=""
tag_prefix="$1"

# Get all tagged releases for it, sorted by date
tags=$(git tag --list "${tag_prefix}-*" --sort=-creatordate)

# If no tags are found, exit
if [ -z "$tags" ]; then
  echo "There are no releases for $tag_prefix!"
  exit 0
fi

# Iterate through the tags
for tag in $tags; do
  if [ -n "$previous_tag" ]; then
    version=$(echo "$previous_tag" | cut -d '-' -f 2)

    echo -e "
<style>
  h4 {
    text-decoration: none;
  }

  h4:hover {
    text-decoration: underline;
  }
</style>
"

    echo -e "<details><summary><h4>Version $version:</h4></summary>"
    git log --pretty=format:"%h %s" "$tag".."$previous_tag" | while read -r commit_hash commit_message; do
      echo "- <a href="$GITLAB_REPO_URL/commit/$commit_hash">$commit_hash - $commit_message</a><br>"
    done
    echo -e "</details>\n"
  fi
  previous_tag=$tag
done
