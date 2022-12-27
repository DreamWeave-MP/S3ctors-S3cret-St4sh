#!/usr/bin/env bash
set -eu -o pipefail

this_dir="$(realpath "$(dirname "${0}")")"
cd "${this_dir}"

first_arg="${1-none}"
second_arg="${2-none}"
third_arg="${3-none}"

if [[ "${first_arg}" = none ]]; then
    echo "Please enter your new mod's name (no special characters):"
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
mv ./l10n/OpenMWModTemplate ./l10n/"${mod_id}"
mv ./scripts/OpenMWModTemplate ./scripts/"${mod_id}"
mv OpenMWModTemplate.omwscripts "${mod_id}".omwscripts

# Find and replace
# .gitlab-ci.yml:9:  project: openmw-mod-template
sed -i "s|openmw-mod-template|${mod_id}|g" .gitlab-ci.yml

# build.sh:8:file_name=openmw-mod-template.zip
# build.sh:14:zip --must-match --recurse-paths ${file_name} scripts CHANGELOG.md LICENSE README.md OpenMWModTemplate.omwscripts version.txt
sed -i "s|openmw-mod-template|${mod_id}|g;s|OpenMWModTemplate|${mod_id}|g" build.sh

# CHANGELOG.md:1:## OpenMW Mod Template Changelog
# CHANGELOG.md:7:<!--[Download Link](https://gitlab.com/modding-openmw/openmw-mod-template/-/packages/TODO)-->
sed -i "s|OpenMW Mod Template|${name}|;s|modding-openmw|${acct}|;s|openmw-mod-template|${mod_id}|" CHANGELOG.md

# l10n/OpenMWModTemplate/en.yaml:1:modDescription: A template for building OpenMW mods, designed to be used as a base for new projects to quickly get going with.
sed -i "s|A template for building OpenMW mods, designed to be used as a base for new projects to quickly get going with.|${desc}|" ./l10n/"${mod_id}"/en.yaml

# LICENSE:3:Copyright (c) 2022 OpenMW Mod Template Authors
sed -i "s|2022|${this_year}|;s|OpenMW Mod Template|${name}|" LICENSE

# openmw-mod-template.omwscripts:1:PLAYER: scripts/openmw-mod-template/player.lua
sed -i "s|OpenMWModTemplate|${mod_id}|" "${mod_id}".omwscripts

# README.md:1:# OpenMW Mod Template
# README.md:3:A template for building OpenMW mods, designed to be used as a base for new projects to quickly get going with. Made to be used with [this modders' guide](https://modding-openmw.com/guides/modders/).
sed -i "s|OpenMW Mod Template|${name}|;s|A template for building OpenMW mods, designed to be used as a base for new projects to quickly get going with. Made to be used with \[this modders' guide\](https://modding-openmw.com/guides/modders/).|${desc}|" README.md

# scripts/OpenMWModTemplate/player.lua:15:local MOD_ID = "OpenMWModTemplate"
# scripts/OpenMWModTemplate/player.lua:32:    name = "OpenMW Mod Template",
# scripts/OpenMWModTemplate/player.lua:47:    name = "OpenMW Mod Template",
# scripts/OpenMWModTemplate/player.lua:101:    -- I.OpenMWModTemplate.SayHello()
sed -i "s|OpenMWModTemplate|${mod_id}|g;s|OpenMW Mod Template|%{name}|g" ./scripts/"${mod_id}"/player.lua

# web/soupault.toml:28:  default = "OpenMW Mod Template &mdash; A template for building OpenMW mods, designed to be used as a base for new projects to quickly get going with"
# web/soupault.toml:29:  append = " | OpenMW Mod Template &mdash; A template for building OpenMW mods, designed to be used as a base for new projects to quickly get going with"
# web/soupault.toml:73:  project = "openmw-mod-template"
sed -i "s|OpenMW Mod Template|${name}|g;s|A template for building OpenMW mods, designed to be used as a base for new projects to quickly get going with|${desc}|g;s|openmw-mod-template|${mod_id}|" web/soupault.toml

# web/site/index.html:1:<p>A template for building OpenMW mods, designed to be used as a base for new projects to quickly get going with. Made to be used with <a href="https://modding-openmw.com/guides/modders/"> this modders' guide</a>.</p>
# web/site/index.html:3:  <img src="/img/openmw-mod-template.gif" title="A short gif of the mod in action" />
sed -i "s|A template for building OpenMW mods, designed to be used as a base for new projects to quickly get going with. Made to be used with <a href=\"https://modding-openmw.com/guides/modders/\"> this modders' guide</a>.|${desc}|" web/site/index.html

# web/site/index.html:3:  <img src="/img/openmw-mod-template.gif" title="A short gif of the mod in action" />
# The match above won't be replaced, the user will want to take a new screenshot/gif and replace it by hand.

# web/templates/main.html:6:    <meta name="description" content="A template for building OpenMW mods, designed to be used as a base for new projects to quickly get going with.">
# web/templates/main.html:7:    <meta name="author" content="OpenMW Mod Template Authors">
# web/templates/main.html:15:    <h1 class="center">OpenMW Mod Template</h1>
# web/templates/main.html:23:      <a class="button" id="download" title="Download the latest release of OpenMW Mod Template">Download</a>
# web/templates/main.html:30:      <a id="download" href="https://gitlab.com/api/v4/projects/modding-openmw%2Fopenmw-mod-template/jobs/artifacts/master/raw/openmw-mod-template.zip?job=make" title="Dev builds may have newer features, but they will be less tested">Dev Build</a> (<a id="sha256" href="https://gitlab.com/api/v4/projects/modding-openmw%2Fopenmw-mod-template/jobs/artifacts/master/raw/openmw-mod-template.zip.sha256sum.txt?job=make" title="Verify the integrity of the file you downloaded">sha256</a>/<a id="sha512" href="https://gitlab.com/api/v4/projects/modding-openmw%2Fopenmw-mod-template/jobs/artifacts/master/raw/openmw-mod-template.zip.sha512sum.txt?job=make" title="Verify the integrity of the file you downloaded">sha512</a>)
# web/templates/main.html:36:      <a href="https://gitlab.com/modding-openmw/openmw-mod-template/activity">Activity</a> | <a href="https://gitlab.com/modding-openmw/openmw-mod-template/-/issues">Report A Bug</a>
# web/templates/main.html:43:    <div id="modProject" data-mod-project="openmw-mod-template"></div>
sed -i "s|A template for building OpenMW mods, designed to be used as a base for new projects to quickly get going with.|${desc}|;s|OpenMW Mod Template|${name}|g;s|modding-openmw|${acct}|g;s|openmw-mod-template|${mod_id}|g" web/templates/main.html

# Inform the user how they can save their changes
cat <<EOF

Run this to save and push all changes:

  git commit -am "This is my mod now!"
  git push

EOF

# Self destruct!
rm -f "${0}"
