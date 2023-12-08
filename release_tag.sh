#!/usr/bin/env bash

# Determine the release tag from Git based on the type of release being made.

set -e
set -x

# Fetch all tags in case they didn't come with the checkout.
git fetch --tags

# git-describe --always almost does what we want, but we need to connect the
# ReleaseTag variable contents to how this build was triggered, which we
# will find out using `Build.SourceBranch` (a pipeline varaible).
#
# Importantly, a few things are going on here:
# - If we were triggered by a tag, we need to output exactly the tag name,
#   so that the artifacts are named correctly. If we cannot do this, the
#   build needs to fail rather than uploading artifacts to some other
#   random tag.
# - If we were triggered by a branch build, we need to be more careful, as
#   tagged commits are also pushed to branches. Branch builds explicitly use
#   the longer format so that if the built commit matches a tag, the
#   ReleaseTag is not a tag name.
if [[ "$GITHUB_REF_TYPE" == tag ]]; then
  # Tag Build: Always use '<TAG>' format; Error if tag not found.
  git describe --exact-match
else
  # Branch Build: Always use '<TAG>-<N>-<SHA>' format.
  git describe --long
fi
