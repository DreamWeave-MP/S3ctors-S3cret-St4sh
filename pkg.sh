#!/bin/sh
set -eu

#
# This script packages the project into a zip file.
#

# Some stuff needs to be special cased as we pull from starwind-builder
wget 'https://gitlab.com/modding-openmw/starwind-builder/-/jobs/artifacts/master/raw/Starwind_Community_Patch_Project.zip?job=build_cpp' -O sw_cpp.zip
unzip -o sw_cpp.zip -d sw_cpp/
rm sw_cpp.zip

file_name=s3ctors_s3cret_st4sh

cat > version.txt <<EOF
Mod version: $(git describe --tags || git rev-parse --short HEAD)
EOF

mods=$(./web/modDirs.sh .)

set -- mods

for mod in $mods; do

zip --must-match \
    --recurse-paths \
    "$mod".zip \
    version.txt \
    "$mod"/

sha256sum "$mod".zip > "$mod".sha256sum.txt
sha512sum "$mod".zip > "$mod".sha512sum.txt

done

zip --must-match \
    ${file_name}.zip \
    version.txt \
    *sha*sum.txt \
    *.zip

sha256sum ${file_name}.zip > ${file_name}.sha256sum.txt
sha512sum ${file_name}.zip > ${file_name}.sha512sum.txt
