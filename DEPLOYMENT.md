# Frontend Microservice Deployment Guide

This guide explains the Docker containerization and CI/CD pipeline for the Vite frontend microservice.

## 📋 Overview

This setup includes:
- Multi-stage Dockerfile for production builds
- GitHub Actions CI/CD pipeline
- Docker image publishing to DockerHub
- Security scanning and best practices

## 🐳 Dockerfile Explanation

### Multi-Stage Build Strategy

Our Dockerfile uses a **multi-stage build** approach for optimal image size and security:

#### Stage 1: Build Stage (`node:18-alpine`)
```dockerfile
FROM node:18-alpine AS build
```

**Purpose**: Compile and build the Vite application
- Uses Node.js 18 on Alpine Linux (smaller footprint)
- Installs all dependencies (including devDependencies)
- Builds the production bundle

**Key Features**:
- **Build-time environment variable**: `VITE_API_URL` is set during build
- **Layer caching**: Package files copied first to leverage Docker cache
- **Production build**: Runs `npm run build` to generate optimized assets

#### Stage 2: Production Stage (`nginx:alpine`)
```dockerfile
FROM nginx:alpine AS production
```

**Purpose**: Serve the built application efficiently
- Uses lightweight Nginx on Alpine Linux
- Only contains production assets (no source code or build tools)
- Reduces final image size significantly

### Environment Variables

```dockerfile
ARG VITE_API_URL=https://api.prod.example.com
ENV VITE_API_URL=$VITE_API_URL
```

- **Build Argument**: Can be overridden during build time
- **Default Value**: Points to production API endpoint
- **Vite Integration**: Automatically injected into the build process

### Security Features

1. **Health Check**: Built-in health monitoring
2. **Non-root execution**: Nginx runs as non-privileged user
3. **Minimal attack surface**: Only production assets in final image

## ⚙️ Nginx Configuration

The `nginx.conf` file provides:

### Single Page Application (SPA) Support
```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```
Routes all non-existent paths to `index.html` for client-side routing.

### Performance Optimizations
- **Gzip compression** for faster loading
- **Static asset caching** with long expiration times
- **Cache headers** for proper browser caching

### Security Headers
- `X-Frame-Options`: Prevents clickjacking
- `X-Content-Type-Options`: Prevents MIME sniffing
- `X-XSS-Protection`: Enables XSS filtering
- `Referrer-Policy`: Controls referrer information

## 🚀 GitHub Actions CI Pipeline

### Trigger Conditions

The pipeline runs on:
- Push to `main` or `develop` branches
- Pull requests to `main`
- Manual workflow dispatch

### Pipeline Jobs

#### 1. Build and Push Job

**Steps Overview**:
1. **Code Checkout**: Get latest source code
2. **Node.js Setup**: Install Node.js 18 with npm caching
3. **Testing**: Run tests and linting (if available)
4. **Docker Setup**: Configure Buildx for multi-platform builds
5. **Metadata Extraction**: Generate Docker tags and labels
6. **DockerHub Login**: Authenticate with Docker registry
7. **Build & Push**: Create and publish Docker image
8. **SBOM Generation**: Create Software Bill of Materials

**Multi-Platform Support**:
```yaml
platforms: linux/amd64,linux/arm64
```
Builds images for both x86 and ARM architectures.

**Caching Strategy**:
```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```
Uses GitHub Actions cache to speed up subsequent builds.

#### 2. Security Scan Job

**Trivy Scanner**: 
- Scans the built image for vulnerabilities
- Generates SARIF report for GitHub Security tab
- Runs only on successful builds (not PRs)

### Image Tagging Strategy

The pipeline creates multiple tags:
- `latest`: For main branch builds
- `{branch-name}`: For branch-specific builds
- `{branch}-{sha}`: For specific commit tracking
- `pr-{number}`: For pull request builds

## 🔧 Setup Instructions

### Prerequisites

1. **DockerHub Account**: Create account at hub.docker.com
2. **GitHub Repository**: Your code repository
3. **DockerHub Token**: Generate access token in DockerHub settings

### Configuration Steps

#### 1. Update Image Name
In `.github/workflows/ci-pipeline.yml`:
```yaml
env:
  IMAGE_NAME: your-dockerhub-username/frontend-microservice
```
Replace `your-dockerhub-username` with your actual DockerHub username.

#### 2. GitHub Secrets
Add these secrets to your GitHub repository:

**Settings → Secrets and variables → Actions**

| Secret Name | Description | Value |
|-------------|-------------|-------|
| `DOCKERHUB_USERNAME` | Your DockerHub username | `your-username` |
| `DOCKERHUB_TOKEN` | DockerHub access token | `dckr_pat_xxxxx...` |

#### 3. Package.json Scripts
Ensure your `package.json` includes:
```json
{
  "scripts": {
    "build": "vite build",
    "test": "vitest",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0"
  }
}
```

## 🏃‍♂️ Local Development

### Build Docker Image
```bash
# Build with default API URL
docker build -t frontend-microservice .

# Build with custom API URL
docker build --build-arg VITE_API_URL=https://api.dev.example.com -t frontend-microservice:dev .
```

### Run Container
```bash
# Run on port 8080
docker run -p 8080:80 frontend-microservice

# Run with health checks
docker run -p 8080:80 --health-cmd="curl -f http://localhost/ || exit 1" frontend-microservice
```

### Test Health Check
```bash
curl http://localhost:8080/health
# Should return: healthy
```

## 📊 Monitoring and Troubleshooting

### Container Logs
```bash
docker logs <container-id>
```

### Health Status
```bash
docker inspect <container-id> | grep Health -A 10
```

### Pipeline Status
- Check GitHub Actions tab in your repository
- Review build logs for any failures
- Monitor DockerHub for published images

## 🔒 Security Best Practices

1. **Regular Updates**: Keep base images updated
2. **Vulnerability Scanning**: Automated with Trivy
3. **Secrets Management**: Use GitHub Secrets for sensitive data
4. **Minimal Dependencies**: Multi-stage build reduces attack surface
5. **Non-root Execution**: Nginx runs as non-privileged user

## 🚀 Production Deployment

The built Docker image can be deployed to:
- **Kubernetes clusters**
- **Docker Swarm**
- **Cloud container services** (AWS ECS, Google Cloud Run, Azure Container Instances)
- **Traditional servers** with Docker

Example Kubernetes deployment:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-microservice
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend-microservice
  template:
    metadata:
      labels:
        app: frontend-microservice
    spec:
      containers:
      - name: frontend
        image: your-dockerhub-username/frontend-microservice:latest
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
```

This completes your frontend microservice deployment pipeline with Docker and GitHub Actions!
