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
dist_dir="${build_dir}/dist"

source "${repo_dir}/sw-versions.sh"

if [ "$#" -ne 1 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  echo "USAGE: $0 <target>" >&2
  echo                      >&2
  echo "EXAMPLE:"           >&2
  echo "  $0 riscv32"       >&2
  exit 1
fi

target="$1"

# Double check the arch part of the target tuple.
target_arch="${target/%-*}"
if [ "$target_arch" != "riscv32" ] && [ "$target_arch" != "riscv64" ]; then
  echo "Error: unsupported target '${target}'"  >&2
  echo                                          >&2
  echo "Supported arches are: riscv32, riscv64" >&2
  exit 1
fi

set -x

mkdir -p "$build_dir"
cd "$build_dir"

if [ ! -d binutils ]; then
  git clone "$BINUTILS_URL" binutils \
    --branch "$BINUTILS_BRANCH" \
    --depth 1
fi

cd binutils
git reset --hard
git checkout "$BINUTILS_COMMIT"
git apply "${patch_dir}/binutils/"*

mkdir -p build
cd build

mkdir -p "$dist_dir"

../configure \
  --target="$target" \
  --program-prefix="$target-" \
  --prefix="$dist_dir" \
  --with-libexpat-type=static

make -j "$(nproc)"
make install
