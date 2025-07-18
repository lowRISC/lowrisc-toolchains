#!/bin/bash
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

## build-binutils.sh
#
# Builds:
# - GNU Binutils, GDB
#
# Then:
# - Creates a tar file of the whole install directory

set -e -o pipefail

repo_dir="$(git rev-parse --show-toplevel)"
build_dir="${repo_dir}/build"
patch_dir="${repo_dir}/patches"

source "${repo_dir}/sw-versions.sh"

if [ "$#" -ne 2 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  echo "USAGE: $0 <target> <dist dir>"    >&2
  echo                                    >&2
  echo "EXAMPLE:"                         >&2
  echo "  $0 riscv32 dist/"               >&2
  exit 1
fi

# Strip any `-unknown-...` suffix
target="${1/%-*}"
if [ "$target" != "riscv32" ] && [ "$target" != "riscv64" ]; then
  echo "Error: unsupported target '${target}'"   >&2
  echo                                           >&2
  echo "Supported targets are: riscv32, riscv64" >&2
  exit 1
fi

set -x

dist_dir="$(realpath "$2")"
mkdir -p "$dist_dir"

mkdir -p "$build_dir"
cd $build_dir

if [ ! -d binutils ]; then
  git clone "$BINUTILS_URL" binutils
fi

cd binutils
git reset --hard
git checkout "$BINUTILS_COMMIT"
git apply "${patch_dir}/binutils/"*

mkdir -p build
cd build

# export LDFLAGS="--static"

../configure \
  --target "$target" \
  --program-prefix="${target}-unknown-elf-" \
  --prefix "$dist_dir"

make -j "$(nproc)"
make install
