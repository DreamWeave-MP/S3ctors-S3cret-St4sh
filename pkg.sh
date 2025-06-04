#!/bin/sh
set -eu

#
# This script packages the project into a zip file.
#

# Some stuff needs to be special cased as we pull from starwind-builder
wget 'https://gitlab.com/modding-openmw/starwind-builder/-/jobs/artifacts/master/raw/Starwind_Community_Patch_Project.zip?job=build_cpp' -O sw_cpp.zip
unzip -o sw_cpp.zip -d sw_cpp/
rm sw_cpp.zip

wget 'https://gitlab.com/modding-openmw/Starwind-Builder/-/jobs/artifacts/master/download?job=build_tsi' -O sw_merged/Starwind.omwaddon
wget 'https://gitlab.com/modding-openmw/Starwind-Builder/-/jobs/artifacts/master/download?job=build_vanilla' -O sw_merged/Starwind_SP.omwaddon

file_name=s3ctors_s3cret_st4sh

cat > version.txt <<EOF
Mod version: $(git describe --tags || git rev-parse --short HEAD)
EOF

mods=$(./web/modDirs.sh .)

set -- mods

for mod in $mods; do

    cp version.txt "$mod"/

    cd "$mod"/

    # if [ -f CHANGELOG.md ]; then
    #     mv CHANGELOG.md orig_CHANGELOG.md
    #     cat <(../changelog.sh "$mod") orig_CHANGELOG.md > CHANGELOG.md
    # else
    #     ../changelog.sh "$mod" > CHANGELOG.md
    # fi

    zip --recurse-paths \
        ../"$mod".zip \
        . \
        --exclude=orig_CHANGELOG.md

    rm -rf CHANGELOG.md

    if [ -f orig_CHANGELOG.md ]; then
        mv orig_CHANGELOG.md CHANGELOG.md
    fi

    cd ..

    sha256sum "$mod".zip > "$mod".sha256sum.txt
    sha512sum "$mod".zip > "$mod".sha512sum.txt

done

# mv CHANGELOG.md orig_CHANGELOG.md
# cat <(./changelog.sh s3ctors_s3cret_st4sh) orig_CHANGELOG.md > CHANGELOG.md

zip --must-match \
    ${file_name}.zip \
    CHANGELOG.md \
    version.txt \
    *sha*sum.txt \
    *.zip

# rm -rf CHANGELOG.md

# mv orig_CHANGELOG.md CHANGELOG.md

sha256sum ${file_name}.zip > ${file_name}.sha256sum.txt
sha512sum ${file_name}.zip > ${file_name}.sha512sum.txt
