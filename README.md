lowRISC toolchain builds
========================

This repository contains tools to create toolchains for lowRISC internal
use. The toolchains are *not supported* by lowRISC or recommended to be
used outside of lowRISC.

Head over to the
[GitHub releases for this repository](https://github.com/lowRISC/lowrisc-toolchains/releases)
for pre-built toolchains.

* A GCC RV32IMC without hardfloat support, targeting [Ibex](https://github.com/lowRISC/ibex/)
* A GCC RV64IMAC, targeting [Muntjac](https://github.com/lowRISC/muntjac)
* A GCC elf multilib toolchain
* A GCC linux multilib toolchain

How to do a release
-------------------

1. Modify any of the following variables to configure the build:
   - `CROSSTOOL_NG_VERSION` in `install-crosstool-ng.sh`

2. Modify any of the `*.config` files to update the crosstool-ng configurations
   for a particular toolchain.

3. Push the changes or do a pull request, and wait for the pipeline to
   complete.

   The build can be tested by downloading the Azure Pipeline artifacts.
     1. Go to the [lowrisc-toolchains Azure Pipelines page](https://dev.azure.com/lowrisc/lowrisc-toolchains/_build?definitionId=2&_a=summary)
     2. Select a build
     3. Click on "Artifacts" (top right)
     4. Download the desired artifact, and test it.

4. Tag a release

   ```bash
   VERSION=$(date +%Y%m%d)-1
   git tag -a -m "Release version $VERSION" $VERSION
   ```

5. Push the tag

   ```bash
   git push origin $VERSION
   ```

   Now the release builds on Azure Pipelines, and the resulting binaries
   will be uploaded to
   [GitHub releases](https://github.com/lowRISC/lowrisc-toolchains/releases).

How to generate the bitmanip patch
------------------------------------

```
git clone https://github.com/riscv-collab/riscv-binutils-gdb.git
cd riscv-binutils-gdb
# checkout Pirmin's bitmanip 1.00+0.93 PR (https://github.com/riscv-collab/riscv-binutils-gdb/pull/267)
gh pr checkout 267
# 7c9dd840 (riscv-binutils-2.35-rvb) is our baseline
git diff 7c9dd840 > $TOP/patches/lowrisc-toolchain-gcc-rv32imcb/binutils/git-7c9dd840/001-bitmanip.patch
```
