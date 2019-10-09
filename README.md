lowRISC toolchain builds
========================

This repository contains tools to create toolchains for lowRISC internal
use. The toolchains are *not supported* by lowRISC or recommended to be
used outside of lowRISC.

Head over to the
[GitHub releases for this repository](https://github.com/lowRISC/lowrisc-toolchains/releases)
for pre-built toolchains.

* A GCC RV32IMC without hardfloat support, targeting [Ibex](https://github.com/lowRISC/ibex/)
* A GCC multilib toolchain

How to do a release
-------------------

1. Modify `RISCV_GNU_TOOLCHAIN_COMMIT_ID` in `azure-pipelines.yml` and
   other build scripts and flags as needed.

2. Push the changes or do a pull request, and wait for the pipeline to
   complete.

   The build can be tested by downloading the Azure Pipeline artifacts.
     1. Go to the [lowrisc-toolchains Azure Pipelines page](https://dev.azure.com/lowrisc/lowrisc-toolchains/_build?definitionId=2&_a=summary)
     2. Select a build
     3. Click on "Artifacts" (top right)
     4. Download the desired artifact, and test it.

3. Tag a release

   ```bash
   VERSION=$(date +%Y%m%d)-1
   git tag -a -m "Release version $VERSION" $VERSION
   ```

4. Push the tag

   ```bash
   git push origin $VERSION
   ```

   Now the release builds on Azure Pipelines, and the resulting binaries
   will be uploaded to
   [GitHub releases](https://github.com/lowRISC/lowrisc-toolchains/releases).
