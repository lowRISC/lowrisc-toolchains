# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

FROM phusion/holy-build-box-64:latest

# Build Dependencies. We'd do this later, but `holy-build-box-64` is missing
# sudo
RUN yum install -y sudo shadow-utils \
      bison flex texinfo help2man gawk gettext wget curl xz \
      ncurses-devel ncurses-static glib2-devel glib2-static libfdt-devel \
      pixman-devel
