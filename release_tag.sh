#!/usr/bin/env bash

# Determine the release tag from Git based on the type of release being made.

set -e
set -x

# git-describe --always almost does what we want, but we need to connect the
# `RELEASE_TAG` variable contents to how this build was triggered, which we
# will find out using `$GITHUB_REF_TYPE` (a GitHub Actions variable).
#
# Importantly, a few things are going on here:
# - If we were triggered by a tag, we need to output exactly the tag name,
#   so that the artifacts are named correctly. If we cannot do this, the
#   build needs to fail rather than uploading artifacts to some other
#   random tag.
# - If we were triggered by a branch build, we need to be more careful, as
#   tagged commits are also pushed to branches. Branch builds explicitly use
#   the longer format so that if the built commit matches a tag, the
#   `RELEASE_TAG` is not a tag name.
if [[ "$GITHUB_REF_TYPE" == tag ]]; then
  echo "$GITHUB_REF_NAME"
else
  # Branch Build: Always use '<TAG>-<N>-<SHA>' format.
  git describe --long
fi
