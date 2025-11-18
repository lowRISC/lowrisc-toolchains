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

# Binutils 2.44 release
# We will apply an unratified bitmanip patch to it
export BINUTILS_URL=https://sourceware.org/git/binutils-gdb.git
export BINUTILS_BRANCH=binutils-2_44
export BINUTILS_COMMIT=815d9a14cbbb3b81843f7566222c87fb22e7255d
