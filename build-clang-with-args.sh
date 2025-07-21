#!/bin/bash
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

## build-clang-with-args.sh
#
# Builds:
# - Clang/LLVM
#
# Then:
# - Appends to `buildinfo` with the clang info
# - Adds cross-compilation configuration files for certain build systems
# - Creates a tar file of the whole install directory

set -e
set -x
set -o pipefail

if ! [ "$#" -ge 3 ]; then
  echo "Usage: $0 <config_name> <target> <dest_dir> <march> <mabi> <mcmodel> <cflags...>"
  exit 2
fi;

## Take configuration from arguments
# This is the name for the tar file.
toolchain_name="${1}"
# This is the expected target triple (so we can set a default)
toolchain_target="${2}"
# This is the directory where we want the toolchain to added to
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

mkdir -p "${build_top_dir}/build"
cd "${build_top_dir}/build"


llvm_dir="${build_top_dir}/build/llvm-project"
if [ ! -d "$llvm_dir" ]; then
  git clone "$LLVM_URL" "$llvm_dir" \
    --branch "$LLVM_BRANCH" \
    --depth 1
fi
cd "${llvm_dir}"
git fetch origin
git checkout --force "${LLVM_VERSION}"

# Clang Symlinks
clang_links_to_create="clang++"
clang_links_to_create+=";${toolchain_target}-clang;${toolchain_target}-clang++"
# LLD Symlinks
lld_links_to_create="ld.lld;ld64.lld"
lld_links_to_create+=";${toolchain_target}-ld.lld;${toolchain_target}-ld64.lld"

llvm_build_dir="${build_top_dir}/build/llvm-build"

# Delete old build artifacts (if they exist)
rm -rf "${llvm_build_dir}"

mkdir -p "${llvm_build_dir}"
cd "${llvm_build_dir}"

# TODO:
# - Stage 2 Build
# - Build compiler-rt and other runtimes

llvm_tools="llvm-ar"
llvm_tools+=";llvm-cov"
llvm_tools+=";llvm-dwarfdump"
llvm_tools+=";llvm-nm"
llvm_tools+=";llvm-objcopy"
llvm_tools+=";llvm-objdump"
llvm_tools+=";llvm-profdata"
llvm_tools+=";llvm-ranlib"
llvm_tools+=";llvm-readelf"
llvm_tools+=";llvm-readobj"
llvm_tools+=";llvm-size"
llvm_tools+=";llvm-strings"
llvm_tools+=";llvm-strip"
llvm_tools+=";llvm-symbolizer"

llvm_distribution_components="clang;"
llvm_distribution_components+=";clang-format"
llvm_distribution_components+=";clang-tidy"
llvm_distribution_components+=";clang-resource-headers"
llvm_distribution_components+=";libclang"
llvm_distribution_components+=";lld"
llvm_distribution_components+=";scan-build"
llvm_distribution_components+=";scan-view"
llvm_distribution_components+=";${llvm_tools}"

cmake "${llvm_dir}/llvm" \
  -Wno-dev \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${toolchain_dest}" \
  -DLLVM_TARGETS_TO_BUILD="RISCV" \
  -DLLVM_ENABLE_PROJECTS="clang;lld;clang-tools-extra" \
  -DLLVM_ENABLE_BACKTRACES=Off \
  -DLLVM_DEFAULT_TARGET_TRIPLE="${toolchain_target}" \
  -DLLVM_STATIC_LINK_CXX_STDLIB=On \
  -DCLANG_VENDOR="lowRISC" \
  -DBUG_REPORT_URL="toolchains@lowrisc.org" \
  -DLLVM_INCLUDE_EXAMPLES=Off \
  -DLLVM_INCLUDE_DOCS=Off \
  -DLLVM_INSTALL_TOOLCHAIN_ONLY=On \
  -DLLVM_INSTALL_BINUTILS_SYMLINKS=Off \
  -DCLANG_LINKS_TO_CREATE="${clang_links_to_create}" \
  -DLLD_SYMLINKS_TO_CREATE="${lld_links_to_create}" \
  -DLLVM_TOOLCHAIN_TOOLS="${llvm_tools}" \
  -DLLVM_DISTRIBUTION_COMPONENTS="${llvm_distribution_components}"

cmake --build "${llvm_build_dir}" \
  --parallel $(( $(nproc) + 2 )) \
  --target install-distribution

cd "${build_top_dir}"

# Copy LLVM licenses into toolchain
mkdir -p "${toolchain_dest}/share/licenses/llvm"
cp "${llvm_dir}/llvm/LICENSE.TXT" "${toolchain_dest}/share/licenses/llvm"

ls -l "${toolchain_dest}"

# Write out build info
set +o pipefail # head causes pipe failures, so we have to switch off pipefail while we use it.
ct_ng_version_string="$( (set +o pipefail; ct-ng version | head -n1) )"
clang_version_string="$("${toolchain_dest}/bin/clang" --version | head -n1)"
build_date="$(date -u)"
set -o pipefail

tee "${toolchain_dest}/buildinfo" <<BUILDINFO
Report toolchain bugs to toolchains@lowrisc.org (include this file)

lowRISC toolchain config:  ${toolchain_name}
lowRISC toolchain version: ${tag_name}

Clang version:
  ${clang_version_string}
  (git: ${LLVM_URL} ${LLVM_VERSION})

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
  "kind": "combined",
  "version": "${tag_name}",
  "clang_version": "${clang_version_string}",
  "clang_url": "${LLVM_URL}",
  "clang_git": "${LLVM_VERSION}",
  "build_date": "${build_date}",
  "build_host": "$(hostname)"
}
BUILDINFO_JSON
