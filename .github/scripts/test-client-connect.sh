#!/usr/bin/env bash
set -euo pipefail

SERVER_DIR="${SERVER_DIR:-server}"
CLIENT_DIR="${CLIENT_DIR:-client}"
LOCKFILE_PATH="${LOCKFILE_PATH:-pakku-lock.json}"
USERNAME="${CLIENT_USERNAME:-CIPlayer}"
SERVER_HOST="${SERVER_HOST:-localhost}"
SERVER_PORT="${SERVER_PORT:-25565}"

if [[ ! -d "$SERVER_DIR" ]]; then
  echo "Server directory not found: $SERVER_DIR"
  exit 1
fi

if [[ ! -f "$LOCKFILE_PATH" ]]; then
  echo "Lockfile not found: $LOCKFILE_PATH"
  exit 1
fi

if ! command -v portablemc >/dev/null 2>&1; then
  echo "portablemc is not available in PATH"
  exit 1
fi

if [[ -z "${DISPLAY:-}" ]]; then
  echo "DISPLAY is not set. Xvfb is required for client launch."
  exit 1
fi

mkdir -p "$CLIENT_DIR/profile"
cat > "$CLIENT_DIR/profile/options.txt" <<EOF
skipMultiplayerWarning:true
onboardAccessibility:false
joinedFirstServer:true
tutorialStep:none
EOF

launch_info_file="$(mktemp)"
python3 ./.github/scripts/resolve-client-launch-targets.py "$LOCKFILE_PATH" "$launch_info_file"
readarray -t launch_info < "$launch_info_file"
rm -f "$launch_info_file"

if [[ "${#launch_info[@]}" -lt 2 ]]; then
  echo "Unable to resolve Minecraft launch target from lockfile"
  exit 1
fi

MC_VERSION="${launch_info[0]}"
TARGETS=("${launch_info[@]:1}")

echo "Resolved MC version: $MC_VERSION"
echo "Trying launch targets: ${TARGETS[*]}"

selected_target=""
for target in "${TARGETS[@]}"; do
  echo "Checking launch target: $target"
  dry_log_file="$(mktemp)"
  if portablemc --main-dir "$CLIENT_DIR/.minecraft" start "$target" --work-dir "$CLIENT_DIR/profile" -u "$USERNAME" --dry > /dev/null 2> "$dry_log_file"; then
    selected_target="$target"
    rm -f "$dry_log_file"
    break
  else
    echo "Target failed: $target"
    sed -n '1,8p' "$dry_log_file" || true
    rm -f "$dry_log_file"
  fi
done

if [[ -z "$selected_target" ]]; then
  echo "Failed to resolve a valid portablemc launch target"
  exit 1
fi

echo "Selected launch target: $selected_target"

if [[ -f "$SERVER_DIR/server.properties" ]]; then
  if grep -q '^online-mode=' "$SERVER_DIR/server.properties"; then
    sed -i 's/^online-mode=.*/online-mode=false/' "$SERVER_DIR/server.properties"
  else
    echo 'online-mode=false' >> "$SERVER_DIR/server.properties"
  fi
else
  echo 'online-mode=false' > "$SERVER_DIR/server.properties"
fi

pushd "$SERVER_DIR" >/dev/null
chmod +x run.sh

./run.sh > server.log 2>&1 &
SERVER_PID=$!

echo "Started server with PID $SERVER_PID"

cleanup() {
  if kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
  fi
  if [[ -n "${CLIENT_PID:-}" ]] && kill -0 "$CLIENT_PID" 2>/dev/null; then
    kill "$CLIENT_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

if ! timeout 8m grep -q 'Done ([0-9.]\+s)! For help, type "help"' <(tail -f server.log); then
  echo "Server did not start successfully"
  cat server.log || true
  exit 1
fi

echo "Server started, launching client"
popd >/dev/null

portablemc \
  --main-dir "$CLIENT_DIR/.minecraft" \
  start "$selected_target" \
  --work-dir "$CLIENT_DIR/profile" \
  -u "$USERNAME" \
  -s "$SERVER_HOST" \
  -p "$SERVER_PORT" > "$CLIENT_DIR/client.log" 2>&1 &
CLIENT_PID=$!

echo "Started client with PID $CLIENT_PID"

if ! timeout 6m grep -q "$USERNAME joined the game" <(tail -f "$SERVER_DIR/server.log"); then
  echo "Client did not join server in time"
  echo "===== Server Log ====="
  cat "$SERVER_DIR/server.log" || true
  echo "===== Client Log ====="
  cat "$CLIENT_DIR/client.log" || true
  exit 1
fi

echo "Client joined server successfully"
sleep 20

if ! kill -0 "$CLIENT_PID" 2>/dev/null; then
  echo "Client crashed after joining"
  echo "===== Client Log ====="
  cat "$CLIENT_DIR/client.log" || true
  exit 1
fi

echo "Client connection test passed"