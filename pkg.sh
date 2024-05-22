#!/bin/sh
set -eu

#
# This script packages the project into a zip file.
#

file_name=s3ctors-s3cret-st4sh.zip

cat > version.txt <<EOF
Mod version: $(git describe --tags || git rev-parse --short HEAD)
EOF

zip --must-match --recurse-paths ${file_name} l10n scripts CHANGELOG.md LICENSE README.md s3ctors-s3cret-st4sh.omwscripts version.txt
sha256sum ${file_name} > ${file_name}.sha256sum.txt
sha512sum ${file_name} > ${file_name}.sha512sum.txt
