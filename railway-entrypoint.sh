#!/bin/bash
set -eo pipefail

echo "Starting OpenHands on Railway..."

# Start Docker daemon in the background for Railway deployment
echo "Starting Docker daemon..."
dockerd-entrypoint.sh dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2376 --tls=false &

# Wait for Docker daemon to be ready
echo "Waiting for Docker daemon to be ready..."
timeout=30
while ! docker info >/dev/null 2>&1; do
    if [ $timeout -le 0 ]; then
        echo "Docker daemon failed to start within 30 seconds"
        exit 1
    fi
    echo "Waiting for Docker daemon... ($timeout seconds remaining)"
    sleep 1
    timeout=$((timeout - 1))
done

echo "Docker daemon is ready!"

# Set up environment for Railway
if [ -z "$SANDBOX_USER_ID" ]; then
    export SANDBOX_USER_ID=0
fi

if [ -z "$WORKSPACE_MOUNT_PATH" ]; then
    # This is set to /opt/workspace_base in the Dockerfile. But if the user isn't mounting, we want to unset it so that OpenHands doesn't mount at all
    unset WORKSPACE_BASE
fi

# Ensure proper permissions
chown -R openhands:app /app 2>/dev/null || true
chown -R openhands:app $WORKSPACE_BASE 2>/dev/null || true
chown -R openhands:app $FILE_STORE_PATH 2>/dev/null || true

# Add openhands user to docker group for Railway
DOCKER_SOCKET_GID=$(stat -c '%g' /var/run/docker.sock 2>/dev/null || echo "999")
echo "Docker socket group id: $DOCKER_SOCKET_GID"

if ! getent group $DOCKER_SOCKET_GID >/dev/null 2>&1; then
    echo "Creating group with id $DOCKER_SOCKET_GID"
    addgroup -g $DOCKER_SOCKET_GID docker_runtime 2>/dev/null || true
fi

addgroup openhands docker 2>/dev/null || true
addgroup openhands docker_runtime 2>/dev/null || true

# Test Python dependencies
echo "Testing Python dependencies..."
su openhands -c "cd /app && python -c 'import openhands.agenthub; import dotenv; print(\"✅ All dependencies loaded successfully\")'"

echo "Running OpenHands as openhands user..."
export RUN_AS_OPENHANDS=true

# Execute the command as openhands user
exec su openhands -c "cd /app && exec $*"
