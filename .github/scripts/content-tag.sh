#!/usr/bin/env bash
# Prints the content-hash image tag for a build context.
#   usage: content-tag.sh <context-dir> [rev]
# The tag is the git tree hash of the directory plus the architecture, so it changes only when the files the image is
# built from change, or the architecture does. Unchanged services keep their tag across commits, which lets a deploy resolve
# every service to an image that already exists. The architecture is in the tag so an image built for another one (the
# amd64 images that carry the plain `content-<hash>` tags) is never mistaken for this one and reused.
set -euo pipefail

context="${1:?usage: content-tag.sh <context-dir> [rev]}"
rev="${2:-HEAD}"

tree="$(git rev-parse "$rev:${context%/}")"
echo "content-${tree:0:12}-arm64"
