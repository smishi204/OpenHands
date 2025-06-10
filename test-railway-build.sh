#!/bin/bash

# Test script for Railway deployment build
# This script tests the Railway Dockerfile locally

set -e

echo "🚀 Testing OpenHands Railway Deployment Build"
echo "=============================================="

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    exit 1
fi

echo "✅ Docker is available"

# Check if we're in the right directory
if [ ! -f "Dockerfile.railway" ]; then
    echo "❌ Dockerfile.railway not found. Please run this script from the OpenHands root directory."
    exit 1
fi

echo "✅ Dockerfile.railway found"

# Build the Railway image
echo "🔨 Building Railway Docker image..."
docker build -f Dockerfile.railway -t openhands-railway-test . || {
    echo "❌ Docker build failed"
    exit 1
}

echo "✅ Docker image built successfully"

# Test if the image can start
echo "🧪 Testing image startup..."
CONTAINER_ID=$(docker run -d --privileged -p 3000:3000 openhands-railway-test)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ Failed to start container"
    exit 1
fi

echo "✅ Container started with ID: $CONTAINER_ID"

# Wait a bit for the container to initialize
echo "⏳ Waiting for container to initialize..."
sleep 10

# Check if the container is still running
if ! docker ps | grep -q "$CONTAINER_ID"; then
    echo "❌ Container stopped unexpectedly"
    echo "📋 Container logs:"
    docker logs "$CONTAINER_ID"
    docker rm "$CONTAINER_ID" 2>/dev/null || true
    exit 1
fi

echo "✅ Container is running"

# Test if the health endpoint is accessible
echo "🏥 Testing health endpoint..."
if docker exec "$CONTAINER_ID" curl -f http://localhost:3000/api/health 2>/dev/null; then
    echo "✅ Health endpoint is accessible"
else
    echo "⚠️  Health endpoint not accessible (this might be expected during startup)"
fi

# Test Docker daemon inside container
echo "🐳 Testing Docker daemon inside container..."
if docker exec "$CONTAINER_ID" docker info >/dev/null 2>&1; then
    echo "✅ Docker daemon is running inside container"
else
    echo "❌ Docker daemon is not running inside container"
    echo "📋 Container logs:"
    docker logs "$CONTAINER_ID"
    docker stop "$CONTAINER_ID" >/dev/null 2>&1
    docker rm "$CONTAINER_ID" >/dev/null 2>&1
    exit 1
fi

# Cleanup
echo "🧹 Cleaning up..."
docker stop "$CONTAINER_ID" >/dev/null 2>&1
docker rm "$CONTAINER_ID" >/dev/null 2>&1

echo ""
echo "🎉 Railway deployment test completed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Push these files to your GitHub repository"
echo "2. Connect your repository to Railway"
echo "3. Deploy using the railway.toml configuration"
echo ""
echo "📁 Files created for Railway deployment:"
echo "   - Dockerfile.railway"
echo "   - railway-entrypoint.sh"
echo "   - railway.toml"
echo "   - RAILWAY_DEPLOYMENT.md"
echo ""
