lowRISC toolchain builds
========================

This repository contains tools to create toolchains for lowRISC internal use.
The toolchains are *not supported* by lowRISC or recommended to be used outside of lowRISC.

Head over to the GitHub releases for this repository for pre-built toolchains.

How to do a release
-------------------

1. Modify `RISCV_GNU_TOOLCHAIN_COMMIT_ID` in `azure-pipelines.yml` and
   other build scripts and flags as needed.

2. Tag a release

  ```bash
  VERSION=$(date +%Y%m%d)-1
  git tag -a -m "Release version $VERSION" $VERSION
  ```

3. Push the tag

  ```bash
  git push origin $VERSION
  ```

Now the release builds on Azure Pipelines, and the resulting binaries
will be uploaded to
[GitHub releases](https://github.com/lowRISC/lowrisc-toolchains/releases).
