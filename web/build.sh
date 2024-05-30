#!/usr/bin/env bash
set -euo pipefail

#
# This script builds the project website. It downloads soupault as needed and
# then runs it, the built website can be found at: web/build
#

append_mod_name_div() {
  local mod=$1
  local modName=$2
  local file=$3
  echo "<div id=\"modData\" data-mod-path=\"${mod}\" data-mod-title=\"${modName}\"></div>" >> "$file"
}

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

    mod_title=$(head -1 ../"$mod"/README.md | cut -c 3- | tr -d '\n')

    rm -rf site/"$mod"
    mkdir -p site/"$mod"
    grep -vi "# $mod" ../"$mod"/README.md >> site/"$mod"/index.md

    ../changelog.sh "$mod" >> site/"$mod"/changelog.md

    if [ -f ../"$mod"/CHANGELOG.md ]; then
        grep -vi "#.*changelog" ../"$mod"/CHANGELOG.md >> site/"$mod"/changelog.md
    fi

    append_mod_name_div "$mod" "$mod_title" site/"$mod"/index.md
    append_mod_name_div "$mod" "$mod_title" site/"$mod"/changelog.md


    modimages="$modimages
<div style=\"border: 1px solid #000;\"><a class="modHeader" id="$mod" href=\"./"$mod"/\">$mod_title</a></div>
<br>
"

done

# Changelog
echo "Releases without a download link can be downloaded as a dev build from the link above." > site/index.md

awk -v mods="$modimages" '
    NR == 1 { next }
    /<div id="modMarker"><\/div>/ { print mods; next }
    { print }
' ../README.md >> site/index.md

append_mod_name_div s3ctors_s3cret_st4sh "S3ctor's S3cret St4sh" site/index.md

../changelog.sh "s3ctors_s3cret_st4sh" >> site/changelog.md

append_mod_name_div s3ctors_s3cret_st4sh "S3ctor's S3cret St4sh" site/changelog.md


set -- $launch_args

PATH=${soupault_path}:$PATH soupault "$@"
