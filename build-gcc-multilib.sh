#!/bin/bash

set -e
set -x
set -o pipefail

TOP=$PWD

TAG_NAME="$(git -C $TOP describe --always)"
echo "##vso[task.setvariable variable=ReleaseTag]$TAG_NAME"

TOOLCHAIN_NAME=lowrisc-toolchain-gcc-multilib-$TAG_NAME

mkdir -p build/gcc
cd build/gcc

# Checkout riscv-gnu-toolchain
git clone https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain
git checkout --force $RISCV_GNU_TOOLCHAIN_COMMIT_ID

# Try a shallow update.
git config -f .gitmodules --type=bool submodule.riscv-binutils.shallow true
git config -f .gitmodules --type=bool submodule.riscv-gcc.shallow true
git config -f .gitmodules --type=bool submodule.riscv-glibc.shallow true
git config -f .gitmodules --type=bool submodule.riscv-dejagnu.shallow true
git config -f .gitmodules --type=bool submodule.riscv-newlib.shallow true
git config -f .gitmodules --type=bool submodule.riscv-gdb.shallow true
# This is explicitly disabled, as a shallow update breaks qemu
#   git config -f .gitmodules --type=bool submodule.qemu.shallow true

# Updated Gitmodules configuration
cat .gitmodules

git submodule update --init --recursive --recommend-shallow


# Build ELF Multilib
./configure --prefix=/tools/riscv/elf \
    --enable-multilib
make -j$(( `nproc` * 2 ))

# Cleanup between builds
make clean
git clean -fdx
git submodule foreach --recursive git clean -fdx

# Build Linux Multilib
./configure --prefix=/tools/riscv/linux \
    --enable-multilib
make -j$(( `nproc` * 2 )) linux build-qemu

# Collect Build info
echo -n 'lowRISC toolchain version: ' >> /tools/riscv/buildinfo
git -C $TOP describe --always >> /tools/riscv/buildinfo

echo -n 'Version of https://github.com/riscv/riscv-gnu-toolchain:' >> /tools/riscv/buildinfo
git -C $TOP/build/gcc/riscv-gnu-toolchain describe --always >> /tools/riscv/buildinfo

echo -n 'GCC version: ' >> /tools/riscv/buildinfo
/tools/riscv/elf/bin/riscv64-unknown-elf-gcc --version | head -n1 >> /tools/riscv/buildinfo

echo "Built at $(date -u) on $(hostname)" >> /tools/riscv/buildinfo

# Create archive
tar -cJ \
  --directory=/tools \
  -f $ARTIFACT_STAGING_DIR/$TOOLCHAIN_NAME.tar.xz \
  --transform="s@riscv@$TOOLCHAIN_NAME@" \
  --owner=0 --group=0 \
  riscv
