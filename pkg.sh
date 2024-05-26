#!/bin/sh
set -eu

#
# This script packages the project into a zip file.
#

file_name=s3ctors-s3cret-st4sh.zip

cat > version.txt <<EOF
Mod version: $(git describe --tags || git rev-parse --short HEAD)
EOF

mods="toolgun"

set -- mods

for mod in $mods; do

zip --must-match \
    --recurse-paths \
    "$mod".zip \
    "$mod"/

sha256sum "$mod".zip > "$mod".sha256sum.txt
sha512sum "$mod".zip > "$mod".sha512sum.txt

done

zip --must-match \
    ${file_name} \
    version.txt \
    *sha*sum.txt \
    *.zip

sha256sum ${file_name} > ${file_name}.sha256sum.txt
sha512sum ${file_name} > ${file_name}.sha512sum.txt
