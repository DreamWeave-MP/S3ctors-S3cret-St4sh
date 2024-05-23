#!/usr/bin/env bash
set -euo pipefail

#
# This script builds the project website. It downloads soupault as needed and
# then runs it, the built website can be found at: web/build
#

this_dir=$(realpath "$(dirname "${0}")")
cd "${this_dir}"

soupault_version=4.8.0
soupault_pkg=soupault-${soupault_version}-linux-x86_64.tar.gz
soupault_path=./soupault-${soupault_version}-linux-x86_64

shas=https://github.com/PataphysicalSociety/soupault/releases/download/${soupault_version}/sha256sums
spdl=https://github.com/PataphysicalSociety/soupault/releases/download/${soupault_version}/${soupault_pkg}

if ! [ -f ${soupault_path}/soupault ]; then
    wget ${shas}
    wget ${spdl}
    tar xf ${soupault_pkg}
    grep linux sha256sums | sha256sum -c -
fi

# Changelog
echo "Releases without a download link can be downloaded as a dev build from the link above." > site/changelog.md
grep -v "## MOMW Mod Template" ../CHANGELOG.md >> site/changelog.md

# Index
# echo '<div class="center"><a href="/img/image.png"><img src="/img/image.png" title="The stats menu" /></a></div>' > site/index.md
grep -v "# MOMW Mod Template" ../README.md >> site/index.md
cp ../toolgun/README.md site/toolgun.md

PATH=${soupault_path}:$PATH soupault "$@"
