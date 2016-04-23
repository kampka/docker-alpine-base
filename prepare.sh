#!/bin/bash

set -e
set -u

error_exit(){
  echo "$@" 1>&2
  exit 1
}


CURRENT_DIR="$(realpath $(dirname $0))"
KEY_DIR="${CURRENT_DIR}/keys"
BUILD_DIR="$(mktemp -d -p $CURRENT_DIR alpine-XXXXXXXX)"

VERBOSIRY="-q"

ALPINE_RELEASE="${ALPINE_RELEASE:-latest-stable}"
ALPINE_MIRROR="${ALPINE_MIRROR:-http://nl.alpinelinux.org}"
ALPINE_ARCH="x86_64"

[ -e "$CURRENT_DIR/ALPINE_RELEASE" ] && ALPINE_RELEASE="$(cat $CURRENT_DIR/ALPINE_RELEASE)"

usage() {

  echo "$0: Prepare a basic alpine linux tarball"
  echo ""
  echo "Options:"
  echo "  --alpine-release <release-version>       : The alpine release version the tarball is based on. (default: ${ALPINE_RELEASE})"
  echo "  --alpine-mirror <mirror-url>             : The base url of the alpine mirror to use. (default: ${ALPINE_MIRROR})"
  echo "  --arch <architecture>                    : The release architecture. (default: ${ALPINE_ARCH})"
  echo "  --verbose                                : Be more verbose."
  echo "  --help                                   : Print this message and exit."

}

while [ $# -gt 0 ]; do
  case $1 in
    --alpine-release)
      shift
      [ -n "$1" ] || error_exit "No alpine release version given."
      case $1 in
        -*)
          error_exit "Not a valid alpine version: $1"
          ;;
        *)
          ALPINE_RELEASE="$1"
          ;;
        esac
      ;;
    --alpine-mirror)
      shift
      [ -n "$1" ] || error_exit "No alpine mirror given."
      case $1 in
        -*)
          error_exit "Not a valid alpine mirror: $1"
          ;;
        *)
          ALPINE_MIRROR="$1"
          ;;
        esac
      ;;
    --verbose)
      VERBOSIRY="-v"
      ;;
    --arch)
    shift
      [ -n "$1" ] || error_exit "No alpine architecture given."
      case $1 in
        -*)
          error_exit "Not a valid alpine architecture: $1"
          ;;
        *)
          ALPINE_ARCH="$1"
          ;;
        esac
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown parameter $1" 1>&2
      usage
      exit 1
      ;;
  esac
  shift
done

CMD_PREFIX=""
[ "$(id -u)" -ne 0 ] && CMD_PREFIX="sudo"

trap "$CMD_PREFIX rm -rf $BUILD_DIR" EXIT

cd "$BUILD_DIR"
echo "Preparing static apk-tools"
curl -sss -f -L -O "$ALPINE_MIRROR/alpine/$ALPINE_RELEASE/main/$ALPINE_ARCH/APKINDEX.tar.gz" || error_exit "Failed to download alpine APKINDEX for release $ALPINE_RELEASE on $ALPINE_ARCH"
tar xvzf  APKINDEX.tar.gz 1>/dev/null || error_exit "Failed to extract APKINDEX."

APK_TOOLS_VERSION="$(cat APKINDEX | sed -n '/apk-tools-static/,/^$/p' | grep '^V:' | cut -d':' -f 2)"

curl -sss -f -L -O "$ALPINE_MIRROR/alpine/$ALPINE_RELEASE/main/$ALPINE_ARCH/apk-tools-static-$APK_TOOLS_VERSION.apk" || error_exit "Failed to download apk-tools-static $APK_TOOLS_VERSION"
tar xvzf "apk-tools-static-$APK_TOOLS_VERSION.apk" 1>/dev/null || error_exit "Failed to extract apk-tools-static from apk-tools-static-$APK_TOOLS_VERSION.apk"

APK_TOOLS_STATIC="$BUILD_DIR/sbin/apk.static"


SHA_SIGNATIRE_FILE="$(find ${BUILD_DIR}/sbin -type f -name apk.static.SIGN.RSA.*.rsa.pub)"
KEY_ID="$(echo $SHA_SIGNATIRE_FILE | grep -E -o '([0-9a-zA-Z]{8}).rsa.pub' | cut -d'.' -f 1 )"

KEY_FILE="$(find ${KEY_DIR} -type f -name *${KEY_ID}.rsa.pub)"

[ -n "${KEY_FILE}" ] || error_exit "No known public key found for ID $KEY_ID."

openssl dgst -sha1 -verify "$KEY_FILE" -signature $SHA_SIGNATIRE_FILE "$APK_TOOLS_STATIC" || error_exit "Failed to verify apk.static signature"

[ -x "$APK_TOOLS_STATIC" ] || error_exit "No executable apk.static found at $APK_TOOLS_STATIC."

echo "Preparing alpine root directory"

ALPINE_ROOT_DIR="$BUILD_DIR/root"
mkdir -p "$ALPINE_ROOT_DIR" || error_exit "Cannot create alpine root dir at $ALPINE_ROOT_DIR"

$CMD_PREFIX $APK_TOOLS_STATIC -X "$ALPINE_MIRROR/alpine/${ALPINE_RELEASE}/main" -U --keys-dir="$CURRENT_DIR/keys" --root "$ALPINE_ROOT_DIR" --initdb add busybox apk-tools alpine-keys alpine-baselayout || error_exit "Failed preparing alpine root filesystem."

$CMD_PREFIX sh -c "echo $ALPINE_MIRROR/alpine/${ALPINE_RELEASE}/main > $ALPINE_ROOT_DIR/etc/apk/repositories"
$CMD_PREFIX sh -c "rm -rf $ALPINE_ROOT_DIR/var/cache/apk/*"


echo "Create alpine root tarball"
cd "$ALPINE_ROOT_DIR"

$CMD_PREFIX tar cvJf "$CURRENT_DIR/alpine-base.tar.xz" *
