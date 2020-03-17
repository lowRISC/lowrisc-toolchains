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
git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain
git checkout --force $RISCV_GNU_TOOLCHAIN_COMMIT_ID

# Build ELF Multilib
./configure --prefix=/tools/riscv/elf \
    --enable-multilib
make -j$(( `nproc` * 2 ))

# Cleanup between builds
make clean
git clean -fdx

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
