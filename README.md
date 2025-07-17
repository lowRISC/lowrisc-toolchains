lowRISC toolchain builds
========================

This repository contains tools to create toolchains for lowRISC internal
use. The toolchains are *not supported* by lowRISC or recommended to be
used outside of lowRISC.

Head over to the
[GitHub releases for this repository](https://github.com/lowRISC/lowrisc-toolchains/releases)
for pre-built toolchains.

* Clang RV32IMCB without hardfloat support, targeting [Ibex](https://github.com/lowRISC/ibex/)
* Clang RV64IMAC, targeting [Muntjac](https://github.com/lowRISC/muntjac)

How to do a release
-------------------

1. Push the changes or do a pull request, and wait for the CI workflow to
   complete.

   The build can be tested by downloading the GitHub artifacts.
     1. Go to the [lowrisc-toolchains Actions page](https://github.com/lowRISC/lowrisc-toolchains/actions).
     2. Select a workflow run from the list.
     4. Download the desired artifact from the bottom of the page and test it.

2. Tag a release

   ```bash
   VERSION=$(date +%Y%m%d)-1
   git tag -a -m "Release version $VERSION" $VERSION
   ```

3. Push the tag

   ```bash
   git push origin $VERSION
   ```

   Now the release builds on GitHub's CI, and the resulting binaries
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
How to install pre-built toolchain
------------------------------------
1. Download a tar.gz file from release page.
2. Decompress files to ~/.local
```
  tar -xf  <location of your tar.gz> --strip-components=1 -C ~/.local
```
3. Now you should be able to compile software with lowrisc-toolchain.
