#!/bin/bash

# This documents the versions of any software checked out from git

# master 2021-12-08
export CROSSTOOL_NG_URL=https://github.com/crosstool-ng/crosstool-ng.git
export CROSSTOOL_NG_VERSION=5075e1f98e4329502682746cc30fa5c0c5a19d26

# v4.0.1
export QEMU_VERSION=23967e5b2a6c6d04b8db766a8a149f3631a7b899

# LLVM 16.0.2 plus:
# - hardening patches
# - unratified bitmanip extensions
# - `.option arch` assembly directive
export LLVM_URL=https://github.com/lowRISC/llvm-project.git
export LLVM_BRANCH=ot-llvm-16-hardening
export LLVM_VERSION=f42b43e5262eae10a0c7d208423b4947e539f8f9
