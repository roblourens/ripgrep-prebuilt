#!/bin/bash
# Adapted from https://github.com/BurntSushi/ripgrep/blob/master/ci/before_deploy.sh

# package the build artifacts

set -ex

. "$(dirname $0)/utils.sh"

# Generate artifacts for release
mk_artifacts() {
    CARGO="$(builder)"
    if is_arm; then
        "$CARGO" build --target "$TARGET" --release
    else
        # Technically, MUSL builds will force PCRE2 to get statically compiled,
        # but we also want PCRE2 statically build for macOS binaries.
        PCRE2_SYS_STATIC=1 "$CARGO" build --target "$TARGET" --release --features 'pcre2'
    fi
}

mk_tarball() {
    pushd ..
    this_tag=`git tag -l --contains HEAD`
    if [ -z $this_tag ]; then
        this_tag='test'
    fi
    popd

    # When cross-compiling, use the right `strip` tool on the binary.
    local gcc_prefix="$(gcc_prefix)"

    local name="ripgrep-${this_tag}-${TARGET}"

    # Copy the ripgrep binary and strip it.
    "${gcc_prefix}strip" "target/$TARGET/release/rg"

    tar czf "target/$TARGET/release/rg" "$OUT_DIR/$name.tar.gz" "$name"
}

main() {
    mk_artifacts
    mk_tarball
}

main