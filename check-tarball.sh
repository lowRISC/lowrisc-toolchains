#!/bin/bash
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

## check-tarball.sh
#
# Takes a tarball name and checks all symlinks resolve to an existing file. This
# has been an issue we keep running into, so CI can now check it for us!
#
# It also checks that the `buildinfo.json` in the tarball is valid JSON, which
# was an issue we ran into.

set -e
set -o pipefail

if ! [ "$#" = 1 ]; then
  echo "Usage: $0 <tarball>"
  exit 2
fi;

tarball="$1"
tarball_dest="$(mktemp -d)"

found_error=false

echo "Checking: $1"

# Extract tarball into `tarball_dest`
echo "Extracting:"
tar -x -v \
  -f "${tarball}" \
  --strip-components=1 \
  -C "${tarball_dest}"

broken_symlinks="$(mktemp)"

# Check for broken symlinks
echo "Checking symlinks"
find "${tarball_dest}" -type l \
  -exec test ! -e '{}' \; \
  -print | tee "${broken_symlinks}"

if [ -s "${broken_symlinks}" ]; then
  echo "ERROR: Broken Symlinks Found"
  found_error=true
fi

echo "Checking buidinfo.json"
if ! python3 -mjson.tool "${tarball_dest}/buildinfo.json"; then
  echo "ERROR: buildinfo.json not valid json"
  found_error=true
fi

# Check binaries to ensure that they are only linked to a very limited set of
# libraries:
#
# # Linux dynamic linker and kernel interface
# ld-linux.*
# linux-gate.so
# linux-vdso.so
#
# # glibc
# libc.so
# libm.so
# libpthread.so
# librt.so
# libdl.so
# libcrypt.so  (NOT libcrypto.so!)
# libutil.so
# libnsl.so
# libresolv.so

# # GCC runtime
# libgcc_s.so
#
# See
# https://github.com/phusion/holy-build-box/blob/master/ESSENTIAL-SYSTEM-LIBRARIES.md
# for details.

# Clang links against the following libraries, which must be present at
# runtime:
# - libz.so.1 (zlib)
# - libncursesw.so.5 and libtinfo.so.5 (ncurses5)
# - libstdc++.so.6
export LIBCHECK_ALLOW='libstdc\+\+|libtinfo|libncursesw|libz'

libcheck_output="$(mktemp)"

echo "Checking ELF Binaries for Library Usage"
find "${tarball_dest}/bin" \
  -exec sh -c 'file "$1" | grep -qi ": elf"' _ {} \; \
  -exec python3 libcheck.py {} \; | tee "${libcheck_output}"
if grep "is linked to non-system libraries" "${libcheck_output}"; then
  echo "ERROR: Toolchain Executable Linked to non-system library."
  found_error=true
fi

if [ "${found_error}" = "true" ]; then
  echo "FAIL! Problems found, see errors above."
  exit 1
else
  echo "PASS! No problems found."
  exit 0
fi
