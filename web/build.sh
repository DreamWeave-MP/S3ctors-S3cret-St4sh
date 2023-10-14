#!/usr/bin/env bash
set -euo pipefail

#
# This script builds the project website. It downloads soupault as needed and
# then runs it, the built website can be found at: web/build
#

this_dir=$(realpath "$(dirname "${0}")")
cd "${this_dir}"

soupault_version=4.6.0
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

cp ../CHANGELOG.md site/changelog.md
cp ../README.md site/readme.md

PATH=${soupault_path}:$PATH soupault "$@"
