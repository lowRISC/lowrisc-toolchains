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
set -o pipefail

repo_dir="$(git rev-parse --show-toplevel)"
build_dir="${repo_dir}/build"
dist_dir="${build_dir}/dist"

usage="\
USAGE: ${0} [options] <args>

OPTIONS:
  -h,--help   Print this message
     --debug  Build with assertions and debug info
     --clean  Build from scratch

ARGS:
     --name    <name>     Name of the toolchain
     --target  <target>   Default target triple
     --march   <march>    Default -march
     --mabi    <mabi>     Default -mabi
     --mcmodel <mcmodel>  Default -mcmodel
"
options="$(getopt -a -o '-h' -l 'help,name:,target:,march:,mabi:,mcmodel:,debug,clean' -- "$@")"

err() {
  echo "ERROR ${1}" >&2
  echo              >&2
  echo "$usage"     >&2
  exit 2
}
[[ "$options" == *"--name"* ]]    || err 'Missing argument `--name`'
[[ "$options" == *"--target"* ]]  || err 'Missing argument `--target`'
[[ "$options" == *"--march"* ]]   || err 'Missing argument `--march`'
[[ "$options" == *"--mabi"* ]]    || err 'Missing argument `--mabi`'
[[ "$options" == *"--mcmodel"* ]] || err 'Missing argument `--mcmodel`'

build_type=Release
clean=false

eval set -- "$options"
while true; do
  case "$1" in
    -h,--help) echo "$usage" && exit 0;;
    --name)    toolchain_name="$2";   shift 2;;
    --target)  toolchain_target="$2"; shift 2;;
    --march)   march="$2";            shift 2;;
    --mabi)    mabi="$2";             shift 2;;
    --mcmodel) mcmodel="$2";          shift 2;;
    --debug)   build_type=Debug;      shift 1;;
    --clean)   clean=true;            shift 1;;
    --)        shift; break;;
  esac
done

set -x

# For *_VERSION variables
# shellcheck source=sw-versions.sh
source "${repo_dir}/sw-versions.sh"

tag_name="${RELEASE_TAG:-HEAD}"

mkdir -p "$build_dir"
cd "$build_dir"

llvm_dir="${build_dir}/llvm-project"
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

llvm_build_dir="${build_dir}/llvm-project/build"

if [[ "$clean" == true ]]; then
  rm -rf "${llvm_build_dir}"
fi

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
  -DCMAKE_BUILD_TYPE="${build_type}" \
  -DCMAKE_INSTALL_PREFIX="${dist_dir}" \
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

cd "${repo_dir}"

# Copy LLVM licenses into toolchain
mkdir -p "${dist_dir}/share/licenses/llvm"
cp "${llvm_dir}/llvm/LICENSE.TXT" "${dist_dir}/share/licenses/llvm"

ls -l "${dist_dir}"

# Write out build info
set +o pipefail # head causes pipe failures, so we have to switch off pipefail while we use it.
clang_version_string="$("${dist_dir}/bin/clang" --version | head -n1)"
build_date="$(date -u)"
set -o pipefail

tee "${dist_dir}/buildinfo" <<BUILDINFO
Report toolchain bugs to toolchains@lowrisc.org (include this file)

lowRISC toolchain config:  ${toolchain_name}
lowRISC toolchain version: ${tag_name}

Clang version:
  ${clang_version_string}
  (git: ${LLVM_URL} ${LLVM_VERSION})

C Flags:
  -march=${march} -mabi=${mabi} -mcmodel=${mcmodel}

Built at ${build_date} on $(hostname)
BUILDINFO

tee "${dist_dir}/buildinfo.json" <<BUILDINFO_JSON
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
