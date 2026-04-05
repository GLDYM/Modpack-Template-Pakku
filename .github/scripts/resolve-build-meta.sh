#!/usr/bin/env bash
set -euo pipefail

PACK_NAME="$(sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' pakku.json | head -n 1)"
if [[ -z "$PACK_NAME" ]]; then
  PACK_NAME="modpack"
fi

PACK_VERSION="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' pakku.json | head -n 1)"
if [[ -z "$PACK_VERSION" ]]; then
  PACK_VERSION="0.0.0"
fi

PACK_NAME_SLUG="$(echo "$PACK_NAME" | sed 's/[[:space:]]//g; s/[^A-Za-z0-9._-]/-/g; s/-\{2,\}/-/g; s/^-//; s/-$//')"
if [[ -z "$PACK_NAME_SLUG" ]]; then
  PACK_NAME_SLUG="modpack"
fi

PAKKU_URL="$(sed -n 's/.*"pakku_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' installer/install-config.json | head -n 1)"
if [[ -z "$PAKKU_URL" ]]; then
  PAKKU_URL="https://github.com/juraj-hrivnak/Pakku/releases/download/v1.3.2/pakku.jar"
fi

lock_json="$(tr -d '\r\n' < pakku-lock.json)"
MC_VERSION="$(echo "$lock_json" | sed -n 's/.*"mc_versions"[[:space:]]*:[[:space:]]*\[[[:space:]]*"\([^"]*\)".*/\1/p')"
if [[ -z "$MC_VERSION" ]]; then
  MC_VERSION="1.20.1"
fi

mc_major="$(echo "$MC_VERSION" | awk -F. '{print $1}')"
mc_minor="$(echo "$MC_VERSION" | awk -F. '{print $2}')"
mc_patch="$(echo "$MC_VERSION" | awk -F. '{print $3}')"

if [[ -z "$mc_minor" ]]; then
  mc_minor="0"
fi

if [[ -z "$mc_patch" ]]; then
  mc_patch="0"
fi

# Legacy naming: 1.x.y
# Modern naming: x.y.z (major starts from 26)
JAVA_VERSION="21"
if (( mc_major == 1 )); then
  if (( mc_minor >= 21 )); then
    JAVA_VERSION="21"
  elif (( mc_minor == 20 && mc_patch >= 5 )); then
    JAVA_VERSION="21"
  elif (( mc_minor >= 18 )); then
    JAVA_VERSION="17"
  elif (( mc_minor == 17 )); then
    JAVA_VERSION="16"
  else
    JAVA_VERSION="8"
  fi
elif (( mc_major >= 26 )); then
  JAVA_VERSION="25"
fi

CLIENT_ZIP="${PACK_NAME_SLUG}-build.zip"
SERVER_ZIP="Server-${PACK_NAME_SLUG}-build.zip"
FULL_SERVER_ZIP="Full-Server-${PACK_NAME_SLUG}-build.zip"
RELEASE_TAG="v${PACK_VERSION}"
CLIENT_RELEASE_ZIP="${PACK_NAME_SLUG}-${PACK_VERSION}.zip"
SERVER_RELEASE_ZIP="Server-${PACK_NAME_SLUG}-${PACK_VERSION}.zip"
FULL_SERVER_RELEASE_ZIP="Full-Server-${PACK_NAME_SLUG}-${PACK_VERSION}.zip"
CHANGELOG_FILE="CHANGELOG-${PACK_VERSION}.md"

if [[ -z "${GITHUB_OUTPUT:-}" ]]; then
  echo "GITHUB_OUTPUT is not set"
  exit 1
fi

{
  echo "pack_name=$PACK_NAME"
  echo "pack_version=$PACK_VERSION"
  echo "pack_name_slug=$PACK_NAME_SLUG"
  echo "pakku_url=$PAKKU_URL"
  echo "mc_version=$MC_VERSION"
  echo "java_version=$JAVA_VERSION"
  echo "client_zip=$CLIENT_ZIP"
  echo "server_zip=$SERVER_ZIP"
  echo "full_server_zip=$FULL_SERVER_ZIP"
  echo "release_tag=$RELEASE_TAG"
  echo "client_release_zip=$CLIENT_RELEASE_ZIP"
  echo "server_release_zip=$SERVER_RELEASE_ZIP"
  echo "full_server_release_zip=$FULL_SERVER_RELEASE_ZIP"
  echo "changelog_file=$CHANGELOG_FILE"
} >> "$GITHUB_OUTPUT"
