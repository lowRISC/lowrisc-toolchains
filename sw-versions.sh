#!/bin/bash

# This documents the versions of any software checked out from git

# crosstool-ng-1.26.0-rc1
export CROSSTOOL_NG_URL=https://github.com/crosstool-ng/crosstool-ng.git
export CROSSTOOL_NG_VERSION=5a09578b6798f426b62d97b2ece1ba5e7b82990b

# v4.0.1
export QEMU_VERSION=23967e5b2a6c6d04b8db766a8a149f3631a7b899

# LLVM 16.0.2 plus:
# - hardening patches
# - unratified bitmanip extensions
# - `.option arch` assembly directive
export LLVM_URL=https://github.com/lowRISC/llvm-project.git
export LLVM_BRANCH=ot-llvm-16-hardening
export LLVM_VERSION=2e46e90331297be7788c355a0e1eb6b6b8e823c1
