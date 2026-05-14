#!/bin/sh
set -eu

ENTRYPOINT="${1:-entrypoint.sh}"

if [ ! -f "$ENTRYPOINT" ]; then
  echo "Missing entrypoint: $ENTRYPOINT" >&2
  exit 1
fi

require_line() {
  pattern="$1"
  message="$2"

  if ! grep -Eq "$pattern" "$ENTRYPOINT"; then
    echo "$message" >&2
    exit 1
  fi
}

line_number() {
  pattern="$1"
  grep -En "$pattern" "$ENTRYPOINT" | head -n 1 | cut -d: -f1
}

require_line "^set -euo pipefail$" "entrypoint.sh must fail fast with set -euo pipefail"
require_line "VITE_APP_API_HOST:\\?VITE_APP_API_HOST is required" "entrypoint.sh must clearly require VITE_APP_API_HOST"
require_line "VITE_APP_CLIENT_HOST:\\?VITE_APP_CLIENT_HOST is required" "entrypoint.sh must clearly require VITE_APP_CLIENT_HOST"
require_line "VITE_APP_CLIENT_PORT:\\?VITE_APP_CLIENT_PORT is required" "entrypoint.sh must clearly require VITE_APP_CLIENT_PORT"
require_line "VITE_APP_ONE_ACCOUNT_EXTERNAL_ID:-" "entrypoint.sh must allow optional one-account configuration to be unset"
require_line "npm run build" "entrypoint.sh must build the client before serving it"
require_line "dist/index\\.html" "entrypoint.sh must verify dist/index.html exists"
require_line "npx serve -s dist -l tcp://0\\.0\\.0\\.0:\\$\\{VITE_APP_CLIENT_PORT\\}" "entrypoint.sh must bind serve to 0.0.0.0 with SPA fallback"

if grep -Eq "nohup .*npm run build|npm run build.*&" "$ENTRYPOINT"; then
  echo "entrypoint.sh must not run the client build in the background" >&2
  exit 1
fi

build_line="$(line_number "npm run build")"
serve_line="$(line_number "npx serve -s dist")"

if [ -z "$build_line" ] || [ -z "$serve_line" ] || [ "$build_line" -ge "$serve_line" ]; then
  echo "entrypoint.sh must build the client before starting serve" >&2
  exit 1
fi

echo "entrypoint.sh startup contract looks good"
