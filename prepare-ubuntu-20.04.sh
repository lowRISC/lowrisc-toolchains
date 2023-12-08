#!/bin/bash
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

set -e
set -x

# Install prerequisite packages.
#
# Notes:
# - liblzma-dev is removed to prevent it being dynamically linked to GDB.
# - libxml2-dev is removed to prevent it being dynamically linked to LD.
sudo apt install -y \
  bison \
  curl \
  flex \
  gawk \
  gettext \
  git \
  help2man \
  libffi-dev \
  libncurses-dev \
  libpixman-1-dev \
  libtool-bin \
  texinfo \
  xz-utils \
  zlib1g \
  zlib1g-dev

sudo apt remove -y \
  liblzma-dev \
  libxml2-dev
