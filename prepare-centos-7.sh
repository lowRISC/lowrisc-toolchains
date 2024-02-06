#!/bin/bash
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

set -e
set -x

# Repository for the `gh` GitHub CLI tool used for creating releases.
yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo

yum install -y \
  sudo \
  gh \
  git \
  shadow-utils \
  bison \
  flex \
  texinfo \
  help2man \
  gawk \
  gettext \
  curl \
  xz \
  ncurses-devel \
  ncurses-static \
  pixman-devel \
  rh-python36 \
  zlib-devel \
  zlib-static \
  libffi-devel
