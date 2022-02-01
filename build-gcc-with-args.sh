#!/bin/bash
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

## build-gcc-with-args.sh
#
# Builds:
# - GCC, using crosstool-ng and the .config files provided
#
# Then:
# - Adds a `buildinfo` file describing the configuration
# - Adds cross-compilation configuration files for certain build systems
# - Creates a tar file of the whole install directory

set -e
set -x
set -o pipefail

if ! [ "$#" -ge 3 ]; then
  echo "Usage: $0 <config_name> <target> <dest_dir> <cflags...>"
  exit 2
fi;

## Take configuration from arguments
# This is the name for the tar file, and also the basename of the .config file
toolchain_name="${1}"
# This is the expected gcc target triple (so we can invoke gcc)
toolchain_target="${2}"
# This is the directory where we want the toolchain to be installed.
toolchain_dest="${3}"
# -march option default value
march="${4}"
# -mabi option default value
mabi="${5}"
# -mcmodel option default value
mcmodel="${6}"
# Remaining cflags for build configurations
toolchain_cflags=("${@:7}")

build_top_dir="${PWD}"

# For *_VERSION variables
# shellcheck source=sw-versions.sh
source "${build_top_dir}/sw-versions.sh"

tag_name="${RELEASE_TAG:-HEAD}"
toolchain_full_name="${toolchain_name}-${tag_name}"

# crosstools-NG needs the ability to create and chmod the
# $toolchain_dest directory.
sudo mkdir -p "$(dirname "${toolchain_dest}")"
sudo chmod 777 "$(dirname "${toolchain_dest}")"

mkdir -p "${toolchain_dest}"

mkdir -p "${build_top_dir}/build/gcc"
cd "${build_top_dir}/build/gcc"

# Create crosstool-ng config file with correct `CT_PREFIX_DIR` and `CT_LOCAL_PATCH_DIR`
{
  grep -v '^CT_PREFIX_DIR=' "${build_top_dir}/${toolchain_name}.config"
  echo ""
  echo "# ADDED BY ${0}";
  echo "CT_PREFIX_DIR=\"${toolchain_dest}\""
  echo "CT_LOCAL_PATCH_DIR=\"${build_top_dir}/patches/${toolchain_name}\""
  echo "# END ADDED BY ${0}"
} > .config
ct-ng upgradeconfig
cat .config

# crosstool-ng doesn't work with some environment variables set, leading to
# errors like "Don't set LD_LIBRARY_PATH. It screws up the build." otherwise.
# Do so in a subshell to avoid disturbing subsequent tasks.
(
  unset LD_LIBRARY_PATH
  unset LIBRARY_PATH
  unset LPATH
  unset CPATH
  unset C_INCLUDE_PATH
  unset CPLUS_INCLUDE_PATH
  unset OBJC_INCLUDE_PATH
  unset CFLAGS
  unset CXXFLAGS
  unset CC
  unset CXX
  unset GREP_OPTIONS

  # Invoke crosstool-ng
  ct-ng build
)

cd "${build_top_dir}"

## Create Toolchain Files!
# These don't yet add cflags ldflags
"${build_top_dir}/generate-gcc-cmake-toolchain.sh" \
  "${toolchain_target}" "${toolchain_dest}" "${toolchain_cflags[@]}"
"${build_top_dir}/generate-gcc-meson-cross-file.sh" \
  "${toolchain_target}" "${toolchain_dest}" ${march} ${mabi} ${mcmodel} \
  "${toolchain_cflags[@]}"

ls -l "${toolchain_dest}"

# Write out build info
set +o pipefail # head causes pipe failures, so we have to switch off pipefail while we use it.
ct_ng_version_string="$(ct-ng version | head -n1)"
gcc_version_string="$("${toolchain_dest}/bin/${toolchain_target}-gcc" --version | head -n1)"
build_date="$(date -u)"
set -o pipefail

tee "${toolchain_dest}/buildinfo" <<BUILDINFO
Report toolchain bugs to toolchains@lowrisc.org (include this file)

lowRISC toolchain config:  ${toolchain_name}
lowRISC toolchain version: ${tag_name}

GCC version:
  ${gcc_version_string}

Crosstool-ng version:
  ${ct_ng_version_string}
  (git: ${CROSSTOOL_NG_URL} ${CROSSTOOL_NG_VERSION})

C Flags:
  -march=${march} -mabi=${mabi} -mcmodel=${mcmodel} ${toolchain_cflags[@]}

Built at ${build_date} on $(hostname)
BUILDINFO

tee "${toolchain_dest}/buildinfo.json" <<BUILDINFO_JSON
{
  "toolchain_config": "${toolchain_name}",
  "kind": "gcc-only",
  "version": "${tag_name}",
  "gcc_version": "${gcc_version_string}",
  "crosstool-ng_version": "${ct_ng_version_string}",
  "crosstool-ng_url": "${CROSSTOOL_NG_URL}",
  "crosstool-ng_git": "${CROSSTOOL_NG_VERSION}",
  "build_date": "${build_date}",
  "build_host": "$(hostname)"
}
BUILDINFO_JSON

# If `ARTIFACT_STAGING_DIR` is not set, we don't want to leave the final binary
# in the root directory.
artifact_dir="${ARTIFACT_STAGING_DIR:-${build_top_dir}/build}"

# Package up toolchain directory
"${build_top_dir}/create-prefixed-archive.sh" \
  "${toolchain_full_name}" \
  "${toolchain_dest}" \
  "${artifact_dir}"
