#!/bin/bash
set -euo pipefail

: "${VITE_APP_API_HOST:?VITE_APP_API_HOST is required}"
: "${VITE_APP_CLIENT_HOST:?VITE_APP_CLIENT_HOST is required}"
: "${VITE_APP_CLIENT_PORT:?VITE_APP_CLIENT_PORT is required}"

server_pid=""
client_pid=""

cleanup() {
  trap - EXIT
  kill "$server_pid" "$client_pid" 2>/dev/null || true
  wait "$server_pid" "$client_pid" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

# all env vars used in the client app need to be set here as well
export VITE_APP_API_HOST=${VITE_APP_API_HOST}
export VITE_APP_CLIENT_HOST=${VITE_APP_CLIENT_HOST}
export VITE_APP_CLIENT_PORT=${VITE_APP_CLIENT_PORT}
export VITE_APP_ONE_ACCOUNT_EXTERNAL_ID=${VITE_APP_ONE_ACCOUNT_EXTERNAL_ID:-}

cd server
NODE_ENV=production node index.js &
server_pid=$!

cd ../client

echo "Building the UI. Please wait..."
npm run build
echo "UI built successfully!"

if ! kill -0 "$server_pid" 2>/dev/null; then
  echo "Server process exited before the UI server started" >&2
  wait "$server_pid"
fi

if [ ! -f dist/index.html ]; then
  echo "Client build did not produce dist/index.html" >&2
  exit 1
fi

# Serve the UI
npx serve -s dist -l "tcp://0.0.0.0:${VITE_APP_CLIENT_PORT}" &
client_pid=$!

set +e
wait -n "$server_pid" "$client_pid"
exit_code=$?
set -e

cleanup
exit "$exit_code"
