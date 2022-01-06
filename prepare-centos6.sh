#!/bin/bash
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Install prerequisite packages.
#
# Notes:
# - The devtoolset-8 SCL is already installed as part of the base image and
#   provides a sufficiently new GCC version.
# - Python 2.7 or newer is required by the LLVM build system.
sudo yum install -y \
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
  rh-python35 \
  zlib-devel \
  zlib-static \
  libffi-devel

# Enable SCLs for all shell sessions.
# See https://access.redhat.com/solutions/527703
cat << EOF > /tmp/scl_enable.sh
#!/bin/bash
source scl_source enable rh-python35
EOF
sudo mv /tmp/scl_enable.sh /etc/profile.d/scl_enable.sh
