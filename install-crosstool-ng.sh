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

# Explicitly include libtinfo in the ncurses linker options since it seems to be
# not picked up by configure itself, leading to the following error otherwise:
#
# /usr/local/bin/libtool  --tag CC  --mode=link gcc  -g -O2   -o nconf nconf-nconf.o nconf-nconf.gui.o nconf-zconf.o -lmenuw -lpanelw -lncursesw
# libtool: link: gcc -g -O2 -o nconf nconf-nconf.o nconf-nconf.gui.o nconf-zconf.o  -lmenuw -lpanelw -lncursesw
# /opt/rh/devtoolset-8/root/usr/libexec/gcc/x86_64-redhat-linux/8/ld: nconf-nconf.o: undefined reference to symbol 'keypad'
# //lib64/libtinfo.so.5: error adding symbols: DSO missing from command line
CURSES_LIBS="-lcursesw -ltinfo" ./configure --prefix=/usr/local && make && sudo make install
