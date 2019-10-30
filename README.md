lowRISC toolchain builds
========================

This repository contains tools to create toolchains for lowRISC internal
use. The toolchains are *not supported* by lowRISC or recommended to be
used outside of lowRISC.

Head over to the
[GitHub releases for this repository](https://github.com/lowRISC/lowrisc-toolchains/releases)
for pre-built toolchains.

* A GCC RV32IMC without hardfloat support, targeting [Ibex](https://github.com/lowRISC/ibex/)
* A GCC elf multilib toolchain
* A GCC linux multilib toolchain, with linux user-space Qemu binaries

How to do a release
-------------------

1. Modify any of the following variables to configure the build:
   - `CROSSTOOL_NG_VERSION` in `install-crosstool-ng.sh`
   - `QEMU_VERSION` in `build-gcc-with-args.sh`

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

How to generate the bitmanip patches
------------------------------------

1. Generate the binutils patch:

   ```
   git clone https://github.com/riscv/riscv-binutils-gdb.git
   cd riscv-binutils-gdb
   git checkout riscv-bitmanip
   # 612aac65 is our upstream baseline
   git diff 612aac65 > $TOP/patches/binutils/git-612aac65/001-bitmanip.patch
   ```

2. Generate the GCC patch:

   ```
   git clone https://github.com/riscv/riscv-gcc.git
   cd riscv-gcc
   git checkout riscv-bitmanip
   # 49f75e008c0 is our upstream baseline
   git diff 49f75e008c0 > $TOP/patches/gcc/git-49f75e00/001-bitmanip.patch
   ```
