#!/usr/bin/env sh

set -ex

./build-binutils.sh "riscv32-unknown-elf"

./build-clang-with-args.sh \
  "lowrisc-toolchain-rv32imcb" \
  "Release" \
  "riscv32-unknown-elf" \
  "rv32imc_zba_zbb_zbc_zbs" \
  "ilp32" \
  "medany"

./create-prefixed-archive.sh \
  "lowrisc-toolchain-rv32imcb" \
  "build/"
