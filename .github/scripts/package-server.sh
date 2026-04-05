#!/usr/bin/env bash
set -euo pipefail

SERVER_ZIP_NAME="${1:-}"
FULL_SERVER_ZIP_NAME="${2:-}"

if [[ -z "$SERVER_ZIP_NAME" || -z "$FULL_SERVER_ZIP_NAME" ]]; then
  echo "Usage: $0 <server-zip-name> <full-server-zip-name>"
  exit 1
fi

if [[ ! -f "pakku-lock.json" ]]; then
  echo "pakku-lock.json not found"
  exit 1
fi

if [[ ! -f "installer/install-config.json" ]]; then
  echo "installer/install-config.json not found"
  exit 1
fi

chmod +x installer/install-server.sh
./installer/install-server.sh

zip -r "./${FULL_SERVER_ZIP_NAME}" ./server/*

cp pakku.json installer/
cp pakku-lock.json installer/
cp pakku.jar installer/
cp -r .pakku/ installer/

lock_json="$(tr -d '\r\n' < pakku-lock.json)"
config_json="$(tr -d '\r\n' < installer/install-config.json)"
mc_version="$(echo "$lock_json" | sed -n 's/.*"mc_versions"[[:space:]]*:[[:space:]]*\[[[:space:]]*"\([^"]*\)".*/\1/p')"

loader_name=""
loader_version=""
installer_file_name=""
installer_url=""

if echo "$lock_json" | grep -q '"neoforge"[[:space:]]*:'; then
  loader_name="neoforge"
  loader_version="$(echo "$lock_json" | sed -n 's/.*"neoforge"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  installer_file_name="neoforge-${loader_version}-installer.jar"
  template="$(echo "$config_json" | sed -n 's/.*"neoforge_installer_url_template"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  installer_url="${template//\{loader_version\}/$loader_version}"
elif echo "$lock_json" | grep -q '"forge"[[:space:]]*:'; then
  loader_name="forge"
  loader_version="$(echo "$lock_json" | sed -n 's/.*"forge"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  installer_file_name="forge-${mc_version}-${loader_version}-installer.jar"
  template="$(echo "$config_json" | sed -n 's/.*"forge_installer_url_template"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  installer_url="${template//\{mc_version\}/$mc_version}"
  installer_url="${installer_url//\{loader_version\}/$loader_version}"
elif echo "$lock_json" | grep -q '"fabric"[[:space:]]*:'; then
  loader_name="fabric"
  loader_version="$(echo "$lock_json" | sed -n 's/.*"fabric"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  fabric_installer_version="$(echo "$config_json" | sed -n 's/.*"fabric_installer_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  installer_file_name="fabric-installer-${fabric_installer_version}.jar"
  template="$(echo "$config_json" | sed -n 's/.*"fabric_installer_url_template"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  installer_url="${template//\{installer_version\}/$fabric_installer_version}"
else
  echo "Unsupported loader in pakku-lock.json"
  exit 1
fi

echo "Detected loader for installer package: ${loader_name} ${loader_version}"
if [[ -n "$installer_url" ]]; then
  wget "$installer_url" -O "$installer_file_name"
  cp "$installer_file_name" installer/
fi

rm -rf installer/.pakku/client-overrides/*

shopt -s dotglob
zip -r "./${SERVER_ZIP_NAME}" ./installer
shopt -u dotglob
