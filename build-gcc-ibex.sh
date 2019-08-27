#!/bin/bash

set -e
set -x

TOP=$PWD

TAG_NAME="$(git -C $TOP describe --always)"
echo "##vso[task.setvariable variable=ReleaseTag]$TAG_NAME"

TOOLCHAIN_NAME=lowrisc-toolchain-gcc-rv32imc-$TAG_NAME

mkdir -p build/gcc
cd build/gcc
git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain
git checkout $RISCV_GNU_TOOLCHAIN_COMMIT_ID
./configure --prefix=/tools/riscv \
    --with-abi=ilp32 \
    --with-arch=rv32imc \
    --with-cmodel=medany 2>&1 | tee --append $ARTIFACT_STAGING_DIR/$TOOLCHAIN_NAME.log
make -j$(nproc) 2>&1 | tee --append $ARTIFACT_STAGING_DIR/$TOOLCHAIN_NAME.log
# Includes make install

echo 'Version:' >> /tools/riscv/buildinfo
git -C $TOP describe --always >> /tools/riscv/buildinfo
echo >> /tools/riscv/buildinfo

echo 'Version of https://github.com/riscv/riscv-gnu-toolchain:' >> /tools/riscv/buildinfo
git -C $TOP/build/gcc/riscv-gnu-toolchain describe --always >> /tools/riscv/buildinfo
echo >> /tools/riscv/buildinfo

echo 'GCC version:' >> /tools/riscv/buildinfo
/tools/riscv/bin/riscv32-unknown-elf-gcc --version | head -n1 >> /tools/riscv/buildinfo
echo >> /tools/riscv/buildinfo

echo "Built at $(date -u) on $(hostname)" >> /tools/riscv/buildinfo
echo >> /tools/riscv/buildinfo

tar -cJ \
  --directory=/tools \
  -f $ARTIFACT_STAGING_DIR/$TOOLCHAIN_NAME.tar.xz \
  --transform="s@riscv@$TOOLCHAIN_NAME@" \
  --owner=0 --group=0 \
  riscv
