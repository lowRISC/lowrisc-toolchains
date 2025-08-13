#!/usr/bin/env sh

set -ex

./build-binutils.sh "riscv32-unknown-elf"

./build-clang-with-args.sh \
  --name "lowrisc-toolchain-rv32imcb" \
  --target "riscv32-unknown-elf" \
  --march "rv32imc_zba_zbb_zbc_zbs" \
  --mabi "ilp32" \
  --mcmodel "medany" \
  "$@"

./create-prefixed-archive.sh \
  "lowrisc-toolchain-rv32imcb" \
  "build/"
