#!/bin/bash
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

set -e
set -x

# Repository for the `gh` GitHub CLI tool used for creating releases.
dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo

# Repository for expat-static
dnf install -y almalinux-release-devel

dnf install -y \
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
  pixman-devel \
  python36 \
  zlib-devel \
  zlib-static \
  libffi-devel \
  expat-static \
  lld
