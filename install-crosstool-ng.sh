#!/bin/bash
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

build_top_dir="${PWD}"

# For *_VERSION variables
# shellcheck source=sw-versions.sh
. "${build_top_dir}/sw-versions.sh"

mkdir -p build && cd build || exit 1
git clone https://github.com/lowRISC/crosstool-ng || exit 1
cd crosstool-ng || exit 1
git checkout --force "${CROSSTOOL_NG_VERSION}" || exit 1
./bootstrap || exit 1
./configure --prefix=/usr/local && make && sudo make install
