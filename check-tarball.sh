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
set -x
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
if ! python -mjson.tool "${tarball_dest}/buildinfo.json"; then
  echo "ERROR: buildinfo.json not valid json"
  found_error=true
fi

if [ "${found_error}" = "true" ]; then
  exit 1
else
  exit 0
fi
