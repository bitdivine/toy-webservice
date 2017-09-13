#!/bin/sh

set -eux
set -o pipefail

INSTALL_DIR="${INSTALL_DIR:-/opt/terraform/bin}"
# Get the version to install, degrading gracefully depending on which tools are installed:
test -n "${VERSION:-}" \
    || VERSION="$(curl https://releases.hashicorp.com/index.json | jmespath "terraform.versions.*.version" --output text | sort --version-sort | tail -n1)" \
    || VERSION="$(curl https://releases.hashicorp.com/terraform/ | grep terraform_ | sed 's/.*href.*>terraform_//g;s/<.*//g' | sort --version-sort | tail -n1)"
CURRENT="$(terraform --version | awk '{print $(NF);exit}' || true)"
PLATFORM="$(uname | tr 'A-Z' 'a-z')"
ARCH="$(uname -m | sed 's/x86_64/amd64/g')"
INSTALL_FILE="$INSTALL_DIR/terraform-$VERSION-$PLATFORM-$ARCH"
INSTALL_LINK="$INSTALL_DIR/terraform"

if test "v$VERSION" != "$CURRENT"; then
    echo "Installing terraform v$VERSION ..."
    TMP_DIR="$(mktemp -d)"
    TMP_DOWNLOAD="$TMP_DIR/terraform_${VERSION}_${PLATFORM}_${ARCH}.zip"
    TMP_SIGNATURE="$TMP_DIR/terraform_${VERSION}_${PLATFORM}_${ARCH}.sig"
    TMP_UNPACKED="$TMP_DIR/unpacked"
    mkdir -p "$TMP_DIR" "$TMP_UNPACKED" "$INSTALL_DIR"
    wget -O "$TMP_DOWNLOAD"  "https://releases.hashicorp.com/terraform/$VERSION/terraform_${VERSION}_${PLATFORM}_${ARCH}.zip"
    wget -O "$TMP_SIGNATURE" "https://releases.hashicorp.com/terraform/$VERSION/terraform_${VERSION}_SHA256SUMS.sig"
    # If gpg is installed, use it to verify the download, else trust https. :-/
    ! which gpg || gpg --verify "$TMP_SIGNATURE" "$TMP_DOWNLOAD"
    unzip -d "$TMP_UNPACKED" "$TMP_DOWNLOAD"
    mv "$TMP_UNPACKED/terraform" "$INSTALL_FILE"
    rm -f "$INSTALL_LINK"
    ln -s "$INSTALL_FILE" "$INSTALL_LINK"
    rm -fr "$TMP_DIR"
    echo "Terraform installed in $INSTALL_DIR"
else
    echo "Latest stable version of terraform already installed."
fi