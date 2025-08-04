#!/bin/bash

# This documents the versions of any software checked out from git

# LLVM 16.0.2 plus:
# - hardening patches
# - unratified bitmanip extensions
# - `.option arch` assembly directive
# - single-byte code coverage
export LLVM_URL=https://github.com/lowRISC/llvm-project.git
export LLVM_BRANCH=ot-llvm-16-hardening
export LLVM_VERSION=dec908d48facb6041c12b95b8ade64719a894917

# RISC-V fork of Binutils 2.35 with bitmanip instruction support
export BINUTILS_URL=https://github.com/riscv-collab/riscv-binutils-gdb.git
export BINUTILS_BRANCH=riscv-binutils-2.35-rvb
export BINUTILS_COMMIT=7c9dd840fbb6a1171a51feb08afb859288615137
