#!/bin/bash
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

## build-gcc-with-args.sh
#
# Builds:
# - GCC, using crosstool-ng and the .config files provided
# - Qemu (userspace)
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
# Remaining cflags for build configurations
toolchain_cflags=("${@:4}")

build_top_dir="${PWD}"

# For *_VERSION variables
# shellcheck source=sw-versions.sh
source "${build_top_dir}/sw-versions.sh"

tag_name="$(git -C "${build_top_dir}" describe --always)"
set +x
echo "##vso[task.setvariable variable=ReleaseTag]${tag_name}"
set -x

toolchain_full_name="${toolchain_name}-${tag_name}"

# crosstools-NG needs the ability to create and chmod the
# $toolchain_dest directory.
sudo mkdir -p "$(dirname "${toolchain_dest}")"
sudo chmod 777 "$(dirname "${toolchain_dest}")"

mkdir -p "${toolchain_dest}"

mkdir -p "${build_top_dir}/build/gcc"
cd "${build_top_dir}/build/gcc"

# Create crosstool-ng config file with correct `CT_PREFIX_DIR`
{
  cat "${build_top_dir}/${toolchain_name}.config";
  echo "";
  echo "# ADDED BY ${0}";
  echo "CT_PREFIX_DIR=\"${toolchain_dest}\"";
  echo "# END ADDED BY ${0}";
} >> .config
ct-ng upgradeconfig
cat .config

# Invoke crosstool-ng
ct-ng build

# Build Qemu when building a RISC-V linux toolchain
qemu_dir="${build_top_dir}/build/qemu"

qemu_prefix_arg=""
case "${toolchain_target}" in
  riscv*-linux-gnu)
    qemu_prefix_arg="--interp-prefix=${toolchain_dest}/${toolchain_target}/sysroot"
  ;;
esac

git clone https://git.qemu.org/git/qemu.git "${qemu_dir}"
cd "${qemu_dir}"

git checkout --force --recurse-submodules "${QEMU_VERSION}"

mkdir -p "${qemu_dir}/build"
cd "${qemu_dir}/build"

# shellcheck disable=SC2086
"${qemu_dir}/configure" \
  "--prefix=${toolchain_dest}" \
  ${qemu_prefix_arg} \
  "--target-list=riscv64-softmmu,riscv32-softmmu,riscv64-linux-user,riscv32-linux-user"

make -j$(( $(nproc) + 2 ))
make -j$(( $(nproc) + 2 )) install

# Copy Qemu licenses into toolchain
mkdir -p "${toolchain_dest}/share/licenses/qemu"
cp "${qemu_dir}/LICENSE" "${toolchain_dest}/share/licenses/qemu"
cp "${qemu_dir}/COPYING" "${toolchain_dest}/share/licenses/qemu"
cp "${qemu_dir}/COPYING.LIB" "${toolchain_dest}/share/licenses/qemu"

cd "${build_top_dir}/build/gcc"

## Create Toolchain Files!
# These don't yet add cflags ldflags
"${build_top_dir}/generate-gcc-cmake-toolchain.sh" \
  "${toolchain_target}" "${toolchain_dest}" "${toolchain_cflags[@]}"
"${build_top_dir}/generate-gcc-meson-cross-file.sh" \
  "${toolchain_target}" "${toolchain_dest}" "${toolchain_cflags[@]}"

ls -l "${toolchain_dest}"

# Write out build info
set +o pipefail # head causes pipe failures, so we have to switch off pipefail while we use it.
ct_ng_version_string="$(ct-ng version | head -n1)"
gcc_version_string="$("${toolchain_dest}/bin/${toolchain_target}-gcc" --version | head -n1)"
qemu_version_string="$("${toolchain_dest}/bin/qemu-riscv64" --version | head -n1)"
build_date="$(date -u)"
set -o pipefail

tee "${toolchain_dest}/buildinfo" <<BUILDINFO
Report toolchain bugs to toolchains@lowrisc.org (include this file)

lowRISC toolchain config:  ${toolchain_name}
lowRISC toolchain version: ${tag_name}

GCC version:
  ${gcc_version_string}

Qemu version:
  ${qemu_version_string}
  (git: ${QEMU_VERSION})

Crosstool-ng version:
  ${ct_ng_version_string}
  (git: ${CROSSTOOL_NG_VERSION})

C Flags:
  ${toolchain_cflags[@]}

Built at ${build_date} on $(hostname)
BUILDINFO

tee "${toolchain_dest}/buildinfo.json" <<BUILDINFO_JSON
{
  "toolchain_config": "${toolchain_name}",
  "version": "${tag_name}",
  "gcc_version": "${gcc_version_string}",
  "qemu_version": "${qemu_version_string}",
  "qemu_git": "${QEMU_VERSION}",
  "crosstool-ng_version": "${ct_ng_version_string}",
  "crosstool-ng_git": "${CROSSTOOL_NG_VERSION}",
  "build_date": "${build_date}",
  "build_host": "$(hostname)"
}
BUILDINFO_JSON

# Package up toolchain directory
tar -cJ \
  --show-transformed-names --verbose \
  --directory="$(dirname "${toolchain_dest}")" \
  -f "$ARTIFACT_STAGING_DIR/$toolchain_full_name.tar.xz" \
  --transform="flags=rhS;s@^$(basename "${toolchain_dest}")@$toolchain_full_name@" \
  --owner=0 --group=0 \
  "$(basename "${toolchain_dest}")"
