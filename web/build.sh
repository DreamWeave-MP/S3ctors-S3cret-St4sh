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

mods=$(./modDirs.sh ..)

modimages=""

launch_args="$@"

set -- mods

for mod in $mods; do

    grep -vi "# $mod" ../"$mod"/README.md >> site/"$mod".md
    grep -vi "# $mod Changelog" ../"$mod"/CHANGELOG.md >> site/"$mod"-changelog.md

    echo "<div id=\"modName\" data-mod-name=\""$mod"\"></div>" >> site/"$mod".md
    echo "<div id=\"modName\" data-mod-name=\""$mod"\"></div>" >> site/"$mod"-changelog.md

    modimages="$modimages<a href=\"./"$mod"/\"><img src=\"./img/"$mod".svg\" alt=\""$mod"\"/></a>+<br>+"

done

# Changelog
echo "Releases without a download link can be downloaded as a dev build from the link above." > site/changelog.md
grep -v "## S3St4sh Changelog" ../CHANGELOG.md >> site/changelog.md

# Index
# echo '<div class="center"><a href="/img/image.png"><img src="/img/image.png" title="The stats menu" /></a></div>' > site/index.md

sed "s|<div id=\"modMarker\"></div>|$modimages|" ../README.md \
    | tr '+' '\n' \
    | grep -v "# s3ctors-s3cret-st4sh" >> site/index.md

cat ../CHANGELOG.md >> site/changelog.md

echo "<div id=\"modName\" data-mod-name=\"s3ctors-s3cret-st4sh\"></div>" >> site/index.md
echo "<div id=\"modName\" data-mod-name=\"s3ctors-s3cret-st4sh\"></div>" >> site/changelog.md


set -- $launch_args

PATH=${soupault_path}:$PATH soupault "$@"
