#!/bin/bash
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

## check-tarball-symlinks.sh
#
# Takes a tarball name and checks all symlinks resolve to an existing file. This
# has been an issue we keep running into, so CI can now check it for us!

set -e
set -x
set -o pipefail

if ! [ "$#" = 1 ]; then
  echo "Usage: $0 <tarball>"
  exit 2
fi;

tarball="$1"
tarball_dest="$(mktemp -d)"

echo "Checking: $1"

# Extract tarball into `tarball_dest`
echo "Extracting:"
tar -x -v \
  -f "${tarball}" \
  --strip-components=1 \
  -C "${tarball_dest}"

broken_symlinks="$(mktemp)"

# Check for broken symlinks
echo "Broken Symlinks:"
find "${tarball_dest}" -type l \
  -exec test ! -e '{}' \; \
  -print | tee "${broken_symlinks}"

if [ -s "${broken_symlinks}" ]; then
  echo "ERROR: Broken Symlinks Found"
  exit 1
fi
