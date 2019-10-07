#!/bin/bash

set -e
set -x
set -o pipefail

TOP=$PWD

TAG_NAME="$(git -C $TOP describe --always)"
echo "##vso[task.setvariable variable=ReleaseTag]$TAG_NAME"

TOOLCHAIN_NAME=lowrisc-toolchain-gcc-rv32imc-$TAG_NAME

# XXX: This will create a toolchain in /tools/riscv/riscv32-unknown-elf
# We curently use /tools/riscv directly, which is set through CT_PREFIX_DIR in
# the config file. If we decide to go for a triple-specific toolchain subdir,
# we can go back to using this setting here, and remove CT_PREFIX_DIR from the
# config.
#export CT_PREFIX=/tools/riscv

mkdir -p build/gcc
cd build/gcc
cp ../../lowrisc-toolchain-gcc-rv32imc.config .config
ct-ng upgradeconfig
cat .config
ct-ng build

ls -l /tools/riscv

echo 'Version:' >> /tools/riscv/buildinfo
git -C $TOP describe --always >> /tools/riscv/buildinfo
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
