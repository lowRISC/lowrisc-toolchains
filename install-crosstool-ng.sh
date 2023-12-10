#!/bin/bash
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

build_top_dir="${PWD}"

set -e

# For *_VERSION variables
# shellcheck source=sw-versions.sh
. "${build_top_dir}/sw-versions.sh"

mkdir -p "${build_top_dir}/build"

rm -rf "${build_top_dir}/build/crosstool-ng"
git clone "${CROSSTOOL_NG_URL}" "${build_top_dir}/build/crosstool-ng"
cd "${build_top_dir}/build/crosstool-ng"
git checkout --force "${CROSSTOOL_NG_VERSION}"

./bootstrap

./configure --prefix=/usr/local && make && sudo make install
