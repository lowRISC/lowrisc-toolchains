lowRISC Toolchain Builds
========================

This repository contains toolchain builds and tools to create toolchains for lowRISC internal and partner use.
The toolchains are *not supported* by lowRISC or recommended to be used outside of lowRISC and partners.

Head over to the
[GitHub releases for this repository](https://github.com/lowRISC/lowrisc-toolchains/releases)
for pre-built toolchains.

The following toolchains are provided:

* Binutils + Clang RV32IMCB without hardfloat support, targeting [Ibex](https://github.com/lowRISC/ibex).
* Binutils + Clang RV64IMAC, targeting [Muntjac](https://github.com/lowRISC/muntjac).

Creating a Release
------------------

1. Push the changes or do a pull request, and wait for the CI workflow to
   complete.

   The build can be tested by downloading the GitHub artifacts.
     1. Go to the [Github Actions page](https://github.com/lowRISC/lowrisc-toolchains/actions).
     2. Select a workflow run from the list.
     3. Download the desired artifact from the bottom of the page and test it.

2. Tag the release.

   ```sh
   VERSION=$(date +%Y%m%d)-1
   git tag -a -m "Release version $VERSION" $VERSION
   ```

3. Push the tag.

   ```sh
   git push origin $VERSION
   ```

   Now the release builds on GitHub's CI, and the resulting binaries will be uploaded to
   [GitHub releases](https://github.com/lowRISC/lowrisc-toolchains/releases).


Manual Installation
-------------------

1. Download a release archive matching your host architecture and target system from the
   [Github releases](https://github.com/lowRISC/lowrisc-toolchains/releases).

2. Extract the archive:

   ```sh
   xzcat <path to the downloaded archive> | tar -xvf -
   ```

3. You should now be able to use the toolchain. You may optionally add the `bin` subfolder
   to your `PATH` to use the binaries from anywhere.

Opentitan Bazel Integration
---------------------------

The Ibex toolchain artifacts are consumed by Bazel for building Opentitan software.
For development and testing purposes, you may override the toolchain used with a local build
instead of a released version.

In the following steps, `OPENTITAN` denotes the path to your Opentitan checkout, and
`TOOLCHAIN` denotes the path to the toolchain you wish to override with
(if you have a locally built toolchain, this should be the `dist` folder).

1. Create an empty `REPO.bazel` file in the toolchain folder.

   ```sh
   touch $TOOLCHAIN/REPO.bazel
   ```

2. Create a symbolic link called `BUILD` in the toolchain folder, pointing to the toolchain's
   build file in the Opentitan checkout.

   ```sh
   ln -s $OPENTITAN/third_party/lowrisc/BUILD.lowrisc_rv32imcb_toolchain.bazel $TOOLCHAIN/BUILD
   ```

3. Override the repository in your Bazel commands.

   ```sh
   bazel --override_repository=+lowrisc_rv32imcb_toolchain+lowrisc_rv32imcb_toolchain=$TOOLCHAIN ...
   ```

   Repeatedly specifying the flag can be tedious, so to override the repository by default for all
   commands, create a `.bazelrc-site` file in your Opentitan checkout containing the following:

   ```
   common --override_repository=+lowrisc_rv32imcb_toolchain+lowrisc_rv32imcb_toolchain=<path to your toolchain>
   ```
