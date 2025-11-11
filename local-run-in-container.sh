#!/bin/bash
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

IMAGE=quay.io/pypa/manylinux_2_28_x86_64

exec docker run -t -i \
  -v $(pwd):/home/dev/src \
  --env DEV_UID=$(id -u) --env DEV_GID=$(id -g) \
  "${IMAGE}" \
  "$@"
