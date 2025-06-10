#!/usr/bin/env sh
set -euo

#
# This script builds the project website. It downloads soupault as needed and
# then runs it, the built website can be found at: web/build
#

while [ $# -gt 0 ]; do
  case "$1" in
    --with-downloads)
      DO_DOWNLOADS=1
      shift
      ;;
    *)
      break
      ;;
  esac
done

if [ "${DO_DOWNLOADS:-0}" = 1 ]; then
  # These used to be part of pkg.sh, but now pkg.sh is deprecated...
  wget 'https://gitlab.com/modding-openmw/starwind-builder/-/jobs/artifacts/master/raw/Starwind_Community_Patch_Project.zip?job=build_cpp' -O sw_cpp.zip
  unzip -o sw_cpp.zip -d sw_cpp/
  rm sw_cpp.zip

  wget 'https://gitlab.com/modding-openmw/Starwind-Builder/-/jobs/artifacts/master/download?job=build_tsi' -O sw_merged/Starwind.omwaddon
  wget 'https://gitlab.com/modding-openmw/Starwind-Builder/-/jobs/artifacts/master/download?job=build_vanilla' -O sw_merged/Starwind_SP.omwaddon
fi

this_dir=$(realpath "$(dirname "${0}")")
cd "${this_dir}"

soupault_version=4.10.0
soupault_pkg=soupault-${soupault_version}-linux-x86_64.tar.gz
soupault_path=./soupault-${soupault_version}-linux-x86_64

shas=https://github.com/PataphysicalSociety/soupault/releases/download/${soupault_version}/sha256sums
spdl=https://github.com/PataphysicalSociety/soupault/releases/download/${soupault_version}/${soupault_pkg}

if ! [ -f ./soupault ]; then
    wget ${shas}
    wget ${spdl}
    tar xf ${soupault_pkg}
    grep linux-x86_64 sha256sums | sha256sum -c -
    mv ${soupault_path}/soupault .
    rm -rf ${soupault_pkg} ${soupault_path} sha256sums
fi

./soupault "$@"
