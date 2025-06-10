# OpenHands Railway Deployment Guide

This guide explains how to deploy OpenHands to Railway.com with Docker-in-Docker (DinD) support for the runtime environment.

## Files Overview

### 1. `Dockerfile.railway`
A specialized Dockerfile for Railway deployment that:
- Uses Docker-in-Docker (DinD) base image for runtime support
- Configures proper user permissions and security
- Sets up the environment for Railway's container platform
- Includes all necessary dependencies for OpenHands

### 2. `railway-entrypoint.sh`
Custom entrypoint script that:
- Starts the Docker daemon in the background
- Configures proper permissions for Docker socket access
- Sets up the OpenHands user environment
- Ensures compatibility with Railway's platform

### 3. `railway.toml`
Railway configuration file that:
- Specifies the custom Dockerfile to use
- Sets environment variables for OpenHands
- Configures health checks and restart policies
- Optimizes deployment settings for Railway

## Deployment Steps

### Prerequisites
1. A Railway.com account
2. Railway CLI installed (optional but recommended)
3. This OpenHands repository

### Option 1: Deploy via Railway Dashboard

1. **Connect Repository**
   - Go to [Railway Dashboard](https://railway.app/dashboard)
   - Click "New Project" → "Deploy from GitHub repo"
   - Select your OpenHands repository

2. **Configure Build Settings**
   - Railway should automatically detect the `railway.toml` file
   - If not, manually set:
     - Build Command: `docker build -f Dockerfile.railway -t openhands-railway .`
     - Start Command: `uvicorn openhands.server.listen:app --host 0.0.0.0 --port $PORT`

3. **Set Environment Variables**
   The following environment variables are automatically configured via `railway.toml`, but you can override them:

   ```
   SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.all-hands.dev/all-hands-ai/runtime:0.41-nikolaik
   SANDBOX_USER_ID=0
   RUN_AS_OPENHANDS=true
   USE_HOST_NETWORK=false
   FILE_STORE=local
   FILE_STORE_PATH=/.openhands-state
   WORKSPACE_BASE=/opt/workspace_base
   DOCKER_TLS_CERTDIR=""
   DOCKER_HOST=unix:///var/run/docker.sock
   SERVE_FRONTEND=true
   LOG_LEVEL=INFO
   SANDBOX_LOCAL_RUNTIME_URL=http://localhost
   ```

4. **Deploy**
   - Click "Deploy" and wait for the build to complete
   - Railway will provide you with a public URL

### Option 2: Deploy via Railway CLI

1. **Install Railway CLI**
   ```bash
   npm install -g @railway/cli
   ```

2. **Login to Railway**
   ```bash
   railway login
   ```

3. **Initialize Project**
   ```bash
   railway init
   ```

4. **Deploy**
   ```bash
   railway up
   ```

## Important Notes

### Docker-in-Docker Support
- The deployment uses Docker-in-Docker to support OpenHands' runtime requirements
- This allows OpenHands to create and manage containers for code execution
- The Docker daemon runs inside the Railway container with proper security configurations

### Security Considerations
- The deployment runs with necessary privileges for Docker access
- User permissions are properly configured to maintain security
- Docker socket access is restricted to the OpenHands user

### Resource Requirements
- Recommended: At least 2GB RAM and 2 CPU cores
- Storage: Minimum 10GB for Docker images and workspace
- Railway's Pro plan is recommended for production use

### Limitations
- Some Docker features may be limited in Railway's environment
- Network access between containers may have restrictions
- Persistent storage is limited to Railway's volume system

## Troubleshooting

### Common Issues

1. **Docker Daemon Not Starting**
   - Check logs for Docker daemon startup errors
   - Ensure sufficient resources are allocated
   - Verify Railway supports privileged containers

2. **Permission Errors**
   - Check that the entrypoint script has execute permissions
   - Verify user/group configurations in the Dockerfile

3. **Port Binding Issues**
   - Ensure the application binds to `0.0.0.0:$PORT`
   - Check that Railway's PORT environment variable is used

4. **Runtime Container Issues**
   - Verify the runtime container image is accessible
   - Check Docker daemon logs for pull errors

### Debugging

To debug deployment issues:

1. **Check Railway Logs**
   ```bash
   railway logs
   ```

2. **Connect to Container**
   ```bash
   railway shell
   ```

3. **Test Docker Daemon**
   ```bash
   docker info
   docker ps
   ```

## Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `SANDBOX_RUNTIME_CONTAINER_IMAGE` | `docker.all-hands.dev/all-hands-ai/runtime:0.41-nikolaik` | Runtime container image |
| `SANDBOX_USER_ID` | `0` | User ID for sandbox environment |
| `RUN_AS_OPENHANDS` | `true` | Run as OpenHands user |
| `USE_HOST_NETWORK` | `false` | Use host networking |
| `FILE_STORE` | `local` | File storage backend |
| `FILE_STORE_PATH` | `/.openhands-state` | Path for file storage |
| `WORKSPACE_BASE` | `/opt/workspace_base` | Base workspace directory |
| `DOCKER_HOST` | `unix:///var/run/docker.sock` | Docker daemon socket |
| `SERVE_FRONTEND` | `true` | Serve frontend files |
| `LOG_LEVEL` | `INFO` | Logging level |

## Support

For deployment issues:
1. Check Railway's documentation
2. Review OpenHands logs via Railway dashboard
3. Ensure all environment variables are properly set
4. Verify Docker-in-Docker functionality

## Security Notes

- This deployment requires privileged container access for Docker-in-Docker
- Ensure your Railway project has appropriate access controls
- Consider using Railway's private networking features for production
- Regularly update the base images and dependencies
