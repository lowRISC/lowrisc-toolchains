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
static_libs_dir="${build_dir}/libs"

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

mkdir -p "$dist_dir"
mkdir -p "$build_dir"
mkdir -p "$static_libs_dir"
cd "$build_dir"

if [ ! -d binutils ]; then
  git clone "$BINUTILS_URL" binutils \
    --branch "$BINUTILS_BRANCH" \
    --depth 1
fi

if [ ! -d gmp ]; then
    tmp=$(mktemp -d)
    mkdir -p ${tmp}/gmp
    curl -L "$GMP_URL" -o "${tmp}/gmp.tar.xz"
    printf "$GMP_SHA256  ${tmp}/gmp.tar.xz\n" > ${tmp}/gmp.sha256
    sha256sum -c ${tmp}/gmp.sha256
    xzcat ${tmp}/gmp.tar.xz | tar --strip-components=1 -C ${tmp}/gmp -x -v -f -
    mv ${tmp}/gmp gmp
    rm ${tmp}/gmp.tar.xz
fi

if [ ! -d mpfr ]; then
    git clone "$MPFR_URL" mpfr \
    --branch "$MPFR_BRANCH" \
    --depth 1
fi

cd gmp
./configure \
    --enable-static=yes \
    --enable-shared=no \
    --prefix=$static_libs_dir
make -j "$(nproc)"
make -j "$(nproc)" check
make install
cd ..

cd mpfr
./autogen.sh
./configure \
    --enable-static=yes \
    --enable-shared=no \
    --with-gmp=$static_libs_dir \
    --prefix=$static_libs_dir
make -j "$(nproc)"
make install
cd ..

cd binutils
mkdir -p build
cd build
../configure \
    --target="$target" \
    --program-prefix="$target-" \
    --prefix="$dist_dir" \
    --with-libexpat-type=static \
    --with-gmp=$static_libs_dir \
    --with-mpfr=$static_libs_dir
make -j "$(nproc)"
make -C gas check
make install
