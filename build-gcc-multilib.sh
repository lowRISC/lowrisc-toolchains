#!/bin/bash

set -e
set -x

TOP=$PWD

TOOLCHAIN_NAME=lowrisc-toolchain-gcc-multilib-$(git -C $TOP describe --always)

mkdir -p build/gcc
cd build/gcc
git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain
git checkout $RISCV_GNU_TOOLCHAIN_COMMIT_ID

# Build ELF Multilib
./configure --prefix=/tools/riscv/elf \
    --enable-multilib 2>&1 | tee --append $ARTIFACT_STAGING_DIR/$TOOLCHAIN_NAME.log
make -j$(( `nproc` * 2 )) 2>&1 | tee --append $ARTIFACT_STAGING_DIR/$TOOLCHAIN_NAME.log

make clean
# Build Linux Multilib
./configure --prefix=/tools/riscv/linux \
    --enable-multilib 2>&1 | tee --append $ARTIFACT_STAGING_DIR/$TOOLCHAIN_NAME.log
make -j$(( `nproc` * 2 )) linux 2>&1 | tee --append $ARTIFACT_STAGING_DIR/$TOOLCHAIN_NAME.log

echo 'Version:' >> /tools/riscv/buildinfo
git -C $TOP describe --always >> /tools/riscv/buildinfo
echo >> /tools/riscv/buildinfo

echo 'Version of https://github.com/riscv/riscv-gnu-toolchain:' >> /tools/riscv/buildinfo
git -C $TOP/build/gcc/riscv-gnu-toolchain describe --always >> /tools/riscv/buildinfo
echo >> /tools/riscv/buildinfo

echo 'GCC version:' >> /tools/riscv/buildinfo
/tools/riscv/elf/bin/riscv64-unknown-elf-gcc --version | head -n1 >> /tools/riscv/buildinfo
echo >> /tools/riscv/buildinfo

echo "Built at $(date -u) on $(hostname)" >> /tools/riscv/buildinfo
echo >> /tools/riscv/buildinfo

tar -cJ \
  --directory=/tools \
  -f $ARTIFACT_STAGING_DIR/$TOOLCHAIN_NAME.tar.xz \
  --transform="s@riscv@$TOOLCHAIN_NAME@" \
  --owner=0 --group=0 \
  riscv
