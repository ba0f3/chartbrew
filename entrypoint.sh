#!/bin/bash
set -Eeuo pipefail

# all env vars used in the client app need to be set here as well
export VITE_APP_API_HOST="${VITE_APP_API_HOST:-}"
export VITE_APP_CLIENT_HOST="${VITE_APP_CLIENT_HOST:-}"
export VITE_APP_CLIENT_PORT="${VITE_APP_CLIENT_PORT:-4018}"
export VITE_APP_ONE_ACCOUNT_EXTERNAL_ID="${VITE_APP_ONE_ACCOUNT_EXTERNAL_ID:-}"

api_pid=""
client_pid=""
build_pid=""

stop_children() {
  for pid in "${api_pid}" "${client_pid}" "${build_pid}"; do
    if [ -n "${pid}" ] && kill -0 "${pid}" 2>/dev/null; then
      kill "${pid}" 2>/dev/null || true
    fi
  done
}

trap "stop_children; exit 143" TERM INT

cd server
NODE_ENV=production node index.js &
api_pid="$!"

cd ../client
# mkdir -p dist

# Build the UI in the background
# sh -c 'echo "The UI is rebuilding. Please wait..." && npm run build && echo "UI built successfully!" && cp -rf build/* dist/' &
sh -c 'echo "The UI is rebuilding. Please wait..." && npm run build && echo "UI built successfully!"' &
build_pid="$!"

# Serve the UI
npx serve -s dist -l "${VITE_APP_CLIENT_PORT}" &
client_pid="$!"

set +e
wait -n "${api_pid}" "${client_pid}"
exit_code="$?"

stop_children
wait "${api_pid}" "${client_pid}" "${build_pid}" 2>/dev/null || true
exit "${exit_code}"
