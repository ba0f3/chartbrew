#!/bin/bash

# all env vars used in the client app need to be set here as well
export VITE_APP_API_HOST=${VITE_APP_API_HOST}
export VITE_APP_CLIENT_HOST=${VITE_APP_CLIENT_HOST}
export VITE_APP_CLIENT_PORT=${VITE_APP_CLIENT_PORT}
export VITE_APP_ONE_ACCOUNT_EXTERNAL_ID=${VITE_APP_ONE_ACCOUNT_EXTERNAL_ID}

# Start the API server in the background; logs go to container stdout/stderr
( cd server && NODE_ENV=production node index.js ) &

# Rebuild the UI in the background so runtime Vite env vars take effect
( cd client && echo "The UI is rebuilding. Please wait..." && npm run build && echo "UI built successfully!" ) &

# Serve the UI in the foreground (keeps the container alive and forwards signals)
cd client
exec npx serve -s dist -l ${VITE_APP_CLIENT_PORT}
