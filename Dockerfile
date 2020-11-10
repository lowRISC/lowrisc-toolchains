# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

FROM phusion/holy-build-box-64:latest

# Build Dependencies. We'd do this later, but `holy-build-box-64` is missing
# sudo and nodejs
RUN yum install -y sudo nodejs shadow-utils \
      bison flex texinfo help2man gawk gettext wget curl \
      ncurses-devel ncurses-static glib2-devel glib2-static libfdt-devel \
      pixman-devel

LABEL "com.azure.dev.pipelines.agent.handler.node.path"="/usr/bin/node"

# We might as well install crosstool-ng in the image now too.
ADD install-crosstool-ng.sh sw-versions.sh ./
RUN bash ./install-crosstool-ng.sh && \
  rm -f ./install-crosstool-ng.sh sw-versions.sh
