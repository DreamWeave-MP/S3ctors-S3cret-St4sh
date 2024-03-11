#!/usr/bin/env bash
set -eu -o pipefail

this_dir="$(realpath "$(dirname "${0}")")"
cd "${this_dir}"

first_arg="${1-none}"
second_arg="${2-none}"
third_arg="${3-none}"

if [[ "${first_arg}" = none ]]; then
    echo "Please enter your new mod's name (no special characters, dash instead of spaces, and all lowercase!):"
    read -r name
else
    name="${first_arg}"
fi

if [[ "${second_arg}" = none ]]; then
    echo "Please enter a description for your new mod:"
    read -r desc
else
    desc="${second_arg}"
fi

if [[ "${third_arg}" = none ]]; then
    echo "Please enter your GitLab account name (e.g. https://gitlab.com/my-account-name):"
    read -r acct
else
    acct="${third_arg}"
fi

mod_id=${name//[[:space:]]/}
this_year=$(date +%Y)

# Rename dirs and things
mv ./l10n/MOMWModTemplate ./l10n/"${mod_id}"
mv ./scripts/MOMWModTemplate ./scripts/"${mod_id}"
mv MOMWModTemplate.omwscripts "${mod_id}".omwscripts

# Find and replace
sed -i "s|momw-mod-template|${mod_id}|g" .gitlab-ci.yml
sed -i "s|momw-mod-template|${mod_id}|g;s|MOMWModTemplate|${mod_id}|g" pkg.sh
sed -i "s|MOMW Mod Template|${name}|;s|modding-openmw|${acct}|;s|momw-mod-template|${mod_id}|" CHANGELOG.md
sed -i "s|A template for building and distributing Morrowind mods, designed to be used as a base for new projects to quickly get going with.|${desc}|" ./l10n/"${mod_id}"/en.yaml
sed -i "s|2022|${this_year}|;s|MOMW Mod Template|${name}|" LICENSE
sed -i "s|MOMWModTemplate|${mod_id}|" "${mod_id}".omwscripts
sed -i "s|MOMW Mod Template|${name}|;s|A template for building and distributing Morrowind mods, designed to be used as a base for new projects to quickly get going with. Made to be used with \[this modders' guide\](https://modding-openmw.com/guides/modders/).|${desc}|" README.md
sed -i "s|MOMWModTemplate|${mod_id}|g;s|MOMW Mod Template|%{name}|g" ./scripts/"${mod_id}"/player.lua
sed -i "s|MOMW Mod Template|${name}|g;s|A template for building and distributing Morrowind mods, designed to be used as a base for new projects to quickly get going with.${desc}|g;s|momw-mod-template|${mod_id}|" web/soupault.toml
sed -i "s|A template for building and distributing Morrowind mods, designed to be used as a base for new projects to quickly get going with. Made to be used with <a href=\"https://modding-openmw.com/guides/modders/\"> this modders' guide</a>.|${desc}|" web/site/index.html
sed -i "s|A template for building and distributing Morrowind mods, designed to be used as a base for new projects to quickly get going with.|${desc}|;s|MOMW Mod Template|${name}|g;s|modding-openmw|${acct}|g;s|momw-mod-template|${mod_id}|g" web/templates/main.html

echo rm -rf .git

echo git init

# Inform the user how they can save their changes
cat <<EOF

Run this to save and push all changes:

  git commit -am "Initial commit of my new mod"
  git push

EOF

# Self destruct!
echo rm -f "${0}"
